import gleam/io
import gleam/list
import gleam/string
import gleeunit/should
import yog/builder/grid
import yog/io/ascii
import yog/model

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
