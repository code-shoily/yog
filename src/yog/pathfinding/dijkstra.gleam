//// [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) for 
//// single-source shortest paths in graphs with non-negative edge weights.
////
//// Dijkstra's algorithm finds the shortest path from a source node to all other reachable
//// nodes in a graph. It works by maintaining a priority queue of nodes to visit,
//// always expanding the node with the smallest known distance.
////
//// ## Algorithm
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | [Dijkstra](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) (single-target) | `shortest_path/6` | O((V + E) log V) | One-to-one shortest path |
//// | [Dijkstra](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) (single-source) | `single_source_distances/5` | O((V + E) log V) | One-to-all shortest paths |
//// | Implicit Dijkstra | `implicit_dijkstra/6` | O((V + E) log V) | Large/infinite graphs |
////
//// ## Key Concepts
////
//// - **Greedy Strategy**: Always expands the node with minimum tentative distance
//// - **Priority Queue**: Min-heap ordered by current best distance
//// - **Relaxation**: Update distances when a shorter path is found
//// - **Non-Negative Weights**: Required for correctness (use Bellman-Ford for negative weights)
////
//// ## Comparison with Other Algorithms
////
//// | Algorithm | Handles Negative Weights | Complexity | Use Case |
//// |-----------|-------------------------|------------|----------|
//// | Dijkstra | ❌ No | O((V+E) log V) | General shortest paths |
//// | A* | ❌ No | O((V+E) log V) | When good heuristic available |
//// | Bellman-Ford | ✅ Yes | O(VE) | Negative weights, cycle detection |
//// | Floyd-Warshall | ✅ Yes | O(V³) | All-pairs shortest paths |
////
//// ## History
////
//// Edsger W. Dijkstra published this algorithm in 1959. The original paper described
//// it for finding the shortest path between two nodes, but it's commonly used for
//// single-source shortest paths to all nodes.
////
//// ## Use Cases
////
//// - **Network routing**: OSPF, IS-IS protocols use Dijkstra
//// - **Map services**: Shortest driving directions
//// - **Social networks**: Degrees of separation
//// - **Game development**: Shortest path on weighted grids
////
//// ## References
////
//// - [Wikipedia: Dijkstra's Algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)
//// - [Dijkstra's Original Paper (1959)](https://link.springer.com/article/10.1007/BF01386390)
//// - [Red Blob Games: Dijkstra Introduction](https://www.redblobgames.com/pathfinding/a-star/introduction.html)
//// - [CP-Algorithms: Dijkstra](https://cp-algorithms.com/graph/dijkstra.html)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/order.{type Order}
import yog/internal/priority_queue
import yog/internal/util.{compare_distance_frontier, should_explore_node}
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/a_star
import yog/pathfinding/path.{type Path}
import yog/traversal.{type WalkControl}

/// Finds the shortest path between two nodes using Dijkstra's algorithm.
///
/// Works with non-negative edge weights only.
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
/// dijkstra.shortest_path(
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
  a_star.a_star(
    in: graph,
    from: start,
    to: goal,
    with_zero: zero,
    with_add: add,
    with_compare: compare,
    with_heuristic: fn(_, _) { zero },
  )
}

/// Computes shortest distances from a source node to all reachable nodes.
///
/// Returns a dictionary mapping each reachable node to its shortest distance
/// from the source. Unreachable nodes are not included in the result.
///
/// **Time Complexity:** O((V + E) log V) with heap
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn single_source_distances(
  in graph: Graph(n, e),
  from source: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dict(NodeId, e) {
  let frontier =
    priority_queue.new(fn(a, b) { compare_distance_frontier(a, b, compare) })
    |> priority_queue.push(#(zero, source))

  do_single_source_dijkstra(graph, frontier, dict.new(), add, compare)
}

fn do_single_source_dijkstra(
  graph: Graph(n, e),
  frontier: priority_queue.Queue(#(e, NodeId)),
  distances: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Dict(NodeId, e) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> distances
    Ok(#(#(dist, current), rest_frontier)) -> {
      let should_explore =
        should_explore_node(distances, current, dist, compare)

      case should_explore {
        False ->
          do_single_source_dijkstra(
            graph,
            rest_frontier,
            distances,
            add,
            compare,
          )
        True -> {
          let new_distances = dict.insert(distances, current, dist)

          let next_frontier =
            model.successors(graph, current)
            |> list.fold(rest_frontier, fn(h, neighbor) {
              let #(next_id, weight) = neighbor
              priority_queue.push(h, #(add(dist, weight), next_id))
            })

          do_single_source_dijkstra(
            graph,
            next_frontier,
            new_distances,
            add,
            compare,
          )
        }
      }
    }
  }
}

/// Finds the shortest path in an implicit graph using Dijkstra's algorithm.
///
/// Instead of a materialized `Graph`, this uses a `successors_with_cost` function
/// to compute weighted neighbors on demand.
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
pub fn implicit_dijkstra(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  a_star.implicit_a_star(
    from: start,
    successors_with_cost: successors,
    is_goal: is_goal,
    with_heuristic: fn(_) { zero },
    with_zero: zero,
    with_add: add,
    with_compare: compare,
  )
}

/// Like `implicit_dijkstra`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// The `visited_by` function extracts the deduplication key from each state.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
pub fn implicit_dijkstra_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  a_star.implicit_a_star_by(
    from: start,
    successors_with_cost: successors,
    visited_by: key_fn,
    is_goal: is_goal,
    with_heuristic: fn(_) { zero },
    with_zero: zero,
    with_add: add,
    with_compare: compare,
  )
}

/// Folds over an implicit weighted graph using Dijkstra's algorithm.
///
/// Like `implicit_dijkstra` but visits nodes in order of increasing cost and
/// accumulates state. Provides control over traversal via `WalkControl`.
///
/// **Time Complexity:** O((V + E) log V)
pub fn fold(
  from start: nid,
  initial acc: a,
  successors_of successors: fn(nid) -> List(#(nid, e)),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with folder: fn(a, nid, e) -> #(WalkControl, a),
) -> a {
  let frontier =
    priority_queue.new(fn(a: #(e, nid), b: #(e, nid)) { compare(a.0, b.0) })
    |> priority_queue.push(#(zero, start))

  do_fold(frontier, dict.new(), acc, successors, add, compare, folder)
}

fn do_fold(frontier, best, acc, successors, add, compare, folder) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> acc
    Ok(#(#(cost, node), rest)) -> {
      let is_stale = case dict.get(best, node) {
        Ok(prev) -> compare(prev, cost) != order.Gt
        _ -> False
      }

      case is_stale {
        True -> do_fold(rest, best, acc, successors, add, compare, folder)
        False -> {
          let new_best = dict.insert(best, node, cost)
          let #(control, new_acc) = folder(acc, node, cost)
          case control {
            traversal.Halt -> new_acc
            traversal.Stop ->
              do_fold(rest, new_best, new_acc, successors, add, compare, folder)
            traversal.Continue -> {
              let next_frontier =
                list.fold(successors(node), rest, fn(q, neighbor) {
                  let #(nb_node, edge_cost) = neighbor
                  let new_cost = add(cost, edge_cost)
                  let is_worse = case dict.get(new_best, nb_node) {
                    Ok(prev_cost) -> compare(prev_cost, new_cost) != order.Gt
                    _ -> False
                  }
                  case is_worse {
                    True -> q
                    False -> priority_queue.push(q, #(new_cost, nb_node))
                  }
                })
              do_fold(
                next_frontier,
                new_best,
                new_acc,
                successors,
                add,
                compare,
                folder,
              )
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// ============================================================================

/// Finds the shortest path using **integer weights**.
///
/// This is a convenience wrapper around `shortest_path` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
///
/// ## Example
///
/// ```gleam
/// // Much cleaner than the full explicit version
/// dijkstra.shortest_path_int(graph, from: 1, to: 5)
/// // => Some(Path([1, 2, 5], 15))
///
/// // Equivalent explicit call:
/// // dijkstra.shortest_path(
/// //   graph, from: 1, to: 5,
/// //   with_zero: 0,
/// //   with_add: int.add,
/// //   with_compare: int.compare
/// // )
/// ```
///
/// ## When to Use
///
/// Use this for graphs with `Int` edge weights (hop counts, distances in meters,
/// costs in cents, etc.). For custom weight types (Money, Distance, etc.), use
/// the full `shortest_path` function with your own semiring operations.
pub fn shortest_path_int(
  in graph: Graph(n, Int),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  shortest_path(
    graph,
    start,
    goal,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
  )
}

/// Finds the shortest path using **float weights**.
///
/// This is a convenience wrapper around `shortest_path` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
///
/// ## Example
///
/// ```gleam
/// dijkstra.shortest_path_float(graph, from: 1, to: 5)
/// // => Some(Path([1, 2, 5], 15.5))
/// ```
///
/// ## When to Use
///
/// Use this for graphs with `Float` edge weights (probabilities, distances in
/// kilometers with decimal precision, continuous costs, etc.). Note that float
/// arithmetic has precision limitations - for exact calculations, prefer `Int`
/// weights (e.g., store cents instead of dollars).
pub fn shortest_path_float(
  in graph: Graph(n, Float),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Float)) {
  shortest_path(
    graph,
    start,
    goal,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
  )
}

/// Computes shortest distances using **integer weights**.
///
/// Convenience wrapper for `single_source_distances` with `Int` weights.
pub fn single_source_distances_int(
  in graph: Graph(n, Int),
  from source: NodeId,
) -> Dict(NodeId, Int) {
  single_source_distances(
    graph,
    source,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
  )
}

/// Computes shortest distances using **float weights**.
///
/// Convenience wrapper for `single_source_distances` with `Float` weights.
pub fn single_source_distances_float(
  in graph: Graph(n, Float),
  from source: NodeId,
) -> Dict(NodeId, Float) {
  single_source_distances(
    graph,
    source,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
  )
}
