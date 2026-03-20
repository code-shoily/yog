import gleam/int
import gleam/list
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/operation

// ============= Union Tests =============

pub fn union_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.union(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn union_with_empty_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 = model.new(Directed)

  let result = operation.union(g1, g2)

  model.order(result)
  |> should.equal(2)
}

pub fn union_disjoint_graphs_test() {
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

  let result = operation.union(g1, g2)

  // Should have all 4 nodes
  model.order(result)
  |> should.equal(4)

  // Should have all edges
  model.edge_count(result)
  |> should.equal(2)
}

pub fn union_overlapping_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "X")
    // Same ID, different data
    |> model.add_node(3, "C")

  let result = operation.union(g1, g2)

  // Should have 3 unique nodes
  model.order(result)
  |> should.equal(3)
}

// ============= Intersection Tests =============

pub fn intersection_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.intersection(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn intersection_no_common_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")

  let result = operation.intersection(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn intersection_common_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let g2 =
    model.new(Directed)
    |> model.add_node(2, "X")
    |> model.add_node(3, "Y")
    |> model.add_node(4, "D")

  let result = operation.intersection(g1, g2)

  // Should have nodes 2 and 3
  model.order(result)
  |> should.equal(2)
}

pub fn intersection_common_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 20, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 2, to: 3, with: 30, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 40, default: "")

  let result = operation.intersection(g1, g2)

  // Should have all 3 nodes (common to both)
  model.order(result)
  |> should.equal(3)

  // Should have only the common edge 2->3
  model.edge_count(result)
  |> should.equal(1)
}

// ============= Difference Tests =============

pub fn difference_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.difference(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn difference_no_common_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")

  let result = operation.difference(g1, g2)

  // Should keep all nodes from g1 (no overlap)
  model.order(result)
  |> should.equal(2)
}

pub fn difference_removes_common_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let g2 =
    model.new(Directed)
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let result = operation.difference(g1, g2)

  // Should only have node 1 (others removed as they exist in g2)
  model.order(result)
  |> should.equal(1)
}

pub fn difference_removes_common_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 20, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let result = operation.difference(g1, g2)

  // Edge 1->2 is removed (exists in g2), edge 2->3 remains
  // Nodes 2 and 3 remain (connected by edge 2->3)
  // Node 1 is removed (no remaining edges)
  model.order(result)
  |> should.equal(2)

  // Should only have edge 2->3 (1->2 removed as it exists in g2)
  model.edge_count(result)
  |> should.equal(1)
}

// ============= Symmetric Difference Tests =============

pub fn symmetric_difference_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.symmetric_difference(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn symmetric_difference_disjoint_graphs_test() {
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

  let result = operation.symmetric_difference(g1, g2)

  // Should have all 4 nodes and 2 edges (no overlap)
  model.order(result)
  |> should.equal(4)

  model.edge_count(result)
  |> should.equal(2)
}

pub fn symmetric_difference_common_edge_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 20, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 30, default: "")

  let result = operation.symmetric_difference(g1, g2)

  // Should have all nodes
  model.order(result)
  |> should.equal(3)

  // Should have edges 2->3 and 3->1 (1->2 excluded as it's common)
  model.edge_count(result)
  |> should.equal(2)
}

// ============= Disjoint Union Tests =============

pub fn disjoint_union_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result = operation.disjoint_union(g1, g2)

  model.order(result)
  |> should.equal(0)
}

pub fn disjoint_union_basic_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(0, "A")
    |> model.add_node(1, "B")
    |> model.add_edge_ensure(from: 0, to: 1, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(0, "C")
    // Same ID as in g1
    |> model.add_node(1, "D")
    // Same ID as in g1
    |> model.add_edge_ensure(from: 0, to: 1, with: 20, default: "")

  let result = operation.disjoint_union(g1, g2)

  // Should have 4 nodes (g1: 0,1 + g2: 2,3 after re-indexing)
  model.order(result)
  |> should.equal(4)

  // Should have 2 edges
  model.edge_count(result)
  |> should.equal(2)
}

pub fn disjoint_union_preserves_structure_test() {
  // Two triangles that should remain separate
  let g1 =
    model.new(Directed)
    |> model.add_node(0, "A1")
    |> model.add_node(1, "A2")
    |> model.add_node(2, "A3")
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 0, with: 1, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(0, "B1")
    |> model.add_node(1, "B2")
    |> model.add_node(2, "B3")
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: "")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 0, with: 1, default: "")

  let result = operation.disjoint_union(g1, g2)

  // Should have 6 nodes
  model.order(result)
  |> should.equal(6)

  // Should have 6 edges (2 triangles)
  model.edge_count(result)
  |> should.equal(6)

  // Nodes from g2 should be re-indexed to 3, 4, 5
  let nodes = model.all_nodes(result) |> list.sort(int.compare)
  nodes
  |> should.equal([0, 1, 2, 3, 4, 5])
}

pub fn disjoint_union_second_empty_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let g2 = model.new(Directed)

  let result = operation.disjoint_union(g1, g2)

  // Should just be g1
  model.order(result)
  |> should.equal(2)
}

// ============= Cartesian Product Tests =============

pub fn cartesian_product_empty_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let result =
    operation.cartesian_product(g1, g2, with_first: 0, with_second: 0)

  model.order(result)
  |> should.equal(0)
}

pub fn cartesian_product_with_empty_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(0, "A")
    |> model.add_node(1, "B")

  let g2 = model.new(Directed)

  let result =
    operation.cartesian_product(g1, g2, with_first: 0, with_second: 0)

  // Product with empty is empty
  model.order(result)
  |> should.equal(0)
}

pub fn cartesian_product_single_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(0, "A")

  let g2 =
    model.new(Directed)
    |> model.add_node(0, "X")

  let result =
    operation.cartesian_product(g1, g2, with_first: 0, with_second: 0)

  // Single node pair
  model.order(result)
  |> should.equal(1)
}

pub fn cartesian_product_path_2x2_test() {
  // Create two paths of 2 nodes each
  // Result should be a 2x2 grid with 4 nodes
  let g1 =
    model.new(Undirected)
    |> model.add_node(0, "A")
    |> model.add_node(1, "B")
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: "")

  let g2 =
    model.new(Undirected)
    |> model.add_node(0, "X")
    |> model.add_node(1, "Y")
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: "")

  let result =
    operation.cartesian_product(g1, g2, with_first: 0, with_second: 0)

  // Should have 4 nodes: (0,0), (0,1), (1,0), (1,1)
  model.order(result)
  |> should.equal(4)

  // Should have 4 edges (grid structure)
  model.edge_count(result)
  |> should.equal(4)
}

// ============= Is Subgraph Tests =============

pub fn is_subgraph_empty_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  operation.is_subgraph(g1, g2)
  |> should.be_true()
}

pub fn is_subgraph_empty_is_subgraph_test() {
  let g1 = model.new(Directed)

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  // Empty graph is a subgraph of any graph
  operation.is_subgraph(g1, g2)
  |> should.be_true()
}

pub fn is_subgraph_identical_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  operation.is_subgraph(g1, g2)
  |> should.be_true()
}

pub fn is_subgraph_true_test() {
  let subgraph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 20, default: "")

  operation.is_subgraph(subgraph, graph)
  |> should.be_true()
}

pub fn is_subgraph_missing_node_test() {
  let subgraph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(4, "D")
  // Not in graph

  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  operation.is_subgraph(subgraph, graph)
  |> should.be_false()
}

pub fn is_subgraph_missing_edge_test() {
  let subgraph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
  // No edge between 1 and 2

  operation.is_subgraph(subgraph, graph)
  |> should.be_false()
}

pub fn is_subgraph_not_subgraph_when_larger_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  // g1 is not a subgraph of g2 (g1 has more nodes)
  operation.is_subgraph(g1, g2)
  |> should.be_false()
}

// ============= Complex Operation Tests =============

pub fn union_then_intersection_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  let g2 =
    model.new(Directed)
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge_ensure(from: 2, to: 3, with: 20, default: "")

  let union_result = operation.union(g1, g2)
  model.order(union_result)
  |> should.equal(3)

  let intersection_result = operation.intersection(g1, g2)
  model.order(intersection_result)
  |> should.equal(1)
  // Only node 2
}

pub fn difference_self_is_empty_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "")

  // G - G should be empty (all nodes and edges removed)
  let result = operation.difference(g1, g1)

  model.order(result)
  |> should.equal(0)
}
