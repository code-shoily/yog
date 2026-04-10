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
import gleam/order.{type Order}
import gleam/result
import yog/internal/brandes
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding/dijkstra

// =============================================================================
// Types
// =============================================================================

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

// =============================================================================
// Degree Centrality
// =============================================================================

/// Calculates the Degree Centrality for all nodes in the graph.
/// 
/// For directed graphs, use `mode` to specify which edges to count.
/// For undirected graphs, the `mode` is ignored.
///
/// ## Interpreting Degree Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | `1.0` | The node is connected to every other node (hub) |
/// | `0.5` | The node is connected to half the other nodes |
/// | `0.0` | Isolated node — no connections |
pub fn degree(graph: Graph(n, e), mode: DegreeMode) -> Centrality {
  let n = model.order(graph)
  let factor = case n > 1 {
    True -> int.to_float(n - 1)
    False -> 1.0
  }

  use acc, id <- list.fold(model.all_nodes(graph), dict.new())
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
///
/// ## Interpreting Closeness Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | `1.0` | The node is one hop away from all others (e.g. center of a star) |
/// | `0.5` | The node is typically 2 hops away from others |
/// | `0.0` | The node cannot reach everyone (disconnected or isolated) |
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
      use acc, source <- list.fold(nodes, dict.new())
      let distances =
        dijkstra.single_source_distances(
          in: graph,
          from: source,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )

      case dict.size(distances) == n {
        False -> dict.insert(acc, source, 0.0)
        True -> {
          let total_distance =
            dict.fold(distances, zero, fn(sum, _node, dist) { add(sum, dist) })
          let centrality_score = int.to_float(n - 1) /. to_float(total_distance)
          dict.insert(acc, source, centrality_score)
        }
      }
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
///
/// ## Interpreting Harmonic Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | `1.0` | The node is directly connected to all others |
/// | `0.5` | The node is directly connected to half the others |
/// | `0.0` | Isolated node — cannot reach anyone else |
///
/// Unlike closeness, disconnected nodes still receive credit for the
/// neighbors they *can* reach rather than being penalized with `0.0`.
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

      use acc, source <- list.fold(nodes, dict.new())
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
              case d >. 0.0 {
                True -> sum +. { 1.0 /. d }
                False -> sum
              }
            }
          }
        })

      dict.insert(acc, source, sum_of_reciprocals /. denominator)
    }
  }
}

/// Calculates Betweenness Centrality for all nodes.
/// 
/// Betweenness centrality of a node v is the sum of the fraction of 
/// all-pairs shortest paths that pass through v.
///
/// **Time Complexity:** O(VE) for unweighted, O(VE + V²logV) for weighted.
///
/// ## Interpreting Betweenness Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | **High** | The node is a bridge or gatekeeper — many shortest paths go through it |
/// | **Low** | The node is peripheral — most paths bypass it |
/// | `0.0` | The node lies on no shortest paths between any other pair |
///
/// A high betweenness node is critical for network connectivity:
/// removing it can fragment the graph or severely increase path lengths.
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

  let scores = {
    use acc, s <- list.fold(nodes, initial)
    let discovery = brandes.run_discovery(graph, s, zero, add, compare)
    let dependencies = brandes.accumulate_node_dependencies(discovery)
    merge_scores(acc, dependencies, s)
  }

  apply_undirected_scaling(scores, graph.kind)
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
        let current = dict_get_float(acc2, node)
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
// =============================================================================
// PageRank
// =============================================================================

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
///
/// ## Interpreting PageRank
///
/// | Value | Meaning |
/// |-------|---------|
/// | **High** | The node is linked to by many other important nodes |
/// | **Low** | The node has few or low-quality incoming links |
/// | `1.0` | Single-node graph (trivial case) |
///
/// PageRank scores always sum to `1.0` across all nodes. A node with
/// rank `0.5` in a 2-node graph means it captures half the total
/// importance in the network.
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

      let new_ranks = {
        use acc, node <- list.fold(nodes, dict.new())
        let rank_sum = {
          use sum, neighbor <- list.fold(get_in_neighbors(graph, node), 0.0)
          let neighbor_rank = dict_get_float(ranks, neighbor)
          let out_degree = get_out_degree(graph, neighbor)
          case out_degree > 0 {
            True -> sum +. neighbor_rank /. int.to_float(out_degree)
            False -> sum
          }
        }

        let new_rank =
          { 1.0 -. damping } /. n_float +. damping *. { sink_sum +. rank_sum }

        dict.insert(acc, node, new_rank)
      }

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
  use sum, node <- list.fold(nodes, 0.0)
  let out_degree = get_out_degree(graph, node)
  case out_degree == 0 {
    True -> sum +. dict_get_float(ranks, node) /. n_float
    False -> sum
  }
}

fn get_in_neighbors(graph: Graph(n, e), node: NodeId) -> List(NodeId) {
  case graph.kind {
    Undirected ->
      model.successors(graph, node)
      |> list.map(fn(edge) { edge.0 })
    Directed ->
      model.predecessors(graph, node)
      |> list.map(fn(edge) { edge.0 })
  }
}

fn get_out_degree(graph: Graph(n, e), node: NodeId) -> Int {
  case graph.kind {
    Undirected ->
      model.neighbors(graph, node)
      |> list.length()
    Directed ->
      model.successors(graph, node)
      |> list.length()
  }
}

fn calculate_l1_norm(
  old_ranks: Dict(NodeId, Float),
  new_ranks: Dict(NodeId, Float),
  nodes: List(NodeId),
) -> Float {
  use sum, node <- list.fold(nodes, 0.0)
  let old_val = dict_get_float(old_ranks, node)
  let new_val = dict_get_float(new_ranks, node)
  sum +. float.absolute_value(new_val -. old_val)
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
///
/// ## Interpreting Eigenvector Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | **High** | The node is connected to other highly central nodes |
/// | **Low** | The node is connected to peripheral or unimportant nodes |
/// | `0.0` | Isolated node with no connections |
///
/// Eigenvector scores are normalized (L2 norm = 1.0), so they represent
/// relative importance rather than absolute counts.
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
      let initial_scores = {
        use acc, id <- list.fold(nodes, dict.new())
        let perturbation = int.to_float(id) /. 1000.0
        dict.insert(acc, id, 1.0 +. perturbation)
      }

      iterate_eigenvector_with_oscillation_check(
        graph,
        nodes,
        initial_scores,
        dict.new(),
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
      let new_scores = {
        use acc, node <- list.fold(nodes, dict.new())
        let neighbor_sum = {
          use sum, neighbor <- list.fold(get_in_neighbors(graph, node), 0.0)
          let neighbor_score = dict_get_float(scores, neighbor)
          sum +. neighbor_score
        }
        dict.insert(acc, node, neighbor_sum)
      }

      let l2_norm = calculate_l2_norm(new_scores, nodes)
      let normalized = case l2_norm >. 0.0 {
        True ->
          dict.map_values(new_scores, fn(_node, score) { score /. l2_norm })
        False -> new_scores
      }

      let l2_diff = calculate_l2_difference(scores, normalized, nodes)

      let is_oscillating = case dict.size(prev_prev_scores) > 0 {
        True -> {
          let l2_diff_2 =
            calculate_l2_difference(prev_prev_scores, normalized, nodes)
          l2_diff_2 <. tolerance
        }
        False -> False
      }

      case is_oscillating {
        True -> {
          let averaged = {
            use acc, node <- list.fold(nodes, dict.new())
            let val1 = dict_get_float(normalized, node)
            let val2 = dict_get_float(scores, node)
            dict.insert(acc, node, { val1 +. val2 } /. 2.0)
          }

          let avg_norm = calculate_l2_norm(averaged, nodes)
          case avg_norm >. 0.0 {
            True ->
              dict.map_values(averaged, fn(_node, score) { score /. avg_norm })
            False -> averaged
          }
        }
        False ->
          case l2_diff <. tolerance {
            True -> normalized
            False ->
              iterate_eigenvector_with_oscillation_check(
                graph,
                nodes,
                normalized,
                scores,
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
  let sum_squares = {
    use sum, node <- list.fold(nodes, 0.0)
    let score = dict_get_float(scores, node)
    sum +. score *. score
  }

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
  let sum_squares = {
    use sum, node <- list.fold(nodes, 0.0)
    let old_val = dict_get_float(old_scores, node)
    let new_val = dict_get_float(new_scores, node)
    let diff = new_val -. old_val
    sum +. diff *. diff
  }

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
///
/// ## Interpreting Katz Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | **High** | The node has many short paths to other important nodes |
/// | **Low** | The node is distant from the network core |
/// | `≈ beta` | Isolated node — only receives the baseline score |
///
/// Because of the constant `beta` term, even isolated nodes receive a
/// non-zero score, making Katz more forgiving than eigenvector centrality.
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
      let initial_scores = {
        use acc, id <- list.fold(nodes, dict.new())
        dict.insert(acc, id, beta)
      }

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
      let new_scores = {
        use acc, node <- list.fold(nodes, dict.new())
        let neighbor_sum = {
          use sum, neighbor <- list.fold(get_in_neighbors(graph, node), 0.0)
          let neighbor_score = dict_get_float(scores, neighbor)
          sum +. neighbor_score
        }
        let new_score = alpha *. neighbor_sum +. beta
        dict.insert(acc, node, new_score)
      }

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
  use sum, node <- list.fold(nodes, 0.0)
  let old_val = dict_get_float(old_scores, node)
  let new_val = dict_get_float(new_scores, node)
  sum +. float.absolute_value(new_val -. old_val)
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
/// centrality.alpha_centrality(graph, alpha: 0.3, initial: 1.0, max_iterations: 100, tolerance: 0.0001)
/// // => dict.from_list([#(1, 2.0), #(2, 3.0), #(3, 2.0)])
/// ```
///
/// ## Interpreting Alpha Centrality
///
/// | Value | Meaning |
/// |-------|---------|
/// | **High** | The node has many paths from other central nodes |
/// | **Low** | The node is at the edge of the network with few incoming paths |
/// | `0.0` | Isolated node — no incoming paths to accumulate influence |
///
/// Unlike Katz, alpha centrality has no baseline `beta` term, so isolated
/// nodes converge to `0.0` rather than retaining a minimum score.
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
      let initial_scores = {
        use acc, id <- list.fold(nodes, dict.new())
        dict.insert(acc, id, initial)
      }

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
      let new_scores = {
        use acc, node <- list.fold(nodes, dict.new())
        let neighbor_sum = {
          use sum, neighbor <- list.fold(get_in_neighbors(graph, node), 0.0)
          let neighbor_score = dict_get_float(scores, neighbor)
          sum +. neighbor_score
        }
        let new_score = alpha *. neighbor_sum
        dict.insert(acc, node, new_score)
      }

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

// =============================================================================
// Convenience Wrappers
// =============================================================================

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

fn dict_get_float(dict: Dict(NodeId, Float), key: NodeId) -> Float {
  dict.get(dict, key) |> result.unwrap(0.0)
}
