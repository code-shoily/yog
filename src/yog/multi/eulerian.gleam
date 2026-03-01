import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import yog/model.{Directed, Undirected}
import yog/multi/model.{type MultiGraph} as m

// EdgeId and NodeId are both Int; defined locally to keep signatures readable
type EdgeId =
  Int

type NodeId =
  Int

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Returns `True` if the multigraph has an Eulerian circuit — a closed walk
/// that traverses every edge exactly once.
///
/// Conditions:
/// - **Undirected:** all nodes have even degree and the graph is connected.
/// - **Directed:** every node has equal in-degree and out-degree and the
///   graph is (weakly) connected.
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_circuit(graph: MultiGraph(n, e)) -> Bool {
  case dict.size(graph.nodes) {
    0 -> False
    _ ->
      case graph.kind {
        Undirected -> all_even_degree(graph) && is_connected(graph)
        Directed -> all_balanced_degree(graph) && is_connected(graph)
      }
  }
}

/// Returns `True` if the multigraph has an Eulerian path — an open walk that
/// traverses every edge exactly once.
///
/// Conditions:
/// - **Undirected:** exactly 0 or 2 nodes have odd degree and the graph is connected.
/// - **Directed:** at most one node with (out − in = 1), at most one with
///   (in − out = 1), all others balanced; graph must be connected.
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_path(graph: MultiGraph(n, e)) -> Bool {
  case dict.size(graph.nodes) {
    0 -> False
    _ ->
      case graph.kind {
        Undirected -> {
          let odd_count =
            dict.keys(graph.nodes)
            |> list.filter(fn(n) { m.out_degree(graph, n) % 2 == 1 })
            |> list.length()
          { odd_count == 0 || odd_count == 2 } && is_connected(graph)
        }
        Directed -> {
          let #(starts, ends, balanced) =
            dict.keys(graph.nodes)
            |> list.fold(#(0, 0, True), fn(acc, n) {
              let #(s, e, ok) = acc
              let diff = m.out_degree(graph, n) - m.in_degree(graph, n)
              case diff {
                1 -> #(s + 1, e, ok)
                -1 -> #(s, e + 1, ok)
                0 -> acc
                _ -> #(s, e, False)
              }
            })
          balanced
          && { starts == 0 && ends == 0 || starts == 1 && ends == 1 }
          && is_connected(graph)
        }
      }
  }
}

/// Finds an Eulerian circuit using Hierholzer's algorithm adapted for
/// multigraphs.  The circuit is returned as a list of **`EdgeId`s** rather
/// than node IDs, which avoids ambiguity when parallel edges exist.
///
/// Returns `None` if no Eulerian circuit exists.
///
/// **Time Complexity:** O(E)
pub fn find_eulerian_circuit(graph: MultiGraph(n, e)) -> Option(List(EdgeId)) {
  case has_eulerian_circuit(graph) {
    False -> None
    True ->
      case dict.keys(graph.nodes) |> list.first() {
        Error(_) -> None
        Ok(start) -> run_hierholzer(graph, start)
      }
  }
}

/// Finds an Eulerian path using Hierholzer's algorithm adapted for multigraphs.
/// Returns the path as a list of **`EdgeId`s**.  Returns `None` if no path exists.
///
/// **Time Complexity:** O(E)
pub fn find_eulerian_path(graph: MultiGraph(n, e)) -> Option(List(EdgeId)) {
  case has_eulerian_path(graph) {
    False -> None
    True ->
      case find_path_start(graph) {
        None -> None
        Some(s) -> run_hierholzer(graph, s)
      }
  }
}

// ---------------------------------------------------------------------------
// Internal: Hierholzer adapted for multigraphs
// ---------------------------------------------------------------------------

fn run_hierholzer(
  graph: MultiGraph(n, e),
  start: NodeId,
) -> Option(List(EdgeId)) {
  let all_ids = m.all_edge_ids(graph) |> set.from_list()
  let #(_used, path) = do_hierholzer(graph, start, all_ids, [])
  case list.is_empty(path) {
    True -> None
    False -> Some(path)
  }
}

fn do_hierholzer(
  graph: MultiGraph(n, e),
  current: NodeId,
  available: Set(EdgeId),
  path: List(EdgeId),
) -> #(Set(EdgeId), List(EdgeId)) {
  case pick_edge(graph, current, available) {
    None -> #(available, path)
    Some(#(next_node, eid)) -> {
      let available2 = set.delete(available, eid)
      let #(av3, built) = do_hierholzer(graph, next_node, available2, path)
      #(av3, [eid, ..built])
    }
  }
}

fn pick_edge(
  graph: MultiGraph(n, e),
  current: NodeId,
  available: Set(EdgeId),
) -> Option(#(NodeId, EdgeId)) {
  m.successors(graph, current)
  |> list.find_map(fn(s) {
    let #(dst, eid, _data) = s
    case set.contains(available, eid) {
      True -> Ok(#(dst, eid))
      False -> Error(Nil)
    }
  })
  |> option.from_result()
}

// ---------------------------------------------------------------------------
// Internal: degree / connectivity helpers
// ---------------------------------------------------------------------------

fn all_even_degree(graph: MultiGraph(n, e)) -> Bool {
  dict.keys(graph.nodes)
  |> list.all(fn(n) { m.out_degree(graph, n) % 2 == 0 })
}

fn all_balanced_degree(graph: MultiGraph(n, e)) -> Bool {
  dict.keys(graph.nodes)
  |> list.all(fn(n) { m.out_degree(graph, n) == m.in_degree(graph, n) })
}

fn is_connected(graph: MultiGraph(n, e)) -> Bool {
  case dict.keys(graph.nodes) |> list.first() {
    Error(_) -> True
    Ok(start) -> {
      let visited = bfs_node_set(graph, start, set.new())
      set.size(visited) == dict.size(graph.nodes)
    }
  }
}

fn bfs_node_set(
  graph: MultiGraph(n, e),
  current: NodeId,
  visited: Set(NodeId),
) -> Set(NodeId) {
  case set.contains(visited, current) {
    True -> visited
    False -> {
      let visited2 = set.insert(visited, current)
      let neighbors =
        list.append(
          m.successors(graph, current) |> list.map(fn(s) { s.0 }),
          m.predecessors(graph, current) |> list.map(fn(p) { p.0 }),
        )
        |> list.unique()
      list.fold(neighbors, visited2, fn(acc, neighbor) {
        bfs_node_set(graph, neighbor, acc)
      })
    }
  }
}

fn find_path_start(graph: MultiGraph(n, e)) -> Option(NodeId) {
  case graph.kind {
    Undirected ->
      dict.keys(graph.nodes)
      |> list.find(fn(n) { m.out_degree(graph, n) % 2 == 1 })
      |> result.or(
        dict.keys(graph.nodes)
        |> list.find(fn(n) { m.out_degree(graph, n) > 0 }),
      )
      |> option.from_result()
    Directed ->
      dict.keys(graph.nodes)
      |> list.find(fn(n) { m.out_degree(graph, n) > m.in_degree(graph, n) })
      |> result.or(
        dict.keys(graph.nodes)
        |> list.find(fn(n) { m.out_degree(graph, n) > 0 }),
      )
      |> option.from_result()
  }
}
