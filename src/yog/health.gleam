//// Network health and structural quality metrics.
////
//// These metrics measure the overall "health" and structural properties
//// of your graph, including size, compactness, and connectivity patterns.
////
//// ## Overview
////
//// | Metric | Function | Measures |
//// |--------|----------|----------|
//// | Diameter | `diameter/5` | Maximum distance (worst-case reachability) |
//// | Radius | `radius/5` | Minimum eccentricity (best central point) |
//// | Eccentricity | `eccentricity/6` | Maximum distance from a node |
//// | Assortativity | `assortativity/1` | Degree correlation (homophily) |
//// | Average Path Length | `average_path_length/6` | Typical separation |
////
//// ## Example
////
//// ```gleam
//// import gleam/int
//// import gleam/order
//// import yog/health
////
//// let graph = // ... build your graph
////
//// // Check graph compactness
//// let diam = health.diameter(
////   in: graph,
////   with_zero: 0,
////   with_add: int.add,
////   with_compare: int.compare,
////   with: fn(w) { w }
//// )
//// let rad = health.radius(
////   in: graph,
////   with_zero: 0,
////   with_add: int.add,
////   with_compare: int.compare,
////   with: fn(w) { w }
//// )
////
//// // Small diameter = well-connected
//// // High assortativity = nodes cluster with similar nodes
//// let assort = health.assortativity(graph)
//// ```

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import yog
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/dijkstra
import yog/transform

// =============================================================================
// Distance Metrics
// =============================================================================

/// The diameter is the maximum eccentricity (longest shortest path).
/// Returns None if the graph is disconnected or empty.
///
/// Time Complexity: O(V × (V+E) log V)
///
/// ## Interpreting Diameter
///
/// | Value | Meaning |
/// |-------|---------|
/// | `1` | Complete graph — everyone is directly connected |
/// | `2` | Small world — at most one hop between any pair |
/// | `> log(V)` | Relatively sparse or stretched topology |
/// | `None` | Disconnected or empty graph |
pub fn diameter(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with weight_fn: fn(e) -> e,
) -> Option(e) {
  let nodes = model.all_nodes(graph)

  case list.is_empty(nodes) {
    True -> None
    False -> {
      let eccentricities =
        list.filter_map(nodes, fn(node) {
          eccentricity(
            in: graph,
            node: node,
            with_zero: zero,
            with_add: add,
            with_compare: compare,
            with: weight_fn,
          )
          |> option.to_result(Nil)
        })

      case list.is_empty(eccentricities) {
        True -> None
        False ->
          list.reduce(eccentricities, fn(max_ecc, ecc) {
            case compare(ecc, max_ecc) {
              order.Gt -> ecc
              _ -> max_ecc
            }
          })
          |> option.from_result
      }
    }
  }
}

/// The radius is the minimum eccentricity.
/// Returns None if the graph is disconnected or empty.
///
/// Time Complexity: O(V × (V+E) log V)
///
/// ## Interpreting Radius
///
/// | Value | Meaning |
/// |-------|---------|
/// | `= diameter` | Highly symmetric structure (e.g. cycle, complete graph) |
/// | `< diameter` | Centralized topology with a clear hub (e.g. star) |
/// | `1` | There exists a central node one hop from everyone else |
/// | `None` | Disconnected or empty graph |
pub fn radius(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with weight_fn: fn(e) -> e,
) -> Option(e) {
  let nodes = model.all_nodes(graph)

  case list.is_empty(nodes) {
    True -> None
    False -> {
      let eccentricities =
        list.filter_map(nodes, fn(node) {
          eccentricity(
            in: graph,
            node: node,
            with_zero: zero,
            with_add: add,
            with_compare: compare,
            with: weight_fn,
          )
          |> option.to_result(Nil)
        })

      case list.is_empty(eccentricities) {
        True -> None
        False ->
          list.reduce(eccentricities, fn(min_ecc, ecc) {
            case compare(ecc, min_ecc) {
              order.Lt -> ecc
              _ -> min_ecc
            }
          })
          |> option.from_result
      }
    }
  }
}

/// Eccentricity is the maximum distance from a node to all other nodes.
/// Returns None if the node cannot reach all other nodes.
///
/// Time Complexity: O((V+E) log V)
///
/// ## Interpreting Eccentricity
///
/// | Value | Meaning |
/// |-------|---------|
/// | `= radius` | The node is in the graph center |
/// | `= diameter` | The node is on the periphery (worst-case reachability) |
/// | `1` | The node is adjacent to every other node |
/// | `0` | Single-node graph |
/// | `None` | The node cannot reach all others (disconnected component) |
pub fn eccentricity(
  in graph: Graph(n, e),
  node node: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with weight_fn: fn(e) -> e,
) -> Option(e) {
  let all_nodes = model.all_nodes(graph)
  let num_nodes = list.length(all_nodes)

  case num_nodes {
    0 | 1 -> Some(zero)
    _ -> {
      let weighted_graph =
        transform.map_edges(graph, applying: fn(_, _, w) { weight_fn(w) })

      let distances =
        dijkstra.single_source_distances(
          in: weighted_graph,
          from: node,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )

      case dict.size(distances) == num_nodes {
        False -> None
        True -> {
          dict.values(distances)
          |> list.reduce(fn(max_dist, dist) {
            case compare(dist, max_dist) {
              order.Gt -> dist
              _ -> max_dist
            }
          })
          |> option.from_result
        }
      }
    }
  }
}

// =============================================================================
// Assortativity
// =============================================================================

/// Assortativity coefficient measures degree correlation.
///
/// Time Complexity: O(V+E)
///
/// ## Interpreting Assortativity
///
/// | Value | Meaning |
/// |-------|---------|
/// | **Positive** | High-degree nodes preferentially connect to other high-degree nodes (assortative) |
/// | **Negative** | High-degree nodes connect to low-degree nodes (disassortative) |
/// | **Zero** | Random mixing, or all nodes have the same degree (regular graph) |
///
/// Common real-world patterns:
/// - Social networks tend to be **assortative** (people with many friends know each other)
/// - Biological and technological networks tend to be **disassortative** (hubs serve many leaves)
pub fn assortativity(graph: Graph(n, e)) -> Float {
  let nodes = model.all_nodes(graph)

  let degrees = {
    use acc, node <- list.fold(nodes, dict.new())
    let degree = list.length(yog.neighbors(graph, node))
    dict.insert(acc, node, degree)
  }

  let edges_data =
    list.flat_map(nodes, fn(u) {
      yog.successors(graph, u)
      |> list.map(fn(edge) {
        let #(v, _) = edge
        let du = dict_get_int(degrees, u)
        let dv = dict_get_int(degrees, v)
        #(du, dv)
      })
    })

  case list.is_empty(edges_data) {
    True -> 0.0
    False -> {
      let m = int.to_float(list.length(edges_data))

      let #(sum_jk, sum_j, sum_k, sum_j_squared, sum_k_squared) = {
        use acc, edge <- list.fold(edges_data, #(0.0, 0.0, 0.0, 0.0, 0.0))
        let #(j, k) = edge
        let jf = int.to_float(j)
        let kf = int.to_float(k)
        #(
          acc.0 +. jf *. kf,
          acc.1 +. jf,
          acc.2 +. kf,
          acc.3 +. jf *. jf,
          acc.4 +. kf *. kf,
        )
      }

      let mean_j = sum_j /. m
      let mean_k = sum_k /. m
      let numerator = sum_jk /. m -. mean_j *. mean_k

      let denom_j = sum_j_squared /. m -. mean_j *. mean_j
      let denom_k = sum_k_squared /. m -. mean_k *. mean_k

      let denominator = float.square_root(denom_j *. denom_k)

      case denominator {
        Ok(d) if d >. 0.0 -> numerator /. d
        _ -> 0.0
      }
    }
  }
}

// =============================================================================
// Average Path Length
// =============================================================================

/// Average shortest path length across all node pairs.
/// Returns None if the graph is disconnected or empty.
/// Requires a function to convert edge weights to Float for averaging.
///
/// Time Complexity: O(V × (V+E) log V)
///
/// ## Interpreting Average Path Length
///
/// | Value | Meaning |
/// |-------|---------|
/// | `≈ 1.0` | Dense or highly connected graph (e.g. complete graph) |
/// | `≈ 2.0` | Star-like or small-world structure |
/// | `≈ V/3` | Chain-like or path-like topology |
/// | `None` | Disconnected or empty graph |
///
/// A low APL relative to the number of nodes indicates a **small-world** structure:
/// the graph achieves global connectivity through a small number of hops.
pub fn average_path_length(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with weight_fn: fn(e) -> e,
  with_to_float to_float: fn(e) -> Float,
) -> Option(Float) {
  let nodes = model.all_nodes(graph)
  let num_nodes = list.length(nodes)

  case num_nodes {
    0 | 1 -> None
    _ -> {
      let weighted_graph =
        transform.map_edges(graph, applying: fn(_, _, w) { weight_fn(w) })

      let all_distances =
        list.map(nodes, fn(source) {
          dijkstra.single_source_distances(
            in: weighted_graph,
            from: source,
            with_zero: zero,
            with_add: add,
            with_compare: compare,
          )
        })

      let all_reachable =
        list.all(all_distances, fn(distances) {
          dict.size(distances) == num_nodes
        })

      case all_reachable {
        False -> None
        True -> {
          let total = {
            use acc, distances <- list.fold(all_distances, 0.0)
            let sum = {
              use s, _node, dist <- dict.fold(distances, 0.0)
              s +. to_float(dist)
            }
            acc +. sum
          }

          let zero_distances = int.to_float(num_nodes) *. to_float(zero)
          let num_pairs = int.to_float(num_nodes * { num_nodes - 1 })
          Some({ total -. zero_distances } /. num_pairs)
        }
      }
    }
  }
}

// =============================================================================
// Helpers
// =============================================================================

fn dict_get_int(dict: dict.Dict(NodeId, Int), key: NodeId) -> Int {
  dict.get(dict, key) |> result.unwrap(0)
}
