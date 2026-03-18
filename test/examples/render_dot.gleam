import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/io/dot
import yog/model
import yog/pathfinding/dijkstra
import yog/transform

pub fn main() {
  // Create a sample graph
  let graph =
    model.new(model.Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 2, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 3)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 3, with: 10)

  // 1. Basic DOT output
  io.println("--- Basic DOT Output ---")
  let dot_basic =
    dot.to_dot(
      graph |> transform.map_edges(int.to_string),
      dot.default_dot_options(),
    )
  io.println(dot_basic)

  // 2. DOT with highlighted path
  io.println("\n--- DOT with Highlighted Path ---")
  case dijkstra.shortest_path(graph, 1, 3, 0, int.add, int.compare) {
    Some(path) -> {
      let options = dot.path_to_dot_options(path, dot.default_dot_options())
      let dot_highlighted =
        dot.to_dot(graph |> transform.map_edges(int.to_string), options)
      io.println(dot_highlighted)
    }
    None -> io.println("No path found")
  }

  io.println("\nTip: You can render this by piping to Graphviz:")
  io.println("gleam run -m examples/render_dot | dot -Tpng -o graph.png")
}
