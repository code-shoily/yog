import gleam/dict
import gleam/option.{Some}
import gleeunit/should
import yog
import yog/generator/classic
import yog/pathfinding/path.{Path}
import yog/pathfinding/unweighted

pub fn unweighted_shortest_path_test() {
  // Line graph: 0-1-2-3-4
  // classic.path(5) returns a path graph P5
  let graph = classic.path(5)

  unweighted.shortest_path(graph, from: 0, to: 4)
  |> should.equal(Some(Path(nodes: [0, 1, 2, 3, 4], total_weight: 4)))

  unweighted.shortest_path(graph, from: 4, to: 0)
  |> should.equal(Some(Path(nodes: [4, 3, 2, 1, 0], total_weight: 4)))
}

pub fn unweighted_single_source_test() {
  // Cycle graph: 0-1-2-0
  let graph = classic.cycle(3)

  let dists = unweighted.single_source_distances(graph, source: 0)
  dict.get(dists, 0) |> should.equal(Ok(0))
  dict.get(dists, 1) |> should.equal(Ok(1))
  dict.get(dists, 2) |> should.equal(Ok(1))
}

pub fn unweighted_apsp_test() {
  // Tiny graph: 0-1, 1-2
  let graph =
    yog.undirected()
    |> yog.add_edge_ensure(0, 1, 1, Nil)
    |> yog.add_edge_ensure(1, 2, 1, Nil)

  let apsp = unweighted.all_pairs_shortest_paths(graph)

  dict.get(apsp, #(0, 0)) |> should.equal(Ok(0))
  dict.get(apsp, #(0, 1)) |> should.equal(Ok(1))
  dict.get(apsp, #(0, 2)) |> should.equal(Ok(2))
  dict.get(apsp, #(1, 0)) |> should.equal(Ok(1))
  dict.get(apsp, #(2, 0)) |> should.equal(Ok(2))
}

pub fn unweighted_unreachable_test() {
  let graph =
    yog.directed()
    |> yog.add_node(0, "a")
    |> yog.add_node(1, "b")

  unweighted.shortest_path(graph, from: 0, to: 1)
  |> should.equal(option.None)

  let dists = unweighted.single_source_distances(graph, source: 0)
  dict.get(dists, 1) |> should.equal(Error(Nil))
}
