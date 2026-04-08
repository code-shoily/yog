import gleam/dict
import gleam/int
import gleam/list
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/model.{type Graph, type NodeId}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// HELPERS
// ============================================================================

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
// STRUCTURAL INVARIANTS
// ============================================================================

pub fn edge_count_consistency_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  let declared_count = model.edge_count(graph)
  let actual_count = count_edges_manual(graph)

  let expected = case graph.kind {
    model.Directed -> actual_count
    model.Undirected -> actual_count / 2
  }

  assert declared_count == expected
}

pub fn undirected_symmetry_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

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

pub fn undirected_neighbors_equal_successors_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())
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
// MUTATION INVARIANTS
// ============================================================================

pub fn add_remove_edge_inverse_directed_test() {
  use #(graph, #(src, dst, weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let assert Ok(with_edge) =
        model.add_edge(graph, from: src, to: dst, with: weight)

      let edge_exists =
        model.successors(with_edge, src)
        |> list.any(fn(pair) { pair.0 == dst })
      assert edge_exists

      let removed = model.remove_edge(with_edge, src, dst)

      let edge_gone =
        model.successors(removed, src)
        |> list.all(fn(pair) { pair.0 != dst })
      assert edge_gone
    }
  }
}

pub fn add_remove_edge_inverse_undirected_test() {
  use #(graph, #(src, dst, weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let assert Ok(with_edge) =
        model.add_edge(graph, from: src, to: dst, with: weight)

      // Both directions should exist
      let forward_exists =
        model.successors(with_edge, src)
        |> list.any(fn(pair) { pair.0 == dst })
      let backward_exists =
        model.successors(with_edge, dst)
        |> list.any(fn(pair) { pair.0 == src })
      assert forward_exists && backward_exists

      // Remove one direction
      let removed = model.remove_edge(with_edge, src, dst)

      let forward_gone =
        model.successors(removed, src)
        |> list.all(fn(pair) { pair.0 != dst })
      assert forward_gone
    }
  }
}

// ============================================================================
// EDGE CASES (Aggressive)
// ============================================================================

pub fn empty_graph_edge_count_test() {
  let directed = model.new(model.Directed)
  let undirected = model.new(model.Undirected)

  assert model.edge_count(directed) == 0
  assert model.edge_count(undirected) == 0
  assert model.order(directed) == 0
  assert model.order(undirected) == 0
}

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

pub fn remove_nonexistent_edge_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  // Create a node ID that cannot exist
  let next_id = model.order(graph)
  let removed = model.remove_edge(graph, next_id, next_id)

  // Should be a no-op
  assert model.edge_count(removed) == model.edge_count(graph)
  assert model.order(removed) == model.order(graph)
}

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
