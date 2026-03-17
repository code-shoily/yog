import gleam/int
import gleam/io
import gleam/option.{Some}
import yog
import yog/pathfinding/a_star

pub fn main() {
  // A graph of locations and travel times (minutes)
  let graph =
    yog.undirected()
    |> yog.add_node(1, #(0, 0))
    // Home: (x, y)
    |> yog.add_node(2, #(5, 2))
    // Coffee shop
    |> yog.add_node(3, #(2, 8))
    // Park
    |> yog.add_node(4, #(10, 10))
    // Office
    |> yog.add_edge(from: 1, to: 2, with: 10)
    |> yog.add_edge(from: 2, to: 3, with: 15)
    |> yog.add_edge(from: 3, to: 4, with: 20)
    |> yog.add_edge(from: 2, to: 4, with: 25)

  // Use A* with Euclidean-style distance heuristic
  let heuristic = fn(from: Int, to: Int) {
    // In a real app, we'd look up coordinates for 'from' and 'to'
    // For this example, let's assume we know the goal is node 4 (office)
    case to == 4 {
      True ->
        case from {
          1 -> 14
          // estimate from home
          2 -> 8
          // estimate from coffee
          3 -> 5
          // estimate from park
          4 -> 0
          _ -> 0
        }
      False -> 0
    }
  }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: heuristic,
    )

  case result {
    Some(path) -> {
      io.println(
        "Fastest route takes " <> int.to_string(path.total_weight) <> " minutes",
      )
      // Print nodes manually or use a string conversion if needed
      io.println("Route nodes found.")
    }
    option.None -> io.println("No route to office!")
  }
}
