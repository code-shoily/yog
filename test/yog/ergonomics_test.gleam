import gleeunit/should
import yog
import yog/model

pub fn ergonomics_pipeline_test() {
  // Should be able to use the entire pipeline from the yog module
  let assert Ok(graph) =
    yog.directed()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let graph = yog.transpose(graph)
  // Re-exported from transform

  // Verify re-exported traversal
  let path = yog.walk(in: graph, from: 1, using: yog.breadth_first)
  path |> should.equal([1])
  // 1 is now a sink since edges were 1->2 and 2->3, reversed it's 2->1 and 3->2

  let reachable = yog.walk(in: graph, from: 3, using: yog.breadth_first)
  reachable |> should.equal([3, 2, 1])
}

pub fn transform_reexport_test() {
  let graph = yog.undirected() |> yog.add_edge_ensure(1, 2, 5, default: Nil)

  // Re-exported map_nodes
  let graph2 = yog.map_nodes(graph, fn(_) { "data" })
  yog.all_nodes(graph2) |> should.equal([1, 2])

  // Re-exported filter_edges
  let graph3 = yog.filter_edges(graph, fn(_, _, w) { w > 10 })
  yog.successors(graph3, 1) |> should.equal([])
}

pub fn traversal_fold_reexport_test() {
  let graph = yog.from_edges(model.Directed, [#(1, 2, 5)])

  // Re-exported fold_walk and constants
  let count =
    yog.fold_walk(
      from: 1,
      using: yog.breadth_first,
      initial: 0,
      with: fn(acc, _id, _meta) { #(yog.continue, acc + 1) },
      over: graph,
    )

  count |> should.equal(2)
}
