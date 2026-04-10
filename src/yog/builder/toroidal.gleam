//// Toroidal grid builder - grids where edges wrap around.
////
//// A toroidal grid is like a regular grid, but movement wraps at the boundaries:
//// moving off the right edge brings you to the left edge, moving off the bottom
//// brings you to the top. This creates a torus topology (like Pac-Man or Asteroids).
////
//// ## Use Cases
////
//// - **Games**: Pac-Man, Civilization, roguelikes with wrapping maps
//// - **Cellular automata**: Conway's Game of Life without edge artifacts
//// - **Simulations**: Physics simulations where boundaries shouldn't matter
////
//// ## Distance Heuristics for Toroidal Grids
////
//// Regular distance functions don't account for wrapping. Use these instead:
////
//// - **Rook (4-way)** → `toroidal_manhattan_distance`
//// - **Queen (8-way)** → `toroidal_chebyshev_distance`
//// - **Weighted diagonals** → `toroidal_octile_distance`
////
//// ## Example
////
//// ```gleam
//// import yog/builder/toroidal
//// import yog/model.{Directed}
////
//// pub fn main() {
////   let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
////
////   // Create toroidal grid where all moves wrap
////   let grid = toroidal.from_2d_list(
////     grid_data,
////     Directed,
////     can_move: toroidal.always(),
////   )
////
////   // Distance from (0,0) to (2,2) goes "around" the grid
////   // On 3x3: direct is 4, but wrapping is 2 (up 1 + left 1)
////   let start = toroidal.coord_to_id(0, 0, 3)
////   let goal = toroidal.coord_to_id(2, 2, 3)
////   let dist = toroidal.toroidal_manhattan_distance(start, goal, 3, 3)
////   // dist = 2
//// }
//// ```

import gleam/dict
import gleam/int
import gleam/list
import yog/builder/grid
import yog/internal/utils
import yog/model.{type Graph, type GraphType, type NodeId}

/// A toroidal grid where edges wrap around to opposite sides.
///
/// Internally wraps a regular Grid, but uses different construction
/// and distance calculation logic.
pub opaque type ToroidalGrid(cell_data, edge_data) {
  ToroidalGrid(
    /// The underlying graph structure
    graph: Graph(cell_data, edge_data),
    /// Number of rows in the grid
    rows: Int,
    /// Number of columns in the grid
    cols: Int,
  )
}

// =============================================================================
// BUILDERS
// =============================================================================

/// Creates a toroidal graph from a 2D list using 4-directional (rook) movement.
///
/// Movement wraps at boundaries: moving right from the rightmost column
/// brings you to the leftmost column, and similarly for vertical movement.
///
/// ## Example
///
/// ```gleam
/// let data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
///
/// let grid = toroidal.from_2d_list(
///   data,
///   model.Directed,
///   can_move: toroidal.always(),
/// )
///
/// // Cell at (0, 2) connects to cell at (0, 0) via wrapping
/// ```
///
/// **Time Complexity:** O(rows × cols)
pub fn from_2d_list(
  grid_data: List(List(cell_data)),
  graph_type: GraphType,
  can_move can_move: fn(cell_data, cell_data) -> Bool,
) -> ToroidalGrid(cell_data, Int) {
  from_2d_list_with_topology(grid_data, graph_type, rook(), can_move:)
}

/// Creates a toroidal graph from a 2D list using a custom movement topology.
///
/// Like `from_2d_list`, but allows custom movement patterns. All movement
/// wraps at boundaries.
///
/// ## Example
///
/// ```gleam
/// // 8-way toroidal movement
/// let grid = toroidal.from_2d_list_with_topology(
///   data,
///   model.Directed,
///   toroidal.queen(),
///   can_move: toroidal.always(),
/// )
/// ```
///
/// **Time Complexity:** O(rows × cols × |topology|)
pub fn from_2d_list_with_topology(
  grid_data: List(List(cell_data)),
  graph_type: GraphType,
  topology: List(#(Int, Int)),
  can_move can_move: fn(cell_data, cell_data) -> Bool,
) -> ToroidalGrid(cell_data, Int) {
  let rows = list.length(grid_data)
  let cols = case grid_data {
    [first_row, ..] -> list.length(first_row)
    [] -> 0
  }

  let mut_graph = model.new(graph_type)

  // Flatten grid into list of cells with coordinates
  let cells =
    grid_data
    |> list.index_map(fn(row, row_idx) {
      row
      |> list.index_map(fn(cell, col_idx) { #(row_idx, col_idx, cell) })
    })
    |> list.flatten

  // Add all nodes
  let graph_with_nodes =
    cells
    |> list.fold(mut_graph, fn(g, cell) {
      let #(row, col, data) = cell
      let id = coord_to_id(row, col, cols)
      model.add_node(g, id, data)
    })

  let graph_with_edges = {
    use g, cell <- list.fold(cells, graph_with_nodes)
    let #(row, col, from_data) = cell
    let from_id = coord_to_id(row, col, cols)

    use acc_g, delta <- list.fold(topology, g)
    let #(d_row, d_col) = delta
    let n_row = wrap_coordinate(row + d_row, rows)
    let n_col = wrap_coordinate(col + d_col, cols)
    let to_id = coord_to_id(n_row, n_col, cols)

    let assert Ok(to_data) = dict.get(graph_with_nodes.nodes, to_id)
    case can_move(from_data, to_data) {
      True -> {
        let assert Ok(g) =
          model.add_edge(acc_g, from: from_id, to: to_id, with: 1)
        g
      }
      False -> acc_g
    }
  }

  ToroidalGrid(graph: graph_with_edges, rows: rows, cols: cols)
}

/// Wraps a coordinate to stay within bounds [0, size).
///
/// Handles negative values correctly for wrapping.
fn wrap_coordinate(coord: Int, size: Int) -> Int {
  case coord % size {
    n if n < 0 -> n + size
    n -> n
  }
}

// =============================================================================
// DISTANCE FUNCTIONS
// =============================================================================

/// Calculates the Manhattan distance on a toroidal grid.
///
/// Takes the shorter path, accounting for wrapping. For example, on a 10-wide
/// grid, the distance from column 1 to column 9 is 2 (wrapping left), not 8.
///
/// **Use this for:** Rook (4-way) movement on toroidal grids
///
/// ## Example
///
/// ```gleam
/// // On a 10x10 toroidal grid
/// let start = toroidal.coord_to_id(1, 1, 10)
/// let goal = toroidal.coord_to_id(9, 9, 10)
///
/// // Regular Manhattan: 8 + 8 = 16
/// // Toroidal: min(8,2) + min(8,2) = 4 (wrap both ways)
/// toroidal.toroidal_manhattan_distance(start, goal, 10, 10)
/// // => 4
/// ```
pub fn toroidal_manhattan_distance(
  from_id: NodeId,
  to_id: NodeId,
  cols: Int,
  rows: Int,
) -> Int {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  let row_diff = int.absolute_value(from_row - to_row)
  let col_diff = int.absolute_value(from_col - to_col)

  // Take the shorter path (direct or wrapped)
  let min_row_dist = int.min(row_diff, rows - row_diff)
  let min_col_dist = int.min(col_diff, cols - col_diff)

  min_row_dist + min_col_dist
}

/// Calculates the Chebyshev distance on a toroidal grid.
///
/// Like toroidal Manhattan, but uses max instead of sum. Optimal for
/// 8-way (queen) movement where wrapping is allowed.
///
/// **Use this for:** Queen (8-way) movement on toroidal grids
///
/// ## Example
///
/// ```gleam
/// // On a 10x10 toroidal grid
/// let start = toroidal.coord_to_id(1, 1, 10)
/// let goal = toroidal.coord_to_id(9, 9, 10)
///
/// // Toroidal Chebyshev: max(min(8,2), min(8,2)) = 2
/// toroidal.toroidal_chebyshev_distance(start, goal, 10, 10)
/// // => 2
/// ```
pub fn toroidal_chebyshev_distance(
  from_id: NodeId,
  to_id: NodeId,
  cols: Int,
  rows: Int,
) -> Int {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  let row_diff = int.absolute_value(from_row - to_row)
  let col_diff = int.absolute_value(from_col - to_col)

  // Take the shorter path (direct or wrapped)
  let min_row_dist = int.min(row_diff, rows - row_diff)
  let min_col_dist = int.min(col_diff, cols - col_diff)

  int.max(min_row_dist, min_col_dist)
}

/// Calculates the Octile distance on a toroidal grid.
///
/// For grids where diagonal moves cost √2 and orthogonal moves cost 1,
/// accounting for wrapping at boundaries.
///
/// **Use this for:** Weighted 8-directional movement on toroidal grids
///
/// ## Example
///
/// ```gleam
/// let start = toroidal.coord_to_id(1, 1, 10)
/// let goal = toroidal.coord_to_id(9, 9, 10)
///
/// toroidal.toroidal_octile_distance(start, goal, 10, 10)
/// // => 2.828... (2 × √2)
/// ```
pub fn toroidal_octile_distance(
  from_id: NodeId,
  to_id: NodeId,
  cols: Int,
  rows: Int,
) -> Float {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  let row_diff = int.absolute_value(from_row - to_row)
  let col_diff = int.absolute_value(from_col - to_col)

  // Take the shorter path (direct or wrapped)
  let min_row_dist = int.min(row_diff, rows - row_diff)
  let min_col_dist = int.min(col_diff, cols - col_diff)

  let min_d = int.min(min_row_dist, min_col_dist)
  let max_d = int.max(min_row_dist, min_col_dist)

  // √2 ≈ 1.414213562373095
  int.to_float(min_d) *. 1.414213562373095 +. int.to_float(max_d - min_d)
}

// =============================================================================
// COORDINATE CONVERSION (re-exported from grid)
// =============================================================================

/// Converts grid coordinates (row, col) to a node ID.
///
/// Uses row-major ordering: id = row * cols + col
///
/// ## Example
///
/// ```gleam
/// toroidal.coord_to_id(0, 0, 3)  // => 0
/// toroidal.coord_to_id(1, 2, 3)  // => 5
/// toroidal.coord_to_id(2, 1, 3)  // => 7
/// ```
pub fn coord_to_id(row: Int, col: Int, cols: Int) -> NodeId {
  grid.coord_to_id(row, col, cols)
}

/// Converts a node ID back to grid coordinates (row, col).
///
/// ## Example
///
/// ```gleam
/// toroidal.id_to_coord(0, 3)  // => #(0, 0)
/// toroidal.id_to_coord(5, 3)  // => #(1, 2)
/// toroidal.id_to_coord(7, 3)  // => #(2, 1)
/// ```
pub fn id_to_coord(id: NodeId, cols: Int) -> #(Int, Int) {
  grid.id_to_coord(id, cols)
}

// =============================================================================
// GRAPH CONVERSION
// =============================================================================

/// Converts the toroidal grid to a standard `Graph`.
///
/// The resulting graph can be used with all yog algorithms.
/// The wrapping connections are already encoded as edges.
///
/// ## Example
///
/// ```gleam
/// let graph = toroidal.to_graph(grid)
/// // Now use with pathfinding, traversal, etc.
/// ```
pub fn to_graph(grid: ToroidalGrid(cell_data, e)) -> Graph(cell_data, e) {
  grid.graph
}

/// Converts the toroidal grid to a standard `Grid`.
///
/// The resulting grid maintains the same graph structure with all
/// wrapping connections as edges. Useful for using grid-specific
/// functionality like ASCII rendering.
///
/// ## Example
///
/// ```gleam
/// let toroidal_grid = // ... create toroidal grid
/// let grid = toroidal.to_grid(toroidal_grid)
/// io.println(ascii.grid_to_string(grid))
/// ```
pub fn to_grid(grid: ToroidalGrid(cell_data, e)) -> grid.Grid(cell_data, e) {
  grid.Grid(graph: grid.graph, rows: grid.rows, cols: grid.cols)
}

/// Gets the number of rows in the toroidal grid.
pub fn rows(grid: ToroidalGrid(cell_data, e)) -> Int {
  grid.rows
}

/// Gets the number of columns in the toroidal grid.
pub fn cols(grid: ToroidalGrid(cell_data, e)) -> Int {
  grid.cols
}

/// Gets the cell data at the specified grid coordinate.
///
/// Returns `Ok(cell_data)` if the coordinate is valid, `Error(Nil)` otherwise.
///
/// ## Example
///
/// ```gleam
/// case toroidal.get_cell(grid, 1, 2) {
///   Ok(cell) -> // Use cell data
///   Error(_) -> // Out of bounds
/// }
/// ```
pub fn get_cell(
  grid: ToroidalGrid(cell_data, e),
  row: Int,
  col: Int,
) -> Result(cell_data, Nil) {
  case row >= 0 && row < grid.rows && col >= 0 && col < grid.cols {
    False -> Error(Nil)
    True -> {
      let id = coord_to_id(row, col, grid.cols)
      dict.get(grid.graph.nodes, id)
    }
  }
}

/// Finds a node in the grid where the cell data matches a predicate.
///
/// Returns the node ID of the first matching cell, or Error(Nil) if not found.
///
/// ## Example
///
/// ```gleam
/// // Find the starting position marked with 'S'
/// case toroidal.find_node(grid, fn(cell) { cell == "S" }) {
///   Ok(start_id) -> // Use start_id
///   Error(_) -> // Not found
/// }
/// ```
pub fn find_node(
  grid: ToroidalGrid(cell_data, e),
  predicate: fn(cell_data) -> Bool,
) -> Result(NodeId, Nil) {
  let max_id = grid.rows * grid.cols - 1
  utils.range(0, max_id)
  |> list.find_map(fn(id) {
    case dict.get(grid.graph.nodes, id) {
      Ok(data) ->
        case predicate(data) {
          True -> Ok(id)
          False -> Error(Nil)
        }
      Error(_) -> Error(Nil)
    }
  })
}

// =============================================================================
// TOPOLOGY PRESETS (re-exported from grid)
// =============================================================================

/// Cardinal (4-way) movement: up, down, left, right.
///
/// Named after the rook in chess. Wraps at boundaries on toroidal grids.
///
/// ```
/// . ↑ .
/// ← · →
/// . ↓ .
/// ```
pub fn rook() -> List(#(Int, Int)) {
  grid.rook()
}

/// Diagonal (4-way) movement: the four diagonal directions.
///
/// Named after the bishop in chess. Wraps at boundaries on toroidal grids.
///
/// ```
/// ↖ . ↗
/// . · .
/// ↙ . ↘
/// ```
pub fn bishop() -> List(#(Int, Int)) {
  grid.bishop()
}

/// All 8 surrounding directions: cardinal + diagonal.
///
/// Named after the queen in chess. Wraps at boundaries on toroidal grids.
///
/// ```
/// ↖ ↑ ↗
/// ← · →
/// ↙ ↓ ↘
/// ```
pub fn queen() -> List(#(Int, Int)) {
  grid.queen()
}

/// L-shaped jumps in all 8 orientations.
///
/// Named after the knight in chess. Wraps at boundaries on toroidal grids.
///
/// ```
/// . ♞ . ♞ .
/// ♞ . . . ♞
/// . . · . .
/// ♞ . . . ♞
/// . ♞ . ♞ .
/// ```
pub fn knight() -> List(#(Int, Int)) {
  grid.knight()
}

// =============================================================================
// MOVEMENT PREDICATES (re-exported from grid)
// =============================================================================

/// Allows movement between any cells except the specified wall value.
///
/// Both the source and destination cells must not be the wall value.
///
/// ## Example
///
/// ```gleam
/// let maze = [[".", "#", "."], [".", ".", "."], ["#", "#", "."]]
///
/// let g = toroidal.from_2d_list(
///   maze,
///   model.Directed,
///   can_move: toroidal.avoiding("#"),
/// )
/// ```
pub fn avoiding(wall_value: cell_data) -> fn(cell_data, cell_data) -> Bool {
  grid.avoiding(wall_value)
}

/// Allows movement only between cells matching the specified value.
///
/// Both the source and destination cells must match the valid value.
///
/// ## Example
///
/// ```gleam
/// let terrain = [[".", "~", "^"], [".", ".", "^"], ["~", ".", "."]]
///
/// let g = toroidal.from_2d_list(
///   terrain,
///   model.Directed,
///   can_move: toroidal.walkable("."),
/// )
/// ```
pub fn walkable(valid_value: cell_data) -> fn(cell_data, cell_data) -> Bool {
  grid.walkable(valid_value)
}

/// Always allows movement between adjacent cells.
///
/// Every neighbor pair gets an edge regardless of cell data.
///
/// ## Example
///
/// ```gleam
/// let labels = [["A", "B"], ["C", "D"]]
///
/// let g = toroidal.from_2d_list(
///   labels,
///   model.Undirected,
///   can_move: toroidal.always(),
/// )
/// ```
pub fn always() -> fn(cell_data, cell_data) -> Bool {
  grid.always()
}

/// Allows movement only between cells matching any of the specified values.
///
/// Both the source and destination cells must be included in the valid values list.
///
/// ## Example
///
/// ```gleam
/// let terrain = [[".", "P", "#"], ["#", ".", "."]]
///
/// let g = toroidal.from_2d_list(
///   terrain,
///   model.Directed,
///   can_move: toroidal.including([".", "P"]),
/// )
/// ```
pub fn including(
  valid_values: List(cell_data),
) -> fn(cell_data, cell_data) -> Bool {
  grid.including(valid_values)
}
