import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}

/// Represents a partition of a bipartite graph into two independent sets.
/// In a bipartite graph, all edges connect vertices from `left` to `right`,
/// with no edges within `left` or within `right`.
pub type Partition {
  Partition(left: Set(NodeId), right: Set(NodeId))
}

/// Checks if a graph is bipartite (2-colorable).
///
/// A graph is bipartite if its vertices can be divided into two disjoint sets
/// such that every edge connects a vertex in one set to a vertex in the other set.
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_node(4, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///
/// bipartite.is_bipartite(graph)  // => True (can color as: 1,3 vs 2,4)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn is_bipartite(graph: Graph(n, e)) -> Bool {
  case partition(graph) {
    Some(_) -> True
    None -> False
  }
}

/// Returns the two partitions of a bipartite graph, or None if the graph is not bipartite.
///
/// Uses BFS with 2-coloring to detect bipartiteness and construct the partitions.
/// Handles disconnected graphs by checking all components.
///
/// ## Example
/// ```gleam
/// case bipartite.partition(graph) {
///   Some(Partition(left, right)) -> {
///     // left and right are the two independent sets
///     io.println("Graph is bipartite!")
///   }
///   None -> io.println("Graph is not bipartite")
/// }
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn partition(graph: Graph(n, e)) -> Option(Partition) {
  let nodes = dict.keys(graph.nodes)

  let initial_colors = dict.new()

  case color_graph(graph, nodes, initial_colors) {
    None -> None
    Some(colors) -> {
      // Split nodes by color
      let #(left, right) =
        dict.fold(colors, #(set.new(), set.new()), fn(acc, node, color) {
          let #(left_set, right_set) = acc
          case color {
            True -> #(set.insert(left_set, node), right_set)
            False -> #(left_set, set.insert(right_set, node))
          }
        })

      Some(Partition(left: left, right: right))
    }
  }
}

/// Finds a maximum matching in a bipartite graph.
///
/// A matching is a set of edges with no common vertices. A maximum matching
/// has the largest possible number of edges.
///
/// Uses the augmenting path algorithm (also known as the Hungarian algorithm
/// for unweighted bipartite matching).
///
/// Returns a list of matched pairs `#(left_node, right_node)`.
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)  // left
///   |> yog.add_node(2, Nil)  // left
///   |> yog.add_node(3, Nil)  // right
///   |> yog.add_node(4, Nil)  // right
///   |> yog.add_edge(from: 1, to: 3, with: 1)
///   |> yog.add_edge(from: 1, to: 4, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// case bipartite.partition(graph) {
///   Some(p) -> {
///     let matching = bipartite.maximum_matching(graph, p)
///     // => [#(1, 3), #(2, 4)] or [#(1, 4), #(2, 3)]
///   }
///   None -> panic as "Not bipartite"
/// }
/// ```
///
/// **Time Complexity:** O(V * E)
pub fn maximum_matching(
  graph: Graph(n, e),
  partition: Partition,
) -> List(#(NodeId, NodeId)) {
  // Start with empty matching
  let matching = Matching(left_to_right: dict.new(), right_to_left: dict.new())

  // Try to find augmenting path from each left vertex
  let left_list = set.to_list(partition.left)
  let final_matching =
    list.fold(left_list, matching, fn(current_matching, left_node) {
      let visited = set.new()
      case
        find_augmenting_path(
          graph,
          left_node,
          partition,
          current_matching,
          visited,
        )
      {
        None -> current_matching
        Some(updated_matching) -> updated_matching
      }
    })

  dict.fold(final_matching.left_to_right, [], fn(acc, left, right) {
    [#(left, right), ..acc]
  })
}

type Matching {
  Matching(
    left_to_right: Dict(NodeId, NodeId),
    right_to_left: Dict(NodeId, NodeId),
  )
}

// ============= Helper Functions =============

// Color the graph using BFS, returns None if graph is not bipartite
fn color_graph(
  graph: Graph(n, e),
  remaining_nodes: List(NodeId),
  colors: Dict(NodeId, Bool),
) -> Option(Dict(NodeId, Bool)) {
  case remaining_nodes {
    [] -> Some(colors)
    [node, ..rest] -> {
      case dict.has_key(colors, node) {
        True -> color_graph(graph, rest, colors)
        False -> {
          case bfs_color(graph, node, True, colors) {
            None -> None
            Some(updated_colors) -> color_graph(graph, rest, updated_colors)
          }
        }
      }
    }
  }
}

// BFS coloring from a single starting node
fn bfs_color(
  graph: Graph(n, e),
  start: NodeId,
  start_color: Bool,
  colors: Dict(NodeId, Bool),
) -> Option(Dict(NodeId, Bool)) {
  let queue = [#(start, start_color)]
  do_bfs_color(graph, queue, colors)
}

fn do_bfs_color(
  graph: Graph(n, e),
  queue: List(#(NodeId, Bool)),
  colors: Dict(NodeId, Bool),
) -> Option(Dict(NodeId, Bool)) {
  case queue {
    [] -> Some(colors)
    [#(node, color), ..rest] -> {
      case dict.get(colors, node) {
        Ok(existing_color) -> {
          case existing_color == color {
            True -> do_bfs_color(graph, rest, colors)
            False -> None
          }
        }
        Error(_) -> {
          let new_colors = dict.insert(colors, node, color)

          let neighbors = get_neighbors(graph, node)
          let next_color = !color
          let new_queue =
            list.fold(neighbors, rest, fn(q, neighbor) {
              [#(neighbor, next_color), ..q]
            })

          do_bfs_color(graph, new_queue, new_colors)
        }
      }
    }
  }
}

fn get_neighbors(graph: Graph(n, e), node: NodeId) -> List(NodeId) {
  case graph.kind {
    model.Undirected -> {
      case dict.get(graph.out_edges, node) {
        Error(_) -> []
        Ok(neighbors) -> dict.keys(neighbors)
      }
    }
    model.Directed -> {
      let out_neighbors = case dict.get(graph.out_edges, node) {
        Error(_) -> []
        Ok(neighbors) -> dict.keys(neighbors)
      }
      let in_neighbors = case dict.get(graph.in_edges, node) {
        Error(_) -> []
        Ok(neighbors) -> dict.keys(neighbors)
      }
      list.append(out_neighbors, in_neighbors)
      |> list.unique()
    }
  }
}

// Find an augmenting path from a left vertex using DFS
// Returns updated matching if path found
fn find_augmenting_path(
  graph: Graph(n, e),
  left_node: NodeId,
  partition: Partition,
  matching: Matching,
  visited: Set(NodeId),
) -> Option(Matching) {
  case dict.has_key(matching.left_to_right, left_node) {
    True -> None
    False -> {
      let right_neighbors =
        get_neighbors(graph, left_node)
        |> list.filter(fn(n) { set.contains(partition.right, n) })

      try_neighbors(
        graph,
        left_node,
        right_neighbors,
        partition,
        matching,
        visited,
      )
    }
  }
}

fn try_neighbors(
  graph: Graph(n, e),
  left_node: NodeId,
  right_neighbors: List(NodeId),
  partition: Partition,
  matching: Matching,
  visited: Set(NodeId),
) -> Option(Matching) {
  case right_neighbors {
    [] -> None
    [right_node, ..rest] -> {
      case set.contains(visited, right_node) {
        True ->
          try_neighbors(graph, left_node, rest, partition, matching, visited)
        False -> {
          let new_visited = set.insert(visited, right_node)

          case dict.get(matching.right_to_left, right_node) {
            Error(_) -> {
              Some(Matching(
                left_to_right: dict.insert(
                  matching.left_to_right,
                  left_node,
                  right_node,
                ),
                right_to_left: dict.insert(
                  matching.right_to_left,
                  right_node,
                  left_node,
                ),
              ))
            }
            Ok(matched_left) -> {
              case
                find_augmenting_path(
                  graph,
                  matched_left,
                  partition,
                  Matching(
                    left_to_right: dict.delete(
                      matching.left_to_right,
                      matched_left,
                    ),
                    right_to_left: dict.delete(
                      matching.right_to_left,
                      right_node,
                    ),
                  ),
                  new_visited,
                )
              {
                None ->
                  try_neighbors(
                    graph,
                    left_node,
                    rest,
                    partition,
                    matching,
                    visited,
                  )
                Some(updated_matching) -> {
                  Some(Matching(
                    left_to_right: dict.insert(
                      updated_matching.left_to_right,
                      left_node,
                      right_node,
                    ),
                    right_to_left: dict.insert(
                      updated_matching.right_to_left,
                      right_node,
                      left_node,
                    ),
                  ))
                }
              }
            }
          }
        }
      }
    }
  }
}

// ============= Stable Marriage Problem =============

/// Result of the stable marriage algorithm.
///
/// Contains the matched pairs and allows querying the partner of any person.
pub type StableMarriage {
  StableMarriage(matches: Dict(NodeId, NodeId))
}

/// Finds a stable matching given preference lists for two groups.
///
/// Uses the Gale-Shapley algorithm to find a stable matching where no two people
/// would both prefer each other over their current partners.
///
/// The algorithm is "proposer-optimal" - it finds the best stable matching for
/// the proposing group (left), and the worst stable matching for the receiving
/// group (right).
///
/// ## Parameters
///
/// - `left_prefs` - Dict mapping each left person to their preference list (most preferred first)
/// - `right_prefs` - Dict mapping each right person to their preference list (most preferred first)
///
/// ## Returns
///
/// A `StableMarriage` containing the matched pairs. Use `get_partner()` to query matches.
///
/// ## Example
///
/// ```gleam
/// // Medical residency matching
/// let residents = dict.from_list([
///   #(1, [101, 102, 103]),  // Resident 1 prefers hospitals 101, 102, 103
///   #(2, [102, 101, 103]),
///   #(3, [101, 103, 102]),
/// ])
///
/// let hospitals = dict.from_list([
///   #(101, [1, 2, 3]),      // Hospital 101 prefers residents 1, 2, 3
///   #(102, [2, 1, 3]),
///   #(103, [1, 2, 3]),
/// ])
///
/// let matching = bipartite.stable_marriage(residents, hospitals)
/// case get_partner(matching, 1) {
///   Some(hospital) -> io.println("Resident 1 matched to hospital " <> int.to_string(hospital))
///   None -> io.println("Resident 1 unmatched")
/// }
/// ```
///
/// ## Properties
///
/// - **Stable:** No two people would both prefer each other over their current partners
/// - **Complete:** Everyone is matched (if groups are equal size)
/// - **Optimal for proposers:** Left group gets best stable matching possible
/// - **Pessimal for receivers:** Right group gets worst stable matching possible
///
/// **Time Complexity:** O(n²) where n is the size of each group
///
/// ## Use Cases
///
/// - Medical residency matching (NRMP)
/// - College admissions
/// - Job assignments
/// - Roommate pairing
/// - Task allocation
pub fn stable_marriage(
  left_prefs: Dict(NodeId, List(NodeId)),
  right_prefs: Dict(NodeId, List(NodeId)),
) -> StableMarriage {
  // Build ranking maps for O(1) preference lookups
  let right_rankings = build_rankings(right_prefs)

  // Initialize: all left people are free, all right people are unmatched
  // Sort keys for deterministic proposal order
  let free_left =
    dict.to_list(left_prefs)
    |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
    |> list.map(fn(pair) { pair.0 })
  let matches = dict.new()
  let next_proposal = dict.new()

  let final_matches =
    gale_shapley(free_left, left_prefs, right_rankings, matches, next_proposal)

  StableMarriage(matches: final_matches)
}

/// Get the partner of a person in a stable matching.
///
/// Returns `Some(partner)` if the person is matched, `None` otherwise.
pub fn get_partner(marriage: StableMarriage, person: NodeId) -> Option(NodeId) {
  dict.get(marriage.matches, person)
  |> option.from_result()
}

// Build ranking map: for each right person, map their preferences to ranks (0, 1, 2, ...)
// This allows O(1) comparison of preferences
fn build_rankings(
  prefs: Dict(NodeId, List(NodeId)),
) -> Dict(NodeId, Dict(NodeId, Int)) {
  dict.fold(prefs, dict.new(), fn(rankings, person, pref_list) {
    let ranking =
      list.index_fold(pref_list, dict.new(), fn(rank_map, candidate, index) {
        dict.insert(rank_map, candidate, index)
      })
    dict.insert(rankings, person, ranking)
  })
}

// Gale-Shapley algorithm main loop
fn gale_shapley(
  free_left: List(NodeId),
  left_prefs: Dict(NodeId, List(NodeId)),
  right_rankings: Dict(NodeId, Dict(NodeId, Int)),
  matches: Dict(NodeId, NodeId),
  next_proposal: Dict(NodeId, Int),
) -> Dict(NodeId, NodeId) {
  case free_left {
    [] -> matches
    [proposer, ..rest_free] -> {
      // Get proposer's preference list
      let pref_list = dict.get(left_prefs, proposer) |> result.unwrap([])

      // Get index of next person to propose to
      let proposal_index = dict.get(next_proposal, proposer) |> result.unwrap(0)

      case list.drop(pref_list, proposal_index) {
        [] ->
          gale_shapley(
            rest_free,
            left_prefs,
            right_rankings,
            matches,
            next_proposal,
          )
        [receiver, ..] -> {
          // Update next proposal index
          let updated_next =
            dict.insert(next_proposal, proposer, proposal_index + 1)

          // Check if receiver is currently matched
          case get_current_match(matches, receiver) {
            None -> {
              // Receiver is free, accept proposal
              let new_matches =
                matches
                |> dict.insert(proposer, receiver)
                |> dict.insert(receiver, proposer)

              gale_shapley(
                rest_free,
                left_prefs,
                right_rankings,
                new_matches,
                updated_next,
              )
            }
            Some(current_partner) -> {
              // Receiver is matched, check if they prefer proposer
              case
                prefers(right_rankings, receiver, proposer, current_partner)
              {
                True -> {
                  // Receiver prefers proposer, switch partners
                  let new_matches =
                    matches
                    |> dict.delete(current_partner)
                    |> dict.insert(proposer, receiver)
                    |> dict.insert(receiver, proposer)

                  // Current partner becomes free
                  let new_free = [current_partner, ..rest_free]

                  gale_shapley(
                    new_free,
                    left_prefs,
                    right_rankings,
                    new_matches,
                    updated_next,
                  )
                }
                False -> {
                  // Receiver rejects proposer, proposer stays free
                  gale_shapley(
                    [proposer, ..rest_free],
                    left_prefs,
                    right_rankings,
                    matches,
                    updated_next,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
}

// Get the current match for a person (considering bidirectional matching)
fn get_current_match(
  matches: Dict(NodeId, NodeId),
  person: NodeId,
) -> Option(NodeId) {
  dict.get(matches, person)
  |> option.from_result()
}

// Check if receiver prefers proposer over current_partner using ranking map
fn prefers(
  rankings: Dict(NodeId, Dict(NodeId, Int)),
  receiver: NodeId,
  proposer: NodeId,
  current_partner: NodeId,
) -> Bool {
  case dict.get(rankings, receiver) {
    Error(_) -> False
    Ok(receiver_ranking) -> {
      let proposer_rank =
        dict.get(receiver_ranking, proposer) |> result.unwrap(999_999)
      let current_rank =
        dict.get(receiver_ranking, current_partner) |> result.unwrap(999_999)

      proposer_rank < current_rank
    }
  }
}
