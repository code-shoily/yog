import gleam/int
import gleam/io
import yog
import yog/flow/min_cut as flow
import yog/model

pub fn main() {
  io.println("=== Yog Global Min-Cut Showcase ===\n")

  // This example models a graph that is almost disconnected
  // Two cliques of 5 nodes connected by a single bridge
  let graph =
    yog.from_edges(model.Undirected, [
      // Cluster A (nodes 1-5)
      #(1, 2, 10),
      #(2, 3, 10),
      #(3, 4, 10),
      #(4, 5, 10),
      #(5, 1, 10),
      // Cluster B (nodes 6-10)
      #(6, 7, 10),
      #(7, 8, 10),
      #(8, 9, 10),
      #(9, 10, 10),
      #(10, 6, 10),
      // The bridge (the minimum cut)
      #(1, 6, 1),
    ])

  // Find the global minimum cut using Stoer-Wagner
  let result = flow.global_min_cut(graph)

  io.println("Min cut weight: " <> int.to_string(result.weight))
  io.println("Group A size: " <> int.to_string(result.group_a_size))
  io.println("Group B size: " <> int.to_string(result.group_b_size))

  let answer = result.group_a_size * result.group_b_size
  io.println("Product of component sizes: " <> int.to_string(answer))
}
