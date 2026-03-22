//// # ⚠️ Deprecated Module
////
//// This module has been renamed to `yog/dag/model` (singular).
//// Please update your imports to use `yog/dag/model` instead.
////
//// This module will be removed in a future version.

import yog/dag/model as dag_model
import yog/model.{type Graph, type NodeId}

// Re-export types
pub type DagError =
  dag_model.DagError

pub type Dag(node_data, edge_data) =
  dag_model.Dag(node_data, edge_data)

/// Attempts to create a `Dag` from a regular `Graph`.
///
/// @deprecated Use `yog/dag/model.from_graph` instead
@deprecated("Use yog/dag/model.from_graph instead")
pub fn from_graph(graph: Graph(n, e)) -> Result(Dag(n, e), DagError) {
  dag_model.from_graph(graph)
}

/// Unwraps a `Dag` back into a regular `Graph`.
///
/// @deprecated Use `yog/dag/model.to_graph` instead
@deprecated("Use yog/dag/model.to_graph instead")
pub fn to_graph(dag: Dag(n, e)) -> Graph(n, e) {
  dag_model.to_graph(dag)
}

/// Adds a node to the DAG.
///
/// @deprecated Use `yog/dag/model.add_node` instead
@deprecated("Use yog/dag/model.add_node instead")
pub fn add_node(dag: Dag(n, e), id: NodeId, data: n) -> Dag(n, e) {
  dag_model.add_node(dag, id, data)
}

/// Removes a node and all its connected edges from the DAG.
///
/// @deprecated Use `yog/dag/model.remove_node` instead
@deprecated("Use yog/dag/model.remove_node instead")
pub fn remove_node(dag: Dag(n, e), id: NodeId) -> Dag(n, e) {
  dag_model.remove_node(dag, id)
}

/// Removes an edge from the DAG.
///
/// @deprecated Use `yog/dag/model.remove_edge` instead
@deprecated("Use yog/dag/model.remove_edge instead")
pub fn remove_edge(
  dag: Dag(n, e),
  from src: NodeId,
  to dst: NodeId,
) -> Dag(n, e) {
  dag_model.remove_edge(dag, src, dst)
}

/// Adds an edge to the DAG.
///
/// @deprecated Use `yog/dag/model.add_edge` instead
@deprecated("Use yog/dag/model.add_edge instead")
pub fn add_edge(
  dag: Dag(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
) -> Result(Dag(n, e), DagError) {
  dag_model.add_edge(dag, src, dst, weight)
}
