import gleeunit/should
import gleam/int
import gleam/list
import yog/model.{Undirected}
import yog/mst

// ============= Basic MST Tests =============

// Simple triangle graph
//   1
//  /|\
// 2-+-3
pub fn mst_simple_triangle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 1, to: 3, with: 3)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // MST should have 2 edges (n-1 for n nodes)
  list.length(result)
  |> should.equal(2)

  // Total weight should be 1+2=3 (edges 1-2 and 2-3)
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(3)

  // Should include edges 1-2 and 2-3
  list.any(result, fn(e) { e.from == 1 && e.to == 2 && e.weight == 1 })
  |> should.be_true()

  list.any(result, fn(e) { e.from == 2 && e.to == 3 && e.weight == 2 })
  |> should.be_true()
}

// Linear chain
pub fn mst_linear_chain_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 2 edges
  list.length(result)
  |> should.equal(2)

  // Total weight should be 15
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(15)
}

// Single edge
pub fn mst_single_edge_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  list.length(result)
  |> should.equal(1)

  case result {
    [edge] -> {
      edge.from
      |> should.equal(1)

      edge.to
      |> should.equal(2)

      edge.weight
      |> should.equal(10)
    }
    _ -> should.fail()
  }
}

// Single node (no edges)
pub fn mst_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  list.length(result)
  |> should.equal(0)
}

// Empty graph
pub fn mst_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  list.length(result)
  |> should.equal(0)
}

// ============= Classic MST Test Cases =============

// Square with diagonal
//   1---2
//   |\ /|
//   | X |
//   |/ \|
//   3---4
pub fn mst_square_with_diagonal_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 5)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 3 edges (4 nodes)
  list.length(result)
  |> should.equal(3)

  // Total weight should be 3 (three edges of weight 1)
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(3)
}

// Classic example where greedy fails but Kruskal works
pub fn mst_classic_kruskal_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 4, with: 3)
    |> model.add_edge(from: 1, to: 4, with: 4)
    |> model.add_edge(from: 2, to: 4, with: 5)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  list.length(result)
  |> should.equal(3)

  // Should select edges 1-2 (1), 2-3 (2), 3-4 (3) for total weight 6
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(6)
}

// Pentagon graph
pub fn mst_pentagon_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    // Pentagon edges
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 4, with: 3)
    |> model.add_edge(from: 4, to: 5, with: 4)
    |> model.add_edge(from: 5, to: 1, with: 5)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 4 edges (5 nodes)
  list.length(result)
  |> should.equal(4)

  // Should select edges 1,2,3,4 (not 5) for total weight 10
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(10)
}

// ============= Disconnected Graph Tests =============

pub fn mst_disconnected_two_components_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // Component 1: 1-2
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Component 2: 3-4
    |> model.add_edge(from: 3, to: 4, with: 2)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 2 edges (one per component)
  list.length(result)
  |> should.equal(2)

  // Should be a forest, not a tree
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(3)
}

pub fn mst_disconnected_three_components_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    // Component 1: 1-2
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Component 2: 3-4
    |> model.add_edge(from: 3, to: 4, with: 2)
    // Component 3: 5-6
    |> model.add_edge(from: 5, to: 6, with: 3)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 3 edges (one per component)
  list.length(result)
  |> should.equal(3)
}

// Isolated nodes
pub fn mst_with_isolated_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Nodes 3 and 4 are isolated

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should only have 1 edge
  list.length(result)
  |> should.equal(1)
}

// ============= Weight Variation Tests =============

pub fn mst_all_same_weights_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 5)
    |> model.add_edge(from: 1, to: 4, with: 5)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 3 edges
  list.length(result)
  |> should.equal(3)

  // All edges have weight 5, so total is 15
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(15)
}

pub fn mst_zero_weight_edges_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 0)
    |> model.add_edge(from: 2, to: 3, with: 0)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  list.length(result)
  |> should.equal(2)

  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(0)
}

// ============= Complete Graph Tests =============

pub fn mst_complete_graph_k4_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // All possible edges with increasing weights
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 1, to: 4, with: 3)
    |> model.add_edge(from: 2, to: 3, with: 4)
    |> model.add_edge(from: 2, to: 4, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 6)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // MST of K4 has 3 edges
  list.length(result)
  |> should.equal(3)

  // Should select edges with weights 1, 2, 3
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(6)
}

pub fn mst_complete_graph_k5_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    // K5 has 10 edges
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 1, to: 4, with: 3)
    |> model.add_edge(from: 1, to: 5, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 5)
    |> model.add_edge(from: 2, to: 4, with: 6)
    |> model.add_edge(from: 2, to: 5, with: 7)
    |> model.add_edge(from: 3, to: 4, with: 8)
    |> model.add_edge(from: 3, to: 5, with: 9)
    |> model.add_edge(from: 4, to: 5, with: 10)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // MST of K5 has 4 edges
  list.length(result)
  |> should.equal(4)

  // Should select edges with weights 1, 2, 3, 4
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(10)
}

// ============= Cycle Detection Tests =============

pub fn mst_avoids_cycle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 100)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have 2 edges (avoiding the cycle)
  list.length(result)
  |> should.equal(2)

  // Should not include the heavy edge
  list.any(result, fn(e) { e.weight == 100 })
  |> should.be_false()
}

// ============= Large Graph Tests =============

pub fn mst_larger_graph_test() {
  // Create a graph with 10 nodes and various edges
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    |> model.add_node(9, "9")
    |> model.add_node(10, "10")
    // Add edges to form a spanning tree with some extras
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 4, with: 3)
    |> model.add_edge(from: 4, to: 5, with: 4)
    |> model.add_edge(from: 5, to: 6, with: 5)
    |> model.add_edge(from: 6, to: 7, with: 6)
    |> model.add_edge(from: 7, to: 8, with: 7)
    |> model.add_edge(from: 8, to: 9, with: 8)
    |> model.add_edge(from: 9, to: 10, with: 9)
    // Add some cycle-creating edges with higher weights
    |> model.add_edge(from: 1, to: 10, with: 100)
    |> model.add_edge(from: 5, to: 10, with: 50)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Should have exactly 9 edges (n-1 for n=10)
  list.length(result)
  |> should.equal(9)

  // Should have total weight 1+2+3+4+5+6+7+8+9 = 45
  let total_weight =
    list.fold(result, 0, fn(acc, edge) { acc + edge.weight })

  total_weight
  |> should.equal(45)
}

// ============= Edge Case: Self Loops =============

pub fn mst_with_self_loop_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 2)

  let result = mst.kruskal(in: graph, with_compare: int.compare)

  // Self-loops should be ignored (they create cycles)
  // Should only have 1 edge connecting 1 and 2
  list.length(result)
  |> should.equal(1)

  case result {
    [edge] -> {
      edge.from
      |> should.equal(1)

      edge.to
      |> should.equal(2)
    }
    _ -> should.fail()
  }
}
