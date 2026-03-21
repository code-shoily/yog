import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/model
import yog/pathfinding/dijkstra
import yog/render/dot

pub fn main() {
  // Create a sample graph with Int edge weights
  let graph =
    model.new(model.Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")
  let assert Ok(graph) =
    model.add_edges(graph, [#(1, 2, 5), #(2, 3, 3), #(1, 3, 10)])

  // Create options with an edge formatter for Int weights
  let options = dot.default_dot_options_with_edge_formatter(int.to_string)

  // 1. Basic DOT output
  io.println("--- Basic DOT Output ---")
  let dot_basic = dot.to_dot(graph, options)
  io.println(dot_basic)

  // 2. DOT with highlighted path
  io.println("\n--- DOT with Highlighted Path ---")
  case dijkstra.shortest_path(graph, 1, 3, 0, int.add, int.compare) {
    Some(path) -> {
      let highlighted_options = dot.path_to_dot_options(path, options)
      let dot_highlighted = dot.to_dot(graph, highlighted_options)
      io.println(dot_highlighted)
    }
    None -> io.println("No path found")
  }

  io.println("\nTip: You can render this by piping to Graphviz:")
  io.println("gleam run -m examples/render_dot | dot -Tpng -o graph.png")
}
