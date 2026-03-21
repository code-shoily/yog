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

/// The diameter is the maximum eccentricity (longest shortest path).
/// Returns None if the graph is disconnected or empty.
///
/// Time Complexity: O(V × (V+E) log V)
///
/// ## Example
///
/// ```gleam
/// let diam = health.diameter(
///   in: graph,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   with: fn(w) { w }
/// )
/// case diam {
///   Some(d) -> io.println("Diameter: " <> int.to_string(d))
///   None -> io.println("Graph is disconnected")
/// }
/// ```
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
      // Calculate eccentricity for all nodes
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
/// ## Example
///
/// ```gleam
/// let rad = health.radius(
///   in: graph,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   with: fn(w) { w }
/// )
/// case rad {
///   Some(r) -> io.println("Radius: " <> int.to_string(r))
///   None -> io.println("Graph is disconnected")
/// }
/// ```
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
      // Calculate eccentricity for all nodes
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
/// ## Example
///
/// ```gleam
/// let ecc = health.eccentricity(
///   in: graph,
///   node: node_id,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   with: fn(w) { w }
/// )
/// case ecc {
///   Some(e) -> io.println("Eccentricity: " <> int.to_string(e))
///   None -> io.println("Node cannot reach all others")
/// }
/// ```
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
      // Transform graph to apply weight function
      let weighted_graph = transform.map_edges(graph, with: weight_fn)

      // Run Dijkstra from this node
      let distances =
        dijkstra.single_source_distances(
          in: weighted_graph,
          from: node,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )

      // Check if all nodes are reachable
      let reachable_count = dict.size(distances)

      case reachable_count == num_nodes {
        False -> None
        True -> {
          // Find maximum distance
          case
            dict.values(distances)
            |> list.reduce(fn(max_dist, dist) {
              case compare(dist, max_dist) {
                order.Gt -> dist
                _ -> max_dist
              }
            })
          {
            Ok(max) -> Some(max)
            Error(Nil) -> None
          }
        }
      }
    }
  }
}

/// Assortativity coefficient measures degree correlation.
/// - Positive: high-degree nodes connect to high-degree nodes (assortative)
/// - Negative: high-degree nodes connect to low-degree nodes (disassortative)
/// - Zero: random mixing
///
/// Time Complexity: O(V+E)
///
/// ## Example
///
/// ```gleam
/// let assort = health.assortativity(graph)
/// case assort >. 0.0 {
///   True -> io.println("Assortative mixing (homophily)")
///   False -> io.println("Disassortative mixing")
/// }
/// ```
pub fn assortativity(graph: Graph(n, e)) -> Float {
  let nodes = model.all_nodes(graph)

  // Calculate degrees for all nodes
  let degrees =
    list.fold(nodes, dict.new(), fn(acc, node) {
      let degree = list.length(yog.neighbors(graph, node))
      dict.insert(acc, node, degree)
    })

  // Calculate assortativity using Newman's formula
  let edges_data =
    list.flat_map(nodes, fn(u) {
      yog.successors(graph, u)
      |> list.map(fn(edge) {
        let #(v, _) = edge
        let du = dict.get(degrees, u) |> result.unwrap(0)
        let dv = dict.get(degrees, v) |> result.unwrap(0)
        #(du, dv)
      })
    })

  case list.is_empty(edges_data) {
    True -> 0.0
    False -> {
      let m = int.to_float(list.length(edges_data))

      let sum_jk =
        list.fold(edges_data, 0.0, fn(acc, edge) {
          let #(j, k) = edge
          acc +. int.to_float(j * k)
        })

      let sum_j =
        list.fold(edges_data, 0.0, fn(acc, edge) {
          let #(j, _) = edge
          acc +. int.to_float(j)
        })

      let sum_k =
        list.fold(edges_data, 0.0, fn(acc, edge) {
          let #(_, k) = edge
          acc +. int.to_float(k)
        })

      let sum_j_squared =
        list.fold(edges_data, 0.0, fn(acc, edge) {
          let #(j, _) = edge
          acc +. int.to_float(j * j)
        })

      let sum_k_squared =
        list.fold(edges_data, 0.0, fn(acc, edge) {
          let #(_, k) = edge
          acc +. int.to_float(k * k)
        })

      let numerator = sum_jk /. m -. { sum_j /. m } *. { sum_k /. m }

      let denom_j = sum_j_squared /. m -. { sum_j /. m } *. { sum_j /. m }
      let denom_k = sum_k_squared /. m -. { sum_k /. m } *. { sum_k /. m }

      let denominator = float.square_root(denom_j *. denom_k)

      case denominator {
        Ok(d) if d >. 0.0 -> numerator /. d
        _ -> 0.0
      }
    }
  }
}

/// Average shortest path length across all node pairs.
/// Returns None if the graph is disconnected or empty.
/// Requires a function to convert edge weights to Float for averaging.
///
/// Time Complexity: O(V × (V+E) log V)
///
/// ## Example
///
/// ```gleam
/// let avg_path = health.average_path_length(
///   in: graph,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   with: fn(w) { w },
///   with_to_float: int.to_float
/// )
/// case avg_path {
///   Some(avg) -> io.println("Average path length: " <> float.to_string(avg))
///   None -> io.println("Graph is disconnected")
/// }
/// ```
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
      // Transform graph to apply weight function
      let weighted_graph = transform.map_edges(graph, with: weight_fn)

      // Calculate all-pairs shortest paths
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

      // Check if graph is fully connected
      let all_reachable =
        list.all(all_distances, fn(distances) {
          dict.size(distances) == num_nodes
        })

      case all_reachable {
        False -> None
        True -> {
          // Sum all distances (excluding self-distances which are zero)
          let total =
            list.fold(all_distances, 0.0, fn(acc, distances) {
              let sum =
                dict.fold(distances, 0.0, fn(sum, _node, dist) {
                  sum +. to_float(dist)
                })
              acc +. sum
            })

          // Subtract self-distances (all zeros) and divide by number of pairs (n * (n-1))
          let zero_distances = int.to_float(num_nodes) *. to_float(zero)
          let num_pairs = int.to_float(num_nodes * { num_nodes - 1 })
          Some({ total -. zero_distances } /. num_pairs)
        }
      }
    }
  }
}
