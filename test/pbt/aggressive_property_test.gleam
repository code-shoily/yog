////
//// Aggressive property tests - trying to find bugs by testing edge cases
////

import gleam/list
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/model
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
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

  let next_id = model.order(graph)
  let assert Ok(graph) =
    graph
    |> model.add_node(next_id, next_id)
    |> model.add_edge(from: next_id, to: next_id, with: 10)

  let successors = model.successors(graph, next_id)
  assert list.any(successors, fn(pair) { pair.0 == next_id })
}

pub fn self_loop_undirected_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let next_id = model.order(graph)
  let assert Ok(graph) =
    graph
    |> model.add_node(next_id, next_id)
    |> model.add_edge(from: next_id, to: next_id, with: 10)

  let successors = model.successors(graph, next_id)
  let succ_count = list.length(successors)

  assert succ_count >= 1
}

// ============================================================================
// EDGE CASE: Multiple Edges Between Same Nodes
// ============================================================================

pub fn multiple_edges_same_pair_test() {
  use #(graph, #(src, dst, _weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let weight1 = 10
      let weight2 = 20

      let assert Ok(g1) =
        model.add_edge(graph, from: src, to: dst, with: weight1)
      let count_after_1 = model.edge_count(g1)

      let assert Ok(g2) = model.add_edge(g1, from: src, to: dst, with: weight2)
      let count_after_2 = model.edge_count(g2)

      assert count_after_1 == count_after_2

      let successors = model.successors(g2, src)

      // Weight should be the latest (20)
      let edge_exists_with_new_weight =
        list.any(successors, fn(pair) { pair.0 == dst && pair.1 == weight2 })
      assert edge_exists_with_new_weight
    }
  }
}

// ============================================================================
// EDGE CASE: Remove Edge That Doesn't Exist
// ============================================================================

pub fn remove_nonexistent_edge_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  // Create a node ID that cannot exist
  let next_id = model.order(graph)
  let removed = model.remove_edge(graph, next_id, next_id)

  // Should be a no-op
  assert model.edge_count(removed) == model.edge_count(graph)
  assert model.order(removed) == model.order(graph)
}

// ============================================================================
// EDGE CASE: Undirected Edge Removal Symmetry
// ============================================================================

pub fn undirected_edge_removal_symmetry_test() {
  use #(graph, #(src, dst, weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case src == dst {
        True -> Nil
        False -> {
          let assert Ok(with_edge) =
            model.add_edge(graph, from: src, to: dst, with: weight)

          // Remove one edge, should implicitly remove both for undirected
          let removed = model.remove_edge(with_edge, src, dst)

          let forward_after = model.successors(removed, src)
          let backward_after = model.successors(removed, dst)

          // Verify both directions are fully removed
          let forward_gone = list.all(forward_after, fn(pair) { pair.0 != dst })
          assert forward_gone

          let backward_gone =
            list.all(backward_after, fn(pair) { pair.0 != src })
          assert backward_gone
        }
      }
    }
  }
}

// ============================================================================
// EDGE CASE: Filter Nodes Edge Cases
// ============================================================================

pub fn filter_all_nodes_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  // Filter out all nodes
  let empty = transform.filter_nodes(graph, fn(_) { False })

  assert model.order(empty) == 0
  assert model.edge_count(empty) == 0
}

// ============================================================================
// EDGE CASE: Transpose on Graph with Self-Loop
// ============================================================================

pub fn transpose_with_self_loop_test() {
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

  let next_id = model.order(graph)
  let graph_with_loop =
    graph
    |> model.add_node(next_id, next_id)
  let assert Ok(graph_with_loop) =
    model.add_edge(graph_with_loop, from: next_id, to: next_id, with: 10)

  let transposed = transform.transpose(graph_with_loop)

  // Self-loop should remain a self-loop
  let successors = model.successors(transposed, next_id)
  assert list.any(successors, fn(pair) { pair.0 == next_id })
}

// ============================================================================
// EDGE CASE: Node with No Edges
// ============================================================================

pub fn isolated_node_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  let next_id = model.order(graph)
  let count = model.edge_count(graph)
  let graph = model.add_node(graph, next_id, next_id)

  assert model.order(graph) == next_id + 1
  assert model.edge_count(graph) == count

  let successors = model.successors(graph, next_id)
  let predecessors = model.predecessors(graph, next_id)

  assert list.is_empty(successors)
  assert list.is_empty(predecessors)
}
