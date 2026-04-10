//// ASCII art rendering for grids and mazes.
////
//// Renders grid structures as text using simple ASCII characters (+, -, |)
//// or Unicode box-drawing characters (┌, ─, ┼, │). Perfect for terminal
//// output and following along with "Mazes for Programmers" book examples.
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
////      can_move: grid.including([">", "<", "V", "^"]),
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
////
//// ## Unicode Rendering
////
//// For a more polished look, use `grid_to_string_unicode`:
////
//// ```gleam
//// io.println(ascii.grid_to_string_unicode(maze))
//// // Output:
//// // ┌───┬───┬───┐
//// // │   │   │   │
//// // ├───┼   ├───┤
//// // │   │   │   │
//// // └───┴───┴───┘
//// ```
////
//// ## Displaying Cell Contents
////
//// You can show values inside cells using occupants:
////
//// ```gleam
//// let occupants = dict.from_list([
////   #(0, "S"),  // Start
////   #(8, "G"),  // Goal
//// ])
//// io.println(ascii.grid_to_string_with_occupants(maze, occupants))
//// ```

import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import yog/builder/grid.{type Grid}
import yog/builder/toroidal.{type ToroidalGrid}
import yog/internal/util
import yog/model.{type Graph, type NodeId}

// =============================================================================
// ASCII RENDERING (using +, -, |)
// =============================================================================

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
      let col_range = util.range(0, grid.cols - 1)
      let body_lines =
        util.range(0, grid.rows - 1)
        |> list.flat_map(fn(row) {
          [
            draw_cell_row(grid.graph, grid.cols, row, dict.new(), col_range),
            draw_horizontal_walls(
              grid.graph,
              grid.rows,
              grid.cols,
              row,
              col_range,
            ),
          ]
        })

      [top_line, ..body_lines]
      |> string.join("\n")
    }
  }
}

/// Converts a grid to ASCII art with cell contents displayed.
///
/// The occupants dictionary maps node IDs to single-character strings
/// that will be displayed inside each cell.
///
/// ## Example
///
/// ```gleam
/// let occupants = dict.from_list([#(0, "S"), #(8, "G")])
/// io.println(ascii.grid_to_string_with_occupants(maze, occupants))
/// ```
pub fn grid_to_string_with_occupants(
  grid: Grid(n, e),
  occupants: Dict(NodeId, String),
) -> String {
  case grid.rows, grid.cols {
    0, _ | _, 0 -> ""
    _, _ -> {
      let top_line = draw_top_border(grid.cols)
      let col_range = util.range(0, grid.cols - 1)
      let body_lines =
        util.range(0, grid.rows - 1)
        |> list.flat_map(fn(row) {
          [
            draw_cell_row(grid.graph, grid.cols, row, occupants, col_range),
            draw_horizontal_walls(
              grid.graph,
              grid.rows,
              grid.cols,
              row,
              col_range,
            ),
          ]
        })

      [top_line, ..body_lines]
      |> string.join("\n")
    }
  }
}

// =============================================================================
// UNICODE RENDERING (using ┌, ─, │, ┼, etc.)
// =============================================================================

/// Converts a grid to Unicode box-drawing art.
///
/// Uses Unicode characters like ┌, ─, ┬, ┼, │ for a more polished look.
/// Each intersection is drawn correctly based on surrounding walls.
///
/// ## Example
///
/// ```gleam
/// io.println(ascii.grid_to_string_unicode(maze))
/// // Output:
/// // ┌───┬───┬───┐
/// // │   │   │   │
/// // ├───┼   ├───┤
/// // │   │   │   │
/// // └───┴───┴───┘
/// ```
pub fn grid_to_string_unicode(grid: Grid(n, e)) -> String {
  grid_to_string_unicode_with_occupants(grid, dict.new())
}

/// Converts a grid to Unicode box-drawing art with cell contents.
///
/// ## Example
///
/// ```gleam
/// let occupants = dict.from_list([#(0, "S"), #(8, "G")])
/// io.println(ascii.grid_to_string_unicode_with_occupants(maze, occupants))
/// ```
pub fn grid_to_string_unicode_with_occupants(
  grid: Grid(n, e),
  occupants: Dict(NodeId, String),
) -> String {
  case grid.rows, grid.cols {
    0, _ | _, 0 -> ""
    _, _ -> {
      // Render line by line (intersection rows and cell rows)
      util.range(0, grid.rows)
      |> list.map(fn(i_r) {
        let intersection_row =
          draw_unicode_intersection_row(grid.graph, grid.rows, grid.cols, i_r)

        case i_r < grid.rows {
          True -> {
            let cell_row =
              draw_unicode_cell_row(
                grid.graph,
                grid.rows,
                grid.cols,
                i_r,
                occupants,
              )
            intersection_row <> "\n" <> cell_row
          }
          False -> intersection_row
        }
      })
      |> string.join("\n")
    }
  }
}

// =============================================================================
// TOROIDAL GRID SUPPORT
// =============================================================================

/// Converts a toroidal grid to ASCII art.
///
/// Adds arrow hints around the border to indicate wrap-around connections.
pub fn toroidal_to_string(toroidal_grid: ToroidalGrid(n, e)) -> String {
  let grid = toroidal.to_grid(toroidal_grid)
  let base = grid_to_string(grid)
  add_toroidal_hints(
    base,
    toroidal.rows(toroidal_grid),
    toroidal.cols(toroidal_grid),
  )
}

/// Converts a toroidal grid to ASCII art with cell contents.
pub fn toroidal_to_string_with_occupants(
  toroidal_grid: ToroidalGrid(n, e),
  occupants: Dict(NodeId, String),
) -> String {
  let grid = toroidal.to_grid(toroidal_grid)
  let base = grid_to_string_with_occupants(grid, occupants)
  add_toroidal_hints(
    base,
    toroidal.rows(toroidal_grid),
    toroidal.cols(toroidal_grid),
  )
}

/// Converts a toroidal grid to Unicode box-drawing art.
pub fn toroidal_to_string_unicode(toroidal_grid: ToroidalGrid(n, e)) -> String {
  let grid = toroidal.to_grid(toroidal_grid)
  let base = grid_to_string_unicode(grid)
  add_toroidal_hints_unicode(
    base,
    toroidal.rows(toroidal_grid),
    toroidal.cols(toroidal_grid),
  )
}

/// Converts a toroidal grid to Unicode art with cell contents.
pub fn toroidal_to_string_unicode_with_occupants(
  toroidal_grid: ToroidalGrid(n, e),
  occupants: Dict(NodeId, String),
) -> String {
  let grid = toroidal.to_grid(toroidal_grid)
  let base = grid_to_string_unicode_with_occupants(grid, occupants)
  add_toroidal_hints_unicode(
    base,
    toroidal.rows(toroidal_grid),
    toroidal.cols(toroidal_grid),
  )
}

// =============================================================================
// ASCII RENDERING HELPERS
// =============================================================================

fn draw_top_border(cols: Int) -> String {
  "+" <> string.repeat("---+", cols)
}

fn draw_cell_row(
  graph: Graph(n, e),
  cols: Int,
  row: Int,
  occupants: Dict(NodeId, String),
  col_range: List(Int),
) -> String {
  col_range
  |> list.map(fn(col) {
    let cell_id = grid.coord_to_id(row, col, cols)
    let right_id = grid.coord_to_id(row, col + 1, cols)

    // Get cell content (centered in 3 spaces)
    let content =
      dict.get(occupants, cell_id)
      |> fn(r) {
        case r {
          Ok(c) -> string.slice(c, 0, 1)
          Error(_) -> " "
        }
      }
    let cell_text = " " <> content <> " "

    // Check if there's a passage to the right
    case has_passage(graph, cell_id, right_id) {
      True -> cell_text <> " "
      False -> cell_text <> "|"
    }
  })
  |> string.concat()
  |> string.append("|", _)
}

fn draw_horizontal_walls(
  graph: Graph(n, e),
  rows: Int,
  cols: Int,
  row: Int,
  col_range: List(Int),
) -> String {
  col_range
  |> list.map(fn(col) {
    let cell_id = grid.coord_to_id(row, col, cols)
    let below_id = grid.coord_to_id(row + 1, col, cols)

    // Check if there's a passage below. 
    // If we're at the last row, it's always a boundary (wall).
    let wall = case row < rows - 1 && has_passage(graph, cell_id, below_id) {
      True -> "   "
      False -> "---"
    }
    wall <> "+"
  })
  |> string.concat()
  |> string.append("+", _)
}

// =============================================================================
// UNICODE RENDERING HELPERS
// =============================================================================

fn draw_unicode_intersection_row(
  graph: Graph(n, e),
  rows: Int,
  cols: Int,
  i_r: Int,
) -> String {
  util.range(0, cols)
  |> list.map(fn(i_c) {
    let intersection = get_unicode_intersection(graph, rows, cols, i_r, i_c)

    case i_c < cols {
      True -> {
        case horizontal_wall(graph, rows, cols, i_r, i_c) {
          True -> intersection <> "───"
          False -> intersection <> "   "
        }
      }
      False -> intersection
    }
  })
  |> string.concat()
}

fn draw_unicode_cell_row(
  graph: Graph(n, e),
  rows: Int,
  cols: Int,
  r: Int,
  occupants: Dict(NodeId, String),
) -> String {
  util.range(0, cols)
  |> list.map(fn(c) {
    let wall = case vertical_wall(graph, rows, cols, r, c) {
      True -> "│"
      False -> " "
    }

    case c < cols {
      True -> {
        let cell_id = grid.coord_to_id(r, c, cols)
        let content =
          dict.get(occupants, cell_id)
          |> fn(r) {
            case r {
              Ok(c) -> string.slice(c, 0, 1)
              Error(_) -> " "
            }
          }
        wall <> " " <> content <> " "
      }
      False -> wall
    }
  })
  |> string.concat()
}

fn get_unicode_intersection(
  graph: Graph(n, e),
  rows: Int,
  cols: Int,
  i_r: Int,
  i_c: Int,
) -> String {
  let up = i_r > 0 && vertical_wall(graph, rows, cols, i_r - 1, i_c)
  let down = i_r < rows && vertical_wall(graph, rows, cols, i_r, i_c)
  let left = i_c > 0 && horizontal_wall(graph, rows, cols, i_r, i_c - 1)
  let right = i_c < cols && horizontal_wall(graph, rows, cols, i_r, i_c)

  case up, down, left, right {
    False, False, False, False -> " "
    False, False, True, True -> "─"
    False, False, True, False -> "─"
    False, False, False, True -> "─"
    True, True, False, False -> "│"
    True, False, False, False -> "│"
    False, True, False, False -> "│"
    False, True, False, True -> "┌"
    False, True, True, False -> "┐"
    True, False, False, True -> "└"
    True, False, True, False -> "┘"
    False, True, True, True -> "┬"
    True, False, True, True -> "┴"
    True, True, False, True -> "├"
    True, True, True, False -> "┤"
    True, True, True, True -> "┼"
  }
}

fn vertical_wall(
  graph: Graph(n, e),
  _rows: Int,
  cols: Int,
  r: Int,
  c: Int,
) -> Bool {
  case c {
    0 -> True
    n if n == cols -> True
    _ -> {
      let left_id = grid.coord_to_id(r, c - 1, cols)
      let right_id = grid.coord_to_id(r, c, cols)
      !has_passage(graph, left_id, right_id)
    }
  }
}

fn horizontal_wall(
  graph: Graph(n, e),
  rows: Int,
  cols: Int,
  r: Int,
  c: Int,
) -> Bool {
  case r {
    0 -> True
    n if n == rows -> True
    _ -> {
      let above_id = grid.coord_to_id(r - 1, c, cols)
      let below_id = grid.coord_to_id(r, c, cols)
      !has_passage(graph, above_id, below_id)
    }
  }
}

// =============================================================================
// TOROIDAL HINTS
// =============================================================================

fn add_toroidal_hints(ascii: String, _rows: Int, cols: Int) -> String {
  let lines = string.split(ascii, "\n")

  // Top arrow line
  let top_arrows = "  " <> string.join(list.repeat("v", cols), "   ")

  // Middle side arrows
  let body_with_sides =
    lines
    |> list.index_map(fn(line, idx) {
      // Cell rows are at odd indices (1, 3, 5...)
      case idx % 2 == 1 {
        True -> "> " <> line <> " <"
        False -> "  " <> line
      }
    })

  // Bottom arrow line
  let bottom_arrows = "  " <> string.join(list.repeat("^", cols), "   ")

  string.join(
    [top_arrows, ..list.append(body_with_sides, [bottom_arrows])],
    "\n",
  )
}

fn add_toroidal_hints_unicode(unicode: String, _rows: Int, cols: Int) -> String {
  let lines = string.split(unicode, "\n")

  // Top arrow line (v)
  let top_arrows = "  " <> string.join(list.repeat("v", cols), "   ")

  // Middle side arrows
  let body_with_sides =
    lines
    |> list.index_map(fn(line, idx) {
      // Cell rows are at odd indices (1, 3, 5...)
      case idx % 2 == 1 {
        True -> "> " <> line <> " <"
        False -> "  " <> line
      }
    })

  // Bottom arrow line (using ʌ U+028C or ^)
  let bottom_arrows = "  " <> string.join(list.repeat("ʌ", cols), "   ")

  string.join(
    [top_arrows, ..list.append(body_with_sides, [bottom_arrows])],
    "\n",
  )
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Checks if there's a passage (edge) between two cells.
///
/// A passage exists if there's an edge in either direction
/// (since mazes can be directed or undirected).
pub fn has_passage(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  has_edge(graph, from, to) || has_edge(graph, to, from)
}

/// Checks if an edge exists from one node to another.
pub fn has_edge(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  case dict.get(graph.out_edges, from) {
    Ok(neighbors) -> dict.has_key(neighbors, to)
    Error(_) -> False
  }
}
