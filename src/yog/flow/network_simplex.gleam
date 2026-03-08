//// Network Simplex algorithm for minimum cost flow.

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option}
import yog/model.{type Graph, type NodeId}

/// A flow vector assigning an amount of flow to each edge.
pub type FlowMap =
  List(#(model.NodeId, model.NodeId, Int))

/// Returned when Network Simplex succeeds.
pub type MinCostFlowResult {
  MinCostFlowResult(
    /// The optimal minimum cost of the flow routing.
    cost: Int,
    /// The flow amounts assigned to each edge to achieve the minimum cost.
    flow: FlowMap,
  )
}

/// Errors that can occur during Network Simplex optimization.
pub type NetworkSimplexError {
  /// The demands of the network cannot be satisfied given the edge capacities.
  Infeasible
  /// The network contains a negative-cost cycle with infinite capacity.
  Unbounded
  /// The sum of all node demands does not equal 0.
  UnbalancedDemands
}

/// A unified state object passed recursively through the pivot loop.
/// This maintains a tree data structure using flat indexed arrays for O(1) random access updates.
type OmniState {
  OmniState(
    node_count: Int,
    edge_count: Int,
    // Constant original graph metrics
    nodes: List(NodeId),
    demands: List(Int),
    // Parallel to nodes: D
    // Mapping arrays
    edge_sources: List(NodeId),
    // Parallel to edges: S
    edge_targets: List(NodeId),
    // Parallel to edges: T
    edge_capacities: List(Int),
    // Parallel to edges: U
    edge_costs: List(Int),
    // Parallel to edges: C
    // The current flow on each edge (indexed 0 to ec+nc-1)
    flows: List(Int),
    // Dual variables (node potentials) for each node (indexed 0 to nc-1)
    phis: List(Int),
    // Spanning tree thread metrics (indexed 0 to nc-1)
    parents: List(Int),
    edges: List(Int),
    sizes: List(Int),
    nexts: List(Int),
    prevs: List(Int),
    lasts: List(Int),
    // Block marking for Dantzig-Bland pivot selection
    blockmark: Int,
    /// The maximum possible value used as infinity for costs/capacities
    inf: Int,
  )
}

fn wget(collection: List(a), index: Int) -> a {
  let len = list.length(collection)
  let mod_idx = index % len
  let true_idx = case mod_idx < 0 {
    True -> mod_idx + len
    False -> mod_idx
  }
  let assert Ok(val) = collection |> list.drop(true_idx) |> list.first()
  val
}

fn wupdate(collection: List(a), index: Int, update: fn(a) -> a) -> List(a) {
  let len = list.length(collection)
  let mod_idx = index % len
  let true_idx = case mod_idx < 0 {
    True -> mod_idx + len
    False -> mod_idx
  }
  let before = list.take(collection, true_idx)
  let after = list.drop(collection, true_idx + 1)
  let assert Ok(val) = collection |> list.drop(true_idx) |> list.first()
  list.flatten([before, [update(val)], after])
}

fn wassoc(collection: List(a), index: Int, value: a) -> List(a) {
  wupdate(collection, index, fn(_) { value })
}

fn seq_do(start: Int, end: Int, acc: List(Int)) -> List(Int) {
  case start > end {
    True -> list.reverse(acc)
    False -> seq_do(start + 1, end, [start, ..acc])
  }
}

fn seq(start: Int, end: Int) -> List(Int) {
  seq_do(start, end, [])
}

// ----------
// INITIALIZATION
// ----------

/// Solves the Minimum Cost Flow problem using the Network Simplex algorithm.
///
/// Returns either the optimal flow assignment or an error.
///
/// **Time Complexity:** O(V²E) worst case.
///
/// ## Parameters
///
/// - `graph`: The flow network
/// - `get_demand`: Node demand mapping
/// - `get_capacity`: Edge capacity mapping
/// - `get_cost`: Edge unit cost mapping
pub fn min_cost_flow(
  graph: Graph(n, e),
  get_demand: fn(n) -> Int,
  get_capacity: fn(e) -> Int,
  get_cost: fn(e) -> Int,
) -> Result(MinCostFlowResult, NetworkSimplexError) {
  let extract_res = extract(graph, get_demand, get_capacity, get_cost)
  case extract_res {
    Error(err) -> Error(err)
    Ok(omni) -> {
      let max_pivots = int.max(500, omni.edge_count * 5)
      let ans =
        omni
        |> add_super_source()
        |> init_spanning_tree()
        |> pivot_loop(max_pivots)

      // Remove super source and extract flows
      summarize(ans, graph)
    }
  }
}

fn extract(
  graph: Graph(n, e),
  get_demand: fn(n) -> Int,
  get_capacity: fn(e) -> Int,
  get_cost: fn(e) -> Int,
) -> Result(OmniState, NetworkSimplexError) {
  let nodes = model.all_nodes(graph)
  let nc = list.length(nodes)
  let _ = case nc > 0 {
    True -> Nil
    False -> panic as "Graph has no nodes"
  }

  let _nodes_array = nodes
  let node_indices =
    nodes
    |> list.index_map(fn(n, i) { #(n, i) })
    |> dict.from_list()

  // Node demands
  let demands =
    nodes
    |> list.map(fn(n) {
      let assert Ok(ndata) = dict.get(graph.nodes, n)
      get_demand(ndata)
    })

  // Quick check: total demand must be 0
  let total_demand = list.fold(demands, 0, int.add)
  case total_demand == 0 {
    False -> Error(UnbalancedDemands)
    True -> {
      // Edges extraction
      let edges =
        dict.fold(graph.out_edges, [], fn(acc_out, src, targets) {
          dict.fold(targets, acc_out, fn(acc_in, dst, weight) {
            [#(src, dst, weight), ..acc_in]
          })
        })
      let ec = list.length(edges)

      // Map edges to their node indices
      let edge_sources =
        edges
        |> list.map(fn(e_val) {
          let #(src, _dst, _w) = e_val
          let assert Ok(idx) = dict.get(node_indices, src)
          idx
        })
      let edge_targets =
        edges
        |> list.map(fn(e_val) {
          let #(_src, dst, _w) = e_val
          let assert Ok(idx) = dict.get(node_indices, dst)
          idx
        })

      let edge_costs =
        list.map(edges, fn(e_val) {
          let #(_, _, w) = e_val
          get_cost(w)
        })
      let edge_capacities =
        list.map(edges, fn(e_val) {
          let #(_, _, w) = e_val
          get_capacity(w)
        })

      // Infinity bounds
      let sum_cap = int.absolute_value(list.fold(edge_capacities, 0, int.add))
      let sum_cost =
        list.fold(edge_costs, 0, fn(acc, c) { acc + int.absolute_value(c) })
      let max_demand =
        list.fold(demands, 0, fn(acc, d) { int.max(acc, int.absolute_value(d)) })

      let inf =
        { int.max(int.max(sum_cap, sum_cost), max_demand) * 3 } |> int.max(1)

      // Sanity check capacities
      let invalid_caps = list.any(edge_capacities, fn(c) { c < 0 })
      case invalid_caps {
        True -> panic as "Negative capacity encountered"
        False -> Nil
      }

      Ok(OmniState(
        node_count: nc,
        edge_count: ec,
        nodes: nodes,
        demands: demands,
        edge_sources: edge_sources,
        edge_targets: edge_targets,
        edge_capacities: edge_capacities,
        edge_costs: edge_costs,
        // Dummy arrays until initialized
        flows: [],
        phis: [],
        parents: [],
        edges: [],
        sizes: [],
        nexts: [],
        prevs: [],
        lasts: [],
        blockmark: 0,
        inf: inf,
      ))
    }
  }
}

fn add_super_source(omni: OmniState) -> OmniState {
  let nc = omni.node_count

  // Use the actual index `nc` for the super source, not `-1`
  let ss_edges =
    omni.demands
    |> list.index_map(fn(d, p) {
      case d > 0 {
        True -> #(p, nc)
        False -> #(nc, p)
      }
    })

  let new_sources =
    list.flatten([omni.edge_sources, list.map(ss_edges, fn(e) { e.0 })])
  let new_targets =
    list.flatten([omni.edge_targets, list.map(ss_edges, fn(e) { e.1 })])

  let new_costs =
    list.flatten([omni.edge_costs, list.repeat(omni.inf, times: nc)])
  let new_caps =
    list.flatten([omni.edge_capacities, list.repeat(omni.inf, times: nc)])

  // FIX: Append 0 demand for the super source so array lengths align
  let new_demands = list.append(omni.demands, [0])

  OmniState(
    ..omni,
    demands: new_demands,
    edge_sources: new_sources,
    edge_targets: new_targets,
    edge_costs: new_costs,
    edge_capacities: new_caps,
    node_count: nc + 1,
    edge_count: omni.edge_count + nc,
  )
}

fn init_spanning_tree(omni: OmniState) -> OmniState {
  let nc = omni.node_count
  let ec = omni.edge_count
  let old_nc = nc - 1
  let old_ec = ec - old_nc

  // flows: size ec
  let flows_base = list.repeat(0, times: old_ec)
  let flows_demands =
    list.map(list.take(omni.demands, old_nc), int.absolute_value)
  let flows = list.flatten([flows_base, flows_demands])

  // phis: size nc
  let phis_base =
    list.map(list.take(omni.demands, old_nc), fn(d) {
      case d > 0 {
        True -> -omni.inf
        False -> omni.inf
      }
    })
  let phis = list.flatten([phis_base, [0]])

  // edges: size nc. Artificial edges are from old_ec to ec-1.
  let edges = list.flatten([seq(old_ec, ec - 1), [-1]])

  // parents: size nc. Super source is old_nc.
  let parents = list.flatten([list.repeat(old_nc, times: old_nc), [-1]])

  // sizes: size nc
  let sizes = list.flatten([list.repeat(1, times: old_nc), [nc]])

  // nexts: DFS thread
  let nexts = list.flatten([seq(1, old_nc - 1), [-1, 0]])

  // prevs: DFS thread backwards
  let prevs = list.flatten([[old_nc], seq(0, old_nc - 2), [-1]])

  // lasts: Last descendant in subtree
  let lasts = list.flatten([seq(0, old_nc - 1), [old_nc - 1]])

  OmniState(
    ..omni,
    flows: flows,
    phis: phis,
    parents: parents,
    edges: edges,
    sizes: sizes,
    nexts: nexts,
    prevs: prevs,
    lasts: lasts,
  )
}

// ----------
// HELPERS
// ----------

fn reduced_cost(omni: OmniState, i: Int) -> Int {
  let c = wget(omni.edge_costs, i)
  let s = wget(omni.edge_sources, i)
  let t = wget(omni.edge_targets, i)
  let phi_s = wget(omni.phis, s)
  let phi_t = wget(omni.phis, t)
  let base_cost = c + phi_s - phi_t
  case wget(omni.flows, i) == 0 {
    True -> base_cost
    False -> -base_cost
  }
}

fn residual_capacity(omni: OmniState, i: Int, p: Int) -> Int {
  let s = wget(omni.edge_sources, i)
  let u = wget(omni.edge_capacities, i)
  let f = wget(omni.flows, i)
  case s == p {
    True -> u - f
    False -> f
  }
}

fn find_apex(omni: OmniState, p: Int, q: Int) -> Int {
  do_find_apex(omni, p, q, omni.node_count)
}

fn do_find_apex(omni: OmniState, p: Int, q: Int, max: Int) -> Int {
  case p == q || max <= 0 {
    True -> p
    False -> {
      let next_p = case wget(omni.sizes, p) >= wget(omni.sizes, q) {
        True -> p
        False -> wget(omni.parents, p)
      }
      let next_q = case wget(omni.sizes, q) >= wget(omni.sizes, p) {
        True -> q
        False -> wget(omni.parents, q)
      }

      let final_p = case
        next_p != next_q && wget(omni.sizes, next_p) == wget(omni.sizes, next_q)
      {
        True -> wget(omni.parents, next_p)
        False -> next_p
      }
      let final_q = case
        next_p != next_q && wget(omni.sizes, next_p) == wget(omni.sizes, next_q)
      {
        True -> wget(omni.parents, next_q)
        False -> next_q
      }
      do_find_apex(omni, final_p, final_q, max - 1)
    }
  }
}

fn trace_path(omni: OmniState, p: Int, w: Int) -> #(List(Int), List(Int)) {
  do_trace_path(omni, p, w, [p], [], omni.node_count)
}

fn do_trace_path(
  omni: OmniState,
  p: Int,
  w: Int,
  wn: List(Int),
  we: List(Int),
  max: Int,
) -> #(List(Int), List(Int)) {
  case p == w || max <= 0 {
    True -> #(wn, we)
    False -> {
      let next_p = wget(omni.parents, p)
      do_trace_path(
        omni,
        next_p,
        w,
        list.append(wn, [next_p]),
        list.append(we, [wget(omni.edges, p)]),
        max - 1,
      )
    }
  }
}

fn find_cycle(
  omni: OmniState,
  i: Int,
  p: Int,
  q: Int,
) -> #(List(Int), List(Int), Int) {
  let w = find_apex(omni, p, q)
  let #(wn_p, we_p) = trace_path(omni, p, w)
  let wn_p_rev = list.reverse(wn_p)
  let we_p_rev = list.append(list.reverse(we_p), [i])

  let #(wn_q, we_q) = trace_path(omni, q, w)
  // Drop the apex itself from wn_q to avoid duplication
  let wn_q_rev = list.take(wn_q, list.length(wn_q) - 1)

  #(
    list.append(wn_p_rev, wn_q_rev),
    list.append(we_p_rev, we_q),
    list.length(wn_p),
  )
}

fn find_leaving_edge(
  omni: OmniState,
  wn: List(Int),
  we: List(Int),
) -> #(Int, Int) {
  let zipped = list.zip(we, wn)
  let min_edge =
    list.fold(zipped, option.None, fn(acc, ew) {
      let #(i, cycle_source_node) = ew
      let rc = residual_capacity(omni, i, cycle_source_node)
      case acc {
        option.None -> option.Some(#(i, rc))
        option.Some(#(min_i, min_rc)) -> {
          case rc < min_rc || { rc == min_rc && i < min_i } {
            True -> option.Some(#(i, rc))
            False -> acc
          }
        }
      }
    })

  let assert option.Some(#(j, rc)) = min_edge
  #(j, rc)
}

fn augment_flow(
  omni: OmniState,
  wn: List(Int),
  we: List(Int),
  f: Int,
) -> OmniState {
  let zipped = list.zip(we, wn)
  list.fold(zipped, omni, fn(acc, ew) {
    let #(i, p) = ew
    let s = wget(acc.edge_sources, i)
    let update_amt = case s == p {
      True -> f
      False -> -f
    }
    OmniState(
      ..acc,
      flows: wupdate(acc.flows, i, fn(curr) { curr + update_amt }),
    )
  })
}

fn trace_subtree(omni: OmniState, p: Int) -> List(Int) {
  let l = wget(omni.lasts, p)
  do_trace_subtree(omni, p, l, omni.node_count)
}

fn do_trace_subtree(omni: OmniState, p: Int, l: Int, max: Int) -> List(Int) {
  case p == l || max <= 0 {
    True -> [p]
    False -> [p, ..do_trace_subtree(omni, wget(omni.nexts, p), l, max - 1)]
  }
}

fn remove_tree_edge(omni: OmniState, s: Int, t: Int) -> OmniState {
  let assert True = s == wget(omni.parents, t)

  let size_t = wget(omni.sizes, t)
  let prev_t = wget(omni.prevs, t)
  let last_t = wget(omni.lasts, t)
  let next_last_t = wget(omni.nexts, last_t)

  let o1 =
    OmniState(
      ..omni,
      edges: wassoc(omni.edges, t, -1),
      parents: wassoc(omni.parents, t, -1),
      nexts: wassoc(omni.nexts, prev_t, next_last_t),
      prevs: wassoc(omni.prevs, next_last_t, prev_t),
    )
  let o2 =
    OmniState(
      ..o1,
      nexts: wassoc(o1.nexts, last_t, t),
      prevs: wassoc(o1.prevs, t, last_t),
    )

  // Update ancestors
  do_remove_tree_edge_ancestors(o2, s, size_t, last_t, prev_t, omni.node_count)
}

fn do_remove_tree_edge_ancestors(
  omni: OmniState,
  s: Int,
  size_t: Int,
  last_t: Int,
  prev_t: Int,
  max: Int,
) -> OmniState {
  case s < 0 || max <= 0 {
    True -> omni
    False -> {
      let next_s = wget(omni.parents, s)
      let o1 =
        OmniState(
          ..omni,
          sizes: wupdate(omni.sizes, s, fn(curr) { curr - size_t }),
          lasts: wupdate(omni.lasts, s, fn(curr) {
            case curr == last_t {
              True -> prev_t
              False -> curr
            }
          }),
        )
      do_remove_tree_edge_ancestors(o1, next_s, size_t, last_t, prev_t, max - 1)
    }
  }
}

fn make_root(omni: OmniState, q: Int) -> OmniState {
  let #(ancestors, _) = do_get_ancestors(omni, q, [], omni.node_count)
  let reversed_ancestors = list.reverse(ancestors)

  let zipped = list.zip(reversed_ancestors, list.drop(reversed_ancestors, 1))
  list.fold(zipped, omni, fn(acc, pq) {
    let #(p, q_curr) = pq
    let size_p = wget(acc.sizes, p)
    let last_p = wget(acc.lasts, p)
    let prev_q = wget(acc.prevs, q_curr)
    let last_q = wget(acc.lasts, q_curr)
    let next_last_q = wget(acc.nexts, last_q)

    let size_q = wget(acc.sizes, q_curr)

    let e_q = wget(acc.edges, q_curr)
    let o1 =
      OmniState(
        ..acc,
        edges: wassoc(wassoc(acc.edges, p, e_q), q_curr, -1),
        parents: wassoc(wassoc(acc.parents, p, q_curr), q_curr, -1),
        sizes: wassoc(wassoc(acc.sizes, p, size_p - size_q), q_curr, size_p),
        nexts: wassoc(wassoc(acc.nexts, prev_q, next_last_q), last_q, q_curr),
        prevs: wassoc(wassoc(acc.prevs, next_last_q, prev_q), q_curr, last_q),
      )

    let o2 = case last_p == last_q {
      True -> OmniState(..o1, lasts: wassoc(o1.lasts, p, prev_q))
      False -> o1
    }

    let last_p_new = wget(o2.lasts, p)

    OmniState(
      ..o2,
      prevs: wassoc(wassoc(o2.prevs, p, last_q), q_curr, last_p_new),
      nexts: wassoc(wassoc(o2.nexts, last_q, p), last_p_new, q_curr),
      lasts: wassoc(o2.lasts, q_curr, last_p_new),
    )
  })
}

fn do_get_ancestors(
  omni: OmniState,
  q: Int,
  acc: List(Int),
  max: Int,
) -> #(List(Int), Int) {
  case q < 0 || max <= 0 {
    True -> #(acc, q)
    False ->
      do_get_ancestors(
        omni,
        wget(omni.parents, q),
        list.append(acc, [q]),
        max - 1,
      )
  }
}

fn update_potentials(omni: OmniState, i: Int, p: Int, q: Int) -> OmniState {
  let c = wget(omni.edge_costs, i)
  let s = wget(omni.edge_sources, i)
  let t = wget(omni.edge_targets, i)

  let phi_s = wget(omni.phis, s)
  let phi_t = wget(omni.phis, t)
  let _phi_q = wget(omni.phis, q)
  let _phi_p = wget(omni.phis, p)

  let delta = case p == s {
    True -> phi_s + c - phi_t
    False -> phi_t - c - phi_s
  }

  let subtree_nodes = trace_subtree(omni, q)
  list.fold(subtree_nodes, omni, fn(acc, n) {
    OmniState(..acc, phis: wupdate(acc.phis, n, fn(curr) { curr + delta }))
  })
}

// ----------
// PIVOT LOGIC
// ----------

pub type EnteringEdge =
  #(Int, Int, Int, Int)

// (i, p, q, f)

fn find_entering_edges(omni: OmniState) -> Option(EnteringEdge) {
  // Dantzig-Bland selection
  let search_space = seq(0, omni.edge_count - 1)

  let result =
    list.fold_until(search_space, option.None, fn(acc, idx) {
      let offset = { omni.blockmark + idx } % omni.edge_count

      // Check if non-basic
      let is_tree_edge = list.contains(omni.edges, offset)
      case is_tree_edge {
        True -> list.Continue(acc)
        False -> {
          let rc = reduced_cost(omni, offset)
          case rc < 0 {
            False -> list.Continue(acc)
            True -> {
              let s = wget(omni.edge_sources, offset)
              let t = wget(omni.edge_targets, offset)
              let f = wget(omni.flows, offset)

              let #(p, q) = case f == 0 {
                True -> #(s, t)
                False -> #(t, s)
              }

              list.Stop(option.Some(#(offset, p, q, f)))
            }
          }
        }
      }
    })

  case result {
    option.Some(#(_i, _, _, _)) -> {
      // For Dantzig, we might want to update blockmark, but not strictly needed for correctness if we loop
      result
    }
    option.None -> option.None
  }
}

fn pivot(omni: OmniState, ee: EnteringEdge) -> OmniState {
  let #(i, p, q, _initial_f) = ee
  let #(wn, we, len_p) = find_cycle(omni, i, p, q)

  // FIX: Just get the edge and the capacity
  let #(j, rc) = find_leaving_edge(omni, wn, we)

  // Determine if j is on the p-side
  let j_on_p_side = list.take(we, len_p) |> list.contains(j)
  let #(p_val, q_val) = case j_on_p_side {
    True -> #(q, p)
    False -> #(p, q)
  }

  // Augment flow
  let omni = augment_flow(omni, wn, we, rc)

  case i == j {
    True -> omni
    False -> {
      // FIX: Deterministically find the child node of the leaving edge
      let j_src = wget(omni.edge_sources, j)
      let j_tgt = wget(omni.edge_targets, j)
      let leaving_child = case wget(omni.parents, j_src) == j_tgt {
        True -> j_src
        False -> j_tgt
      }
      let leaving_parent = wget(omni.parents, leaving_child)

      // Tree update
      let omni = remove_tree_edge(omni, leaving_parent, leaving_child)
      let omni = make_root(omni, q_val)
      let omni =
        OmniState(
          ..omni,
          parents: wassoc(omni.parents, q_val, p_val),
          edges: wassoc(omni.edges, q_val, i),
        )

      let o1 =
        do_add_tree_edge_ancestors(
          omni,
          p_val,
          wget(omni.sizes, q_val),
          omni.node_count,
        )
      let o2 = do_add_tree_edge_thread(o1, q_val, p_val)

      update_potentials(o2, i, p_val, q_val)
    }
  }
}

fn do_add_tree_edge_ancestors(
  omni: OmniState,
  p: Int,
  size_q: Int,
  max: Int,
) -> OmniState {
  case p < 0 || max <= 0 {
    True -> omni
    False -> {
      let o1 =
        OmniState(
          ..omni,
          sizes: wupdate(omni.sizes, p, fn(curr) { curr + size_q }),
        )
      do_add_tree_edge_ancestors(o1, wget(omni.parents, p), size_q, max - 1)
    }
  }
}

fn do_update_lasts_ancestors(
  omni: OmniState,
  s: Int,
  last_s: Int,
  last_t: Int,
  max: Int,
) -> OmniState {
  case s < 0 || max <= 0 {
    True -> omni
    False -> {
      let o1 =
        OmniState(
          ..omni,
          lasts: wupdate(omni.lasts, s, fn(curr) {
            case curr == last_s {
              True -> last_t
              False -> curr
            }
          }),
        )
      let next_s = wget(o1.parents, s)
      do_update_lasts_ancestors(o1, next_s, last_s, last_t, max - 1)
    }
  }
}

fn do_add_tree_edge_thread(omni: OmniState, t: Int, s: Int) -> OmniState {
  let last_s = wget(omni.lasts, s)
  let next_last_s = wget(omni.nexts, last_s)
  let last_t = wget(omni.lasts, t)

  let o1 = do_update_lasts_ancestors(omni, s, last_s, last_t, omni.node_count)

  OmniState(
    ..o1,
    nexts: wassoc(wassoc(o1.nexts, last_s, t), last_t, next_last_s),
    prevs: wassoc(wassoc(o1.prevs, t, last_s), next_last_s, last_t),
  )
}

fn pivot_loop(omni: OmniState, max_iter: Int) -> OmniState {
  case max_iter <= 0 {
    True -> panic as "Network Simplex Cycle Timeout Error!"
    False -> {
      case find_entering_edges(omni) {
        option.None -> omni
        option.Some(ee) -> {
          let next_omni = pivot(omni, ee)
          pivot_loop(next_omni, max_iter - 1)
        }
      }
    }
  }
}

fn summarize(
  omni: OmniState,
  _graph: Graph(n, e),
) -> Result(MinCostFlowResult, NetworkSimplexError) {
  // Check for infeasibility: any artificial edge has non-zero flow
  let onc = omni.node_count - 1
  let oec = omni.edge_count - onc

  let artificial_edges = seq(oec, oec + onc - 1)
  let is_infeasible =
    list.any(artificial_edges, fn(i) { wget(omni.flows, i) > 0 })

  case is_infeasible {
    True -> Error(Infeasible)
    False -> {
      let flow_list = seq(0, oec - 1)
      let #(flow_map, total_cost) =
        list.fold(flow_list, #([], 0), fn(acc, i) {
          let #(current_map, current_cost) = acc
          let f = wget(omni.flows, i)
          case f > 0 {
            False -> acc
            True -> {
              let s_idx = wget(omni.edge_sources, i)
              let t_idx = wget(omni.edge_targets, i)
              let c = wget(omni.edge_costs, i)

              let s = wget(omni.nodes, s_idx)
              let t = wget(omni.nodes, t_idx)

              #([#(s, t, f), ..current_map], current_cost + { f * c })
            }
          }
        })

      Ok(MinCostFlowResult(flow: flow_map, cost: total_cost))
    }
  }
}
