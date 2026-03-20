import gleam/dict
import gleeunit/should
import yog
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

pub fn modularity_weighted_graph_test() {
  // Graph: 1-2 (weight 10), 2-3 (weight 1), 3-4 (weight 10)
  // Comm A: {1, 2}, Comm B: {3, 4}
  // Total degree sum 2m = 10*2 + 1*2 + 10*2 = 42
  // m = 21
  // For Comm A: sum_in = 20, sum_tot = 10 + 11 = 21
  // Q_A = (20/42) - (21/42)^2 = 20/42 - 1/4 = 40/84 - 21/84 = 19/84
  // For Comm B: sum_in = 20, sum_tot = 10 + 11 = 21
  // Q_B = 19/84
  // Q_total = 38/84 = 19/42 = 0.4523809523809524
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([#(1, 2, 10), #(2, 3, 1), #(3, 4, 10)])

  let assignments = dict.from_list([#(1, 1), #(2, 1), #(3, 2), #(4, 2)])
  let communities = Communities(assignments, 2)

  let q = metrics.modularity(graph, communities)
  let diff = q -. 0.45238095
  let abs_diff = case diff <. 0.0 {
    True -> 0.0 -. diff
    False -> diff
  }

  { abs_diff <. 0.000001 } |> should.be_true()
}
