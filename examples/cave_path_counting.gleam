import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import gleam/string
import yog/model.{type Graph}

pub fn main() {
  // Model a cave system with small and large caves
  // Small caves (lowercase) can only be visited once
  // Large caves (uppercase) can be visited multiple times
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, "start")
    |> model.add_node(1, "A")
    |> model.add_node(2, "b")
    |> model.add_node(3, "c")
    |> model.add_node(4, "d")
    |> model.add_node(5, "end")
    |> model.add_edge(from: 0, to: 1, with: Nil)
    |> model.add_edge(from: 0, to: 2, with: Nil)
    |> model.add_edge(from: 1, to: 3, with: Nil)
    |> model.add_edge(from: 1, to: 2, with: Nil)
    |> model.add_edge(from: 2, to: 4, with: Nil)
    |> model.add_edge(from: 1, to: 5, with: Nil)
    |> model.add_edge(from: 4, to: 5, with: Nil)

  // Custom DFS with backtracking to count all valid paths
  let paths = count_paths(graph, 0, set.new(), False)
  // Prints: Found 10 valid paths through the cave system
  io.println(
    "Found " <> int.to_string(paths) <> " valid paths through the cave system",
  )
}

fn count_paths(
  graph: Graph(String, Nil),
  current: Int,
  visited_small: Set(String),
  can_revisit_one: Bool,
) -> Int {
  let assert Ok(cave_name) = dict.get(graph.nodes, current)

  case cave_name {
    "end" -> 1
    // Found a complete path
    _ -> {
      model.successors(graph, current)
      |> list.fold(0, fn(count, neighbor) {
        let #(neighbor_id, _) = neighbor
        let assert Ok(neighbor_name) = dict.get(graph.nodes, neighbor_id)

        let is_small = string.lowercase(neighbor_name) == neighbor_name
        let already_visited = set.contains(visited_small, neighbor_name)

        case neighbor_name, is_small, already_visited {
          "start", _, _ -> count
          // Never revisit start
          _, False, _ -> {
            // Large cave - always allowed
            count
            + count_paths(graph, neighbor_id, visited_small, can_revisit_one)
          }
          _, True, False -> {
            // Small cave not yet visited
            let new_visited = set.insert(visited_small, neighbor_name)
            count
            + count_paths(graph, neighbor_id, new_visited, can_revisit_one)
          }
          _, True, True if can_revisit_one -> {
            // Small cave already visited, but we have a revisit token
            count + count_paths(graph, neighbor_id, visited_small, False)
          }
          _, True, True -> count
          // Small cave already visited, no token
        }
      })
    }
  }
}
