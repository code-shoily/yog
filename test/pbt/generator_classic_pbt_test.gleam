import gleam/int
import gleam/list
import gleeunit
import qcheck
import yog/generator/classic as generators
import yog/internal/utils
import yog/model

// Reduced test count since there are 65 PBT tests in this file
const test_count = 25

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Complete Graph Properties
// ============================================================================

pub fn complete_graph_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 20),
  )

  let graph = generators.complete(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n
}

pub fn complete_graph_has_correct_edge_count_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 15),
  )

  let graph = generators.complete(n)
  let edge_count = model.edge_count(graph)

  // Undirected complete graph has n*(n-1)/2 edges
  let expected = { n * { n - 1 } } / 2

  assert edge_count == expected
}

pub fn complete_graph_is_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 10),
  )

  let graph = generators.complete(n)
  let all_nodes = model.all_nodes(graph)

  let is_regular = case all_nodes {
    [] -> True
    nodes ->
      list.all(nodes, fn(node) {
        let degree = model.successors(graph, node) |> list.length()
        degree == n - 1
      })
  }

  assert is_regular
}

// ============================================================================
// Cycle Graph Properties
// ============================================================================

pub fn cycle_graph_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 30),
  )

  let graph = generators.cycle(n)
  let node_count = model.all_nodes(graph) |> list.length()

  // Cycle requires at least 3 nodes
  let expected = case n < 3 {
    True -> 0
    False -> n
  }

  assert node_count == expected
}

pub fn cycle_graph_has_n_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 30),
  )

  let graph = generators.cycle(n)
  let edge_count = model.edge_count(graph)

  // Undirected cycle has n edges
  assert edge_count == n
}

pub fn cycle_graph_is_2_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 20),
  )

  let graph = generators.cycle(n)
  let all_nodes = model.all_nodes(graph)

  let is_2_regular =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == 2
    })

  assert is_2_regular
}

// ============================================================================
// Path Graph Properties
// ============================================================================

pub fn path_graph_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 30),
  )

  let graph = generators.path(n)
  let node_count = model.all_nodes(graph) |> list.length()

  // Path with n <= 0 should have 0 nodes, otherwise n nodes
  let expected = case n <= 0 {
    True -> 0
    False -> n
  }

  assert node_count == expected
}

pub fn path_graph_has_n_minus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 30),
  )

  let graph = generators.path(n)
  let edge_count = model.edge_count(graph)

  // Undirected path has n-1 edges
  assert edge_count == n - 1
}

pub fn path_graph_endpoints_have_degree_1_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 20),
  )

  let graph = generators.path(n)

  // First and last nodes have degree 1
  let first_degree = model.successors(graph, 0) |> list.length()
  let last_degree = model.successors(graph, n - 1) |> list.length()

  assert first_degree == 1
  assert last_degree == 1
}

// ============================================================================
// Star Graph Properties
// ============================================================================

pub fn star_graph_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 30),
  )

  let graph = generators.star(n)
  let node_count = model.all_nodes(graph) |> list.length()

  let expected = case n <= 0 {
    True -> 0
    False -> n
  }

  assert node_count == expected
}

pub fn star_graph_has_n_minus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 30),
  )

  let graph = generators.star(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == n - 1
}

pub fn star_graph_center_has_degree_n_minus_1_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 20),
  )

  let graph = generators.star(n)
  let center_degree = model.successors(graph, 0) |> list.length()

  assert center_degree == n - 1
}

pub fn star_graph_leaves_have_degree_1_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 15),
  )

  let graph = generators.star(n)

  // All non-center nodes should have degree 1
  let leaves = utils.range(1, n - 1) |> list.map(fn(x) { x })

  let all_leaves_degree_1 =
    list.all(leaves, fn(leaf) {
      let degree = model.successors(graph, leaf) |> list.length()
      degree == 1
    })

  assert all_leaves_degree_1
}

// ============================================================================
// Wheel Graph Properties
// ============================================================================

pub fn wheel_graph_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(4, 20),
  )

  let graph = generators.wheel(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n
}

pub fn wheel_graph_has_2_times_n_minus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(4, 15),
  )

  let graph = generators.wheel(n)
  let edge_count = model.edge_count(graph)

  // Wheel has 2*(n-1) edges: (n-1) spokes + (n-1) rim edges
  assert edge_count == 2 * { n - 1 }
}

pub fn wheel_graph_center_has_degree_n_minus_1_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(4, 15),
  )

  let graph = generators.wheel(n)
  let center_degree = model.successors(graph, 0) |> list.length()

  assert center_degree == n - 1
}

pub fn wheel_graph_rim_nodes_have_degree_3_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(4, 12),
  )

  let graph = generators.wheel(n)

  // Rim nodes (1 to n-1) should have degree 3
  let rim_nodes = utils.range(1, n - 1) |> list.map(fn(x) { x })

  let all_rim_degree_3 =
    list.all(rim_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == 3
    })

  assert all_rim_degree_3
}

// ============================================================================
// Complete Bipartite Properties
// ============================================================================

pub fn complete_bipartite_has_m_plus_n_nodes_test() {
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 10),
  )
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 10),
  )

  let graph = generators.complete_bipartite(m, n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == m + n
}

pub fn complete_bipartite_has_m_times_n_edges_test() {
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 8),
  )
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 8),
  )

  let graph = generators.complete_bipartite(m, n)
  let edge_count = model.edge_count(graph)

  assert edge_count == m * n
}

pub fn complete_bipartite_is_bipartite_test() {
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 6),
  )
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 6),
  )

  let graph = generators.complete_bipartite(m, n)

  // Left partition nodes (0..m-1) should only connect to right partition
  let left_partition = utils.range(0, m - 1) |> list.map(fn(x) { x })
  let right_partition = utils.range(m, m + n - 1) |> list.map(fn(x) { x })

  let is_bipartite =
    list.all(left_partition, fn(left) {
      let neighbors =
        model.successors(graph, left) |> list.map(fn(edge) { edge.0 })
      // All neighbors should be in right partition
      list.all(neighbors, fn(neighbor) {
        list.contains(right_partition, neighbor)
      })
    })

  assert is_bipartite
}

// ============================================================================
// Binary Tree Properties
// ============================================================================

pub fn binary_tree_has_correct_node_count_test() {
  use depth <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 5),
  )

  let graph = generators.binary_tree(depth)
  let node_count = model.all_nodes(graph) |> list.length()

  // Binary tree of depth d has 2^(d+1) - 1 nodes
  let expected = int.bitwise_shift_left(1, depth + 1) - 1

  assert node_count == expected
}

pub fn binary_tree_has_n_minus_1_edges_test() {
  use depth <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 5),
  )

  let graph = generators.binary_tree(depth)
  let node_count = model.all_nodes(graph) |> list.length()
  let edge_count = model.edge_count(graph)

  // Tree has n-1 edges
  assert edge_count == node_count - 1
}

pub fn binary_tree_root_has_at_most_2_children_test() {
  use depth <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 5),
  )

  let graph = generators.binary_tree(depth)
  let root_children = model.successors(graph, 0) |> list.length()

  assert root_children == 2
}

// ============================================================================
// k-ary Tree Properties
// ============================================================================

pub fn kary_tree_is_tree_test() {
  use depth <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 4),
  )
  use arity <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  let graph = generators.kary_tree(depth, arity: arity)
  let node_count = model.all_nodes(graph) |> list.length()
  let edge_count = model.edge_count(graph)

  // Tree has n-1 edges
  assert edge_count == node_count - 1
}

pub fn kary_tree_root_has_at_most_k_children_test() {
  use depth <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 4),
  )
  use arity <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 4),
  )

  let graph = generators.kary_tree(depth, arity: arity)
  let root_children = model.successors(graph, 0) |> list.length()

  // Root should have min(arity, total_nodes - 1) children
  assert root_children <= arity
}

// ============================================================================
// Grid Properties
// ============================================================================

pub fn grid_2d_has_rows_times_cols_nodes_test() {
  use rows <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )
  use cols <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )

  let graph = generators.grid_2d(rows, cols)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == rows * cols
}

pub fn grid_2d_corner_nodes_have_degree_2_test() {
  use rows <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 6),
  )
  use cols <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 6),
  )

  let graph = generators.grid_2d(rows, cols)

  // Corner node 0 should have degree 2
  let corner_degree = model.successors(graph, 0) |> list.length()

  assert corner_degree == 2
}

pub fn grid_2d_internal_nodes_have_degree_4_test() {
  use rows <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 6),
  )
  use cols <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 6),
  )

  let graph = generators.grid_2d(rows, cols)

  // Center node should have degree 4
  let center = { rows / 2 } * cols + { cols / 2 }
  let center_degree = model.successors(graph, center) |> list.length()

  assert center_degree == 4
}

// ============================================================================
// Petersen Graph Properties (Fixed Graph)
// ============================================================================

pub fn petersen_graph_has_10_nodes_test() {
  let graph = generators.petersen()
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 10
}

pub fn petersen_graph_has_15_edges_test() {
  let graph = generators.petersen()
  let edge_count = model.edge_count(graph)

  assert edge_count == 15
}

pub fn petersen_graph_is_3_regular_test() {
  let graph = generators.petersen()
  let all_nodes = model.all_nodes(graph)

  let is_3_regular =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == 3
    })

  assert is_3_regular
}

// ============================================================================
// Hypercube Properties
// ============================================================================

pub fn hypercube_has_2_pow_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 5),
  )

  let graph = generators.hypercube(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == int.bitwise_shift_left(1, n)
}

pub fn hypercube_is_n_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 5),
  )

  let graph = generators.hypercube(n)
  let all_nodes = model.all_nodes(graph)

  let is_n_regular =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == n
    })

  assert is_n_regular
}

// ============================================================================
// Ladder Graph Properties
// ============================================================================

pub fn ladder_has_2n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 15),
  )

  let graph = generators.ladder(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 2 * n
}

pub fn ladder_has_3n_minus_2_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 15),
  )

  let graph = generators.ladder(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == 3 * n - 2
}

// ============================================================================
// Circular Ladder (Prism) Properties
// ============================================================================

pub fn circular_ladder_has_2n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 12),
  )

  let graph = generators.circular_ladder(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 2 * n
}

pub fn circular_ladder_has_3n_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 10),
  )

  let graph = generators.circular_ladder(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == 3 * n
}

pub fn circular_ladder_is_cubic_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(3, 8),
  )

  let graph = generators.circular_ladder(n)
  let all_nodes = model.all_nodes(graph)

  let is_cubic =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == 3
    })

  assert is_cubic
}

// ============================================================================
// Möbius Ladder Properties
// ============================================================================

pub fn mobius_ladder_has_2n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 10),
  )

  let graph = generators.mobius_ladder(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 2 * n
}

pub fn mobius_ladder_has_3n_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 8),
  )

  let graph = generators.mobius_ladder(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == 3 * n
}

pub fn mobius_ladder_is_cubic_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 6),
  )

  let graph = generators.mobius_ladder(n)
  let all_nodes = model.all_nodes(graph)

  let is_cubic =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == 3
    })

  assert is_cubic
}

// ============================================================================
// Friendship Graph Properties
// ============================================================================

pub fn friendship_has_2n_plus_1_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 10),
  )

  let graph = generators.friendship(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 2 * n + 1
}

pub fn friendship_has_3n_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )

  let graph = generators.friendship(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == 3 * n
}

pub fn friendship_center_has_degree_2n_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )

  let graph = generators.friendship(n)
  let center_degree = model.successors(graph, 0) |> list.length()

  assert center_degree == 2 * n
}

// ============================================================================
// Crown Graph Properties
// ============================================================================

pub fn crown_has_2n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 10),
  )

  let graph = generators.crown(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 2 * n
}

pub fn crown_has_n_times_n_minus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 8),
  )

  let graph = generators.crown(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == n * { n - 1 }
}

pub fn crown_is_n_minus_1_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 6),
  )

  let graph = generators.crown(n)
  let all_nodes = model.all_nodes(graph)

  let is_regular =
    list.all(all_nodes, fn(node) {
      let degree = model.successors(graph, node) |> list.length()
      degree == n - 1
    })

  assert is_regular
}

// ============================================================================
// Turán Graph Properties
// ============================================================================

pub fn turan_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 12),
  )
  use r <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 6),
  )

  let graph = generators.turan(n, r)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n
}

pub fn turan_is_complete_when_r_geq_n_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 6),
  )

  // When r >= n, Turán graph is complete
  let turan = generators.turan(n, n + 1)
  let complete = generators.complete(n)

  assert model.edge_count(turan) == model.edge_count(complete)
}

// ============================================================================
// Empty Graph Properties
// ============================================================================

pub fn empty_graph_has_n_nodes_and_no_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 20),
  )

  let graph = generators.empty(n)
  let node_count = model.all_nodes(graph) |> list.length()
  let edge_count = model.edge_count(graph)

  let expected_nodes = case n <= 0 {
    True -> 0
    False -> n
  }

  assert node_count == expected_nodes
  assert edge_count == 0
}

// ============================================================================
// Platonic Solids Properties
// ============================================================================

pub fn tetrahedron_is_k4_test() {
  let tetra = generators.tetrahedron()
  let k4 = generators.complete(4)

  assert model.edge_count(tetra) == model.edge_count(k4)
}

pub fn cube_is_3d_hypercube_test() {
  let cube = generators.cube()
  let h3 = generators.hypercube(3)

  assert model.all_nodes(cube) |> list.length()
    == model.all_nodes(h3) |> list.length()
  assert model.edge_count(cube) == model.edge_count(h3)
}

pub fn octahedron_has_6_nodes_12_edges_test() {
  let octa = generators.octahedron()

  assert model.all_nodes(octa) |> list.length() == 6
  assert model.edge_count(octa) == 12
}

pub fn dodecahedron_has_20_nodes_30_edges_test() {
  let dodec = generators.dodecahedron()

  assert model.all_nodes(dodec) |> list.length() == 20
  assert model.edge_count(dodec) == 30
}

pub fn icosahedron_has_12_nodes_30_edges_test() {
  let icosa = generators.icosahedron()

  assert model.all_nodes(icosa) |> list.length() == 12
  assert model.edge_count(icosa) == 30
}

// ============================================================================
// Book Graph Properties
// ============================================================================

pub fn book_has_n_plus_2_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 10),
  )

  let graph = generators.book(n)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n + 2
}

pub fn book_has_2n_plus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )

  let graph = generators.book(n)
  let edge_count = model.edge_count(graph)

  assert edge_count == 2 * n + 1
}

// ============================================================================
// Complete k-ary Tree Properties
// ============================================================================

pub fn complete_kary_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 20),
  )
  use arity <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  let graph = generators.complete_kary(n, arity: arity)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n
}

pub fn complete_kary_is_tree_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 15),
  )
  use arity <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  let graph = generators.complete_kary(n, arity: arity)
  let node_count = model.all_nodes(graph) |> list.length()
  let edge_count = model.edge_count(graph)

  // Tree has n-1 edges
  assert edge_count == node_count - 1
}

// ============================================================================
// Caterpillar Properties
// ============================================================================

pub fn caterpillar_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 15),
  )
  use spine_len <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 10),
  )

  let graph = generators.caterpillar(n, spine_length: spine_len)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == n
}

pub fn caterpillar_is_tree_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 12),
  )
  use spine_len <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 8),
  )

  let graph = generators.caterpillar(n, spine_length: spine_len)
  let node_count = model.all_nodes(graph) |> list.length()
  let edge_count = model.edge_count(graph)

  // Tree has n-1 edges
  assert edge_count == node_count - 1
}

// ============================================================================
// Windmill Properties
// ============================================================================

pub fn windmill_has_1_plus_n_times_k_minus_1_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 5),
  )
  use k <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 5),
  )

  let graph = generators.windmill(n, clique_size: k)
  let node_count = model.all_nodes(graph) |> list.length()

  assert node_count == 1 + n * { k - 1 }
}

pub fn windmill_center_has_correct_degree_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 4),
  )
  use k <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 5),
  )

  let graph = generators.windmill(n, clique_size: k)
  let center_degree = model.successors(graph, 0) |> list.length()

  // Center connects to all non-center nodes
  assert center_degree == n * { k - 1 }
}

// ============================================================================
// Windmill/Equivalence with Friendship
// ============================================================================

pub fn windmill_k3_is_friendship_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 5),
  )

  let windmill = generators.windmill(n, clique_size: 3)
  let friendship = generators.friendship(n)

  assert model.all_nodes(windmill) |> list.length()
    == model.all_nodes(friendship) |> list.length()
  assert model.edge_count(windmill) == model.edge_count(friendship)
}
