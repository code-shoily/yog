//// Floyd-Warshall algorithm for all-pairs shortest paths.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order, Lt}
import yog/model.{type Graph, type NodeId}

/// Computes shortest paths between all pairs of nodes using Floyd-Warshall.
///
/// **Time Complexity:** O(V³)
///
/// Returns an error if a negative cycle is detected.
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

// -----------------------------------------------------------------------------
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// -----------------------------------------------------------------------------

/// Computes all-pairs shortest paths with **integer weights**.
///
/// This is a convenience wrapper around `floyd_warshall` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
///
/// ## Example
///
/// ```gleam
/// let result = floyd_warshall.floyd_warshall_int(graph)
/// // => Ok(Dict([#(#(1, 2), 10), #(#(1, 3), 25), ...]))
/// ```
///
/// ## When to Use
///
/// Use this for dense graphs where you need all-pairs distances with `Int`
/// weights. For sparse graphs or single-source queries, prefer Dijkstra.
/// Returns `Error(Nil)` if a negative cycle is detected.
pub fn floyd_warshall_int(
  in graph: Graph(n, Int),
) -> Result(Dict(#(NodeId, NodeId), Int), Nil) {
  floyd_warshall(
    graph,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
  )
}

/// Computes all-pairs shortest paths with **float weights**.
///
/// This is a convenience wrapper around `floyd_warshall` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
///
/// ## Warning
///
/// Float arithmetic has precision limitations. Negative cycles might not be
/// detected reliably due to floating-point errors.
pub fn floyd_warshall_float(
  in graph: Graph(n, Float),
) -> Result(Dict(#(NodeId, NodeId), Float), Nil) {
  floyd_warshall(
    graph,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
  )
}
