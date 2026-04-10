//// Brandes' algorithm for betweenness centrality.
////
//// Shared implementation of Dijkstra-based shortest-path discovery
//// and dependency accumulation used by betweenness centrality and
//// edge-betweenness-based community detection.

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/order.{type Order, Gt}
import gleam/result
import yog/internal/priority_queue as pq
import yog/model.{type Graph, type NodeId}

pub type BrandesDiscovery =
  #(List(NodeId), Dict(NodeId, List(NodeId)), Dict(NodeId, Int))

pub fn run_discovery(
  graph: Graph(n, e),
  source: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> BrandesDiscovery {
  let queue =
    pq.new(fn(a: #(e, NodeId), b: #(e, NodeId)) { compare(a.0, b.0) })
    |> pq.push(#(zero, source))

  let dists = dict.from_list([#(source, zero)])
  let sigmas = dict.from_list([#(source, 1)])
  let preds = dict.new()
  let stack = []

  do_brandes_dijkstra(graph, queue, dists, sigmas, preds, stack, add, compare)
}

fn do_brandes_dijkstra(
  graph: Graph(n, e),
  queue: pq.Queue(#(e, NodeId)),
  dists: Dict(NodeId, e),
  sigmas: Dict(NodeId, Int),
  preds: Dict(NodeId, List(NodeId)),
  stack: List(NodeId),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> BrandesDiscovery {
  case pq.pop(queue) {
    Error(Nil) -> #(stack, preds, sigmas)
    Ok(#(#(d_v, v), rest_q)) -> {
      let current_best = dict.get(dists, v) |> result.unwrap(d_v)
      case compare(d_v, current_best) {
        Gt ->
          do_brandes_dijkstra(
            graph,
            rest_q,
            dists,
            sigmas,
            preds,
            stack,
            add,
            compare,
          )
        _ -> {
          let new_stack = [v, ..stack]

          let #(next_q, next_dists, next_sigmas, next_preds) =
            process_successors(
              graph,
              v,
              d_v,
              rest_q,
              dists,
              sigmas,
              preds,
              add,
              compare,
            )

          do_brandes_dijkstra(
            graph,
            next_q,
            next_dists,
            next_sigmas,
            next_preds,
            new_stack,
            add,
            compare,
          )
        }
      }
    }
  }
}

fn process_successors(
  graph: Graph(n, e),
  v: NodeId,
  d_v: e,
  queue: pq.Queue(#(e, NodeId)),
  dists: Dict(NodeId, e),
  sigmas: Dict(NodeId, Int),
  preds: Dict(NodeId, List(NodeId)),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> #(
  pq.Queue(#(e, NodeId)),
  Dict(NodeId, e),
  Dict(NodeId, Int),
  Dict(NodeId, List(NodeId)),
) {
  use state, edge <- list.fold(model.successors(graph, v), #(
    queue,
    dists,
    sigmas,
    preds,
  ))
  let #(q, ds, ss, ps) = state
  let #(w, weight) = edge
  let new_dist = add(d_v, weight)

  case dict.get(ds, w) {
    Error(Nil) -> #(
      pq.push(q, #(new_dist, w)),
      dict.insert(ds, w, new_dist),
      dict.insert(ss, w, get_sigma(ss, v)),
      dict.insert(ps, w, [v]),
    )
    Ok(old_dist) ->
      case compare(new_dist, old_dist) {
        order.Lt -> #(
          pq.push(q, #(new_dist, w)),
          dict.insert(ds, w, new_dist),
          dict.insert(ss, w, get_sigma(ss, v)),
          dict.insert(ps, w, [v]),
        )
        order.Eq -> #(
          q,
          ds,
          dict.upsert(ss, w, fn(curr) {
            option.unwrap(curr, 0) + get_sigma(ss, v)
          }),
          dict.upsert(ps, w, fn(curr) { [v, ..option.unwrap(curr, [])] }),
        )
        order.Gt -> state
      }
  }
}

pub fn get_sigma(sigmas: Dict(NodeId, Int), id: NodeId) -> Int {
  dict.get(sigmas, id) |> result.unwrap(0)
}

/// Accumulates node-level dependency deltas for standard betweenness.
pub fn accumulate_node_dependencies(
  discovery: BrandesDiscovery,
) -> Dict(NodeId, Float) {
  let #(stack, preds, sigmas) = discovery

  use deltas, v <- list.fold(stack, dict.new())
  let sigma_v = int.to_float(get_sigma(sigmas, v))
  let delta_v = dict.get(deltas, v) |> result.unwrap(0.0)
  let v_preds = dict.get(preds, v) |> result.unwrap([])

  use acc_deltas, u <- list.fold(v_preds, deltas)
  let sigma_u = int.to_float(get_sigma(sigmas, u))
  let fraction = sigma_u /. sigma_v *. { 1.0 +. delta_v }
  dict.upsert(acc_deltas, u, fn(curr) { option.unwrap(curr, 0.0) +. fraction })
}

/// Accumulates edge-level dependency deltas for edge betweenness.
pub fn accumulate_edge_dependencies(
  discovery: BrandesDiscovery,
) -> Dict(#(NodeId, NodeId), Float) {
  let #(stack, preds, sigmas) = discovery
  let node_deltas = dict.new()
  let edge_deltas = dict.new()

  let #(_node_deltas, final_edge_deltas) = {
    use acc, v <- list.fold(stack, #(node_deltas, edge_deltas))
    let #(nd, ed) = acc
    let sigma_v = int.to_float(get_sigma(sigmas, v))
    let delta_v = dict.get(nd, v) |> result.unwrap(0.0)
    let v_preds = dict.get(preds, v) |> result.unwrap([])

    use inner_acc, u <- list.fold(v_preds, #(nd, ed))
    let #(inner_nd, inner_ed) = inner_acc
    let sigma_u = int.to_float(get_sigma(sigmas, u))

    let c = { sigma_u /. sigma_v } *. { 1.0 +. delta_v }
    let edge = case u < v {
      True -> #(u, v)
      False -> #(v, u)
    }

    let new_nd =
      dict.upsert(inner_nd, u, fn(curr) { option.unwrap(curr, 0.0) +. c })
    let new_ed = dict.insert(inner_ed, edge, c)
    #(new_nd, new_ed)
  }

  final_edge_deltas
}
