import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/community/label_propagation
import yog/model

pub fn complete_graph_test() {
  // K5 should converge to 1 community
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(0, 1, Nil, default: Nil)
    |> model.add_edge_ensure(0, 2, Nil, default: Nil)
    |> model.add_edge_ensure(0, 3, Nil, default: Nil)
    |> model.add_edge_ensure(0, 4, Nil, default: Nil)
    |> model.add_edge_ensure(1, 2, Nil, default: Nil)
    |> model.add_edge_ensure(1, 3, Nil, default: Nil)
    |> model.add_edge_ensure(1, 4, Nil, default: Nil)
    |> model.add_edge_ensure(2, 3, Nil, default: Nil)
    |> model.add_edge_ensure(2, 4, Nil, default: Nil)
    |> model.add_edge_ensure(3, 4, Nil, default: Nil)

  let comms = label_propagation.detect(g)
  comms.num_communities |> should.equal(1)
}

pub fn disjoint_cliques_test() {
  // Two triangles: {0,1,2} and {3,4,5}
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    |> model.add_edge_ensure(0, 1, Nil, default: Nil)
    |> model.add_edge_ensure(1, 2, Nil, default: Nil)
    |> model.add_edge_ensure(2, 0, Nil, default: Nil)
    |> model.add_edge_ensure(3, 4, Nil, default: Nil)
    |> model.add_edge_ensure(4, 5, Nil, default: Nil)
    |> model.add_edge_ensure(5, 3, Nil, default: Nil)

  let comms = label_propagation.detect(g)
  comms.num_communities |> should.equal(2)

  let label0 = dict.get(comms.assignments, 0) |> should.be_ok
  let label2 = dict.get(comms.assignments, 2) |> should.be_ok
  let label3 = dict.get(comms.assignments, 3) |> should.be_ok
  let label5 = dict.get(comms.assignments, 5) |> should.be_ok

  label0 |> should.equal(label2)
  label3 |> should.equal(label5)
  label0 |> should.not_equal(label3)
}

pub fn ffi_shuffle_test() {
  let l = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let s = label_propagation.shuffle(l)
  list.length(s) |> should.equal(10)
  list.sort(s, int.compare) |> should.equal(l)
}

pub fn ffi_random_int_test() {
  let n = 10
  let r = label_propagation.random_int(n)
  { r >= 1 && r <= n } |> should.be_true
}
