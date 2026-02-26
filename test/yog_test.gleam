import gleeunit
import gleeunit/should
import yog
import yog/model

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn directed_creates_directed_graph_test() {
  let graph = yog.directed()

  // Should be able to add nodes and edges
  let graph =
    graph
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_edge(from: 1, to: 2, with: 10)

  // Verify it's directed (edge only goes one way)
  yog.successors(graph, 1)
  |> should.equal([#(2, 10)])

  yog.predecessors(graph, 1)
  |> should.equal([])

  yog.predecessors(graph, 2)
  |> should.equal([#(1, 10)])
}

pub fn undirected_creates_undirected_graph_test() {
  let graph = yog.undirected()

  // Should be able to add nodes and edges
  let graph =
    graph
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_edge(from: 1, to: 2, with: 5)

  // Verify it's undirected (edge goes both ways)
  yog.successors(graph, 1)
  |> should.equal([#(2, 5)])

  yog.successors(graph, 2)
  |> should.equal([#(1, 5)])
}

pub fn directed_equivalent_to_new_directed_test() {
  let graph1 =
    yog.directed()
    |> yog.add_node(1, "A")
    |> yog.add_edge(from: 1, to: 2, with: 10)

  let graph2 =
    yog.new(model.Directed)
    |> yog.add_node(1, "A")
    |> yog.add_edge(from: 1, to: 2, with: 10)

  // Both should have same structure
  yog.successors(graph1, 1)
  |> should.equal(yog.successors(graph2, 1))

  yog.all_nodes(graph1)
  |> should.equal(yog.all_nodes(graph2))
}

pub fn undirected_equivalent_to_new_undirected_test() {
  let graph1 =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_edge(from: 1, to: 2, with: 5)

  let graph2 =
    yog.new(model.Undirected)
    |> yog.add_node(1, "A")
    |> yog.add_edge(from: 1, to: 2, with: 5)

  // Both should have same structure
  yog.successors(graph1, 1)
  |> should.equal(yog.successors(graph2, 1))

  yog.all_nodes(graph1)
  |> should.equal(yog.all_nodes(graph2))
}

pub fn add_unweighted_edge_test() {
  let graph: yog.Graph(String, Nil) =
    yog.directed()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_unweighted_edge(from: 1, to: 2)

  yog.successors(graph, 1)
  |> should.equal([#(2, Nil)])
}

pub fn add_simple_edge_test() {
  let graph =
    yog.directed()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_simple_edge(from: 1, to: 2)

  yog.successors(graph, 1)
  |> should.equal([#(2, 1)])
}

pub fn add_simple_edge_multiple_test() {
  let graph =
    yog.directed()
    |> yog.add_simple_edge(from: 1, to: 2)
    |> yog.add_simple_edge(from: 2, to: 3)
    |> yog.add_simple_edge(from: 3, to: 4)

  // All edges should have weight 1
  yog.successors(graph, 1)
  |> should.equal([#(2, 1)])

  yog.successors(graph, 2)
  |> should.equal([#(3, 1)])

  yog.successors(graph, 3)
  |> should.equal([#(4, 1)])
}

pub fn add_unweighted_edge_undirected_test() {
  let graph: yog.Graph(String, Nil) =
    yog.undirected()
    |> yog.add_unweighted_edge(from: 1, to: 2)

  // Should work in both directions
  yog.successors(graph, 1)
  |> should.equal([#(2, Nil)])

  yog.successors(graph, 2)
  |> should.equal([#(1, Nil)])
}
