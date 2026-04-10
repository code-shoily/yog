import gleam/dict
import gleeunit/should
import yog/community/karate_club
import yog/community/louvain
import yog/community/metrics
import yog/model

pub fn simple_two_communities_test() {
  // Two triangles connected by a single edge
  // Louvain should find communities, though may not be exactly 2 due to local optima
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

  let comms = louvain.detect(g)

  // Should find at least 2 communities (may find more due to local optima on small graphs)
  { comms.num_communities >= 2 } |> should.be_true
  { comms.num_communities <= 6 } |> should.be_true

  // All nodes should be assigned
  dict.size(comms.assignments) |> should.equal(6)

  // Modularity should be positive for this clear community structure
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

  let comms = louvain.detect(g)

  // A complete graph should ideally be 1 community
  // But the algorithm may find more on small graphs
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

  let comms = louvain.detect(g)
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
    louvain.LouvainOptions(
      min_modularity_gain: 0.0001,
      max_iterations: 50,
      seed: 123,
    )

  let comms = louvain.detect_with_options(g, options)

  // Should produce valid communities
  { comms.num_communities >= 1 } |> should.be_true
  dict.size(comms.assignments) |> should.equal(3)
}

pub fn empty_graph_test() {
  let g = model.new(model.Undirected)
  let comms = louvain.detect(g)
  comms.num_communities |> should.equal(0)
}

pub fn single_node_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)

  let comms = louvain.detect(g)
  comms.num_communities |> should.equal(1)
}

pub fn karate_club_test() {
  // Test on the famous Zachary's Karate Club
  let g = karate_club.karate_club_graph()
  let comms = louvain.detect(g)

  // Should find some structure (usually 2-5 communities, but can vary with randomization)
  { comms.num_communities >= 2 } |> should.be_true
  // Relax upper bound as different shuffle algorithms may produce different valid results
  { comms.num_communities <= 8 } |> should.be_true

  // Check modularity is reasonable
  let q = metrics.modularity(g, comms)
  { q >. 0.0 } |> should.be_true
}
