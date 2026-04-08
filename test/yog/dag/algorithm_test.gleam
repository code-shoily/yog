import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/dag/algorithm.{Ancestors, Descendants}
import yog/dag/model as dag_model
import yog/model.{Directed}

pub fn topological_sort_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(1, 3, 20, "")
    |> model.add_edge_ensure(2, 4, 30, "")
    |> model.add_edge_ensure(3, 4, 40, "")

  let assert Ok(d) = dag_model.from_graph(g)
  let sorted = algorithm.topological_sort(d)

  // Both 2 and 3 must come after 1, and 4 must come after 2 and 3
  list.contains(sorted, 1) |> should.be_true
  list.contains(sorted, 4) |> should.be_true

  let i1 = get_index(sorted, 1)
  let i2 = get_index(sorted, 2)
  let i3 = get_index(sorted, 3)
  let i4 = get_index(sorted, 4)

  should.be_true(i1 < i2)
  should.be_true(i1 < i3)
  should.be_true(i2 < i4)
  should.be_true(i3 < i4)
}

pub fn longest_path_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(1, 3, 20, "")
    |> model.add_edge_ensure(2, 4, 30, "")
    |> model.add_edge_ensure(3, 4, 40, "")
    |> model.add_edge_ensure(4, 5, 5, "")

  let assert Ok(d) = dag_model.from_graph(g)
  algorithm.longest_path(d)
  |> should.equal([1, 3, 4, 5])
}

pub fn shortest_path_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(1, 3, 20, "")
    |> model.add_edge_ensure(2, 4, 30, "")
    |> model.add_edge_ensure(3, 4, 40, "")
    |> model.add_edge_ensure(4, 5, 5, "")

  let assert Ok(d) = dag_model.from_graph(g)

  // Shortest path from 1 to 5: 1->2->4->5 = 10+30+5 = 45
  let path = algorithm.shortest_path(d, from: 1, to: 5)
  let assert Some(p) = path
  p.nodes |> should.equal([1, 2, 4, 5])
  p.total_weight |> should.equal(45)
}

pub fn shortest_path_no_path_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_node(3, "isolated")

  let assert Ok(d) = dag_model.from_graph(g)

  // No path from 1 to 3
  algorithm.shortest_path(d, from: 1, to: 3)
  |> should.equal(None)
}

pub fn shortest_path_same_node_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")

  let assert Ok(d) = dag_model.from_graph(g)

  // Path from node to itself has distance 0
  let path = algorithm.shortest_path(d, from: 1, to: 1)
  let assert Some(p) = path
  p.nodes |> should.equal([1])
  p.total_weight |> should.equal(0)
}

pub fn count_reachability_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(1, 4, 20, "")
    |> model.add_edge_ensure(2, 3, 30, "")
    |> model.add_edge_ensure(4, 3, 40, "")

  let assert Ok(d) = dag_model.from_graph(g)

  let descendants = algorithm.count_reachability(d, Descendants)
  dict.get(descendants, 1) |> should.equal(Ok(3))
  dict.get(descendants, 3) |> should.equal(Ok(0))

  let ancestors = algorithm.count_reachability(d, Ancestors)
  dict.get(ancestors, 3) |> should.equal(Ok(3))
  dict.get(ancestors, 1) |> should.equal(Ok(0))
}

pub fn lowest_common_ancestors_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensure(1, 3, 10, "")
    |> model.add_edge_ensure(1, 4, 20, "")
    |> model.add_edge_ensure(2, 3, 30, "")
    |> model.add_edge_ensure(2, 4, 40, "")
    |> model.add_edge_ensure(0, 1, 50, "")
    |> model.add_edge_ensure(0, 2, 60, "")

  let assert Ok(d) = dag_model.from_graph(g)
  let lca = algorithm.lowest_common_ancestors(d, 3, 4)

  list.length(lca) |> should.equal(2)
  list.contains(lca, 1) |> should.be_true
  list.contains(lca, 2) |> should.be_true
  list.contains(lca, 0) |> should.be_false
}

fn get_index(l: List(a), item: a) -> Int {
  do_get_index(l, item, 0)
}

fn do_get_index(l: List(a), item: a, acc: Int) -> Int {
  case l {
    [] -> -1
    [x, ..] if x == item -> acc
    [_, ..rest] -> do_get_index(rest, item, acc + 1)
  }
}
