import gleam/list
import gleam/set
import gleeunit/should
import yog/community/clique_percolation
import yog/model.{Undirected}

pub fn cpm_simple_test() {
  // Two triangles sharing a bridge would NOT be detected as one community by CPM-3
  // Two triangles sharing ONE node would NOT be detected as one community by CPM-3
  // Two triangles sharing TWO nodes (an edge) ARE detected as one community by CPM-3

  let g =
    model.new(Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)
    |> model.add_edge_ensure(1, 3, 1, default: Nil)
    |> model.add_edge_ensure(2, 3, 1, default: Nil)
  // Triangle (0,1,2) and (1,2,3) sharing edge (1,2)
  // Node 4 is isolated

  let overlapping = clique_percolation.detect_overlapping(g)

  list.length(overlapping.communities) |> should.equal(1)

  let comm0 = list.first(overlapping.communities) |> should.be_ok
  set.size(comm0) |> should.equal(4)
  set.contains(comm0, 0) |> should.be_true
  set.contains(comm0, 3) |> should.be_true
}

pub fn cpm_overlapping_test() {
  // Two triangles sharing one node
  // Each triangle is its own community, the shared node belongs to both
  let g =
    model.new(Undirected)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)
    |> model.add_edge_ensure(2, 3, 1, default: Nil)
    |> model.add_edge_ensure(3, 4, 1, default: Nil)
    |> model.add_edge_ensure(4, 2, 1, default: Nil)

  let overlapping = clique_percolation.detect_overlapping(g)

  list.length(overlapping.communities) |> should.equal(2)
}
