import gleam/list
import gleeunit/should
import yog
import yog/connectivity

// ============= Basic Connectivity Tests =============

pub fn connectivity_empty_graph_test() {
  let graph = yog.undirected()

  let result = connectivity.analyze(in: graph)

  result.bridges
  |> should.equal([])

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_single_node_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")

  let result = connectivity.analyze(in: graph)

  result.bridges
  |> should.equal([])

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_two_nodes_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Single edge is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  // Neither node is an articulation point (only 2 nodes)
  result.articulation_points
  |> should.equal([])
}

// ============= Bridge Detection Tests =============

pub fn connectivity_linear_chain_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges in a linear chain
  result.bridges
  |> list.length()
  |> should.equal(3)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(2, 3))
  |> should.be_true()

  result.bridges
  |> list.contains(#(3, 4))
  |> should.be_true()

  // Middle nodes are articulation points
  result.articulation_points
  |> list.length()
  |> should.equal(2)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()

  result.articulation_points
  |> list.contains(3)
  |> should.be_true()
}

pub fn connectivity_triangle_no_bridges_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges in a cycle (triangle)
  result.bridges
  |> should.equal([])

  // No articulation points in a triangle
  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_bridge_between_triangles_test() {
  // Two triangles connected by a single edge (bridge)
  //   1 - 2      4 - 5
  //    \ /        \ /
  //     3 ------- 6
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_node(5, "E")
    |> yog.add_node(6, "F")
    // First triangle
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)
    // Second triangle
    |> yog.add_edge(from: 4, to: 5, with: 1)
    |> yog.add_edge(from: 5, to: 6, with: 1)
    |> yog.add_edge(from: 6, to: 4, with: 1)
    // Bridge connecting the triangles
    |> yog.add_edge(from: 3, to: 6, with: 1)

  let result = connectivity.analyze(in: graph)

  // Only the connecting edge is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(3, 6))
  |> should.be_true()

  // The endpoints of the bridge are articulation points
  result.articulation_points
  |> list.length()
  |> should.equal(2)

  result.articulation_points
  |> list.contains(3)
  |> should.be_true()

  result.articulation_points
  |> list.contains(6)
  |> should.be_true()
}

// ============= Articulation Point Detection Tests =============

pub fn connectivity_star_graph_test() {
  // Star graph: center node connected to all others
  //     2
  //     |
  // 3 - 1 - 4
  //     |
  //     5
  let graph =
    yog.undirected()
    |> yog.add_node(1, "Center")
    |> yog.add_node(2, "A")
    |> yog.add_node(3, "B")
    |> yog.add_node(4, "C")
    |> yog.add_node(5, "D")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 1, to: 5, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges in a star
  result.bridges
  |> list.length()
  |> should.equal(4)

  // Only the center is an articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(1)
  |> should.be_true()
}

pub fn connectivity_diamond_test() {
  // Diamond shape: two paths from 1 to 4
  //   1
  //  / \
  // 2   3
  //  \ /
  //   4
  let graph =
    yog.undirected()
    |> yog.add_node(1, "Top")
    |> yog.add_node(2, "Left")
    |> yog.add_node(3, "Right")
    |> yog.add_node(4, "Bottom")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges (multiple paths between all pairs)
  result.bridges
  |> should.equal([])

  // No articulation points in a diamond
  // (removing any node leaves remaining nodes connected)
  result.articulation_points
  |> should.equal([])
}

// ============= Complex Graph Tests =============

pub fn connectivity_complex_graph_test() {
  // Complex graph with multiple bridges and articulation points
  //     1 - 2 - 3
  //         |   |
  //         4 - 5 - 6
  //             |
  //             7 - 8
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_node(5, "E")
    |> yog.add_node(6, "F")
    |> yog.add_node(7, "G")
    |> yog.add_node(8, "H")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 3, to: 5, with: 1)
    |> yog.add_edge(from: 4, to: 5, with: 1)
    |> yog.add_edge(from: 5, to: 6, with: 1)
    |> yog.add_edge(from: 5, to: 7, with: 1)
    |> yog.add_edge(from: 7, to: 8, with: 1)

  let result = connectivity.analyze(in: graph)

  // Bridges: 1-2, 5-6, 5-7, 7-8
  result.bridges
  |> list.length()
  |> should.equal(4)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(5, 6))
  |> should.be_true()

  result.bridges
  |> list.contains(#(5, 7))
  |> should.be_true()

  result.bridges
  |> list.contains(#(7, 8))
  |> should.be_true()

  // Articulation points: 2, 5, 7
  result.articulation_points
  |> list.length()
  |> should.equal(3)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()

  result.articulation_points
  |> list.contains(5)
  |> should.be_true()

  result.articulation_points
  |> list.contains(7)
  |> should.be_true()
}

// ============= Disconnected Graph Tests =============

pub fn connectivity_disconnected_components_test() {
  // Two separate components
  // Component 1: 1 - 2
  // Component 2: 3 - 4 - 5
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_node(5, "E")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 5, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges (within their components)
  result.bridges
  |> list.length()
  |> should.equal(3)

  // Middle node of second component is articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(4)
  |> should.be_true()
}

pub fn connectivity_isolated_nodes_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Only the edge between connected nodes is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  // Isolated node doesn't affect articulation points
  result.articulation_points
  |> should.equal([])
}

// ============= Edge Case Tests =============

pub fn connectivity_self_loop_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_edge(from: 1, to: 1, with: 1)
    |> yog.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Self-loop doesn't affect bridge detection
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_parallel_edges_test() {
  // Multiple edges between the same pair of nodes
  // Note: Standard Tarjan's algorithm with node-based parent tracking
  // doesn't handle parallel edges perfectly - it would need edge IDs.
  // This test documents the actual behavior.
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 2, with: 2)
    // Duplicate edge with different weight
    |> yog.add_edge(from: 2, to: 3, with: 1)

  let result = connectivity.analyze(in: graph)

  // With node-based parent tracking, parallel edges are detected
  // Both edges 1-2 and 2-3 are detected as bridges
  result.bridges
  |> list.length()
  |> should.equal(2)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(2, 3))
  |> should.be_true()

  // Node 2 is an articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()
}

pub fn connectivity_complete_graph_test() {
  // Complete graph K4: every node connected to every other node
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges in a complete graph
  result.bridges
  |> should.equal([])

  // No articulation points in a complete graph
  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_square_with_diagonal_test() {
  // Square with one diagonal
  //   1 - 2
  //   | X |
  //   3 - 4
  let graph =
    yog.undirected()
    |> yog.add_node(1, "A")
    |> yog.add_node(2, "B")
    |> yog.add_node(3, "C")
    |> yog.add_node(4, "D")
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    // Diagonal

  let result = connectivity.analyze(in: graph)

  // No bridges (multiple paths between all pairs)
  result.bridges
  |> should.equal([])

  // No articulation points (removing any node leaves graph connected)
  result.articulation_points
  |> should.equal([])
}

// ============= Bridge Ordering Test =============

pub fn connectivity_bridge_ordering_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(5, "A")
    |> yog.add_node(3, "B")
    |> yog.add_edge(from: 5, to: 3, with: 1)

  let result = connectivity.analyze(in: graph)

  // Bridges should be stored in canonical order (lower ID first)
  result.bridges
  |> should.equal([#(3, 5)])
}
