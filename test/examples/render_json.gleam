import gleam/io
import gleam/json
import yog/io/json as yog_json
import yog/model

pub fn main() {
  // Create a sample graph
  let assert Ok(graph) =
    model.new(model.Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "connects")

  // 1. Basic JSON output
  io.println("--- Basic JSON Output ---")
  let json_basic = yog_json.to_json(graph, yog_json.default_json_options())
  io.println(json_basic)

  // 2. Custom JSON structure (e.g., for D3.js or Cytoscape)
  io.println("\n--- Custom JSON Output ---")
  let options =
    yog_json.JsonOptions(
      node_mapper: fn(id, data) {
        json.object([
          #("id", json.int(id)),
          #("label", json.string(data)),
          #("type", json.string("user")),
        ])
      },
      edge_mapper: fn(source, target, weight) {
        json.object([
          #("from", json.int(source)),
          #("to", json.int(target)),
          #("metadata", json.object([#("weight", json.string(weight))])),
        ])
      },
    )

  let json_custom = yog_json.to_json(graph, options)
  io.println(json_custom)
}
