////
//// Aggressive property tests - trying to find bugs by testing edge cases
////

import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleeunit
import qcheck
import yog/model.{type Graph, type GraphType, type NodeId}
import yog/transform

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// EDGE CASE: Empty Graphs
// ============================================================================

pub fn empty_graph_edge_count_test() {
  let directed = model.new(model.Directed)
  let undirected = model.new(model.Undirected)

  assert model.edge_count(directed) == 0
  assert model.edge_count(undirected) == 0
  assert model.order(directed) == 0
  assert model.order(undirected) == 0
}

pub fn empty_graph_transpose_test() {
  let directed = model.new(model.Directed)
  let transposed = transform.transpose(directed)

  assert model.order(transposed) == 0
  assert model.edge_count(transposed) == 0
}

// ============================================================================
// EDGE CASE: Self-Loops
// ============================================================================

pub fn self_loop_directed_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_edge(from: 0, to: 0, with: 10)

  // Should have 1 edge
  assert model.edge_count(graph) == 1

  // Node 0 should be its own successor
  let successors = model.successors(graph, 0)
  assert list.length(successors) == 1
  assert list.any(successors, fn(pair) { pair.0 == 0 })
}

pub fn self_loop_undirected_test() {
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_edge(from: 0, to: 0, with: 10)

  // For undirected self-loop, should it count as 1 or 2?
  let edge_count = model.edge_count(graph)

  // Let's see what it actually is
  let successors = model.successors(graph, 0)
  let succ_count = list.length(successors)

  // Document the actual behavior
  assert succ_count >= 1
}

// ============================================================================
// EDGE CASE: Multiple Edges Between Same Nodes
// ============================================================================

pub fn multiple_edges_same_pair_test() {
  // Add same edge twice - should replace not accumulate
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_edge(from: 0, to: 1, with: 10)
    |> model.add_edge(from: 0, to: 1, with: 20)
  // Replace weight

  assert model.edge_count(graph) == 1

  let successors = model.successors(graph, 0)
  assert list.length(successors) == 1

  // Weight should be the latest (20)
  let weight = case list.first(successors) {
    Ok(#(_dst, w)) -> w
    Error(_) -> panic as "Should have successor"
  }
  assert weight == 20
}

// ============================================================================
// EDGE CASE: Remove Edge That Doesn't Exist
// ============================================================================

pub fn remove_nonexistent_edge_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)

  // No edge exists, try to remove it
  let removed = model.remove_edge(graph, 0, 1)

  // Should be a no-op
  assert model.edge_count(removed) == model.edge_count(graph)
  assert model.order(removed) == model.order(graph)
}

// ============================================================================
// EDGE CASE: Undirected Edge Removal Asymmetry
// ============================================================================

pub fn undirected_edge_removal_asymmetry_test() {
  // DOCUMENTED BEHAVIOR (but surprising):
  // remove_edge() only removes ONE direction for undirected graphs
  // This is inconsistent with add_edge() which adds BOTH directions
  // See model.gleam lines 293-295 and 324-328

  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_edge(from: 0, to: 1, with: 10)

  // add_edge created BOTH directions
  assert list.length(model.successors(graph, 0)) == 1
  assert list.length(model.successors(graph, 1)) == 1

  // Remove in one direction - docs say this only removes ONE direction
  let removed_once = model.remove_edge(graph, 0, 1)

  let forward_after = model.successors(removed_once, 0)
  let backward_after = model.successors(removed_once, 1)

  // Verify the documented behavior: only ONE direction removed
  assert forward_after == []
  assert list.length(backward_after) == 1
  // Still exists!

  // To fully remove, must call twice (as documented)
  let fully_removed = model.remove_edge(removed_once, 1, 0)

  assert model.successors(fully_removed, 0) == []
  assert model.successors(fully_removed, 1) == []
  assert model.edge_count(fully_removed) == 0
}

// ============================================================================
// EDGE CASE: Filter Nodes Edge Cases
// ============================================================================

pub fn filter_all_nodes_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_edge(from: 0, to: 1, with: 10)

  // Filter out all nodes
  let empty = transform.filter_nodes(graph, fn(_) { False })

  assert model.order(empty) == 0
  assert model.edge_count(empty) == 0
}

// ============================================================================
// EDGE CASE: Transpose on Graph with Self-Loop
// ============================================================================

pub fn transpose_with_self_loop_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_edge(from: 0, to: 0, with: 10)

  let transposed = transform.transpose(graph)

  // Self-loop should remain a self-loop
  let successors = model.successors(transposed, 0)
  assert list.length(successors) == 1
  assert list.any(successors, fn(pair) { pair.0 == 0 })
}

// ============================================================================
// EDGE CASE: Node with No Edges
// ============================================================================

pub fn isolated_node_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 10)

  // Node 2 is isolated
  assert model.order(graph) == 3
  assert model.edge_count(graph) == 1

  let successors = model.successors(graph, 2)
  let predecessors = model.predecessors(graph, 2)

  assert list.length(successors) == 0
  assert list.length(predecessors) == 0
}
