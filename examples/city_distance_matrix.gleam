import gleam/dict
import gleam/int
import gleam/io
import yog
import yog/pathfinding/floyd_warshall

pub fn main() {
  // A graph of cities with distances between them
  let graph =
    yog.undirected()
    |> yog.add_node(1, "London")
    |> yog.add_node(2, "Paris")
    |> yog.add_node(3, "Berlin")
    |> yog.add_node(4, "Rome")
    |> yog.add_edge(from: 1, to: 2, with: 344)
    // Distance in km
    |> yog.add_edge(from: 2, to: 3, with: 878)
    |> yog.add_edge(from: 3, to: 4, with: 1184)
    |> yog.add_edge(from: 2, to: 4, with: 1105)

  // Calculate all-pairs shortest paths using Floyd-Warshall
  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      io.println("City distance matrix:")
      // London to Rome
      case dict.get(distances, #(1, 4)) {
        Ok(d) -> io.println("London to Rome: " <> int.to_string(d) <> "km")
        Error(_) -> io.println("No path found")
      }
    }
    Error(_) -> io.println("Negative cycle detected!")
  }
}
