//// [A* (A-Star)](https://en.wikipedia.org/wiki/A*_search_algorithm) search algorithm 
//// for optimal pathfinding with heuristic guidance.
////
//// A* is an informed search algorithm that finds the shortest path from a start node
//// to a goal node using a heuristic function to guide exploration. It combines the
//// completeness of Dijkstra's algorithm with the efficiency of greedy best-first search.
////
//// ## Algorithm
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | [A* Search](https://en.wikipedia.org/wiki/A*_search_algorithm) | `a_star/7` | O((V + E) log V) | Pathfinding with good heuristics |
//// | Implicit A* | `implicit_a_star/7` | O((V + E) log V) | Large/infinite graphs generated on-demand |
////
//// ## Key Concepts
////
//// - **Evaluation Function**: f(n) = g(n) + h(n)
////   - g(n): Actual cost from start to node n
////   - h(n): Heuristic estimate from n to goal
////   - f(n): Estimated total cost through n
//// - **Admissible Heuristic**: h(n) ≤ actual cost (never overestimates)
//// - **Consistent Heuristic**: h(n) ≤ cost(n→n') + h(n') (triangle inequality)
////
//// ## When to Use A*
////
//// **Use A* when:**
//// - You have a specific goal node (not single-source to all)
//// - You can provide a good heuristic estimate
//// - The heuristic is admissible (underestimates)
////
//// **Use Dijkstra when:**
//// - No good heuristic available (h(n) = 0 reduces A* to Dijkstra)
//// - You need shortest paths to all nodes from a source
////
//// ## Heuristic Examples
////
//// | Domain | Heuristic | Admissible? |
//// |--------|-----------|-------------|
//// | Grid (4-way) | Manhattan distance | Yes |
//// | Grid (8-way) | Chebyshev distance | Yes |
//// | Geospatial | Haversine/great-circle | Yes |
//// | Road networks | Precomputed landmarks | Yes |
////
//// ## Use Cases
////
//// - **Video games**: NPC pathfinding on game maps
//// - **GPS navigation**: Route planning with distance estimates
//// - **Robotics**: Motion planning with obstacle avoidance
//// - **Puzzle solving**: Sliding puzzles, mazes, labyrinths
////
//// ## References
////
//// - [Wikipedia: A* Search Algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm)
//// - [Red Blob Games: A* Implementation](https://www.redblobgames.com/pathfinding/a-star/introduction.html)
//// - [Stanford CS161: A* Lecture](https://web.stanford.edu/class/cs161/lectures/lecture20.pdf)
//// - [CP-Algorithms: A*](https://cp-algorithms.com/graph/A-star.html)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import yog/internal/priority_queue
import yog/internal/util.{compare_a_star_frontier, should_explore_node}
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/path.{type Path, Path}

/// Finds the shortest path using A* search with a heuristic function.
///
/// A* is more efficient than Dijkstra when you have a good heuristic estimate
/// of the remaining distance to the goal.
///
/// **Time Complexity:** O((V + E) log V)
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
/// - `heuristic`: A function that estimates distance from any node to the goal.
///   Must be admissible (h(n) ≤ actual distance).
pub fn a_star(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_heuristic h: fn(NodeId, NodeId) -> e,
) -> Option(Path(e)) {
  let initial_f = h(start, goal)
  let frontier =
    priority_queue.new(fn(a, b) { compare_a_star_frontier(a, b, compare) })
    |> priority_queue.push(#(initial_f, zero, [start]))

  do_a_star(graph, goal, frontier, dict.new(), add, compare, h)
  |> option.map(fn(res) {
    let #(dist, path) = res
    Path(nodes: list.reverse(path), total_weight: dist)
  })
}

fn do_a_star(
  graph,
  goal,
  frontier,
  visited,
  add,
  compare,
  h,
) -> Option(#(e, List(NodeId))) {
  case priority_queue.pop(frontier) {
    Ok(#(#(_, dist, [current, ..] as path), _)) if current == goal ->
      Some(#(dist, path))

    Ok(#(#(_, dist, [current, ..] as path), rest_frontier)) ->
      case should_explore_node(visited, current, dist, compare) {
        False -> do_a_star(graph, goal, rest_frontier, visited, add, compare, h)
        True -> {
          let new_visited = dict.insert(visited, current, dist)
          let successors = model.successors(graph, current)

          let next_frontier = {
            use acc_h, neighbor <- list.fold(successors, rest_frontier)
            let #(next_id, weight) = neighbor
            let next_dist = add(dist, weight)

            case should_explore_node(new_visited, next_id, next_dist, compare) {
              True -> {
                let f_score = add(next_dist, h(next_id, goal))
                priority_queue.push(
                  acc_h,
                  #(f_score, next_dist, [next_id, ..path]),
                )
              }
              False -> acc_h
            }
          }

          do_a_star(graph, goal, next_frontier, new_visited, add, compare, h)
        }
      }

    _ -> None
  }
}

/// Finds the shortest path in an implicit graph using A* search with a heuristic.
///
/// **Time Complexity:** O((V + E) log V)
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two costs
/// - `compare`: Function to compare two costs
/// - `heuristic`: Function that estimates remaining cost from any state to goal.
///   Must be admissible.
pub fn implicit_a_star(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  implicit_a_star_by(
    from: start,
    successors_with_cost: successors,
    visited_by: fn(s) { s },
    is_goal: is_goal,
    with_heuristic: h,
    with_zero: zero,
    with_add: add,
    with_compare: compare,
  )
}

/// Like `implicit_a_star`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// The `visited_by` function extracts the deduplication key from each state.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
pub fn implicit_a_star_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  with_heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  let initial_f = h(start)
  let frontier =
    priority_queue.new(fn(a: #(cost, cost, state), b: #(cost, cost, state)) {
      compare(a.0, b.0)
    })
    |> priority_queue.push(#(initial_f, zero, start))

  do_implicit_a_star_by(
    frontier,
    dict.new(),
    successors,
    key_fn,
    is_goal,
    h,
    add,
    compare,
  )
}

fn do_implicit_a_star_by(
  frontier: priority_queue.Queue(#(cost, cost, state)),
  distances: Dict(key, cost),
  successors: fn(state) -> List(#(state, cost)),
  key_fn: fn(state) -> key,
  is_goal: fn(state) -> Bool,
  h: fn(state) -> cost,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  case priority_queue.pop(frontier) {
    Ok(#(#(_, dist, current), rest_frontier)) -> {
      case is_goal(current) {
        True -> Some(dist)
        False -> {
          let current_key = key_fn(current)
          case should_explore_node(distances, current_key, dist, compare) {
            False ->
              do_implicit_a_star_by(
                rest_frontier,
                distances,
                successors,
                key_fn,
                is_goal,
                h,
                add,
                compare,
              )
            True -> {
              let new_distances = dict.insert(distances, current_key, dist)

              let next_frontier = {
                use frontier_acc, neighbor <- list.fold(
                  successors(current),
                  rest_frontier,
                )
                let #(next_state, edge_cost) = neighbor
                let next_dist = add(dist, edge_cost)
                let next_key = key_fn(next_state)

                case
                  should_explore_node(
                    new_distances,
                    next_key,
                    next_dist,
                    compare,
                  )
                {
                  True -> {
                    let f_score = add(next_dist, h(next_state))
                    priority_queue.push(frontier_acc, #(
                      f_score,
                      next_dist,
                      next_state,
                    ))
                  }
                  False -> frontier_acc
                }
              }

              do_implicit_a_star_by(
                next_frontier,
                new_distances,
                successors,
                key_fn,
                is_goal,
                h,
                add,
                compare,
              )
            }
          }
        }
      }
    }

    _ -> None
  }
}

// ============================================================================
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// ============================================================================

/// Finds the shortest path using A* with **integer weights**.
///
/// This is a convenience wrapper around `a_star` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
///
/// You still need to provide a heuristic function.
///
/// ## Example
///
/// ```gleam
/// // Grid distance heuristic (Manhattan distance)
/// let heuristic = fn(from, to) {
///   let dx = int.absolute_value(from.x - to.x)
///   let dy = int.absolute_value(from.y - to.y)
///   dx + dy
/// }
///
/// a_star.a_star_int(graph, from: start, to: goal, with_heuristic: heuristic)
/// ```
pub fn a_star_int(
  in graph: Graph(n, Int),
  from start: NodeId,
  to goal: NodeId,
  with_heuristic h: fn(NodeId, NodeId) -> Int,
) -> Option(Path(Int)) {
  a_star(
    in: graph,
    from: start,
    to: goal,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
    with_heuristic: h,
  )
}

/// Finds the shortest path using A* with **float weights**.
///
/// This is a convenience wrapper around `a_star` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
///
/// You still need to provide a heuristic function.
pub fn a_star_float(
  in graph: Graph(n, Float),
  from start: NodeId,
  to goal: NodeId,
  with_heuristic h: fn(NodeId, NodeId) -> Float,
) -> Option(Path(Float)) {
  a_star(
    in: graph,
    from: start,
    to: goal,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
    with_heuristic: h,
  )
}
