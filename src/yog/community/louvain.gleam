//// Louvain method for community detection.
////
//// A fast, hierarchical algorithm that optimizes modularity. One of the most
//// widely used community detection algorithms due to its excellent balance
//// of speed and quality.
////
//// ## Algorithm
////
//// The Louvain method works in two phases that repeat until convergence:
////
//// 1. **Local Optimization**: Each node moves to the neighbor community that
////    maximizes modularity gain
//// 2. **Aggregation**: Communities become super-nodes in a new aggregated graph
//// 3. **Repeat** until no improvement in modularity
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Large graphs (millions of nodes) | ✓ Excellent |
//// | Hierarchical structure needed | ✓ Yes |
//// | General purpose | ✓ Works well on most networks |
//// | Quality over speed | Consider Leiden |
////
//// ## Complexity
////
//// - **Time**: O(E × iterations), typically O(E log V) in practice
//// - **Space**: O(V + E)
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/louvain
//// import yog/community/metrics
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1), #(1, 3, 1)])
////
//// // Basic usage
//// let communities = louvain.detect(graph)
//// io.debug(communities.num_communities)  // => 1 (all connected)
////
//// // With custom options
//// let options = louvain.LouvainOptions(
////   min_modularity_gain: 0.0001,
////   max_iterations: 100,
////   seed: 42,
//// )
//// let communities = louvain.detect_with_options(graph, options)
////
//// // Evaluate quality with modularity
//// let q = metrics.modularity(graph, communities)
//// io.debug(q)  // => 0.0 to 1.0 (higher is better)
//// ```
////
//// ## References
////
//// - [Blondel et al. 2008 - Fast unfolding of communities](https://arxiv.org/abs/0803.0476)
//// - [Wikipedia: Louvain Method](https://en.wikipedia.org/wiki/Louvain_method)

import gleam/dict
import gleam/list
import gleam/result
import yog/community.{type Communities, type Dendrogram, Communities, Dendrogram}
import yog/community/internal.{type CommunityState, CommunityState}
import yog/community/metrics
import yog/model.{type Graph, type NodeId}

/// Options for the Louvain algorithm.
pub type LouvainOptions {
  LouvainOptions(
    /// Stop when gain < threshold
    min_modularity_gain: Float,
    /// Max iterations per phase
    max_iterations: Int,
    /// Random seed for tie-breaking
    seed: Int,
  )
}

/// Statistics from the Louvain algorithm run.
pub type LouvainStats {
  LouvainStats(
    /// Number of phases executed
    num_phases: Int,
    /// Final modularity achieved
    final_modularity: Float,
    /// Modularity at each iteration
    iteration_modularity: List(Float),
  )
}

/// Default options for Louvain algorithm.
pub fn default_options() -> LouvainOptions {
  LouvainOptions(min_modularity_gain: 0.000001, max_iterations: 100, seed: 42)
}

/// Detects communities using the Louvain algorithm with default options.
pub fn detect(graph: Graph(n, Int)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using the Louvain algorithm with custom options.
pub fn detect_with_options(
  graph: Graph(n, Int),
  options: LouvainOptions,
) -> Communities {
  let #(communities, _stats) = detect_with_stats(graph, options)
  communities
}

/// Detects communities and returns statistics for debugging/analysis.
pub fn detect_with_stats(
  graph: Graph(n, Int),
  options: LouvainOptions,
) -> #(Communities, LouvainStats) {
  let nodes = model.all_nodes(graph)
  let total_weight = internal.calculate_total_weight(graph)

  // Initialize: each node in its own community
  let initial_assignments =
    list.index_map(nodes, fn(i, node) { #(node, i) })
    |> dict.from_list

  let node_weights = internal.calculate_node_weights(graph)

  let initial_state =
    CommunityState(
      assignments: initial_assignments,
      node_weights: node_weights,
      community_totals: internal.calculate_community_totals(
        initial_assignments,
        node_weights,
      ),
      community_internals: dict.new(),
      total_weight: total_weight,
    )

  do_louvain(graph, initial_state, [], 0, options)
}

/// Full hierarchical Louvain detection.
pub fn detect_hierarchical(graph: Graph(n, Int)) -> Dendrogram {
  detect_hierarchical_with_options(graph, default_options())
}

/// Full hierarchical Louvain detection with custom options.
pub fn detect_hierarchical_with_options(
  graph: Graph(n, Int),
  options: LouvainOptions,
) -> Dendrogram {
  let nodes = model.all_nodes(graph)
  let total_weight = internal.calculate_total_weight(graph)

  // Initialize
  let initial_assignments =
    list.index_map(nodes, fn(i, node) { #(node, i) })
    |> dict.from_list

  let node_weights = internal.calculate_node_weights(graph)

  let initial_state =
    CommunityState(
      assignments: initial_assignments,
      node_weights: node_weights,
      community_totals: internal.calculate_community_totals(
        initial_assignments,
        node_weights,
      ),
      community_internals: dict.new(),
      total_weight: total_weight,
    )

  do_louvain_hierarchical(graph, initial_state, [], 0, options)
}

fn do_louvain(
  graph: Graph(n, Int),
  state: CommunityState,
  mod_history: List(Float),
  phase: Int,
  options: LouvainOptions,
) -> #(Communities, LouvainStats) {
  // Run local optimization until convergence
  let #(improved, new_state) = phase1_local_optimize(graph, state, options)

  // Calculate modularity
  let normalized_assignments =
    internal.normalize_assignments(new_state.assignments)
  let communities =
    Communities(
      assignments: normalized_assignments,
      num_communities: internal.count_unique_communities(normalized_assignments),
    )
  let q = metrics.modularity(graph, communities)
  let new_history = [q, ..mod_history]

  case !improved || phase >= options.max_iterations {
    True -> {
      // Converged - return final result
      let stats =
        LouvainStats(
          num_phases: phase + 1,
          final_modularity: q,
          iteration_modularity: list.reverse(new_history),
        )
      #(communities, stats)
    }
    False -> {
      // Continue with another phase on the same graph
      do_louvain(graph, new_state, new_history, phase + 1, options)
    }
  }
}

fn do_louvain_hierarchical(
  graph: Graph(n, Int),
  state: CommunityState,
  levels: List(Communities),
  phase: Int,
  options: LouvainOptions,
) -> Dendrogram {
  // Phase 1: Local optimization
  let #(improved, new_state) = phase1_local_optimize(graph, state, options)

  // Save current level
  let normalized_assignments =
    internal.normalize_assignments(new_state.assignments)
  let current_communities =
    Communities(
      assignments: normalized_assignments,
      num_communities: internal.count_unique_communities(normalized_assignments),
    )
  let new_levels = [current_communities, ..levels]

  // Check for convergence
  let num_comms = internal.count_unique_communities(new_state.assignments)

  case !improved || phase >= options.max_iterations || num_comms <= 1 {
    True -> {
      // Converged
      Dendrogram(levels: list.reverse(new_levels), merge_order: [])
    }
    False -> {
      // Phase 2: Aggregation
      let aggregated = internal.phase2_aggregate(graph, new_state.assignments)

      // Rebuild state and continue
      let aggregated_state = internal.rebuild_state(aggregated)

      do_louvain_hierarchical_recursive(
        aggregated,
        aggregated_state,
        new_levels,
        phase + 1,
        options,
      )
    }
  }
}

fn do_louvain_hierarchical_recursive(
  graph: Graph(Nil, Int),
  state: CommunityState,
  levels: List(Communities),
  phase: Int,
  options: LouvainOptions,
) -> Dendrogram {
  // Phase 1: Local optimization
  let #(improved, new_state) = phase1_local_optimize(graph, state, options)

  // Save current level
  let normalized_assignments =
    internal.normalize_assignments(new_state.assignments)
  let current_communities =
    Communities(
      assignments: normalized_assignments,
      num_communities: internal.count_unique_communities(normalized_assignments),
    )
  let new_levels = [current_communities, ..levels]

  // Check for convergence
  let num_comms = internal.count_unique_communities(new_state.assignments)

  case !improved || phase >= options.max_iterations || num_comms <= 1 {
    True -> {
      // Converged
      Dendrogram(levels: list.reverse(new_levels), merge_order: [])
    }
    False -> {
      // Phase 2: Aggregation
      let aggregated = internal.phase2_aggregate(graph, new_state.assignments)

      // Rebuild state and continue
      let aggregated_state = internal.rebuild_state(aggregated)

      do_louvain_hierarchical_recursive(
        aggregated,
        aggregated_state,
        new_levels,
        phase + 1,
        options,
      )
    }
  }
}

fn phase1_local_optimize(
  graph: Graph(n, Int),
  state: CommunityState,
  options: LouvainOptions,
) -> #(Bool, CommunityState) {
  let nodes = dict.keys(state.assignments)
  do_phase1_iterations(graph, state, nodes, False, 0, options)
}

fn do_phase1_iterations(
  graph: Graph(n, Int),
  state: CommunityState,
  nodes: List(NodeId),
  improved: Bool,
  iteration: Int,
  options: LouvainOptions,
) -> #(Bool, CommunityState) {
  case iteration >= options.max_iterations {
    True -> #(improved, state)
    False -> {
      let #(new_state, local_improved) =
        do_phase1_pass(graph, state, nodes, options)

      case local_improved {
        False -> #(improved, new_state)
        True ->
          do_phase1_iterations(
            graph,
            new_state,
            nodes,
            True,
            iteration + 1,
            options,
          )
      }
    }
  }
}

fn do_phase1_pass(
  graph: Graph(n, Int),
  state: CommunityState,
  nodes: List(NodeId),
  options: LouvainOptions,
) -> #(CommunityState, Bool) {
  // Shuffle nodes for randomization
  let shuffled =
    internal.shuffle(nodes, options.seed + dict.size(state.assignments))

  list.fold(shuffled, #(state, False), fn(acc, node) {
    let #(current_state, _improved) = acc
    let current_comm =
      dict.get(current_state.assignments, node) |> result.unwrap(node)
    let node_weight =
      dict.get(current_state.node_weights, node) |> result.unwrap(0.0)

    // Get neighbor communities and their connection weights to this node
    let neighbor_comms =
      internal.get_neighbor_communities(graph, current_state, node)

    // Find best community
    let #(best_comm, best_gain) =
      list.fold(neighbor_comms, #(current_comm, 0.0), fn(best, neighbor_comm) {
        let #(_best_c, best_g) = best
        let gain =
          internal.calculate_modularity_gain(
            graph,
            node,
            current_comm,
            neighbor_comm,
            node_weight,
            current_state,
          )
        case gain >. best_g {
          True -> #(neighbor_comm, gain)
          False -> best
        }
      })

    case best_gain >. options.min_modularity_gain && best_comm != current_comm {
      True -> {
        // Move node to best community
        let new_state =
          internal.move_node(
            current_state,
            node,
            current_comm,
            best_comm,
            node_weight,
          )
        #(new_state, True)
      }
      False -> acc
    }
  })
}
