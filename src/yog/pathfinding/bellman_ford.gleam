//// [Bellman-Ford algorithm](https://en.wikipedia.org/wiki/Bellman%E2%80%93Ford_algorithm) for 
//// single-source shortest paths with support for negative edge weights.
////
//// The Bellman-Ford algorithm finds shortest paths from a source node to all other nodes,
//// even when edges have negative weights. It can also detect negative cycles reachable
//// from the source, which make shortest paths undefined.
////
//// ## Algorithm
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | [Bellman-Ford](https://en.wikipedia.org/wiki/Bellman%E2%80%93Ford_algorithm) | `bellman_ford/6` | O(VE) | Negative weights, cycle detection |
//// | SPFA (Queue-optimized) | `bellman_ford/6` | O(E) average | Sparse graphs with few negative edges |
//// | Implicit Bellman-Ford | `implicit_bellman_ford/6` | O(VE) | Implicit/large graphs |
////
//// ## Key Concepts
////
//// - **Relaxation**: Repeatedly improve distance estimates (V-1 passes)
//// - **Negative Cycle**: Cycle with total negative weight (no shortest path exists)
//// - **Shortest Path Tree**: Tree of shortest paths from source to all nodes
////
//// ## Why V-1 Relaxation Passes?
////
//// In a graph with V nodes, any shortest path has at most V-1 edges.
//// Each pass of Bellman-Ford relaxes all edges, propagating shortest
//// path information one hop further each time.
////
//// ## Comparison with Dijkstra
////
//// | Feature | Bellman-Ford | Dijkstra |
//// |---------|--------------|----------|
//// | Negative weights | ✅ Yes | ❌ No |
//// | Negative cycle detection | ✅ Yes | ❌ N/A |
//// | Time complexity | O(VE) | O((V+E) log V) |
//// | Data structure | Simple loops | Priority queue |
////
//// ## When to Use Bellman-Ford
////
//// **Use Bellman-Ford when:**
//// - Edge weights may be negative
//// - You need to detect negative cycles
//// - The graph is small or sparse enough for O(VE)
////
//// **Use Dijkstra when:**
//// - All edge weights are non-negative
//// - You need better performance
////
//// ## Use Cases
////
//// - **Currency arbitrage**: Detecting negative cycles in exchange rates
//// - **Financial modeling**: Cost calculations with credits/penalties
//// - **Chemical reactions**: Energy changes with positive and negative values
//// - **Constraint solving**: Difference constraints systems
////
//// ## History
////
//// Published independently by Richard Bellman (1958) and Lester Ford Jr. (1956).
//// The algorithm is a classic example of dynamic programming.
////
//// ## References
////
//// - [Wikipedia: Bellman-Ford Algorithm](https://en.wikipedia.org/wiki/Bellman%E2%80%93Ford_algorithm)
//// - [Wikipedia: Shortest Path Faster Algorithm (SPFA)](https://en.wikipedia.org/wiki/Shortest_Path_Faster_Algorithm)
//// - [CP-Algorithms: Bellman-Ford](https://cp-algorithms.com/graph/bellman_ford.html)
//// - [CS 170: Bellman-Ford Lecture](https://cs170.org/lecture-notes/)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order, Lt}
import gleam/result
import gleam/set
import yog/internal/queue
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/util.{type Path, Path}

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

/// Finds shortest path with support for negative edge weights using Bellman-Ford.
///
/// **Time Complexity:** O(VE)
///
/// ## Returns
///
/// - `ShortestPath(path)`: If a valid shortest path exists
/// - `NegativeCycle`: If a negative cycle is reachable from the start node
/// - `NoPath`: If no path exists from start to goal
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn bellman_ford(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> BellmanFordResult(e) {
  let all_nodes = model.all_nodes(graph)

  let initial_distances = dict.from_list([#(start, zero)])
  let initial_predecessors = dict.new()

  let node_count = list.length(all_nodes)
  let #(distances, predecessors) =
    relaxation_passes(
      graph,
      all_nodes,
      initial_distances,
      initial_predecessors,
      node_count - 1,
      with_add: add,
      with_compare: compare,
    )

  case
    has_negative_cycle(
      graph,
      all_nodes,
      distances,
      with_add: add,
      with_compare: compare,
    )
  {
    True -> NegativeCycle
    False -> {
      case dict.get(distances, goal) {
        Error(Nil) -> NoPath
        Ok(dist) -> {
          case reconstruct_path(predecessors, start, goal, [goal]) {
            Ok(path) -> ShortestPath(Path(nodes: path, total_weight: dist))
            Error(Nil) -> NoPath
          }
        }
      }
    }
  }
}

pub fn relaxation_passes(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  predecessors: Dict(NodeId, NodeId),
  remaining: Int,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> #(Dict(NodeId, e), Dict(NodeId, NodeId)) {
  case remaining <= 0 {
    True -> #(distances, predecessors)
    False -> {
      let #(new_distances, new_predecessors, relaxed_any) =
        list.fold(nodes, #(distances, predecessors, False), fn(acc, u) {
          let #(dists, preds, changed) = acc

          case dict.get(dists, u) {
            Error(Nil) -> acc
            Ok(u_dist) -> {
              let neighbors = model.successors(graph, u)

              list.fold(
                neighbors,
                #(dists, preds, changed),
                fn(inner_acc, edge) {
                  let #(v, weight) = edge
                  let #(curr_dists, curr_preds, _) = inner_acc
                  let new_dist = add(u_dist, weight)

                  case dict.get(curr_dists, v) {
                    Error(Nil) -> #(
                      dict.insert(curr_dists, v, new_dist),
                      dict.insert(curr_preds, v, u),
                      True,
                    )
                    Ok(v_dist) ->
                      case compare(new_dist, v_dist) {
                        Lt -> #(
                          dict.insert(curr_dists, v, new_dist),
                          dict.insert(curr_preds, v, u),
                          True,
                        )
                        _ -> inner_acc
                      }
                  }
                },
              )
            }
          }
        })

      case relaxed_any {
        False -> #(new_distances, new_predecessors)
        True ->
          relaxation_passes(
            graph,
            nodes,
            new_distances,
            new_predecessors,
            remaining - 1,
            with_add: add,
            with_compare: compare,
          )
      }
    }
  }
}

pub fn has_negative_cycle(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Bool {
  list.any(nodes, fn(u) {
    case dict.get(distances, u) {
      Error(Nil) -> False
      Ok(u_dist) -> {
        model.successors(graph, u)
        |> list.any(fn(edge) {
          let #(v, weight) = edge
          let new_dist = add(u_dist, weight)

          case dict.get(distances, v) {
            Error(Nil) -> False
            Ok(v_dist) ->
              case compare(new_dist, v_dist) {
                Lt -> True
                _ -> False
              }
          }
        })
      }
    }
  })
}

pub fn reconstruct_path(
  predecessors: Dict(NodeId, NodeId),
  start: NodeId,
  current: NodeId,
  acc: List(NodeId),
) -> Result(List(NodeId), Nil) {
  case current == start {
    True -> Ok(acc)
    False -> {
      case dict.get(predecessors, current) {
        Error(Nil) -> Error(Nil)
        Ok(pred) -> reconstruct_path(predecessors, start, pred, [pred, ..acc])
      }
    }
  }
}

/// Finds shortest path in implicit graphs with support for negative edge weights.
///
/// **Time Complexity:** O(VE) average case
///
/// ## Returns
///
/// - `FoundGoal(cost)`: If a valid shortest path to goal exists
/// - `DetectedNegativeCycle`: If a negative cycle is reachable from start
/// - `NoGoal`: If no goal state is reached
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two costs
/// - `compare`: Function to compare two costs
pub fn implicit_bellman_ford(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> ImplicitBellmanFordResult(cost) {
  do_implicit_bellman_ford(
    queue.new() |> queue.push(start),
    dict.from_list([#(start, zero)]),
    dict.from_list([#(start, 0)]),
    set.new(),
    successors,
    is_goal,
    zero,
    add,
    compare,
  )
}

fn do_implicit_bellman_ford(
  q: queue.Queue(state),
  distances: Dict(state, cost),
  relax_counts: Dict(state, Int),
  in_queue: set.Set(state),
  successors: fn(state) -> List(#(state, cost)),
  is_goal: fn(state) -> Bool,
  zero: cost,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> ImplicitBellmanFordResult(cost) {
  case queue.pop(q) {
    Error(Nil) -> {
      distances
      |> dict.to_list()
      |> list.filter(fn(entry) { is_goal(entry.0) })
      |> list.sort(fn(a, b) { compare(a.1, b.1) })
      |> list.first()
      |> result.map(fn(entry) { FoundGoal(entry.1) })
      |> result.unwrap(NoGoal)
    }
    Ok(#(current, rest_queue)) -> {
      let new_in_queue = set.delete(in_queue, current)
      let current_dist = dict.get(distances, current) |> result.unwrap(zero)

      let #(new_distances, new_counts, new_queue, new_in_q) =
        successors(current)
        |> list.fold(
          #(distances, relax_counts, rest_queue, new_in_queue),
          fn(acc, neighbor) {
            let #(dists, counts, q_acc, in_q_acc) = acc
            let #(next_state, edge_cost) = neighbor
            let new_dist = add(current_dist, edge_cost)

            case dict.get(dists, next_state) {
              Ok(prev_dist) ->
                case compare(new_dist, prev_dist) {
                  Lt -> {
                    let updated_dists = dict.insert(dists, next_state, new_dist)
                    let relax_count =
                      dict.get(counts, next_state) |> result.unwrap(0)
                    let new_count = relax_count + 1
                    let updated_counts =
                      dict.insert(counts, next_state, new_count)
                    case new_count > dict.size(dists) {
                      True -> #(updated_dists, updated_counts, q_acc, in_q_acc)
                      False -> {
                        case set.contains(in_q_acc, next_state) {
                          True -> #(
                            updated_dists,
                            updated_counts,
                            q_acc,
                            in_q_acc,
                          )
                          False -> #(
                            updated_dists,
                            updated_counts,
                            queue.push(q_acc, next_state),
                            set.insert(in_q_acc, next_state),
                          )
                        }
                      }
                    }
                  }
                  _ -> acc
                }
              Error(Nil) -> {
                let updated_dists = dict.insert(dists, next_state, new_dist)
                let updated_counts = dict.insert(counts, next_state, 1)
                #(
                  updated_dists,
                  updated_counts,
                  queue.push(q_acc, next_state),
                  set.insert(in_q_acc, next_state),
                )
              }
            }
          },
        )

      let has_negative_cycle =
        new_counts
        |> dict.to_list()
        |> list.any(fn(entry) { entry.1 > dict.size(new_distances) })

      case has_negative_cycle {
        True -> DetectedNegativeCycle
        False ->
          do_implicit_bellman_ford(
            new_queue,
            new_distances,
            new_counts,
            new_in_q,
            successors,
            is_goal,
            zero,
            add,
            compare,
          )
      }
    }
  }
}

/// Like `implicit_bellman_ford`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// The `visited_by` function extracts the deduplication key from each state.
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
  let start_key = key_fn(start)
  do_implicit_bellman_ford_by(
    queue.new() |> queue.push(start),
    dict.from_list([#(start_key, #(zero, start))]),
    dict.from_list([#(start_key, 0)]),
    set.new(),
    successors,
    key_fn,
    is_goal,
    zero,
    add,
    compare,
  )
}

fn do_implicit_bellman_ford_by(
  q: queue.Queue(state),
  distances: Dict(key, #(cost, state)),
  relax_counts: Dict(key, Int),
  in_queue: set.Set(state),
  successors: fn(state) -> List(#(state, cost)),
  key_fn: fn(state) -> key,
  is_goal: fn(state) -> Bool,
  zero: cost,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> ImplicitBellmanFordResult(cost) {
  case queue.pop(q) {
    Error(Nil) -> {
      distances
      |> dict.to_list()
      |> list.filter(fn(entry) { is_goal(entry.1.1) })
      |> list.sort(fn(a, b) { compare(a.1.0, b.1.0) })
      |> list.first()
      |> result.map(fn(entry) { FoundGoal(entry.1.0) })
      |> result.unwrap(NoGoal)
    }
    Ok(#(current, rest_queue)) -> {
      let current_key = key_fn(current)
      let new_in_queue = set.delete(in_queue, current)
      let #(current_dist, _) =
        dict.get(distances, current_key) |> result.unwrap(#(zero, current))

      let #(new_distances, new_counts, new_queue, new_in_q) =
        successors(current)
        |> list.fold(
          #(distances, relax_counts, rest_queue, new_in_queue),
          fn(acc, neighbor) {
            let #(dists, counts, q_acc, in_q_acc) = acc
            let #(next_state, edge_cost) = neighbor
            let next_key = key_fn(next_state)
            let new_dist = add(current_dist, edge_cost)

            case dict.get(dists, next_key) {
              Ok(#(prev_dist, _)) ->
                case compare(new_dist, prev_dist) {
                  Lt -> {
                    let updated_dists =
                      dict.insert(dists, next_key, #(new_dist, next_state))
                    let relax_count =
                      dict.get(counts, next_key) |> result.unwrap(0)
                    let new_count = relax_count + 1
                    let updated_counts =
                      dict.insert(counts, next_key, new_count)
                    case new_count > dict.size(dists) {
                      True -> #(updated_dists, updated_counts, q_acc, in_q_acc)
                      False -> {
                        case set.contains(in_q_acc, next_state) {
                          True -> #(
                            updated_dists,
                            updated_counts,
                            q_acc,
                            in_q_acc,
                          )
                          False -> #(
                            updated_dists,
                            updated_counts,
                            queue.push(q_acc, next_state),
                            set.insert(in_q_acc, next_state),
                          )
                        }
                      }
                    }
                  }
                  _ -> acc
                }
              Error(Nil) -> {
                let updated_dists =
                  dict.insert(dists, next_key, #(new_dist, next_state))
                let updated_counts = dict.insert(counts, next_key, 1)
                #(
                  updated_dists,
                  updated_counts,
                  queue.push(q_acc, next_state),
                  set.insert(in_q_acc, next_state),
                )
              }
            }
          },
        )

      let has_negative_cycle =
        new_counts
        |> dict.to_list()
        |> list.any(fn(entry) { entry.1 > dict.size(new_distances) })

      case has_negative_cycle {
        True -> DetectedNegativeCycle
        False ->
          do_implicit_bellman_ford_by(
            new_queue,
            new_distances,
            new_counts,
            new_in_q,
            successors,
            key_fn,
            is_goal,
            zero,
            add,
            compare,
          )
      }
    }
  }
}

// -----------------------------------------------------------------------------
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// -----------------------------------------------------------------------------

/// Finds shortest path with **integer weights**, handling negative edges.
///
/// This is a convenience wrapper around `bellman_ford` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
///
/// ## Example
///
/// ```gleam
/// bellman_ford.bellman_ford_int(graph, from: 1, to: 5)
/// // => ShortestPath(Path([1, 2, 5], 15))
/// ```
///
/// ## When to Use
///
/// Use this for graphs with `Int` edge weights that may be negative (arbitrage
/// detection, time-dependent costs, etc.). For graphs with only non-negative
/// weights, prefer `dijkstra.shortest_path_int` which is faster.
pub fn bellman_ford_int(
  in graph: Graph(n, Int),
  from start: NodeId,
  to goal: NodeId,
) -> BellmanFordResult(Int) {
  bellman_ford(
    graph,
    start,
    goal,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
  )
}

/// Finds shortest path with **float weights**, handling negative edges.
///
/// This is a convenience wrapper around `bellman_ford` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
///
/// ## Warning
///
/// Float arithmetic has precision limitations. Negative cycles might not be
/// detected reliably due to floating-point errors. Prefer `Int` weights for
/// critical calculations.
pub fn bellman_ford_float(
  in graph: Graph(n, Float),
  from start: NodeId,
  to goal: NodeId,
) -> BellmanFordResult(Float) {
  bellman_ford(
    graph,
    start,
    goal,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
  )
}
