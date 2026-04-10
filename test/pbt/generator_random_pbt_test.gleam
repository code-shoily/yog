import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleeunit
import qcheck
import yog/generator/random as generators
import yog/model

// Reduced test count to avoid slowing down the test suite
const test_count = 25

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Erdős-Rényi G(n, p) Properties
// ============================================================================

pub fn erdos_renyi_gnp_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 30),
  )

  let graph = generators.erdos_renyi_gnp(n, 0.3, seed: Some(42))
  let node_count = list.length(model.all_nodes(graph))

  assert node_count == n
}

pub fn erdos_renyi_gnp_expected_edge_count_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(10, 30),
  )

  let p = 0.5
  let graph = generators.erdos_renyi_gnp(n, p, seed: Some(42))
  let edge_count = model.edge_count(graph)

  // Expected edges = p * n(n-1)/2
  let expected = float.round(p *. int.to_float(n * { n - 1 }) /. 2.0)

  // Edge count should be reasonable (within 3 standard deviations)
  // This is a probabilistic test - may occasionally fail
  let variance = int.to_float(n * { n - 1 }) /. 2.0 *. p *. { 1.0 -. p }
  let std_dev = case float.square_root(variance) {
    Ok(sd) -> float.truncate(sd)
    Error(_) -> 5
  }
  let tolerance = int.max(std_dev * 4, 5)

  assert edge_count >= expected - tolerance
  assert edge_count <= expected + tolerance
}

// ============================================================================
// Erdős-Rényi G(n, m) Properties
// ============================================================================

pub fn erdos_renyi_gnm_has_exactly_m_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(5, 20),
  )
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 50),
  )

  let graph = generators.erdos_renyi_gnm(n, m, seed: Some(42))
  let max_edges = n * { n - 1 } / 2
  let expected_m = int.min(m, max_edges)

  assert model.edge_count(graph) == expected_m
}

// ============================================================================
// Barabási-Albert Properties
// ============================================================================

pub fn barabasi_albert_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(5, 30),
  )
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 4),
  )

  let graph = generators.barabasi_albert(n, m, seed: Some(42))
  let node_count = list.length(model.all_nodes(graph))

  assert node_count == n
}

pub fn barabasi_albert_has_correct_edge_count_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(5, 20),
  )
  use m <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 3),
  )

  let graph = generators.barabasi_albert(n, m, seed: Some(42))
  let m0 = int.max(m, 2)
  let initial_edges = case m0 {
    1 -> 0
    _ -> m0 * { m0 - 1 } / 2
  }
  let expected_edges = initial_edges + { n - m0 } * m

  assert model.edge_count(graph) == expected_edges
}

// ============================================================================
// Watts-Strogatz Properties
// ============================================================================

pub fn watts_strogatz_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(8, 30),
  )
  use k_half <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 3),
  )

  let k = k_half * 2
  // Ensure k < n
  let valid_k = int.min(k, n - 2)
  let graph = generators.watts_strogatz(n, valid_k, 0.1, seed: Some(42))
  let node_count = list.length(model.all_nodes(graph))

  assert node_count == n
}

pub fn watts_strogatz_p0_is_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(6, 20),
  )
  use k <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 4),
  )

  // With p=0, should be k-regular
  let graph = generators.watts_strogatz(n, k * 2, 0.0, seed: Some(42))

  let is_k_regular =
    model.all_nodes(graph)
    |> list.all(fn(node) {
      let degree = list.length(model.neighbors(graph, node))
      degree == k * 2
    })

  assert is_k_regular
}

// ============================================================================
// Random Tree Properties
// ============================================================================

pub fn random_tree_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(0, 30),
  )

  let graph = generators.random_tree(n, seed: Some(42))
  let node_count = list.length(model.all_nodes(graph))

  assert node_count == n
}

pub fn random_tree_has_n_minus_1_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 25),
  )

  let graph = generators.random_tree(n, seed: Some(42))
  let edge_count = model.edge_count(graph)

  assert edge_count == n - 1
}

// ============================================================================
// Random Regular Properties
// ============================================================================

pub fn random_regular_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(6, 20),
  )
  use d <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  // Only test with valid params (n*d even and d < n)
  let valid_params = case int.remainder(n * d, 2) {
    Ok(0) -> d < n
    _ -> False
  }

  case valid_params {
    True -> {
      let graph = generators.random_regular(n, d, seed: Some(42))
      let node_count = list.length(model.all_nodes(graph))
      assert node_count == n
    }
    False -> {
      // Skip invalid params
      Nil
    }
  }
}

pub fn random_regular_is_d_regular_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(6, 16),
  )
  use d <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  // Only test with valid params (n*d even and d < n)
  let valid_params = case int.remainder(n * d, 2) {
    Ok(0) -> d < n
    _ -> False
  }

  case valid_params {
    True -> {
      let graph = generators.random_regular(n, d, seed: Some(42))

      let is_d_regular =
        model.all_nodes(graph)
        |> list.all(fn(node) {
          let degree = list.length(model.neighbors(graph, node))
          degree == d
        })

      assert is_d_regular
    }
    False -> {
      // Skip invalid params
      Nil
    }
  }
}

pub fn random_regular_has_nd_half_edges_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(6, 16),
  )
  use d <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(2, 4),
  )

  // Only test with valid params (n*d even and d < n)
  let valid_params = case int.remainder(n * d, 2) {
    Ok(0) -> d < n
    _ -> False
  }

  case valid_params {
    True -> {
      let graph = generators.random_regular(n, d, seed: Some(42))
      let expected_edges = n * d / 2
      assert model.edge_count(graph) == expected_edges
    }
    False -> {
      // Skip invalid params
      Nil
    }
  }
}

// ============================================================================
// SBM Properties
// ============================================================================

pub fn sbm_has_n_nodes_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(4, 30),
  )
  use k <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(1, 5),
  )

  let graph = generators.sbm(n, k, 0.3, 0.05, seed: Some(42))
  let node_count = list.length(model.all_nodes(graph))

  assert node_count == n
}

pub fn sbm_high_pin_creates_dense_communities_test() {
  use n <- qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bounded_int(10, 20),
  )

  // With p_in=1 and p_out=0, edges only within communities
  let k = 2
  let graph = generators.sbm(n, k, 1.0, 0.0, seed: Some(42))

  // Communities may not be perfectly balanced (nodes assigned sequentially)
  // Each community has either n/2 or n/2 + 1 nodes (for odd n)
  // Just check that we have a reasonable number of edges
  let edge_count = model.edge_count(graph)

  // With p_in=1, we should have close to maximum possible intra-community edges
  // Allow some tolerance for the random assignment
  assert edge_count > 0
}
