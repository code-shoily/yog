//// Maximum flow algorithms for network flow problems.
////
//// This module provides implementations of maximum flow algorithms, which solve
//// the problem of finding the maximum amount of "flow" that can be sent from a
//// source node to a sink node in a flow network, respecting edge capacity constraints.
////
//// ## Algorithms
////
//// - **Edmonds-Karp** - Ford-Fulkerson with BFS for finding augmenting paths
////   - Time Complexity: O(VE²)
////   - Most straightforward and reliable implementation
////   - Good performance for most practical problems
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/max_flow
//// import gleam/int
////
//// pub fn main() {
////   // Create a flow network
////   // Edges represent capacity constraints
////   let network =
////     yog.directed()
////     |> yog.add_edge(from: 0, to: 1, with: 10)  // source to A, capacity 10
////     |> yog.add_edge(from: 0, to: 2, with: 10)  // source to B, capacity 10
////     |> yog.add_edge(from: 1, to: 3, with: 4)   // A to C, capacity 4
////     |> yog.add_edge(from: 1, to: 2, with: 2)   // A to B, capacity 2
////     |> yog.add_edge(from: 2, to: 3, with: 9)   // B to C, capacity 9
////
////   let result = max_flow.edmonds_karp(
////     in: network,
////     from: 0,  // source
////     to: 3,    // sink
////     with_zero: 0,
////     with_add: int.add,
////     with_subtract: fn(a, b) { a - b },
////     with_compare: int.compare,
////     with_min: int.min,
////   )
////
////   // result.max_flow => 13
////   // result.min_cut => [0] on one side, [1, 2, 3] on other
//// }
//// ```
////
//// ## Applications
////
//// - **Network flow optimization** - Bandwidth allocation, traffic routing, pipe networks
//// - **Bipartite matching** - Assignment problems, job scheduling
//// - **Min-cut problems** - Network reliability, graph partitioning via max-flow min-cut theorem
//// - **Image segmentation** - Computer vision applications
//// - **Circulation with demands** - Supply chain, resource distribution
//// - **Project selection** - Maximize profit subject to dependencies

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{type Order, Gt}
import gleam/result
import gleam/set.{type Set}
import yog/internal/queue
import yog/model.{type Graph, type NodeId}

// Flat map of residual capacities for efficient updates
type Residuals(e) =
  Dict(#(NodeId, NodeId), e)

// Adjacency list for efficient neighbor lookups during BFS/DFS
type AdjacencyList =
  Dict(NodeId, List(NodeId))

/// Result of a max flow computation.
///
/// Contains both the maximum flow value and information needed to extract
/// the minimum cut.
pub type MaxFlowResult(e) {
  MaxFlowResult(
    /// The maximum flow value from source to sink
    max_flow: e,
    /// The residual graph after flow computation (has remaining capacities)
    residual_graph: Graph(Nil, e),
    /// The source node
    source: NodeId,
    /// The sink node
    sink: NodeId,
  )
}

/// Represents a minimum cut in the network.
///
/// A cut partitions the nodes into two sets: those reachable from the source
/// in the residual graph (source_side) and the rest (sink_side).
/// The capacity of the cut equals the max flow by the max-flow min-cut theorem.
pub type MinCut {
  MinCut(
    /// Nodes reachable from source (source side of cut)
    source_side: Set(NodeId),
    /// Nodes on sink side of cut
    sink_side: Set(NodeId),
  )
}

/// Finds the maximum flow using the Edmonds-Karp algorithm.
///
/// Edmonds-Karp is a specific implementation of the Ford-Fulkerson method
/// that uses BFS to find the shortest augmenting path. This guarantees
/// O(VE²) time complexity.
///
/// **Time Complexity:** O(VE²)
///
/// ## Parameters
///
/// - `in` - The flow network (directed graph where edge weights are capacities)
/// - `from` - The source node (where flow originates)
/// - `to` - The sink node (where flow terminates)
/// - `with_zero` - The zero element for the capacity type (e.g., 0 for Int)
/// - `with_add` - Function to add two capacity values
/// - `with_subtract` - Function to subtract capacity values
/// - `with_compare` - Function to compare capacity values
/// - `with_min` - Function to find minimum of two capacity values
///
/// ## Returns
///
/// A `MaxFlowResult` containing:
/// - The maximum flow value
/// - The residual graph (for extracting flow paths or min-cut)
/// - Source and sink node IDs
///
/// ## Example
///
/// ```gleam
/// import gleam/int
/// import yog
/// import yog/max_flow
///
/// let network =
///   yog.directed()
///   |> yog.add_edge(from: 0, to: 1, with: 16)
///   |> yog.add_edge(from: 0, to: 2, with: 13)
///   |> yog.add_edge(from: 1, to: 2, with: 10)
///   |> yog.add_edge(from: 1, to: 3, with: 12)
///   |> yog.add_edge(from: 2, to: 1, with: 4)
///   |> yog.add_edge(from: 2, to: 4, with: 14)
///   |> yog.add_edge(from: 3, to: 2, with: 9)
///   |> yog.add_edge(from: 3, to: 5, with: 20)
///   |> yog.add_edge(from: 4, to: 3, with: 7)
///   |> yog.add_edge(from: 4, to: 5, with: 4)
///
/// let result = max_flow.edmonds_karp(
///   in: network,
///   from: 0,
///   to: 5,
///   with_zero: 0,
///   with_add: int.add,
///   with_subtract: fn(a, b) { a - b },
///   with_compare: int.compare,
///   with_min: int.min,
/// )
///
/// // result.max_flow => 23
/// ```
pub fn edmonds_karp(
  in graph: Graph(n, e),
  from source: NodeId,
  to sink: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_subtract subtract: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_min min: fn(e, e) -> e,
) -> MaxFlowResult(e) {
  // Early exit if source == sink
  case source == sink {
    True -> {
      let empty_graph = model.new(model.Directed)
      MaxFlowResult(
        max_flow: zero,
        residual_graph: empty_graph,
        source: source,
        sink: sink,
      )
    }
    False -> {
      // Build initial residual capacities as flat dict
      let #(residuals, all_nodes) = build_residuals(graph, zero)

      // Build adjacency list once - structure doesn't change, only capacities do
      let adj_list = build_adjacency_list(residuals)

      // Run tail-recursive Ford-Fulkerson with BFS (Edmonds-Karp)
      let #(final_residuals, total_flow) =
        ford_fulkerson(
          residuals,
          adj_list,
          source,
          sink,
          zero,
          zero,
          add,
          subtract,
          compare,
          min,
        )

      // Convert residuals back to Graph for min-cut extraction
      let residual_graph = residuals_to_graph(final_residuals, all_nodes)

      MaxFlowResult(
        max_flow: total_flow,
        residual_graph: residual_graph,
        source: source,
        sink: sink,
      )
    }
  }
}

/// Extracts the minimum cut from a max flow result.
///
/// Uses the max-flow min-cut theorem: the minimum cut can be found by
/// identifying all nodes reachable from the source in the residual graph
/// after computing max flow.
///
/// The cut separates nodes reachable from source (source_side) from the
/// rest (sink_side). The capacity of edges crossing from source_side to
/// sink_side equals the max flow value.
///
/// ## Parameters
///
/// - `result` - The max flow result from `edmonds_karp`
/// - `with_zero` - The zero element for the capacity type
/// - `with_compare` - Function to compare capacity values
///
/// ## Example
///
/// ```gleam
/// let result = max_flow.edmonds_karp(...)
/// let cut = max_flow.min_cut(result, with_zero: 0, with_compare: int.compare)
/// // cut.source_side contains nodes on source side
/// // cut.sink_side contains nodes on sink side
/// ```
pub fn min_cut(
  result: MaxFlowResult(e),
  with_zero zero: e,
  with_compare compare: fn(e, e) -> Order,
) -> MinCut {
  // Find all nodes reachable from source in residual graph (via edges with positive capacity)
  let reachable =
    find_reachable_nodes(result.residual_graph, result.source, zero, compare)

  // All other nodes are on the sink side
  let all_nodes = model.all_nodes(result.residual_graph) |> set.from_list()
  let sink_side = set.difference(all_nodes, reachable)

  MinCut(source_side: reachable, sink_side: sink_side)
}

// Build flat residual capacities dict with forward and backward edges
fn build_residuals(graph: Graph(n, e), zero: e) -> #(Residuals(e), Set(NodeId)) {
  // Get all nodes that appear in edges (both as source and destination)
  let nodes_set =
    extract_all_nodes_from_edges(graph)
    |> set.union(set.from_list(model.all_nodes(graph)))

  let all_nodes_list = set.to_list(nodes_set)

  // Build flat dict of capacities
  let residuals =
    list.fold(all_nodes_list, dict.new(), fn(caps, node_id) {
      let successors = model.successors(graph, node_id)
      list.fold(successors, caps, fn(acc, edge) {
        let #(neighbor, capacity) = edge
        // Add forward edge
        let with_forward = dict.insert(acc, #(node_id, neighbor), capacity)
        // Add backward edge if it doesn't exist
        case dict.has_key(with_forward, #(neighbor, node_id)) {
          True -> with_forward
          False -> dict.insert(with_forward, #(neighbor, node_id), zero)
        }
      })
    })

  #(residuals, nodes_set)
}

// Build adjacency list from residuals for O(1) neighbor lookup
fn build_adjacency_list(residuals: Residuals(e)) -> AdjacencyList {
  dict.fold(residuals, dict.new(), fn(adj, edge, _capacity) {
    let #(from, to) = edge
    dict.upsert(adj, from, fn(existing) {
      case existing {
        Some(neighbors) -> [to, ..neighbors]
        None -> [to]
      }
    })
  })
}

// Tail-recursive Ford-Fulkerson algorithm with BFS for finding augmenting paths
fn ford_fulkerson(
  residuals: Residuals(e),
  adj_list: AdjacencyList,
  source: NodeId,
  sink: NodeId,
  total_flow: e,
  zero: e,
  add: fn(e, e) -> e,
  subtract: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
  min: fn(e, e) -> e,
) -> #(Residuals(e), e) {
  // Try to find an augmenting path
  case
    find_augmenting_path_bfs(
      residuals,
      adj_list,
      source,
      sink,
      zero,
      compare,
      min,
    )
  {
    Error(Nil) -> #(residuals, total_flow)
    Ok(#(path, bottleneck)) -> {
      // Augment flow along the path - fast dict updates
      let new_residuals =
        augment_path(residuals, path, bottleneck, add, subtract)

      // Reuse adjacency list - structure unchanged, only capacities change
      // BFS will skip edges with zero capacity via has_capacity check
      ford_fulkerson(
        new_residuals,
        adj_list,
        source,
        sink,
        add(total_flow, bottleneck),
        zero,
        add,
        subtract,
        compare,
        min,
      )
    }
  }
}

// BFS to find shortest augmenting path with positive capacity
fn find_augmenting_path_bfs(
  residuals: Residuals(e),
  adj_list: AdjacencyList,
  source: NodeId,
  sink: NodeId,
  zero: e,
  compare: fn(e, e) -> Order,
  min: fn(e, e) -> e,
) -> Result(#(List(NodeId), e), Nil) {
  // BFS with parent tracking using two-list queue for O(1) operations
  let initial_queue = queue.new() |> queue.push(source)
  do_bfs(
    residuals,
    adj_list,
    initial_queue,
    dict.from_list([#(source, #(-1, zero))]),
    sink,
    zero,
    compare,
    min,
  )
}

fn do_bfs(
  residuals: Residuals(e),
  adj_list: AdjacencyList,
  q: queue.Queue(NodeId),
  parents: Dict(NodeId, #(NodeId, e)),
  sink: NodeId,
  zero: e,
  compare: fn(e, e) -> Order,
  min: fn(e, e) -> e,
) -> Result(#(List(NodeId), e), Nil) {
  case queue.pop(q) {
    Error(Nil) -> Error(Nil)
    Ok(#(current, rest)) -> {
      case current == sink {
        True -> {
          // Reconstruct path and find bottleneck
          let #(path, bottleneck) = reconstruct_path(parents, sink, zero, min)
          Ok(#(path, bottleneck))
        }
        False -> {
          // Get neighbors from adjacency list (O(1) lookup)
          let neighbors = dict.get(adj_list, current) |> result.unwrap([])

          // Find neighbors with positive capacity
          let #(new_neighbors, new_parents) =
            list.fold(neighbors, #([], parents), fn(acc, neighbor) {
              let #(neighbors_acc, parents_acc) = acc

              // Look up capacity for edge current -> neighbor
              let cap =
                dict.get(residuals, #(current, neighbor)) |> result.unwrap(zero)

              // Only visit if not visited and has positive capacity
              let already_visited = dict.has_key(parents_acc, neighbor)
              let has_capacity = compare(cap, zero) == Gt

              case already_visited || !has_capacity {
                True -> acc
                False -> {
                  let updated_parents =
                    dict.insert(parents_acc, neighbor, #(current, cap))
                  // Prepend neighbor (O(1))
                  #([neighbor, ..neighbors_acc], updated_parents)
                }
              }
            })

          // O(1) amortized enqueue - no more O(n) list.append!
          let new_queue = queue.push_list(rest, new_neighbors)
          do_bfs(
            residuals,
            adj_list,
            new_queue,
            new_parents,
            sink,
            zero,
            compare,
            min,
          )
        }
      }
    }
  }
}

// Reconstruct path from parent map and find bottleneck capacity
fn reconstruct_path(
  parents: Dict(NodeId, #(NodeId, e)),
  sink: NodeId,
  zero: e,
  min: fn(e, e) -> e,
) -> #(List(NodeId), e) {
  do_reconstruct_path(parents, sink, [], zero, True, min)
}

fn do_reconstruct_path(
  parents: Dict(NodeId, #(NodeId, e)),
  current: NodeId,
  path: List(NodeId),
  bottleneck: e,
  is_first: Bool,
  min: fn(e, e) -> e,
) -> #(List(NodeId), e) {
  let new_path = [current, ..path]

  case dict.get(parents, current) {
    Error(Nil) -> #(new_path, bottleneck)
    Ok(#(parent, capacity)) -> {
      case parent {
        -1 -> #(new_path, bottleneck)
        _ -> {
          // Update bottleneck (skip first iteration since we don't have edge yet)
          let new_bottleneck = case is_first {
            True -> capacity
            False -> min(capacity, bottleneck)
          }
          do_reconstruct_path(
            parents,
            parent,
            new_path,
            new_bottleneck,
            False,
            min,
          )
        }
      }
    }
  }
}

// Augment flow along a path - fast dict updates
fn augment_path(
  residuals: Residuals(e),
  path: List(NodeId),
  bottleneck: e,
  add: fn(e, e) -> e,
  subtract: fn(e, e) -> e,
) -> Residuals(e) {
  do_augment_path(residuals, path, bottleneck, add, subtract)
}

fn do_augment_path(
  residuals: Residuals(e),
  path: List(NodeId),
  bottleneck: e,
  add: fn(e, e) -> e,
  subtract: fn(e, e) -> e,
) -> Residuals(e) {
  case path {
    [] | [_] -> residuals
    [from, to, ..rest] -> {
      // Fast capacity updates using dict operations
      let forward_key = #(from, to)
      let backward_key = #(to, from)

      let forward_cap =
        dict.get(residuals, forward_key) |> result.unwrap(bottleneck)
      let backward_cap =
        dict.get(residuals, backward_key) |> result.unwrap(bottleneck)

      // Update both edges in one pass
      let new_residuals =
        residuals
        |> dict.insert(forward_key, subtract(forward_cap, bottleneck))
        |> dict.insert(backward_key, add(backward_cap, bottleneck))

      do_augment_path(new_residuals, [to, ..rest], bottleneck, add, subtract)
    }
  }
}

// Convert flat residuals back to Graph structure (for min-cut)
fn residuals_to_graph(
  residuals: Residuals(e),
  all_nodes: Set(NodeId),
) -> Graph(Nil, e) {
  // Start with empty directed graph
  let graph =
    set.fold(all_nodes, model.new(model.Directed), fn(g, node) {
      model.add_node(g, node, Nil)
    })

  // Add all edges from residuals
  dict.fold(residuals, graph, fn(g, edge, capacity) {
    let #(from, to) = edge
    model.add_edge(g, from: from, to: to, with: capacity)
  })
}

// Extract all nodes that appear in edges (source or destination)
fn extract_all_nodes_from_edges(graph: Graph(n, e)) -> Set(NodeId) {
  // Get all source nodes (nodes with outgoing edges)
  let source_nodes = set.from_list(dict.keys(graph.out_edges))

  // Get all destination nodes (iterate through all edge lists)
  let dest_nodes =
    dict.values(graph.out_edges)
    |> list.flat_map(fn(edge_dict) { dict.keys(edge_dict) })
    |> set.from_list()

  set.union(source_nodes, dest_nodes)
}

// Find all nodes reachable from source via DFS on residual graph
// Only follows edges with positive capacity
fn find_reachable_nodes(
  residual: Graph(Nil, e),
  source: NodeId,
  zero: e,
  compare: fn(e, e) -> Order,
) -> Set(NodeId) {
  do_dfs_reachable(residual, [source], set.new(), zero, compare)
}

fn do_dfs_reachable(
  residual: Graph(Nil, e),
  stack: List(NodeId),
  visited: Set(NodeId),
  zero: e,
  compare: fn(e, e) -> Order,
) -> Set(NodeId) {
  case stack {
    [] -> visited
    [current, ..rest] -> {
      case set.contains(visited, current) {
        True -> do_dfs_reachable(residual, rest, visited, zero, compare)
        False -> {
          let new_visited = set.insert(visited, current)
          // Add all unvisited neighbors with positive capacity to stack
          // Use fold to prepend (O(1)) instead of append (O(n))
          let new_stack =
            model.successors(residual, current)
            |> list.fold(rest, fn(stack_acc, edge) {
              let #(node, capacity) = edge
              case
                !set.contains(new_visited, node)
                && compare(capacity, zero) == Gt
              {
                True -> [node, ..stack_acc]
                False -> stack_acc
              }
            })

          do_dfs_reachable(residual, new_stack, new_visited, zero, compare)
        }
      }
    }
  }
}
