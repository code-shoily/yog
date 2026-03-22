import gleeunit/should
import yog/dag/model as dag_model
import yog/model.{Directed}

pub fn dag_from_to_graph_test() {
  // Acyclic Graph
  let g1 =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(2, 3, 20, "")

  let assert Ok(d1) = dag_model.from_graph(g1)
  dag_model.to_graph(d1)
  |> should.equal(g1)

  // Cyclic Graph
  let g2 =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, 10, "")
    |> model.add_edge_ensure(2, 3, 20, "")
    |> model.add_edge_ensure(3, 1, 30, "")

  dag_model.from_graph(g2)
  |> should.be_error
}

pub fn dag_mutation_test() {
  let g =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(1, 2, 10, "")
  let assert Ok(d) = dag_model.from_graph(g)

  // Test add_node
  let d2 = dag_model.add_node(d, 3, "C")
  let g2 = dag_model.to_graph(d2)
  model.all_nodes(g2) |> should.equal([1, 2, 3])

  // Test remove_node
  let d3 = dag_model.remove_node(d2, 2)
  let g3 = dag_model.to_graph(d3)
  model.all_nodes(g3) |> should.equal([1, 3])
  // Ensure the edge 1->2 was also removed
  model.successors(g3, 1) |> should.equal([])

  // Test remove_edge
  let d4 = dag_model.remove_edge(d, from: 1, to: 2)
  let g4 = dag_model.to_graph(d4)
  model.successors(g4, 1) |> should.equal([])

  // Test add_edge success (no cycle)
  let d_with_node3 = dag_model.add_node(d, 3, "C")
  let assert Ok(d5) = dag_model.add_edge(d_with_node3, from: 2, to: 3, with: 20)
  let g5 = dag_model.to_graph(d5)
  model.successors(g5, 2) |> should.equal([#(3, 20)])

  // Test add_edge failure (cycle)
  let d6 = dag_model.add_edge(d, from: 2, to: 1, with: 30)
  d6 |> should.be_error
}
