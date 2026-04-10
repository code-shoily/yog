import gleam/dict
import gleam/int
import gleam/order
import gleeunit/should
import yog/pathfinding/util

pub fn compare_frontier_test() {
  let cmp = int.compare
  util.compare_frontier(#(10, [1]), #(20, [2]), cmp)
  |> should.equal(order.Lt)

  util.compare_frontier(#(20, [1]), #(10, [2]), cmp)
  |> should.equal(order.Gt)

  util.compare_frontier(#(10, [1]), #(10, [2]), cmp)
  |> should.equal(order.Eq)
}

pub fn compare_distance_frontier_test() {
  let cmp = int.compare
  util.compare_distance_frontier(#(10, 1), #(20, 2), cmp)
  |> should.equal(order.Lt)

  util.compare_distance_frontier(#(20, 1), #(10, 2), cmp)
  |> should.equal(order.Gt)

  util.compare_distance_frontier(#(10, 1), #(10, 2), cmp)
  |> should.equal(order.Eq)
}

pub fn compare_a_star_frontier_test() {
  let cmp = int.compare
  // a: #(f, g, path), b: #(f, g, path)
  util.compare_a_star_frontier(#(10, 5, [1]), #(20, 10, [2]), cmp)
  |> should.equal(order.Lt)

  util.compare_a_star_frontier(#(20, 10, [1]), #(10, 5, [2]), cmp)
  |> should.equal(order.Gt)

  util.compare_a_star_frontier(#(10, 5, [1]), #(10, 5, [2]), cmp)
  |> should.equal(order.Eq)
}

pub fn should_explore_node_test() {
  let compare = int.compare
  let visited = dict.from_list([#(1, 10), #(2, 20)])

  // Node not visited
  util.should_explore_node(visited, 3, 5, compare)
  |> should.be_true()

  // Node visited, new distance shorter
  util.should_explore_node(visited, 1, 5, compare)
  |> should.be_true()

  // Node visited, new distance equal
  util.should_explore_node(visited, 1, 10, compare)
  |> should.be_false()

  // Node visited, new distance longer
  util.should_explore_node(visited, 1, 15, compare)
  |> should.be_false()
}
