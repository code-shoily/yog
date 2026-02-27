import gleam/list
import gleeunit/should
import yog/components
import yog/generators/random
import yog/model

// ============= Erdős-Rényi G(n,p) Tests =============

pub fn erdos_renyi_gnp_basic_test() {
  let graph = random.erdos_renyi_gnp(10, 0.0)

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn erdos_renyi_gnp_complete_test() {
  let graph = random.erdos_renyi_gnp(5, 1.0)

  // With p=1, should be complete
  list.length(model.all_nodes(graph))
  |> should.equal(5)
}

// ============= Erdős-Rényi G(n,m) Tests =============

pub fn erdos_renyi_gnm_basic_test() {
  let graph = random.erdos_renyi_gnm(10, 15)

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

// ============= Barabási-Albert Tests =============

pub fn barabasi_albert_basic_test() {
  let graph = random.barabasi_albert(20, 3)

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

pub fn barabasi_albert_connected_test() {
  let graph = random.barabasi_albert(30, 2)

  // BA graphs are always connected
  let comps = components.strongly_connected_components(graph)
  list.length(comps)
  |> should.equal(1)
}

// ============= Watts-Strogatz Tests =============

pub fn watts_strogatz_basic_test() {
  let graph = random.watts_strogatz(20, 4, 0.0)

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(20)
}

// ============= Random Tree Tests =============

pub fn random_tree_basic_test() {
  let graph = random.random_tree(10)

  model.all_nodes(graph)
  |> list.length()
  |> should.equal(10)
}

pub fn random_tree_connected_test() {
  let graph = random.random_tree(20)

  // Tree should be connected
  let comps = components.strongly_connected_components(graph)
  list.length(comps)
  |> should.equal(1)
}

// ============= Property Tests =============

pub fn all_generators_respect_node_count_test() {
  let n = 15

  let graphs = [
    random.erdos_renyi_gnp(n, 0.3),
    random.erdos_renyi_gnm(n, 20),
    random.barabasi_albert(n, 3),
    random.watts_strogatz(n, 4, 0.1),
    random.random_tree(n),
  ]

  list.all(graphs, fn(g) { list.length(model.all_nodes(g)) == n })
  |> should.be_true()
}
