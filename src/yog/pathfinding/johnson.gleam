//// [Johnson's algorithm](https://en.wikipedia.org/wiki/Johnson%27s_algorithm) for
//// all-pairs shortest paths in weighted graphs with negative edge weights.
////
//// Johnson's algorithm efficiently computes shortest paths between all pairs of nodes
//// in sparse graphs, even when edges have negative weights (but no negative cycles).
//// It combines Bellman-Ford and Dijkstra's algorithms with a reweighting technique.
////
//// ## Algorithm
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | [Johnson's](https://en.wikipedia.org/wiki/Johnson%27s_algorithm) | `johnson/4` | O(V² log V + VE) | Sparse graphs with negative weights |
////
//// ## Key Concepts
////
//// - **Reweighting**: Transform negative weights to non-negative while preserving shortest paths
//// - **Bellman-Ford Phase**: Compute reweighting function and detect negative cycles
//// - **Dijkstra Phase**: Run Dijkstra from each vertex on reweighted graph
//// - **Distance Adjustment**: Transform reweighted distances back to original weights
////
//// ## How Reweighting Works
////
//// The algorithm computes a potential function `h(v)` for each vertex such that:
//// ```
//// w'(u,v) = w(u,v) + h(u) - h(v) ≥ 0
//// ```
////
//// This transformation preserves shortest paths because for any path p = v₁→v₂→...→vₖ:
//// ```
//// w'(p) = w(p) + h(v₁) - h(vₖ)
//// ```
////
//// So the relative ordering of path weights remains the same!
////
//// ## The Algorithm Steps
////
//// 1. **Add temporary source**: Create new vertex `s` with 0-weight edges to all vertices
//// 2. **Run Bellman-Ford**: From `s` to compute h(v) = distance[v] and detect negative cycles
//// 3. **Reweight edges**: Set w'(u,v) = w(u,v) + h(u) - h(v) for all edges
//// 4. **Run V × Dijkstra**: Compute shortest paths on reweighted graph
//// 5. **Adjust distances**: Set dist(u,v) = dist'(u,v) - h(u) + h(v)
////
//// ## Comparison with Other All-Pairs Algorithms
////
//// | Approach | Complexity | Best For |
//// |----------|------------|----------|
//// | Floyd-Warshall | O(V³) | Dense graphs (E ≈ V²) |
//// | Johnson's | O(V² log V + VE) | Sparse graphs (E ≪ V²) |
//// | V × Dijkstra | O(V(V+E) log V) | Sparse graphs, non-negative weights only |
//// | V × Bellman-Ford | O(V²E) | Rarely optimal |
////
//// **Rule of thumb**:
//// - Use Johnson's for sparse graphs with negative weights
//// - Use Floyd-Warshall for dense graphs or when simplicity matters
//// - Use V × Dijkstra for sparse graphs with only non-negative weights
////
//// ## Complexity Analysis
////
//// - **Bellman-Ford phase**: O(VE) - run once
//// - **Dijkstra phase**: O(V × (V+E) log V) = O(V² log V + VE) - run V times
//// - **Total**: O(V² log V + VE)
////
//// For sparse graphs where E = O(V), this is O(V² log V), much better than
//// Floyd-Warshall's O(V³)!
////
//// ## Negative Cycles
////
//// The algorithm detects negative cycles during the Bellman-Ford phase.
//// If a negative cycle exists, the function returns `Error(Nil)`.
////
//// ## Use Cases
////
//// - **Sparse road networks**: Computing all-pairs distances with tolls/credits
//// - **Currency arbitrage**: Finding profitable exchange cycles
//// - **Network routing**: Precomputing routing tables with various costs
//// - **Game AI**: Pathfinding in large sparse maps with varied terrain costs
////
//// ## History
////
//// Published by Donald B. Johnson in 1977. The algorithm is a brilliant
//// combination of Bellman-Ford's ability to handle negative weights and
//// Dijkstra's efficiency with non-negative weights.
////
//// ## References
////
//// - [Wikipedia: Johnson's Algorithm](https://en.wikipedia.org/wiki/Johnson%27s_algorithm)
//// - [Johnson's Original Paper (1977)](https://doi.org/10.1145/321992.321993)
//// - [CP-Algorithms: Johnson's Algorithm](https://cp-algorithms.com/graph/all-pair-shortest-path-johnson.html)
//// - [MIT 6.006: Advanced Shortest Paths](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order, Lt}
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/dijkstra

/// Computes shortest paths between all pairs of nodes using Johnson's algorithm.
///
/// **Time Complexity:** O(V² log V + VE)
///
/// Returns an error if a negative cycle is detected.
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `subtract`: Function to subtract two weights (for reweighting)
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// let result = johnson.johnson(
///   in: graph,
///   with_zero: 0,
///   with_add: int.add,
///   with_subtract: int.subtract,
///   with_compare: int.compare
/// )
/// // => Ok(Dict([#(#(1, 2), 10), #(#(1, 3), 25), ...]))
/// ```
///
/// ## When to Use
///
/// Use Johnson's algorithm for **sparse graphs** when you need all-pairs shortest
/// paths and the graph may contain negative edge weights (but no negative cycles).
/// For dense graphs, prefer Floyd-Warshall. For graphs with only non-negative
/// weights, consider running Dijkstra from each vertex directly.
pub fn johnson(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_subtract subtract: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let nodes = model.all_nodes(graph)

  // Step 1: Create a new node ID that doesn't exist in the graph
  let temp_source = find_new_node_id(nodes)

  // Step 2: Run Bellman-Ford from temp_source to compute h(v) for all v
  // and detect negative cycles
  case
    compute_reweighting_function(graph, temp_source, nodes, zero, add, compare)
  {
    Error(Nil) -> Error(Nil)
    Ok(h) -> {
      // Step 3: For each vertex, run Dijkstra on the reweighted graph
      let all_pairs_distances =
        list.fold(nodes, dict.new(), fn(distances, u) {
          let distances_from_u =
            dijkstra.single_source_distances(
              in: reweight_graph(graph, h, zero, add, subtract),
              from: u,
              with_zero: zero,
              with_add: add,
              with_compare: compare,
            )

          // Step 4: Adjust distances back to original weights
          list.fold(nodes, distances, fn(acc, v) {
            case dict.get(distances_from_u, v) {
              Ok(dist_reweighted) -> {
                let h_u = dict.get(h, u) |> unwrap_or(zero)
                let h_v = dict.get(h, v) |> unwrap_or(zero)
                // dist(u,v) = dist'(u,v) - h(u) + h(v)
                let actual_dist = add(subtract(dist_reweighted, h_u), h_v)
                dict.insert(acc, #(u, v), actual_dist)
              }
              Error(Nil) -> acc
            }
          })
        })

      Ok(all_pairs_distances)
    }
  }
}

/// Finds a node ID that doesn't exist in the graph (for temporary source)
fn find_new_node_id(nodes: List(NodeId)) -> NodeId {
  case nodes {
    [] -> 0
    _ -> {
      let max_node =
        list.fold(nodes, 0, fn(max, node) {
          case node > max {
            True -> node
            False -> max
          }
        })
      max_node + 1
    }
  }
}

/// Runs Bellman-Ford to compute reweighting function h(v) for each vertex
fn compute_reweighting_function(
  graph: Graph(n, e),
  temp_source: NodeId,
  nodes: List(NodeId),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Result(Dict(NodeId, e), Nil) {
  // Add temporary source connected to all vertices with 0-weight edges
  let initial_distances = dict.from_list([#(temp_source, zero)])
  let initial_predecessors = dict.new()

  let node_count = list.length(nodes) + 1

  // Run relaxation passes from temp_source
  let #(distances, _predecessors) =
    bellman_ford_with_temp_source(
      graph,
      temp_source,
      [temp_source, ..nodes],
      initial_distances,
      initial_predecessors,
      node_count - 1,
      zero,
      add,
      compare,
    )

  // Check for negative cycles
  case
    has_negative_cycle_with_temp_source(
      graph,
      temp_source,
      nodes,
      distances,
      zero,
      add,
      compare,
    )
  {
    True -> Error(Nil)
    False -> Ok(distances)
  }
}

/// Modified Bellman-Ford relaxation that includes edges from temporary source
fn bellman_ford_with_temp_source(
  graph: Graph(n, e),
  temp_source: NodeId,
  all_nodes: List(NodeId),
  distances: Dict(NodeId, e),
  predecessors: Dict(NodeId, NodeId),
  remaining: Int,
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> #(Dict(NodeId, e), Dict(NodeId, NodeId)) {
  case remaining <= 0 {
    True -> #(distances, predecessors)
    False -> {
      let #(new_distances, new_predecessors) =
        list.fold(all_nodes, #(distances, predecessors), fn(acc, u) {
          let #(dists, preds) = acc

          case dict.get(dists, u) {
            Error(Nil) -> acc
            Ok(u_dist) -> {
              // Get neighbors from the graph, or all nodes if u is temp_source
              let neighbors = case u == temp_source {
                True ->
                  list.filter(all_nodes, fn(node) { node != temp_source })
                  |> list.map(fn(node) { #(node, zero) })
                False -> model.successors(graph, u)
              }

              list.fold(neighbors, #(dists, preds), fn(inner_acc, edge) {
                let #(v, weight) = edge
                let #(curr_dists, curr_preds) = inner_acc
                let new_dist = add(u_dist, weight)

                case dict.get(curr_dists, v) {
                  Error(Nil) -> #(
                    dict.insert(curr_dists, v, new_dist),
                    dict.insert(curr_preds, v, u),
                  )
                  Ok(v_dist) ->
                    case compare(new_dist, v_dist) {
                      Lt -> #(
                        dict.insert(curr_dists, v, new_dist),
                        dict.insert(curr_preds, v, u),
                      )
                      _ -> inner_acc
                    }
                }
              })
            }
          }
        })

      bellman_ford_with_temp_source(
        graph,
        temp_source,
        all_nodes,
        new_distances,
        new_predecessors,
        remaining - 1,
        zero,
        add,
        compare,
      )
    }
  }
}

/// Checks for negative cycles including edges from temporary source
fn has_negative_cycle_with_temp_source(
  graph: Graph(n, e),
  temp_source: NodeId,
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  zero: e,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Bool {
  let all_nodes = [temp_source, ..nodes]

  list.any(all_nodes, fn(u) {
    case dict.get(distances, u) {
      Error(Nil) -> False
      Ok(u_dist) -> {
        let neighbors = case u == temp_source {
          True ->
            list.filter(all_nodes, fn(node) { node != temp_source })
            |> list.map(fn(node) { #(node, zero) })
          False -> model.successors(graph, u)
        }

        list.any(neighbors, fn(edge) {
          let #(v, weight) = edge
          let new_dist = add(u_dist, weight)

          case dict.get(distances, v) {
            Error(Nil) -> False
            Ok(v_dist) ->
              case compare(new_dist, v_dist) {
                Lt -> True
                _ -> False
              }
          }
        })
      }
    }
  })
}

/// Creates a new graph with reweighted edges: w'(u,v) = w(u,v) + h(u) - h(v)
fn reweight_graph(
  graph: Graph(n, e),
  h: Dict(NodeId, e),
  zero: e,
  add: fn(e, e) -> e,
  subtract: fn(e, e) -> e,
) -> Graph(n, e) {
  let new_out_edges =
    dict.fold(graph.out_edges, dict.new(), fn(acc, u, neighbors) {
      let h_u = dict.get(h, u) |> unwrap_or(zero)
      let new_neighbors =
        dict.fold(neighbors, dict.new(), fn(inner_acc, v, weight) {
          let h_v = dict.get(h, v) |> unwrap_or(zero)
          // w'(u,v) = w(u,v) + h(u) - h(v)
          let new_weight = subtract(add(weight, h_u), h_v)
          dict.insert(inner_acc, v, new_weight)
        })
      dict.insert(acc, u, new_neighbors)
    })

  let new_in_edges =
    dict.fold(graph.in_edges, dict.new(), fn(acc, v, sources) {
      let h_v = dict.get(h, v) |> unwrap_or(zero)
      let new_sources =
        dict.fold(sources, dict.new(), fn(inner_acc, u, weight) {
          let h_u = dict.get(h, u) |> unwrap_or(zero)
          // w'(u,v) = w(u,v) + h(u) - h(v)
          let new_weight = subtract(add(weight, h_u), h_v)
          dict.insert(inner_acc, u, new_weight)
        })
      dict.insert(acc, v, new_sources)
    })

  model.Graph(..graph, out_edges: new_out_edges, in_edges: new_in_edges)
}

/// Helper to unwrap Result with a provided default value
fn unwrap_or(result: Result(a, b), default: a) -> a {
  case result {
    Ok(value) -> value
    Error(_) -> default
  }
}

// -----------------------------------------------------------------------------
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// -----------------------------------------------------------------------------

/// Computes all-pairs shortest paths with **integer weights** using Johnson's algorithm.
///
/// This is a convenience wrapper around `johnson` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.subtract` for subtraction
/// - `int.compare` for comparison
///
/// ## Example
///
/// ```gleam
/// let result = johnson.johnson_int(graph)
/// // => Ok(Dict([#(#(1, 2), 10), #(#(1, 3), 25), ...]))
/// ```
///
/// ## When to Use
///
/// Use this for **sparse graphs** where you need all-pairs distances with `Int`
/// weights that may be negative. For dense graphs, prefer `floyd_warshall_int`.
/// For graphs with only non-negative weights, consider running `dijkstra` V times.
///
/// Returns `Error(Nil)` if a negative cycle is detected.
pub fn johnson_int(
  in graph: Graph(n, Int),
) -> Result(Dict(#(NodeId, NodeId), Int), Nil) {
  johnson(
    graph,
    with_zero: 0,
    with_add: int.add,
    with_subtract: int.subtract,
    with_compare: int.compare,
  )
}

/// Computes all-pairs shortest paths with **float weights** using Johnson's algorithm.
///
/// This is a convenience wrapper around `johnson` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.subtract` for subtraction
/// - `float.compare` for comparison
///
/// ## Warning
///
/// Float arithmetic has precision limitations. Negative cycles might not be
/// detected reliably due to floating-point errors. Prefer `Int` weights for
/// critical calculations.
pub fn johnson_float(
  in graph: Graph(n, Float),
) -> Result(Dict(#(NodeId, NodeId), Float), Nil) {
  johnson(
    graph,
    with_zero: 0.0,
    with_add: float.add,
    with_subtract: float.subtract,
    with_compare: float.compare,
  )
}
