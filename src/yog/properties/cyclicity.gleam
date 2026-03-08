//// Graph cyclicity and Directed Acyclic Graph (DAG) analysis.

import yog/model.{type Graph}
import yog/traversal

/// Checks if the graph is a Directed Acyclic Graph (DAG) or has no cycles if undirected.
///
/// For directed graphs, a cycle exists if there is a path from a node back to itself.
/// For undirected graphs, a cycle exists if there is a path of length >= 3 from a node back to itself,
/// or a self-loop.
///
/// **Time Complexity:** O(V + E)
pub fn is_acyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_acyclic(graph)
}

/// Checks if the graph contains at least one cycle.
///
/// Logical opposite of `is_acyclic`.
///
/// **Time Complexity:** O(V + E)
pub fn is_cyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_cyclic(graph)
}
