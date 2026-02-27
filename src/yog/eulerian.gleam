import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/traversal

/// Checks if the graph has an Eulerian circuit (a cycle that visits every edge exactly once).
///
/// ## Conditions
/// - **Undirected graph:** All vertices must have even degree and the graph must be connected
/// - **Directed graph:** All vertices must have equal in-degree and out-degree, and the graph must be strongly connected
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 1, with: 1)
///
/// has_eulerian_circuit(graph)  // => True (triangle)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_circuit(graph: Graph(n, e)) -> Bool {
  case dict.size(graph.nodes) {
    0 -> False
    _ -> {
      case graph.kind {
        Undirected -> check_eulerian_circuit_undirected(graph)
        Directed -> check_eulerian_circuit_directed(graph)
      }
    }
  }
}

/// Checks if the graph has an Eulerian path (a path that visits every edge exactly once).
///
/// ## Conditions
/// - **Undirected graph:** Exactly 0 or 2 vertices must have odd degree, and the graph must be connected
/// - **Directed graph:** At most one vertex with (out-degree - in-degree = 1), at most one with (in-degree - out-degree = 1), all others balanced
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// has_eulerian_path(graph)  // => True (path from 1 to 3)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_path(graph: Graph(n, e)) -> Bool {
  case dict.size(graph.nodes) {
    0 -> False
    _ -> {
      case graph.kind {
        Undirected -> check_eulerian_path_undirected(graph)
        Directed -> check_eulerian_path_directed(graph)
      }
    }
  }
}

/// Finds an Eulerian circuit in the graph using Hierholzer's algorithm.
///
/// Returns the path as a list of node IDs that form a circuit (starts and ends at the same node).
/// Returns None if no Eulerian circuit exists.
///
/// **Time Complexity:** O(E)
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 1, with: 1)
///
/// find_eulerian_circuit(graph)  // => Some([1, 2, 3, 1])
/// ```
pub fn find_eulerian_circuit(graph: Graph(n, e)) -> Option(List(NodeId)) {
  case has_eulerian_circuit(graph) {
    False -> None
    True -> {
      // Find any vertex with edges as starting point
      case dict.keys(graph.nodes) |> list.first {
        Error(_) -> None
        Ok(start) -> {
          let result = hierholzer(graph, start)
          case list.is_empty(result) {
            True -> None
            False -> Some(result)
          }
        }
      }
    }
  }
}

/// Finds an Eulerian path in the graph using Hierholzer's algorithm.
///
/// Returns the path as a list of node IDs. Returns None if no Eulerian path exists.
///
/// **Time Complexity:** O(E)
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// find_eulerian_path(graph)  // => Some([1, 2, 3])
/// ```
pub fn find_eulerian_path(graph: Graph(n, e)) -> Option(List(NodeId)) {
  case has_eulerian_path(graph) {
    False -> None
    True -> {
      // Find the starting vertex
      let start = case graph.kind {
        Undirected -> find_odd_degree_vertex(graph)
        Directed -> find_unbalanced_vertex(graph)
      }

      case start {
        None -> None
        Some(start_node) -> {
          let result = hierholzer(graph, start_node)
          case list.is_empty(result) {
            True -> None
            False -> Some(result)
          }
        }
      }
    }
  }
}

// ============= Helper Functions =============

fn check_eulerian_circuit_undirected(graph: Graph(n, e)) -> Bool {
  // All vertices must have even degree
  let all_even =
    dict.keys(graph.nodes)
    |> list.all(fn(node) {
      let degree = get_degree_undirected(graph, node)
      degree % 2 == 0
    })

  case all_even {
    False -> False
    True -> is_connected(graph)
  }
}

fn check_eulerian_path_undirected(graph: Graph(n, e)) -> Bool {
  // Count vertices with odd degree
  let odd_count =
    dict.keys(graph.nodes)
    |> list.filter(fn(node) {
      let degree = get_degree_undirected(graph, node)
      degree % 2 == 1
    })
    |> list.length()

  // Must be 0 or 2 vertices with odd degree
  case odd_count {
    0 -> is_connected(graph)
    2 -> is_connected(graph)
    _ -> False
  }
}

fn check_eulerian_circuit_directed(graph: Graph(n, e)) -> Bool {
  // All vertices must have equal in-degree and out-degree
  let all_balanced =
    dict.keys(graph.nodes)
    |> list.all(fn(node) {
      let in_deg = get_in_degree(graph, node)
      let out_deg = get_out_degree(graph, node)
      in_deg == out_deg
    })

  all_balanced && is_connected(graph)
}

fn check_eulerian_path_directed(graph: Graph(n, e)) -> Bool {
  let #(start_count, end_count, balanced) =
    dict.keys(graph.nodes)
    |> list.fold(#(0, 0, True), fn(acc, node) {
      let #(starts, ends, still_balanced) = acc
      let in_deg = get_in_degree(graph, node)
      let out_deg = get_out_degree(graph, node)
      let diff = out_deg - in_deg

      case diff {
        1 -> #(starts + 1, ends, still_balanced)
        -1 -> #(starts, ends + 1, still_balanced)
        0 -> acc
        _ -> #(starts, ends, False)
      }
    })

  case balanced {
    False -> False
    True -> {
      case start_count, end_count {
        0, 0 -> is_connected(graph)
        1, 1 -> is_connected(graph)
        _, _ -> False
      }
    }
  }
}

fn get_degree_undirected(graph: Graph(n, e), node: NodeId) -> Int {
  case dict.get(graph.out_edges, node) {
    Error(_) -> 0
    Ok(neighbors) -> dict.size(neighbors)
  }
}

fn get_in_degree(graph: Graph(n, e), node: NodeId) -> Int {
  case dict.get(graph.in_edges, node) {
    Error(_) -> 0
    Ok(neighbors) -> dict.size(neighbors)
  }
}

fn get_out_degree(graph: Graph(n, e), node: NodeId) -> Int {
  case dict.get(graph.out_edges, node) {
    Error(_) -> 0
    Ok(neighbors) -> dict.size(neighbors)
  }
}

fn is_connected(graph: Graph(n, e)) -> Bool {
  case dict.keys(graph.nodes) |> list.first {
    Error(_) -> True
    Ok(start) -> {
      let visited =
        traversal.walk(from: start, in: graph, using: traversal.BreadthFirst)
      list.length(visited) == dict.size(graph.nodes)
    }
  }
}

fn find_odd_degree_vertex(graph: Graph(n, e)) -> Option(NodeId) {
  dict.keys(graph.nodes)
  |> list.find(fn(node) {
    let degree = get_degree_undirected(graph, node)
    degree % 2 == 1
  })
  |> option.from_result()
  // If no odd degree vertex, start from any vertex with edges
  |> option.or(
    dict.keys(graph.nodes)
    |> list.find(fn(node) { get_degree_undirected(graph, node) > 0 })
    |> option.from_result(),
  )
}

fn find_unbalanced_vertex(graph: Graph(n, e)) -> Option(NodeId) {
  dict.keys(graph.nodes)
  |> list.find(fn(node) {
    let in_deg = get_in_degree(graph, node)
    let out_deg = get_out_degree(graph, node)
    out_deg > in_deg
  })
  |> option.from_result()
  // If all balanced, start from any vertex with edges
  |> option.or(
    dict.keys(graph.nodes)
    |> list.find(fn(node) { get_out_degree(graph, node) > 0 })
    |> option.from_result(),
  )
}

// Hierholzer's algorithm implementation
// Returns path in correct order
fn hierholzer(graph: Graph(n, e), start: NodeId) -> List(NodeId) {
  let all_edges = build_edge_list(graph)
  let #(_remaining, path) = do_hierholzer(graph, start, all_edges, [])
  path
}

fn do_hierholzer(
  graph: Graph(n, e),
  current: NodeId,
  available_edges: List(#(NodeId, NodeId)),
  path: List(NodeId),
) -> #(List(#(NodeId, NodeId)), List(NodeId)) {
  // Find an unused edge from current
  case find_and_remove_edge(graph, current, available_edges) {
    None -> {
      // No more edges from current, add to path
      #(available_edges, [current, ..path])
    }
    Some(#(next, remaining_edges)) -> {
      // Follow the edge and continue
      do_hierholzer(graph, next, remaining_edges, path)
      // After exhausting path from 'next', add current
      |> fn(result) {
        let #(edges_left, built_path) = result
        #(edges_left, [current, ..built_path])
      }
    }
  }
}

fn find_and_remove_edge(
  graph: Graph(n, e),
  from: NodeId,
  edges: List(#(NodeId, NodeId)),
) -> Option(#(NodeId, List(#(NodeId, NodeId)))) {
  find_and_remove_edge_helper(graph, from, edges, [])
}

fn find_and_remove_edge_helper(
  graph: Graph(n, e),
  from: NodeId,
  edges: List(#(NodeId, NodeId)),
  checked: List(#(NodeId, NodeId)),
) -> Option(#(NodeId, List(#(NodeId, NodeId)))) {
  case edges {
    [] -> None
    [#(f, t), ..rest] if f == from -> {
      // Found an edge from 'from'
      let remaining = case graph.kind {
        Directed -> list.append(checked, rest)
        Undirected -> {
          // For undirected, also remove the reverse edge
          list.append(checked, rest)
          |> list.filter(fn(edge) {
            let #(a, b) = edge
            a != t || b != f
          })
        }
      }
      Some(#(t, remaining))
    }
    [edge, ..rest] -> {
      // Not the right edge, keep looking
      find_and_remove_edge_helper(graph, from, rest, [edge, ..checked])
    }
  }
}

fn build_edge_list(graph: Graph(n, e)) -> List(#(NodeId, NodeId)) {
  dict.fold(graph.out_edges, [], fn(acc, from, neighbors) {
    let edges_from_node =
      dict.keys(neighbors)
      |> list.map(fn(to) { #(from, to) })
    list.append(acc, edges_from_node)
  })
}
