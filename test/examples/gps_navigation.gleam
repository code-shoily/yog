import gleam/int
import gleam/io
import gleam/option.{Some}
import yog
import yog/model
import yog/pathfinding/a_star

pub fn main() {
  // A graph of locations and travel times (minutes)
  let graph =
    yog.from_edges(model.Undirected, [
      #(1, 2, 10),
      // Home (1) <-> Coffee shop (2): 10 min
      #(2, 3, 15),
      // Coffee shop (2) <-> Park (3): 15 min
      #(3, 4, 20),
      // Park (3) <-> Office (4): 20 min
      #(2, 4, 25),
      // Coffee shop (2) <-> Office (4): 25 min
    ])

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
          // at destination
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
      with_heuristic: heuristic,
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
