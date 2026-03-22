//// # ⚠️ Deprecated Module
////
//// This module has been renamed to `yog/dag/algorithm` (singular).
//// Please update your imports to use `yog/dag/algorithm` instead.
////
//// This module will be removed in a future version.

import gleam/dict
import gleam/option.{type Option}
import yog/dag/algorithm
import yog/dag/model as dag_model
import yog/model.{type NodeId}
import yog/pathfinding/utils.{type Path}

// Re-export types
pub type Dag(node_data, edge_data) =
  dag_model.Dag(node_data, edge_data)

pub type Direction =
  algorithm.Direction

// Note: Direction constructors (Ancestors, Descendants) can be accessed via:
// - import yog/dag/algorithm.{Ancestors, Descendants}
// - Or use them as algorithm.Ancestors and algorithm.Descendants

/// Returns a topological ordering of all nodes in the DAG.
///
/// @deprecated Use `yog/dag/algorithm.topological_sort` instead
@deprecated("Use yog/dag/algorithm.topological_sort instead")
pub fn topological_sort(dag: Dag(n, e)) -> List(NodeId) {
  algorithm.topological_sort(dag)
}

/// Finds the longest path (critical path) in a weighted DAG.
///
/// @deprecated Use `yog/dag/algorithm.longest_path` instead
@deprecated("Use yog/dag/algorithm.longest_path instead")
pub fn longest_path(dag: Dag(n, Int)) -> List(NodeId) {
  algorithm.longest_path(dag)
}

/// Computes the transitive closure of a DAG.
///
/// @deprecated Use `yog/dag/algorithm.transitive_closure` instead
@deprecated("Use yog/dag/algorithm.transitive_closure instead")
pub fn transitive_closure(
  dag: Dag(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Dag(n, e) {
  algorithm.transitive_closure(dag, merge_fn)
}

/// Computes the transitive reduction of a DAG.
///
/// @deprecated Use `yog/dag/algorithm.transitive_reduction` instead
@deprecated("Use yog/dag/algorithm.transitive_reduction instead")
pub fn transitive_reduction(
  dag: Dag(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Dag(n, e) {
  algorithm.transitive_reduction(dag, merge_fn)
}

/// Finds the shortest path between two specific nodes in a weighted DAG.
///
/// @deprecated Use `yog/dag/algorithm.shortest_path` instead
@deprecated("Use yog/dag/algorithm.shortest_path instead")
pub fn shortest_path(
  dag: Dag(n, Int),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  algorithm.shortest_path(dag, start, goal)
}

/// Counts the number of ancestors or descendants for every node.
///
/// @deprecated Use `yog/dag/algorithm.count_reachability` instead
@deprecated("Use yog/dag/algorithm.count_reachability instead")
pub fn count_reachability(
  dag: Dag(n, e),
  direction: Direction,
) -> dict.Dict(NodeId, Int) {
  algorithm.count_reachability(dag, direction)
}

/// Finds the lowest common ancestors (LCAs) of two nodes.
///
/// @deprecated Use `yog/dag/algorithm.lowest_common_ancestors` instead
@deprecated("Use yog/dag/algorithm.lowest_common_ancestors instead")
pub fn lowest_common_ancestors(
  dag: Dag(n, e),
  node_a: NodeId,
  node_b: NodeId,
) -> List(NodeId) {
  algorithm.lowest_common_ancestors(dag, node_a, node_b)
}
