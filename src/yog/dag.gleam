//// # Frugal Directed Acyclic Graphs
//// 
//// This module provides a strictly typed wrapper `Dag(n, e)` for modeling 
//// Directed Acyclic Graphs (DAGs) without runtime cycle-checking overhead during
//// standard graph building. 
//// 
//// ## The Frugal DAG Philosophy
//// 
//// Yog treats DAGs as a specialized _view_ of a graph, rather than a fundamentally 
//// different structure. The standard way to create a DAG is to:
//// 
//// 1. Build a normal graph first using `yog.directed()` and standard `add_node`/`add_edge`.
//// 2. Once built, "seal" it as a DAG using `dag.from_graph(graph)`. This runs
////    a fast $O(V+E)$ validation.
//// 3. Utilize DAG-only algorithms (like $O(V+E)$ longest paths or transitive closures) 
////    on the returned `Dag` instance.
//// 
//// **Do not build graphs exclusively with `dag.add_edge()`!** 
//// 
//// While mutating functions like `add_node`, `remove_node`, and `add_edge` are 
//// available here, they are designed strictly for *experimentation* or *minor updates* 
//// to an already-validated DAG. Because `add_edge` can introduce a cycle, calling it 
//// forces an $O(V+E)$ property check immediately, returning a `Result(Dag, DagError)`.
//// Attempting to build a 100,000-edge graph using `dag.add_edge` will result in 
//// $O(N \cdot (V+E))$ performance decay.

import gleam/option.{type Option}
import yog/dag/algorithms
import yog/dag/models.{type Dag}
import yog/model.{type NodeId}
import yog/pathfinding/utils.{type Path}

// Re-export models
pub fn from_graph(graph) {
  models.from_graph(graph)
}

pub fn to_graph(dag: Dag(n, e)) {
  models.to_graph(dag)
}

pub fn add_node(dag: Dag(n, e), id, data: n) {
  models.add_node(dag, id, data)
}

pub fn remove_node(dag: Dag(n, e), id) {
  models.remove_node(dag, id)
}

pub fn remove_edge(dag: Dag(n, e), from src, to dst) {
  models.remove_edge(dag, from: src, to: dst)
}

pub fn add_edge(dag: Dag(n, e), from src, to dst, with weight: e) {
  models.add_edge(dag, from: src, to: dst, with: weight)
}

// Re-export algorithms
pub fn topological_sort(dag: Dag(n, e)) {
  algorithms.topological_sort(dag)
}

pub fn shortest_path(
  dag: Dag(n, Int),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  algorithms.shortest_path(dag, from: start, to: goal)
}

pub fn longest_path(dag: Dag(n, Int)) {
  algorithms.longest_path(dag)
}

pub fn transitive_closure(dag: Dag(n, e), with merge_fn: fn(e, e) -> e) {
  algorithms.transitive_closure(dag, merge_fn)
}

pub fn transitive_reduction(dag: Dag(n, e), with merge_fn: fn(e, e) -> e) {
  algorithms.transitive_reduction(dag, merge_fn)
}

pub fn count_reachability(dag: Dag(n, e), direction: algorithms.Direction) {
  algorithms.count_reachability(dag, direction)
}

pub fn lowest_common_ancestors(dag: Dag(n, e), node_a, node_b) {
  algorithms.lowest_common_ancestors(dag, node_a, node_b)
}
