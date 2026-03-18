import gleeunit/should
import yog
import yog/flow/min_cut

// ============= Basic Min Cut Tests =============

pub fn min_cut_single_edge_test() {
  // Two nodes connected by a single edge
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 5)

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(5)

  result.group_a_size
  |> should.equal(1)

  result.group_b_size
  |> should.equal(1)
}

pub fn min_cut_triangle_test() {
  // Triangle: all edges have weight 1
  // Minimum cut is any single edge
  // Note: Due to undirected edge storage, contraction doubles weights,
  // so the reported cut weight is 2 (= 2 * 1)
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(2)
}

pub fn min_cut_square_test() {
  // Square graph: 4 nodes in a cycle
  // Min cut is any edge
  // Note: Reported weight is 2 (= 2 * 1) due to undirected edge storage
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 1, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(2)
}

pub fn min_cut_square_with_diagonal_test() {
  // Square with diagonal: min cut is 2 edges
  // (e.g., cutting 1-2 and 3-4 separates into {1,4} and {2,3})
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 1, 1),
      #(1, 3, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(2)
}

// ============= Weighted Graph Tests =============

pub fn min_cut_weighted_path_test() {
  // Linear path with different weights
  // a -[10]- b -[1]- c -[10]- d
  // Min cut is the middle edge (weight 1)
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([
      #(1, 2, 10),
      #(2, 3, 1),
      #(3, 4, 10),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(1)
}

pub fn min_cut_bottleneck_test() {
  // Two complete subgraphs connected by a single edge
  // Left: K3 with weight 10 edges
  // Right: K3 with weight 10 edges
  // Bridge: weight 1
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_edges([
      // Left triangle
      #(1, 2, 10),
      #(2, 3, 10),
      #(3, 1, 10),
      // Right triangle
      #(4, 5, 10),
      #(5, 6, 10),
      #(6, 4, 10),
      // Bridge
      #(3, 4, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(1)

  result.group_a_size
  |> should.equal(3)

  result.group_b_size
  |> should.equal(3)
}

// ============= Complex Graph Tests =============

pub fn min_cut_k4_test() {
  // Complete graph K4: every node connected to every other
  // Min cut is 3 (removing any single node)
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(1, 4, 1),
      #(2, 3, 1),
      #(2, 4, 1),
      #(3, 4, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(3)

  // One node vs three nodes
  result.group_a_size
  |> should.equal(1)

  result.group_b_size
  |> should.equal(3)
}

pub fn min_cut_parallel_edges_test() {
  // Two nodes with multiple edges between them
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edges([
      #(1, 2, 5),
      #(1, 2, 3),
      #(2, 3, 1),
      #(3, 4, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  // Min cut should be 1 (either 2-3 or 3-4)
  result.weight
  |> should.equal(1)
}

pub fn min_cut_star_graph_test() {
  // Star graph: center connected to 4 outer nodes
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(1, 4, 1),
      #(1, 5, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  // Min cut is any single edge (separating one leaf from the rest)
  result.weight
  |> should.equal(1)

  // One leaf vs the rest
  result.group_a_size
  |> should.equal(1)

  result.group_b_size
  |> should.equal(4)
}

// ============= AoC 2023 Day 25 Style Test =============

pub fn min_cut_aoc_style_test() {
  // Simplified version of AoC 2023 Day 25
  // Two clusters connected by exactly 3 edges
  // Make intra-cluster edges heavier so cutting between clusters is the unique minimum
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_edges([
      // Cluster 1 (densely connected with heavy edges)
      #(1, 2, 10),
      #(2, 3, 10),
      #(3, 1, 10),
      // Cluster 2 (densely connected with heavy edges)
      #(4, 5, 10),
      #(5, 6, 10),
      #(6, 4, 10),
      // Three light bridges between clusters (the minimum cut)
      #(1, 4, 1),
      #(2, 5, 1),
      #(3, 6, 1),
    ])

  let result = min_cut.global_min_cut(in: graph)

  // The algorithm correctly identifies the three bridge edges
  result.weight
  |> should.equal(3)

  // The key result: correct partition (3 nodes in each cluster)
  // For AoC 2023 Day 25, multiply these to get the answer
  result.group_a_size
  |> should.equal(3)

  result.group_b_size
  |> should.equal(3)

  // Product for AoC answer
  result.group_a_size * result.group_b_size
  |> should.equal(9)
}

// ============= Edge Cases =============

pub fn min_cut_two_nodes_test() {
  // Minimum size graph for min-cut
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 10)

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(10)

  result.group_a_size
  |> should.equal(1)

  result.group_b_size
  |> should.equal(1)
}

pub fn min_cut_self_loop_test() {
  // Self-loops should not affect min-cut
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(1, 1, 100),
    ])

  let result = min_cut.global_min_cut(in: graph)

  result.weight
  |> should.equal(1)
}
