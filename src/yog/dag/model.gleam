//// # ⚠️ Experimental Module
////
//// This module is experimental and provides minimal, working functionality.
//// The implementation is functional but may not be fully optimized for performance.
////
//// **Expected changes:**
//// - Additional features and algorithms will be added
//// - Performance enhancements and optimizations
//// - API may be subject to change in future versions
////
//// Use with caution in production environments.

import yog/model.{type Graph}
import yog/property/cyclicity as properties

/// Error type representing why a graph cannot be treated as a DAG.
pub type DagError {
  /// Returned when attempting to create a DAG from a graph that contains cycles.
  CycleDetected
  /// Returned when attempting to add an invalid edge to a DAG.
  InvalidEdge(String)
}

/// An opaque wrapper around a `Graph` that guarantees acyclicity at the type level.
///
/// Unlike a regular `Graph`, a `Dag` is statically proven to contain no cycles,
/// enabling total functions for operations like topological sorting.
///
/// ## Construction
///
/// Create a `Dag` from an existing graph using `from_graph()`:
///
/// ```gleam
/// import yog/dag/model
///
/// case model.from_graph(my_graph) {
///   Ok(dag) -> // Safe to use DAG-only operations
///   Error(model.CycleDetected) -> // Handle cyclic graph
/// }
/// ```
///
/// ## Type Safety
///
/// Once constructed, the `Dag` type ensures that all operations preserve acyclicity.
/// Functions that could potentially create cycles (like `add_edge`) return `Result` types.
pub opaque type Dag(node_data, edge_data) {
  Dag(graph: Graph(node_data, edge_data))
}

/// Attempts to create a `Dag` from a regular `Graph`.
///
/// Validates that the graph contains no cycles. If validation passes, returns
/// `Ok(Dag)`; otherwise returns `Error(CycleDetected)`.
///
/// **Time Complexity:** O(V + E)
pub fn from_graph(graph: Graph(n, e)) -> Result(Dag(n, e), DagError) {
  case properties.is_acyclic(graph) {
    True -> Ok(Dag(graph))
    False -> Error(CycleDetected)
  }
}

/// Unwraps a `Dag` back into a regular `Graph`.
///
/// This is useful when you need to use operations that work on any graph type,
/// or when you want to export the DAG to formats that accept general graphs.
pub fn to_graph(dag: Dag(n, e)) -> Graph(n, e) {
  dag.graph
}

/// Adds a node to the DAG.
///
/// Adding a node cannot create a cycle, so this operation is infallible and
/// returns a `Dag` directly.
///
/// **Time Complexity:** O(1)
pub fn add_node(dag: Dag(n, e), id: model.NodeId, data: n) -> Dag(n, e) {
  Dag(model.add_node(dag.graph, id, data))
}

/// Removes a node and all its connected edges from the DAG.
///
/// Removing nodes/edges cannot create a cycle, so this operation is infallible
/// and returns a `Dag` directly.
///
/// **Time Complexity:** O(V + E) in the worst case (removing all edges of the node).
pub fn remove_node(dag: Dag(n, e), id: model.NodeId) -> Dag(n, e) {
  Dag(model.remove_node(dag.graph, id))
}

/// Removes an edge from the DAG.
///
/// Removing edges cannot create a cycle, so this operation is infallible
/// and returns a `Dag` directly.
///
/// **Time Complexity:** O(1)
pub fn remove_edge(
  dag: Dag(n, e),
  from src: model.NodeId,
  to dst: model.NodeId,
) -> Dag(n, e) {
  Dag(model.remove_edge(dag.graph, src, dst))
}

/// Adds an edge to the DAG. 
/// Because adding an edge can potentially create a cycle, this operation must validate the resulting
/// graph and returns a `Result(Dag, DagError)`.
///
/// **Time Complexity:** O(V+E) (due to required cycle check on insertion).
pub fn add_edge(
  dag: Dag(n, e),
  from src: model.NodeId,
  to dst: model.NodeId,
  with weight: e,
) -> Result(Dag(n, e), DagError) {
  case model.add_edge(dag.graph, from: src, to: dst, with: weight) {
    Ok(graph) -> from_graph(graph)
    Error(msg) -> Error(InvalidEdge(msg))
  }
}
