import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/dag/algorithms.{Ancestors, Descendants}
import yog/dag/models
import yog/model.{Directed}

pub fn topological_sort_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 3, 20, "")
    |> model.add_edge_ensured(2, 4, 30, "")
    |> model.add_edge_ensured(3, 4, 40, "")

  let assert Ok(d) = models.from_graph(g)
  let sorted = algorithms.topological_sort(d)

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
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 3, 20, "")
    |> model.add_edge_ensured(2, 4, 30, "")
    |> model.add_edge_ensured(3, 4, 40, "")
    |> model.add_edge_ensured(4, 5, 5, "")

  let assert Ok(d) = models.from_graph(g)
  algorithms.longest_path(d)
  |> should.equal([1, 3, 4, 5])
}

pub fn transitive_closure_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")

  let assert Ok(d) = models.from_graph(g)
  let tc = algorithms.transitive_closure(d, with: int.add) |> models.to_graph

  let assert Ok(targets_of_1) = dict.get(tc.out_edges, 1)
  dict.has_key(targets_of_1, 2) |> should.be_true
  dict.has_key(targets_of_1, 3) |> should.be_true
}

pub fn transitive_reduction_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")
    |> model.add_edge_ensured(1, 3, 30, "")

  let assert Ok(d) = models.from_graph(g)
  let tr = algorithms.transitive_reduction(d, with: int.add) |> models.to_graph

  let assert Ok(targets_of_1) = dict.get(tr.out_edges, 1)
  dict.has_key(targets_of_1, 2) |> should.be_true
  dict.has_key(targets_of_1, 3) |> should.be_false
}

pub fn count_reachability_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 4, 20, "")
    |> model.add_edge_ensured(2, 3, 30, "")
    |> model.add_edge_ensured(4, 3, 40, "")

  let assert Ok(d) = models.from_graph(g)

  let descendants = algorithms.count_reachability(d, Descendants)
  dict.get(descendants, 1) |> should.equal(Ok(3))
  dict.get(descendants, 3) |> should.equal(Ok(0))

  let ancestors = algorithms.count_reachability(d, Ancestors)
  dict.get(ancestors, 3) |> should.equal(Ok(3))
  dict.get(ancestors, 1) |> should.equal(Ok(0))
}

pub fn lowest_common_ancestors_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 3, 10, "")
    |> model.add_edge_ensured(1, 4, 20, "")
    |> model.add_edge_ensured(2, 3, 30, "")
    |> model.add_edge_ensured(2, 4, 40, "")
    |> model.add_edge_ensured(0, 1, 50, "")
    |> model.add_edge_ensured(0, 2, 60, "")

  let assert Ok(d) = models.from_graph(g)
  let lca = algorithms.lowest_common_ancestors(d, 3, 4)

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
