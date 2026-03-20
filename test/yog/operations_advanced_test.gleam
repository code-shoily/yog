import gleam/int
import gleam/list
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/operation

// ============= Compose Tests =============

pub fn compose_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.compose(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn compose_overlapping_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "X")
    // Same ID, different data
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 3, with: 20, default: "")

  let result = operation.compose(g1, g2)

  // Should have nodes 1, 2, 3
  model.order(result)
  |> should.equal(3)

  // Should have both edges
  model.edge_count(result)
  |> should.equal(2)

  // Node 1 should have data from g2 ("X")
  let node1_data = model.all_nodes(result) |> list.contains(1)
  node1_data
  |> should.be_true()
}

pub fn compose_disjoint_graphs_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 3, to: 4, with: 20, default: "")

  let result = operation.compose(g1, g2)

  // Same as union for disjoint graphs
  model.order(result)
  |> should.equal(4)

  model.edge_count(result)
  |> should.equal(2)
}

// ============= Power Tests =============

pub fn power_k0_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")

  // k=0 should return original graph
  let result = operation.power(graph, 0, 1)

  model.order(result)
  |> should.equal(2)

  model.edge_count(result)
  |> should.equal(1)
}

pub fn power_k1_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")

  // k=1 should return original graph
  let result = operation.power(graph, 1, 1)

  model.order(result)
  |> should.equal(3)

  model.edge_count(result)
  |> should.equal(2)
}

pub fn power_path_k2_test() {
  // Path: 1 - 2 - 3 - 4
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")

  // Debug: Check initial edge count
  model.edge_count(graph)
  |> should.equal(3)

  let result = operation.power(graph, 2, 1)

  // Original edges + distance-2 edges: 1-3, 2-4
  model.order(result)
  |> should.equal(4)

  // 3 original edges + 2 new edges = 5 edges (undirected counted once)
  model.edge_count(result)
  |> should.equal(5)
}

pub fn power_triangle_k2_test() {
  // Triangle: 1 - 2 - 3 - 1
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")

  let result = operation.power(graph, 2, 1)

  // Already complete, should stay the same
  model.order(result)
  |> should.equal(3)

  model.edge_count(result)
  |> should.equal(3)
}

pub fn power_directed_test() {
  // Directed path: 1 -> 2 -> 3
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")

  let result = operation.power(graph, 2, 1)

  // Should add edge 1 -> 3 (reachable in 2 hops)
  model.order(result)
  |> should.equal(3)

  // 2 original + 1 new = 3 edges
  model.edge_count(result)
  |> should.equal(3)
}

pub fn power_star_test() {
  // Star: center 1 connected to 2, 3, 4
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 4, with: 1, default: "")

  let result = operation.power(graph, 2, 1)

  // k=2 should make it complete (all leaves connected to each other via center)
  model.order(result)
  |> should.equal(4)

  // Star has 3 edges, complete graph K4 has 6 edges
  model.edge_count(result)
  |> should.equal(6)
}

// ============= Is Isomorphic Tests =============

pub fn isomorphic_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn isomorphic_single_node_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")

  let g2 =
    model.new(Directed)
    |> model.add_node(99, "Z")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn isomorphic_two_nodes_no_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(10, "X")
    |> model.add_node(20, "Y")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn isomorphic_two_nodes_with_edge_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(10, "X")
    |> model.add_node(20, "Y")
    |> model.add_edge_ensure(from: 10, to: 20, with: 5, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn not_isomorphic_different_order_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")

  operation.is_isomorphic(g1, g2)
  |> should.be_false()
}

pub fn not_isomorphic_different_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_false()
}

pub fn isomorphic_triangles_test() {
  // Two triangles with different node IDs
  let g1 =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")

  let g2 =
    model.new(Undirected)
    |> model.add_node(10, "X")
    |> model.add_node(20, "Y")
    |> model.add_node(30, "Z")
    |> model.add_edge_ensure(from: 10, to: 20, with: 5, default: "")
    |> model.add_edge_ensure(from: 20, to: 30, with: 5, default: "")
    |> model.add_edge_ensure(from: 30, to: 10, with: 5, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn isomorphic_squares_test() {
  // Two squares (cycles of 4)
  let g1 =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")
    |> model.add_edge_ensure(from: 4, to: 1, with: 1, default: "")

  let g2 =
    model.new(Undirected)
    |> model.add_node(10, "W")
    |> model.add_node(20, "X")
    |> model.add_node(30, "Y")
    |> model.add_node(40, "Z")
    |> model.add_edge_ensure(from: 10, to: 20, with: 1, default: "")
    |> model.add_edge_ensure(from: 20, to: 30, with: 1, default: "")
    |> model.add_edge_ensure(from: 30, to: 40, with: 1, default: "")
    |> model.add_edge_ensure(from: 40, to: 10, with: 1, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn not_isomorphic_triangle_vs_square_test() {
  let triangle =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")

  let square =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")
    |> model.add_edge_ensure(from: 4, to: 1, with: 1, default: "")

  operation.is_isomorphic(triangle, square)
  |> should.be_false()
}

pub fn not_isomorphic_different_degree_sequences_test() {
  // Star vs Path with 4 nodes
  let star =
    model.new(Undirected)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 4, with: 1, default: "")

  let path =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")

  operation.is_isomorphic(star, path)
  |> should.be_false()
}

pub fn isomorphic_pentagons_test() {
  // Two 5-cycles
  let g1 =
    model.new(Undirected)
    |> model.add_node(0, "A")
    |> model.add_node(1, "B")
    |> model.add_node(2, "C")
    |> model.add_node(3, "D")
    |> model.add_node(4, "E")
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")
    |> model.add_edge_ensure(from: 4, to: 0, with: 1, default: "")

  let g2 =
    model.new(Undirected)
    |> model.add_node(10, "V")
    |> model.add_node(20, "W")
    |> model.add_node(30, "X")
    |> model.add_node(40, "Y")
    |> model.add_node(50, "Z")
    |> model.add_edge_ensure(from: 10, to: 20, with: 1, default: "")
    |> model.add_edge_ensure(from: 20, to: 30, with: 1, default: "")
    |> model.add_edge_ensure(from: 30, to: 40, with: 1, default: "")
    |> model.add_edge_ensure(from: 40, to: 50, with: 1, default: "")
    |> model.add_edge_ensure(from: 50, to: 10, with: 1, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn isomorphic_directed_cycles_test() {
  // Two directed 3-cycles
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(10, "X")
    |> model.add_node(20, "Y")
    |> model.add_node(30, "Z")
    |> model.add_edge_ensure(from: 10, to: 20, with: 1, default: "")
    |> model.add_edge_ensure(from: 20, to: 30, with: 1, default: "")
    |> model.add_edge_ensure(from: 30, to: 10, with: 1, default: "")

  operation.is_isomorphic(g1, g2)
  |> should.be_true()
}

pub fn not_isomorphic_different_directed_structure_test() {
  // Cycle vs path with same number of nodes/edges
  let cycle =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")

  let path =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")

  operation.is_isomorphic(cycle, path)
  |> should.be_false()
}
