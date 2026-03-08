import gleam/dict.{type Dict}
import gleam/list
import gleam/order.{type Order, Lt}
import yog/model.{type Graph, type NodeId}

// ======================== FLOYD-WARSHALL ========================

/// Computes shortest paths between all pairs of nodes using the Floyd-Warshall algorithm.
///
/// Returns a nested dictionary where `distances[i][j]` gives the shortest distance from node `i` to node `j`.
/// If no path exists between two nodes, the pair will not be present in the dictionary.
///
/// Returns `Error(Nil)` if a negative cycle is detected in the graph.
///
/// **Time Complexity:** O(V³)
/// **Space Complexity:** O(V²)
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., `0` for integers, `0.0` for floats)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import gleam/int
/// import gleam/io
/// import yog
/// import yog/pathfinding
///
/// pub fn main() {
///   let graph =
///     yog.directed()
///     |> yog.add_node(1, "A")
///     |> yog.add_node(2, "B")
///     |> yog.add_node(3, "C")
///     |> yog.add_edge(from: 1, to: 2, with: 4)
///     |> yog.add_edge(from: 2, to: 3, with: 3)
///     |> yog.add_edge(from: 1, to: 3, with: 10)
///
///   case pathfinding.floyd_warshall(
///     in: graph,
///     with_zero: 0,
///     with_add: int.add,
///     with_compare: int.compare
///   ) {
///     Ok(distances) -> {
///       // Query distance from node 1 to node 3
///       let assert Ok(row) = dict.get(distances, 1)
///       let assert Ok(dist) = dict.get(row, 3)
///       // dist = 7 (via node 2: 4 + 3)
///       io.println("Distance from 1 to 3: " <> int.to_string(dist))
///     }
///     Error(Nil) -> io.println("Negative cycle detected!")
///   }
/// }
/// ```
///
/// ## Handling Negative Weights
///
/// Floyd-Warshall can handle negative edge weights and will detect negative cycles:
///
/// ```gleam
/// let graph_with_negative_cycle =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_edge(from: 1, to: 2, with: 5)
///   |> yog.add_edge(from: 2, to: 1, with: -10)
///
/// case pathfinding.floyd_warshall(
///   in: graph_with_negative_cycle,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(_) -> io.println("No negative cycle")
///   Error(Nil) -> io.println("Negative cycle detected!")  // This will execute
/// }
/// ```
///
/// ## Use Cases
///
/// - Computing distance matrices for all node pairs
/// - Finding transitive closure of a graph
/// - Detecting negative cycles
/// - Preprocessing for queries about arbitrary node pairs
/// - Graph metrics (diameter, centrality)
///
pub fn floyd_warshall(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let nodes = dict.keys(graph.nodes)

  let initial_distances =
    nodes
    |> list.fold(dict.new(), fn(distances, i) {
      nodes
      |> list.fold(distances, fn(distances, j) {
        case i == j {
          True -> {
            case dict.get(graph.out_edges, i) {
              Ok(neighbors) ->
                case dict.get(neighbors, j) {
                  Ok(weight) -> {
                    case compare(weight, zero) {
                      Lt -> dict.insert(distances, #(i, j), weight)
                      _ -> dict.insert(distances, #(i, j), zero)
                    }
                  }
                  Error(Nil) -> dict.insert(distances, #(i, j), zero)
                }
              Error(Nil) -> dict.insert(distances, #(i, j), zero)
            }
          }
          False -> {
            case dict.get(graph.out_edges, i) {
              Ok(neighbors) ->
                case dict.get(neighbors, j) {
                  Ok(weight) -> dict.insert(distances, #(i, j), weight)
                  Error(Nil) -> distances
                }
              Error(Nil) -> distances
            }
          }
        }
      })
    })

  let final_distances =
    nodes
    |> list.fold(initial_distances, fn(distances, k) {
      nodes
      |> list.fold(distances, fn(distances, i) {
        nodes
        |> list.fold(distances, fn(distances, j) {
          case dict.get(distances, #(i, k)) {
            Error(Nil) -> distances
            Ok(dist_ik) -> {
              case dict.get(distances, #(k, j)) {
                Error(Nil) -> distances
                Ok(dist_kj) -> {
                  let new_dist = add(dist_ik, dist_kj)
                  case dict.get(distances, #(i, j)) {
                    Error(Nil) -> dict.insert(distances, #(i, j), new_dist)
                    Ok(current_dist) -> {
                      case compare(new_dist, current_dist) {
                        Lt -> dict.insert(distances, #(i, j), new_dist)
                        _ -> distances
                      }
                    }
                  }
                }
              }
            }
          }
        })
      })
    })

  case detect_negative_cycle(final_distances, nodes, zero, compare) {
    True -> Error(Nil)
    False -> Ok(final_distances)
  }
}

/// Detects if there's a negative cycle by checking if any node has negative distance to itself
pub fn detect_negative_cycle(
  distances: Dict(#(NodeId, NodeId), e),
  nodes: List(NodeId),
  zero: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  nodes
  |> list.any(fn(i) {
    case dict.get(distances, #(i, i)) {
      Ok(dist) ->
        case compare(dist, zero) {
          Lt -> True
          _ -> False
        }
      Error(Nil) -> False
    }
  })
}
