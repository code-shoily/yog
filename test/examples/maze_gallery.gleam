import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import yog/generator/maze
import yog/render/ascii

pub fn main() {
  let rows = 10
  let cols = 20

  let algorithms = [
    #("Recursive Backtracker (Classic twisty corridors)", fn(r, c, s) {
      maze.recursive_backtracker(r, c, s)
    }),
    #("Wilson's Algorithm (Uniformly random, balanced)", fn(r, c, s) {
      maze.wilson(r, c, s)
    }),
    #("Kruskal's Algorithm (MST-based, many short corridors)", fn(r, c, s) {
      maze.kruskal(r, c, s)
    }),
    #("Eller's Algorithm (Memory-efficient, row-by-row)", fn(r, c, s) {
      maze.ellers(r, c, s)
    }),
    #("Prim's (Simplified) (Radial texture, many dead ends)", fn(r, c, s) {
      maze.prim_simplified(r, c, s)
    }),
    #("Growing Tree (Random strategy)", fn(r, c, s) {
      maze.growing_tree(r, c, maze.Random, s)
    }),
    #("Recursive Division (Fractal chambers and rooms)", fn(r, c, s) {
      maze.recursive_division(r, c, s)
    }),
  ]

  io.println("=== Yog Maze Gallery ===")
  io.println(
    "Grid size: " <> string.inspect(rows) <> "x" <> string.inspect(cols),
  )

  use #(description, generator) <- list.each(algorithms)
  io.println("\n" <> string.repeat("-", 40))
  io.println("Running Algorithm: " <> description)
  io.println(string.repeat("-", 40))

  let m = generator(rows, cols, Some(42))

  m
  |> ascii.grid_to_string()
  |> io.println()

  io.println("\nGallery Complete!")
}
