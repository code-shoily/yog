import gleam/list
import gleeunit/should
import yog
import yog/builder/toroidal
import yog/model

// Basic toroidal grid building tests

pub fn from_2d_list_creates_toroidal_grid_test() {
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  let graph = toroidal.to_graph(grid_result)

  // Check that nodes exist
  model.order(graph)
  |> should.equal(9)
}

pub fn coord_to_id_conversion_test() {
  // Same as regular grid - row-major ordering
  toroidal.coord_to_id(0, 0, 3)
  |> should.equal(0)

  toroidal.coord_to_id(0, 2, 3)
  |> should.equal(2)

  toroidal.coord_to_id(1, 1, 3)
  |> should.equal(4)

  toroidal.coord_to_id(2, 2, 3)
  |> should.equal(8)
}

pub fn id_to_coord_conversion_test() {
  toroidal.id_to_coord(0, 3)
  |> should.equal(#(0, 0))

  toroidal.id_to_coord(2, 3)
  |> should.equal(#(0, 2))

  toroidal.id_to_coord(4, 3)
  |> should.equal(#(1, 1))

  toroidal.id_to_coord(8, 3)
  |> should.equal(#(2, 2))
}

// Wrapping behavior tests

pub fn wrapping_horizontal_test() {
  // 3x3 grid where all moves are allowed
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  let graph = toroidal.to_graph(grid_result)

  // From rightmost cell (0,2), moving right should wrap to (0,0)
  let right_cell = toroidal.coord_to_id(0, 2, 3)
  let left_cell = toroidal.coord_to_id(0, 0, 3)

  let successors = yog.successors(graph, right_cell)

  successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(left_cell)
  |> should.be_true
}

pub fn wrapping_vertical_test() {
  // 3x3 grid where all moves are allowed
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  let graph = toroidal.to_graph(grid_result)

  // From bottom cell (2,1), moving down should wrap to (0,1)
  let bottom_cell = toroidal.coord_to_id(2, 1, 3)
  let top_cell = toroidal.coord_to_id(0, 1, 3)

  let successors = yog.successors(graph, bottom_cell)

  successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(top_cell)
  |> should.be_true
}

pub fn wrapping_diagonal_test() {
  // 3x3 grid with queen topology (8-way movement)
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list_with_topology(
      grid_data,
      model.Directed,
      toroidal.queen(),
      can_move: fn(_, _) { True },
    )

  let graph = toroidal.to_graph(grid_result)

  // From bottom-right corner (2,2), moving down-right should wrap to (0,0)
  let corner = toroidal.coord_to_id(2, 2, 3)
  let opposite = toroidal.coord_to_id(0, 0, 3)

  let successors = yog.successors(graph, corner)

  successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(opposite)
  |> should.be_true
}

pub fn no_boundary_cells_in_toroidal_test() {
  // In a toroidal grid, every cell should have the same number of neighbors
  // (assuming all moves are allowed)
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  let graph = toroidal.to_graph(grid_result)

  // Every cell should have exactly 4 neighbors (rook topology)
  [0, 1, 2, 3, 4, 5, 6, 7, 8]
  |> list.each(fn(id) {
    let successors = yog.successors(graph, id)
    successors
    |> list.length
    |> should.equal(4)
  })
}

pub fn queen_topology_all_cells_have_8_neighbors_test() {
  // With queen topology, every cell should have 8 neighbors
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list_with_topology(
      grid_data,
      model.Directed,
      toroidal.queen(),
      can_move: fn(_, _) { True },
    )

  let graph = toroidal.to_graph(grid_result)

  // Every cell should have exactly 8 neighbors
  [0, 1, 2, 3, 4, 5, 6, 7, 8]
  |> list.each(fn(id) {
    let successors = yog.successors(graph, id)
    successors
    |> list.length
    |> should.equal(8)
  })
}

// Toroidal distance function tests

pub fn toroidal_manhattan_distance_no_wrapping_test() {
  // Distance that doesn't benefit from wrapping
  let from = toroidal.coord_to_id(0, 0, 10)
  let to = toroidal.coord_to_id(2, 3, 10)

  // Direct path is shorter: 2 + 3 = 5
  toroidal.toroidal_manhattan_distance(from, to, 10, 10)
  |> should.equal(5)
}

pub fn toroidal_manhattan_distance_with_horizontal_wrapping_test() {
  // On a 10-wide grid, from column 1 to column 9
  let from = toroidal.coord_to_id(0, 1, 10)
  let to = toroidal.coord_to_id(0, 9, 10)

  // Direct: 8, Wrapped: 2 (left)
  toroidal.toroidal_manhattan_distance(from, to, 10, 10)
  |> should.equal(2)
}

pub fn toroidal_manhattan_distance_with_vertical_wrapping_test() {
  // On a 10-tall grid, from row 1 to row 9
  let from = toroidal.coord_to_id(1, 0, 10)
  let to = toroidal.coord_to_id(9, 0, 10)

  // Direct: 8, Wrapped: 2 (up)
  toroidal.toroidal_manhattan_distance(from, to, 10, 10)
  |> should.equal(2)
}

pub fn toroidal_manhattan_distance_with_both_wrapping_test() {
  // From (1,1) to (9,9) on 10x10 grid
  let from = toroidal.coord_to_id(1, 1, 10)
  let to = toroidal.coord_to_id(9, 9, 10)

  // Direct: 8 + 8 = 16
  // Wrapped: min(8,2) + min(8,2) = 2 + 2 = 4
  toroidal.toroidal_manhattan_distance(from, to, 10, 10)
  |> should.equal(4)
}

pub fn toroidal_manhattan_distance_same_cell_test() {
  let same = toroidal.coord_to_id(5, 5, 10)

  toroidal.toroidal_manhattan_distance(same, same, 10, 10)
  |> should.equal(0)
}

pub fn toroidal_chebyshev_distance_no_wrapping_test() {
  // Distance that doesn't benefit from wrapping
  let from = toroidal.coord_to_id(0, 0, 10)
  let to = toroidal.coord_to_id(2, 3, 10)

  // Chebyshev: max(2, 3) = 3
  toroidal.toroidal_chebyshev_distance(from, to, 10, 10)
  |> should.equal(3)
}

pub fn toroidal_chebyshev_distance_with_wrapping_test() {
  // From (1,1) to (9,9) on 10x10 grid
  let from = toroidal.coord_to_id(1, 1, 10)
  let to = toroidal.coord_to_id(9, 9, 10)

  // Direct: max(8, 8) = 8
  // Wrapped: max(min(8,2), min(8,2)) = max(2, 2) = 2
  toroidal.toroidal_chebyshev_distance(from, to, 10, 10)
  |> should.equal(2)
}

pub fn toroidal_chebyshev_distance_asymmetric_wrapping_test() {
  // From (1,1) to (9,5) on 10x10 grid
  let from = toroidal.coord_to_id(1, 1, 10)
  let to = toroidal.coord_to_id(9, 5, 10)

  // row_diff = 8, wrapped = 2
  // col_diff = 4, wrapped = 4
  // max(2, 4) = 4
  toroidal.toroidal_chebyshev_distance(from, to, 10, 10)
  |> should.equal(4)
}

pub fn toroidal_octile_distance_no_wrapping_test() {
  // Distance that doesn't benefit from wrapping
  let from = toroidal.coord_to_id(0, 0, 10)
  let to = toroidal.coord_to_id(2, 3, 10)

  // min(2,3) * √2 + |2-3| = 2 * 1.414... + 1 = 3.828...
  let distance = toroidal.toroidal_octile_distance(from, to, 10, 10)

  distance
  |> should.equal(3.82842712474619)
}

pub fn toroidal_octile_distance_with_wrapping_test() {
  // From (1,1) to (9,9) on 10x10 grid
  let from = toroidal.coord_to_id(1, 1, 10)
  let to = toroidal.coord_to_id(9, 9, 10)

  // Wrapped distances: 2, 2
  // min(2,2) * √2 + |2-2| = 2 * 1.414... = 2.828...
  let distance = toroidal.toroidal_octile_distance(from, to, 10, 10)

  distance
  |> should.equal(2.82842712474619)
}

pub fn toroidal_octile_distance_same_cell_test() {
  let same = toroidal.coord_to_id(5, 5, 10)

  toroidal.toroidal_octile_distance(same, same, 10, 10)
  |> should.equal(0.0)
}

// Movement predicate tests

pub fn avoiding_works_on_toroidal_test() {
  let maze = [[".", "#", "."], [".", ".", "."], ["#", "#", "."]]

  let g =
    toroidal.from_2d_list(
      maze,
      model.Directed,
      can_move: toroidal.avoiding("#"),
    )
  let graph = toroidal.to_graph(g)

  // (0,0)="." should not reach (0,1)="#" even with wrapping
  let top_left_successors = yog.successors(graph, toroidal.coord_to_id(0, 0, 3))
  top_left_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(toroidal.coord_to_id(0, 1, 3))
  |> should.be_false
}

pub fn always_connects_all_with_wrapping_test() {
  let labels = [["A", "B"], ["C", "D"]]

  let g =
    toroidal.from_2d_list(labels, model.Directed, can_move: toroidal.always())
  let graph = toroidal.to_graph(g)

  // All 4 nodes should exist
  model.order(graph)
  |> should.equal(4)

  // In a 2x2 toroidal grid with rook movement:
  // Left and right wrap to the same neighbor, up and down also wrap to same
  // So each cell has exactly 2 unique neighbors (not 4)
  [0, 1, 2, 3]
  |> list.each(fn(id) {
    let successors = yog.successors(graph, id)
    successors
    |> list.length
    |> should.equal(2)
  })
}

pub fn get_cell_retrieves_correct_data_test() {
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  // Get center cell
  toroidal.get_cell(grid_result, 1, 1)
  |> should.equal(Ok(5))

  // Get corner cells
  toroidal.get_cell(grid_result, 0, 0)
  |> should.equal(Ok(1))

  toroidal.get_cell(grid_result, 2, 2)
  |> should.equal(Ok(9))

  // Out of bounds
  toroidal.get_cell(grid_result, 3, 3)
  |> should.equal(Error(Nil))

  toroidal.get_cell(grid_result, -1, 0)
  |> should.equal(Error(Nil))
}

pub fn find_node_test() {
  let grid_data = [["S", ".", "."], [".", "#", "."], [".", ".", "E"]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  // Find start node
  let start = toroidal.find_node(grid_result, fn(cell) { cell == "S" })
  start
  |> should.equal(Ok(0))

  // Find end node
  let end = toroidal.find_node(grid_result, fn(cell) { cell == "E" })
  end
  |> should.equal(Ok(8))

  // Find non-existent
  let not_found = toroidal.find_node(grid_result, fn(cell) { cell == "X" })
  not_found
  |> should.equal(Error(Nil))
}

// Topology preset tests

pub fn knight_topology_wraps_correctly_test() {
  // 6x6 board for knight movement (4x4 is too small, creates duplicates)
  let board = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
  ]

  let g =
    toroidal.from_2d_list_with_topology(
      board,
      model.Directed,
      toroidal.knight(),
      can_move: toroidal.always(),
    )
  let graph = toroidal.to_graph(g)

  // Knight at (0,0) should have 8 possible moves on 6x6 toroidal
  let corner = yog.successors(graph, toroidal.coord_to_id(0, 0, 6))
  corner
  |> list.length
  |> should.equal(8)
}

pub fn undirected_toroidal_grid_test() {
  let grid_data = [[1, 2], [3, 4]]

  let grid_result =
    toroidal.from_2d_list(grid_data, model.Undirected, can_move: fn(_, _) {
      True
    })

  let graph = toroidal.to_graph(grid_result)

  // In undirected toroidal 2x2 with rook movement:
  // Left wraps to right (same neighbor), up wraps to down (same neighbor)
  // So each cell has exactly 2 unique neighbors
  let top_left = toroidal.coord_to_id(0, 0, 2)
  let successors = yog.successors(graph, top_left)

  successors
  |> list.length
  |> should.equal(2)
}

pub fn including_allows_multiple_cell_types_test() {
  let maze = [["S", "#"], [".", "E"]]

  let g =
    toroidal.from_2d_list(
      maze,
      model.Directed,
      can_move: toroidal.including([".", "S", "E"]),
    )
  let graph = toroidal.to_graph(g)

  // From "S" at (0,0), wrapping down goes to (1,0)="."
  // But wrapping right goes to (0,1)="#" which should be blocked
  let start_successors = yog.successors(graph, toroidal.coord_to_id(0, 0, 2))

  // Should be able to reach (1,0)="." but not (0,1)="#"
  start_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(toroidal.coord_to_id(1, 0, 2))
  |> should.be_true

  start_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(toroidal.coord_to_id(0, 1, 2))
  |> should.be_false
}
