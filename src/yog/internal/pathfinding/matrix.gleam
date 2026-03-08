import gleam/dict.{type Dict}
import gleam/list
import gleam/order.{type Order}
import gleam/set
import yog/internal/pathfinding/dijkstra
import yog/internal/pathfinding/floyd_warshall
import yog/model.{type Graph, type NodeId}

// ======================== DISTANCE MATRIX ========================

/// Computes shortest distances between all pairs of points of interest.
///
/// Automatically chooses the most efficient algorithm based on the density
/// of points of interest relative to the total graph size:
/// - When POIs are dense (> 1/3 of nodes): Uses Floyd-Warshall O(V³)
/// - When POIs are sparse (≤ 1/3 of nodes): Uses multiple single-source Dijkstra O(P × (V+E) log V)
///
/// Returns only distances between the specified points of interest, not all node pairs.
///
/// **Time Complexity:** Automatically optimized based on POI density
///
/// ## Parameters
///
/// - `between`: List of points of interest (POI) nodes
/// - `zero`: The identity element for addition (e.g., `0` for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Returns
///
/// - `Ok(distances)`: Dictionary mapping POI pairs to their shortest distances
/// - `Error(Nil)`: If a negative cycle is detected (only when using Floyd-Warshall)
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import yog
/// import yog/pathfinding
///
/// // Graph with many nodes, but only care about distances between a few POIs
/// let graph = build_large_graph()  // 1000 nodes
/// let pois = [1, 5, 10, 42]       // 4 points of interest
///
/// // Efficiently computes only POI-to-POI distances
/// case pathfinding.distance_matrix(
///   in: graph,
///   between: pois,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(distances) -> {
///     // Get distance from POI 1 to POI 42
///     dict.get(distances, #(1, 42))
///   }
///   Error(Nil) -> panic as "Negative cycle detected"
/// }
/// ```
///
/// ## Use Cases
///
/// - AoC 2016 Day 24: Computing distances between numbered locations
/// - TSP-like problems: Finding optimal tour through specific landmarks
/// - Network analysis: Distances between server hubs
/// - Game pathfinding: Distances between quest objectives
///
/// ## Algorithm Selection
///
/// The function automatically chooses the optimal algorithm:
/// - **Floyd-Warshall** when POIs are dense: Computes all-pairs shortest paths once,
///   then filters to POIs. Efficient when you need distances for most nodes.
/// - **Multiple Dijkstra** when POIs are sparse: Runs single-source shortest paths
///   from each POI. Efficient when POIs are much fewer than total nodes.
///
pub fn distance_matrix(
  in graph: Graph(n, e),
  between points_of_interest: List(NodeId),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let num_nodes = dict.size(graph.nodes)
  let num_pois = list.length(points_of_interest)
  let poi_set = set.from_list(points_of_interest)

  // Choose algorithm based on POI density
  // Floyd-Warshall: O(V³)
  // Multiple Dijkstra: O(P × (V + E) log V) where P = num_pois
  // Crossover heuristic: P > V/3
  case num_pois * 3 > num_nodes {
    True -> {
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
    False -> {
      // Sparse POIs: Run single_source_distances from each POI
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
