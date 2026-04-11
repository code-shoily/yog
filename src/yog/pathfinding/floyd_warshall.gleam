//// [Floyd-Warshall algorithm](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm) 
//// for all-pairs shortest paths in weighted graphs.
////
//// The Floyd-Warshall algorithm finds the shortest paths between all pairs of nodes
//// in a single execution. It uses dynamic programming to iteratively improve shortest
//// path estimates by considering each node as a potential intermediate vertex.
////
//// ## Algorithm
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | [Floyd-Warshall](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm) | `floyd_warshall/4` | O(V³) | Dense graphs, all-pairs paths |
////
//// ## Key Concepts
////
//// - **Dynamic Programming**: Builds solution from smaller subproblems
//// - **K-Intermediate Nodes**: After k iterations, paths use only nodes {1,...,k} as intermediates
//// - **Path Reconstruction**: Predecessor matrix allows full path recovery
//// - **Transitive Closure**: Can be adapted for reachability (boolean weights)
////
//// ## The DP Recurrence
////
//// ```
//// dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
//// ```
////
//// For each intermediate node k, check if going through k improves the path from i to j.
////
//// ## Comparison with Running Dijkstra V Times
////
//// | Approach | Complexity | Best For |
//// |----------|------------|----------|
//// | Floyd-Warshall | O(V³) | Dense graphs (E ≈ V²) |
//// | V × Dijkstra | O(V(V+E) log V) | Sparse graphs |
//// | Johnson's | O(V² log V + VE) | Sparse graphs with negative weights |
////
//// **Rule of thumb**: Use Floyd-Warshall when E > V × log V (fairly dense)
////
//// ## Negative Cycles
////
//// The algorithm can detect negative cycles: after completion, if any node has
//// dist[node][node] < 0, a negative cycle exists.
////
//// ## Variants
////
//// - **Transitive Closure**: Use boolean OR instead of min-plus (Warshall's algorithm)
//// - **Successor Matrix**: Track next hop for path reconstruction
////
//// ## Use Cases
////
//// - **All-pairs routing**: Precompute distances for fast lookup
//// - **Transitive closure**: Reachability queries in databases
//// - **Centrality metrics**: Closeness and betweenness calculations
//// - **Graph analysis**: Detecting negative cycles
////
//// ## History
////
//// Published independently by Robert Floyd (1962), Stephen Warshall (1962),
//// and Bernard Roy (1959). Floyd's version included path reconstruction.
////
//// ## References
////
//// - [Wikipedia: Floyd-Warshall Algorithm](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm)
//// - [Wikipedia: Warshall's Algorithm (Transitive Closure)](https://en.wikipedia.org/wiki/Transitive_closure#Computing_the_transitive_closure)
//// - [CP-Algorithms: Floyd-Warshall](https://cp-algorithms.com/graph/all-pair-shortest-path-floyd-warshall.html)
//// - [MIT 6.006: Dynamic Programming](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/)

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
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn floyd_warshall(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let nodes = dict.keys(graph.nodes)

  let initial_distances = {
    use dists, i <- list.fold(nodes, dict.new())
    // 1. Every node has distance zero to itself
    let dists = dict.insert(dists, #(i, i), zero)

    // 2. Initialize with actual edge weights
    use dists, neighbor <- list.fold(model.successors(graph, i), dists)
    let #(j, weight) = neighbor

    case dict.get(dists, #(i, j)) {
      Ok(curr) ->
        case compare(weight, curr) {
          Lt -> dict.insert(dists, #(i, j), weight)
          _ -> dists
        }
      Error(_) -> dict.insert(dists, #(i, j), weight)
    }
  }

  let final_distances = {
    use distances, k <- list.fold(nodes, initial_distances)
    use distances, i <- list.fold(nodes, distances)
    use distances, j <- list.fold(nodes, distances)

    let maybe_ik = dict.get(distances, #(i, k))
    let maybe_kj = dict.get(distances, #(k, j))

    case maybe_ik, maybe_kj {
      Ok(ik), Ok(kj) -> {
        let new_dist = add(ik, kj)
        case dict.get(distances, #(i, j)) {
          Ok(curr) ->
            case compare(new_dist, curr) {
              Lt -> dict.insert(distances, #(i, j), new_dist)
              _ -> distances
            }
          Error(_) -> dict.insert(distances, #(i, j), new_dist)
        }
      }
      _, _ -> distances
    }
  }

  case detect_negative_cycle(final_distances, nodes, zero, compare) {
    True -> Error(Nil)
    False -> Ok(final_distances)
  }
}

/// Detects if there's a negative cycle by checking if any node has negative distance to itself.
pub fn detect_negative_cycle(
  distances: Dict(#(NodeId, NodeId), e),
  nodes: List(NodeId),
  zero: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  use i <- list.any(nodes)
  case dict.get(distances, #(i, i)) {
    Ok(dist) -> compare(dist, zero) == Lt
    Error(_) -> False
  }
}

// ============================================================================
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// ============================================================================

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
    in: graph,
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
    in: graph,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
  )
}
