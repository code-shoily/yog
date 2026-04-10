import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import yog/connectivity
import yog/generator/random as generators
import yog/model

// ============= Erdős-Rényi G(n,p) Tests =============

pub fn erdos_renyi_gnp_basic_test() {
  let graph = generators.erdos_renyi_gnp(10, 0.0, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn erdos_renyi_gnp_complete_test() {
  let graph = generators.erdos_renyi_gnp(5, 1.0, seed: Some(42))

  // With p=1, should be complete
  list.length(model.all_nodes(graph))
  |> should.equal(5)
}

// ============= Erdős-Rényi G(n,m) Tests =============

pub fn erdos_renyi_gnm_basic_test() {
  let graph = generators.erdos_renyi_gnm(10, 15, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

// ============= Barabási-Albert Tests =============

pub fn barabasi_albert_basic_test() {
  let graph = generators.barabasi_albert(20, 3, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

pub fn barabasi_albert_connected_test() {
  let graph = generators.barabasi_albert(30, 2, seed: Some(42))

  // BA graphs are always connected
  let comps = connectivity.strongly_connected_components(graph)
  list.length(comps)
  |> should.equal(1)
}

// ============= Watts-Strogatz Tests =============

pub fn watts_strogatz_basic_test() {
  let graph = generators.watts_strogatz(20, 4, 0.0, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

// ============= Random Tree Tests =============

pub fn random_tree_basic_test() {
  let graph = generators.random_tree(10, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn random_tree_connected_test() {
  let graph = generators.random_tree(20, seed: Some(42))

  // Tree should be connected
  let comps = connectivity.strongly_connected_components(graph)
  list.length(comps)
  |> should.equal(1)
}

// ============= Property Tests =============

pub fn all_generators_respect_node_count_test() {
  let n = 15

  let graphs = [
    generators.erdos_renyi_gnp(n, 0.3, seed: Some(42)),
    generators.erdos_renyi_gnm(n, 20, seed: Some(42)),
    generators.barabasi_albert(n, 3, seed: Some(42)),
    generators.watts_strogatz(n, 4, 0.1, seed: Some(42)),
    generators.random_tree(n, seed: Some(42)),
  ]

  list.all(graphs, fn(g) { list.length(model.all_nodes(g)) == n })
  |> should.be_true()
}

// ============= Stochastic Block Model (SBM) Tests =============

pub fn sbm_basic_test() {
  let graph = generators.sbm(30, 3, 0.4, 0.05, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(30)
}

// ============= DCSBM Tests =============

pub fn dcsbm_basic_test() {
  let graph = generators.dcsbm(30, 3, 0.4, 0.05, None, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(30)
}

// ============= HSBM Tests =============

pub fn hsbm_basic_test() {
  let graph = generators.hsbm(32, 2, 4, 0.5, 0.01, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(32)
}

// ============= R-MAT Tests =============

pub fn rmat_basic_test() {
  let graph = generators.rmat(32, 100, None, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(32)
}

// ============= Kronecker Tests =============

pub fn kronecker_basic_test() {
  let initiator = #(0.9, 0.5, 0.5, 0.1)
  let graph = generators.kronecker(4, initiator, 100, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(16)
}

// ============= Geometric Graph Tests =============

pub fn geometric_basic_test() {
  let graph = generators.geometric(20, 0.2, seed: Some(42))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

// ============= Configuration Model Tests =============

pub fn configuration_model_basic_test() {
  let degrees = [3, 3, 3, 3]
  let res = generators.configuration_model(degrees, seed: Some(42))

  should.be_ok(res)
  let graph = result.unwrap(res, or: model.new(model.Undirected))

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(4)
}

pub fn randomize_degree_sequence_test() {
  let graph = generators.erdos_renyi_gnp(10, 0.5, seed: Some(42))
  let res = generators.randomize_degree_sequence(graph, seed: Some(43))

  should.be_ok(res)
  let randomized = result.unwrap(res, or: model.new(model.Undirected))

  model.all_nodes(randomized)
  |> list.length()
  |> should.equal(10)
}
