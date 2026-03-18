import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/io/mermaid
import yog/model
import yog/pathfinding/dijkstra
import yog/transform

pub fn main() {
  // Create a sample graph
  let graph =
    model.new(model.Undirected)
    |> model.add_node(1, "Home")
    |> model.add_node(2, "Gym")
    |> model.add_node(3, "Office")
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 2, with: 10)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 3, with: 20)

  // 1. Basic Mermaid output
  io.println("--- Basic Mermaid Output ---")
  let mermaid_basic =
    mermaid.to_mermaid(
      graph |> transform.map_edges(int.to_string),
      mermaid.default_options(),
    )
  io.println("```mermaid")
  io.println(mermaid_basic)
  io.println("```")

  // 2. Mermaid with custom labels and highlighting
  io.println("\n--- Mermaid with Custom Labels & Highlighting ---")
  case dijkstra.shortest_path(graph, 1, 3, 0, int.add, int.compare) {
    Some(path) -> {
      let base_options =
        mermaid.MermaidOptions(
          node_label: fn(id, data) {
            data <> " (ID: " <> int.to_string(id) <> ")"
          },
          edge_label: fn(weight) { weight <> " km" },
          highlighted_nodes: None,
          highlighted_edges: None,
        )
      let options = mermaid.path_to_options(path, base_options)
      let mermaid_custom =
        mermaid.to_mermaid(graph |> transform.map_edges(int.to_string), options)
      io.println("```mermaid")
      io.println(mermaid_custom)
      io.println("```")
    }
    None -> io.println("No path found")
  }

  io.println("\nTip: Paste the output into a GitHub markdown file or")
  io.println(
    "the Mermaid Live Editor (https://mermaid.live/) to see it rendered.",
  )
}
