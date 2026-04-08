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
  use graph <- qcheck.given(qcheck_generators.graph_generator())

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
// TRANSFORMS: MAP
// ============================================================================

pub fn map_nodes_preserves_structure_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

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
  use graph <- qcheck.given(qcheck_generators.graph_generator())

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
  use graph <- qcheck.given(qcheck_generators.graph_generator())
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

pub fn filter_all_nodes_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  // Filter out all nodes
  let empty = transform.filter_nodes(graph, fn(_) { False })

  assert model.order(empty) == 0
  assert model.edge_count(empty) == 0
}

// ============================================================================
// TRANSFORMS: CONVERSION
// ============================================================================

pub fn to_undirected_creates_symmetry_test() {
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

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
