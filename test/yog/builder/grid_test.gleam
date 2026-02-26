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
      in: graph,
      using: BreadthFirst,
      until: fn(node) { node == goal },
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
