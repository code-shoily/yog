//// [Eulerian path](https://en.wikipedia.org/wiki/Eulerian_path) and circuit algorithms using 
//// [Hierholzer's algorithm](https://en.wikipedia.org/wiki/Eulerian_path#Hierholzer's_algorithm).
////
//// An Eulerian path visits every edge exactly once.
//// An Eulerian circuit visits every edge exactly once and returns to the start.
//// These problems originated from the famous [Seven Bridges of Königsberg](https://en.wikipedia.org/wiki/Seven_Bridges_of_K%C3%B6nigsberg)
//// solved by Leonhard Euler in 1736, founding graph theory.
////
//// ## Algorithms
////
//// | Problem | Algorithm | Function | Complexity |
//// |---------|-----------|----------|------------|
//// | Eulerian circuit check | Degree counting | `has_eulerian_circuit/1` | O(V + E) |
//// | Eulerian path check | Degree counting | `has_eulerian_path/1` | O(V + E) |
//// | Find circuit | [Hierholzer's](https://en.wikipedia.org/wiki/Eulerian_path#Hierholzer's_algorithm) | `find_eulerian_circuit/1` | O(E) |
//// | Find path | Hierholzer's | `find_eulerian_path/1` | O(E) |
////
//// ## Key Concepts
////
//// - **Eulerian Circuit**: Closed walk using every edge exactly once
//// - **Eulerian Path**: Open walk using every edge exactly once
//// - **Eulerian Graph**: Graph with an Eulerian circuit
//// - **Semi-Eulerian Graph**: Graph with an Eulerian path but no circuit
////
//// ## Necessary and Sufficient Conditions
////
//// **Undirected Graphs:**
//// - **Circuit**: All vertices have even degree, connected (ignoring isolates)
//// - **Path**: Exactly 0 or 2 vertices have odd degree, connected
////
//// **Directed Graphs:**
//// - **Circuit**: In-degree = Out-degree for all vertices, weakly connected
//// - **Path**: At most one vertex has (out - in) = 1 (start),
////   at most one has (in - out) = 1 (end), all others balanced
////
//// ## Hierholzer's Algorithm
////
//// 1. Start from any vertex (or odd-degree vertex for path)
//// 2. Follow unused edges until returning to start (forming a cycle)
//// 3. If unused edges remain, find vertex on current path with unused edges
//// 4. Form another cycle from that vertex and splice into main path
//// 5. Repeat until all edges used
////
//// ## Relationship to Other Problems
////
//// - **Chinese Postman**: Find shortest closed walk using every edge at least once
////   (adds duplicate edges to make graph Eulerian)
//// - **Route Inspection**: Variant allowing non-closed walks
//// - **Hamiltonian Path**: Visits every *vertex* once (much harder, NP-complete)
////
//// ## Use Cases
////
//// - **Route planning**: Garbage collection, snow plowing, mail delivery
//// - **DNA sequencing**: Constructing genomes from overlapping fragments
//// - **Circuit board drilling**: Optimizing drill paths for PCB manufacturing
//// - **Layout printing**: Efficient pen plotting without lifting
//// - **Museum guard tours**: Covering all corridors efficiently
////
//// ## History
////
//// In 1736, Leonhard Euler proved that the Seven Bridges of Königsberg problem
//// had no solution, establishing the conditions for Eulerian paths and founding
//// graph theory as a mathematical discipline.
////
//// ## References
////
//// - [Wikipedia: Eulerian Path](https://en.wikipedia.org/wiki/Eulerian_path)
//// - [Wikipedia: Seven Bridges of Königsberg](https://en.wikipedia.org/wiki/Seven_Bridges_of_K%C3%B6nigsberg)
//// - [Wikipedia: Hierholzer's Algorithm](https://en.wikipedia.org/wiki/Eulerian_path#Hierholzer's_algorithm)
//// - [Wikipedia: Route Inspection Problem](https://en.wikipedia.org/wiki/Route_inspection_problem)
//// - [CP-Algorithms: Eulerian Path](https://cp-algorithms.com/graph/euler_path.html)

import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId, Directed, Undirected}

/// Checks if the graph has an Eulerian circuit.
///
/// ## Conditions
/// - **Undirected:** All vertices even degree + connected.
/// - **Directed:** All vertices balanced (in == out) + connected.
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

/// Checks if the graph has an Eulerian path.
///
/// ## Conditions
/// - **Undirected:** 0 or 2 odd-degree vertices + connected.
/// - **Directed:** At most one (out - in = 1), at most one (in - out = 1), others balanced.
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
/// Returns the path as a list of node IDs forming a circuit.
///
/// **Time Complexity:** O(E)
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
/// Returns the path as a list of node IDs.
///
/// **Time Complexity:** O(E)
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
  let all_even =
    dict.keys(graph.nodes)
    |> list.all(fn(node) { model.degree(graph, node) % 2 == 0 })

  case all_even {
    False -> False
    True -> is_connected(graph)
  }
}

fn check_eulerian_path_undirected(graph: Graph(n, e)) -> Bool {
  let odd_count =
    dict.keys(graph.nodes)
    |> list.filter(fn(node) { model.degree(graph, node) % 2 == 1 })
    |> list.length()

  case odd_count {
    0 -> is_connected(graph)
    2 -> is_connected(graph)
    _ -> False
  }
}

fn check_eulerian_circuit_directed(graph: Graph(n, e)) -> Bool {
  let all_balanced =
    dict.keys(graph.nodes)
    |> list.all(fn(node) {
      model.in_degree(graph, node) == model.out_degree(graph, node)
    })

  all_balanced && is_connected(graph)
}

fn check_eulerian_path_directed(graph: Graph(n, e)) -> Bool {
  let #(start_count, end_count, balanced) =
    dict.keys(graph.nodes)
    |> list.fold(#(0, 0, True), fn(acc, node) {
      let diff = model.out_degree(graph, node) - model.in_degree(graph, node)
      case diff, acc {
        1, #(s, e, b) -> #(s + 1, e, b)
        -1, #(s, e, b) -> #(s, e + 1, b)
        0, _ -> acc
        _, #(s, e, _) -> #(s, e, False)
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

fn is_connected(graph: Graph(n, e)) -> Bool {
  case dict.keys(graph.nodes) |> list.first {
    Error(_) -> True
    Ok(start) -> {
      let visited = walk_all_neighbors(graph, start, set.new())
      set.size(visited) == dict.size(graph.nodes)
    }
  }
}

fn walk_all_neighbors(
  graph: Graph(n, e),
  node: NodeId,
  visited: Set(NodeId),
) -> Set(NodeId) {
  case set.contains(visited, node) {
    True -> visited
    False -> {
      let new_visited = set.insert(visited, node)
      use v, neighbor <- list.fold(model.neighbor_ids(graph, node), new_visited)
      walk_all_neighbors(graph, neighbor, v)
    }
  }
}

fn find_odd_degree_vertex(graph: Graph(n, e)) -> Option(NodeId) {
  dict.keys(graph.nodes)
  |> list.find(fn(node) { model.degree(graph, node) % 2 == 1 })
  |> option.from_result()
  |> option.or(
    dict.keys(graph.nodes)
    |> list.find(fn(node) { model.degree(graph, node) > 0 })
    |> option.from_result(),
  )
}

fn find_unbalanced_vertex(graph: Graph(n, e)) -> Option(NodeId) {
  dict.keys(graph.nodes)
  |> list.find(fn(node) {
    model.out_degree(graph, node) > model.in_degree(graph, node)
  })
  |> option.from_result()
  |> option.or(
    dict.keys(graph.nodes)
    |> list.find(fn(node) { model.out_degree(graph, node) > 0 })
    |> option.from_result(),
  )
}

// Hierholzer's algorithm implementation
// Uses Dict(NodeId, List(NodeId)) for O(1) edge lookup/removal per step.
fn hierholzer(graph: Graph(n, e), start: NodeId) -> List(NodeId) {
  let adj = build_adjacency_lists(graph)
  let #(_remaining, path) = do_hierholzer(graph, start, adj, [])
  path
}

fn do_hierholzer(
  graph: Graph(n, e),
  current: NodeId,
  adj: dict.Dict(NodeId, List(NodeId)),
  path: List(NodeId),
) -> #(dict.Dict(NodeId, List(NodeId)), List(NodeId)) {
  // Try to pop the first available neighbor from the current node's list
  case dict.get(adj, current) {
    Error(_) | Ok([]) -> {
      // No more edges from current, add to path
      #(adj, [current, ..path])
    }
    Ok([next, ..rest]) -> {
      // Remove the edge current -> next by updating the adjacency list
      let adj = dict.insert(adj, current, rest)

      // For undirected graphs, also remove the reverse edge (next -> current)
      let adj = case graph.kind {
        Directed -> adj
        Undirected -> remove_first_occurrence(adj, next, current)
      }

      // Follow the edge and continue
      do_hierholzer(graph, next, adj, path)
      |> fn(result) {
        let #(edges_left, built_path) = result
        #(edges_left, [current, ..built_path])
      }
    }
  }
}

// Remove the first occurrence of `target` from `node`'s neighbor list.
fn remove_first_occurrence(
  adj: dict.Dict(NodeId, List(NodeId)),
  node: NodeId,
  target: NodeId,
) -> dict.Dict(NodeId, List(NodeId)) {
  case dict.get(adj, node) {
    Error(_) -> adj
    Ok(neighbors) -> {
      let updated = do_remove_first(neighbors, target, [])
      dict.insert(adj, node, updated)
    }
  }
}

fn do_remove_first(
  items: List(NodeId),
  target: NodeId,
  checked: List(NodeId),
) -> List(NodeId) {
  case items {
    [] -> list.reverse(checked)
    [head, ..tail] if head == target -> list.append(list.reverse(checked), tail)
    [head, ..tail] -> do_remove_first(tail, target, [head, ..checked])
  }
}

// Build Dict(NodeId, List(NodeId)) from the graph's out_edges.
fn build_adjacency_lists(graph: Graph(n, e)) -> dict.Dict(NodeId, List(NodeId)) {
  dict.fold(graph.out_edges, dict.new(), fn(acc, from, neighbors) {
    dict.insert(acc, from, dict.keys(neighbors))
  })
}
