import gleam/dict
import gleeunit/should
import yog/model.{Directed, Undirected}

pub fn add_edges_success_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 5), #(1, 3, 15)])

  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 10), #(3, 15)])))

  graph.out_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(3, 5)])))
}

pub fn add_edges_fails_on_missing_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  // Node 3 doesn't exist
  model.add_edges(graph, [#(1, 2, 10), #(2, 3, 5)])
  |> should.equal(Error("Node 3 does not exist"))
}

pub fn add_edges_fails_fast_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  // Both node 2 and 3 don't exist, but should fail on first edge (1->2)
  model.add_edges(graph, [#(1, 2, 10), #(2, 3, 5)])
  |> should.equal(Error("Node 2 does not exist"))
}

pub fn add_simple_edges_success_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_simple_edges([#(1, 2), #(2, 3), #(1, 3)])

  // All edges should have weight 1
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 1), #(3, 1)])))

  graph.out_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(3, 1)])))
}

pub fn add_simple_edges_fails_on_missing_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  model.add_simple_edges(graph, [#(1, 2), #(2, 3)])
  |> should.equal(Error("Node 2 does not exist"))
}

pub fn add_unweighted_edges_success_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_unweighted_edges([#(1, 2), #(2, 3), #(1, 3)])

  // All edges should have weight Nil
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, Nil), #(3, Nil)])))

  graph.out_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(3, Nil)])))
}

pub fn add_unweighted_edges_fails_on_missing_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  model.add_unweighted_edges(graph, [#(1, 2)])
  |> should.equal(Error("Node 2 does not exist"))
}

pub fn add_edges_empty_list_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let assert Ok(result) = model.add_edges(graph, [])

  result
  |> should.equal(graph)
}

pub fn add_edges_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 10)])

  // Should create edges in both directions
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 10)])))

  graph.out_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(1, 10)])))
}
