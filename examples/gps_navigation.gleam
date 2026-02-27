import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/model.{Undirected}
import yog/pathfinding

pub fn main() {
  // Model road network with travel times
  let road_network =
    model.new(Undirected)
    |> model.add_node(1, "Home")
    |> model.add_node(2, "Office")
    |> model.add_node(3, "Mall")
    |> model.add_edge(from: 1, to: 2, with: 15)
    // 15 minutes
    |> model.add_edge(from: 2, to: 3, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 30)

  // Use A* with straight-line distance heuristic
  let straight_line_distance = fn(from, to) {
    // Simplified: in reality would use coordinates
    case from == to {
      True -> 0
      False -> 5
      // Optimistic estimate
    }
  }

  case
    pathfinding.a_star(
      in: road_network,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: straight_line_distance,
    )
  {
    Some(path) -> {
      // Path(nodes: [1, 2, 3], total_weight: 25)
      // Prints: Fastest route takes 25 minutes
      io.println(
        "Fastest route takes " <> int.to_string(path.total_weight) <> " minutes",
      )
    }
    None -> io.println("No route found")
  }
}
