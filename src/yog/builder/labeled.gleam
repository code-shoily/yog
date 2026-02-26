//// A builder for creating graphs using arbitrary labels instead of integer IDs.
////
//// This module provides a convenient way to build graphs when your nodes are
//// naturally identified by strings or other types, rather than integers. The
//// builder maintains a mapping from labels to internal integer IDs and
//// converts to a standard `Graph` when needed.
////
//// ## Example
////
//// ```gleam
//// import yog/builder/labeled
//// import yog/pathfinding
//// import gleam/int
////
//// pub fn main() {
////   // Build a graph using string labels
////   let builder =
////     labeled.directed()
////     |> labeled.add_edge("home", "work", 10)
////     |> labeled.add_edge("work", "gym", 5)
////     |> labeled.add_edge("home", "gym", 12)
////
////   // Convert to a Graph to use with algorithms
////   let graph = labeled.to_graph(builder)
////
////   // Get the node IDs for the labels we care about
////   let assert Ok(home_id) = labeled.get_id(builder, "home")
////   let assert Ok(gym_id) = labeled.get_id(builder, "gym")
////
////   // Now use standard graph algorithms
////   case pathfinding.shortest_path(
////     in: graph,
////     from: home_id,
////     to: gym_id,
////     with_zero: 0,
////     with_add: int.add,
////     with_compare: int.compare,
////   ) {
////     Ok(path) -> // Path found!
////     Error(_) -> // No path
////   }
//// }
//// ```

import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import yog/model.{type Graph, type GraphType, type NodeId}

/// A builder for graphs that use arbitrary labels instead of integer node IDs.
///
/// The builder maintains an internal mapping from labels to integer IDs and
/// stores the label as the node's data in the underlying graph.
pub type Builder(label, edge_data) {
  Builder(
    /// The underlying graph structure
    graph: Graph(label, edge_data),
    /// Mapping from label to internal node ID
    label_to_id: Dict(label, NodeId),
    /// Next available node ID
    next_id: NodeId,
  )
}

/// Creates a new empty labeled graph builder.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
/// import yog/model.{Directed}
///
/// let builder = labeled.new(Directed)
/// ```
pub fn new(graph_type: GraphType) -> Builder(label, edge_data) {
  Builder(graph: model.new(graph_type), label_to_id: dict.new(), next_id: 0)
}

/// Creates a new empty labeled directed graph builder.
///
/// This is a convenience function equivalent to `labeled.new(Directed)`.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
///
/// let builder =
///   labeled.directed()
///   |> labeled.add_edge("home", "work", 10)
/// ```
pub fn directed() -> Builder(label, edge_data) {
  Builder(graph: model.new(model.Directed), label_to_id: dict.new(), next_id: 0)
}

/// Creates a new empty labeled undirected graph builder.
///
/// This is a convenience function equivalent to `labeled.new(Undirected)`.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
///
/// let builder =
///   labeled.undirected()
///   |> labeled.add_edge("A", "B", 5)
/// ```
pub fn undirected() -> Builder(label, edge_data) {
  Builder(
    graph: model.new(model.Undirected),
    label_to_id: dict.new(),
    next_id: 0,
  )
}

/// Gets or creates a node for the given label, returning the builder and node ID.
///
/// If a node with this label already exists, returns its ID without modification.
/// If it doesn't exist, creates a new node with the label as its data.
///
/// ## Example
///
/// ```gleam
/// let #(builder, node_a) = labeled.ensure_node(builder, "Node A")
/// let #(builder, node_b) = labeled.ensure_node(builder, "Node B")
/// // Now you have the IDs and can use them with lower-level operations
/// ```
pub fn ensure_node(
  builder: Builder(label, e),
  label: label,
) -> #(Builder(label, e), NodeId) {
  case dict.get(builder.label_to_id, label) {
    Ok(id) -> #(builder, id)
    Error(_) -> {
      let id = builder.next_id
      let new_graph = model.add_node(builder.graph, id, label)
      let new_mapping = dict.insert(builder.label_to_id, label, id)
      #(
        Builder(graph: new_graph, label_to_id: new_mapping, next_id: id + 1),
        id,
      )
    }
  }
}

/// Adds a node with the given label explicitly.
///
/// If a node with this label already exists, its data will be replaced.
/// This is useful when you want to add nodes before adding edges.
///
/// ## Example
///
/// ```gleam
/// builder
/// |> labeled.add_node("Node A")
/// |> labeled.add_node("Node B")
/// |> labeled.add_edge("Node A", "Node B", 5)
/// ```
pub fn add_node(builder: Builder(label, e), label: label) -> Builder(label, e) {
  let #(new_builder, _id) = ensure_node(builder, label)
  new_builder
}

/// Adds an edge between two labeled nodes.
///
/// If either node doesn't exist, it will be created automatically.
/// For directed graphs, adds a single edge from `from` to `to`.
/// For undirected graphs, adds edges in both directions.
///
/// ## Example
///
/// ```gleam
/// builder
/// |> labeled.add_edge(from: "A", to: "B", with: 10)
/// |> labeled.add_edge(from: "B", to: "C", with: 5)
/// ```
pub fn add_edge(
  builder: Builder(label, e),
  from src_label: label,
  to dst_label: label,
  with weight: e,
) -> Builder(label, e) {
  let #(builder, src_id) = ensure_node(builder, src_label)
  let #(builder, dst_id) = ensure_node(builder, dst_label)

  let new_graph =
    model.add_edge(builder.graph, from: src_id, to: dst_id, with: weight)

  Builder(..builder, graph: new_graph)
}

/// Adds an unweighted edge between two labeled nodes.
///
/// This is a convenience function for graphs where edges have no meaningful weight.
/// Uses `Nil` as the edge data type. Nodes are created automatically if they don't exist.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
///
/// let builder: labeled.Builder(String, Nil) = labeled.directed()
///   |> labeled.add_unweighted_edge("A", "B")
///   |> labeled.add_unweighted_edge("B", "C")
/// ```
pub fn add_unweighted_edge(
  builder: Builder(label, Nil),
  from src_label: label,
  to dst_label: label,
) -> Builder(label, Nil) {
  let #(builder, src_id) = ensure_node(builder, src_label)
  let #(builder, dst_id) = ensure_node(builder, dst_label)

  let new_graph =
    model.add_edge(builder.graph, from: src_id, to: dst_id, with: Nil)

  Builder(..builder, graph: new_graph)
}

/// Adds a simple edge with weight 1 between two labeled nodes.
///
/// This is a convenience function for graphs with integer weights where
/// a default weight of 1 is appropriate (e.g., unweighted graphs, hop counts).
/// Nodes are created automatically if they don't exist.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
///
/// let builder = labeled.directed()
///   |> labeled.add_simple_edge("home", "work")
///   |> labeled.add_simple_edge("work", "gym")
/// // Both edges have weight 1
/// ```
pub fn add_simple_edge(
  builder: Builder(label, Int),
  from src_label: label,
  to dst_label: label,
) -> Builder(label, Int) {
  let #(builder, src_id) = ensure_node(builder, src_label)
  let #(builder, dst_id) = ensure_node(builder, dst_label)

  let new_graph =
    model.add_edge(builder.graph, from: src_id, to: dst_id, with: 1)

  Builder(..builder, graph: new_graph)
}

/// Looks up the internal node ID for a given label.
///
/// Returns `Ok(id)` if the label exists, `Error(Nil)` if it doesn't.
///
/// ## Example
///
/// ```gleam
/// case labeled.get_id(builder, "Node A") {
///   Ok(id) -> // Use the ID
///   Error(_) -> // Label doesn't exist
/// }
/// ```
pub fn get_id(builder: Builder(label, e), label: label) -> Result(NodeId, Nil) {
  dict.get(builder.label_to_id, label)
}

/// Converts the builder to a standard `Graph`.
///
/// The resulting graph uses integer IDs internally and stores the labels
/// as node data. This graph can be used with all yog algorithms.
///
/// ## Example
///
/// ```gleam
/// let graph = labeled.to_graph(builder)
/// // Now use with pathfinding, traversal, etc.
/// ```
pub fn to_graph(builder: Builder(label, e)) -> Graph(label, e) {
  builder.graph
}

/// Returns all labels that have been added to the builder.
///
/// ## Example
///
/// ```gleam
/// let labels = labeled.all_labels(builder)
/// // ["Node A", "Node B", "Node C"]
/// ```
pub fn all_labels(builder: Builder(label, e)) -> List(label) {
  dict.keys(builder.label_to_id)
}

/// Gets the successors of a node by its label.
///
/// Returns a list of tuples containing the successor's label and edge data.
///
/// ## Example
///
/// ```gleam
/// case labeled.successors(builder, "Node A") {
///   Ok(successors) -> // List of #(label, edge_data)
///   Error(_) -> // Node doesn't exist
/// }
/// ```
pub fn successors(
  builder: Builder(label, e),
  label: label,
) -> Result(List(#(label, e)), Nil) {
  use id <- result.try(get_id(builder, label))
  let successor_edges = model.successors(builder.graph, id)

  // Map node IDs back to labels
  successor_edges
  |> list_map_ids_to_labels(builder.graph)
  |> Ok
}

/// Gets the predecessors of a node by its label.
///
/// Returns a list of tuples containing the predecessor's label and edge data.
///
/// ## Example
///
/// ```gleam
/// case labeled.predecessors(builder, "Node A") {
///   Ok(predecessors) -> // List of #(label, edge_data)
///   Error(_) -> // Node doesn't exist
/// }
/// ```
pub fn predecessors(
  builder: Builder(label, e),
  label: label,
) -> Result(List(#(label, e)), Nil) {
  use id <- result.try(get_id(builder, label))
  let predecessor_edges = model.predecessors(builder.graph, id)

  // Map node IDs back to labels
  predecessor_edges
  |> list_map_ids_to_labels(builder.graph)
  |> Ok
}

// Helper function to map a list of (NodeId, edge_data) to (label, edge_data)
fn list_map_ids_to_labels(
  edges: List(#(NodeId, e)),
  graph: Graph(label, e),
) -> List(#(label, e)) {
  edges
  |> list.filter_map(fn(edge) {
    let #(node_id, edge_data) = edge
    case dict.get(graph.nodes, node_id) {
      Ok(label) -> Ok(#(label, edge_data))
      Error(_) -> Error(Nil)
    }
  })
}
