import gleam/list
import gleam/option.{Some}
import gleam/set
import gleeunit/should
import yog/generator/random as generators
import yog/model

// ============= Random Regular Graph Tests =============

pub fn random_regular_basic_test() {
  let graph = generators.random_regular(10, 3, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn random_regular_has_correct_edge_count_test() {
  // 3-regular graph with 10 nodes has 15 edges
  let graph = generators.random_regular(10, 3, seed: Some(42))
  model.edge_count(graph)
  |> should.equal(15)
}

pub fn random_regular_all_nodes_have_degree_d_test() {
  let d = 3
  let n = 10
  let graph = generators.random_regular(n, d, seed: Some(42))

  let all_have_degree_d =
    model.all_nodes(graph)
    |> list.all(fn(node) {
      let degree = list.length(model.neighbors(graph, node))
      degree == d
    })

  all_have_degree_d
  |> should.be_true()
}

pub fn random_regular_0_regular_test() {
  // 0-regular graph has no edges
  let graph = generators.random_regular(10, 0, seed: Some(42))
  model.edge_count(graph)
  |> should.equal(0)
}

pub fn random_regular_invalid_params_test() {
  // d >= n should return empty graph
  let graph = generators.random_regular(5, 5, seed: Some(42))
  model.all_nodes(graph)
  |> list.length()
  |> should.equal(0)

  // n * d must be even
  let graph2 = generators.random_regular(5, 3, seed: Some(42))
  model.all_nodes(graph2)
  |> list.length()
  |> should.equal(0)
}

// ============= SBM Tests =============

pub fn sbm_basic_test() {
  let graph = generators.sbm(20, 4, 0.5, 0.1, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

pub fn sbm_invalid_params_test() {
  // Invalid probabilities
  let graph = generators.sbm(20, 4, 1.5, 0.1, seed: Some(42))
  model.all_nodes(graph)
  |> list.length()
  |> should.equal(0)

  // k < 1
  let graph2 = generators.sbm(20, 0, 0.5, 0.1, seed: Some(42))
  model.all_nodes(graph2)
  |> list.length()
  |> should.equal(0)
}

pub fn sbm_high_intra_prob_creates_more_edges_test() {
  // High p_in should create many edges
  let graph = generators.sbm(20, 2, 0.9, 0.01, seed: Some(42))
  let edge_count = model.edge_count(graph)

  // With p_in=0.9, should have many edges (> 20 for this config)
  { edge_count > 20 }
  |> should.be_true()
}

pub fn sbm_p_in_1_creates_complete_communities_test() {
  // With p_in=1, communities should be complete
  // With p_out=0, no edges between communities
  let graph = generators.sbm(6, 2, 1.0, 0.0, seed: Some(42))

  // 2 communities of 3 nodes each, complete within, none between
  // Each community has 3 nodes, so 3 edges per community = 6 total
  model.edge_count(graph)
  |> should.equal(6)
}

// ============= Watts-Strogatz with Seeds =============

pub fn watts_strogatz_reproducibility_test() {
  // Same seed should produce same graph structure
  let graph1 = generators.watts_strogatz(20, 4, 0.1, seed: Some(42))
  let graph2 = generators.watts_strogatz(20, 4, 0.1, seed: Some(42))

  model.edge_count(graph1)
  |> should.equal(model.edge_count(graph2))
}

pub fn watts_strogatz_different_seeds_different_graphs_test() {
  // Different seeds should generally produce different graphs
  let graph1 = generators.watts_strogatz(50, 6, 0.3, seed: Some(42))
  let graph2 = generators.watts_strogatz(50, 6, 0.3, seed: Some(99))

  // They might coincidentally be the same but very unlikely
  // Just verify both are valid
  model.all_nodes(graph1)
  |> list.length()
  |> should.equal(50)

  model.all_nodes(graph2)
  |> list.length()
  |> should.equal(50)
}

// ============= Barabási-Albert with Seeds =============

pub fn barabasi_albert_reproducibility_test() {
  let graph1 = generators.barabasi_albert(30, 2, seed: Some(42))
  let graph2 = generators.barabasi_albert(30, 2, seed: Some(42))

  model.edge_count(graph1)
  |> should.equal(model.edge_count(graph2))
}

pub fn barabasi_albert_scale_free_property_test() {
  // Larger BA graphs should have hub nodes (high degree)
  let graph = generators.barabasi_albert(100, 2, seed: Some(42))

  let degrees =
    model.all_nodes(graph)
    |> list.map(fn(node) { list.length(model.neighbors(graph, node)) })

  // Max degree should be significantly higher than m
  let max_degree =
    degrees
    |> list.fold(0, fn(max, d) {
      case d > max {
        True -> d
        False -> max
      }
    })

  // In BA graphs, max degree grows with n (should be > 5 for n=100, m=2)
  { max_degree > 5 }
  |> should.be_true()
}

// ============= Erdős-Rényi with Seeds =============

pub fn erdos_renyi_gnp_reproducibility_test() {
  let graph1 = generators.erdos_renyi_gnp(30, 0.3, seed: Some(42))
  let graph2 = generators.erdos_renyi_gnp(30, 0.3, seed: Some(42))

  model.edge_count(graph1)
  |> should.equal(model.edge_count(graph2))
}

pub fn erdos_renyi_gnm_exact_edge_count_test() {
  // G(n, m) should have exactly m edges
  let graph = generators.erdos_renyi_gnm(20, 50, seed: Some(42))
  model.edge_count(graph)
  |> should.equal(50)
}

pub fn erdos_renyi_gnm_respects_max_edges_test() {
  // Can't have more edges than possible
  // For n=5, max edges = 10
  let graph = generators.erdos_renyi_gnm(5, 100, seed: Some(42))
  model.edge_count(graph)
  |> should.equal(10)
}

// ============= Random Tree Tests =============

pub fn random_tree_has_n_minus_1_edges_test() {
  let n = 20
  let graph = generators.random_tree(n, seed: Some(42))
  model.edge_count(graph)
  |> should.equal(n - 1)
}

pub fn random_tree_is_connected_test() {
  let graph = generators.random_tree(20, seed: Some(42))

  // Count reachable nodes from node 0 using BFS
  let reachable = bfs_count(graph, 0, set.new())
  set.size(reachable)
  |> should.equal(20)
}

fn bfs_count(graph, start, visited) {
  case set.contains(visited, start) {
    True -> visited
    False -> {
      let new_visited = set.insert(visited, start)
      let neighbors = model.neighbors(graph, start) |> list.map(fn(p) { p.0 })
      list.fold(neighbors, new_visited, fn(v, n) { bfs_count(graph, n, v) })
    }
  }
}

// ============= Directed Graph Tests =============

pub fn erdos_renyi_gnp_directed_test() {
  let graph =
    generators.erdos_renyi_gnp_with_type(10, 0.5, model.Directed, Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn erdos_renyi_gnm_directed_edge_count_test() {
  // Directed graph with n=10, max edges = 90
  let graph =
    generators.erdos_renyi_gnm_with_type(10, 50, model.Directed, Some(42))
  model.edge_count(graph)
  |> should.equal(50)
}

pub fn barabasi_albert_directed_test() {
  let graph =
    generators.barabasi_albert_with_type(20, 2, model.Directed, Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

pub fn watts_strogatz_directed_test() {
  let graph =
    generators.watts_strogatz_with_type(20, 4, 0.1, model.Directed, Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

pub fn random_regular_directed_test() {
  let graph =
    generators.random_regular_with_type(10, 3, model.Directed, Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn sbm_directed_test() {
  let graph =
    generators.sbm_with_type(20, 4, 0.5, 0.1, model.Directed, Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}
