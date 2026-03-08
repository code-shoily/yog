import gleam/int
import gleam/io
import yog
import yog/flow/min_cut as flow

pub fn main() {
  io.println("=== Yog Global Min-Cut Showcase ===\n")

  // This example models a graph that is almost disconnected
  // Two cliques of 5 nodes connected by a single bridge
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    // Cluster A
    |> yog.add_edge(1, 2, 10)
    |> yog.add_edge(2, 3, 10)
    |> yog.add_edge(3, 4, 10)
    |> yog.add_edge(4, 5, 10)
    |> yog.add_edge(5, 1, 10)
    |> yog.add_node(6, Nil)
    |> yog.add_node(7, Nil)
    |> yog.add_node(8, Nil)
    |> yog.add_node(9, Nil)
    |> yog.add_node(10, Nil)
    // Cluster B
    |> yog.add_edge(6, 7, 10)
    |> yog.add_edge(7, 8, 10)
    |> yog.add_edge(8, 9, 10)
    |> yog.add_edge(9, 10, 10)
    |> yog.add_edge(10, 6, 10)
    // The bridge (the minimum cut)
    |> yog.add_edge(1, 6, 1)

  // Find the global minimum cut using Stoer-Wagner
  let result = flow.global_min_cut(graph)

  io.println("Min cut weight: " <> int.to_string(result.weight))
  io.println("Group A size: " <> int.to_string(result.group_a_size))
  io.println("Group B size: " <> int.to_string(result.group_b_size))

  let answer = result.group_a_size * result.group_b_size
  io.println("Product of component sizes: " <> int.to_string(answer))
}
