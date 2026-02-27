import gleam/int
import gleam/io
import yog/min_cut
import yog/model

pub fn main() {
  // Example graph for Global Minimum Cut (Stoer-Wagner)
  // This is similar to Advent of Code 2023 Day 25
  let graph =
    model.new(model.Undirected)
    |> model.add_node(1, "a")
    |> model.add_node(2, "b")
    |> model.add_node(3, "c")
    |> model.add_node(4, "d")
    |> model.add_node(5, "e")
    |> model.add_node(6, "f")
    |> model.add_node(7, "g")
    |> model.add_node(8, "h")
    // Component 1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 5, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 2, to: 6, with: 1)
    // Component 2
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 7, with: 1)
    |> model.add_edge(from: 3, to: 8, with: 1)
    |> model.add_edge(from: 4, to: 7, with: 1)
    |> model.add_edge(from: 4, to: 8, with: 1)
    |> model.add_edge(from: 7, to: 8, with: 1)
    // Bottleneck edges (cut these to separate the graph)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 5, to: 3, with: 1)

  io.println("--- Global Minimum Cut ---")

  let result = min_cut.global_min_cut(graph)

  io.println("Min cut weight: " <> int.to_string(result.weight))
  io.println("Group A size: " <> int.to_string(result.group_a_size))
  io.println("Group B size: " <> int.to_string(result.group_b_size))

  let answer = result.group_a_size * result.group_b_size
  io.println("Multiplied sizes (AoC style): " <> int.to_string(answer))
}
