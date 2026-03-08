import gleeunit/should
import yog/dag
import yog/model.{Directed}

pub fn dag_facade_test() {
  let g =
    model.new(Directed)
    |> model.add_edge_ensured(1, 2, 10, "")
    |> model.add_edge_ensured(2, 3, 20, "")

  let assert Ok(d) = dag.from_graph(g)

  // Test re-exports from models
  dag.to_graph(d) |> should.equal(g)

  // Test re-exports from algorithms
  dag.topological_sort(d) |> should.equal([1, 2, 3])
  dag.longest_path(d) |> should.equal([1, 2, 3])
}

pub fn dag_facade_mutation_test() {
  let g =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensured(1, 2, 10, "")
  let assert Ok(d) = dag.from_graph(g)

  // Test facade mutation re-exports
  let d2 = dag.add_node(d, 3, "C")
  let g2 = dag.to_graph(d2)
  model.all_nodes(g2) |> should.equal([1, 2, 3])

  dag.add_edge(d, from: 2, to: 1, with: 30) |> should.be_error
}
