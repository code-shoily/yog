//// Optimized distance matrix computation for subsets of nodes.
////
//// This module provides an auto-selecting algorithm for computing shortest path
//// distances between specified "points of interest" (POIs) in a graph. It intelligently
//// chooses between Floyd-Warshall, Johnson's, and multiple Dijkstra runs based on
//// graph characteristics and POI density.
////
//// ## Algorithm Selection
////
//// **With negative weights support** (when `with_subtract` is provided):
////
//// | Algorithm | When Selected | Complexity |
//// |-----------|---------------|------------|
//// | [Johnson's](https://en.wikipedia.org/wiki/Johnson%27s_algorithm) | Sparse graphs (E < V²/4) | O(V² log V + VE) then filter |
//// | [Floyd-Warshall](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm) | Dense graphs (E ≥ V²/4) | O(V³) then filter |
////
//// **Without negative weights** (when `with_subtract` is `None`):
////
//// | Algorithm | When Selected | Complexity |
//// |-----------|---------------|------------|
//// | [Dijkstra](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) × P | Few POIs (P ≤ V/3) | O(P × (V + E) log V) |
//// | [Floyd-Warshall](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm) | Many POIs (P > V/3) | O(V³) then filter |
////
//// ## Heuristics
////
//// **For graphs with potential negative weights:**
//// - Johnson's algorithm is preferred for sparse graphs where E < V²/4
//// - Floyd-Warshall is preferred for denser graphs
////
//// **For non-negative weights only:**
//// - Multiple Dijkstra runs when P ≤ V/3 (few POIs)
//// - Floyd-Warshall when P > V/3 (many POIs)
////
//// ## Use Cases
////
//// - **Game AI**: Pathfinding between key locations (not all nodes)
//// - **Logistics**: Distance matrix for delivery stops
//// - **Facility location**: Distances between candidate sites
//// - **Network analysis**: Selected node pairwise distances
////
//// ## Example
////
//// ```gleam
//// // Compute distances only between important waypoints
//// let pois = [start, waypoint_a, waypoint_b, goal]
//// let distances = matrix.distance_matrix(
////   in: graph,
////   between: pois,
////   with_zero: 0,
////   with_add: int.add,
////   with_compare: int.compare,
//// )
//// // Result contains only 4×4 = 16 distances, not full V×V matrix
//// ```
////
//// ## References
////
//// - See `yog/pathfinding/floyd_warshall` for all-pairs algorithm details (O(V³))
//// - See `yog/pathfinding/johnson` for sparse all-pairs with negative weights (O(V² log V + VE))
//// - See `yog/pathfinding/dijkstra` for single-source algorithm details (O((V+E) log V))

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/set
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/dijkstra
import yog/pathfinding/floyd_warshall
import yog/pathfinding/johnson

/// Computes shortest distances between all pairs of points of interest.
///
/// Automatically chooses the best algorithm based on:
/// - Whether negative weights are possible (presence of `with_subtract`)
/// - Graph sparsity (E relative to V²)
/// - POI density (P relative to V)
///
/// **Time Complexity:** O(V³), O(V² log V + VE), or O(P × (V + E) log V)
///
/// ## Parameters
///
/// - `with_subtract`: Optional subtraction function for negative weight support.
///   If provided, enables Johnson's algorithm for sparse graphs with negative weights.
///   If `None`, assumes non-negative weights and may use Dijkstra.
///
/// ## Examples
///
/// ```gleam
/// // Non-negative weights only (uses Dijkstra or Floyd-Warshall)
/// matrix.distance_matrix(
///   in: graph,
///   between: pois,
///   with_zero: 0,
///   with_add: int.add,
///   with_subtract: None,
///   with_compare: int.compare,
/// )
///
/// // Support negative weights (uses Johnson's or Floyd-Warshall)
/// matrix.distance_matrix(
///   in: graph,
///   between: pois,
///   with_zero: 0,
///   with_add: int.add,
///   with_subtract: Some(int.subtract),
///   with_compare: int.compare,
/// )
/// ```
pub fn distance_matrix(
  in graph: Graph(n, e),
  between points_of_interest: List(NodeId),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_subtract subtract: Option(fn(e, e) -> e),
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let num_nodes = dict.size(graph.nodes)
  let num_edges = model.edge_count(graph)
  let num_pois = list.length(points_of_interest)
  let poi_set = set.from_list(points_of_interest)

  case subtract {
    // Negative weights possible: Choose between Johnson's and Floyd-Warshall
    Some(sub_fn) -> {
      // For sparse graphs, Johnson's is faster: O(V² log V + VE) vs O(V³)
      // Heuristic: Use Johnson's if E < V²/4 (very sparse)
      let is_sparse = num_edges * 4 < num_nodes * num_nodes

      case is_sparse {
        True -> {
          // Use Johnson's algorithm for sparse graphs with potential negative weights
          case
            johnson.johnson(
              in: graph,
              with_zero: zero,
              with_add: add,
              with_subtract: sub_fn,
              with_compare: compare,
            )
          {
            Error(Nil) -> Error(Nil)
            Ok(all_distances) -> {
              // Filter to only POI-to-POI distances
              let poi_distances =
                dict.filter(all_distances, fn(key, _value) {
                  let #(from_node, to_node) = key
                  set.contains(poi_set, from_node)
                  && set.contains(poi_set, to_node)
                })
              Ok(poi_distances)
            }
          }
        }
        False -> {
          // Use Floyd-Warshall for dense graphs
          use_floyd_warshall(graph, poi_set, zero, add, compare)
        }
      }
    }
    // Non-negative weights only: Choose between Dijkstra and Floyd-Warshall
    None -> {
      // Original heuristic: P > V/3
      // Floyd-Warshall: O(V³)
      // Multiple Dijkstra: O(P × (V + E) log V) where P = num_pois
      case num_pois * 3 > num_nodes {
        True -> {
          // Many POIs: Use Floyd-Warshall
          use_floyd_warshall(graph, poi_set, zero, add, compare)
        }
        False -> {
          // Few POIs: Run single_source_distances from each POI
          let result =
            list.fold(points_of_interest, dict.new(), fn(acc, source) {
              let distances =
                dijkstra.single_source_distances(
                  in: graph,
                  from: source,
                  with_zero: zero,
                  with_add: add,
                  with_compare: compare,
                )

              // Add only POI-to-POI distances
              list.fold(points_of_interest, acc, fn(acc2, target) {
                case dict.get(distances, target) {
                  Ok(dist) -> dict.insert(acc2, #(source, target), dist)
                  Error(Nil) -> acc2
                }
              })
            })

          Ok(result)
        }
      }
    }
  }
}

/// Helper function to run Floyd-Warshall and filter results to POIs
fn use_floyd_warshall(
  graph: Graph(n, e),
  poi_set: set.Set(NodeId),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  case
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: zero,
      with_add: add,
      with_compare: compare,
    )
  {
    Error(Nil) -> Error(Nil)
    Ok(all_distances) -> {
      // Filter to only POI-to-POI distances
      let poi_distances =
        dict.filter(all_distances, fn(key, _value) {
          let #(from_node, to_node) = key
          set.contains(poi_set, from_node) && set.contains(poi_set, to_node)
        })
      Ok(poi_distances)
    }
  }
}
