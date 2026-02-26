import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Lt}
import gleam/result
import yog/internal/heap
import yog/model.{type Graph, type NodeId}

/// Represents a path through the graph with its total weight.
pub type Path(e) {
  Path(nodes: List(NodeId), total_weight: e)
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
  let frontier =
    heap.new()
    |> heap.insert(#(zero, [start]), fn(a, b) {
      compare_frontier(a, b, compare)
    })

  do_dijkstra(graph, goal, frontier, dict.new(), add, compare)
}

fn do_dijkstra(
  graph: Graph(n, e),
  goal: NodeId,
  frontier: heap.Heap(#(e, List(NodeId))),
  visited: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(Path(e)) {
  case heap.find_min(frontier) {
    Error(Nil) -> None
    Ok(#(dist, [current, ..] as path)) -> {
      let rest_frontier =
        heap.delete_min(frontier, fn(a, b) { compare_frontier(a, b, compare) })
        |> result.unwrap(heap.new())

      case current == goal {
        True -> Some(Path(nodes: list.reverse(path), total_weight: dist))
        False -> {
          let should_explore = should_explore_node(visited, current, dist, compare)

          case should_explore {
            False ->
              do_dijkstra(graph, goal, rest_frontier, visited, add, compare)
            True -> {
              let new_visited = dict.insert(visited, current, dist)

              let next_frontier =
                model.successors(graph, current)
                |> list.fold(rest_frontier, fn(h, neighbor) {
                  let #(next_id, weight) = neighbor
                  heap.insert(
                    h,
                    #(add(dist, weight), [next_id, ..path]),
                    fn(a, b) { compare_frontier(a, b, compare) },
                  )
                })

              do_dijkstra(graph, goal, next_frontier, new_visited, add, compare)
            }
          }
        }
      }
    }
    Ok(_) -> None
  }
}

fn compare_frontier(
  a: #(e, List(NodeId)),
  b: #(e, List(NodeId)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Helper to determine if a node should be explored based on distance comparison.
/// Returns True if the node hasn't been visited or if the new distance is shorter.
fn should_explore_node(
  visited: Dict(NodeId, e),
  node: NodeId,
  new_dist: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  case dict.get(visited, node) {
    Ok(prev_dist) ->
      case compare(new_dist, prev_dist) {
        Lt -> True
        _ -> False
      }
    Error(Nil) -> True
  }
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
  let initial_f = h(start, goal)
  // Heap stores #(F_Score, Actual_Dist, Path)
  let frontier =
    heap.new()
    |> heap.insert(#(initial_f, zero, [start]), fn(a, b) { compare(a.0, b.0) })

  do_a_star(graph, goal, frontier, dict.new(), add, compare, h)
}

fn do_a_star(graph, goal, frontier, visited, add, compare, h) {
  case heap.find_min(frontier) {
    Error(Nil) -> None
    Ok(#(_, dist, [current, ..] as path)) -> {
      let rest_frontier =
        heap.delete_min(frontier, fn(a, b) { compare(a.0, b.0) })
        |> result.unwrap(heap.new())

      case current == goal {
        True -> Some(Path(nodes: list.reverse(path), total_weight: dist))
        False -> {
          // G-SAFE BRANCHING (No guards)
          let should_explore = should_explore_node(visited, current, dist, compare)

          case should_explore {
            False ->
              do_a_star(graph, goal, rest_frontier, visited, add, compare, h)
            True -> {
              let new_visited = dict.insert(visited, current, dist)
              let next_frontier =
                model.successors(graph, current)
                |> list.fold(rest_frontier, fn(acc_h, neighbor) {
                  let #(next_id, weight) = neighbor
                  let next_dist = add(dist, weight)
                  let f_score = add(next_dist, h(next_id, goal))
                  heap.insert(
                    acc_h,
                    #(f_score, next_dist, [next_id, ..path]),
                    fn(a, b) { compare(a.0, b.0) },
                  )
                })
              do_a_star(
                graph,
                goal,
                next_frontier,
                new_visited,
                add,
                compare,
                h,
              )
            }
          }
        }
      }
    }
    _ -> None
  }
}

// ======================== BELLMAN-FORD ========================

/// Result type for Bellman-Ford algorithm.
pub type BellmanFordResult(e) {
  /// A shortest path was found successfully
  ShortestPath(path: Path(e))
  /// A negative cycle was detected (reachable from source)
  NegativeCycle
  /// No path exists from start to goal
  NoPath
}

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
  // Get all nodes
  let all_nodes = model.all_nodes(graph)

  // Initialize distances: start=0, others=infinity (represented as None)
  let initial_distances = dict.from_list([#(start, zero)])
  let initial_predecessors = dict.new()

  // Run V-1 iterations of edge relaxation
  let node_count = list.length(all_nodes)
  let #(distances, predecessors) =
    relaxation_passes(
      graph,
      all_nodes,
      initial_distances,
      initial_predecessors,
      node_count - 1,
      add,
      compare,
    )

  // Check for negative cycles
  case has_negative_cycle(graph, all_nodes, distances, add, compare) {
    True -> NegativeCycle
    False -> {
      // Reconstruct path
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

fn relaxation_passes(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  predecessors: Dict(NodeId, NodeId),
  remaining: Int,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> #(Dict(NodeId, e), Dict(NodeId, NodeId)) {
  case remaining <= 0 {
    True -> #(distances, predecessors)
    False -> {
      // Relax all edges
      let #(new_distances, new_predecessors) =
        list.fold(nodes, #(distances, predecessors), fn(acc, u) {
          let #(dists, preds) = acc

          case dict.get(dists, u) {
            Error(Nil) -> acc
            Ok(u_dist) -> {
              // Get all outgoing edges from u
              let neighbors = model.successors(graph, u)

              list.fold(neighbors, #(dists, preds), fn(inner_acc, edge) {
                let #(v, weight) = edge
                let #(curr_dists, curr_preds) = inner_acc
                let new_dist = add(u_dist, weight)

                case dict.get(curr_dists, v) {
                  Error(Nil) ->
                    // v not reached yet, update it
                    #(
                      dict.insert(curr_dists, v, new_dist),
                      dict.insert(curr_preds, v, u),
                    )
                  Ok(v_dist) ->
                    case compare(new_dist, v_dist) {
                      Lt ->
                        // Found shorter path
                        #(
                          dict.insert(curr_dists, v, new_dist),
                          dict.insert(curr_preds, v, u),
                        )
                      _ -> inner_acc
                    }
                }
              })
            }
          }
        })

      relaxation_passes(
        graph,
        nodes,
        new_distances,
        new_predecessors,
        remaining - 1,
        add,
        compare,
      )
    }
  }
}

fn has_negative_cycle(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Bool {
  // Try to relax edges one more time
  // If any edge can still be relaxed, there's a negative cycle
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

fn reconstruct_path(
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
