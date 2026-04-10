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
  let rows = 12
  let cols = 20

  io.println("╔════════════════════════════════════════════════════════════╗")
  io.println("║     MAZE SOLVER WITH DIRECTIONAL ARROWS (^ v > <)         ║")
  io.println("╚════════════════════════════════════════════════════════════╝")

  io.println(
    "\nGenerating "
    <> string.inspect(rows)
    <> "×"
    <> string.inspect(cols)
    <> " maze...",
  )
  let m = maze.recursive_backtracker(rows, cols, Some(42))
  let graph = grid.to_graph(m)

  let start = 0
  let goal = rows * cols - 1

  io.println("Start: node " <> string.inspect(start) <> " (top-left)")
  io.println("Goal:  node " <> string.inspect(goal) <> " (bottom-right)")

  case dijkstra.shortest_path_int(graph, start, goal) {
    option.Some(path) -> {
      io.println(
        "\nPath found! Length: "
        <> string.inspect(list.length(path.nodes))
        <> " nodes",
      )

      let directional_occupants =
        path.nodes
        |> list.window_by_2()
        |> list.map(fn(pair) {
          let #(current, next) = pair
          let direction = {
            case next == current + 1 {
              True -> ">"
              False -> {
                case next == current - 1 {
                  True -> "<"
                  False -> {
                    case next == current + cols {
                      True -> "v"
                      False -> {
                        case next == current - cols {
                          True -> "^"
                          False -> "·"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          #(current, direction)
        })
        |> dict.from_list()
        |> dict.insert(start, "S")
        |> dict.insert(goal, "G")

      io.println("\nSolution with Directional Arrows:")
      io.println("   S = Start, G = Goal, >v<^ = Path direction")
      io.println("")
      m
      |> ascii.grid_to_string_unicode_with_occupants(directional_occupants)
      |> io.println()
    }
    option.None -> {
      io.println("No path found.")
    }
  }
}
