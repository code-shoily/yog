//// Centrality measures for identifying important nodes in graphs.
////
//// Provides degree, closeness, harmonic, betweenness, and PageRank centrality.
//// All functions return a Dict(NodeId, Float) mapping nodes to their scores.
////
//// ## Overview
////
//// | Measure | Function | Best For |
//// |---------|----------|----------|
//// | Degree | `degree/2` | Local connectivity |
//// | Closeness | `closeness/5` | Distance to all others |
//// | Harmonic | `harmonic_centrality/5` | Disconnected graphs |
//// | Betweenness | `betweenness/5` | Bridge/gatekeeper detection |
//// | PageRank | `pagerank/2` | Link-quality importance |

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/order.{type Order, Gt}
import gleam/result
import yog/internal/priority_queue as pq
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding/dijkstra

/// A mapping of Node IDs to their calculated centrality scores.
pub type Centrality =
  Dict(NodeId, Float)

/// Specifies which edges to consider for directed graphs.
pub type DegreeMode {
  /// Consider only incoming edges (Prestige).
  InDegree
  /// Consider only outgoing edges (Gregariousness).
  OutDegree
  /// Consider both incoming and outgoing edges.
  TotalDegree
}

/// Calculates the Degree Centrality for all nodes in the graph.
/// 
/// For directed graphs, use `mode` to specify which edges to count.
/// For undirected graphs, the `mode` is ignored.
pub fn degree(graph: Graph(n, e), mode: DegreeMode) -> Centrality {
  let n = model.order(graph)
  let nodes = model.all_nodes(graph)

  let factor = case n > 1 {
    True -> int.to_float(n - 1)
    False -> 1.0
  }

  list.fold(nodes, dict.new(), fn(acc, id) {
    let count = case graph.kind {
      Undirected -> list.length(model.neighbors(graph, id))
      Directed ->
        case mode {
          InDegree -> list.length(model.predecessors(graph, id))
          OutDegree -> list.length(model.successors(graph, id))
          TotalDegree ->
            list.length(model.successors(graph, id))
            + list.length(model.predecessors(graph, id))
        }
    }
    dict.insert(acc, id, int.to_float(count) /. factor)
  })
}

/// Calculates Closeness Centrality for all nodes.
///
/// Closeness centrality measures how close a node is to all other nodes
/// in the graph. It is calculated as the reciprocal of the sum of the
/// shortest path distances from the node to all other nodes.
///
/// Formula: C(v) = (n - 1) / Σ d(v, u) for all u ≠ v
///
/// Note: In disconnected graphs, nodes that cannot reach all other nodes
/// will have a centrality of 0.0. Consider harmonic_centrality for 
/// disconnected graphs.
///
/// **Time Complexity:** O(V * (V + E) log V) using Dijkstra from each node
///
/// ## Parameters
///
/// - `zero`: The identity element for distances (e.g., 0 for integers)
/// - `add`: Function to add two distances
/// - `compare`: Function to compare two distances
/// - `to_float`: Function to convert distance type to Float for final score
///
/// ## Example
///
/// ```gleam
/// centrality.closeness(
///   graph,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   with_to_float: int.to_float,
/// )
/// // => dict.from_list([#(1, 0.666), #(2, 1.0), #(3, 0.666)])
/// ```
pub fn closeness(
  graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_to_float to_float: fn(e) -> Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n <= 1 {
    True ->
      list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, 0.0) })
    False -> {
      list.fold(nodes, dict.new(), fn(acc, source) {
        let distances =
          dijkstra.single_source_distances(
            in: graph,
            from: source,
            with_zero: zero,
            with_add: add,
            with_compare: compare,
          )

        case dict.size(distances) == n {
          False -> {
            dict.insert(acc, source, 0.0)
          }
          True -> {
            // Sum all distances (including 0 for self, which doesn't affect sum)
            let total_distance =
              dict.fold(distances, zero, fn(sum, _node, dist) { add(sum, dist) })

            // Calculate closeness: (n-1) / sum_of_distances_to_others
            // Note: total_distance includes 0 for self, so it's just sum to others
            let centrality_score =
              int.to_float(n - 1) /. to_float(total_distance)

            dict.insert(acc, source, centrality_score)
          }
        }
      })
    }
  }
}

/// Calculates Harmonic Centrality for all nodes.
///
/// Harmonic centrality is a variation of closeness centrality that handles
/// disconnected graphs gracefully. It sums the reciprocals of the shortest 
/// path distances from a node to all other reachable nodes.
///
/// Formula: H(v) = Σ (1 / d(v, u)) / (n - 1) for all u ≠ v
///
/// **Time Complexity:** O(V * (V + E) log V)
pub fn harmonic_centrality(
  graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_to_float to_float: fn(e) -> Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n <= 1 {
    True ->
      list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, 0.0) })
    False -> {
      let denominator = int.to_float(n - 1)

      list.fold(nodes, dict.new(), fn(acc, source) {
        let distances =
          dijkstra.single_source_distances(
            in: graph,
            from: source,
            with_zero: zero,
            with_add: add,
            with_compare: compare,
          )

        let sum_of_reciprocals =
          dict.fold(distances, 0.0, fn(sum, node, dist) {
            case node == source {
              True -> sum
              False -> {
                let d = to_float(dist)
                // Avoid division by zero if an edge weight is 0
                case d >. 0.0 {
                  True -> sum +. { 1.0 /. d }
                  False -> sum
                }
              }
            }
          })

        dict.insert(acc, source, sum_of_reciprocals /. denominator)
      })
    }
  }
}

/// Calculates Betweenness Centrality for all nodes.
/// 
/// Betweenness centrality of a node v is the sum of the fraction of 
/// all-pairs shortest paths that pass through v.
///
/// **Time Complexity:** O(VE) for unweighted, O(VE + V²logV) for weighted.
pub fn betweenness(
  graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_to_float _to_float: fn(e) -> Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let initial =
    list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, 0.0) })

  let scores =
    list.fold(nodes, initial, fn(acc, s) {
      let discovery = run_discovery(graph, s, zero, add, compare)
      let dependencies = run_accumulation(discovery)

      merge_scores(acc, dependencies, s)
    })

  apply_undirected_scaling(scores, graph.kind)
}

type BrandesDiscovery =
  #(List(NodeId), Dict(NodeId, List(NodeId)), Dict(NodeId, Int))

fn run_discovery(
  graph: Graph(n, e),
  source: NodeId,
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> BrandesDiscovery {
  let queue =
    pq.new(fn(a: #(e, NodeId), b: #(e, NodeId)) { compare(a.0, b.0) })
    |> pq.push(#(zero, source))

  let dists = dict.from_list([#(source, zero)])
  let sigmas = dict.from_list([#(source, 1)])
  let preds = dict.new()
  let stack = []

  do_brandes_dijkstra(graph, queue, dists, sigmas, preds, stack, add, compare)
}

fn do_brandes_dijkstra(
  graph: Graph(n, e),
  queue: pq.Queue(#(e, NodeId)),
  dists: Dict(NodeId, e),
  sigmas: Dict(NodeId, Int),
  preds: Dict(NodeId, List(NodeId)),
  stack: List(NodeId),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> BrandesDiscovery {
  case pq.pop(queue) {
    Error(Nil) -> #(stack, preds, sigmas)
    Ok(#(#(d_v, v), rest_q)) -> {
      let current_best = dict.get(dists, v) |> result.unwrap(d_v)
      case compare(d_v, current_best) {
        Gt ->
          do_brandes_dijkstra(
            graph,
            rest_q,
            dists,
            sigmas,
            preds,
            stack,
            add,
            compare,
          )
        _ -> {
          let new_stack = [v, ..stack]

          let #(next_q, next_dists, next_sigmas, next_preds) =
            model.successors(graph, v)
            |> list.fold(#(rest_q, dists, sigmas, preds), fn(state, edge) {
              let #(q, ds, ss, ps) = state
              let #(w, weight) = edge
              let new_dist = add(d_v, weight)

              case dict.get(ds, w) {
                Error(Nil) -> {
                  let q2 = pq.push(q, #(new_dist, w))
                  let ds2 = dict.insert(ds, w, new_dist)
                  let ss2 = dict.insert(ss, w, get_sigma(ss, v))
                  let ps2 = dict.insert(ps, w, [v])
                  #(q2, ds2, ss2, ps2)
                }
                Ok(old_dist) -> {
                  case compare(new_dist, old_dist) {
                    order.Lt -> {
                      let q2 = pq.push(q, #(new_dist, w))
                      let ds2 = dict.insert(ds, w, new_dist)
                      let ss2 = dict.insert(ss, w, get_sigma(ss, v))
                      let ps2 = dict.insert(ps, w, [v])
                      #(q2, ds2, ss2, ps2)
                    }
                    order.Eq -> {
                      let ss2 =
                        dict.upsert(ss, w, fn(curr) {
                          option.unwrap(curr, 0) + get_sigma(ss, v)
                        })
                      let ps2 =
                        dict.upsert(ps, w, fn(curr) {
                          [v, ..option.unwrap(curr, [])]
                        })
                      #(q, ds, ss2, ps2)
                    }
                    order.Gt -> state
                  }
                }
              }
            })

          do_brandes_dijkstra(
            graph,
            next_q,
            next_dists,
            next_sigmas,
            next_preds,
            new_stack,
            add,
            compare,
          )
        }
      }
    }
  }
}

fn get_sigma(sigmas: Dict(NodeId, Int), id: NodeId) -> Int {
  dict.get(sigmas, id) |> result.unwrap(0)
}

fn run_accumulation(discovery: BrandesDiscovery) -> Dict(NodeId, Float) {
  let #(stack, preds, sigmas) = discovery
  accumulate_dependencies(stack, preds, sigmas)
}

fn accumulate_dependencies(
  stack: List(NodeId),
  preds: Dict(NodeId, List(NodeId)),
  sigmas: Dict(NodeId, Int),
) -> Dict(NodeId, Float) {
  let initial_deltas = dict.new()

  list.fold(stack, initial_deltas, fn(deltas, v) {
    let sigma_v = int.to_float(get_sigma(sigmas, v))
    let delta_v = dict.get(deltas, v) |> result.unwrap(0.0)
    let v_preds = dict.get(preds, v) |> result.unwrap([])

    list.fold(v_preds, deltas, fn(acc_deltas, u) {
      let sigma_u = int.to_float(get_sigma(sigmas, u))
      // The core formula: delta[u] += (sigma[u]/sigma[v]) * (1 + delta[v])
      let fraction = sigma_u /. sigma_v *. { 1.0 +. delta_v }
      dict.upsert(acc_deltas, u, fn(curr) {
        option.unwrap(curr, 0.0) +. fraction
      })
    })
  })
}

fn merge_scores(
  acc: Dict(NodeId, Float),
  dependencies: Dict(NodeId, Float),
  source: NodeId,
) -> Dict(NodeId, Float) {
  dict.fold(dependencies, acc, fn(acc2, node, delta) {
    case node == source {
      True -> acc2
      False -> {
        let current = dict.get(acc2, node) |> result.unwrap(0.0)
        dict.insert(acc2, node, current +. delta)
      }
    }
  })
}

fn scale_all(scores: Dict(NodeId, Float), factor: Float) -> Dict(NodeId, Float) {
  dict.map_values(scores, fn(_node, score) { score *. factor })
}

fn apply_undirected_scaling(
  scores: Dict(NodeId, Float),
  kind: model.GraphType,
) -> Dict(NodeId, Float) {
  case kind {
    Undirected -> scale_all(scores, 0.5)
    Directed -> scores
  }
}

/// Configuration options for the PageRank algorithm.
///
/// PageRank models a "random surfer" who follows links with probability
/// `damping` and jumps to a random page with probability `1 - damping`.
///
/// ## Fields
///
/// - `damping`: Probability of continuing to follow links (typically 0.85).
///   Higher values mean the surfer follows more links before random jumping.
/// - `max_iterations`: Maximum iterations before returning current scores.
/// - `tolerance`: Convergence threshold. Algorithm stops when the L1 norm
///   of score changes falls below this value.
///
/// ## Default Options
///
/// Use `default_pagerank_options()` for standard settings:
/// - damping: 0.85
/// - max_iterations: 100
/// - tolerance: 0.0001
pub type PageRankOptions {
  PageRankOptions(damping: Float, max_iterations: Int, tolerance: Float)
}

/// Calculates PageRank centrality for all nodes.
///
/// PageRank measures node importance based on the quality and quantity of
/// incoming links. A node is important if it is linked to by other important
/// nodes. Originally developed for ranking web pages, it's useful for:
///
/// - Ranking nodes in directed networks
/// - Identifying influential nodes in citation networks
/// - Finding important entities in knowledge graphs
/// - Recommendation systems
///
/// The algorithm uses a "random surfer" model: with probability `damping`,
/// the surfer follows a random outgoing link; otherwise, they jump to any
/// random node. This models both link-following behavior and the possibility
/// of starting a new browsing session.
///
/// **Time Complexity:** O(max_iterations × (V + E))
///
/// ## When to Use PageRank
///
/// - **Directed graphs** where link direction matters
/// - When you care about **link quality** (links from important nodes count more)
/// - Citation networks, web graphs, recommendation systems
///
/// For undirected graphs, consider `eigenvector/3` instead.
///
/// ## Example
///
/// ```gleam
/// // Use default options (recommended for most cases)
/// let options = centrality.default_pagerank_options()
/// let scores = centrality.pagerank(graph, options)
/// // => dict.from_list([#(1, 0.256), #(2, 0.488), #(3, 0.256)])
///
/// // Custom options for faster convergence or different damping
/// let custom = centrality.PageRankOptions(
///   damping: 0.9,        // Follow more links before jumping
///   max_iterations: 50,  // Faster but less precise
///   tolerance: 0.001,    // Less strict convergence
/// )
/// let scores = centrality.pagerank(graph, custom)
/// ```
pub fn pagerank(graph: Graph(n, e), options: PageRankOptions) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)
  let initial_rank = 1.0 /. int.to_float(n)

  let ranks =
    list.fold(nodes, dict.new(), fn(acc, id) {
      dict.insert(acc, id, initial_rank)
    })

  iterate_pagerank(graph, ranks, nodes, n, options, 0)
}

fn iterate_pagerank(
  graph: Graph(n, e),
  ranks: Dict(NodeId, Float),
  nodes: List(NodeId),
  n: Int,
  options: PageRankOptions,
  iteration: Int,
) -> Centrality {
  case iteration >= options.max_iterations {
    True -> ranks
    False -> {
      let damping = options.damping
      let n_float = int.to_float(n)

      let sink_sum = calculate_sink_sum(graph, ranks, nodes, n_float)

      let new_ranks =
        list.fold(nodes, dict.new(), fn(acc, node) {
          let in_neighbors = get_in_neighbors(graph, node)
          let rank_sum =
            list.fold(in_neighbors, 0.0, fn(sum, neighbor) {
              let neighbor_rank =
                dict.get(ranks, neighbor) |> result.unwrap(0.0)
              let out_degree = get_out_degree(graph, neighbor)
              case out_degree > 0 {
                True -> sum +. neighbor_rank /. int.to_float(out_degree)
                False -> sum
              }
            })

          let new_rank =
            { 1.0 -. damping } /. n_float +. damping *. { sink_sum +. rank_sum }

          dict.insert(acc, node, new_rank)
        })

      let l1_norm = calculate_l1_norm(ranks, new_ranks, nodes)

      case l1_norm <. options.tolerance {
        True -> new_ranks
        False ->
          iterate_pagerank(graph, new_ranks, nodes, n, options, iteration + 1)
      }
    }
  }
}

fn calculate_sink_sum(
  graph: Graph(n, e),
  ranks: Dict(NodeId, Float),
  nodes: List(NodeId),
  n_float: Float,
) -> Float {
  list.fold(nodes, 0.0, fn(sum, node) {
    let out_degree = get_out_degree(graph, node)
    case out_degree == 0 {
      True -> {
        let node_rank = dict.get(ranks, node) |> result.unwrap(0.0)
        sum +. node_rank /. n_float
      }
      False -> sum
    }
  })
}

fn get_in_neighbors(graph: Graph(n, e), node: NodeId) -> List(NodeId) {
  case graph.kind {
    Undirected -> {
      model.successors(graph, node)
      |> list.map(fn(edge) { edge.0 })
    }
    Directed -> {
      model.predecessors(graph, node)
      |> list.map(fn(edge) { edge.0 })
    }
  }
}

fn get_out_degree(graph: Graph(n, e), node: NodeId) -> Int {
  case graph.kind {
    Undirected -> {
      model.neighbors(graph, node)
      |> list.length()
    }
    Directed -> {
      model.successors(graph, node)
      |> list.length()
    }
  }
}

fn calculate_l1_norm(
  old_ranks: Dict(NodeId, Float),
  new_ranks: Dict(NodeId, Float),
  nodes: List(NodeId),
) -> Float {
  list.fold(nodes, 0.0, fn(sum, node) {
    let old_val = dict.get(old_ranks, node) |> result.unwrap(0.0)
    let new_val = dict.get(new_ranks, node) |> result.unwrap(0.0)
    let diff = case new_val >. old_val {
      True -> new_val -. old_val
      False -> old_val -. new_val
    }
    sum +. diff
  })
}

// -----------------------------------------------------------------------------
// Eigenvector Centrality
// -----------------------------------------------------------------------------

/// Calculates Eigenvector Centrality for all nodes.
///
/// Eigenvector centrality measures a node's influence based on the centrality
/// of its neighbors. A node is important if it is connected to other important
/// nodes. Uses power iteration to converge on the principal eigenvector.
///
/// **Time Complexity:** O(max_iterations * (V + E))
///
/// ## Parameters
///
/// - `max_iterations`: Maximum number of power iterations
/// - `tolerance`: Convergence threshold for L2 norm
///
/// ## Example
///
/// ```gleam
/// centrality.eigenvector(graph, max_iterations: 100, tolerance: 0.0001)
/// // => dict.from_list([#(1, 0.707), #(2, 1.0), #(3, 0.707)])
/// ```
pub fn eigenvector(
  graph: Graph(n, e),
  max_iterations: Int,
  tolerance: Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n <= 1 {
    True ->
      list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, 1.0) })
    False -> {
      // Initialize with all ones, plus small node-ID-based perturbation
      // The perturbation must be large enough to break symmetry but small enough
      // not to bias results toward high-ID nodes
      let initial_scores =
        list.fold(nodes, dict.new(), fn(acc, id) {
          // Use 1.0 + (id / 1000.0) to add 0.1% per node ID
          // This is sufficient to break oscillation in symmetric graphs
          let perturbation = int.to_float(id) /. 1000.0
          dict.insert(acc, id, 1.0 +. perturbation)
        })

      iterate_eigenvector_with_oscillation_check(
        graph,
        nodes,
        initial_scores,
        dict.new(),
        // prev_prev starts empty
        max_iterations,
        tolerance,
        0,
      )
    }
  }
}

fn iterate_eigenvector_with_oscillation_check(
  graph: Graph(n, e),
  nodes: List(NodeId),
  scores: Dict(NodeId, Float),
  prev_prev_scores: Dict(NodeId, Float),
  max_iterations: Int,
  tolerance: Float,
  iteration: Int,
) -> Centrality {
  case iteration >= max_iterations {
    True -> scores
    False -> {
      // Compute new scores: x_v = Σ A_uv * x_u for neighbors u
      let new_scores =
        list.fold(nodes, dict.new(), fn(acc, node) {
          let neighbor_sum =
            get_in_neighbors(graph, node)
            |> list.fold(0.0, fn(sum, neighbor) {
              let neighbor_score =
                dict.get(scores, neighbor) |> result.unwrap(0.0)
              sum +. neighbor_score
            })
          dict.insert(acc, node, neighbor_sum)
        })

      let l2_norm = calculate_l2_norm(new_scores, nodes)
      let normalized = case l2_norm >. 0.0 {
        True ->
          dict.map_values(new_scores, fn(_node, score) { score /. l2_norm })
        False -> new_scores
      }

      // Check for convergence against previous iteration
      let l2_diff = calculate_l2_difference(scores, normalized, nodes)

      // Also check for 2-cycle oscillation (compare with prev_prev)
      let is_oscillating = case dict.size(prev_prev_scores) > 0 {
        True -> {
          let l2_diff_2 =
            calculate_l2_difference(prev_prev_scores, normalized, nodes)
          l2_diff_2 <. tolerance
        }
        False -> False
      }

      case is_oscillating {
        // Oscillation detected: return average of the two oscillating states
        // This gives the approximate eigenvector for graphs with symmetric structure
        True -> {
          let averaged =
            list.fold(nodes, dict.new(), fn(acc, node) {
              let val1 = dict.get(normalized, node) |> result.unwrap(0.0)
              let val2 = dict.get(scores, node) |> result.unwrap(0.0)
              let avg = { val1 +. val2 } /. 2.0
              dict.insert(acc, node, avg)
            })

          // Renormalize the average
          let avg_norm = calculate_l2_norm(averaged, nodes)
          case avg_norm >. 0.0 {
            True ->
              dict.map_values(averaged, fn(_node, score) { score /. avg_norm })
            False -> averaged
          }
        }
        False ->
          case l2_diff <. tolerance {
            // Normal convergence
            True -> normalized
            False ->
              iterate_eigenvector_with_oscillation_check(
                graph,
                nodes,
                normalized,
                scores,
                // prev becomes prev_prev
                max_iterations,
                tolerance,
                iteration + 1,
              )
          }
      }
    }
  }
}

fn calculate_l2_norm(scores: Dict(NodeId, Float), nodes: List(NodeId)) -> Float {
  let sum_squares =
    list.fold(nodes, 0.0, fn(sum, node) {
      let score = dict.get(scores, node) |> result.unwrap(0.0)
      sum +. score *. score
    })
  case sum_squares >. 0.0 {
    True -> sum_squares |> float.square_root() |> result.unwrap(0.0)
    False -> 0.0
  }
}

fn calculate_l2_difference(
  old_scores: Dict(NodeId, Float),
  new_scores: Dict(NodeId, Float),
  nodes: List(NodeId),
) -> Float {
  let sum_squares =
    list.fold(nodes, 0.0, fn(sum, node) {
      let old_val = dict.get(old_scores, node) |> result.unwrap(0.0)
      let new_val = dict.get(new_scores, node) |> result.unwrap(0.0)
      let diff = new_val -. old_val
      sum +. diff *. diff
    })
  case sum_squares >. 0.0 {
    True -> sum_squares |> float.square_root() |> result.unwrap(0.0)
    False -> 0.0
  }
}

// -----------------------------------------------------------------------------
// Katz Centrality
// -----------------------------------------------------------------------------

/// Calculates Katz Centrality for all nodes.
///
/// Katz centrality is a variant of eigenvector centrality that adds an
/// attenuation factor (alpha) to prevent the infinite accumulation of
/// centrality in cycles. It also includes a constant term (beta) to give
/// every node some base centrality.
///
/// Formula: C(v) = α * Σ C(u) + β for all neighbors u
///
/// **Time Complexity:** O(max_iterations * (V + E))
///
/// ## Parameters
///
/// - `alpha`: Attenuation factor (must be < 1/largest_eigenvalue, typically 0.1-0.3)
/// - `beta`: Base centrality (typically 1.0)
/// - `max_iterations`: Maximum number of iterations
/// - `tolerance`: Convergence threshold
///
/// ## Example
///
/// ```gleam
/// centrality.katz(graph, alpha: 0.1, beta: 1.0, max_iterations: 100, tolerance: 0.0001)
/// // => dict.from_list([#(1, 2.5), #(2, 3.0), #(3, 2.5)])
/// ```
pub fn katz(
  graph: Graph(n, e),
  alpha: Float,
  beta: Float,
  max_iterations: Int,
  tolerance: Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n <= 0 {
    True -> dict.new()
    False -> {
      let initial_scores =
        list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, beta) })

      iterate_katz(
        graph,
        nodes,
        initial_scores,
        alpha,
        beta,
        max_iterations,
        tolerance,
        0,
      )
    }
  }
}

fn iterate_katz(
  graph: Graph(n, e),
  nodes: List(NodeId),
  scores: Dict(NodeId, Float),
  alpha: Float,
  beta: Float,
  max_iterations: Int,
  tolerance: Float,
  iteration: Int,
) -> Centrality {
  case iteration >= max_iterations {
    True -> scores
    False -> {
      // Compute new scores: x_v = α * Σ x_u + β for neighbors u
      let new_scores =
        list.fold(nodes, dict.new(), fn(acc, node) {
          let neighbor_sum =
            get_in_neighbors(graph, node)
            |> list.fold(0.0, fn(sum, neighbor) {
              let neighbor_score =
                dict.get(scores, neighbor) |> result.unwrap(0.0)
              sum +. neighbor_score
            })
          let new_score = alpha *. neighbor_sum +. beta
          dict.insert(acc, node, new_score)
        })

      let l1_diff = calculate_l1_norm_diff(scores, new_scores, nodes)
      case l1_diff <. tolerance {
        True -> new_scores
        False ->
          iterate_katz(
            graph,
            nodes,
            new_scores,
            alpha,
            beta,
            max_iterations,
            tolerance,
            iteration + 1,
          )
      }
    }
  }
}

fn calculate_l1_norm_diff(
  old_scores: Dict(NodeId, Float),
  new_scores: Dict(NodeId, Float),
  nodes: List(NodeId),
) -> Float {
  list.fold(nodes, 0.0, fn(sum, node) {
    let old_val = dict.get(old_scores, node) |> result.unwrap(0.0)
    let new_val = dict.get(new_scores, node) |> result.unwrap(0.0)
    let diff = case new_val >. old_val {
      True -> new_val -. old_val
      False -> old_val -. new_val
    }
    sum +. diff
  })
}

// -----------------------------------------------------------------------------
// Alpha Centrality
// -----------------------------------------------------------------------------

/// Calculates Alpha Centrality for all nodes.
///
/// Alpha centrality is a generalization of Katz centrality for directed
/// graphs. It measures the total number of paths from a node, weighted
/// by path length with attenuation factor alpha.
///
/// Unlike Katz, alpha centrality does not include a constant beta term
/// and is particularly useful for analyzing influence in directed networks.
///
/// Formula: C(v) = α * Σ C(u) for all predecessors u (or neighbors for undirected)
///
/// **Time Complexity:** O(max_iterations * (V + E))
///
/// ## Parameters
///
/// - `alpha`: Attenuation factor (typically 0.1-0.5)
/// - `initial`: Initial centrality value for all nodes
/// - `max_iterations`: Maximum number of iterations
/// - `tolerance`: Convergence threshold
///
/// ## Example
///
/// ```gleam
/// centrality.alpha(graph, alpha: 0.3, initial: 1.0, max_iterations: 100, tolerance: 0.0001)
/// // => dict.from_list([#(1, 2.0), #(2, 3.0), #(3, 2.0)])
/// ```
pub fn alpha_centrality(
  graph: Graph(n, e),
  alpha: Float,
  initial: Float,
  max_iterations: Int,
  tolerance: Float,
) -> Centrality {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n <= 0 {
    True -> dict.new()
    False -> {
      // Initialize with given initial value
      let initial_scores =
        list.fold(nodes, dict.new(), fn(acc, id) {
          dict.insert(acc, id, initial)
        })

      iterate_alpha(
        graph,
        nodes,
        initial_scores,
        alpha,
        max_iterations,
        tolerance,
        0,
      )
    }
  }
}

fn iterate_alpha(
  graph: Graph(n, e),
  nodes: List(NodeId),
  scores: Dict(NodeId, Float),
  alpha: Float,
  max_iterations: Int,
  tolerance: Float,
  iteration: Int,
) -> Centrality {
  case iteration >= max_iterations {
    True -> scores
    False -> {
      // Compute new scores: x_v = α * Σ x_u for neighbors/predecessors u
      let new_scores =
        list.fold(nodes, dict.new(), fn(acc, node) {
          let neighbor_sum =
            get_in_neighbors(graph, node)
            |> list.fold(0.0, fn(sum, neighbor) {
              let neighbor_score =
                dict.get(scores, neighbor) |> result.unwrap(0.0)
              sum +. neighbor_score
            })
          let new_score = alpha *. neighbor_sum
          dict.insert(acc, node, new_score)
        })

      let l1_diff = calculate_l1_norm_diff(scores, new_scores, nodes)
      case l1_diff <. tolerance {
        True -> new_scores
        False ->
          iterate_alpha(
            graph,
            nodes,
            new_scores,
            alpha,
            max_iterations,
            tolerance,
            iteration + 1,
          )
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Convenience Wrappers
// -----------------------------------------------------------------------------

/// Degree centrality with default options for undirected graphs.
/// Uses TotalDegree mode.
pub fn degree_total(graph: Graph(n, e)) -> Centrality {
  degree(graph, TotalDegree)
}

/// Closeness centrality with **Int** weights (e.g., unweighted graphs).
/// Uses 0 as zero, int.add, int.compare, and int.to_float.
pub fn closeness_int(graph: Graph(n, Int)) -> Centrality {
  closeness(
    graph,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
    with_to_float: int.to_float,
  )
}

/// Closeness centrality with **Float** weights.
/// Uses 0.0 as zero, float.add, float.compare, and identity.
pub fn closeness_float(graph: Graph(n, Float)) -> Centrality {
  closeness(
    graph,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
    with_to_float: fn(x) { x },
  )
}

/// Harmonic centrality with **Int** weights.
pub fn harmonic_centrality_int(graph: Graph(n, Int)) -> Centrality {
  harmonic_centrality(
    graph,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
    with_to_float: int.to_float,
  )
}

/// Harmonic centrality with **Float** weights.
pub fn harmonic_centrality_float(graph: Graph(n, Float)) -> Centrality {
  harmonic_centrality(
    graph,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
    with_to_float: fn(x) { x },
  )
}

/// Betweenness centrality with **Int** weights.
pub fn betweenness_int(graph: Graph(n, Int)) -> Centrality {
  betweenness(
    graph,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
    with_to_float: int.to_float,
  )
}

/// Betweenness centrality with **Float** weights.
pub fn betweenness_float(graph: Graph(n, Float)) -> Centrality {
  betweenness(
    graph,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
    with_to_float: fn(x) { x },
  )
}

/// Default PageRank options (damping=0.85, max_iterations=100, tolerance=0.0001).
pub fn default_pagerank_options() -> PageRankOptions {
  PageRankOptions(damping: 0.85, max_iterations: 100, tolerance: 0.0001)
}
