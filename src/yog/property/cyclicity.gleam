//// Graph [cyclicity](https://en.wikipedia.org/wiki/Cycle_(graph_theory)) and
//// [Directed Acyclic Graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph) analysis.
////
//// This module provides efficient algorithms for detecting cycles in graphs,
//// which is fundamental for topological sorting, deadlock detection, and
//// validating graph properties.
////
//// ## Algorithms
////
//// | Problem | Algorithm | Function | Complexity |
//// |---------|-----------|----------|------------|
//// | Cycle detection (directed) | [Kahn's algorithm](https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm) | `is_acyclic/1`, `is_cyclic/1` | O(V + E) |
//// | Cycle detection (undirected) | [Union-Find / DFS](https://en.wikipedia.org/wiki/Cycle_detection) | `is_acyclic/1`, `is_cyclic/1` | O(V + E) |
////
//// ## Key Concepts
////
//// - **Cycle**: Path that starts and ends at the same vertex
//// - **Simple Cycle**: No repeated vertices (except start/end)
//// - **Acyclic Graph**: Graph with no cycles
//// - **DAG**: Directed Acyclic Graph - directed graph with no directed cycles
//// - **Self-Loop**: Edge from a vertex to itself
////
//// ## Cycle Detection Methods
////
//// **Directed Graphs (Kahn's Algorithm)**:
//// - Repeatedly remove vertices with no incoming edges
//// - If all vertices removed → acyclic
//// - If stuck with remaining vertices → cycle exists
////
//// **Undirected Graphs**:
//// - Track visited nodes during DFS
//// - If we revisit a node (that's not the immediate parent) → cycle exists
//// - Self-loops also count as cycles
////
//// ## Applications of Cycle Detection
////
//// - **Dependency resolution**: Detect circular dependencies in package managers
//// - **Deadlock detection**: Resource allocation graphs in operating systems
//// - **Schema validation**: Ensure no circular references in data models
//// - **Build systems**: Detect circular dependencies in Makefiles
//// - **Course prerequisites**: Validate prerequisite chains aren't circular
////
//// ## Relationship to Other Properties
////
//// - **Tree**: Connected acyclic graph
//// - **Forest**: Disjoint union of trees (acyclic)
//// - **Topological sort**: Only possible on DAGs (acyclic directed graphs)
//// - **Eulerian paths**: Require specific degree conditions related to cycles
////
//// ## References
////
//// - [Wikipedia: Cycle Detection](https://en.wikipedia.org/wiki/Cycle_detection)
//// - [Wikipedia: Directed Acyclic Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
//// - [Wikipedia: Kahn's Algorithm](https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm)
//// - [CP-Algorithms: Finding Cycles](https://cp-algorithms.com/graph/finding-cycle.html)

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}
import yog/traversal

/// Checks if the graph is a Directed Acyclic Graph (DAG) or has no cycles if undirected.
///
/// For directed graphs, a cycle exists if there is a path from a node back to itself.
/// For undirected graphs, a cycle exists if there is a path of length >= 3 from a node back to itself,
/// or a self-loop.
///
/// **Time Complexity:** O(V + E)
pub fn is_acyclic(graph: Graph(n, e)) -> Bool {
  !is_cyclic(graph)
}

/// Checks if the graph contains at least one cycle.
///
/// Logical opposite of `is_acyclic`.
///
/// **Time Complexity:** O(V + E)
pub fn is_cyclic(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    model.Directed -> result.is_error(traversal.topological_sort(graph))
    model.Undirected ->
      do_has_undirected_cycle(graph, model.all_nodes(graph), set.new())
  }
}

fn do_has_undirected_cycle(
  graph: Graph(n, e),
  nodes: List(NodeId),
  visited: Set(NodeId),
) -> Bool {
  case nodes {
    [] -> False
    [node, ..rest] -> {
      case set.contains(visited, node) {
        True -> do_has_undirected_cycle(graph, rest, visited)
        False -> {
          let #(cycle, new_visited) =
            check_undirected_cycle(graph, node, None, visited)
          case cycle {
            True -> True
            False -> do_has_undirected_cycle(graph, rest, new_visited)
          }
        }
      }
    }
  }
}

fn check_undirected_cycle(
  graph: Graph(n, e),
  node: NodeId,
  parent: Option(NodeId),
  visited: Set(NodeId),
) -> #(Bool, Set(NodeId)) {
  let new_visited = set.insert(visited, node)
  let neighbors = model.successor_ids(graph, node)

  use #(_, current_visited), neighbor <- list.fold_until(neighbors, #(
    False,
    new_visited,
  ))
  case set.contains(current_visited, neighbor) {
    True -> {
      let is_parent = case parent {
        Some(p) -> p == neighbor
        None -> False
      }
      case is_parent {
        True -> list.Continue(#(False, current_visited))
        False -> list.Stop(#(True, current_visited))
      }
    }
    False -> {
      let #(has_cycle, next_visited) =
        check_undirected_cycle(graph, neighbor, Some(node), current_visited)
      case has_cycle {
        True -> list.Stop(#(True, next_visited))
        False -> list.Continue(#(False, next_visited))
      }
    }
  }
}
