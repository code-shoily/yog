import gleam/int
import gleam/list
import gleam/set
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/model.{type Graph}
import yog/transform

pub fn main() {
  gleeunit.main()
}

// Reduced test count for complex graph transformations
const test_count = 25

fn config() {
  qcheck.default_config()
  |> qcheck.with_test_count(test_count)
}

// ============================================================================
// HELPERS
// ============================================================================

/// Check if two graphs are structurally equal
fn graphs_equal(g1: Graph(n, e), g2: Graph(n, e)) -> Bool {
  g1.kind == g2.kind
  && g1.nodes == g2.nodes
  && g1.out_edges == g2.out_edges
  && g1.in_edges == g2.in_edges
}

// ============================================================================
// TRANSFORMS: TRANSPOSE
// ============================================================================

pub fn transpose_involutive_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

  let double_transposed =
    graph
    |> transform.transpose()
    |> transform.transpose()

  assert graphs_equal(graph, double_transposed)
}

pub fn empty_graph_transpose_test() {
  let directed = model.new(model.Directed)
  let transposed = transform.transpose(directed)

  assert model.order(transposed) == 0
  assert model.edge_count(transposed) == 0
}

pub fn transpose_with_self_loop_test() {
  use graph <- qcheck.run(
    config(),
    qcheck_generators.directed_graph_generator(),
  )

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
// TRANSFORMS: MAP
// ============================================================================

pub fn map_nodes_preserves_structure_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

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

pub fn map_edges_preserves_structure_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

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
// TRANSFORMS: FILTER
// ============================================================================

pub fn filter_nodes_removes_incident_edges_test() {
  use #(graph, threshold) <- qcheck.run(
    config(),
    qcheck.tuple2(
      qcheck_generators.graph_generator(),
      qcheck.bounded_int(0, 20),
    ),
  )

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

pub fn filter_edges_property_test() {
  use #(graph, threshold) <- qcheck.run(
    config(),
    qcheck.tuple2(
      qcheck_generators.graph_generator(),
      qcheck.bounded_int(0, 50),
    ),
  )

  // Filter edges with weight > threshold
  let filtered = transform.filter_edges(graph, fn(_, _, w) { w > threshold })

  // Same number of nodes
  assert model.order(filtered) == model.order(graph)

  // Fewer or equal edges
  assert model.edge_count(filtered) <= model.edge_count(graph)

  // All remaining edges satisfy the predicate
  let all_edges_valid =
    list.all(model.all_edges(filtered), fn(edge) {
      let #(_, _, weight) = edge
      weight > threshold
    })

  assert all_edges_valid
}

pub fn filter_all_nodes_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

  // Filter out all nodes
  let empty = transform.filter_nodes(graph, fn(_) { False })

  assert model.order(empty) == 0
  assert model.edge_count(empty) == 0
}

// ============================================================================
// TRANSFORMS: CONVERSION
// ============================================================================

pub fn to_undirected_creates_symmetry_test() {
  use graph <- qcheck.run(
    config(),
    qcheck_generators.directed_graph_generator(),
  )

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

pub fn to_directed_property_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())
  let directed = transform.to_directed(graph)
  assert directed.kind == model.Directed
}

// ============================================================================
// TRANSFORMS: COMBINATIONS
// ============================================================================

pub fn merge_property_test() {
  use #(g1, g2) <- qcheck.run(
    config(),
    qcheck.tuple2(
      qcheck_generators.graph_generator(),
      qcheck_generators.graph_generator(),
    ),
  )

  let merged = transform.merge(g1, g2)

  // Order should be at least max of orders and at most sum
  assert model.order(merged) >= int.max(model.order(g1), model.order(g2))
  assert model.order(merged) <= model.order(g1) + model.order(g2)

  // All nodes from both exist
  let all_nodes_present =
    list.all(model.all_nodes(g1), fn(n) { model.has_node(merged, n) })
    && list.all(model.all_nodes(g2), fn(n) { model.has_node(merged, n) })

  assert all_nodes_present
}

pub fn subgraph_is_consistent_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

  let all_ids = model.all_nodes(graph)
  case all_ids {
    [] -> Nil
    _ -> {
      // Pick some random IDs from the graph
      let sub_ids = list.take(all_ids, 5)
      let sub = transform.subgraph(graph, sub_ids)

      assert model.order(sub) <= list.length(sub_ids)
      assert list.all(model.all_nodes(sub), fn(id) {
        list.contains(sub_ids, id)
      })
    }
  }
}

pub fn complement_property_test() {
  // For a small graph, order(G) + order(complement(G)) = K_n (without self-loops)
  use graph <- qcheck.run(
    config(),
    qcheck_generators.directed_graph_generator(),
  )

  let n = model.order(graph)
  // Skip too large graphs or empty ones for this specific counting
  case n > 1 && n < 6 {
    True -> {
      // Ensure no self-loops for counts to be simple
      let g = transform.filter_edges(graph, fn(u, v, _) { u != v })
      let comp = transform.complement(g, 1)

      // Total edges in complete directed graph (no self-loops) is n*(n-1)
      assert model.edge_count(g) + model.edge_count(comp) == n * { n - 1 }
    }
    False -> Nil
  }
}

pub fn contract_reduces_order_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())

  let nodes = model.all_nodes(graph)
  case nodes {
    [a, b, ..] -> {
      let contracted = transform.contract(graph, a, b, int.add)
      assert model.order(contracted) == model.order(graph) - 1
      assert !model.has_node(contracted, b)
      assert model.has_node(contracted, a)
    }
    _ -> Nil
  }
}

// ============================================================================
// TRANSFORMS: REACHABILITY
// ============================================================================

pub fn transitive_closure_idempotent_test() {
  use graph <- qcheck.run(config(), qcheck_generators.dag_generator())

  let first = transform.transitive_closure(graph, int.max)
  let second = transform.transitive_closure(first, int.max)

  assert graphs_equal(first, second)
}

pub fn transitive_reduction_closure_identity_test() {
  // For DAGs: closure(reduction(G)) == closure(G)
  use graph <- qcheck.run(config(), qcheck_generators.dag_generator())

  let reduction = transform.transitive_reduction(graph, int.max)
  let closure_of_reduction = transform.transitive_closure(reduction, int.max)
  let closure_of_original = transform.transitive_closure(graph, int.max)

  assert graphs_equal(closure_of_reduction, closure_of_original)
}

// ============================================================================
// TRANSFORMS: UPDATES
// ============================================================================

pub fn update_node_property_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())
  let nodes = model.all_nodes(graph)

  case nodes {
    [id, ..] -> {
      let updated = transform.update_node(graph, id, 0, fn(x) { x + 100 })
      assert model.order(updated) == model.order(graph)
      // Node data is updated (need model.node to check, which returns Result)
      let assert Ok(data) = model.node(updated, id)
      let assert Ok(old_data) = model.node(graph, id)
      assert data == old_data + 100
    }
    [] -> Nil
  }
}

pub fn update_edge_property_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())
  let edges = model.all_edges(graph)

  case edges {
    [#(u, v, w), ..] -> {
      let updated =
        transform.update_edge(graph, u, v, 0, fn(weight) { weight + 5 })
      let assert Ok(new_w) = model.edge_data(updated, u, v)
      assert new_w == w + 5
    }
    [] -> Nil
  }
}

pub fn map_edges_indexed_identity_test() {
  use graph <- qcheck.run(config(), qcheck_generators.graph_generator())
  let mapped = transform.map_edges_indexed(graph, fn(_, _, w) { w })
  assert graphs_equal(graph, mapped)
}
