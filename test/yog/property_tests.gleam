////
//// Property-based tests for Yog using qcheck.
////
//// These tests verify mathematical properties and invariants that should hold
//// for all valid inputs, catching edge cases that example-based tests might miss.
////

import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleeunit
import qcheck
import yog/model.{type Graph, type GraphType, type NodeId}
import yog/transform
import yog/traversal

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// GENERATORS
// ============================================================================

/// Generate a random GraphType (Directed or Undirected)
fn graph_type_generator() {
  use is_directed <- qcheck.map(qcheck.bool())
  case is_directed {
    True -> model.Directed
    False -> model.Undirected
  }
}

/// Generate a random graph with Int node data and Int edge weights
/// - Nodes: 0 to max_nodes-1
/// - Edges: Random connections with positive weights
fn graph_generator() {
  use kind <- qcheck.bind(graph_type_generator())
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(kind, num_nodes, num_edges)
}

/// Generate a graph with specific parameters
fn graph_generator_custom(
  kind: GraphType,
  num_nodes: Int,
  num_edges: Int,
) -> qcheck.Generator(Graph(Int, Int)) {
  use edges <- qcheck.map(qcheck.fixed_length_list_from(
    edge_triple_generator(num_nodes),
    num_edges,
  ))

  // Build graph: add nodes first, then edges
  let graph = model.new(kind)

  let graph = case num_nodes {
    0 -> graph
    _ -> {
      list.range(0, num_nodes - 1)
      |> list.fold(graph, fn(g, node_id) { model.add_node(g, node_id, node_id) })
    }
  }

  edges
  |> list.fold(graph, fn(g, edge) {
    let #(src, dst, weight) = edge
    model.add_edge(g, from: src, to: dst, with: weight)
  })
}

/// Generate an undirected graph
fn undirected_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Undirected, num_nodes, num_edges)
}

/// Generate a directed graph
fn directed_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Directed, num_nodes, num_edges)
}

/// Generate an edge triple #(src, dst, weight)
fn edge_triple_generator(max_node_id: Int) {
  case max_node_id {
    0 -> qcheck.return(#(0, 0, 1))
    _ -> {
      use src <- qcheck.bind(qcheck.bounded_int(0, max_node_id - 1))
      use dst <- qcheck.bind(qcheck.bounded_int(0, max_node_id - 1))
      use weight <- qcheck.map(qcheck.bounded_int(1, 100))
      #(src, dst, weight)
    }
  }
}

/// Generate a traversal order (BFS or DFS)
fn traversal_order_generator() {
  use is_bfs <- qcheck.map(qcheck.bool())
  case is_bfs {
    True -> traversal.BreadthFirst
    False -> traversal.DepthFirst
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Check if two graphs are structurally equal
fn graphs_equal(g1: Graph(n, e), g2: Graph(n, e)) -> Bool {
  g1.kind == g2.kind
  && g1.nodes == g2.nodes
  && g1.out_edges == g2.out_edges
  && g1.in_edges == g2.in_edges
}

/// Get all edges from a graph as a list of tuples
fn get_all_edges(graph: Graph(n, e)) -> List(#(NodeId, NodeId, e)) {
  dict.fold(graph.out_edges, [], fn(acc, src, targets) {
    dict.fold(targets, acc, fn(edge_acc, dst, weight) {
      [#(src, dst, weight), ..edge_acc]
    })
  })
}

/// Count edges manually by iterating through out_edges
fn count_edges_manual(graph: Graph(n, e)) -> Int {
  dict.fold(graph.out_edges, 0, fn(acc, _src, targets) {
    acc + dict.size(targets)
  })
}

/// Sort a list of tuples by first element
fn sort_node_list(nodes: List(#(NodeId, e))) -> List(#(NodeId, e)) {
  list.sort(nodes, fn(a, b) { int.compare(a.0, b.0) })
}

// ============================================================================
// PROPERTY 1: Transpose is Involutive
// ============================================================================
// Mathematical property: transpose(transpose(G)) = G
// This is critical because Yog's O(1) transpose is a key feature

pub fn transpose_involutive_test() {
  use graph <- qcheck.given(graph_generator())

  let double_transposed =
    graph
    |> transform.transpose()
    |> transform.transpose()

  assert graphs_equal(graph, double_transposed)
}

// ============================================================================
// PROPERTY 2: Edge Count Consistency
// ============================================================================
// The edge_count() function should match actual edges in the graph
// For undirected graphs, each edge is stored twice but counted once

pub fn edge_count_consistency_test() {
  use graph <- qcheck.given(graph_generator())

  let declared_count = model.edge_count(graph)
  let actual_count = count_edges_manual(graph)

  let expected = case graph.kind {
    model.Directed -> actual_count
    model.Undirected -> actual_count / 2
  }

  assert declared_count == expected
}

// ============================================================================
// PROPERTY 3: Undirected Graphs are Symmetric
// ============================================================================
// For undirected graphs, successors(v) should equal predecessors(v)
// This ensures edges are truly bidirectional

pub fn undirected_symmetry_test() {
  use graph <- qcheck.given(undirected_graph_generator())

  let all_nodes = model.all_nodes(graph)

  // Check symmetry for each node
  let is_symmetric =
    list.all(all_nodes, fn(node) {
      let successors = sort_node_list(model.successors(graph, node))
      let predecessors = sort_node_list(model.predecessors(graph, node))
      successors == predecessors
    })

  assert is_symmetric
}

// ============================================================================
// PROPERTY 4: Add/Remove Edge are Inverses
// ============================================================================
// Adding and then removing an edge should make it disappear
// Using example-based tests instead of full PBT for performance

pub fn add_remove_edge_inverse_directed_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)

  let with_edge = model.add_edge(graph, from: 0, to: 1, with: 10)

  let edge_exists =
    model.successors(with_edge, 0)
    |> list.any(fn(pair) { pair.0 == 1 })
  assert edge_exists

  let removed = model.remove_edge(with_edge, 0, 1)

  let edge_gone =
    model.successors(removed, 0)
    |> list.all(fn(pair) { pair.0 != 1 })
  assert edge_gone
}

pub fn add_remove_edge_inverse_undirected_test() {
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)

  let with_edge = model.add_edge(graph, from: 0, to: 1, with: 10)

  // Both directions should exist
  let forward_exists =
    model.successors(with_edge, 0)
    |> list.any(fn(pair) { pair.0 == 1 })
  let backward_exists =
    model.successors(with_edge, 1)
    |> list.any(fn(pair) { pair.0 == 0 })
  assert forward_exists && backward_exists

  // Remove one direction
  let removed = model.remove_edge(with_edge, 0, 1)

  let forward_gone =
    model.successors(removed, 0)
    |> list.all(fn(pair) { pair.0 != 1 })
  assert forward_gone
}

// ============================================================================
// PROPERTY 5: Neighbors == Successors for Undirected Graphs
// ============================================================================
// For undirected graphs, neighbors() and successors() should be identical

pub fn undirected_neighbors_equal_successors_test() {
  use graph <- qcheck.given(undirected_graph_generator())
  use node <- qcheck.given(qcheck.bounded_int(0, 20))

  // Only test if node exists in graph
  case dict.has_key(graph.nodes, node) {
    False -> Nil
    True -> {
      let neighbors = sort_node_list(model.neighbors(graph, node))
      let successors = sort_node_list(model.successors(graph, node))

      assert neighbors == successors
    }
  }
}

// ============================================================================
// PROPERTY 6: Map Nodes Preserves Structure
// ============================================================================
// Mapping node data should not change graph structure (edges, topology)

pub fn map_nodes_preserves_structure_test() {
  use graph <- qcheck.given(graph_generator())

  // Map node data: n -> n * 2
  let mapped = transform.map_nodes(graph, fn(n) { n * 2 })

  // Same number of nodes and edges
  assert model.order(mapped) == model.order(graph)
  assert model.edge_count(mapped) == model.edge_count(graph)

  // Same adjacency structure (same edges exist)
  let structure_preserved =
    list.all(model.all_nodes(graph), fn(node) {
      let orig_successors =
        model.successors(graph, node)
        |> list.map(fn(pair) { pair.0 })
        |> list.sort(int.compare)

      let mapped_successors =
        model.successors(mapped, node)
        |> list.map(fn(pair) { pair.0 })
        |> list.sort(int.compare)

      orig_successors == mapped_successors
    })

  assert structure_preserved
}

// ============================================================================
// PROPERTY 7: Map Edges Preserves Structure
// ============================================================================
// Mapping edge weights should not change graph topology

pub fn map_edges_preserves_structure_test() {
  use graph <- qcheck.given(graph_generator())

  // Map edge weights: w -> w * 2
  let mapped = transform.map_edges(graph, fn(w) { w * 2 })

  // Same number of nodes and edges
  assert model.order(mapped) == model.order(graph)
  assert model.edge_count(mapped) == model.edge_count(graph)

  // Same adjacency structure
  let structure_preserved =
    list.all(model.all_nodes(graph), fn(node) {
      let orig_neighbors =
        model.successors(graph, node)
        |> list.map(fn(pair) { pair.0 })
        |> list.sort(int.compare)

      let mapped_neighbors =
        model.successors(mapped, node)
        |> list.map(fn(pair) { pair.0 })
        |> list.sort(int.compare)

      orig_neighbors == mapped_neighbors
    })

  assert structure_preserved
}

// ============================================================================
// PROPERTY 8: Filter Nodes Removes Incident Edges
// ============================================================================
// When filtering nodes, all edges to/from removed nodes should be gone

pub fn filter_nodes_removes_incident_edges_test() {
  use graph <- qcheck.given(graph_generator())
  use threshold <- qcheck.given(qcheck.bounded_int(0, 20))

  // Filter: keep nodes with data > threshold
  let filtered = transform.filter_nodes(graph, fn(n) { n > threshold })

  let kept_nodes = set.from_list(model.all_nodes(filtered))

  // No edges should connect to removed nodes
  let no_invalid_edges =
    list.all(model.all_nodes(filtered), fn(node) {
      // All successors should be in kept_nodes
      let all_successors_valid =
        model.successors(filtered, node)
        |> list.all(fn(succ_pair) {
          let #(succ, _weight) = succ_pair
          set.contains(kept_nodes, succ)
        })

      // All predecessors should be in kept_nodes
      let all_predecessors_valid =
        model.predecessors(filtered, node)
        |> list.all(fn(pred_pair) {
          let #(pred, _weight) = pred_pair
          set.contains(kept_nodes, pred)
        })

      all_successors_valid && all_predecessors_valid
    })

  assert no_invalid_edges
}

// ============================================================================
// PROPERTY 9: To Undirected Creates Symmetry
// ============================================================================
// Converting to undirected should create symmetric adjacencies

pub fn to_undirected_creates_symmetry_test() {
  use graph <- qcheck.given(directed_graph_generator())

  // Convert to undirected, keeping max weight when edges conflict
  let undirected =
    transform.to_undirected(graph, fn(w1, w2) { int.max(w1, w2) })

  // Should be undirected type
  assert undirected.kind == model.Undirected

  // Should have symmetric adjacencies
  let is_symmetric =
    list.all(model.all_nodes(undirected), fn(node) {
      let successors =
        model.successors(undirected, node)
        |> list.map(fn(p) { p.0 })
        |> set.from_list

      let predecessors =
        model.predecessors(undirected, node)
        |> list.map(fn(p) { p.0 })
        |> set.from_list

      successors == predecessors
    })

  assert is_symmetric
}

// ============================================================================
// PROPERTY 10: BFS/DFS Visit Each Node at Most Once
// ============================================================================
// Traversal should never visit the same node twice
// Using example-based tests for specific graph structures

pub fn traversal_no_duplicates_bfs_test() {
  // Simple linear graph: 0 -> 1 -> 2
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let visited = traversal.walk(graph, from: 0, using: traversal.BreadthFirst)

  let unique_count = set.size(set.from_list(visited))
  let total_count = list.length(visited)

  assert unique_count == total_count
}

pub fn traversal_no_duplicates_dfs_test() {
  // Graph with cycle: 0 -> 1 -> 2 -> 0
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 0, with: 1)

  let visited = traversal.walk(graph, from: 0, using: traversal.DepthFirst)

  let unique_count = set.size(set.from_list(visited))
  let total_count = list.length(visited)

  // Should visit each node exactly once despite cycle
  assert unique_count == total_count
  assert total_count == 3
}
