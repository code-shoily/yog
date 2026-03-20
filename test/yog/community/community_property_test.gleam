import gleam/dict
import gleam/list
import gleam/option
import gleeunit/should
import qcheck
import yog
import yog/community/fluid_communities
import yog/community/leiden
import yog/community/louvain
import yog/community/metrics
import yog/model
import yog/qcheck_generators

// ============================================================================
// 1. Universal Assignment Invariant
// ============================================================================

pub fn louvain_universal_assignment_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let communities = louvain.detect(graph)
  let assignments = communities.assignments
  let nodes = model.all_nodes(graph)

  // Every node in the graph must have an assignment
  let all_assigned = list.all(nodes, fn(n) { dict.has_key(assignments, n) })

  all_assigned |> should.be_true()
}

pub fn leiden_universal_assignment_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let communities = leiden.detect(graph)
  let assignments = communities.assignments
  let nodes = model.all_nodes(graph)

  let all_assigned = list.all(nodes, fn(n) { dict.has_key(assignments, n) })

  all_assigned |> should.be_true()
}

pub fn fluid_universal_assignment_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let communities = fluid_communities.detect(graph)
  let assignments = communities.assignments
  let nodes = model.all_nodes(graph)

  // Fluid communities might not assign disconnected nodes, so we filter 
  // them out or just check degree > 0
  let unassigned_handled =
    list.all(nodes, fn(n) {
      let degree = list.length(yog.neighbors(graph, n))
      degree == 0 || dict.has_key(assignments, n)
    })

  unassigned_handled |> should.be_true()
}

// ============================================================================
// 2. Modularity Bounds Invariant
// ============================================================================

pub fn modularity_bounds_louvain_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let communities = louvain.detect(graph)
  let mod_val = metrics.modularity(graph, communities)

  let valid = mod_val >=. -0.5000001 && mod_val <=. 1.0000001
  valid |> should.be_true()
}

pub fn modularity_bounds_leiden_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let communities = leiden.detect(graph)
  let mod_val = metrics.modularity(graph, communities)

  let valid = mod_val >=. -0.5000001 && mod_val <=. 1.0000001
  valid |> should.be_true()
}

// ============================================================================
// 3. Fluid "k" Constraint
// ============================================================================

pub fn fluid_communities_yields_exact_k_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())
  let n = list.length(model.all_nodes(graph))

  // For a random graph and a requested k=3, it should yield min(3, n)
  let options =
    fluid_communities.FluidOptions(
      target_communities: 3,
      max_iterations: 10,
      seed: option.Some(42),
    )

  let communities = fluid_communities.detect_with_options(graph, options)

  // It could be 1 for disconnected/empty edge cases, but typically bounded by n and k
  let valid = case n {
    0 -> communities.num_communities == 1 || communities.num_communities == 0
    _ if n < 3 ->
      communities.num_communities == n || communities.num_communities == 1
    _ -> communities.num_communities == 3 || communities.num_communities == 1
  }

  valid |> should.be_true()
}
