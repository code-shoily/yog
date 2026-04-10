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
//// - `lexicographical_topological_sort/2`: Ordering with custom priority
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
import yog/internal/random.{type Rng}
import yog/model.{type Graph, type NodeId}

// =============================================================================
// TYPES
// =============================================================================

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

// =============================================================================
// WALKS
// =============================================================================

/// Walks the graph starting from the given node, visiting all reachable nodes.
///
/// Returns a list of NodeIds in the order they were visited.
/// Uses successors to follow directed paths.
///
/// ## Example
///
/// ```gleam
/// // BFS traversal
/// traversal.walk(graph, from: 1, using: BreadthFirst)
/// // => [1, 2, 3, 4, 5]
///
/// // DFS traversal
/// traversal.walk(graph, from: 1, using: DepthFirst)
/// // => [1, 2, 4, 5, 3]
/// ```
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

/// Performs a Greedy Best-First Walk starting from the given node.
///
/// Visits nodes in order of their score as determined by `score_of`.
/// Lower scores are visited first. Unlike Dijkstra, scores are not cumulative.
///
/// ## Example
///
/// ```gleam
/// traversal.best_first_walk(
///   graph,
///   from: 1,
///   scored_by: fn(node_id) { get_priority(node_id) }
/// )
/// ```
pub fn best_first_walk(
  in graph: Graph(n, e),
  from start_id: NodeId,
  scored_by score_of: fn(NodeId) -> Int,
) -> List(NodeId) {
  best_first_fold(
    over: graph,
    from: start_id,
    initial: [],
    scored_by: score_of,
    with: fn(acc, node_id) { #(Continue, [node_id, ..acc]) },
  )
  |> list.reverse()
}

/// Simulates a random walk on the graph for a specified number of steps.
///
/// At each step, one of the current node's neighbors is chosen uniformly
/// at random. Returns the sequence of node IDs visited.
///
/// ## Parameters
///
/// - `steps`: Maximum number of steps to take.
/// - `seed`: Optional seed for reproducibility.
///
/// ## Example
///
/// ```gleam
/// traversal.random_walk(graph, from: 1, steps: 10, seed: Some(42))
/// // => [1, 2, 5, 2, 3, 1, ...]
/// ```
pub fn random_walk(
  in graph: Graph(n, e),
  from start_id: NodeId,
  steps limit: Int,
  seed seed: Option(Int),
) -> List(NodeId) {
  let rng = random.new(seed)
  do_random_walk(graph, start_id, limit, rng, [start_id])
  |> list.reverse()
}

fn do_random_walk(graph, current, remaining, rng, acc) {
  case remaining <= 0 {
    True -> acc
    False -> {
      let neighbors = model.successor_ids(graph, current)
      case neighbors {
        [] -> acc
        _ -> {
          let n = list.length(neighbors)
          let #(idx, next_rng) = random.next_int(rng, n)
          let assert Ok(next) =
            list.drop(neighbors, idx)
            |> list.first
          do_random_walk(graph, next, remaining - 1, next_rng, [next, ..acc])
        }
      }
    }
  }
}

/// Walks the graph but stops early when a condition is met.
///
/// Traverses the graph until `until` returns True for a node.
/// Returns all nodes visited including the one that stopped traversal.
///
/// ## Example
///
/// ```gleam
/// // Stop when we find node 5
/// traversal.walk_until(
///   graph,
///   from: 1,
///   using: BreadthFirst,
///   until: fn(node) { node == 5 }
/// )
/// ```
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

/// Folds over nodes in Best-First order using a priority queue.
///
/// Nodes are explored according to the score returned by `score_of` (cheapest first).
/// This is a Greedy Best-First Search — if you need cumulative edge costs,
/// use `dijkstra.fold` instead.
pub fn best_first_fold(
  over graph: Graph(n, e),
  from start: NodeId,
  initial acc: a,
  scored_by score_of: fn(NodeId) -> Int,
  with folder: fn(a, NodeId) -> #(WalkControl, a),
) -> a {
  let q =
    priority_queue.new(fn(a: #(Int, NodeId), b: #(Int, NodeId)) {
      int.compare(a.0, b.0)
    })
    |> priority_queue.push(#(score_of(start), start))

  do_best_first_fold(graph, q, set.new(), acc, score_of, folder)
}

fn do_best_first_fold(graph, q, visited, acc, score_of, folder) {
  case priority_queue.pop(q) {
    Error(Nil) -> acc
    Ok(#(#(_score, node), rest)) -> {
      case set.contains(visited, node) {
        True -> do_best_first_fold(graph, rest, visited, acc, score_of, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node)
          let new_visited = set.insert(visited, node)
          case control {
            Halt -> new_acc
            Stop ->
              do_best_first_fold(
                graph,
                rest,
                new_visited,
                new_acc,
                score_of,
                folder,
              )
            Continue -> {
              let next_q =
                list.fold(model.successor_ids(graph, node), rest, fn(q_acc, nb) {
                  case set.contains(new_visited, nb) {
                    True -> q_acc
                    False -> priority_queue.push(q_acc, #(score_of(nb), nb))
                  }
                })
              do_best_first_fold(
                graph,
                next_q,
                new_visited,
                new_acc,
                score_of,
                folder,
              )
            }
          }
        }
      }
    }
  }
}

/// Folds over nodes during graph traversal, accumulating state with metadata.
///
/// This function combines traversal with state accumulation, providing metadata
/// about each visited node (depth and parent). The folder function controls the
/// traversal flow:
///
/// - `Continue`: Explore successors of the current node normally
/// - `Stop`: Skip successors of this node, but continue processing other queued nodes
/// - `Halt`: Stop the entire traversal immediately and return the accumulator
///
/// **Time Complexity:** O(V + E) for both BFS and DFS
///
/// ## Parameters
///
/// - `folder`: Called for each visited node with (accumulator, node_id, metadata).
///   Returns `#(WalkControl, new_accumulator)`.
///
/// ## Examples
///
/// ```gleam
/// import gleam/dict
/// import yog/traversal.{BreadthFirst, Continue, Halt, Stop, WalkMetadata}
///
/// // Find all nodes within distance 3 from start
/// let nearby = traversal.fold_walk(
///   graph,
///   from: 1,
///   using: BreadthFirst,
///   initial: dict.new(),
///   with: fn(acc, node_id, meta) {
///     case meta.depth <= 3 {
///       True -> #(Continue, dict.insert(acc, node_id, meta.depth))
///       False -> #(Stop, acc)  // Don't explore beyond depth 3
///     }
///   }
/// )
/// ```
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
///
/// Unlike `fold_walk`, this does not require a materialised `Graph` value.
/// Instead, you supply a `successors_of` function that computes neighbours
/// on the fly — ideal for infinite grids, state-space search, or any
/// graph that is too large or expensive to build upfront.
///
/// ## Example
///
/// ```gleam
/// // BFS shortest path in an implicit maze
/// traversal.implicit_fold(
///   from: #(1, 1),
///   using: BreadthFirst,
///   initial: -1,
///   successors_of: fn(pos) { open_neighbours(pos, fav) },
///   with: fn(acc, pos, meta) {
///     case pos == target {
///       True -> #(Halt, meta.depth)
///       False -> #(Continue, acc)
///     }
///   },
/// )
/// ```
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
///
/// This is essential when your node type carries extra state beyond what
/// defines "identity". For example, in state-space search you might have
/// `#(Position, Mask)` nodes, but only want to visit each `Position` once —
/// the `Mask` is just carried state, not part of the identity.
///
/// The `visited_by` function extracts the deduplication key from each node.
/// Internally, a `Set(key)` tracks which keys have been visited, but the
/// full `nid` value (with all its state) is still passed to your folder.
///
/// **Time Complexity:** O(V + E) for both BFS and DFS, where V and E are
/// measured in terms of unique *keys* (not unique nodes).
///
/// ## Example
///
/// ```gleam
/// // Search a maze where nodes carry both position and step count
/// // but we only want to visit each position once (first-visit wins)
/// type State {
///   State(pos: #(Int, Int), steps: Int)
/// }
///
/// traversal.implicit_fold_by(
///   from: State(#(0, 0), 0),
///   using: BreadthFirst,
///   initial: None,
///   successors_of: fn(state) {
///     neighbors(state.pos)
///     |> list.map(fn(next_pos) {
///       State(next_pos, state.steps + 1)
///     })
///   },
///   visited_by: fn(state) { state.pos },  // Dedupe by position only
///   with: fn(acc, state, _meta) {
///     case state.pos == target {
///       True -> #(Halt, Some(state.steps))
///       False -> #(Continue, acc)
///     }
///   },
/// )
/// ```
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

// =============================================================================
// SORTS
// =============================================================================

/// Performs a topological sort on a directed graph using Kahn's algorithm.
///
/// Returns a linear ordering of nodes such that for every directed edge (u, v),
/// node u comes before node v in the ordering.
///
/// Returns `Error(Nil)` if the graph contains a cycle.
///
/// **Time Complexity:** O(V + E) where V is vertices and E is edges
///
/// ## Example
///
/// ```gleam
/// traversal.topological_sort(graph)
/// // => Ok([1, 2, 3, 4])  // Valid ordering
/// // or Error(Nil)         // Cycle detected
/// ```
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

/// Performs a topological sort that returns the lexicographically smallest sequence.
///
/// Uses a heap-based version of Kahn's algorithm to ensure that when multiple
/// nodes have in-degree 0, the smallest one (according to `compare_nodes`) is chosen first.
///
/// The comparison function operates on **node data**, not node IDs, allowing intuitive
/// comparisons like `string.compare` for alphabetical ordering.
///
/// Returns `Error(Nil)` if the graph contains a cycle.
///
/// **Time Complexity:** O(V log V + E) due to heap operations
///
/// ## Example
///
/// ```gleam
/// // Get alphabetical ordering by node data
/// traversal.lexicographical_topological_sort(graph, string.compare)
/// // => Ok([0, 1, 2])  // Node IDs ordered by their string data
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
