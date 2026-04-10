//// A builder for creating graphs from 2D grids.
////
//// This module provides convenient ways to convert 2D grids (like heightmaps,
//// mazes, or game boards) into graphs for pathfinding and traversal algorithms.
////
//// ## Choosing the Right Distance Heuristic
////
//// For optimal A* pathfinding, use the heuristic that matches your topology:
////
//// - **Rook (4-way)** → `manhattan_distance` - sum of absolute differences
//// - **Queen (8-way)** → `chebyshev_distance` - maximum of absolute differences
//// - **Weighted diagonals** → `octile_distance` - when diagonal moves cost √2
//// - **Bishop or Knight** → `chebyshev_distance` (admissible but may be loose)
////
//// ## Example
////
//// ```gleam
//// import yog/builder/grid
//// import yog/model.{Directed}
//// import yog/traversal.{BreadthFirst}
////
//// pub fn main() {
////   // A simple heightmap where you can only climb up by 1
////   let heightmap = [
////     [1, 2, 3],
////     [4, 5, 6],
////     [7, 8, 9]
////   ]
////
////   // Build a graph where edges exist only if height diff <= 1
////   let grid = grid.from_2d_list(
////     heightmap,
////     Directed,
////     can_move: fn(from_height, to_height) {
////       to_height - from_height <= 1
////     }
////   )
////
////   // Convert to graph and use with algorithms
////   let graph = grid.to_graph(grid)
////   let start = grid.coord_to_id(0, 0, grid.cols)
////   let goal = grid.coord_to_id(2, 2, grid.cols)
////
////   traversal.walk_until(
////     from: start,
////     in: graph,
////     using: BreadthFirst,
////     until: fn(node) { node == goal }
////   )
//// }
//// ```

import gleam/dict
import gleam/int
import gleam/list
import yog/internal/utils
import yog/model.{type Graph, type GraphType, type NodeId}

// =============================================================================
// Types
// =============================================================================

/// A grid builder that wraps a graph and maintains grid dimensions.
///
/// The grid uses row-major ordering: node_id = row * cols + col
pub type Grid(cell_data, edge_data) {
  Grid(
    /// The underlying graph structure
    graph: Graph(cell_data, edge_data),
    /// Number of rows in the grid
    rows: Int,
    /// Number of columns in the grid
    cols: Int,
  )
}

// =============================================================================
// Builders
// =============================================================================

/// Creates a graph from a 2D list using 4-directional (rook) movement.
///
/// Each cell becomes a node, and edges are added between adjacent cells
/// (up/down/left/right) if the `can_move` predicate returns True.
/// This is equivalent to `from_2d_list_with_topology` with `rook()`.
///
/// ## Example
///
/// ```gleam
/// let heightmap = [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
///
/// let g = grid.from_2d_list(
///   heightmap,
///   model.Directed,
///   can_move: fn(from, to) { to - from <= 1 },
/// )
/// ```
///
/// **Time Complexity:** O(rows × cols)
pub fn from_2d_list(
  grid_data: List(List(cell_data)),
  graph_type: GraphType,
  can_move can_move: fn(cell_data, cell_data) -> Bool,
) -> Grid(cell_data, Int) {
  from_2d_list_with_topology(grid_data, graph_type, rook(), can_move:)
}

/// Creates a graph from a 2D list using a custom movement topology.
///
/// The `topology` parameter is a list of `#(row_delta, col_delta)` offsets
/// that define which neighbors each cell can reach. Use the built-in
/// presets — `rook()`, `bishop()`, `queen()`, `knight()` — or define
/// your own.
///
/// ## Example
///
/// ```gleam
/// // 8-way movement (queen topology) on a maze
/// let maze = [[".", "#", "."], [".", ".", "."], ["#", ".", "."]]
///
/// let g = grid.from_2d_list_with_topology(
///   maze,
///   model.Directed,
///   grid.queen(),
///   can_move: grid.avoiding("#"),
/// )
/// ```
///
/// ```gleam
/// // Knight jumps on a chessboard
/// let board = [
///   [0, 0, 0, 0, 0],
///   [0, 0, 0, 0, 0],
///   [0, 0, 0, 0, 0],
///   [0, 0, 0, 0, 0],
///   [0, 0, 0, 0, 0],
/// ]
///
/// let g = grid.from_2d_list_with_topology(
///   board,
///   model.Directed,
///   grid.knight(),
///   can_move: grid.always(),
/// )
/// ```
///
/// **Time Complexity:** O(rows × cols × |topology|)
pub fn from_2d_list_with_topology(
  grid_data: List(List(cell_data)),
  graph_type: GraphType,
  topology: List(#(Int, Int)),
  can_move can_move: fn(cell_data, cell_data) -> Bool,
) -> Grid(cell_data, Int) {
  let rows = list.length(grid_data)
  let cols = case grid_data {
    [first_row, ..] -> list.length(first_row)
    [] -> 0
  }

  let mut_graph = model.new(graph_type)

  let cells =
    grid_data
    |> list.index_map(fn(row, row_idx) {
      row
      |> list.index_map(fn(cell, col_idx) { #(row_idx, col_idx, cell) })
    })
    |> list.flatten

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
    let n_row = row + d_row
    let n_col = col + d_col

    case n_row >= 0 && n_row < rows && n_col >= 0 && n_col < cols {
      False -> acc_g
      True -> {
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
    }
  }

  Grid(graph: graph_with_edges, rows: rows, cols: cols)
}

// =============================================================================
// Topology Presets
// =============================================================================

/// Cardinal (4-way) movement: up, down, left, right.
///
/// Named after the rook in chess, which moves along ranks and files.
/// This is the default topology used by `from_2d_list`.
///
/// ```
/// . ↑ .
/// ← · →
/// . ↓ .
/// ```
pub fn rook() -> List(#(Int, Int)) {
  [#(-1, 0), #(1, 0), #(0, -1), #(0, 1)]
}

/// Diagonal (4-way) movement: the four diagonal directions.
///
/// Named after the bishop in chess, which moves along diagonals.
///
/// ```
/// ↖ . ↗
/// . · .
/// ↙ . ↘
/// ```
pub fn bishop() -> List(#(Int, Int)) {
  [#(-1, -1), #(-1, 1), #(1, -1), #(1, 1)]
}

/// All 8 surrounding directions: cardinal + diagonal.
///
/// Named after the queen in chess, which combines rook and bishop movement.
///
/// ```
/// ↖ ↑ ↗
/// ← · →
/// ↙ ↓ ↘
/// ```
pub fn queen() -> List(#(Int, Int)) {
  [#(-1, -1), #(-1, 0), #(-1, 1), #(0, -1), #(0, 1), #(1, -1), #(1, 0), #(1, 1)]
}

/// L-shaped jumps in all 8 orientations.
///
/// Named after the knight in chess, which jumps in an L-shape
/// (2 squares in one direction, 1 square perpendicular).
///
/// ```
/// . ♞ . ♞ .
/// ♞ . . . ♞
/// . . · . .
/// ♞ . . . ♞
/// . ♞ . ♞ .
/// ```
pub fn knight() -> List(#(Int, Int)) {
  [
    #(-2, -1),
    #(-2, 1),
    #(-1, -2),
    #(-1, 2),
    #(1, -2),
    #(1, 2),
    #(2, -1),
    #(2, 1),
  ]
}

// =============================================================================
// Coordinate Conversion
// =============================================================================

/// Converts grid coordinates (row, col) to a node ID.
///
/// Uses row-major ordering: id = row * cols + col
///
/// ## Example
///
/// ```gleam
/// grid.coord_to_id(0, 0, 3)  // => 0
/// grid.coord_to_id(1, 2, 3)  // => 5
/// grid.coord_to_id(2, 1, 3)  // => 7
/// ```
pub fn coord_to_id(row: Int, col: Int, cols: Int) -> NodeId {
  row * cols + col
}

/// Converts a node ID back to grid coordinates (row, col).
///
/// ## Example
///
/// ```gleam
/// grid.id_to_coord(0, 3)  // => #(0, 0)
/// grid.id_to_coord(5, 3)  // => #(1, 2)
/// grid.id_to_coord(7, 3)  // => #(2, 1)
/// ```
pub fn id_to_coord(id: NodeId, cols: Int) -> #(Int, Int) {
  #(id / cols, id % cols)
}

// =============================================================================
// Graph Conversion
// =============================================================================

/// Gets the cell data at the specified grid coordinate.
///
/// Returns `Ok(cell_data)` if the coordinate is valid, `Error(Nil)` otherwise.
///
/// ## Example
///
/// ```gleam
/// case grid.get_cell(grid, 1, 2) {
///   Ok(cell) -> // Use cell data
///   Error(_) -> // Out of bounds
/// }
/// ```
pub fn get_cell(
  grid: Grid(cell_data, e),
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

/// Converts the grid to a standard `Graph`.
///
/// The resulting graph can be used with all yog algorithms.
///
/// ## Example
///
/// ```gleam
/// let graph = grid.to_graph(grid)
/// // Now use with pathfinding, traversal, etc.
/// ```
pub fn to_graph(grid: Grid(cell_data, e)) -> Graph(cell_data, e) {
  grid.graph
}

// =============================================================================
// Distance Heuristics
// =============================================================================

/// Calculates the Manhattan distance between two node IDs.
///
/// This is useful as a heuristic for A* pathfinding on grids.
/// Manhattan distance is the sum of absolute differences in coordinates:
/// |x1 - x2| + |y1 - y2|
///
/// ## Example
///
/// ```gleam
/// let start = grid.coord_to_id(0, 0, 10)
/// let goal = grid.coord_to_id(3, 4, 10)
/// let distance = grid.manhattan_distance(start, goal, 10)
/// // => 7 (3 + 4)
/// ```
pub fn manhattan_distance(from_id: NodeId, to_id: NodeId, cols: Int) -> Int {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  int.absolute_value(from_row - to_row) + int.absolute_value(from_col - to_col)
}

/// Calculates the Chebyshev distance between two node IDs.
///
/// This is the optimal heuristic for A* pathfinding on grids with 8-way
/// (queen) movement, where diagonal moves have the same cost as orthogonal moves.
/// Chebyshev distance is the maximum of absolute differences in coordinates:
/// max(|x1 - x2|, |y1 - y2|)
///
/// **Use this for:** `queen()` topology, or any 8-directional movement
///
/// ## Example
///
/// ```gleam
/// let start = grid.coord_to_id(0, 0, 10)
/// let goal = grid.coord_to_id(3, 4, 10)
/// let distance = grid.chebyshev_distance(start, goal, 10)
/// // => 4 (max of 3 and 4)
/// ```
pub fn chebyshev_distance(from_id: NodeId, to_id: NodeId, cols: Int) -> Int {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  let row_diff = int.absolute_value(from_row - to_row)
  let col_diff = int.absolute_value(from_col - to_col)

  int.max(row_diff, col_diff)
}

/// Calculates the Octile distance between two node IDs.
///
/// This is the optimal heuristic for A* pathfinding on grids with 8-way
/// movement where diagonal moves cost √2 (approximately 1.414) and orthogonal
/// moves cost 1. This represents true Euclidean-style movement on a grid.
///
/// The formula is: min(dx, dy) × √2 + |dx - dy|
///
/// **Use this for:** Weighted 8-directional movement with realistic diagonal costs
///
/// ## Example
///
/// ```gleam
/// let start = grid.coord_to_id(0, 0, 10)
/// let goal = grid.coord_to_id(3, 4, 10)
/// let distance = grid.octile_distance(start, goal, 10)
/// // => 5.242... (3 × √2 + 1)
/// ```
pub fn octile_distance(from_id: NodeId, to_id: NodeId, cols: Int) -> Float {
  let #(from_row, from_col) = id_to_coord(from_id, cols)
  let #(to_row, to_col) = id_to_coord(to_id, cols)

  let row_diff = int.absolute_value(from_row - to_row)
  let col_diff = int.absolute_value(from_col - to_col)

  let min_d = int.min(row_diff, col_diff)
  let max_d = int.max(row_diff, col_diff)

  // √2 ≈ 1.414213562373095
  int.to_float(min_d) *. 1.414213562373095 +. int.to_float(max_d - min_d)
}

// =============================================================================
// Node Lookup
// =============================================================================

/// Finds a node in the grid where the cell data matches a predicate.
///
/// Returns the node ID of the first matching cell, or Error(Nil) if not found.
///
/// ## Example
///
/// ```gleam
/// // Find the starting position marked with 'S'
/// case grid.find_node(grid, fn(cell) { cell == "S" }) {
///   Ok(start_id) -> // Use start_id
///   Error(_) -> // Not found
/// }
/// ```
pub fn find_node(
  grid: Grid(cell_data, e),
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

/// Allows movement between any cells except the specified wall value.
///
/// Useful for maze-style grids where `"#"` or similar marks a wall.
/// Both the source and destination cells must not be the wall value.
///
/// ## Example
///
/// ```gleam
/// // Maze where "#" is impassable
/// let maze = [
///   [".", "#", "."],
///   [".", ".", "."],
///   ["#", "#", "."],
/// ]
///
/// let g = grid.from_2d_list(maze, model.Directed, can_move: grid.avoiding("#"))
/// // Edges only connect non-wall cells
/// ```
// =============================================================================
// Movement Predicates
// =============================================================================

pub fn avoiding(wall_value: cell_data) -> fn(cell_data, cell_data) -> Bool {
  fn(from, to) { from != wall_value && to != wall_value }
}

/// Allows movement only between cells matching the specified value.
///
/// The inverse of `avoiding` — instead of blacklisting one value,
/// this whitelists exactly one value. Both the source and destination
/// cells must match the valid value.
///
/// ## Example
///
/// ```gleam
/// // Grid with varied terrain — only "." is walkable
/// let terrain = [
///   [".", "~", "^"],
///   [".", ".", "^"],
///   ["~", ".", "."],
/// ]
///
/// let g = grid.from_2d_list(terrain, model.Directed, can_move: grid.walkable("."))
/// // Only "." → "." edges exist
/// ```
pub fn walkable(valid_value: cell_data) -> fn(cell_data, cell_data) -> Bool {
  fn(from, to) { from == valid_value && to == valid_value }
}

/// Always allows movement between adjacent cells.
///
/// Every 4-directional neighbor pair gets an edge regardless of cell data.
/// Useful for fully connected grids or when the cell data is purely
/// informational (e.g., storing coordinates or labels).
///
/// ## Example
///
/// ```gleam
/// let labels = [["A", "B"], ["C", "D"]]
///
/// let g = grid.from_2d_list(labels, model.Undirected, can_move: grid.always())
/// // All adjacent cells are connected
/// ```
pub fn always() -> fn(cell_data, cell_data) -> Bool {
  fn(_from, _to) { True }
}

/// Allows movement only between cells matching any of the specified values.
///
/// A multi-value version of `walkable`. Both the source and destination
/// cells must be included in the valid values list.
///
/// ## Example
///
/// ```gleam
/// // Grid where both "." and "P" are walkable
/// let terrain = [
///   [".", "P", "#"],
///   ["#", ".", "."],
/// ]
///
/// let g = grid.from_2d_list(terrain, model.Directed, can_move: grid.including([".", "P"]))
/// // Edges exist between any combination of "." and "P"
/// ```
pub fn including(
  valid_values: List(cell_data),
) -> fn(cell_data, cell_data) -> Bool {
  fn(from, to) {
    list.contains(valid_values, from) && list.contains(valid_values, to)
  }
}
