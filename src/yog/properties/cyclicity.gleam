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
