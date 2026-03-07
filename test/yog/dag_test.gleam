import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/dag
import yog/dag/algorithms.{Ancestors, Descendants}
import yog/model.{Directed}

pub fn dag_models_test() {
  // Acyclic Graph
  let g1 =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")

  let assert Ok(d1) = dag.from_graph(g1)
  dag.to_graph(d1)
  |> should.equal(g1)

  // Cyclic Graph
  let g2 =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")
    |> model.add_edge_ensured(3, 1, 30, "")

  dag.from_graph(g2)
  |> should.be_error
}

pub fn topological_sort_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 3, 20, "")
    |> model.add_edge_ensured(2, 4, 30, "")
    |> model.add_edge_ensured(3, 4, 40, "")

  let assert Ok(d) = dag.from_graph(g)
  let sorted = dag.topological_sort(d)

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
    // Path 1-2-4 has weight 10 + 30 = 40
    // Path 1-3-4 has weight 20 + 40 = 60 (winner)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 3, 20, "")
    |> model.add_edge_ensured(2, 4, 30, "")
    |> model.add_edge_ensured(3, 4, 40, "")
    // 4-5 adds 5, so longest path should be 1-3-4-5 (weight 65)
    |> model.add_edge_ensured(4, 5, 5, "")

  let assert Ok(d) = dag.from_graph(g)
  dag.longest_path(d)
  |> should.equal([1, 3, 4, 5])
}

pub fn transitive_closure_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")

  let assert Ok(d) = dag.from_graph(g)
  let tc = dag.transitive_closure(d, with: int.add) |> dag.to_graph

  dict.get(tc.out_edges, 1) |> should.be_ok
  let assert Ok(targets_of_1) = dict.get(tc.out_edges, 1)
  dict.has_key(targets_of_1, 2) |> should.be_true
  dict.has_key(targets_of_1, 3) |> should.be_true
  // The new transitive edge
}

pub fn transitive_reduction_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")
    |> model.add_edge_ensured(1, 3, 30, "")
  // Redundant edge

  let assert Ok(d) = dag.from_graph(g)
  let tr = dag.transitive_reduction(d, with: int.add) |> dag.to_graph

  let assert Ok(targets_of_1) = dict.get(tr.out_edges, 1)
  dict.has_key(targets_of_1, 2) |> should.be_true
  dict.has_key(targets_of_1, 3) |> should.be_false
  // Should be removed
}

pub fn count_reachability_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(1, 4, 20, "")
    |> model.add_edge_ensured(2, 3, 30, "")
    |> model.add_edge_ensured(4, 3, 40, "")

  let assert Ok(d) = dag.from_graph(g)

  let descendants = dag.count_reachability(d, Descendants)
  dict.get(descendants, 1) |> should.equal(Ok(3))
  // 2, 4, 3
  dict.get(descendants, 3) |> should.equal(Ok(0))
  // none

  let ancestors = dag.count_reachability(d, Ancestors)
  dict.get(ancestors, 3) |> should.equal(Ok(3))
  // 1, 2, 4
  dict.get(ancestors, 1) |> should.equal(Ok(0))
  // none
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

  // 3 and 4 share ancestors 1, 2, and 0.
  // 1 and 2 are the "lowest" common ancestors because 0 is an ancestor of 1 and 2.

  let assert Ok(d) = dag.from_graph(g)
  let lca = dag.lowest_common_ancestors(d, 3, 4)

  list.length(lca) |> should.equal(2)
  list.contains(lca, 1) |> should.be_true
  list.contains(lca, 2) |> should.be_true
  list.contains(lca, 0) |> should.be_false
}

pub fn dag_mutation_test() {
  let g =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensured(1, 2, 10, "")
  let assert Ok(d) = dag.from_graph(g)

  // Test add_node
  let d2 = dag.add_node(d, 3, "C")
  let g2 = dag.to_graph(d2)
  list.contains(model.all_nodes(g2), 3) |> should.be_true

  // Test remove_node
  let d3 = dag.remove_node(d2, 2)
  let g3 = dag.to_graph(d3)
  list.contains(model.all_nodes(g3), 2) |> should.be_false
  // Ensure the edge 1->2 was also removed from the underlying graph
  list.length(model.successors(g3, 1)) |> should.equal(0)

  // Test remove_edge
  let d4 = dag.remove_edge(d, from: 1, to: 2)
  let g4 = dag.to_graph(d4)
  list.length(model.successors(g4, 1)) |> should.equal(0)

  // Test add_edge success (no cycle)
  let assert Ok(d5) = dag.add_edge(d, from: 2, to: 3, with: 20)
  let g5 = dag.to_graph(d5)
  list.length(model.successors(g5, 2)) |> should.equal(1)

  // Test add_edge failure (cycle)
  let d6 = dag.add_edge(d, from: 2, to: 1, with: 30)
  d6 |> should.be_error
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
