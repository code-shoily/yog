//// Optimized distance matrix computation for subsets of nodes.

import gleam/dict.{type Dict}
import gleam/list
import gleam/order.{type Order}
import gleam/set
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/dijkstra
import yog/pathfinding/floyd_warshall

/// Computes shortest distances between all pairs of points of interest.
///
/// Automatically chooses between Floyd-Warshall and multiple Dijkstra runs
/// based on the density of POIs relative to graph size.
///
/// **Time Complexity:** O(V³) or O(P × (V + E) log V)
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
