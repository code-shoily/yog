import gleam/dict
import gleam/int
import gleam/io
import yog/model
import yog/pathfinding

pub fn main() {
  // Create a graph of 4 cities
  let graph =
    model.new(model.Directed)
    |> model.add_node(1, "City A")
    |> model.add_node(2, "City B")
    |> model.add_node(3, "City C")
    |> model.add_node(4, "City D")
    |> model.add_edge(from: 1, to: 2, with: 3)
    |> model.add_edge(from: 2, to: 1, with: 8)
    |> model.add_edge(from: 1, to: 4, with: 7)
    |> model.add_edge(from: 4, to: 1, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 1, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 1)

  io.println("--- All-Pairs Shortest Paths (Floyd-Warshall) ---")

  case
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(matrix) -> {
      // Matrix is Dict(NodeId, Dict(NodeId, Weight))
      dict.each(matrix, fn(from, rows) {
        dict.each(rows, fn(to, weight) {
          io.println(
            "From "
            <> int.to_string(from)
            <> " to "
            <> int.to_string(to)
            <> ": "
            <> int.to_string(weight),
          )
        })
      })
    }
    Error(_) -> io.println("Negative cycle detected!")
  }
}
