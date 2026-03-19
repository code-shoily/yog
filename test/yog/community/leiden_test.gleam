import gleam/dict
import gleeunit/should
import yog/community/karate_club
import yog/community/leiden
import yog/community/metrics
import yog/model

pub fn simple_two_communities_test() {
  // Two triangles connected by a single edge
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    // First triangle
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)
    // Second triangle
    |> model.add_edge_ensure(3, 4, 1, default: Nil)
    |> model.add_edge_ensure(4, 5, 1, default: Nil)
    |> model.add_edge_ensure(5, 3, 1, default: Nil)
    // Bridge edge
    |> model.add_edge_ensure(2, 3, 1, default: Nil)

  let comms = leiden.detect(g)

  // Should find at least 2 communities
  { comms.num_communities >= 2 } |> should.be_true
  { comms.num_communities <= 6 } |> should.be_true

  // All nodes should be assigned
  dict.size(comms.assignments) |> should.equal(6)

  // Modularity should be positive
  let q = metrics.modularity(g, comms)
  { q >. 0.0 } |> should.be_true
}

pub fn complete_graph_test() {
  // K5 should converge to 1 community (or close to it)
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(0, 2, 1, default: Nil)
    |> model.add_edge_ensure(0, 3, 1, default: Nil)
    |> model.add_edge_ensure(0, 4, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(1, 3, 1, default: Nil)
    |> model.add_edge_ensure(1, 4, 1, default: Nil)
    |> model.add_edge_ensure(2, 3, 1, default: Nil)
    |> model.add_edge_ensure(2, 4, 1, default: Nil)
    |> model.add_edge_ensure(3, 4, 1, default: Nil)

  let comms = leiden.detect(g)

  // A complete graph should ideally be 1 community
  { comms.num_communities >= 1 } |> should.be_true
  { comms.num_communities <= 3 } |> should.be_true

  // All nodes should be assigned
  dict.size(comms.assignments) |> should.equal(5)
}

pub fn modularity_test() {
  // Two disjoint triangles should have positive modularity
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

  let comms = leiden.detect(g)
  let q = metrics.modularity(g, comms)

  // Modularity should be positive for clear community structure
  { q >. 0.0 } |> should.be_true
}

pub fn with_options_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)

  let options =
    leiden.LeidenOptions(
      min_modularity_gain: 0.0001,
      max_iterations: 50,
      refinement_iterations: 3,
      seed: 123,
    )

  let comms = leiden.detect_with_options(g, options)
  { comms.num_communities >= 1 } |> should.be_true
  dict.size(comms.assignments) |> should.equal(3)
}

pub fn well_connected_test() {
  // Leiden guarantees well-connected communities
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    // Component A: 0-1-2 (path)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    // Component B: 3-4-5 (path)
    |> model.add_edge_ensure(3, 4, 1, default: Nil)
    |> model.add_edge_ensure(4, 5, 1, default: Nil)
    // Bridge between components
    |> model.add_edge_ensure(2, 3, 1, default: Nil)

  let comms = leiden.detect(g)

  // Should find reasonable communities
  { comms.num_communities >= 1 } |> should.be_true
}

pub fn karate_club_test() {
  // Test on the famous Zachary's Karate Club
  let g = karate_club.karate_club_graph()
  let comms = leiden.detect(g)

  // Should find some structure (usually 2-5 communities)
  { comms.num_communities >= 2 } |> should.be_true
  { comms.num_communities <= 6 } |> should.be_true

  // Check modularity is reasonable
  let q = metrics.modularity(g, comms)
  { q >. 0.0 } |> should.be_true
}

pub fn empty_graph_test() {
  let g = model.new(model.Undirected)
  let comms = leiden.detect(g)
  comms.num_communities |> should.equal(0)
}

pub fn single_node_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)

  let comms = leiden.detect(g)
  comms.num_communities |> should.equal(1)
}
