import gleam/dict
import gleeunit/should
import yog/builder/grid
import yog/community.{Communities}
import yog/community/metrics
import yog/model

pub fn count_triangles_test() {
  // Triangle graph: K3
  let g =
    grid.from_2d_list(
      [[1, 2], [3, 4]],
      model.Undirected,
      can_move: grid.always(),
    )
    |> grid.to_graph

  // In a 2x2 grid with cardinal neighbors, there are no triangles.
  metrics.count_triangles(g) |> should.equal(0)

  // Create a triangle manually
  let triangle =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)

  metrics.count_triangles(triangle) |> should.equal(1)
}

pub fn modularity_test() {
  // Simple case: two disjoint triangles
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)
    |> model.add_edge_ensure(3, 4, 1, default: Nil)
    |> model.add_edge_ensure(4, 5, 1, default: Nil)
    |> model.add_edge_ensure(5, 3, 1, default: Nil)

  let assignments =
    dict.from_list([#(0, 0), #(1, 0), #(2, 0), #(3, 1), #(4, 1), #(5, 1)])
  let comms = Communities(assignments, 2)

  let q = metrics.modularity(g, comms)
  // For two perfectly separated identical communities, Q should be positive.
  { q >. 0.4 } |> should.be_true
}

pub fn clustering_coefficient_test() {
  let triangle =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)

  metrics.clustering_coefficient(triangle, 0) |> should.equal(1.0)
}
