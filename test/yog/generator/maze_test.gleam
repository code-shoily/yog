import gleam/int
import gleam/list
import gleam/option.{Some}
import gleeunit/should
import yog/builder/grid
import yog/connectivity
import yog/generator/maze
import yog/model

pub fn binary_tree_dimensions_test() {
  let g = maze.binary_tree(5, 10, seed: Some(42))
  g.rows |> should.equal(5)
  g.cols |> should.equal(10)
}

pub fn binary_tree_reproducibility_test() {
  let m1 = maze.binary_tree(10, 10, seed: Some(123))
  let m2 = maze.binary_tree(10, 10, seed: Some(123))

  let g1 = grid.to_graph(m1)
  let g2 = grid.to_graph(m2)

  model.all_edges(g1)
  |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
  |> should.equal(
    model.all_edges(g2) |> list.sort(fn(a, b) { int.compare(a.0, b.0) }),
  )
}

pub fn sidewinder_connectivity_test() {
  let m = maze.sidewinder(5, 5, seed: Some(123))
  let g = grid.to_graph(m)

  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn recursive_backtracker_perfect_maze_test() {
  let rows = 5
  let cols = 5
  let m = maze.recursive_backtracker(rows, cols, seed: Some(42))
  let g = grid.to_graph(m)

  // Connectivity
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)

  // Spanning tree: N-1 edges in undirected terms.
  // yog model for undirected graphs returns count / 2 for edge_count.
  let num_cells = rows * cols
  model.edge_count(g)
  |> should.equal(num_cells - 1)
}

pub fn hunt_and_kill_test() {
  let m = maze.hunt_and_kill(4, 4, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn aldous_broder_test() {
  let m = maze.aldous_broder(4, 4, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn wilson_test() {
  let m = maze.wilson(4, 4, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn kruskal_test() {
  let m = maze.kruskal(5, 5, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn growing_tree_test() {
  let m = maze.growing_tree(5, 5, maze.Random, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn prim_simplified_test() {
  let m = maze.prim_simplified(5, 5, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn prim_true_test() {
  let m = maze.prim_true(5, 5, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn ellers_test() {
  let m = maze.ellers(5, 5, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}

pub fn recursive_division_test() {
  let m = maze.recursive_division(5, 5, seed: Some(42))
  let g = grid.to_graph(m)
  connectivity.strongly_connected_components(g)
  |> list.length()
  |> should.equal(1)
}
