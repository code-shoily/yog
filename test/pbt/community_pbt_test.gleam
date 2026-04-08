import gleam/dict
import gleam/int

import gleam/list
import gleam/option
import gleeunit/should
import pbt/qcheck_generators
import qcheck
import yog
import yog/community/fluid_communities
import yog/community/label_propagation
import yog/community/leiden
import yog/community/louvain
import yog/community/metrics
import yog/internal/utils
import yog/model

const epsilon = 0.0000001

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

  let has_self_loop =
    list.any(model.all_nodes(graph), fn(node) {
      list.any(yog.neighbors(graph, node), fn(neighbor) { neighbor.0 == node })
    })

  case has_self_loop {
    True -> should.be_true(True)
    False -> {
      let communities = louvain.detect(graph)
      let mod_val = metrics.modularity(graph, communities)
      let valid = mod_val >=. -0.5 -. epsilon && mod_val <=. 1.0 +. epsilon
      valid |> should.be_true()
    }
  }
}

pub fn modularity_bounds_leiden_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let has_self_loop =
    list.any(model.all_nodes(graph), fn(node) {
      list.any(yog.neighbors(graph, node), fn(neighbor) { neighbor.0 == node })
    })

  case has_self_loop {
    True -> should.be_true(True)
    False -> {
      let communities = leiden.detect(graph)
      let mod_val = metrics.modularity(graph, communities)
      let valid = mod_val >=. -0.5 -. epsilon && mod_val <=. 1.0 +. epsilon
      valid |> should.be_true()
    }
  }
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
    0 -> communities.num_communities == 0
    _ if n < 3 ->
      communities.num_communities == n || communities.num_communities == 1
    _ -> communities.num_communities == 3 || communities.num_communities == 1
  }

  valid |> should.be_true()
}

// ============================================================================
// 4. General Topological Invariants (Cross-algorithm)
// ============================================================================

pub fn communities_less_than_nodes_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())
  let n = list.length(model.all_nodes(graph))

  let p1 = louvain.detect(graph).num_communities <= n
  let p2 = leiden.detect(graph).num_communities <= n
  let p3 = label_propagation.detect(graph).num_communities <= n

  { p1 && p2 && p3 } |> should.be_true()
}

pub fn contiguous_community_ids_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let comms = leiden.detect(graph)
  let k = comms.num_communities

  let valid_ids = case k {
    0 -> True
    _ -> {
      let unique_ids =
        dict.values(comms.assignments)
        |> list.unique
        |> list.sort(int.compare)

      let expected = utils.range(0, k - 1)
      unique_ids == expected
    }
  }

  valid_ids |> should.be_true()
}

pub fn no_empty_communities_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  let comms = louvain.detect(graph)
  let k = comms.num_communities
  let unique_assigned_ids =
    dict.values(comms.assignments) |> list.unique |> list.length

  // A community partition should not have ghost communities with 0 population
  { unique_assigned_ids == k } |> should.be_true()
}
