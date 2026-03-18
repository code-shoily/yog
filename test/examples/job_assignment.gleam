import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import yog/model
import yog/property/bipartite

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
  let assert Ok(graph) =
    model.add_unweighted_edges(graph, [
      // Alice can do Programming or Design
      #(1, 4),
      #(1, 5),
      // Bob can only do Programming
      #(2, 4),
      // Charlie can do Design or Testing
      #(3, 5),
      #(3, 6),
    ])

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
