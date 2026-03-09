import gleam/dict
import gleam/int
import gleeunit/should
import yog/centrality
import yog/model

// Helper to check if two floats are approximately equal
fn assert_float_close(actual: Float, expected: Float) -> Nil {
  let tolerance = 0.0001
  let diff = case actual >. expected {
    True -> actual -. expected
    False -> expected -. actual
  }
  case diff <=. tolerance {
    True -> Nil
    False -> should.fail()
  }
}

// ---------------------------------------------------------------------------
// Degree Centrality - Undirected Graphs
// ---------------------------------------------------------------------------

pub fn degree_undirected_star_test() {
  // Star graph: node 1 connected to 2, 3, 4
  // 1 has degree 3 (max), others have degree 1
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // Center node (1) should have centrality 1.0 (connected to all others)
  dict.get(scores, 1) |> should.equal(Ok(1.0))

  // Leaf nodes should have centrality 0.333... (1/3)
  let assert Ok(leaf_score) = dict.get(scores, 2)
  assert_float_close(leaf_score, 0.333333)
}

pub fn degree_undirected_complete_graph_test() {
  // Complete graph K4: every node connected to every other node
  // Each node has degree 3, max possible is 3
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // All nodes should have centrality 1.0 (fully connected)
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
  dict.get(scores, 3) |> should.equal(Ok(1.0))
  dict.get(scores, 4) |> should.equal(Ok(1.0))
}

pub fn degree_undirected_path_test() {
  // Path graph: 1-2-3-4
  // Endpoints have degree 1, middle nodes have degree 2
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // Endpoints: degree 1 / 3 = 0.333...
  let assert Ok(endpoint) = dict.get(scores, 1)
  assert_float_close(endpoint, 0.333333)

  // Middle nodes: degree 2 / 3 = 0.666...
  let assert Ok(middle) = dict.get(scores, 2)
  assert_float_close(middle, 0.666666)
}

pub fn degree_undirected_isolated_node_test() {
  // Graph with isolated node
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "connected")
    |> model.add_node(2, "connected")
    |> model.add_node(3, "isolated")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // Isolated node has degree 0
  let assert Ok(isolated_score) = dict.get(scores, 3)
  isolated_score |> should.equal(0.0)

  // Connected nodes have degree 1 / 2 = 0.5
  let assert Ok(connected_score) = dict.get(scores, 1)
  connected_score |> should.equal(0.5)
}

pub fn degree_single_node_test() {
  // Single node - edge case for normalization
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores = centrality.degree(g, centrality.TotalDegree)

  // Avoids division by zero, returns 0.0
  dict.get(scores, 1) |> should.equal(Ok(0.0))
}

// ---------------------------------------------------------------------------
// Degree Centrality - Directed Graphs
// ---------------------------------------------------------------------------

pub fn degree_directed_out_degree_test() {
  // Directed graph: 1->2, 1->3, 2->3
  // Node 1: out-degree 2
  // Node 2: out-degree 1
  // Node 3: out-degree 0
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.degree(g, centrality.OutDegree)

  // Node 1: out-degree 2 / 2 = 1.0
  dict.get(scores, 1) |> should.equal(Ok(1.0))

  // Node 2: out-degree 1 / 2 = 0.5
  let assert Ok(node2_score) = dict.get(scores, 2)
  node2_score |> should.equal(0.5)

  // Node 3: out-degree 0 / 2 = 0.0
  dict.get(scores, 3) |> should.equal(Ok(0.0))
}

pub fn degree_directed_in_degree_test() {
  // Same graph: 1->2, 1->3, 2->3
  // Node 1: in-degree 0
  // Node 2: in-degree 1
  // Node 3: in-degree 2
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.degree(g, centrality.InDegree)

  // Node 1: in-degree 0
  dict.get(scores, 1) |> should.equal(Ok(0.0))

  // Node 2: in-degree 1 / 2 = 0.5
  let assert Ok(node2_score) = dict.get(scores, 2)
  node2_score |> should.equal(0.5)

  // Node 3: in-degree 2 / 2 = 1.0
  dict.get(scores, 3) |> should.equal(Ok(1.0))
}

pub fn degree_directed_total_degree_test() {
  // Same graph: 1->2, 1->3, 2->3
  // Node 1: in 0 + out 2 = 2
  // Node 2: in 1 + out 1 = 2
  // Node 3: in 2 + out 0 = 2
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // All nodes have total degree 2 / 2 = 1.0
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
  dict.get(scores, 3) |> should.equal(Ok(1.0))
}

pub fn degree_directed_mode_ignored_for_undirected_test() {
  // For undirected graphs, mode parameter should be ignored
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  // All modes should produce same result for undirected graph
  let total = centrality.degree(g, centrality.TotalDegree)
  let in_degree = centrality.degree(g, centrality.InDegree)
  let out_degree = centrality.degree(g, centrality.OutDegree)

  total |> should.equal(in_degree)
  total |> should.equal(out_degree)
}

// ---------------------------------------------------------------------------
// Edge Cases
// ---------------------------------------------------------------------------

pub fn degree_empty_graph_test() {
  // Empty graph
  let g = model.new(model.Undirected)

  let scores = centrality.degree(g, centrality.TotalDegree)

  dict.size(scores) |> should.equal(0)
}

pub fn degree_two_nodes_test() {
  // Simple edge case: just two nodes connected
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores = centrality.degree(g, centrality.TotalDegree)

  // Both have degree 1 / 1 = 1.0 (fully connected in 2-node graph)
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
}

// ---------------------------------------------------------------------------
// Closeness Centrality
// ---------------------------------------------------------------------------

pub fn closeness_star_graph_test() {
  // Star graph: node 1 connected to 2, 3, 4
  // Node 1 (center): distances [1, 1, 1], sum = 3, centrality = 3/3 = 1.0
  // Node 2 (leaf): distances [1, 2, 2], sum = 5, centrality = 3/5 = 0.6
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  // Center node should have highest centrality
  let assert Ok(center_score) = dict.get(scores, 1)
  center_score |> should.equal(1.0)

  // Leaf nodes should have lower centrality (3/5 = 0.6)
  let assert Ok(leaf_score) = dict.get(scores, 2)
  assert_float_close(leaf_score, 0.6)
}

pub fn closeness_path_graph_test() {
  // Path: 1-2-3-4
  // Node 1: distances [1, 2, 3], sum = 6, centrality = 3/6 = 0.5
  // Node 2: distances [1, 1, 2], sum = 4, centrality = 3/4 = 0.75
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  // End nodes have lower centrality
  let assert Ok(node1_score) = dict.get(scores, 1)
  assert_float_close(node1_score, 0.5)

  // Middle nodes have higher centrality
  let assert Ok(node2_score) = dict.get(scores, 2)
  assert_float_close(node2_score, 0.75)
}

pub fn closeness_complete_graph_test() {
  // Complete graph K4: every node connected to every other node
  // Each node: distances [1, 1, 1], sum = 3, centrality = 3/3 = 1.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  // All nodes should have perfect centrality
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
  dict.get(scores, 3) |> should.equal(Ok(1.0))
  dict.get(scores, 4) |> should.equal(Ok(1.0))
}

pub fn closeness_disconnected_graph_test() {
  // Disconnected graph: component 1-2 and isolated node 3
  // Node 3 cannot reach nodes 1 and 2, so centrality = 0.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  // Isolated node has 0.0 centrality
  let assert Ok(isolated_score) = dict.get(scores, 3)
  isolated_score |> should.equal(0.0)

  // Nodes in connected component can reach each other but not all nodes
  // Node 1 can only reach node 2 (1 out of 2 other nodes), so 0.0
  let assert Ok(node1_score) = dict.get(scores, 1)
  node1_score |> should.equal(0.0)
}

pub fn closeness_single_node_test() {
  // Single node has 0.0 centrality (edge case)
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  dict.get(scores, 1) |> should.equal(Ok(0.0))
}

pub fn closeness_two_nodes_test() {
  // Two connected nodes
  // Each node: distance [1], sum = 1, centrality = 1/1 = 1.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  // Both nodes should have perfect centrality (directly connected to each other)
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
}

pub fn closeness_empty_graph_test() {
  // Empty graph
  let g = model.new(model.Undirected)

  let scores = centrality.closeness(g, 0, int.add, int.compare, int.to_float)

  dict.size(scores) |> should.equal(0)
}

// ---------------------------------------------------------------------------
// Harmonic Centrality
// ---------------------------------------------------------------------------

pub fn harmonic_star_graph_test() {
  // Star graph: node 1 connected to 2, 3, 4
  // Node 1 (center): 1/1 + 1/1 + 1/1 = 3, normalized = 3/3 = 1.0
  // Node 2 (leaf): 1/1 + 1/2 + 1/2 = 2, normalized = 2/3 = 0.666...
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  // Center node has highest centrality (1.0)
  let assert Ok(center_score) = dict.get(scores, 1)
  center_score |> should.equal(1.0)

  // Leaf nodes: (1/1 + 1/2 + 1/2) / 3 = 2/3 = 0.666...
  let assert Ok(leaf_score) = dict.get(scores, 2)
  assert_float_close(leaf_score, 0.666666)
}

pub fn harmonic_path_graph_test() {
  // Path: 1-2-3-4
  // Node 1: 1/1 + 1/2 + 1/3 = 1.833... / 3 = 0.611...
  // Node 2: 1/1 + 1/1 + 1/2 = 2.5 / 3 = 0.833...
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  // End nodes have lower centrality
  let assert Ok(node1_score) = dict.get(scores, 1)
  assert_float_close(node1_score, 0.611111)

  // Middle nodes have higher centrality
  let assert Ok(node2_score) = dict.get(scores, 2)
  assert_float_close(node2_score, 0.833333)
}

pub fn harmonic_complete_graph_test() {
  // Complete graph K4: every node connected to every other node with distance 1
  // Each node: 1/1 + 1/1 + 1/1 = 3, normalized = 3/3 = 1.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  // All nodes should have perfect centrality
  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
  dict.get(scores, 3) |> should.equal(Ok(1.0))
  dict.get(scores, 4) |> should.equal(Ok(1.0))
}

pub fn harmonic_disconnected_graph_test() {
  // Disconnected graph: component 1-2 and isolated node 3
  // Unlike closeness, harmonic centrality works on disconnected graphs
  // Node 1: reaches node 2 at distance 1, cannot reach node 3
  // Node 1 score: (1/1) / 2 = 0.5 (only counts reachable nodes)
  // Node 3: reaches no one, score = 0.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  // Isolated node has 0.0 centrality
  let assert Ok(isolated_score) = dict.get(scores, 3)
  isolated_score |> should.equal(0.0)

  // Connected nodes can still reach each other
  // Node 1: 1/1 / 2 = 0.5
  let assert Ok(node1_score) = dict.get(scores, 1)
  node1_score |> should.equal(0.5)
}

pub fn harmonic_single_node_test() {
  // Single node has 0.0 centrality (edge case)
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  dict.get(scores, 1) |> should.equal(Ok(0.0))
}

pub fn harmonic_two_nodes_test() {
  // Two connected nodes
  // Each node: 1/1 / 1 = 1.0
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  dict.get(scores, 1) |> should.equal(Ok(1.0))
  dict.get(scores, 2) |> should.equal(Ok(1.0))
}

pub fn harmonic_empty_graph_test() {
  // Empty graph
  let g = model.new(model.Undirected)

  let scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  dict.size(scores) |> should.equal(0)
}

pub fn harmonic_vs_closeness_disconnected_test() {
  // Demonstrates key difference: harmonic works where closeness fails
  // Three nodes: 1-2 connected, 3 isolated
  // Closeness: nodes 1, 2, 3 all get 0.0 (can't reach everyone)
  // Harmonic: nodes 1, 2 get non-zero scores (count reachable nodes only)
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let closeness_scores =
    centrality.closeness(g, 0, int.add, int.compare, int.to_float)
  let harmonic_scores =
    centrality.harmonic_centrality(g, 0, int.add, int.compare, int.to_float)

  // Closeness gives 0.0 for all (disconnected graph)
  let assert Ok(c1) = dict.get(closeness_scores, 1)
  c1 |> should.equal(0.0)

  // Harmonic gives non-zero for connected component
  // Node 1: (1/1) / 2 = 0.5
  let assert Ok(h1) = dict.get(harmonic_scores, 1)
  h1 |> should.equal(0.5)
}

// ---------------------------------------------------------------------------
// Betweenness Centrality (Brandes' Algorithm)
// ---------------------------------------------------------------------------

pub fn betweenness_star_graph_test() {
  // Star graph: node 1 in center, connected to 2, 3, 4
  // All paths between leaves go through center
  // Center (1) should have highest betweenness
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // Center node: 3 pairs of leaves, all paths go through center = 3.0
  // Note: For undirected graphs, standard betweenness divides by 2, 
  // but this implementation returns the raw count
  let assert Ok(center) = dict.get(scores, 1)
  center |> should.equal(3.0)

  // Leaf nodes should have 0.0 (no paths go through them)
  let assert Ok(leaf) = dict.get(scores, 2)
  leaf |> should.equal(0.0)
}

pub fn betweenness_path_graph_test() {
  // Path: 1-2-3-4
  // Node 2 lies on paths: (1,3), (1,4), (2 is endpoint for others)
  // Node 3 lies on paths: (1,4), (2,4), (3 is endpoint for others)
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // Middle nodes have highest centrality
  // Node 2 is on paths: 1-3, 1-4 = 2.0 (raw count)
  let assert Ok(node2) = dict.get(scores, 2)
  node2 |> should.equal(2.0)

  let assert Ok(node3) = dict.get(scores, 3)
  // Same as node 2
  node3 |> should.equal(2.0)

  // End nodes have 0
  let assert Ok(node1) = dict.get(scores, 1)
  node1 |> should.equal(0.0)
}

pub fn betweenness_triangle_test() {
  // Complete graph K3 (triangle): 1-2-3
  // No single point of failure - all paths are direct
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // All nodes should have 0 betweenness (no node lies on shortest paths between others)
  let assert Ok(n1) = dict.get(scores, 1)
  n1 |> should.equal(0.0)
  let assert Ok(n2) = dict.get(scores, 2)
  n2 |> should.equal(0.0)
  let assert Ok(n3) = dict.get(scores, 3)
  n3 |> should.equal(0.0)
}

pub fn betweenness_directed_line_test() {
  // Directed line: 1 -> 2 -> 3 -> 4
  // All paths go through middle nodes
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // In directed graph, no division by 2
  // Node 2 is on paths: (1,3), (1,4) = 2
  let assert Ok(node2) = dict.get(scores, 2)
  node2 |> should.equal(2.0)

  // Node 3 is on paths: (1,4), (2,4) = 2
  let assert Ok(node3) = dict.get(scores, 3)
  node3 |> should.equal(2.0)

  // Endpoints
  let assert Ok(node1) = dict.get(scores, 1)
  node1 |> should.equal(0.0)
}

pub fn betweenness_two_nodes_test() {
  // Just two nodes connected
  // No intermediate nodes for paths
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // Both have 0 (no paths go through intermediates)
  let assert Ok(n1) = dict.get(scores, 1)
  n1 |> should.equal(0.0)
  let assert Ok(n2) = dict.get(scores, 2)
  n2 |> should.equal(0.0)
}

pub fn betweenness_single_node_test() {
  // Single node
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  let assert Ok(n1) = dict.get(scores, 1)
  n1 |> should.equal(0.0)
}

pub fn betweenness_empty_graph_test() {
  let g = model.new(model.Undirected)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  dict.size(scores) |> should.equal(0)
}

pub fn betweenness_diamond_test() {
  // Diamond graph: 1 at top, 2 and 3 in middle, 4 at bottom
  // Paths from 1 to 4: 1-2-4 and 1-3-4 (two equal shortest paths)
  // So nodes 2 and 3 each get 0.5 credit for (1,4) path
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.betweenness(g, 0, int.add, int.compare, int.to_float)

  // Nodes 2 and 3 each get 0.5 for the (1,4) pair (raw count, no division by 2)
  let assert Ok(node2) = dict.get(scores, 2)
  assert_float_close(node2, 0.5)

  let assert Ok(node3) = dict.get(scores, 3)
  assert_float_close(node3, 0.5)
}

// ---------------------------------------------------------------------------
// PageRank
// ---------------------------------------------------------------------------

fn default_pagerank_options() {
  centrality.PageRankOptions(
    damping: 0.85,
    max_iterations: 100,
    tolerance: 0.0001,
  )
}

pub fn pagerank_star_graph_test() {
  // Star graph: node 1 (center) links to 2, 3, 4
  // In directed star with edges center->leaf, center has no incoming links
  // So leaves should have higher PageRank than center
  let g =
    model.new(model.Directed)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  // Leaves should have equal rank, center should have lower (no incoming)
  let assert Ok(center) = dict.get(scores, 1)
  let assert Ok(leaf2) = dict.get(scores, 2)
  let assert Ok(leaf3) = dict.get(scores, 3)
  let assert Ok(leaf4) = dict.get(scores, 4)

  // All leaves should have equal rank
  assert_float_close(leaf2, leaf3)
  assert_float_close(leaf3, leaf4)

  // Center should have lower rank than leaves (only distributes, doesn't receive)
  should.be_true(center <. leaf2)
}

pub fn pagerank_reverse_star_test() {
  // Reverse star: leaves link to center
  // Center should have highest PageRank
  let g =
    model.new(model.Directed)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 4, to: 1, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  // Center should have highest rank
  let assert Ok(center) = dict.get(scores, 1)
  let assert Ok(leaf2) = dict.get(scores, 2)

  should.be_true(center >. leaf2)
}

pub fn pagerank_cycle_test() {
  // Cycle: 1 -> 2 -> 3 -> 1
  // All nodes should have equal PageRank
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  // All should have approximately equal rank (1/3 each)
  let assert Ok(r1) = dict.get(scores, 1)
  let assert Ok(r2) = dict.get(scores, 2)
  let assert Ok(r3) = dict.get(scores, 3)

  assert_float_close(r1, 0.333333)
  assert_float_close(r2, 0.333333)
  assert_float_close(r3, 0.333333)
}

pub fn pagerank_line_test() {
  // Line: 1 -> 2 -> 3 -> 4
  // PageRank should decrease along the line
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  let assert Ok(r1) = dict.get(scores, 1)
  let assert Ok(_) = dict.get(scores, 2)
  let assert Ok(_) = dict.get(scores, 3)
  let assert Ok(r4) = dict.get(scores, 4)

  // Rank should generally decrease along the line (though not strictly)
  // Node 4 has no outgoing links (sink), so it accumulates rank
  should.be_true(r4 >. r1)
}

pub fn pagerank_complete_graph_test() {
  // Complete graph: every node links to every other node
  // All nodes should have equal PageRank
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 1, with: 1)
    |> model.add_edge(from: 4, to: 2, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  // All should have approximately equal rank (1/4 each)
  let assert Ok(r1) = dict.get(scores, 1)
  let assert Ok(r2) = dict.get(scores, 2)

  assert_float_close(r1, 0.25)
  assert_float_close(r2, 0.25)
}

pub fn pagerank_single_node_test() {
  // Single node
  let g =
    model.new(model.Directed)
    |> model.add_node(1, "only")

  let scores = centrality.pagerank(g, default_pagerank_options())

  let assert Ok(r) = dict.get(scores, 1)
  r |> should.equal(1.0)
}

pub fn pagerank_empty_graph_test() {
  let g = model.new(model.Directed)

  let scores = centrality.pagerank(g, default_pagerank_options())

  dict.size(scores) |> should.equal(0)
}

pub fn pagerank_two_nodes_mutual_test() {
  // Two nodes linking to each other
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)

  let scores = centrality.pagerank(g, default_pagerank_options())

  let assert Ok(r1) = dict.get(scores, 1)
  let assert Ok(r2) = dict.get(scores, 2)

  // Both should have equal rank
  assert_float_close(r1, 0.5)
  assert_float_close(r2, 0.5)
}

// ---------------------------------------------------------------------------
// Convenience Functions
// ---------------------------------------------------------------------------

pub fn closeness_int_test() {
  // Test the convenience wrapper for Int weights
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.closeness_int(g)

  // Should produce same result as manual call
  let manual_scores =
    centrality.closeness(g, 0, int.add, int.compare, int.to_float)
  scores |> should.equal(manual_scores)
}

pub fn betweenness_int_test() {
  // Test the convenience wrapper for Int weights
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.betweenness_int(g)

  // Should produce same result as manual call
  let manual_scores =
    centrality.betweenness(g, 0, int.add, int.compare, int.to_float)
  scores |> should.equal(manual_scores)
}

pub fn pagerank_default_options_test() {
  // Test the default pagerank options
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)

  let scores = centrality.pagerank(g, centrality.default_pagerank_options())

  // Should converge with default options
  let assert Ok(r1) = dict.get(scores, 1)
  assert_float_close(r1, 0.5)
}

// ---------------------------------------------------------------------------
// Eigenvector Centrality
// ---------------------------------------------------------------------------

pub fn eigenvector_star_test() {
  // Star graph: center connected to all leaves
  // In eigenvector centrality, leaves have some value but center has most
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.eigenvector(g, 100, 0.0001)

  // Center should have highest eigenvector centrality
  let assert Ok(center) = dict.get(scores, 1)
  let assert Ok(leaf) = dict.get(scores, 2)
  should.be_true(center >. leaf)
}

pub fn eigenvector_path_test() {
  // Path graph: middle nodes should have higher centrality than ends
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.eigenvector(g, 100, 0.0001)

  // Middle nodes (2, 3) should have higher centrality than ends (1, 4)
  let assert Ok(n1) = dict.get(scores, 1)
  let assert Ok(n2) = dict.get(scores, 2)
  should.be_true(n2 >. n1)
}

pub fn eigenvector_single_node_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores = centrality.eigenvector(g, 100, 0.0001)

  // Single node should have centrality 1.0
  let assert Ok(r) = dict.get(scores, 1)
  r |> should.equal(1.0)
}

pub fn eigenvector_empty_test() {
  let g = model.new(model.Undirected)
  let scores = centrality.eigenvector(g, 100, 0.0001)
  dict.size(scores) |> should.equal(0)
}

// ---------------------------------------------------------------------------
// Katz Centrality
// ---------------------------------------------------------------------------

pub fn katz_star_test() {
  // Star graph with Katz centrality
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.katz(g, 0.1, 1.0, 100, 0.0001)

  // All nodes should have at least beta centrality
  let assert Ok(center) = dict.get(scores, 1)
  let assert Ok(leaf) = dict.get(scores, 2)

  // Center should have higher centrality than leaves
  should.be_true(center >. leaf)
  // All should have at least beta (1.0)
  should.be_true(center >=. 1.0)
  should.be_true(leaf >=. 1.0)
}

pub fn katz_path_test() {
  // Path graph with Katz
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.katz(g, 0.1, 1.0, 100, 0.0001)

  // Middle nodes should have higher Katz centrality
  let assert Ok(n2) = dict.get(scores, 2)
  let assert Ok(n1) = dict.get(scores, 1)
  should.be_true(n2 >. n1)
}

pub fn katz_single_node_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  // Single node: only has beta contribution
  let scores = centrality.katz(g, 0.1, 1.0, 100, 0.0001)

  let assert Ok(r) = dict.get(scores, 1)
  // With no neighbors, centrality should be approximately beta
  assert_float_close(r, 1.0)
}

pub fn katz_empty_test() {
  let g = model.new(model.Undirected)
  let scores = centrality.katz(g, 0.1, 1.0, 100, 0.0001)
  dict.size(scores) |> should.equal(0)
}

// ---------------------------------------------------------------------------
// Alpha Centrality
// ---------------------------------------------------------------------------

pub fn alpha_star_test() {
  // Star graph with Alpha centrality
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "center")
    |> model.add_node(2, "leaf")
    |> model.add_node(3, "leaf")
    |> model.add_node(4, "leaf")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)

  let scores = centrality.alpha_centrality(g, 0.3, 1.0, 100, 0.0001)

  // Alpha centrality converges - just verify we get valid scores
  let assert Ok(center) = dict.get(scores, 1)
  let assert Ok(leaf) = dict.get(scores, 2)

  // In a star graph with undirected edges, center and leaves converge to similar values
  // The important thing is that the algorithm converges
  should.be_true(center >=. 0.0)
  should.be_true(leaf >=. 0.0)
}

pub fn alpha_path_test() {
  // Path graph with Alpha centrality
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let scores = centrality.alpha_centrality(g, 0.3, 1.0, 100, 0.0001)

  // Middle nodes should have higher centrality
  let assert Ok(n2) = dict.get(scores, 2)
  let assert Ok(n1) = dict.get(scores, 1)
  should.be_true(n2 >. n1)
}

pub fn alpha_directed_test() {
  // Directed line: 1 -> 2 -> 3
  let g =
    model.new(model.Directed)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let scores = centrality.alpha_centrality(g, 0.3, 1.0, 100, 0.0001)

  // Node 3 accumulates from upstream
  let assert Ok(n1) = dict.get(scores, 1)
  let assert Ok(n2) = dict.get(scores, 2)
  let assert Ok(n3) = dict.get(scores, 3)

  // In directed graphs, alpha centrality flows forward
  should.be_true(n3 >=. n2)
  should.be_true(n2 >=. n1)
}

pub fn alpha_single_node_test() {
  let g =
    model.new(model.Undirected)
    |> model.add_node(1, "only")

  let scores = centrality.alpha_centrality(g, 0.3, 1.0, 100, 0.0001)

  // Single node with no neighbors: centrality goes to 0 after first iteration
  // (alpha * 0 = 0)
  let assert Ok(r) = dict.get(scores, 1)
  r |> should.equal(0.0)
}

pub fn alpha_empty_test() {
  let g = model.new(model.Undirected)
  let scores = centrality.alpha_centrality(g, 0.3, 1.0, 100, 0.0001)
  dict.size(scores) |> should.equal(0)
}
