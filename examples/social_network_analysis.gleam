import gleam/io
import gleam/string
import yog/components
import yog/model.{Directed}

pub fn main() {
  // Model a social network where edges represent "follows" relationships
  let social_graph =
    model.new(Directed)
    |> model.add_node(1, "Alice")
    |> model.add_node(2, "Bob")
    |> model.add_node(3, "Carol")
    |> model.add_edge(from: 1, to: 2, with: Nil)
    |> model.add_edge(from: 2, to: 3, with: Nil)
    |> model.add_edge(from: 3, to: 1, with: Nil)

  // Find groups of mutually connected users
  let communities = components.strongly_connected_components(social_graph)
  io.println(string.inspect(communities))
  // => [[1, 2, 3]]  // All three users form a strongly connected community
}
