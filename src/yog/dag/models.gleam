import yog/model.{type Graph}
import yog/properties

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
