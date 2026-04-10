//// Shared types and utilities for pathfinding algorithms.

import gleam/list
import yog/model.{type Graph, type NodeId}

/// Represents a path through the graph with its total weight.
pub type Path(e) {
  Path(nodes: List(NodeId), total_weight: e)
}

/// Hydrates a list of node IDs with the actual edge data between consecutive nodes.
///
/// This is useful when you have a path from a pathfinding algorithm and need to
/// reconstruct the full sequence of edges with their weights/attributes.
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(model.Directed)
///   |> model.add_edge_ensure(from: 1, to: 2, with: "CAR", default: Nil)
///   |> model.add_edge_ensure(from: 2, to: 3, with: "BUS", default: Nil)
///
/// let path = [1, 2, 3]
/// let edges = path.hydrate_path(graph, path)
/// // => [#(1, 2, "CAR"), #(2, 3, "BUS")]
/// ```
pub fn hydrate_path(
  graph: Graph(n, e),
  node_ids: List(NodeId),
) -> List(#(NodeId, NodeId, e)) {
  do_hydrate_path(graph, node_ids, [])
}

fn do_hydrate_path(
  graph: Graph(n, e),
  node_ids: List(NodeId),
  acc: List(#(NodeId, NodeId, e)),
) -> List(#(NodeId, NodeId, e)) {
  case node_ids {
    [u, v, ..rest] -> {
      let acc = case model.edge_data(graph, u, v) {
        Ok(data) -> [#(u, v, data), ..acc]
        Error(_) -> acc
      }
      do_hydrate_path(graph, [v, ..rest], acc)
    }
    _ -> list.reverse(acc)
  }
}
