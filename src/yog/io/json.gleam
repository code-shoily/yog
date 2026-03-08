import gleam/dict
import gleam/function
import gleam/json
import gleam/list
import yog/model.{type Graph, type NodeId, Undirected}

/// Options for customizing JSON output.
pub type JsonOptions {
  JsonOptions(
    /// Function to convert node ID and data to JSON for the 'nodes' array.
    node_mapper: fn(NodeId, String) -> json.Json,
    /// Function to convert source, target, and edge weight to JSON for the 'edges' array.
    edge_mapper: fn(NodeId, NodeId, String) -> json.Json,
  )
}

/// Creates default JSON options.
///
/// Nodes are `{ "id": 1, "label": "Node A" }`.
/// Edges are `{ "source": 1, "target": 2, "weight": "5" }`.
pub fn default_json_options() -> JsonOptions {
  JsonOptions(
    node_mapper: fn(id, data) {
      json.object([
        #("id", json.int(id)),
        #("label", json.string(data)),
      ])
    },
    edge_mapper: fn(from, to, weight) {
      json.object([
        #("source", json.int(from)),
        #("target", json.int(to)),
        #("weight", json.string(weight)),
      ])
    },
  )
}

/// Converts a graph to a JSON string compatible with many visualization libraries (e.g., D3.js).
///
/// The graph's node data and edge data must be convertible to strings.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// import gleam/io
/// import gleam/json
/// import yog/model
///
/// pub fn main() {
///   let graph =
///     model.new(model.Directed)
///     |> model.add_node(1, "Alice")
///     |> model.add_node(2, "Bob")
///     |> model.add_edge(from: 1, to: 2, with: "follows")
///
///   let json_string = yog_json.to_json(graph, yog_json.default_json_options())
///   io.println(json_string)
/// }
/// ```
///
/// This outputs:
/// ````json
/// {
///   "nodes": [
///     {"id": 1, "label": "Alice"},
///     {"id": 2, "label": "Bob"}
///   ],
///   "edges": [
///     {"source": 1, "target": 2, "weight": "follows"}
///   ]
/// }
/// ````
pub fn to_json(graph: Graph(String, String), options: JsonOptions) -> String {
  let nodes_json =
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      [options.node_mapper(id, data), ..acc]
    })

  let edges_json =
    dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
      let inner_edges =
        dict.fold(targets, [], fn(inner_acc, to_id, weight) {
          case graph.kind {
            Undirected if from_id > to_id -> inner_acc
            _ -> [options.edge_mapper(from_id, to_id, weight), ..inner_acc]
          }
        })
      list.flatten([inner_edges, acc])
    })

  json.to_string(
    json.object([
      #("nodes", json.array(nodes_json, of: function.identity)),
      #("edges", json.array(edges_json, of: function.identity)),
    ]),
  )
}
