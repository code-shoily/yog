import gleam/list
import gleeunit/should
import yog/community/random_walk
import yog/model.{Undirected}

pub fn random_walk_test() {
  // Simple path: 0-1-2
  let g =
    model.new(Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)

  let walk = random_walk.random_walk(g, 0, 10)

  // Walk should start with 0
  list.first(walk) |> should.equal(Ok(0))

  // All nodes in walk should be 0, 1, or 2
  list.each(walk, fn(node) { { node >= 0 && node <= 2 } |> should.be_true })
}

pub fn random_walk_with_restart_test() {
  let g =
    model.new(Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)

  // With high restart probability, it should stay at 0 mostly
  let walk = random_walk.random_walk_with_restart(g, 0, 0.9, 100)
  let count0 = list.filter(walk, fn(n) { n == 0 }) |> list.length
  { count0 > 50 } |> should.be_true
}
