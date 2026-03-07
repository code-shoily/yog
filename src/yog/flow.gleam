import gleam/order.{type Order}
import yog/flow/max_flow
import yog/flow/min_cut
import yog/flow/network_simplex
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

pub fn global_min_cut(in graph: model.Graph(n, Int)) -> GlobalMinCut {
  min_cut.global_min_cut(graph)
}
