import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import gleeunit/should
import yog/builder/grid
import yog/builder/toroidal
import yog/model
import yog/render/ascii

// Test basic ASCII rendering with a simple grid
pub fn simple_grid_ascii_test() {
  // Create a 2x2 grid with all cells connected
  let grid_data = [[0, 1], [2, 3]]

  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string(grid)

  // Should have top border, cell rows, and bottom border
  let lines = string.split(result, "\n")
  list.length(lines)
  |> should.equal(5)
  // Top + (cells + walls) * 2 rows

  // First line should be top border
  list.first(lines)
  |> should.equal(Ok("+---+---+"))
}

// Test maze with walls (some passages removed)
pub fn maze_with_walls_test() {
  // Create a simple 3x3 grid
  let grid_data = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]

  // Only allow specific movements (creating a maze)
  let can_move = fn(from, to) {
    // Allow passages: 0-1, 1-2, 0-3, 3-6, 2-5, 5-8, 4-7, 7-8
    case from, to {
      0, 1 | 1, 0 -> True
      1, 2 | 2, 1 -> True
      0, 3 | 3, 0 -> True
      3, 6 | 6, 3 -> True
      2, 5 | 5, 2 -> True
      5, 8 | 8, 5 -> True
      4, 7 | 7, 4 -> True
      7, 8 | 8, 7 -> True
      _, _ -> False
    }
  }

  let maze = grid.from_2d_list(grid_data, model.Undirected, can_move: can_move)

  let result = ascii.grid_to_string(maze)

  io.println("\n=== Maze with walls ===")
  io.println(result)

  // Should have both passages (spaces) and walls (|, -)
  string.contains(result, "|")
  |> should.be_true()

  string.contains(result, "---")
  |> should.be_true()

  // Top-left to top-middle should be open (0-1 passage exists)
  string.contains(result, "|       ")
  |> should.be_true()
}

// Test empty grid
pub fn empty_grid_test() {
  let grid_data = []
  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string(grid)

  result
  |> should.equal("")
}

// Visual demonstration test (prints to console)
pub fn visual_demo_test() {
  // Create a 5x5 maze with random-ish passages
  let grid_data = [
    [0, 1, 2, 3, 4],
    [5, 6, 7, 8, 9],
    [10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19],
    [20, 21, 22, 23, 24],
  ]

  // Define a maze pattern (simulating a generated maze)
  let can_move = fn(from, to) {
    // A simple maze pattern
    case from, to {
      // Row 0
      0, 1 | 1, 0 -> True
      1, 2 | 2, 1 -> True
      3, 4 | 4, 3 -> True
      // Vertical from row 0
      0, 5 | 5, 0 -> True
      2, 7 | 7, 2 -> True
      // Row 1
      5, 6 | 6, 5 -> True
      7, 8 | 8, 7 -> True
      8, 9 | 9, 8 -> True
      // Vertical from row 1
      6, 11 | 11, 6 -> True
      9, 14 | 14, 9 -> True
      // Row 2
      10, 11 | 11, 10 -> True
      12, 13 | 13, 12 -> True
      13, 14 | 14, 13 -> True
      // Vertical from row 2
      10, 15 | 15, 10 -> True
      12, 17 | 17, 12 -> True
      // Row 3
      15, 16 | 16, 15 -> True
      16, 17 | 17, 16 -> True
      18, 19 | 19, 18 -> True
      // Vertical from row 3
      17, 22 | 22, 17 -> True
      19, 24 | 24, 19 -> True
      // Row 4
      20, 21 | 21, 20 -> True
      21, 22 | 22, 21 -> True
      22, 23 | 23, 22 -> True
      23, 24 | 24, 23 -> True
      _, _ -> False
    }
  }

  let maze = grid.from_2d_list(grid_data, model.Undirected, can_move: can_move)

  io.println("\n=== 5x5 Maze - ASCII ===")
  io.println(ascii.grid_to_string(maze))

  // Just checking it doesn't crash
  should.be_true(True)
}

// =============================================================================
// UNICODE RENDERING TESTS
// =============================================================================

// Test Unicode rendering with a simple grid
pub fn simple_grid_unicode_test() {
  let grid_data = [[0, 1], [2, 3]]

  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string_unicode(grid)

  io.println("\n=== Unicode 2x2 Grid ===")
  io.println(result)

  // Should contain Unicode box-drawing characters
  string.contains(result, "┌")
  |> should.be_true()
  string.contains(result, "└")
  |> should.be_true()
  string.contains(result, "┐")
  |> should.be_true()
  string.contains(result, "┘")
  |> should.be_true()
  string.contains(result, "─")
  |> should.be_true()
  string.contains(result, "│")
  |> should.be_true()
}

// Test Unicode rendering with a larger maze
pub fn maze_with_walls_unicode_test() {
  let grid_data = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]

  let can_move = fn(from, to) {
    case from, to {
      0, 1 | 1, 0 -> True
      1, 2 | 2, 1 -> True
      0, 3 | 3, 0 -> True
      3, 6 | 6, 3 -> True
      2, 5 | 5, 2 -> True
      5, 8 | 8, 5 -> True
      4, 7 | 7, 4 -> True
      7, 8 | 8, 7 -> True
      _, _ -> False
    }
  }

  let maze = grid.from_2d_list(grid_data, model.Undirected, can_move: can_move)
  let result = ascii.grid_to_string_unicode(maze)

  io.println("\n=== Unicode Maze with walls ===")
  io.println(result)

  // Should contain Unicode box-drawing characters
  // At minimum corners and horizontal/vertical lines should appear
  string.contains(result, "┌")
  |> should.be_true()
  string.contains(result, "└")
  |> should.be_true()
  string.contains(result, "┐")
  |> should.be_true()
  string.contains(result, "┘")
  |> should.be_true()
  string.contains(result, "─")
  |> should.be_true()
  string.contains(result, "│")
  |> should.be_true()
}

// Test empty grid Unicode rendering
pub fn empty_grid_unicode_test() {
  let grid_data = []
  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string_unicode(grid)

  result
  |> should.equal("")
}

// =============================================================================
// OCCUPANTS TESTS
// =============================================================================

// Test ASCII rendering with occupants
pub fn simple_grid_with_occupants_test() {
  let grid_data = [[0, 1], [2, 3]]

  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let occupants = dict.from_list([#(0, "S"), #(1, "G"), #(2, "#"), #(3, "@")])

  let result = ascii.grid_to_string_with_occupants(grid, occupants)

  io.println("\n=== ASCII with Occupants ===")
  io.println(result)

  // Check occupants appear in output
  string.contains(result, " S ")
  |> should.be_true()
  string.contains(result, " G ")
  |> should.be_true()
  string.contains(result, " # ")
  |> should.be_true()
  string.contains(result, " @ ")
  |> should.be_true()
}

// Test Unicode rendering with occupants
pub fn unicode_with_occupants_test() {
  let grid_data = [[0, 1, 2], [3, 4, 5]]

  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let occupants = dict.from_list([#(0, "A"), #(5, "B"), #(2, "C")])

  let result = ascii.grid_to_string_unicode_with_occupants(grid, occupants)

  io.println("\n=== Unicode with Occupants ===")
  io.println(result)

  // Check occupants appear
  string.contains(result, " A ")
  |> should.be_true()
  string.contains(result, " B ")
  |> should.be_true()
  string.contains(result, " C ")
  |> should.be_true()

  // Also check Unicode borders are still there
  string.contains(result, "┌")
  |> should.be_true()
}

// Test that occupants are truncated to single character
pub fn occupants_truncation_test() {
  let grid_data = [[0, 1]]

  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  // Multi-character occupant should be truncated to first char
  let occupants = dict.from_list([#(0, "Hello")])

  let result = ascii.grid_to_string_with_occupants(grid, occupants)

  io.println("\n=== Occupants Truncation ===")
  io.println(result)

  // Should only show "H" not "Hello"
  string.contains(result, " H ")
  |> should.be_true()
}

// =============================================================================
// TOROIDAL GRID TESTS
// =============================================================================

// Test basic toroidal grid ASCII rendering
pub fn toroidal_basic_test() {
  let grid_data = [[0, 1, 2], [3, 4, 5]]

  let toroidal_grid =
    toroidal.from_2d_list(
      grid_data,
      model.Undirected,
      can_move: toroidal.always(),
    )

  let result = ascii.toroidal_to_string(toroidal_grid)

  io.println("\n=== Toroidal Grid ASCII ===")
  io.println(result)

  // Should contain arrow hints for wrap-around
  string.contains(result, "v")
  |> should.be_true()
  string.contains(result, "^")
  |> should.be_true()
  string.contains(result, ">")
  |> should.be_true()
  string.contains(result, "<")
  |> should.be_true()

  // Should still have grid structure
  string.contains(result, "+")
  |> should.be_true()
}

// Test toroidal grid with occupants
pub fn toroidal_with_occupants_test() {
  let grid_data = [[0, 1], [2, 3]]

  let toroidal_grid =
    toroidal.from_2d_list(
      grid_data,
      model.Undirected,
      can_move: toroidal.always(),
    )

  let occupants = dict.from_list([#(0, "S"), #(3, "E")])

  let result = ascii.toroidal_to_string_with_occupants(toroidal_grid, occupants)

  io.println("\n=== Toroidal with Occupants ===")
  io.println(result)

  // Check occupants and arrows
  string.contains(result, " S ")
  |> should.be_true()
  string.contains(result, " E ")
  |> should.be_true()
  string.contains(result, "v")
  |> should.be_true()
}

// Test toroidal grid Unicode rendering
pub fn toroidal_unicode_test() {
  let grid_data = [[0, 1, 2], [3, 4, 5]]

  let toroidal_grid =
    toroidal.from_2d_list(
      grid_data,
      model.Undirected,
      can_move: toroidal.always(),
    )

  let result = ascii.toroidal_to_string_unicode(toroidal_grid)

  io.println("\n=== Toroidal Grid Unicode ===")
  io.println(result)

  // Should have Unicode box-drawing chars
  string.contains(result, "┌")
  |> should.be_true()
  string.contains(result, "─")
  |> should.be_true()
  string.contains(result, "│")
  |> should.be_true()

  // Should have arrow hints
  string.contains(result, "v")
  |> should.be_true()
}

// Test toroidal grid Unicode with occupants
pub fn toroidal_unicode_occupants_test() {
  let grid_data = [[0, 1], [2, 3]]

  let toroidal_grid =
    toroidal.from_2d_list(
      grid_data,
      model.Undirected,
      can_move: toroidal.always(),
    )

  let occupants = dict.from_list([#(0, "A"), #(1, "B"), #(2, "C"), #(3, "D")])

  let result =
    ascii.toroidal_to_string_unicode_with_occupants(toroidal_grid, occupants)

  io.println("\n=== Toroidal Unicode with Occupants ===")
  io.println(result)

  // Check all occupants
  string.contains(result, " A ")
  |> should.be_true()
  string.contains(result, " B ")
  |> should.be_true()
  string.contains(result, " C ")
  |> should.be_true()
  string.contains(result, " D ")
  |> should.be_true()
}

// =============================================================================
// EDGE CASE TESTS
// =============================================================================

// Test single cell grid
pub fn single_cell_grid_test() {
  let grid_data = [[0]]
  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let ascii_result = ascii.grid_to_string(grid)
  let unicode_result = ascii.grid_to_string_unicode(grid)

  io.println("\n=== Single Cell - ASCII ===")
  io.println(ascii_result)
  io.println("=== Single Cell - Unicode ===")
  io.println(unicode_result)

  // Single cell should still render correctly
  string.contains(ascii_result, "+")
  |> should.be_true()
  string.contains(unicode_result, "┌")
  |> should.be_true()
}

// Test single row grid
pub fn single_row_grid_test() {
  let grid_data = [[0, 1, 2]]
  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string(grid)

  io.println("\n=== Single Row ===")
  io.println(result)

  // Should have 3 columns
  string.contains(result, "+---+---+---+")
  |> should.be_true()
}

// Test single column grid
pub fn single_column_grid_test() {
  let grid_data = [[0], [1], [2]]
  let grid =
    grid.from_2d_list(grid_data, model.Undirected, can_move: grid.always())

  let result = ascii.grid_to_string(grid)

  io.println("\n=== Single Column ===")
  io.println(result)

  // Should have correct structure
  list.length(string.split(result, "\n"))
  |> should.equal(7)
  // Top + cell rows (3) + walls between (3)
}
