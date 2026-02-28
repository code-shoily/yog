//// A builder for creating graphs from 2D grids.
////
//// This module provides convenient ways to convert 2D grids (like heightmaps,
//// mazes, or game boards) into graphs for pathfinding and traversal algorithms.
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
import gleam/list
import yog/internal/utils
import yog/model.{type Graph, type GraphType, type NodeId}

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

/// Creates a graph from a 2D list (list of rows).
///
/// Each cell becomes a node, and edges are added between adjacent cells
/// (up/down/left/right) if the `can_move` predicate returns True.
///
/// ## Example
///
/// ```gleam
/// // A heightmap where you can only climb 1 unit at a time
/// let heightmap = [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
///
/// let grid = grid.from_2d_list(
///   heightmap,
///   model.Directed,
///   can_move: fn(from, to) { to - from <= 1 }
/// )
/// ```
///
/// **Time Complexity:** O(rows * cols)
pub fn from_2d_list(
  grid_data: List(List(cell_data)),
  graph_type: GraphType,
  can_move can_move: fn(cell_data, cell_data) -> Bool,
) -> Grid(cell_data, Int) {
  // Calculate dimensions
  let rows = list.length(grid_data)
  let cols = case grid_data {
    [first_row, ..] -> list.length(first_row)
    [] -> 0
  }

  // Create empty graph
  let mut_graph = model.new(graph_type)

  // Flatten grid to list of (row, col, cell_data)
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

  // Add edges between adjacent cells
  let graph_with_edges =
    cells
    |> list.fold(graph_with_nodes, fn(g, cell) {
      let #(row, col, from_data) = cell
      let from_id = coord_to_id(row, col, cols)

      // Check all 4-directional neighbors
      let neighbors = [
        #(row - 1, col),
        // Up
        #(row + 1, col),
        // Down
        #(row, col - 1),
        // Left
        #(row, col + 1),
        // Right
      ]

      neighbors
      |> list.fold(g, fn(acc_g, neighbor) {
        let #(n_row, n_col) = neighbor

        // Check bounds
        case n_row >= 0 && n_row < rows && n_col >= 0 && n_col < cols {
          False -> acc_g
          True -> {
            let to_id = coord_to_id(n_row, n_col, cols)

            // Get neighbor's cell data from already-built graph nodes (O(1) dict lookup)
            case dict.get(graph_with_nodes.nodes, to_id) {
              Ok(to_data) -> {
                // Check if move is valid
                case can_move(from_data, to_data) {
                  True ->
                    model.add_edge(acc_g, from: from_id, to: to_id, with: 1)
                  False -> acc_g
                }
              }
              Error(_) -> acc_g
            }
          }
        }
      })
    })

  Grid(graph: graph_with_edges, rows: rows, cols: cols)
}

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

  let row_diff = case from_row > to_row {
    True -> from_row - to_row
    False -> to_row - from_row
  }

  let col_diff = case from_col > to_col {
    True -> from_col - to_col
    False -> to_col - from_col
  }

  row_diff + col_diff
}

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
  // Generate list of all node IDs
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
