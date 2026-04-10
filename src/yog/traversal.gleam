//// Graph traversal algorithms - systematic exploration of graph structure.
////
//// This module provides fundamental graph traversal algorithms for visiting nodes
//// in a specific order. Traversals are the foundation for most graph algorithms
//// including pathfinding, connectivity analysis, and cycle detection.
////
//// ## Traversal Orders
////
//// | Order | Strategy | Best For |
//// |-------|----------|----------|
//// | [BFS](https://en.wikipedia.org/wiki/Breadth-first_search) | Level-by-level | Shortest path (unweighted), finding neighbors |
//// | [DFS](https://en.wikipedia.org/wiki/Depth-first_search) | Deep exploration | Cycle detection, topological sort, connectivity |
////
//// ## Core Functions
////
//// - `bfs/2` / `dfs/2`: Simple traversals returning visited nodes in order
//// - `walk/4`: Generic traversal with custom fold function
//// - `topological_sort/1`: Ordering for DAGs (uses DFS internally)
//// - `is_acyclic/1`: Cycle detection via Kahn's algorithm
////
//// ## Walk Control
////
//// The `fold_walk` function provides fine-grained control:
//// - `Continue`: Explore this node's neighbors normally
//// - `Stop`: Skip this node's neighbors but continue traversal
//// - `Halt`: Stop the entire traversal immediately
////
//// ## Time Complexity
////
//// All traversals run in **O(V + E)** linear time, visiting each node and edge
//// at most once.
////
//// ## References
////
//// - [Wikipedia: Graph Traversal](https://en.wikipedia.org/wiki/Graph_traversal)
//// - [CP-Algorithms: DFS/BFS](https://cp-algorithms.com/graph/breadth-first-search.html)
//// - [Wikipedia: Topological Sorting](https://en.wikipedia.org/wiki/Topological_sorting)

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}
import yog/internal/priority_queue
import yog/internal/queue
import yog/model.{type Graph, type NodeId}

/// Traversal order for graph walking algorithms.
pub type Order {
  /// Breadth-First Search: visit all neighbors before going deeper.
  BreadthFirst
  /// Depth-First Search: visit as deep as possible before backtracking.
  DepthFirst
}

/// Control flow for fold_walk traversal.
pub type WalkControl {
  /// Continue exploring from this node's successors.
  Continue
  /// Stop exploring from this node (but continue with other queued nodes).
  Stop
  /// Halt the entire traversal immediately and return the accumulator.
  Halt
}

/// Metadata provided during fold_walk / implicit_fold traversal.
pub type WalkMetadata(nid) {
  WalkMetadata(
    /// Distance from the start node (number of edges traversed).
    depth: Int,
    /// The parent node that led to this node (None for the start node).
    parent: Option(nid),
  )
}

/// Walks the graph starting from the given node, visiting all reachable nodes.
pub fn walk(
  in graph: Graph(n, e),
  from start_id: NodeId,
  using order: Order,
) -> List(NodeId) {
  fold_walk(
    over: graph,
    from: start_id,
    using: order,
    initial: [],
    with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
  )
  |> list.reverse()
}

/// Walks the graph but stops early when a condition is met.
pub fn walk_until(
  in graph: Graph(n, e),
  from start_id: NodeId,
  using order: Order,
  until should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  fold_walk(
    over: graph,
    from: start_id,
    using: order,
    initial: [],
    with: fn(acc, node_id, _meta) {
      let new_acc = [node_id, ..acc]
      case should_stop(node_id) {
        True -> #(Halt, new_acc)
        False -> #(Continue, new_acc)
      }
    },
  )
  |> list.reverse()
}

/// Folds over nodes during graph traversal, accumulating state with metadata.
pub fn fold_walk(
  over graph: Graph(n, e),
  from start: NodeId,
  using order: Order,
  initial acc: a,
  with folder: fn(a, NodeId, WalkMetadata(NodeId)) -> #(WalkControl, a),
) -> a {
  implicit_fold_by(
    from: start,
    using: order,
    initial: acc,
    successors_of: fn(id) { model.successor_ids(graph, id) },
    visited_by: fn(id) { id },
    with: folder,
  )
}

/// Traverses an *implicit* graph using BFS or DFS, folding over visited nodes.
pub fn implicit_fold(
  from start: nid,
  using order: Order,
  initial acc: a,
  successors_of successors: fn(nid) -> List(nid),
  with folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  implicit_fold_by(
    from: start,
    using: order,
    initial: acc,
    successors_of: successors,
    visited_by: fn(id) { id },
    with: folder,
  )
}

/// Like `implicit_fold`, but deduplicates visited nodes by a custom key.
pub fn implicit_fold_by(
  from start: nid,
  using order: Order,
  initial acc: a,
  successors_of successors: fn(nid) -> List(nid),
  visited_by key_fn: fn(nid) -> key,
  with folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  let meta = WalkMetadata(depth: 0, parent: None)
  case order {
    BreadthFirst -> {
      let q = queue.new() |> queue.push(#(start, meta))
      do_walk_bfs(q, set.new(), acc, successors, key_fn, folder)
    }
    DepthFirst -> {
      do_walk_dfs([#(start, meta)], set.new(), acc, successors, key_fn, folder)
    }
  }
}

fn do_walk_bfs(
  q: queue.Queue(#(nid, WalkMetadata(nid))),
  visited: Set(key),
  acc: a,
  successors: fn(nid) -> List(nid),
  key_fn: fn(nid) -> key,
  folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  case queue.pop(q) {
    Error(Nil) -> acc
    Ok(#(#(node, meta), rest)) -> {
      let key = key_fn(node)
      case set.contains(visited, key) {
        True -> do_walk_bfs(rest, visited, acc, successors, key_fn, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node, meta)
          let new_visited = set.insert(visited, key)
          case control {
            Halt -> new_acc
            Stop ->
              do_walk_bfs(
                rest,
                new_visited,
                new_acc,
                successors,
                key_fn,
                folder,
              )
            Continue -> {
              let next_meta = fn(_n) {
                WalkMetadata(depth: meta.depth + 1, parent: Some(node))
              }
              let q =
                list.fold(successors(node), rest, fn(q, n) {
                  queue.push(q, #(n, next_meta(n)))
                })
              do_walk_bfs(q, new_visited, new_acc, successors, key_fn, folder)
            }
          }
        }
      }
    }
  }
}

fn do_walk_dfs(
  stack: List(#(nid, WalkMetadata(nid))),
  visited: Set(key),
  acc: a,
  successors: fn(nid) -> List(nid),
  key_fn: fn(nid) -> key,
  folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  case stack {
    [] -> acc
    [#(node, meta), ..tail] -> {
      let key = key_fn(node)
      case set.contains(visited, key) {
        True -> do_walk_dfs(tail, visited, acc, successors, key_fn, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node, meta)
          let new_visited = set.insert(visited, key)
          case control {
            Halt -> new_acc
            Stop ->
              do_walk_dfs(
                tail,
                new_visited,
                new_acc,
                successors,
                key_fn,
                folder,
              )
            Continue -> {
              let next_meta = fn(_n) {
                WalkMetadata(depth: meta.depth + 1, parent: Some(node))
              }
              let stack =
                list.fold_right(successors(node), tail, fn(s, n) {
                  [#(n, next_meta(n)), ..s]
                })
              do_walk_dfs(
                stack,
                new_visited,
                new_acc,
                successors,
                key_fn,
                folder,
              )
            }
          }
        }
      }
    }
  }
}

/// Traverses an *implicit* weighted graph using Dijkstra's algorithm.
pub fn implicit_dijkstra(
  from start: nid,
  initial acc: a,
  successors_of successors: fn(nid) -> List(#(nid, Int)),
  with folder: fn(a, nid, Int) -> #(WalkControl, a),
) -> a {
  let frontier =
    priority_queue.new(fn(a: #(Int, nid), b: #(Int, nid)) {
      int.compare(a.0, b.0)
    })
    |> priority_queue.push(#(0, start))
  do_implicit_dijkstra(frontier, dict.new(), acc, successors, folder)
}

fn do_implicit_dijkstra(frontier, best, acc, successors, folder) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> acc
    Ok(#(#(cost, node), rest)) ->
      case dict.get(best, node) {
        Ok(prev) if prev < cost ->
          do_implicit_dijkstra(rest, best, acc, successors, folder)
        _ -> {
          let new_best = dict.insert(best, node, cost)
          let #(control, new_acc) = folder(acc, node, cost)
          case control {
            Halt -> new_acc
            Stop ->
              do_implicit_dijkstra(rest, new_best, new_acc, successors, folder)
            Continue -> {
              let next_frontier =
                list.fold(successors(node), rest, fn(q, neighbor) {
                  let #(nb_node, edge_cost) = neighbor
                  let new_cost = cost + edge_cost
                  case dict.get(new_best, nb_node) {
                    Ok(prev_cost) if prev_cost <= new_cost -> q
                    _ -> priority_queue.push(q, #(new_cost, nb_node))
                  }
                })
              do_implicit_dijkstra(
                next_frontier,
                new_best,
                new_acc,
                successors,
                folder,
              )
            }
          }
        }
      }
  }
}

/// Performs a topological sort on a directed graph using Kahn's algorithm.
pub fn topological_sort(graph: Graph(n, e)) -> Result(List(NodeId), Nil) {
  let all_nodes = model.all_nodes(graph)
  let in_degrees =
    all_nodes
    |> list.map(fn(id) { #(id, model.in_degree(graph, id)) })
    |> dict.from_list()

  let queue =
    dict.to_list(in_degrees)
    |> list.filter_map(fn(p) {
      case p.1 {
        0 -> Ok(p.0)
        _ -> Error(Nil)
      }
    })

  do_kahn(graph, queue, in_degrees, [], list.length(all_nodes))
}

fn do_kahn(graph, queue, in_degrees, acc, total_count) {
  case queue {
    [] ->
      case list.length(acc) == total_count {
        True -> Ok(list.reverse(acc))
        False -> Error(Nil)
      }
    [head, ..tail] -> {
      let #(next_q, next_degrees) =
        list.fold(
          model.successor_ids(graph, head),
          #(tail, in_degrees),
          fn(state, nb) {
            let #(q, degrees) = state
            let new_deg = { dict.get(degrees, nb) |> result.unwrap(0) } - 1
            let q = case new_deg == 0 {
              True -> [nb, ..q]
              False -> q
            }
            #(q, dict.insert(degrees, nb, new_deg))
          },
        )
      do_kahn(graph, next_q, next_degrees, [head, ..acc], total_count)
    }
  }
}

/// Performs a lexicographical topological sort.
pub fn lexicographical_topological_sort(
  graph: Graph(n, e),
  compare_nodes: fn(n, n) -> order.Order,
) -> Result(List(NodeId), Nil) {
  let all_nodes = model.all_nodes(graph)
  let in_degrees =
    all_nodes
    |> list.map(fn(id) { #(id, model.in_degree(graph, id)) })
    |> dict.from_list()

  let compare_by_data = fn(a, b) {
    case dict.get(graph.nodes, a), dict.get(graph.nodes, b) {
      Ok(da), Ok(db) -> compare_nodes(da, db)
      _, _ -> order.Eq
    }
  }

  let q =
    dict.to_list(in_degrees)
    |> list.filter_map(fn(p) {
      case p.1 {
        0 -> Ok(p.0)
        _ -> Error(Nil)
      }
    })
    |> list.fold(priority_queue.new(compare_by_data), priority_queue.push)

  do_lexical_kahn(graph, q, in_degrees, [], list.length(all_nodes))
}

fn do_lexical_kahn(graph, q, in_degrees, acc, total_count) {
  case priority_queue.pop(q) {
    Error(Nil) ->
      case list.length(acc) == total_count {
        True -> Ok(list.reverse(acc))
        False -> Error(Nil)
      }
    Ok(#(head, rest)) -> {
      let #(next_q, next_degrees) =
        list.fold(
          model.successor_ids(graph, head),
          #(rest, in_degrees),
          fn(state, nb) {
            let #(q, degrees) = state
            let new_deg = { dict.get(degrees, nb) |> result.unwrap(0) } - 1
            let q = case new_deg == 0 {
              True -> priority_queue.push(q, nb)
              False -> q
            }
            #(q, dict.insert(degrees, nb, new_deg))
          },
        )
      do_lexical_kahn(graph, next_q, next_degrees, [head, ..acc], total_count)
    }
  }
}
