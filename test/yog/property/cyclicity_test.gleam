import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/property/cyclicity

pub fn is_cyclic_directed_acyclic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(1, 3, 1)])

  cyclicity.is_cyclic(graph) |> should.be_false()
  cyclicity.is_acyclic(graph) |> should.be_true()
}

pub fn is_cyclic_directed_cyclic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

  cyclicity.is_cyclic(graph) |> should.be_true()
  cyclicity.is_acyclic(graph) |> should.be_false()
}

pub fn is_cyclic_undirected_acyclic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(2, 4, 1)])

  cyclicity.is_cyclic(graph) |> should.be_false()
  cyclicity.is_acyclic(graph) |> should.be_true()
}

pub fn is_cyclic_undirected_cyclic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

  cyclicity.is_cyclic(graph) |> should.be_true()
  cyclicity.is_acyclic(graph) |> should.be_false()
}

pub fn is_cyclic_undirected_self_loop_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_edge(from: 1, to: 1, with: 1)

  cyclicity.is_cyclic(graph) |> should.be_true()
  cyclicity.is_acyclic(graph) |> should.be_false()
}

pub fn is_cyclic_empty_graph_directed_test() {
  let graph = model.new(Directed)

  cyclicity.is_cyclic(graph) |> should.be_false()
  cyclicity.is_acyclic(graph) |> should.be_true()
}

pub fn is_cyclic_empty_graph_undirected_test() {
  let graph = model.new(Undirected)

  cyclicity.is_cyclic(graph) |> should.be_false()
  cyclicity.is_acyclic(graph) |> should.be_true()
}
