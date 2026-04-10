import gleam/int
import gleam/option.{None, Some}
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/property/structure

fn tree_graph() {
  model.new(Undirected)
  |> model.add_node(1, Nil)
  |> model.add_node(2, Nil)
  |> model.add_node(3, Nil)
  |> model.add_node(4, Nil)
  |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
  |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
  |> model.add_edge_ensure(2, 4, with: 1, default: Nil)
}

fn cycle_graph() {
  model.new(Undirected)
  |> model.add_node(1, Nil)
  |> model.add_node(2, Nil)
  |> model.add_node(3, Nil)
  |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
  |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
  |> model.add_edge_ensure(3, 1, with: 1, default: Nil)
}

fn complete_graph(n: Int) {
  let g = model.new(Undirected)
  let g = int.range(1, n + 1, g, fn(acc, id) { model.add_node(acc, id, Nil) })
  int.range(1, n + 1, g, fn(acc, i) {
    case i + 1 <= n {
      True ->
        int.range(i + 1, n + 1, acc, fn(inner, j) {
          model.add_edge_ensure(inner, i, j, with: 1, default: Nil)
        })
      False -> acc
    }
  })
}

fn arborescence_graph() {
  model.new(Directed)
  |> model.add_node(1, Nil)
  |> model.add_node(2, Nil)
  |> model.add_node(3, Nil)
  |> model.add_node(4, Nil)
  |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
  |> model.add_edge_ensure(1, 3, with: 1, default: Nil)
  |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
}

pub fn is_tree_test() {
  let tree = tree_graph()
  let cycle = cycle_graph()
  let directed =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)

  structure.is_tree(tree)
  |> should.be_true()

  structure.is_tree(cycle)
  |> should.be_false()

  structure.is_tree(directed)
  |> should.be_false()

  structure.is_tree(model.new(Undirected))
  |> should.be_false()
}

pub fn is_arborescence_test() {
  let arb = arborescence_graph()
  let not_arb =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 1, with: 1, default: Nil)

  structure.is_arborescence(arb)
  |> should.be_true()

  structure.is_arborescence(not_arb)
  |> should.be_false()

  structure.is_arborescence(tree_graph())
  |> should.be_false()
}

pub fn arborescence_root_test() {
  let arb = arborescence_graph()

  structure.arborescence_root(arb)
  |> should.equal(Some(1))

  structure.arborescence_root(tree_graph())
  |> should.equal(None)
}

pub fn is_complete_test() {
  let k3 = complete_graph(3)
  let path = tree_graph()
  let with_loop =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(1, 1, with: 1, default: Nil)

  structure.is_complete(k3)
  |> should.be_true()

  structure.is_complete(path)
  |> should.be_false()

  structure.is_complete(with_loop)
  |> should.be_false()

  structure.is_complete(model.new(Undirected))
  |> should.be_true()
}

pub fn is_regular_test() {
  let cycle = cycle_graph()
  let tree = tree_graph()

  structure.is_regular(cycle, 2)
  |> should.be_true()

  structure.is_regular(cycle, 1)
  |> should.be_false()

  structure.is_regular(tree, 2)
  |> should.be_false()

  structure.is_regular(model.new(Undirected), 0)
  |> should.be_true()
}

pub fn is_connected_test() {
  let connected = tree_graph()
  let disconnected =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)

  structure.is_connected(connected)
  |> should.be_true()

  structure.is_connected(disconnected)
  |> should.be_false()
}

pub fn is_strongly_connected_test() {
  let scc =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 1, with: 1, default: Nil)

  let not_scc = arborescence_graph()

  structure.is_strongly_connected(scc)
  |> should.be_true()

  structure.is_strongly_connected(not_scc)
  |> should.be_false()
}

pub fn is_weakly_connected_test() {
  let weak =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 2, with: 1, default: Nil)

  let not_weak =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)

  structure.is_weakly_connected(weak)
  |> should.be_true()

  structure.is_weakly_connected(not_weak)
  |> should.be_false()
}

pub fn is_planar_test() {
  let k4 = complete_graph(4)
  let k5 = complete_graph(5)
  let k33 =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    |> model.add_node(6, Nil)
    |> model.add_edge_ensure(1, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(1, 5, with: 1, default: Nil)
    |> model.add_edge_ensure(1, 6, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 5, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 6, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 5, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 6, with: 1, default: Nil)

  structure.is_planar(k4)
  |> should.be_true()

  structure.is_planar(k5)
  |> should.be_false()

  structure.is_planar(k33)
  |> should.be_false()
}

pub fn is_chordal_test() {
  let chordal = complete_graph(4)
  let not_chordal =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(4, 1, with: 1, default: Nil)

  structure.is_chordal(chordal)
  |> should.be_true()

  structure.is_chordal(not_chordal)
  |> should.be_false()

  structure.is_chordal(model.new(Directed) |> model.add_node(1, Nil))
  |> should.be_false()
}
