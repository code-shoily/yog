import gleam/list
import gleam/set.{type Set}
import yog/model.{type NodeId}
import yog/multi.{type MultiGraph}

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
  case set.contains(visited_nodes, current) {
    True -> acc
    False -> {
      let visited2 = set.insert(visited_nodes, current)
      let acc2 = [current, ..acc]

      multi.successors(graph, current)
      |> list.fold(#(visited2, used_edges, acc2), fn(state, succ) {
        let #(vn, ue, a) = state
        let #(dst, eid, _) = succ
        case set.contains(ue, eid) {
          True -> state
          False -> {
            let ue2 = set.insert(ue, eid)
            let a2 = do_dfs(graph, dst, vn, ue2, a)
            // Collect any new visited nodes that came out of the recursive call
            let vn2 = list.fold(a2, vn, fn(s, id) { set.insert(s, id) })
            #(vn2, ue2, a2)
          }
        }
      })
      |> fn(r) { r.2 }
    }
  }
}
