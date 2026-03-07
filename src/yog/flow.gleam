import gleam/order.{type Order}
import yog/flow/max_flow
import yog/flow/min_cut
import yog/model.{type Graph, type NodeId}

pub type MaxFlowResult(e) =
  max_flow.MaxFlowResult(e)

pub type SourceSinkCut =
  max_flow.MinCut

pub type GlobalMinCut =
  min_cut.MinCut

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
  max_flow.edmonds_karp(
    in: graph,
    from: source,
    to: sink,
    with_zero: zero,
    with_add: add,
    with_subtract: subtract,
    with_compare: compare,
    with_min: min,
  )
}

pub fn min_cut(
  result: MaxFlowResult(e),
  with_zero zero: e,
  with_compare compare: fn(e, e) -> Order,
) -> SourceSinkCut {
  max_flow.min_cut(result, with_zero: zero, with_compare: compare)
}

pub fn global_min_cut(in graph: Graph(n, Int)) -> GlobalMinCut {
  min_cut.global_min_cut(in: graph)
}
