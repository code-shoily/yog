//// [Bidirectional search](https://en.wikipedia.org/wiki/Bidirectional_search) algorithms
//// that meet in the middle for dramatic speedup.
////
//// These algorithms start two simultaneous searches - one from the source
//// and one from the target - that meet in the middle. This can dramatically
//// reduce the search space compared to single-direction search.
////
//// ## Performance Benefits
////
//// For a graph with branching factor b and depth d:
//// - **Standard BFS**: O(b^d) nodes explored
//// - **Bidirectional BFS**: O(2 × b^(d/2)) nodes explored
////
//// **Example** with b=10, d=6:
//// - Standard: 10^6 = 1,000,000 nodes
//// - Bidirectional: 2 × 10^3 = 2,000 nodes (500× faster!)
////
//// ## Algorithms
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | Bidirectional BFS | `shortest_path_unweighted/3` | O(b^(d/2)) | Unweighted graphs |
//// | Bidirectional Dijkstra | `shortest_path/6` | O(b^(d/2) log b) | Weighted graphs |
////
//// ## Requirements
////
//// - Graph must be connected (otherwise no path exists)
//// - For directed graphs: needs efficient reverse edge lookup (yog's `in_edges` structure is perfect!)
//// - Target node must be known in advance
////
//// ## Termination
////
//// The tricky part of bidirectional search is knowing when to stop:
//// - **BFS**: Can stop as soon as frontiers touch
//// - **Dijkstra**: Must continue until minimum distances from both sides exceed best path found
////
//// ## References
////
//// - [Wikipedia: Bidirectional Search](https://en.wikipedia.org/wiki/Bidirectional_search)
//// - [Red Blob Games: Meeting in the Middle](https://www.redblobgames.com/pathfinding/a-star/introduction.html#bidirectional-search)
//// - [Ira Pohl (1971): Bi-directional Search](https://api.semanticscholar.org/CorpusID:60374980)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/set.{type Set}
import gleamy/priority_queue
import yog/internal/queue
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/utils.{type Path, Path, should_explore_node}

/// Result of a bidirectional search containing paths from both directions
type BiSearchState(e) {
  BiSearchState(
    // Distance and parent map from forward search
    forward_dist: Dict(NodeId, e),
    forward_parent: Dict(NodeId, NodeId),
    // Distance and parent map from backward search
    backward_dist: Dict(NodeId, e),
    backward_parent: Dict(NodeId, NodeId),
    // Meeting point (where paths intersect)
    meeting_point: Option(NodeId),
    // Best path length found so far
    best_length: Option(e),
  )
}

/// Finds the shortest path in an unweighted graph using bidirectional BFS.
///
/// This runs BFS from both source and target simultaneously, stopping when
/// the frontiers meet. Much faster than single-direction BFS for long paths.
///
/// **Time Complexity:** O(b^(d/2)) where b is branching factor and d is depth
///
/// ## Example
///
/// ```gleam
/// bidirectional.shortest_path_unweighted(
///   in: graph,
///   from: 1,
///   to: 100
/// )
/// // => Some(Path([1, 5, 20, 100], 3))
/// ```
pub fn shortest_path_unweighted(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  // Quick check for trivial case
  case start == goal {
    True -> Some(Path([start], 0))
    False -> {
      let initial_state =
        BiSearchState(
          forward_dist: dict.new() |> dict.insert(start, 0),
          forward_parent: dict.new(),
          backward_dist: dict.new() |> dict.insert(goal, 0),
          backward_parent: dict.new(),
          meeting_point: None,
          best_length: None,
        )

      let forward_queue = queue.new() |> queue.push(start)
      let backward_queue = queue.new() |> queue.push(goal)

      do_bidirectional_bfs(graph, forward_queue, backward_queue, initial_state)
      |> option.map(fn(state) {
        case state.meeting_point {
          Some(meeting) -> {
            let path =
              reconstruct_bidirectional_path(
                state.forward_parent,
                state.backward_parent,
                start,
                goal,
                meeting,
              )
            let length = case state.best_length {
              Some(len) -> len
              None -> list.length(path) - 1
            }
            Path(nodes: path, total_weight: length)
          }
          None -> Path(nodes: [], total_weight: 0)
        }
      })
    }
  }
}

fn do_bidirectional_bfs(
  graph: Graph(n, e),
  forward_queue: queue.Queue(NodeId),
  backward_queue: queue.Queue(NodeId),
  state: BiSearchState(Int),
) -> Option(BiSearchState(Int)) {
  // Check if we found a path
  case state.meeting_point {
    Some(_) -> Some(state)
    None -> {
      // Alternate between forward and backward search
      // Always expand the smaller frontier for better performance
      let forward_size = dict.size(state.forward_dist)
      let backward_size = dict.size(state.backward_dist)

      case forward_size <= backward_size {
        True -> {
          // Expand forward frontier
          case queue.pop(forward_queue) {
            Error(Nil) -> None
            Ok(#(current, rest_queue)) -> {
              let current_dist =
                dict.get(state.forward_dist, current)
                |> option.from_result
                |> option.unwrap(0)

              // Check if this node was reached from the other direction
              let new_state = case dict.has_key(state.backward_dist, current) {
                True -> {
                  let back_dist =
                    dict.get(state.backward_dist, current)
                    |> option.from_result
                    |> option.unwrap(0)
                  let total = current_dist + back_dist
                  BiSearchState(
                    ..state,
                    meeting_point: Some(current),
                    best_length: Some(total),
                  )
                }
                False -> state
              }

              // Expand neighbors
              let neighbors = model.successor_ids(graph, current)
              let #(next_state, next_queue) =
                list.fold(
                  neighbors,
                  #(new_state, rest_queue),
                  fn(acc, neighbor) {
                    let #(s, q) = acc
                    case dict.has_key(s.forward_dist, neighbor) {
                      True -> #(s, q)
                      False -> {
                        let updated_state =
                          BiSearchState(
                            ..s,
                            forward_dist: dict.insert(
                              s.forward_dist,
                              neighbor,
                              current_dist + 1,
                            ),
                            forward_parent: dict.insert(
                              s.forward_parent,
                              neighbor,
                              current,
                            ),
                          )
                        let updated_queue = queue.push(q, neighbor)

                        // Check if we met the backward search
                        case dict.has_key(s.backward_dist, neighbor) {
                          True -> {
                            let back_dist =
                              dict.get(s.backward_dist, neighbor)
                              |> option.from_result
                              |> option.unwrap(0)
                            let total = current_dist + 1 + back_dist
                            #(
                              BiSearchState(
                                ..updated_state,
                                meeting_point: Some(neighbor),
                                best_length: Some(total),
                              ),
                              updated_queue,
                            )
                          }
                          False -> #(updated_state, updated_queue)
                        }
                      }
                    }
                  },
                )

              do_bidirectional_bfs(
                graph,
                next_queue,
                backward_queue,
                next_state,
              )
            }
          }
        }
        False -> {
          // Expand backward frontier
          case queue.pop(backward_queue) {
            Error(Nil) -> None
            Ok(#(current, rest_queue)) -> {
              let current_dist =
                dict.get(state.backward_dist, current)
                |> option.from_result
                |> option.unwrap(0)

              // Check if this node was reached from the forward direction
              let new_state = case dict.has_key(state.forward_dist, current) {
                True -> {
                  let fwd_dist =
                    dict.get(state.forward_dist, current)
                    |> option.from_result
                    |> option.unwrap(0)
                  let total = fwd_dist + current_dist
                  BiSearchState(
                    ..state,
                    meeting_point: Some(current),
                    best_length: Some(total),
                  )
                }
                False -> state
              }

              // Expand predecessors (going backwards in directed graphs)
              let predecessors =
                model.predecessors(graph, current)
                |> list.map(fn(p) { p.0 })
              let #(next_state, next_queue) =
                list.fold(predecessors, #(new_state, rest_queue), fn(acc, pred) {
                  let #(s, q) = acc
                  case dict.has_key(s.backward_dist, pred) {
                    True -> #(s, q)
                    False -> {
                      let updated_state =
                        BiSearchState(
                          ..s,
                          backward_dist: dict.insert(
                            s.backward_dist,
                            pred,
                            current_dist + 1,
                          ),
                          backward_parent: dict.insert(
                            s.backward_parent,
                            pred,
                            current,
                          ),
                        )
                      let updated_queue = queue.push(q, pred)

                      // Check if we met the forward search
                      case dict.has_key(s.forward_dist, pred) {
                        True -> {
                          let fwd_dist =
                            dict.get(s.forward_dist, pred)
                            |> option.from_result
                            |> option.unwrap(0)
                          let total = fwd_dist + current_dist + 1
                          #(
                            BiSearchState(
                              ..updated_state,
                              meeting_point: Some(pred),
                              best_length: Some(total),
                            ),
                            updated_queue,
                          )
                        }
                        False -> #(updated_state, updated_queue)
                      }
                    }
                  }
                })

              do_bidirectional_bfs(graph, forward_queue, next_queue, next_state)
            }
          }
        }
      }
    }
  }
}

/// Reconstructs the path from bidirectional search by combining forward and backward paths
fn reconstruct_bidirectional_path(
  forward_parent: Dict(NodeId, NodeId),
  backward_parent: Dict(NodeId, NodeId),
  start: NodeId,
  goal: NodeId,
  meeting: NodeId,
) -> List(NodeId) {
  // Build forward path from start to meeting point (includes meeting)
  let forward_path = build_path_to_meeting(forward_parent, start, meeting, [])

  // Build backward path from meeting point to goal (excludes meeting)
  let backward_path =
    build_path_from_meeting(backward_parent, meeting, goal, [])

  // Combine: forward_path already includes meeting, backward_path doesn't
  list.append(forward_path, backward_path)
}

fn build_path_to_meeting(
  parent_map: Dict(NodeId, NodeId),
  start: NodeId,
  current: NodeId,
  acc: List(NodeId),
) -> List(NodeId) {
  case current == start {
    True -> [start, ..acc]
    False -> {
      case dict.get(parent_map, current) {
        Ok(parent) ->
          build_path_to_meeting(parent_map, start, parent, [current, ..acc])
        Error(Nil) -> [current, ..acc]
      }
    }
  }
}

fn build_path_from_meeting(
  parent_map: Dict(NodeId, NodeId),
  current: NodeId,
  goal: NodeId,
  acc: List(NodeId),
) -> List(NodeId) {
  case current == goal {
    True -> list.reverse(acc)
    False -> {
      case dict.get(parent_map, current) {
        Ok(child) ->
          build_path_from_meeting(parent_map, child, goal, [child, ..acc])
        Error(Nil) -> list.reverse(acc)
      }
    }
  }
}

/// Finds the shortest path in a weighted graph using bidirectional Dijkstra.
///
/// This is trickier than bidirectional BFS because we can't stop as soon
/// as the frontiers meet - we must continue until we can prove optimality.
///
/// **Time Complexity:** O((V + E) log V / 2) - approximately 2x faster than standard Dijkstra
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
/// bidirectional.shortest_path(
///   in: graph,
///   from: 1,
///   to: 100,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => Some(Path([1, 5, 20, 100], 42))
/// ```
pub fn shortest_path(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Option(Path(e)) {
  case start == goal {
    True -> Some(Path([start], zero))
    False -> {
      let initial_state =
        BiSearchState(
          forward_dist: dict.new() |> dict.insert(start, zero),
          forward_parent: dict.new(),
          backward_dist: dict.new() |> dict.insert(goal, zero),
          backward_parent: dict.new(),
          meeting_point: None,
          best_length: None,
        )

      let forward_frontier =
        priority_queue.new(fn(a: #(e, NodeId), b: #(e, NodeId)) {
          compare(a.0, b.0)
        })
        |> priority_queue.push(#(zero, start))

      let backward_frontier =
        priority_queue.new(fn(a: #(e, NodeId), b: #(e, NodeId)) {
          compare(a.0, b.0)
        })
        |> priority_queue.push(#(zero, goal))

      do_bidirectional_dijkstra(
        graph,
        forward_frontier,
        backward_frontier,
        set.new(),
        set.new(),
        initial_state,
        zero,
        add,
        compare,
      )
      |> option.map(fn(state) {
        case state.meeting_point, state.best_length {
          Some(meeting), Some(length) -> {
            let path =
              reconstruct_bidirectional_path(
                state.forward_parent,
                state.backward_parent,
                start,
                goal,
                meeting,
              )
            Path(nodes: path, total_weight: length)
          }
          _, _ -> Path(nodes: [], total_weight: zero)
        }
      })
    }
  }
}

fn do_bidirectional_dijkstra(
  graph: Graph(n, e),
  forward_frontier: priority_queue.Queue(#(e, NodeId)),
  backward_frontier: priority_queue.Queue(#(e, NodeId)),
  forward_settled: Set(NodeId),
  backward_settled: Set(NodeId),
  state: BiSearchState(e),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(BiSearchState(e)) {
  // Termination: if both frontiers are empty, return best path found
  case
    priority_queue.is_empty(forward_frontier),
    priority_queue.is_empty(backward_frontier)
  {
    True, True -> {
      case state.meeting_point {
        Some(_) -> Some(state)
        None -> None
      }
    }
    _, _ -> {
      // Check if we can terminate early
      case state.best_length {
        Some(best) -> {
          // Get minimum distances from both frontiers
          let fwd_min = priority_queue.peek(forward_frontier)
          let back_min = priority_queue.peek(backward_frontier)

          case fwd_min, back_min {
            Ok(#(fd, _)), Ok(#(bd, _)) -> {
              // If sum of minimums >= best path, we can stop
              let sum = add(fd, bd)
              case compare(sum, best) {
                order.Lt | order.Eq ->
                  expand_bidirectional(
                    graph,
                    forward_frontier,
                    backward_frontier,
                    forward_settled,
                    backward_settled,
                    state,
                    zero,
                    add,
                    compare,
                  )
                order.Gt -> Some(state)
              }
            }
            _, _ ->
              expand_bidirectional(
                graph,
                forward_frontier,
                backward_frontier,
                forward_settled,
                backward_settled,
                state,
                zero,
                add,
                compare,
              )
          }
        }
        None ->
          expand_bidirectional(
            graph,
            forward_frontier,
            backward_frontier,
            forward_settled,
            backward_settled,
            state,
            zero,
            add,
            compare,
          )
      }
    }
  }
}

fn expand_bidirectional(
  graph: Graph(n, e),
  forward_frontier: priority_queue.Queue(#(e, NodeId)),
  backward_frontier: priority_queue.Queue(#(e, NodeId)),
  forward_settled: Set(NodeId),
  backward_settled: Set(NodeId),
  state: BiSearchState(e),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(BiSearchState(e)) {
  // Alternate between forward and backward search based on minimum distance
  case
    priority_queue.peek(forward_frontier),
    priority_queue.peek(backward_frontier)
  {
    Ok(#(fwd_dist, _)), Ok(#(back_dist, _)) -> {
      // Expand the frontier with smaller minimum distance
      case compare(fwd_dist, back_dist) {
        order.Lt | order.Eq ->
          expand_forward(
            graph,
            forward_frontier,
            backward_frontier,
            forward_settled,
            backward_settled,
            state,
            zero,
            add,
            compare,
          )
        order.Gt ->
          expand_backward(
            graph,
            forward_frontier,
            backward_frontier,
            forward_settled,
            backward_settled,
            state,
            zero,
            add,
            compare,
          )
      }
    }
    Ok(_), Error(Nil) ->
      expand_forward(
        graph,
        forward_frontier,
        backward_frontier,
        forward_settled,
        backward_settled,
        state,
        zero,
        add,
        compare,
      )
    Error(Nil), Ok(_) ->
      expand_backward(
        graph,
        forward_frontier,
        backward_frontier,
        forward_settled,
        backward_settled,
        state,
        zero,
        add,
        compare,
      )
    Error(Nil), Error(Nil) -> {
      case state.meeting_point {
        Some(_) -> Some(state)
        None -> None
      }
    }
  }
}

fn expand_forward(
  graph: Graph(n, e),
  forward_frontier: priority_queue.Queue(#(e, NodeId)),
  backward_frontier: priority_queue.Queue(#(e, NodeId)),
  forward_settled: Set(NodeId),
  backward_settled: Set(NodeId),
  state: BiSearchState(e),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(BiSearchState(e)) {
  case priority_queue.pop(forward_frontier) {
    Error(Nil) ->
      do_bidirectional_dijkstra(
        graph,
        forward_frontier,
        backward_frontier,
        forward_settled,
        backward_settled,
        state,
        zero,
        add,
        compare,
      )
    Ok(#(#(dist, current), rest_frontier)) -> {
      case set.contains(forward_settled, current) {
        True ->
          do_bidirectional_dijkstra(
            graph,
            rest_frontier,
            backward_frontier,
            forward_settled,
            backward_settled,
            state,
            zero,
            add,
            compare,
          )
        False -> {
          let new_settled = set.insert(forward_settled, current)

          // Check if this node was reached from the other direction
          let updated_state = case dict.get(state.backward_dist, current) {
            Ok(back_dist) -> {
              let total = add(dist, back_dist)
              case state.best_length {
                Some(best) ->
                  case compare(total, best) {
                    order.Lt ->
                      BiSearchState(
                        ..state,
                        meeting_point: Some(current),
                        best_length: Some(total),
                      )
                    _ -> state
                  }
                None ->
                  BiSearchState(
                    ..state,
                    meeting_point: Some(current),
                    best_length: Some(total),
                  )
              }
            }
            Error(Nil) -> state
          }

          // Expand neighbors
          let neighbors = model.successors(graph, current)
          let #(next_state, next_frontier) =
            list.fold(
              neighbors,
              #(updated_state, rest_frontier),
              fn(acc, neighbor) {
                let #(s, frontier) = acc
                let #(next_id, weight) = neighbor
                let new_dist = add(dist, weight)

                case
                  should_explore_node(
                    s.forward_dist,
                    next_id,
                    new_dist,
                    compare,
                  )
                {
                  True -> {
                    let new_s =
                      BiSearchState(
                        ..s,
                        forward_dist: dict.insert(
                          s.forward_dist,
                          next_id,
                          new_dist,
                        ),
                        forward_parent: dict.insert(
                          s.forward_parent,
                          next_id,
                          current,
                        ),
                      )
                    let new_frontier =
                      priority_queue.push(frontier, #(new_dist, next_id))
                    #(new_s, new_frontier)
                  }
                  False -> #(s, frontier)
                }
              },
            )

          do_bidirectional_dijkstra(
            graph,
            next_frontier,
            backward_frontier,
            new_settled,
            backward_settled,
            next_state,
            zero,
            add,
            compare,
          )
        }
      }
    }
  }
}

fn expand_backward(
  graph: Graph(n, e),
  forward_frontier: priority_queue.Queue(#(e, NodeId)),
  backward_frontier: priority_queue.Queue(#(e, NodeId)),
  forward_settled: Set(NodeId),
  backward_settled: Set(NodeId),
  state: BiSearchState(e),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(BiSearchState(e)) {
  case priority_queue.pop(backward_frontier) {
    Error(Nil) ->
      do_bidirectional_dijkstra(
        graph,
        forward_frontier,
        backward_frontier,
        forward_settled,
        backward_settled,
        state,
        zero,
        add,
        compare,
      )
    Ok(#(#(dist, current), rest_frontier)) -> {
      case set.contains(backward_settled, current) {
        True ->
          do_bidirectional_dijkstra(
            graph,
            forward_frontier,
            rest_frontier,
            forward_settled,
            backward_settled,
            state,
            zero,
            add,
            compare,
          )
        False -> {
          let new_settled = set.insert(backward_settled, current)

          // Check if this node was reached from the forward direction
          let updated_state = case dict.get(state.forward_dist, current) {
            Ok(fwd_dist) -> {
              let total = add(fwd_dist, dist)
              case state.best_length {
                Some(best) ->
                  case compare(total, best) {
                    order.Lt ->
                      BiSearchState(
                        ..state,
                        meeting_point: Some(current),
                        best_length: Some(total),
                      )
                    _ -> state
                  }
                None ->
                  BiSearchState(
                    ..state,
                    meeting_point: Some(current),
                    best_length: Some(total),
                  )
              }
            }
            Error(Nil) -> state
          }

          // Expand predecessors (going backwards)
          let predecessors = model.predecessors(graph, current)
          let #(next_state, next_frontier) =
            list.fold(
              predecessors,
              #(updated_state, rest_frontier),
              fn(acc, pred) {
                let #(s, frontier) = acc
                let #(pred_id, weight) = pred
                let new_dist = add(dist, weight)

                case
                  should_explore_node(
                    s.backward_dist,
                    pred_id,
                    new_dist,
                    compare,
                  )
                {
                  True -> {
                    let new_s =
                      BiSearchState(
                        ..s,
                        backward_dist: dict.insert(
                          s.backward_dist,
                          pred_id,
                          new_dist,
                        ),
                        backward_parent: dict.insert(
                          s.backward_parent,
                          pred_id,
                          current,
                        ),
                      )
                    let new_frontier =
                      priority_queue.push(frontier, #(new_dist, pred_id))
                    #(new_s, new_frontier)
                  }
                  False -> #(s, frontier)
                }
              },
            )

          do_bidirectional_dijkstra(
            graph,
            forward_frontier,
            next_frontier,
            forward_settled,
            new_settled,
            next_state,
            zero,
            add,
            compare,
          )
        }
      }
    }
  }
}

// -----------------------------------------------------------------------------
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// -----------------------------------------------------------------------------

/// Finds the shortest path using bidirectional Dijkstra with **integer weights**.
///
/// Convenience wrapper that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
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

/// Finds the shortest path using bidirectional Dijkstra with **float weights**.
///
/// Convenience wrapper that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
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
