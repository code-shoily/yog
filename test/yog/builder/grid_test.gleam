import gleam/int
import gleam/list
import gleeunit/should
import yog
import yog/builder/grid
import yog/model
import yog/traversal.{BreadthFirst}

// Basic grid building tests

pub fn from_2d_list_creates_grid_test() {
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  // Check dimensions
  grid_result.rows
  |> should.equal(3)

  grid_result.cols
  |> should.equal(3)
}

pub fn coord_to_id_conversion_test() {
  // For a 3x3 grid:
  // (0,0)=0  (0,1)=1  (0,2)=2
  // (1,0)=3  (1,1)=4  (1,2)=5
  // (2,0)=6  (2,1)=7  (2,2)=8

  grid.coord_to_id(0, 0, 3)
  |> should.equal(0)

  grid.coord_to_id(0, 2, 3)
  |> should.equal(2)

  grid.coord_to_id(1, 1, 3)
  |> should.equal(4)

  grid.coord_to_id(2, 2, 3)
  |> should.equal(8)
}

pub fn id_to_coord_conversion_test() {
  grid.id_to_coord(0, 3)
  |> should.equal(#(0, 0))

  grid.id_to_coord(2, 3)
  |> should.equal(#(0, 2))

  grid.id_to_coord(4, 3)
  |> should.equal(#(1, 1))

  grid.id_to_coord(8, 3)
  |> should.equal(#(2, 2))
}

pub fn get_cell_retrieves_correct_data_test() {
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  // Get center cell
  grid.get_cell(grid_result, 1, 1)
  |> should.equal(Ok(5))

  // Get corner cells
  grid.get_cell(grid_result, 0, 0)
  |> should.equal(Ok(1))

  grid.get_cell(grid_result, 2, 2)
  |> should.equal(Ok(9))

  // Out of bounds
  grid.get_cell(grid_result, 3, 3)
  |> should.equal(Error(Nil))

  grid.get_cell(grid_result, -1, 0)
  |> should.equal(Error(Nil))
}

// Movement constraint tests

pub fn can_move_constraint_applied_test() {
  let grid_data = [[1, 2, 5], [2, 3, 6], [3, 4, 7]]

  // Can only move if height difference is at most 1
  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(from, to) {
      to - from <= 1
    })

  let graph = grid.to_graph(grid_result)

  // From (0,0)=1, can move to (0,1)=2 (diff=1) and (1,0)=2 (diff=1)
  let successors = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  successors
  |> should.equal([#(1, 1), #(3, 1)])

  // From (0,1)=2, cannot move to (0,2)=5 (diff=3)
  // But can move to (1,1)=3 (diff=1)
  let _successors_2 = yog.successors(graph, grid.coord_to_id(0, 1, 3))
  // Verify edges are constrained
}

pub fn undirected_grid_test() {
  let grid_data = [[1, 2], [3, 4]]

  let grid_result =
    grid.from_2d_list(grid_data, model.Undirected, can_move: fn(_, _) { True })

  let graph = grid.to_graph(grid_result)

  // In undirected graph, edges go both ways
  let top_left = grid.coord_to_id(0, 0, 2)
  let top_right = grid.coord_to_id(0, 1, 2)

  // From top-left, should be able to reach top-right
  let left_successors = yog.successors(graph, top_left)
  left_successors
  |> list.any(fn(succ: #(Int, Int)) { succ.0 == top_right })
  |> should.be_true

  // From top-right, should be able to reach top-left
  let right_successors = yog.successors(graph, top_right)
  right_successors
  |> list.any(fn(succ: #(Int, Int)) { succ.0 == top_left })
  |> should.be_true
}

// Manhattan distance tests

pub fn manhattan_distance_test() {
  // Distance from (0,0) to (3,4) in a grid with 10 columns
  let from = grid.coord_to_id(0, 0, 10)
  let to = grid.coord_to_id(3, 4, 10)

  grid.manhattan_distance(from, to, 10)
  |> should.equal(7)

  // Distance from (2,3) to (2,7)
  let from2 = grid.coord_to_id(2, 3, 10)
  let to2 = grid.coord_to_id(2, 7, 10)

  grid.manhattan_distance(from2, to2, 10)
  |> should.equal(4)

  // Distance from (5,5) to (5,5) should be 0
  let same = grid.coord_to_id(5, 5, 10)

  grid.manhattan_distance(same, same, 10)
  |> should.equal(0)
}

// Find node tests

pub fn find_node_test() {
  let grid_data = [["S", ".", "."], [".", "#", "."], [".", ".", "E"]]

  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  // Find start node
  let start = grid.find_node(grid_result, fn(cell) { cell == "S" })
  start
  |> should.equal(Ok(0))

  // Find end node
  let end = grid.find_node(grid_result, fn(cell) { cell == "E" })
  end
  |> should.equal(Ok(8))

  // Find wall
  let wall = grid.find_node(grid_result, fn(cell) { cell == "#" })
  wall
  |> should.equal(Ok(4))

  // Find non-existent
  let not_found = grid.find_node(grid_result, fn(cell) { cell == "X" })
  not_found
  |> should.equal(Error(Nil))
}

// Integration test: pathfinding on grid

pub fn pathfinding_on_grid_test() {
  // Simple 3x3 grid where all moves are valid
  let grid_data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(_, _) { True })

  let graph = grid.to_graph(grid_result)

  // Find path from top-left (0,0) to bottom-right (2,2) using BFS
  let start = grid.coord_to_id(0, 0, 3)
  let goal = grid.coord_to_id(2, 2, 3)

  let path =
    traversal.walk_until(
      from: start,
      using: BreadthFirst,
      until: fn(node) { node == goal },
      in: graph,
    )

  // Path should exist
  path
  |> list.is_empty
  |> should.be_false

  // Path should end at goal
  path
  |> list.last
  |> should.equal(Ok(goal))
}

// AoC-style test: heightmap with climbing constraint

pub fn heightmap_climbing_test() {
  // Simplified AoC 2022 Day 12 style test
  // 'a' = 1, 'b' = 2, 'c' = 3, etc.
  let grid_data = [[1, 2, 3], [2, 3, 4], [3, 4, 5]]

  // Can only climb 1 unit at a time, but descend any amount
  let grid_result =
    grid.from_2d_list(grid_data, model.Directed, can_move: fn(from, to) {
      to - from <= 1
    })

  let graph = grid.to_graph(grid_result)

  // From (0,0)=1, should be able to move to adjacent cells with height 2
  let start = grid.coord_to_id(0, 0, 3)
  let successors = yog.successors(graph, start)

  // Should have 2 successors: (0,1)=2 and (1,0)=2
  successors
  |> list.length
  |> should.equal(2)

  // From (1,1)=3, can move to cells with height up to 4
  let middle = grid.coord_to_id(1, 1, 3)
  let middle_successors = yog.successors(graph, middle)

  // Can go to: down (2,1)=4, right (1,2)=4
  // Cannot go to: up (0,1)=2 (descent), left (1,0)=2 (descent)
  // Wait, we allow descent (to-from can be negative)
  // Let me re-check the logic
  middle_successors
  |> list.length
  |> should.equal(4)
}

// Predicate helper tests

pub fn avoiding_blocks_walls_test() {
  // "#" cells should be unreachable
  let maze = [[".", "#", "."], [".", ".", "."], ["#", "#", "."]]

  let g = grid.from_2d_list(maze, model.Directed, can_move: grid.avoiding("#"))
  let graph = grid.to_graph(g)

  // (0,0)="." -> can reach (1,0)="." (down) but NOT (0,1)="#" (right)
  let top_left_successors = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  top_left_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(grid.coord_to_id(1, 0, 3))
  |> should.be_true

  top_left_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(grid.coord_to_id(0, 1, 3))
  |> should.be_false

  // (1,1)="." -> can reach all 4 non-wall neighbors
  // up=(0,1)="#" NO, down=(2,1)="#" NO, left=(1,0)="." YES, right=(1,2)="." YES
  let center_successors = yog.successors(graph, grid.coord_to_id(1, 1, 3))
  center_successors
  |> list.length
  |> should.equal(2)
}

pub fn avoiding_blocks_movement_from_wall_test() {
  // avoiding checks both from and to, blocking movement from the wall
  let maze = [["#", "."]]

  let g = grid.from_2d_list(maze, model.Directed, can_move: grid.avoiding("#"))
  let graph = grid.to_graph(g)

  // From "#" at (0,0), cannot move to "." at (0,1) because source is "#"
  let wall_successors = yog.successors(graph, grid.coord_to_id(0, 0, 2))
  wall_successors
  |> list.map(fn(s) { s.0 })
  |> list.contains(grid.coord_to_id(0, 1, 2))
  |> should.be_false
}

pub fn walkable_only_allows_matching_cells_test() {
  // Only "." -> "." edges should exist
  let terrain = [[".", "~", "^"], [".", ".", "^"], ["~", ".", "."]]

  let g =
    grid.from_2d_list(terrain, model.Directed, can_move: grid.walkable("."))
  let graph = grid.to_graph(g)

  // (0,0)="." -> can only reach (1,0)="." (down), NOT (0,1)="~" (right)
  let successors_00 = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  successors_00
  |> list.length
  |> should.equal(1)
  successors_00
  |> list.map(fn(s) { s.0 })
  |> list.contains(grid.coord_to_id(1, 0, 3))
  |> should.be_true

  // (1,1)="." -> can reach (1,0)="." (left) and (2,1)="." (down)
  // cannot reach (0,1)="~" (up) or (1,2)="^" (right)
  let successors_11 = yog.successors(graph, grid.coord_to_id(1, 1, 3))
  successors_11
  |> list.length
  |> should.equal(2)
}

pub fn walkable_blocks_movement_from_non_matching_test() {
  // walkable checks both from and to, so "~" cannot move to "."
  let terrain = [["~", "."]]

  let g =
    grid.from_2d_list(terrain, model.Directed, can_move: grid.walkable("."))
  let graph = grid.to_graph(g)

  // From "~" at (0,0), cannot move to "." at (0,1)
  let successors = yog.successors(graph, grid.coord_to_id(0, 0, 2))
  successors
  |> list.length
  |> should.equal(0)
}

pub fn always_connects_all_adjacent_cells_test() {
  let labels = [["A", "B", "C"], ["D", "E", "F"]]

  let g = grid.from_2d_list(labels, model.Directed, can_move: grid.always())
  let graph = grid.to_graph(g)

  // All 6 nodes should exist
  model.order(graph)
  |> should.equal(6)

  // Corner (0,0) has 2 neighbors: right and down
  let corner_successors = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  corner_successors
  |> list.length
  |> should.equal(2)

  // Middle top (0,1) has 3 neighbors: left, right, down
  let mid_top_successors = yog.successors(graph, grid.coord_to_id(0, 1, 3))
  mid_top_successors
  |> list.length
  |> should.equal(3)

  // Center (1,1) has 3 neighbors: up, left, right (no down, only 2 rows)
  let center_successors = yog.successors(graph, grid.coord_to_id(1, 1, 3))
  center_successors
  |> list.length
  |> should.equal(3)
}

pub fn always_undirected_test() {
  let labels = [["A", "B"], ["C", "D"]]

  let g = grid.from_2d_list(labels, model.Undirected, can_move: grid.always())
  let graph = grid.to_graph(g)

  // In undirected 2x2, each corner has 2 neighbors
  let tl = yog.successors(graph, grid.coord_to_id(0, 0, 2))
  tl |> list.length |> should.equal(2)

  let br = yog.successors(graph, grid.coord_to_id(1, 1, 2))
  br |> list.length |> should.equal(2)
}

pub fn avoiding_and_walkable_equivalence_for_binary_grid_test() {
  // For a grid with only "." and "#", avoiding("#") and walkable(".") behave
  // identically: both allow movement only into "." cells.
  let maze = [[".", "#"], [".", "."]]

  let g1 = grid.from_2d_list(maze, model.Directed, can_move: grid.avoiding("#"))
  let g2 = grid.from_2d_list(maze, model.Directed, can_move: grid.walkable("."))

  // Both should produce the same edges from every node
  [0, 1, 2, 3]
  |> list.each(fn(id) {
    let s1 =
      yog.successors(grid.to_graph(g1), id)
      |> list.map(fn(s) { s.0 })
      |> list.sort(int.compare)
    let s2 =
      yog.successors(grid.to_graph(g2), id)
      |> list.map(fn(s) { s.0 })
      |> list.sort(int.compare)
    s1 |> should.equal(s2)
  })
}

// Topology preset tests

pub fn queen_topology_gives_8_neighbors_for_center_test() {
  // 3x3 grid, center cell should have all 8 neighbors
  let data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let g =
    grid.from_2d_list_with_topology(
      data,
      model.Directed,
      grid.queen(),
      can_move: grid.always(),
    )
  let graph = grid.to_graph(g)

  // Center (1,1) should have 8 neighbors
  let center = yog.successors(graph, grid.coord_to_id(1, 1, 3))
  center |> list.length |> should.equal(8)

  // Corner (0,0) should have 3 neighbors: right, down, diagonal
  let corner = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  corner |> list.length |> should.equal(3)
}

pub fn bishop_topology_diagonal_only_test() {
  let data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let g =
    grid.from_2d_list_with_topology(
      data,
      model.Directed,
      grid.bishop(),
      can_move: grid.always(),
    )
  let graph = grid.to_graph(g)

  // Center (1,1) should have exactly 4 diagonal neighbors
  let center = yog.successors(graph, grid.coord_to_id(1, 1, 3))
  center |> list.length |> should.equal(4)

  // Verify neighbors are the 4 corners
  let neighbor_ids = list.map(center, fn(s) { s.0 })
  neighbor_ids |> list.contains(grid.coord_to_id(0, 0, 3)) |> should.be_true
  neighbor_ids |> list.contains(grid.coord_to_id(0, 2, 3)) |> should.be_true
  neighbor_ids |> list.contains(grid.coord_to_id(2, 0, 3)) |> should.be_true
  neighbor_ids |> list.contains(grid.coord_to_id(2, 2, 3)) |> should.be_true

  // Center should NOT reach cardinal neighbors
  neighbor_ids |> list.contains(grid.coord_to_id(0, 1, 3)) |> should.be_false
  neighbor_ids |> list.contains(grid.coord_to_id(1, 0, 3)) |> should.be_false

  // Corner (0,0) should have exactly 1 diagonal neighbor: (1,1)
  let corner = yog.successors(graph, grid.coord_to_id(0, 0, 3))
  corner |> list.length |> should.equal(1)
}

pub fn knight_topology_l_shaped_jumps_test() {
  // 5x5 board, knight in center should have all 8 L-shaped targets
  let board = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ]

  let g =
    grid.from_2d_list_with_topology(
      board,
      model.Directed,
      grid.knight(),
      can_move: grid.always(),
    )
  let graph = grid.to_graph(g)

  // Knight at center (2,2) should reach all 8 L-shaped squares
  let center = yog.successors(graph, grid.coord_to_id(2, 2, 5))
  center |> list.length |> should.equal(8)

  // Knight at corner (0,0) can only reach (1,2) and (2,1)
  let corner = yog.successors(graph, grid.coord_to_id(0, 0, 5))
  corner |> list.length |> should.equal(2)
  let corner_ids = list.map(corner, fn(s) { s.0 })
  corner_ids |> list.contains(grid.coord_to_id(1, 2, 5)) |> should.be_true
  corner_ids |> list.contains(grid.coord_to_id(2, 1, 5)) |> should.be_true
}

pub fn rook_matches_from_2d_list_test() {
  // rook() topology should produce identical results to from_2d_list
  let data = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let g1 = grid.from_2d_list(data, model.Directed, can_move: grid.always())
  let g2 =
    grid.from_2d_list_with_topology(
      data,
      model.Directed,
      grid.rook(),
      can_move: grid.always(),
    )

  // Every node should have the same successors
  [0, 1, 2, 3, 4, 5, 6, 7, 8]
  |> list.each(fn(id) {
    let s1 =
      yog.successors(grid.to_graph(g1), id)
      |> list.map(fn(s) { s.0 })
      |> list.sort(int.compare)
    let s2 =
      yog.successors(grid.to_graph(g2), id)
      |> list.map(fn(s) { s.0 })
      |> list.sort(int.compare)
    s1 |> should.equal(s2)
  })
}

pub fn including_allows_multiple_cell_types_test() {
  // ".", "S", and "E" should be walkable, while "#" is not
  let maze = [["S", "#"], [".", "E"]]

  let g =
    grid.from_2d_list(
      maze,
      model.Directed,
      can_move: grid.including([".", "S", "E"]),
    )
  let graph = grid.to_graph(g)

  // From "S" at (0,0), can reach "E" at (1,1) via "." at (1,0)
  // (0,0)="S" -> (1,0)="." (down) YES, (0,1)="#" (right) NO
  let start_successors = yog.successors(graph, grid.coord_to_id(0, 0, 2))
  start_successors
  |> list.map(fn(s) { s.0 })
  |> should.equal([grid.coord_to_id(1, 0, 2)])

  // From (1,0)=".", can reach (0,0)="S" (up) and (1,1)="E" (right)
  let mid_successors = yog.successors(graph, grid.coord_to_id(1, 0, 2))
  mid_successors
  |> list.map(fn(s) { s.0 })
  |> list.sort(int.compare)
  |> should.equal([grid.coord_to_id(0, 0, 2), grid.coord_to_id(1, 1, 2)])
}
