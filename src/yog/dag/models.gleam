import yog/model.{type Graph}
import yog/properties/cyclicity as properties

pub type DagError {
  CycleDetected
}

/// Opaque wrapper. Users can see the type, but not construct it directly.
pub opaque type Dag(node_data, edge_data) {
  Dag(graph: Graph(node_data, edge_data))
}

/// The Guard: Uses `is_acyclic` to validate the graph.
pub fn from_graph(graph: Graph(n, e)) -> Result(Dag(n, e), DagError) {
  case properties.is_acyclic(graph) {
    True -> Ok(Dag(graph))
    False -> Error(CycleDetected)
  }
}

/// The Exit: Unwraps the Dag back into a standard Graph for general use.
pub fn to_graph(dag: Dag(n, e)) -> Graph(n, e) {
  dag.graph
}

/// Adds a node to the DAG. This cannot create a cycle, so it is safe and guaranteed to return a Dag.
pub fn add_node(dag: Dag(n, e), id: model.NodeId, data: n) -> Dag(n, e) {
  Dag(model.add_node(dag.graph, id, data))
}

/// Removes a node from the DAG. This cannot create a cycle, so it is safe and guaranteed to return a Dag.
pub fn remove_node(dag: Dag(n, e), id: model.NodeId) -> Dag(n, e) {
  Dag(model.remove_node(dag.graph, id))
}

/// Removes an edge from the DAG. This cannot create a cycle, so it is safe and guaranteed to return a Dag.
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
  model.add_edge(dag.graph, from: src, to: dst, with: weight)
  |> from_graph()
}
