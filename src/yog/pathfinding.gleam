import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/order.{type Order}
import yog/internal/pathfinding/a_star
import yog/internal/pathfinding/bellman_ford
import yog/internal/pathfinding/dijkstra
import yog/internal/pathfinding/floyd_warshall
import yog/internal/pathfinding/matrix
import yog/model.{type Graph, type NodeId}

/// Represents a path through the graph with its total weight.
pub type Path(e) {
  Path(nodes: List(NodeId), total_weight: e)
}

/// Result type for Bellman-Ford algorithm.
pub type BellmanFordResult(e) {
  /// A shortest path was found successfully
  ShortestPath(path: Path(e))
  /// A negative cycle was detected (reachable from source)
  NegativeCycle
  /// No path exists from start to goal
  NoPath
}

/// Result type for implicit Bellman-Ford algorithm.
pub type ImplicitBellmanFordResult(cost) {
  /// A shortest distance to goal was found
  FoundGoal(cost)
  /// A negative cycle was detected (reachable from start)
  DetectedNegativeCycle
  /// No goal state was reached
  NoGoal
}

/// Finds the shortest path between two nodes using Dijkstra's algorithm.
///
/// Works with non-negative edge weights only. For negative weights, use `bellman_ford`.
///
/// **Time Complexity:** O((V + E) log V) with heap
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// pathfinding.shortest_path(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => Some(Path([1, 2, 5], 15))
/// ```
pub fn shortest_path(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Option(Path(e)) {
  dijkstra.shortest_path(graph, start, goal, zero, add, compare)
  |> option.map(fn(res) {
    let #(dist, path) = res
    Path(nodes: list.reverse(path), total_weight: dist)
  })
}

/// Computes shortest distances from a source node to all reachable nodes.
///
/// Returns a dictionary mapping each reachable node to its shortest distance
/// from the source. Unreachable nodes are not included in the result.
///
/// This is useful when you need distances to multiple destinations, or want
/// to find the closest target among many options. More efficient than running
/// `shortest_path` multiple times.
///
/// **Time Complexity:** O((V + E) log V) with heap
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// // Find distances from node 1 to all reachable nodes
/// let distances = pathfinding.single_source_distances(
///   in: graph,
///   from: 1,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => dict.from_list([#(1, 0), #(2, 5), #(3, 8), #(4, 15)])
///
/// // Find closest target among many options
/// let targets = [10, 20, 30]
/// let closest = targets
///   |> list.filter_map(fn(t) { dict.get(distances, t) })
///   |> list.sort(int.compare)
///   |> list.first
/// ```
///
/// ## Use Cases
///
/// - Finding nearest target among multiple options
/// - Computing distance maps for game AI
/// - Network routing table generation
/// - Graph analysis (centrality measures)
/// - Reverse pathfinding (with `transform.transpose`)
pub fn single_source_distances(
  in graph: Graph(n, e),
  from source: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dict(NodeId, e) {
  dijkstra.single_source_distances(graph, source, zero, add, compare)
}

/// Finds the shortest path in an implicit graph using Dijkstra's algorithm.
///
/// Unlike `shortest_path`, this does not require a materialized `Graph` value.
/// Instead, you provide a `successors_with_cost` function that computes weighted
/// neighbors on demand — ideal for state-space search, puzzles, or graphs too
/// large to build upfront.
///
/// Returns the shortest distance to any state satisfying `is_goal`, or `None`
/// if no goal state is reachable.
///
/// **Time Complexity:** O((V + E) log V) where V is visited states and E is explored transitions
///
/// ## Parameters
///
/// - `successors_with_cost`: Function that generates weighted successors for a state
/// - `is_goal`: Predicate that identifies goal states
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two costs
/// - `compare`: Function to compare two costs
///
/// ## Example
///
/// ```gleam
/// // Find shortest path in a state-space where each state is (x, y, collected_keys)
/// type State { State(x: Int, y: Int, keys: Int) }
///
/// pathfinding.implicit_dijkstra(
///   from: State(0, 0, 0),
///   successors_with_cost: fn(state) {
///     // Generate neighbor states with their costs
///     [
///       #(State(state.x + 1, state.y, state.keys), 1),
///       #(State(state.x, state.y + 1, state.keys), 1),
///       // ... more neighbors
///     ]
///   },
///   is_goal: fn(state) { state.keys == all_keys_mask },
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
/// )
/// // => Some(42)  // Shortest distance to goal
/// ```
///
/// ## Use Cases
///
/// - Puzzle solving: State-space search for optimal solutions
/// - Game AI: Pathfinding with complex state (position + inventory)
/// - Planning problems: Finding cheapest action sequences
/// - AoC problems: 2019 Day 18, 2021 Day 23, 2022 Day 16, etc.
///
/// ## Notes
///
/// - States are deduplicated by their full value (using `Dict(state, cost)`)
/// - If your state carries extra data beyond identity, use `implicit_dijkstra_by`
/// - First path to reach a state with minimal cost wins
/// - Works with any cost type that supports addition and comparison
pub fn implicit_dijkstra(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  dijkstra.implicit_dijkstra(start, successors, is_goal, zero, add, compare)
}

/// Like `implicit_dijkstra`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// For example, in state-space search you might have `#(Position, ExtraData)` states,
/// but only want to visit each `Position` once — the `ExtraData` is carried state,
/// not part of the identity.
///
/// The `visited_by` function extracts the deduplication key from each state.
/// Internally, a `Dict(key, cost)` tracks the best cost to each key, but the
/// full state value is still passed to your successor function and goal predicate.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
///
/// ## Parameters
///
/// - `visited_by`: Function that extracts the deduplication key from a state
///
/// ## Example
///
/// ```gleam
/// // State-space search where states carry metadata
/// // Node is #(position, path_history) but we dedupe by position only
/// pathfinding.implicit_dijkstra_by(
///   from: #(start_pos, []),
///   successors_with_cost: fn(state) {
///     let #(pos, history) = state
///     neighbors(pos)
///     |> list.map(fn(next_pos) {
///       #(#(next_pos, [pos, ..history]), move_cost(pos, next_pos))
///     })
///   },
///   visited_by: fn(state) { state.0 },  // Dedupe by position only
///   is_goal: fn(state) { state.0 == goal_pos },
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
/// )
/// ```
///
/// ## Use Cases
///
/// - AoC 2019 Day 18: `#(at_key, collected_mask)` → dedupe by both
/// - Puzzle solving: `#(board_state, move_count)` → dedupe by `board_state`
/// - Pathfinding with budget: `#(position, fuel_left)` → dedupe by `position`
/// - A* with metadata: `#(node_id, came_from)` → dedupe by `node_id`
///
/// ## Comparison to `implicit_dijkstra`
///
/// - `implicit_dijkstra`: Deduplicates by the entire state value
/// - `implicit_dijkstra_by`: Deduplicates by `visited_by(state)` but keeps full state
///
/// Similar to SQL's `DISTINCT ON(key)` or Python's `key=` parameter.
pub fn implicit_dijkstra_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  dijkstra.implicit_dijkstra_by(
    start,
    successors,
    key_fn,
    is_goal,
    zero,
    add,
    compare,
  )
}

// ======================== A* SEARCH ========================

/// Finds the shortest path using A* search with a heuristic function.
///
/// A* is more efficient than Dijkstra when you have a good heuristic estimate
/// of the remaining distance to the goal. The heuristic must be admissible
/// (never overestimate the actual distance) to guarantee finding the shortest path.
///
/// **Time Complexity:** O((V + E) log V), but often faster than Dijkstra in practice
///
/// ## Parameters
///
/// - `heuristic`: A function that estimates distance from any node to the goal.
///   Must be admissible (h(n) ≤ actual distance) to guarantee shortest path.
///
/// ## Example
///
/// ```gleam
/// // Manhattan distance heuristic for grid
/// let h = fn(node, goal) {
///   int.absolute_value(node.x - goal.x) + int.absolute_value(node.y - goal.y)
/// }
///
/// pathfinding.a_star(
///   in: graph,
///   from: start,
///   to: goal,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   heuristic: h
/// )
/// ```
pub fn a_star(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  heuristic h: fn(NodeId, NodeId) -> e,
) -> Option(Path(e)) {
  a_star.a_star(graph, start, goal, zero, add, compare, h)
  |> option.map(fn(res) {
    let #(dist, path) = res
    Path(nodes: list.reverse(path), total_weight: dist)
  })
}

/// Finds the shortest path in an implicit graph using A* search with a heuristic.
///
/// Like `implicit_dijkstra`, but uses a heuristic to guide the search toward the goal.
/// The heuristic must be admissible (never overestimate the actual distance) to guarantee
/// finding the shortest path.
///
/// **Time Complexity:** O((V + E) log V), but often faster than Dijkstra in practice
///
/// ## Parameters
///
/// - `heuristic`: Function that estimates remaining cost from any state to goal.
///   Must be admissible (h(state) ≤ actual cost) to guarantee shortest path.
///
/// ## Example
///
/// ```gleam
/// // Grid pathfinding with Manhattan distance heuristic
/// type Pos { Pos(x: Int, y: Int) }
///
/// pathfinding.implicit_a_star(
///   from: Pos(0, 0),
///   successors_with_cost: fn(pos) {
///     [
///       #(Pos(pos.x + 1, pos.y), 1),
///       #(Pos(pos.x, pos.y + 1), 1),
///     ]
///   },
///   is_goal: fn(pos) { pos.x == 10 && pos.y == 10 },
///   heuristic: fn(pos) {
///     // Manhattan distance to goal
///     int.absolute_value(10 - pos.x) + int.absolute_value(10 - pos.y)
///   },
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
/// )
/// ```
///
/// ## Use Cases
///
/// - Grid pathfinding with spatial heuristics (Manhattan, Euclidean)
/// - Puzzle solving where you can estimate "distance to solution"
/// - Game AI pathfinding on maps
/// - Any scenario where Dijkstra works but you have a good heuristic
pub fn implicit_a_star(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  a_star.implicit_a_star(start, successors, is_goal, h, zero, add, compare)
}

/// Like `implicit_a_star`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// The heuristic still operates on the full state, but deduplication uses only the key.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
///
/// ## Example
///
/// ```gleam
/// // Grid with carried items, but dedupe by position only
/// // Heuristic considers only position, not items
/// pathfinding.implicit_a_star_by(
///   from: #(Pos(0, 0), []),
///   successors_with_cost: fn(state) {
///     let #(pos, items) = state
///     neighbors(pos)
///     |> list.map(fn(next_pos) { #(#(next_pos, items), 1) })
///   },
///   visited_by: fn(state) { state.0 },  // Dedupe by position
///   is_goal: fn(state) { state.0 == goal_pos },
///   heuristic: fn(state) { manhattan_distance(state.0, goal_pos) },
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
/// )
/// ```
pub fn implicit_a_star_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  a_star.implicit_a_star_by(
    start,
    successors,
    key_fn,
    is_goal,
    h,
    zero,
    add,
    compare,
  )
}

// ======================== BELLMAN-FORD ========================

/// Finds shortest path with support for negative edge weights using Bellman-Ford.
///
/// Unlike Dijkstra and A*, this algorithm can handle negative edge weights.
/// It also detects negative cycles reachable from the source node.
///
/// **Time Complexity:** O(VE) where V is vertices and E is edges
///
/// ## Returns
///
/// - `ShortestPath(path)`: If a valid shortest path exists
/// - `NegativeCycle`: If a negative cycle is reachable from the start node
/// - `NoPath`: If no path exists from start to goal
///
/// ## Example
///
/// ```gleam
/// pathfinding.bellman_ford(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => ShortestPath(Path([1, 3, 5], -2))  // Can have negative total weight
/// // or NegativeCycle                       // If cycle detected
/// // or NoPath                              // If unreachable
/// ```
pub fn bellman_ford(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> BellmanFordResult(e) {
  case bellman_ford.bellman_ford(graph, start, goal, zero, add, compare) {
    bellman_ford.ShortestPathRaw(dist, nodes) ->
      ShortestPath(Path(nodes: nodes, total_weight: dist))
    bellman_ford.NegativeCycleRaw -> NegativeCycle
    bellman_ford.NoPathRaw -> NoPath
  }
}

/// Finds shortest path in implicit graphs with support for negative edge weights.
///
/// Uses SPFA (Shortest Path Faster Algorithm), a queue-based variant of Bellman-Ford
/// that works naturally with implicit graphs. Detects negative cycles by counting
/// relaxations per state.
///
/// **Time Complexity:** O(VE) average case where V and E are discovered dynamically
///
/// ## Returns
///
/// - `FoundGoal(cost)`: If a valid shortest path to goal exists
/// - `DetectedNegativeCycle`: If a negative cycle is reachable from start
/// - `NoGoal`: If no goal state is reached before exhausting reachable states
///
/// ## Example
///
/// ```gleam
/// pathfinding.implicit_bellman_ford(
///   from: start_state,
///   successors_with_cost: fn(state) {
///     // Can include negative costs
///     [#(next_state1, -5), #(next_state2, 10)]
///   },
///   is_goal: fn(state) { state == goal },
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
/// )
/// ```
pub fn implicit_bellman_ford(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> ImplicitBellmanFordResult(cost) {
  case
    bellman_ford.implicit_bellman_ford(
      start,
      successors,
      is_goal,
      zero,
      add,
      compare,
    )
  {
    bellman_ford.FoundGoalRaw(cost) -> FoundGoal(cost)
    bellman_ford.DetectedNegativeCycleRaw -> DetectedNegativeCycle
    bellman_ford.NoGoalRaw -> NoGoal
  }
}

/// Like `implicit_bellman_ford`, but deduplicates visited states by a custom key.
///
/// **Time Complexity:** O(VE) where V and E are measured in unique *keys*
pub fn implicit_bellman_ford_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> ImplicitBellmanFordResult(cost) {
  case
    bellman_ford.implicit_bellman_ford_by(
      start,
      successors,
      key_fn,
      is_goal,
      zero,
      add,
      compare,
    )
  {
    bellman_ford.FoundGoalRaw(cost) -> FoundGoal(cost)
    bellman_ford.DetectedNegativeCycleRaw -> DetectedNegativeCycle
    bellman_ford.NoGoalRaw -> NoGoal
  }
}

// ======================== FLOYD-WARSHALL ========================

/// Computes shortest paths between all pairs of nodes using the Floyd-Warshall algorithm.
///
/// Returns a nested dictionary where `distances[i][j]` gives the shortest distance from node `i` to node `j`.
/// If no path exists between two nodes, the pair will not be present in the dictionary.
///
/// Returns `Error(Nil)` if a negative cycle is detected in the graph.
///
/// **Time Complexity:** O(V³)
/// **Space Complexity:** O(V²)
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., `0` for integers, `0.0` for floats)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import gleam/int
/// import gleam/io
/// import yog
/// import yog/pathfinding
///
/// pub fn main() {
///   let graph =
///     yog.directed()
///     |> yog.add_node(1, "A")
///     |> yog.add_node(2, "B")
///     |> yog.add_node(3, "C")
///     |> yog.add_edge(from: 1, to: 2, with: 4)
///     |> yog.add_edge(from: 2, to: 3, with: 3)
///     |> yog.add_edge(from: 1, to: 3, with: 10)
///
///   case pathfinding.floyd_warshall(
///     in: graph,
///     with_zero: 0,
///     with_add: int.add,
///     with_compare: int.compare
///   ) {
///     Ok(distances) -> {
///       // Query distance from node 1 to node 3
///       let assert Ok(row) = dict.get(distances, 1)
///       let assert Ok(dist) = dict.get(row, 3)
///       // dist = 7 (via node 2: 4 + 3)
///       io.println("Distance from 1 to 3: " <> int.to_string(dist))
///     }
///     Error(Nil) -> io.println("Negative cycle detected!")
///   }
/// }
/// ```
///
/// ## Handling Negative Weights
///
/// Floyd-Warshall can handle negative edge weights and will detect negative cycles:
///
/// ```gleam
/// let graph_with_negative_cycle =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_edge(from: 1, to: 2, with: 5)
///   |> yog.add_edge(from: 2, to: 1, with: -10)
///
/// case pathfinding.floyd_warshall(
///   in: graph_with_negative_cycle,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(_) -> io.println("No negative cycle")
///   Error(Nil) -> io.println("Negative cycle detected!")  // This will execute
/// }
/// ```
///
/// ## Use Cases
///
/// - Computing distance matrices for all node pairs
/// - Finding transitive closure of a graph
/// - Detecting negative cycles
/// - Preprocessing for queries about arbitrary node pairs
/// - Graph metrics (diameter, centrality)
///
pub fn floyd_warshall(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  floyd_warshall.floyd_warshall(graph, zero, add, compare)
}

// ======================== DISTANCE MATRIX ========================

/// Computes shortest distances between all pairs of points of interest.
///
/// Automatically chooses the most efficient algorithm based on the density
/// of points of interest relative to the total graph size:
/// - When POIs are dense (> 1/3 of nodes): Uses Floyd-Warshall O(V³)
/// - When POIs are sparse (≤ 1/3 of nodes): Uses multiple single-source Dijkstra O(P × (V+E) log V)
///
/// Returns only distances between the specified points of interest, not all node pairs.
///
/// **Time Complexity:** Automatically optimized based on POI density
///
/// ## Parameters
///
/// - `between`: List of points of interest (POI) nodes
/// - `zero`: The identity element for addition (e.g., `0` for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Returns
///
/// - `Ok(distances)`: Dictionary mapping POI pairs to their shortest distances
/// - `Error(Nil)`: If a negative cycle is detected (only when using Floyd-Warshall)
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import yog
/// import yog/pathfinding
///
/// // Graph with many nodes, but only care about distances between a few POIs
/// let graph = build_large_graph()  // 1000 nodes
/// let pois = [1, 5, 10, 42]       // 4 points of interest
///
/// // Efficiently computes only POI-to-POI distances
/// case pathfinding.distance_matrix(
///   in: graph,
///   between: pois,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(distances) -> {
///     // Get distance from POI 1 to POI 42
///     dict.get(distances, #(1, 42))
///   }
///   Error(Nil) -> panic as "Negative cycle detected"
/// }
/// ```
///
/// ## Use Cases
///
/// - AoC 2016 Day 24: Computing distances between numbered locations
/// - TSP-like problems: Finding optimal tour through specific landmarks
/// - Network analysis: Distances between server hubs
/// - Game pathfinding: Distances between quest objectives
///
/// ## Algorithm Selection
///
/// The function automatically chooses the optimal algorithm:
/// - **Floyd-Warshall** when POIs are dense: Computes all-pairs shortest paths once,
///   then filters to POIs. Efficient when you need distances for most nodes.
/// - **Multiple Dijkstra** when POIs are sparse: Runs single-source shortest paths
///   from each POI. Efficient when POIs are much fewer than total nodes.
///
pub fn distance_matrix(
  in graph: Graph(n, e),
  between points_of_interest: List(NodeId),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  matrix.distance_matrix(graph, points_of_interest, zero, add, compare)
}
