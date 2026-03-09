import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import yog/model.{type NodeId}
import yog/multi/model.{type EdgeId, type MultiGraph} as multi

/// Control flow for fold_walk traversal.
pub type WalkControl {
  /// Continue exploring from this node's successors.
  Continue
  /// Stop exploring from this node (but continue with other queued nodes).
  Stop
  /// Halt the entire traversal immediately and return the accumulator.
  Halt
}

/// Metadata provided during fold_walk traversal for multigraphs.
///
/// Unlike simple graphs, this includes the specific edge used to reach each node.
pub type WalkMetadata {
  WalkMetadata(
    /// Distance from the start node (number of edges traversed).
    depth: Int,
    /// The parent node and edge that led to this node (None for the start node).
    parent: Option(#(NodeId, EdgeId)),
  )
}

/// Performs a Breadth-First Search from `source`, returning visited node IDs
/// in BFS order.
///
/// Unlike simple-graph BFS, this traversal uses edge IDs to correctly handle
/// parallel edges — each **edge** is traversed at most once, but a node may be
/// reached via multiple edges (the first visit wins for ordering purposes).
///
/// **Time Complexity:** O(V + E)
pub fn bfs(graph: MultiGraph(n, e), source: NodeId) -> List(NodeId) {
  do_bfs(graph, [source], set.from_list([source]), set.new(), [])
}

/// Performs a Depth-First Search from `source`, returning visited node IDs
/// in DFS pre-order.
///
/// **Time Complexity:** O(V + E)
pub fn dfs(graph: MultiGraph(n, e), source: NodeId) -> List(NodeId) {
  do_dfs(graph, source, set.new(), set.new(), [])
  |> list.reverse()
}

/// Folds over nodes during multigraph traversal, accumulating state with metadata.
///
/// This function combines traversal with state accumulation, providing metadata
/// about each visited node including which specific edge was used to reach it.
/// The folder function controls the traversal flow:
///
/// - `Continue`: Explore successors of the current node normally
/// - `Stop`: Skip successors of this node, but continue processing other queued nodes
/// - `Halt`: Stop the entire traversal immediately and return the accumulator
///
/// **For multigraphs**: The metadata includes the specific `EdgeId` used to reach
/// each node, which is important when parallel edges exist.
///
/// **Time Complexity:** O(V + E)
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
/// import yog/multi/traversal.{Continue, Halt, Stop, WalkMetadata}
///
/// // Build a parent map tracking which edge led to each node
/// let parents = traversal.fold_walk(
///   over: graph,
///   from: start,
///   initial: dict.new(),
///   with: fn(acc, node_id, meta) {
///     let new_acc = case meta.parent {
///       Some(#(parent_node, edge_id)) ->
///         dict.insert(acc, node_id, #(parent_node, edge_id))
///       None -> acc
///     }
///     #(Continue, new_acc)
///   }
/// )
///
/// // Find all nodes within distance 3
/// let nearby = traversal.fold_walk(
///   over: graph,
///   from: start,
///   initial: [],
///   with: fn(acc, node_id, meta) {
///     case meta.depth <= 3 {
///       True -> #(Continue, [node_id, ..acc])
///       False -> #(Stop, acc)  // Don't explore beyond depth 3
///     }
///   }
/// )
///
/// // Collect all edges in the traversal path
/// let path_edges = traversal.fold_walk(
///   over: graph,
///   from: start,
///   initial: [],
///   with: fn(acc, _node_id, meta) {
///     let new_acc = case meta.parent {
///       Some(#(_, edge_id)) -> [edge_id, ..acc]
///       None -> acc
///     }
///     #(Continue, new_acc)
///   }
/// )
/// ```
pub fn fold_walk(
  over graph: MultiGraph(n, e),
  from start: NodeId,
  initial acc: a,
  with folder: fn(a, NodeId, WalkMetadata) -> #(WalkControl, a),
) -> a {
  let start_metadata = WalkMetadata(depth: 0, parent: None)

  do_fold_walk_bfs(
    graph,
    [#(start, start_metadata)],
    set.new(),
    set.new(),
    acc,
    folder,
  )
}

// ---------------------------------------------------------------------------
// Internal
// ---------------------------------------------------------------------------

fn do_bfs(
  graph: MultiGraph(n, e),
  queue: List(NodeId),
  visited_nodes: Set(NodeId),
  used_edges: Set(Int),
  acc: List(NodeId),
) -> List(NodeId) {
  case queue {
    [] -> list.reverse(acc)
    [current, ..rest_queue] -> {
      // Collect unvisited neighbours reachable via unused edges
      let #(new_nodes, new_edges, next_queue) =
        multi.successors(graph, current)
        |> list.fold(#(visited_nodes, used_edges, rest_queue), fn(state, succ) {
          let #(vn, ue, q) = state
          let #(dst, eid, _) = succ
          case set.contains(ue, eid) || set.contains(vn, dst) {
            True -> state
            False -> #(set.insert(vn, dst), set.insert(ue, eid), [dst, ..q])
          }
        })

      do_bfs(graph, next_queue, new_nodes, new_edges, [current, ..acc])
    }
  }
}

fn do_dfs(
  graph: MultiGraph(n, e),
  current: NodeId,
  visited_nodes: Set(NodeId),
  used_edges: Set(Int),
  acc: List(NodeId),
) -> List(NodeId) {
  // Entry point: use CPS with identity continuation
  do_dfs_cps(graph, current, visited_nodes, used_edges, acc, fn(v, _, a) {
    #(v, a)
  })
  |> fn(r) { r.1 }
}

// CPS version: cont is "what to do after processing this node and all its descendants"
// All calls are tail-recursive to avoid stack overflow on deep graphs
fn do_dfs_cps(
  graph: MultiGraph(n, e),
  current: NodeId,
  visited_nodes: Set(NodeId),
  used_edges: Set(Int),
  acc: List(NodeId),
  cont: fn(Set(NodeId), Set(Int), List(NodeId)) -> #(Set(NodeId), List(NodeId)),
) -> #(Set(NodeId), List(NodeId)) {
  case set.contains(visited_nodes, current) {
    True -> cont(visited_nodes, used_edges, acc)
    False -> {
      let visited2 = set.insert(visited_nodes, current)
      let acc2 = [current, ..acc]

      // Get successors and process them tail-recursively
      let successors = multi.successors(graph, current)
      process_successors_cps(
        graph,
        successors,
        visited2,
        used_edges,
        acc2,
        cont,
      )
    }
  }
}

// Process successors one at a time, tail-recursively
// Passes remaining successors as part of the continuation to maintain DFS order
fn process_successors_cps(
  graph: MultiGraph(n, e),
  successors: List(#(NodeId, Int, e)),
  visited: Set(NodeId),
  used_edges: Set(Int),
  acc: List(NodeId),
  cont: fn(Set(NodeId), Set(Int), List(NodeId)) -> #(Set(NodeId), List(NodeId)),
) -> #(Set(NodeId), List(NodeId)) {
  case successors {
    [] -> {
      // No more successors to process, continue with parent context
      cont(visited, used_edges, acc)
    }
    [#(dst, eid, _), ..rest] -> {
      case set.contains(used_edges, eid) {
        True -> {
          // Edge already used, skip and continue with rest (tail recursive)
          process_successors_cps(graph, rest, visited, used_edges, acc, cont)
        }
        False -> {
          let used2 = set.insert(used_edges, eid)
          // Process this child (tail recursive), then continue with siblings
          do_dfs_cps(
            graph,
            dst,
            visited,
            used2,
            acc,
            fn(v_after, ue_after, acc_after) {
              // After child is done, process remaining siblings
              process_successors_cps(
                graph,
                rest,
                v_after,
                ue_after,
                acc_after,
                cont,
              )
            },
          )
        }
      }
    }
  }
}

// BFS with fold and metadata for multigraphs
fn do_fold_walk_bfs(
  graph: MultiGraph(n, e),
  queue: List(#(NodeId, WalkMetadata)),
  visited_nodes: Set(NodeId),
  used_edges: Set(Int),
  acc: a,
  folder: fn(a, NodeId, WalkMetadata) -> #(WalkControl, a),
) -> a {
  case queue {
    [] -> acc
    [#(node_id, metadata), ..rest_queue] -> {
      case set.contains(visited_nodes, node_id) {
        True ->
          do_fold_walk_bfs(
            graph,
            rest_queue,
            visited_nodes,
            used_edges,
            acc,
            folder,
          )
        False -> {
          // Call folder with current node
          let #(control, new_acc) = folder(acc, node_id, metadata)
          let new_visited = set.insert(visited_nodes, node_id)

          case control {
            Halt -> new_acc
            Stop ->
              do_fold_walk_bfs(
                graph,
                rest_queue,
                new_visited,
                used_edges,
                new_acc,
                folder,
              )
            Continue -> {
              // Add successors to queue with updated metadata
              let #(next_queue, new_used_edges) =
                multi.successors(graph, node_id)
                |> list.fold(#(rest_queue, used_edges), fn(state, succ) {
                  let #(q, ue) = state
                  let #(dst, eid, _) = succ

                  case set.contains(ue, eid) {
                    True -> state
                    False -> {
                      let next_meta =
                        WalkMetadata(
                          depth: metadata.depth + 1,
                          parent: Some(#(node_id, eid)),
                        )
                      #([#(dst, next_meta), ..q], set.insert(ue, eid))
                    }
                  }
                })

              do_fold_walk_bfs(
                graph,
                next_queue,
                new_visited,
                new_used_edges,
                new_acc,
                folder,
              )
            }
          }
        }
      }
    }
  }
}
