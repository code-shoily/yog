import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/path

pub fn hydrate_path_directed_test() {
  let graph =
    model.new(Directed)
    |> model.add_edge_ensure(1, 2, "CAR", default: Nil)
    |> model.add_edge_ensure(2, 3, "BUS", default: Nil)

  let edges = path.hydrate_path(graph, [1, 2, 3])

  edges |> should.equal([#(1, 2, "CAR"), #(2, 3, "BUS")])
}

pub fn hydrate_path_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, Nil)

  let edges = path.hydrate_path(graph, [1])

  edges |> should.equal([])
}

pub fn hydrate_path_empty_test() {
  let graph = model.new(Directed)
  let edges = path.hydrate_path(graph, [])
  edges |> should.equal([])
}

pub fn hydrate_path_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_edge_ensure(1, 2, 10, default: Nil)
    |> model.add_edge_ensure(2, 3, 20, default: Nil)

  let edges = path.hydrate_path(graph, [1, 2, 3])

  edges |> should.equal([#(1, 2, 10), #(2, 3, 20)])
}
