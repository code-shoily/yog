import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
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
///
/// Returns a list of NodeIds in the order they were visited.
/// Uses successors to follow directed paths.
///
/// ## Example
///
/// ```gleam
/// // BFS traversal
/// traversal.walk(from: 1, in: graph, using: BreadthFirst)
/// // => [1, 2, 3, 4, 5]
///
/// // DFS traversal
/// traversal.walk(from: 1, in: graph, using: DepthFirst)
/// // => [1, 2, 4, 5, 3]
/// ```
pub fn walk(
  from start_id: NodeId,
  in graph: Graph(n, e),
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
///
/// Traverses the graph until `should_stop` returns True for a node.
/// Returns all nodes visited including the one that stopped traversal.
///
/// ## Example
///
/// ```gleam
/// // Stop when we find node 5
/// traversal.walk_until(
///   from: 1,
///   in: graph,
///   using: BreadthFirst,
///   until: fn(node) { node == 5 }
/// )
/// ```
pub fn walk_until(
  from start_id: NodeId,
  in graph: Graph(n, e),
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
///   over: graph,
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
///
/// // Stop immediately when target is found (like walk_until)
/// let path_to_target = traversal.fold_walk(
///   over: graph,
///   from: start,
///   using: BreadthFirst,
///   initial: [],
///   with: fn(acc, node_id, _meta) {
///     let new_acc = [node_id, ..acc]
///     case node_id == target {
///       True -> #(Halt, new_acc)   // Stop entire traversal
///       False -> #(Continue, new_acc)
///     }
///   }
/// )
///
/// // Build a parent map for path reconstruction
/// let parents = traversal.fold_walk(
///   over: graph,
///   from: start,
///   using: BreadthFirst,
///   initial: dict.new(),
///   with: fn(acc, node_id, meta) {
///     let new_acc = case meta.parent {
///       Some(p) -> dict.insert(acc, node_id, p)
///       None -> acc
///     }
///     #(Continue, new_acc)
///   }
/// )
///
/// // Count nodes at each depth level
/// let depth_counts = traversal.fold_walk(
///   over: graph,
///   from: root,
///   using: BreadthFirst,
///   initial: dict.new(),
///   with: fn(acc, _node_id, meta) {
///     let count = dict.get(acc, meta.depth) |> result.unwrap(0)
///     #(Continue, dict.insert(acc, meta.depth, count + 1))
///   }
/// )
/// ```
///
/// ## Use Cases
///
/// - Finding nodes within a certain distance
/// - Building shortest path trees (parent pointers)
/// - Collecting nodes with custom filtering logic
/// - Computing statistics during traversal (depth distribution, etc.)
/// - BFS/DFS with early termination based on accumulated state
pub fn fold_walk(
  over graph: Graph(n, e),
  from start: NodeId,
  using order: Order,
  initial acc: a,
  with folder: fn(a, NodeId, WalkMetadata(NodeId)) -> #(WalkControl, a),
) -> a {
  let start_metadata = WalkMetadata(depth: 0, parent: None)

  case order {
    BreadthFirst ->
      do_fold_walk_bfs(
        graph,
        queue.new() |> queue.push(#(start, start_metadata)),
        set.new(),
        acc,
        folder,
      )
    DepthFirst ->
      do_fold_walk_dfs(
        graph,
        [#(start, start_metadata)],
        set.new(),
        acc,
        folder,
      )
  }
}

/// Traverses an *implicit* graph using BFS or DFS,
/// folding over visited nodes with metadata.
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
  let start_meta = WalkMetadata(depth: 0, parent: None)
  case order {
    BreadthFirst ->
      do_virtual_bfs(
        queue.new() |> queue.push(#(start, start_meta)),
        set.new(),
        acc,
        successors,
        folder,
      )
    DepthFirst ->
      do_virtual_dfs([#(start, start_meta)], set.new(), acc, successors, folder)
  }
}

// BFS with fold and metadata
fn do_fold_walk_bfs(
  graph: Graph(n, e),
  q: queue.Queue(#(NodeId, WalkMetadata(NodeId))),
  visited: Set(NodeId),
  acc: a,
  folder: fn(a, NodeId, WalkMetadata(NodeId)) -> #(WalkControl, a),
) -> a {
  case queue.pop(q) {
    Error(Nil) -> acc
    Ok(#(#(node_id, metadata), rest)) -> {
      case set.contains(visited, node_id) {
        True -> do_fold_walk_bfs(graph, rest, visited, acc, folder)
        False -> {
          // Call folder with current node
          let #(control, new_acc) = folder(acc, node_id, metadata)
          let new_visited = set.insert(visited, node_id)

          case control {
            Halt -> new_acc
            Stop -> do_fold_walk_bfs(graph, rest, new_visited, new_acc, folder)
            Continue -> {
              // Add successors to queue with updated metadata
              let next_nodes = model.successor_ids(graph, node_id)
              let next_queue =
                list.fold(next_nodes, rest, fn(current_queue, next_id) {
                  let next_meta =
                    WalkMetadata(
                      depth: metadata.depth + 1,
                      parent: Some(node_id),
                    )
                  queue.push(current_queue, #(next_id, next_meta))
                })

              do_fold_walk_bfs(graph, next_queue, new_visited, new_acc, folder)
            }
          }
        }
      }
    }
  }
}

// DFS with fold and metadata
fn do_fold_walk_dfs(
  graph: Graph(n, e),
  stack: List(#(NodeId, WalkMetadata(NodeId))),
  visited: Set(NodeId),
  acc: a,
  folder: fn(a, NodeId, WalkMetadata(NodeId)) -> #(WalkControl, a),
) -> a {
  case stack {
    [] -> acc
    [#(node_id, metadata), ..tail] -> {
      case set.contains(visited, node_id) {
        True -> do_fold_walk_dfs(graph, tail, visited, acc, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node_id, metadata)
          let new_visited = set.insert(visited, node_id)
          case control {
            Halt -> new_acc
            Stop -> do_fold_walk_dfs(graph, tail, new_visited, new_acc, folder)
            Continue -> {
              let next_nodes = model.successor_ids(graph, node_id)
              let next_stack =
                list.fold(
                  list.reverse(next_nodes),
                  tail,
                  fn(current_stack, next_id) {
                    let next_meta =
                      WalkMetadata(
                        depth: metadata.depth + 1,
                        parent: Some(node_id),
                      )
                    [#(next_id, next_meta), ..current_stack]
                  },
                )
              do_fold_walk_dfs(graph, next_stack, new_visited, new_acc, folder)
            }
          }
        }
      }
    }
  }
}

// Virtual BFS: same as do_fold_walk_bfs but uses a successors function
// instead of querying a Graph.
fn do_virtual_bfs(
  q: queue.Queue(#(nid, WalkMetadata(nid))),
  visited: Set(nid),
  acc: a,
  successors: fn(nid) -> List(nid),
  folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  case queue.pop(q) {
    Error(Nil) -> acc
    Ok(#(#(node_id, metadata), rest)) ->
      case set.contains(visited, node_id) {
        True -> do_virtual_bfs(rest, visited, acc, successors, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node_id, metadata)
          let new_visited = set.insert(visited, node_id)
          case control {
            Halt -> new_acc
            Stop ->
              do_virtual_bfs(rest, new_visited, new_acc, successors, folder)
            Continue -> {
              let next_queue =
                list.fold(successors(node_id), rest, fn(q2, next_id) {
                  queue.push(q2, #(
                    next_id,
                    WalkMetadata(
                      depth: metadata.depth + 1,
                      parent: Some(node_id),
                    ),
                  ))
                })
              do_virtual_bfs(
                next_queue,
                new_visited,
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

// Virtual DFS: same as do_fold_walk_dfs but uses a successors function.
fn do_virtual_dfs(
  stack: List(#(nid, WalkMetadata(nid))),
  visited: Set(nid),
  acc: a,
  successors: fn(nid) -> List(nid),
  folder: fn(a, nid, WalkMetadata(nid)) -> #(WalkControl, a),
) -> a {
  case stack {
    [] -> acc
    [#(node_id, metadata), ..tail] ->
      case set.contains(visited, node_id) {
        True -> do_virtual_dfs(tail, visited, acc, successors, folder)
        False -> {
          let #(control, new_acc) = folder(acc, node_id, metadata)
          let new_visited = set.insert(visited, node_id)
          case control {
            Halt -> new_acc
            Stop ->
              do_virtual_dfs(tail, new_visited, new_acc, successors, folder)
            Continue -> {
              let next_stack =
                list.fold(
                  list.reverse(successors(node_id)),
                  tail,
                  fn(stk, next_id) {
                    [
                      #(
                        next_id,
                        WalkMetadata(
                          depth: metadata.depth + 1,
                          parent: Some(node_id),
                        ),
                      ),
                      ..stk
                    ]
                  },
                )
              do_virtual_dfs(
                next_stack,
                new_visited,
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
