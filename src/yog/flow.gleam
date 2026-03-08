//// Maximum flow and minimum cost flow algorithms for network problems.
////
//// This module provides implementations of algorithms for solving various
//// network flow problems, including:
//// - **Maximum Flow:** Finding the maximum amount of flow between a source and sink.
//// - **Minimum Cut:** Finding the minimum set of edges that disconnect source and sink.
//// - **Minimum Cost Flow:** Finding the cheapest way to satisfy demands in a network.
//// - **Global Minimum Cut:** Finding the minimum cut for any partition of an undirected graph.
////
//// ## Algorithms
////
//// - **Network Simplex:** For minimum cost flow problems.
//// - **Edmonds-Karp:** For maximum flow (Ford-Fulkerson with BFS).
//// - **Stoer-Wagner:** For global minimum cut on undirected graphs.
////
//// ## Applications
////
//// - **Logistics:** Optimizing supply chain and distribution networks.
//// - **Network Analysis:** Bandwidth allocation and traffic routing.
//// - **Computer Vision:** Image segmentation and object tracking.
//// - **Combinatorics:** Bipartite matching and assignment problems.

import gleam/order.{type Order}
import yog/internal/flow/max_flow
import yog/internal/flow/min_cut
import yog/internal/flow/network_simplex
import yog/model

// Re-exports from Network Simplex
pub type FlowMap =
  network_simplex.FlowMap

pub type MinCostFlowResult =
  network_simplex.MinCostFlowResult

pub type NetworkSimplexError =
  network_simplex.NetworkSimplexError

/// Solves the Minimum Cost Flow problem for the given graph, node demands,
/// edge capacities, and edge costs using the Network Simplex algorithm.
///
/// Returns either the optimal flow assignment (along with the minimum cost)
/// or an error if the demands cannot be met or if the problem is unbounded.
///
/// **Time Complexity:** O(V²E) in the worst case, but typically much faster.
///
/// ## Parameters
///
/// - `graph`: The flow network
/// - `get_demand`: Function mapping node data to demand (positive for supply, negative for demand)
/// - `get_capacity`: Function mapping edge data to capacity
/// - `get_cost`: Function mapping edge data to unit cost
///
/// ## Example
///
/// ```gleam
/// let result = flow.min_cost_flow(
///   graph,
///   get_demand: fn(n) { n.demand },
///   get_capacity: fn(e) { e.capacity },
///   get_cost: fn(e) { e.cost }
/// )
/// ```
pub fn min_cost_flow(
  graph: model.Graph(n, e),
  get_demand: fn(n) -> Int,
  get_capacity: fn(e) -> Int,
  get_cost: fn(e) -> Int,
) -> Result(MinCostFlowResult, NetworkSimplexError) {
  network_simplex.solve(graph, get_demand, get_capacity, get_cost)
}

// Re-exports from max_flow
pub type MaxFlowResult(e) =
  max_flow.MaxFlowResult(e)

pub type MaxFlowMinCut =
  max_flow.MinCut

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
/// import yog/flow
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
/// let result = flow.edmonds_karp(
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
  in graph: model.Graph(n, e),
  from source: model.NodeId,
  to sink: model.NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_subtract subtract: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  with_min min: fn(e, e) -> e,
) -> max_flow.MaxFlowResult(e) {
  max_flow.edmonds_karp(graph, source, sink, zero, add, subtract, compare, min)
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
/// let result = flow.edmonds_karp(...)
/// let cut = flow.min_cut(result, with_zero: 0, with_compare: int.compare)
/// // cut.source_side contains nodes on source side
/// // cut.sink_side contains nodes on sink side
/// ```
pub fn min_cut(
  result: max_flow.MaxFlowResult(e),
  with_zero zero: e,
  with_compare compare: fn(e, e) -> Order,
) -> MaxFlowMinCut {
  max_flow.min_cut(result, zero, compare)
}

// Re-exports from min_cut
pub type GlobalMinCut =
  min_cut.MinCut

/// Finds the global minimum cut of an undirected weighted graph using the
/// Stoer-Wagner algorithm.
///
/// Returns the minimum cut weight and the sizes of the two partitions.
/// Perfect for AoC 2023 Day 25, where you need to find the cut of weight 3
/// and compute the product of partition sizes.
///
/// **Time Complexity:** O(V³) or O(VE + V² log V) with a good priority queue
///
/// ## Example
///
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_node(4, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///   |> yog.add_edge(from: 1, to: 4, with: 1)
///
/// let result = flow.global_min_cut(in: graph)
/// // result.weight == 2 (minimum cut)
/// // result.group_a_size * result.group_b_size == product of partition sizes
/// ```
pub fn global_min_cut(in graph: model.Graph(n, Int)) -> GlobalMinCut {
  min_cut.global_min_cut(graph)
}
