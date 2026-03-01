import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import yog/bipartite
import yog/model

pub fn main() {
  // Job Assignment Problem: 3 Workers, 3 Tasks
  // Not everyone can do every task
  let graph =
    model.new(model.Undirected)
    // Workers (Left Partition)
    |> model.add_node(1, "Alice")
    |> model.add_node(2, "Bob")
    |> model.add_node(3, "Charlie")
    // Tasks (Right Partition)
    |> model.add_node(4, "Programming")
    |> model.add_node(5, "Design")
    |> model.add_node(6, "Testing")
    // Alice can do Programming or Design
    |> model.add_edge(from: 1, to: 4, with: Nil)
    |> model.add_edge(from: 1, to: 5, with: Nil)
    // Bob can only do Programming
    |> model.add_edge(from: 2, to: 4, with: Nil)
    // Charlie can do Design or Testing
    |> model.add_edge(from: 3, to: 5, with: Nil)
    |> model.add_edge(from: 3, to: 6, with: Nil)

  io.println("--- Bipartite Job Assignment ---")

  // Check if it's bipartite first
  case bipartite.partition(graph) {
    Some(partition) -> {
      let matching = bipartite.maximum_matching(graph, partition)
      io.println(
        "Maximum assignments found: " <> int.to_string(list.length(matching)),
      )

      list.each(matching, fn(pair) {
        let #(worker_id, task_id) = pair
        io.println(
          "Worker "
          <> int.to_string(worker_id)
          <> " -> Task "
          <> int.to_string(task_id),
        )
      })
    }
    None -> io.println("This graph is not bipartite!")
  }
}
