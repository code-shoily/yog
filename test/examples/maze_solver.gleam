import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import yog/builder/grid
import yog/generator/maze
import yog/pathfinding/dijkstra
import yog/render/ascii

pub fn main() {
  let rows = 15
  let cols = 30

  io.println("╔════════════════════════════════════════════════════════════╗")
  io.println("║              MAZE SOLVER WITH DIJKSTRA                     ║")
  io.println("╚════════════════════════════════════════════════════════════╝")

  // Generate a maze using Recursive Backtracker (great for pathfinding)
  io.println("\n🎲 Generating maze...")
  let m = maze.recursive_backtracker(rows, cols, Some(42))
  let graph = grid.to_graph(m)

  // Define start (top-left) and goal (bottom-right)
  let start = 0
  let goal = rows * cols - 1

  io.println("📍 Start: node " <> string.inspect(start) <> " (top-left)")
  io.println("🎯 Goal:  node " <> string.inspect(goal) <> " (bottom-right)")

  // Solve using Dijkstra's algorithm
  io.println("\n🔍 Solving with Dijkstra's algorithm...")

  case dijkstra.shortest_path_int(graph, start, goal) {
    option.Some(path) -> {
      io.println("✅ Path found!")
      io.println(
        "   Length: " <> string.inspect(list.length(path.nodes)) <> " nodes",
      )
      io.println("   Weight: " <> string.inspect(path.total_weight))

      // Create occupants map for the solution path
      let occupants =
        list.map(path.nodes, fn(node_id) {
          let char = {
            case node_id == start {
              True -> "S"
              False -> {
                case node_id == goal {
                  True -> "G"
                  False -> "·"
                }
              }
            }
          }
          #(node_id, char)
        })
        |> dict.from_list()

      // Render maze with solution path
      io.println("\n🗺️  Maze with Solution Path:")
      io.println("   S = Start, G = Goal, · = Path")
      io.println("")
      m
      |> ascii.grid_to_string_unicode_with_occupants(occupants)
      |> io.println()
    }
    option.None -> {
      io.println("❌ No path found.")
    }
  }

  // Bonus: Show all algorithms with solutions
  io.println("\n" <> string.repeat("═", 64))
  io.println("🎨 BONUS: Compare Different Maze Types with Solutions")
  io.println(string.repeat("═", 64))

  let algorithms = [
    #("Recursive Backtracker", fn() {
      maze.recursive_backtracker(8, 16, Some(123))
    }),
    #("Wilson's Algorithm", fn() { maze.wilson(8, 16, Some(123)) }),
    #("Kruskal's Algorithm", fn() { maze.kruskal(8, 16, Some(123)) }),
  ]

  use #(name, generator) <- list.each(algorithms)
  let maze = generator()
  let graph = grid.to_graph(maze)
  let start = 0
  let goal = 8 * 16 - 1

  case dijkstra.shortest_path_int(graph, start, goal) {
    option.Some(path) -> {
      let occupants =
        list.map(path.nodes, fn(id) {
          let char = {
            case id == start {
              True -> "S"
              False -> {
                case id == goal {
                  True -> "G"
                  False -> "·"
                }
              }
            }
          }
          #(id, char)
        })
        |> dict.from_list()

      io.println(
        "\n"
        <> name
        <> " (path length: "
        <> string.inspect(list.length(path.nodes))
        <> ")",
      )
      maze
      |> ascii.grid_to_string_unicode_with_occupants(occupants)
      |> io.println()
    }
    _ -> {
      io.println("\n" <> name <> ": No solution found")
    }
  }

  io.println("\n✨ Maze solving complete!")
}
