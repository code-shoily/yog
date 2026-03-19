//// ASCII art rendering for grids and mazes.
////
//// Renders grid structures as text using simple ASCII characters (+, -, |).
//// Perfect for terminal output and following along with
//// "Mazes for Programmers" book examples.
////
//// ## Quick Start
////
//// ```gleam
//// import yog/render/ascii
//// import yog/builder/grid
////
////  let map = [
////    [">", ">", "."],
////    [".", "V", ">"],
////    [".", ".", "."],
////  ]
////  let maze =
////    grid.from_2d_list(
////      map,
////      model.Directed,
////      grid.including([">", "<", "V", "^"]),
////    )
////
//// io.println(ascii.grid_to_string(maze))
//// ```
////
//// ## Output
////
//// ```
//// +---+---+---+
//// |       |   |
//// +---+   +---+
//// |   |       |
//// +---+---+---+
//// |   |   |   |
//// +---+---+---+
//// ```

import gleam/dict
import gleam/list
import gleam/string
import yog/builder/grid.{type Grid}
import yog/internal/utils
import yog/model.{type Graph, type NodeId}

/// Converts a grid to ASCII art using simple characters (+, -, |).
///
/// Each cell is represented as a 3-character wide space. Walls are drawn
/// where edges don't exist between adjacent cells.
///
/// ## Example
///
/// ```gleam
/// let maze = // ... create grid
/// io.println(ascii.grid_to_string(maze))
/// ```
pub fn grid_to_string(grid: Grid(n, e)) -> String {
  case grid.rows, grid.cols {
    0, _ | _, 0 -> ""
    _, _ -> {
      let top_line = draw_top_border(grid.cols)
      let body_lines =
        utils.range(0, grid.rows - 1)
        |> list.flat_map(fn(row) {
          [draw_cell_row(grid, row), draw_horizontal_walls(grid, row)]
        })

      [top_line, ..body_lines]
      |> string.join("\n")
    }
  }
}

// =============================================================================
// ASCII RENDERING (using +, -, |)
// =============================================================================

fn draw_top_border(cols: Int) -> String {
  "+" <> string.repeat("---+", cols)
}

fn draw_cell_row(grid: Grid(n, e), row: Int) -> String {
  utils.range(0, grid.cols - 1)
  |> list.fold("|", fn(acc, col) {
    let cell_id = grid.coord_to_id(row, col, grid.cols)
    let right_id = grid.coord_to_id(row, col + 1, grid.cols)

    // Check if there's a passage to the right
    let wall = case has_passage(grid.graph, cell_id, right_id) {
      True -> "    "
      // Passage - no wall
      False -> "   |"
      // Wall
    }

    acc <> wall
  })
}

fn draw_horizontal_walls(grid: Grid(n, e), row: Int) -> String {
  utils.range(0, grid.cols - 1)
  |> list.fold("+", fn(acc, col) {
    let cell_id = grid.coord_to_id(row, col, grid.cols)
    let below_id = grid.coord_to_id(row + 1, col, grid.cols)

    // Check if there's a passage below
    let wall = case has_passage(grid.graph, cell_id, below_id) {
      True -> "   +"
      // Passage - no wall
      False -> "---+"
      // Wall
    }

    acc <> wall
  })
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Checks if there's a passage (edge) between two cells.
///
/// A passage exists if there's an edge in either direction
/// (since mazes can be directed or undirected).
fn has_passage(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  has_edge(graph, from, to) || has_edge(graph, to, from)
}

/// Checks if an edge exists from one node to another.
fn has_edge(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  case dict.get(graph.out_edges, from) {
    Ok(neighbors) -> dict.has_key(neighbors, to)
    Error(_) -> False
  }
}
