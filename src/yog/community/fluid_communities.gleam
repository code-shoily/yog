//// Asynchronous Fluid Communities detection algorithm.
////
//// This algorithm is based on the simple idea of fluids interacting and expanding
//// in a graph environment. It is unique in that it allows specifying exactly
//// the number of communities `k` to find.
////
//// The algorithm starts with `k` randomly placed fluids (seeds). Each fluid
//// has a density that decreases as the community grows. Nodes iteratively
//// update their community to match the fluid with the highest density in their
//// neighborhood. The process completes when no node changes its community.
////
//// ## Example
////
//// ```gleam
//// import yog/community/fluid_communities
////
//// // Find exactly 4 communities
//// let options = fluid_communities.FluidOptions(
////   target_communities: 4,
////   max_iterations: 100,
////   seed: Some(42)
//// )
//// let communities = fluid_communities.detect_with_options(graph, options)
//// ```
////
//// ## References
////
//// - Parés, F., et al. (2017). Fluid Communities: A Competitive, Scalable and Diverse Community Detection Algorithm.

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import yog/community.{type Communities, type CommunityId, Communities}
import yog/community/internal
import yog/model.{type Graph, type NodeId}

/// Options for the Fluid Communities algorithm.
pub type FluidOptions {
  FluidOptions(
    /// Exact number of communities to partition the graph into.
    target_communities: Int,
    /// Maximum number of propagation iterations.
    max_iterations: Int,
    /// Seed for the random number generator (vital for consistent results
    /// due to random processing order and seed selection).
    seed: Option(Int),
  )
}

/// Default options: target 2 communities, max 100 iterations, random seed.
pub fn default_options() -> FluidOptions {
  FluidOptions(target_communities: 2, max_iterations: 100, seed: None)
}

/// Detects `k` communities on an unweighted graph. Default `k = 2`.
pub fn detect(graph: Graph(n, e)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using specific options.
pub fn detect_with_options(
  graph: Graph(n, e),
  options: FluidOptions,
) -> Communities {
  detect_with_weights(graph, options, fn(_) { 1.0 })
}

/// Detects communities using specific options and a given weight function.
pub fn detect_with_weights(
  graph: Graph(n, e),
  options: FluidOptions,
  weight_fn: fn(e) -> Float,
) -> Communities {
  let all_nodes = dict.keys(graph.nodes)
  let k =
    int.max(1, int.min(options.target_communities, list.length(all_nodes)))

  case k {
    0 -> Communities(assignments: dict.new(), num_communities: 0)
    1 ->
      Communities(
        assignments: list.fold(all_nodes, dict.new(), fn(acc, n) {
          dict.insert(acc, n, 0)
        }),
        num_communities: 1,
      )
    _ -> {
      // Initialize random generator
      let rng_seed = option.unwrap(options.seed, 12_345)

      // Select k initial nodes
      let shuffled_nodes = internal.shuffle(all_nodes, rng_seed)
      let initial_nodes = list.take(shuffled_nodes, k)

      // Initialize assignments and sizes
      let #(assignments, sizes) =
        list.index_fold(
          initial_nodes,
          #(dict.new(), dict.new()),
          fn(acc, node, i) {
            let #(asgn, sz) = acc
            #(dict.insert(asgn, node, i), dict.insert(sz, i, 1))
          },
        )

      do_fluid(
        graph,
        all_nodes,
        assignments,
        sizes,
        options.max_iterations,
        rng_seed + 1,
        weight_fn,
      )
    }
  }
}

fn do_fluid(
  graph: Graph(n, e),
  nodes: List(NodeId),
  assignments: Dict(NodeId, CommunityId),
  sizes: Dict(CommunityId, Int),
  iters: Int,
  seed: Int,
  weight_fn: fn(e) -> Float,
) -> Communities {
  case iters <= 0 {
    True -> normalize_communities(assignments, sizes)
    False -> {
      let shuffled = internal.shuffle(nodes, seed)
      let next_seed = seed + 1

      let #(new_assignments, new_sizes, changed, final_seed) =
        list.fold(
          shuffled,
          #(assignments, sizes, False, next_seed),
          fn(acc, node) {
            let #(curr_asgn, curr_sizes, has_changed, current_seed) = acc

            let current_com = dict.get(curr_asgn, node)

            // If node is currently assigned and its community has size 1, it cannot move
            // to prevent the community from dying out.
            let can_move = case current_com {
              Ok(c) -> {
                case dict.get(curr_sizes, c) {
                  Ok(s) if s <= 1 -> False
                  _ -> True
                }
              }
              Error(Nil) -> True
            }

            case can_move {
              False -> acc
              // Keep current state
              True -> {
                // Calculate density sums for neighbors
                let density_sums =
                  list.fold(
                    model.successors(graph, node),
                    dict.new(),
                    fn(densities, neighbor_rel) {
                      let #(neighbor_id, w) = neighbor_rel
                      case dict.get(curr_asgn, neighbor_id) {
                        Ok(neighbor_com) -> {
                          let com_size =
                            dict.get(curr_sizes, neighbor_com)
                            |> result.unwrap(1)
                          // Fluid density definition = 1 / size
                          let density = weight_fn(w) /. int.to_float(com_size)

                          let existing =
                            dict.get(densities, neighbor_com)
                            |> result.unwrap(0.0)
                          dict.insert(
                            densities,
                            neighbor_com,
                            existing +. density,
                          )
                        }
                        Error(Nil) -> densities
                        // Unassigned neighbors contribute nothing
                      }
                    },
                  )

                case dict.size(density_sums) == 0 {
                  // No assigned neighbors, remain as is
                  True -> acc
                  False -> {
                    // Find communities with max density sum
                    let max_items =
                      dict.fold(
                        density_sums,
                        #([], -1.0),
                        fn(max_acc, c, d_sum) {
                          let #(best_coms, max_d) = max_acc
                          case d_sum >. max_d {
                            True -> #([c], d_sum)
                            False ->
                              case d_sum == max_d {
                                True -> #([c, ..best_coms], max_d)
                                False -> max_acc
                              }
                          }
                        },
                      )

                    // Tie breaking
                    let best_com_candidates = max_items.0
                    let #(best_c, new_seed) = case best_com_candidates {
                      [single] -> #(single, current_seed)
                      multi -> {
                        let r =
                          { 1_103_515_245 * current_seed + 12_345 }
                          % 2_147_483_648
                        // handle negative modulo
                        let r_pos = case r < 0 {
                          True -> r * -1
                          False -> r
                        }
                        let idx = r_pos % list.length(multi)
                        let chosen =
                          list.drop(multi, idx)
                          |> list.first
                          |> result.unwrap(0)
                        #(chosen, current_seed + 1)
                      }
                    }

                    let changing = case current_com {
                      Ok(c) -> c != best_c
                      Error(Nil) -> True
                    }

                    case changing {
                      False -> #(curr_asgn, curr_sizes, has_changed, new_seed)
                      True -> {
                        // Perform the move
                        let next_asgn = dict.insert(curr_asgn, node, best_c)

                        // Decrease size of old community if it had one
                        let temp_sizes = case current_com {
                          Ok(old_c) -> {
                            let old_size =
                              dict.get(curr_sizes, old_c) |> result.unwrap(1)
                            dict.insert(curr_sizes, old_c, old_size - 1)
                          }
                          Error(Nil) -> curr_sizes
                        }

                        // Increase size of new community
                        let best_c_size =
                          dict.get(temp_sizes, best_c) |> result.unwrap(0)
                        let next_sizes =
                          dict.insert(temp_sizes, best_c, best_c_size + 1)

                        #(next_asgn, next_sizes, True, new_seed)
                      }
                    }
                  }
                }
              }
            }
          },
        )

      case changed {
        False -> normalize_communities(new_assignments, new_sizes)
        True ->
          do_fluid(
            graph,
            nodes,
            new_assignments,
            new_sizes,
            iters - 1,
            final_seed,
            weight_fn,
          )
      }
    }
  }
}

fn normalize_communities(
  assignments: Dict(NodeId, CommunityId),
  sizes: Dict(CommunityId, Int),
) -> Communities {
  // Re-index community IDs to be contiguous from 0 to actual_k - 1
  let active_communities =
    dict.filter(sizes, fn(_, size) { size > 0 })
    |> dict.keys
    |> list.sort(int.compare)

  let mapping =
    list.index_fold(active_communities, dict.new(), fn(acc, old_id, i) {
      dict.insert(acc, old_id, i)
    })

  let new_assignments =
    dict.fold(assignments, dict.new(), fn(acc, node, old_id) {
      let new_id = dict.get(mapping, old_id) |> result.unwrap(0)
      dict.insert(acc, node, new_id)
    })

  Communities(assignments: new_assignments, num_communities: dict.size(mapping))
}
