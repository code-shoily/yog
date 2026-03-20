//// Leiden method for community detection.
////
//// An improvement over the Louvain algorithm that guarantees well-connected
//// communities. Adds a refinement step to ensure communities are properly
//// connected internally.
////
//// ## Algorithm
////
//// The Leiden method works in three phases that repeat until convergence:
////
//// 1. **Local Optimization** (like Louvain): Nodes move to improve modularity
//// 2. **Refinement**: Partition communities into well-connected sub-communities
//// 3. **Aggregation**: Communities become super-nodes
//// 4. **Repeat** until convergence
////
//// ## Key Differences from Louvain
////
//// | Feature | Louvain | Leiden |
//// |---------|---------|--------|
//// | Speed | Faster | Slightly slower |
//// | Well-connected communities | Not guaranteed | ✓ Guaranteed |
//// | Hierarchical quality | Good | Better |
//// | Disconnected communities | Possible | Prevented |
////
//// ## When to Use
////
//// - When **community quality** matters more than raw speed
//// - When you need **meaningful multi-level structure**
//// - When **disconnected communities** would be problematic
//// - For **hierarchical analysis** requiring well-connected communities at each level
////
//// ## Complexity
////
//// - **Time**: Slightly slower than Louvain (refinement adds overhead)
//// - **Space**: O(V + E) same as Louvain
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/leiden
//// import yog/community/metrics
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])
////
//// // Basic usage
//// let communities = leiden.detect(graph)
//// io.debug(communities.num_communities)
////
//// // With custom options
//// let options = leiden.LeidenOptions(
////   min_modularity_gain: 0.0001,
////   max_iterations: 100,
////   refinement_iterations: 5,
////   seed: 42,
//// )
//// let communities = leiden.detect_with_options(graph, options)
//// ```
////
//// ## References
////
//// - [Traag et al. 2019 - From Louvain to Leiden](https://doi.org/10.1038/s41598-019-41695-z)
//// - [Wikipedia: Leiden Algorithm](https://en.wikipedia.org/wiki/Leiden_algorithm)

import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import yog/community.{type Communities, type Dendrogram, Communities, Dendrogram}
import yog/community/internal.{type CommunityState, CommunityState}
import yog/model.{type Graph, type NodeId}

/// Options for the Leiden algorithm.
pub type LeidenOptions {
  LeidenOptions(
    /// Phase 1: stop when gain < threshold
    min_modularity_gain: Float,
    /// Max iterations per phase
    max_iterations: Int,
    /// Refinement step iterations
    refinement_iterations: Int,
    /// Random seed for tie-breaking
    seed: Int,
  )
}

/// Default options for Leiden algorithm.
pub fn default_options() -> LeidenOptions {
  LeidenOptions(
    min_modularity_gain: 0.000001,
    max_iterations: 100,
    refinement_iterations: 5,
    seed: 42,
  )
}

/// Detects communities using the Leiden algorithm with default options.
pub fn detect(graph: Graph(n, Int)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using the Leiden algorithm with custom options.
pub fn detect_with_options(
  graph: Graph(n, Int),
  options: LeidenOptions,
) -> Communities {
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

  let #(final_state, _) = do_leiden(graph, initial_state, 0, options)

  let normalized_assignments =
    internal.normalize_assignments(final_state.assignments)

  Communities(
    assignments: normalized_assignments,
    num_communities: internal.count_unique_communities(normalized_assignments),
  )
}

/// Full hierarchical Leiden detection.
pub fn detect_hierarchical(graph: Graph(n, Int)) -> Dendrogram {
  detect_hierarchical_with_options(graph, default_options())
}

/// Full hierarchical Leiden detection with custom options.
pub fn detect_hierarchical_with_options(
  graph: Graph(n, Int),
  options: LeidenOptions,
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

  do_leiden_hierarchical(graph, initial_state, [], 0, options)
}

fn do_leiden(
  graph: Graph(n, Int),
  state: CommunityState,
  iteration: Int,
  options: LeidenOptions,
) -> #(CommunityState, Bool) {
  case iteration >= options.max_iterations {
    True -> #(state, False)
    False -> {
      // Phase 1: Local optimization (same as Louvain)
      let #(improved_after_local, state_after_local) =
        phase1_local_optimize(graph, state, options)

      // Phase 1.5: Refinement (key difference from Louvain)
      let state_after_refinement = phase15_refinement(graph, state_after_local)

      // Phase 2: Aggregation
      let aggregated =
        internal.phase2_aggregate(graph, state_after_refinement.assignments)

      // Check for convergence
      let new_num_comms =
        internal.count_unique_communities(state_after_refinement.assignments)
      let old_num_comms = internal.count_unique_communities(state.assignments)

      let converged = new_num_comms == old_num_comms && !improved_after_local

      case converged {
        True -> #(state_after_refinement, False)
        False -> {
          // Rebuild state for aggregated graph and continue with concrete type
          let new_state = internal.rebuild_state(aggregated)
          let #(next_level_state, _) =
            do_leiden_recursive(aggregated, new_state, iteration + 1, options)

          // Compose: map current level nodes to next level communities
          let composed_assignments =
            dict.map_values(
              state_after_refinement.assignments,
              fn(_node, comm_id) {
                dict.get(next_level_state.assignments, comm_id)
                |> result.unwrap(comm_id)
              },
            )

          #(
            CommunityState(
              ..state_after_refinement,
              assignments: composed_assignments,
            ),
            True,
          )
        }
      }
    }
  }
}

fn do_leiden_recursive(
  graph: Graph(Nil, Int),
  state: CommunityState,
  iteration: Int,
  options: LeidenOptions,
) -> #(CommunityState, Bool) {
  case iteration >= options.max_iterations {
    True -> #(state, False)
    False -> {
      // Phase 1: Local optimization (same as Louvain)
      let #(improved_after_local, state_after_local) =
        phase1_local_optimize(graph, state, options)

      // Phase 1.5: Refinement (key difference from Louvain)
      let state_after_refinement = phase15_refinement(graph, state_after_local)

      // Phase 2: Aggregation
      let aggregated =
        internal.phase2_aggregate(graph, state_after_refinement.assignments)

      // Check for convergence
      let new_num_comms =
        internal.count_unique_communities(state_after_refinement.assignments)
      let old_num_comms = internal.count_unique_communities(state.assignments)

      let converged = new_num_comms == old_num_comms && !improved_after_local

      case converged {
        True -> #(state_after_refinement, False)
        False -> {
          // Rebuild state for aggregated graph and continue
          let new_state = internal.rebuild_state(aggregated)
          let #(next_level_state, _) =
            do_leiden_recursive(aggregated, new_state, iteration + 1, options)

          // Compose assignments
          let composed_assignments =
            dict.map_values(
              state_after_refinement.assignments,
              fn(_node, comm_id) {
                dict.get(next_level_state.assignments, comm_id)
                |> result.unwrap(comm_id)
              },
            )

          #(
            CommunityState(
              ..state_after_refinement,
              assignments: composed_assignments,
            ),
            True,
          )
        }
      }
    }
  }
}

fn do_leiden_hierarchical(
  graph: Graph(n, Int),
  state: CommunityState,
  levels: List(Communities),
  iteration: Int,
  options: LeidenOptions,
) -> Dendrogram {
  case iteration >= options.max_iterations {
    True -> Dendrogram(levels: list.reverse(levels), merge_order: [])
    False -> {
      // Phase 1: Local optimization
      let #(improved_after_local, state_after_local) =
        phase1_local_optimize(graph, state, options)

      // Phase 1.5: Refinement
      let state_after_refinement = phase15_refinement(graph, state_after_local)

      // Save current level
      let current_communities =
        Communities(
          assignments: state_after_refinement.assignments,
          num_communities: internal.count_unique_communities(
            state_after_refinement.assignments,
          ),
        )
      let new_levels = [current_communities, ..levels]

      // Check for convergence
      let new_num_comms =
        internal.count_unique_communities(state_after_refinement.assignments)
      let old_num_comms = internal.count_unique_communities(state.assignments)

      let converged =
        new_num_comms == old_num_comms
        && !improved_after_local
        || new_num_comms <= 1

      case converged {
        True -> Dendrogram(levels: list.reverse(new_levels), merge_order: [])
        False -> {
          // Phase 2: Aggregation
          let aggregated =
            internal.phase2_aggregate(graph, state_after_refinement.assignments)

          // Rebuild state and continue
          let new_state = internal.rebuild_state(aggregated)
          do_leiden_hierarchical_recursive(
            aggregated,
            new_state,
            new_levels,
            iteration + 1,
            options,
          )
        }
      }
    }
  }
}

fn do_leiden_hierarchical_recursive(
  graph: Graph(Nil, Int),
  state: CommunityState,
  levels: List(Communities),
  iteration: Int,
  options: LeidenOptions,
) -> Dendrogram {
  case iteration >= options.max_iterations {
    True -> Dendrogram(levels: list.reverse(levels), merge_order: [])
    False -> {
      // Phase 1: Local optimization
      let #(improved_after_local, state_after_local) =
        phase1_local_optimize(graph, state, options)

      // Phase 1.5: Refinement
      let state_after_refinement = phase15_refinement(graph, state_after_local)

      // Save current level
      let current_communities =
        Communities(
          assignments: state_after_refinement.assignments,
          num_communities: internal.count_unique_communities(
            state_after_refinement.assignments,
          ),
        )
      let new_levels = [current_communities, ..levels]

      // Check for convergence
      let new_num_comms =
        internal.count_unique_communities(state_after_refinement.assignments)
      let old_num_comms = internal.count_unique_communities(state.assignments)

      let converged =
        new_num_comms == old_num_comms
        && !improved_after_local
        || new_num_comms <= 1

      case converged {
        True -> Dendrogram(levels: list.reverse(new_levels), merge_order: [])
        False -> {
          // Phase 2: Aggregation
          let aggregated =
            internal.phase2_aggregate(graph, state_after_refinement.assignments)

          // Rebuild state and continue
          let new_state = internal.rebuild_state(aggregated)
          do_leiden_hierarchical_recursive(
            aggregated,
            new_state,
            new_levels,
            iteration + 1,
            options,
          )
        }
      }
    }
  }
}

fn phase1_local_optimize(
  graph: Graph(n, Int),
  state: CommunityState,
  options: LeidenOptions,
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
  options: LeidenOptions,
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
  options: LeidenOptions,
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

    // Get neighbor communities
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

fn phase15_refinement(
  graph: Graph(n, Int),
  state: CommunityState,
) -> CommunityState {
  // Refinement: ensure communities are well-connected
  // For each community, check if it's connected and split if necessary

  let communities = internal.get_community_nodes(state.assignments)

  dict.fold(communities, state, fn(current_state, _comm_id, nodes) {
    case set.size(nodes) <= 1 {
      True -> current_state
      False -> {
        // Check if community is well-connected
        let subgraph = extract_subgraph(graph, nodes)
        let components = find_connected_components(subgraph, nodes)

        case list.length(components) > 1 {
          True -> {
            // Split into connected components
            split_community(current_state, components)
          }
          False -> current_state
        }
      }
    }
  })
}

fn extract_subgraph(
  original: Graph(n, Int),
  nodes: Set(NodeId),
) -> Graph(Nil, Int) {
  let node_list = set.to_list(nodes)
  let subgraph = model.new(model.Undirected)

  // Add nodes with Nil data
  let subgraph_with_nodes =
    list.fold(node_list, subgraph, fn(g, node) { model.add_node(g, node, Nil) })

  // Add edges within the node set
  list.fold(node_list, subgraph_with_nodes, fn(g, u) {
    let successors = model.successors(original, u)
    list.fold(successors, g, fn(g2, edge) {
      let #(v, weight) = edge
      case set.contains(nodes, v) && u < v {
        True -> model.add_edge_ensure(g2, u, v, weight, default: Nil)
        False -> g2
      }
    })
  })
}

fn find_connected_components(
  subgraph: Graph(Nil, Int),
  nodes: Set(NodeId),
) -> List(Set(NodeId)) {
  let node_list = set.to_list(nodes)
  let visited = set.new()

  let #(_, components) =
    list.fold(node_list, #(visited, []), fn(acc, node) {
      let #(visited_acc, comps) = acc
      case set.contains(visited_acc, node) {
        True -> acc
        False -> {
          let component = bfs_component(subgraph, node, visited_acc)
          let new_visited = set.union(visited_acc, component)
          #(new_visited, [component, ..comps])
        }
      }
    })

  components
}

fn bfs_component(
  graph: Graph(Nil, Int),
  start: NodeId,
  initial_visited: Set(NodeId),
) -> Set(NodeId) {
  do_bfs(graph, [start], set.insert(initial_visited, start), set.new())
}

fn do_bfs(
  graph: Graph(Nil, Int),
  queue: List(NodeId),
  visited: Set(NodeId),
  component: Set(NodeId),
) -> Set(NodeId) {
  case queue {
    [] -> component
    [node, ..rest] -> {
      let neighbors =
        model.successors(graph, node)
        |> list.filter_map(fn(edge) {
          let #(n, _) = edge
          case set.contains(visited, n) {
            True -> Error(Nil)
            False -> Ok(n)
          }
        })

      let new_visited =
        list.fold(neighbors, visited, fn(v, n) { set.insert(v, n) })

      let new_component = set.insert(component, node)
      let new_queue = list.append(rest, neighbors)

      do_bfs(graph, new_queue, new_visited, new_component)
    }
  }
}

fn split_community(
  state: CommunityState,
  components: List(Set(NodeId)),
) -> CommunityState {
  case components {
    [] | [_] -> state
    _ -> {
      // Get max community ID
      let max_comm_id =
        state.assignments
        |> dict.values
        |> list.fold(0, int.max)

      // Assign new IDs to all components except first
      let #(new_assignments, _) =
        list.index_fold(
          components,
          #(state.assignments, max_comm_id + 1),
          fn(acc, component, idx) {
            let #(assigns, next_id) = acc
            case idx {
              0 -> {
                // First component keeps current assignments
                acc
              }
              _ -> {
                // Other components get new IDs
                let new_assigns =
                  set.fold(component, assigns, fn(a, node) {
                    dict.insert(a, node, next_id)
                  })
                #(new_assigns, next_id + 1)
              }
            }
          },
        )

      // Recalculate community totals
      let new_totals =
        internal.calculate_community_totals(new_assignments, state.node_weights)

      CommunityState(
        ..state,
        assignments: new_assignments,
        community_totals: new_totals,
      )
    }
  }
}
