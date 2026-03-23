//// Girvan-Newman algorithm for hierarchical community detection.
////
//// Detects communities by iteratively removing edges with the highest
//// edge betweenness centrality. Edges with high betweenness are "bridges"
//// between communities.
////
//// ## Algorithm
////
//// 1. **Calculate** edge betweenness centrality for all edges
//// 2. **Remove** the edge with highest betweenness
//// 3. **Repeat** until no edges remain
//// 4. **Record** connected components at each step (hierarchy)
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Hierarchical structure needed | ✓ Excellent |
//// | Small to medium graphs | ✓ Good |
//// | Large graphs | ✗ Too slow (use Louvain/Leiden) |
//// | Edge importance analysis | ✓ Provides edge betweenness |
////
//// ## Complexity
////
//// - **Time**: O(E² × V) or O(E³) in worst case - expensive!
//// - **Space**: O(V + E)
////
//// **Note**: This algorithm is significantly slower than Louvain/Leiden.
//// Use only when you specifically need the hierarchical decomposition.
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/girvan_newman as gn
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1)])
////
//// // Basic usage - returns finest partition
//// let communities = gn.detect(graph)
////
//// // With options - target specific number of communities
//// let options = gn.GirvanNewmanOptions(target_communities: Some(2))
//// let communities = gn.detect_with_options(graph, options)
////
//// // Full hierarchical detection
//// let dendrogram = gn.detect_hierarchical(
////   graph,
////   with_zero: 0,
////   with_add: int.add,
////   with_compare: int.compare
//// )
//// ```
////
//// ## References
////
//// - [Girvan & Newman 2002 - Community structure in social networks](https://doi.org/10.1073/pnas.122653799)
//// - [Wikipedia: Girvan-Newman Algorithm](https://en.wikipedia.org/wiki/Girvan%E2%80%93Newman_algorithm)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/set
import yog
import yog/community.{type Communities, type Dendrogram, Communities, Dendrogram}
import yog/internal/priority_queue as pq
import yog/model.{type Graph, type NodeId, Directed, Undirected}

/// Options for Girvan-Newman algorithm.
pub type GirvanNewmanOptions {
  GirvanNewmanOptions(
    /// Stop when this many communities found (None = full dendrogram)
    target_communities: Option(Int),
  )
}

/// Default options for Girvan-Newman.
pub fn default_options() -> GirvanNewmanOptions {
  GirvanNewmanOptions(target_communities: None)
}

/// Calculates edge betweenness centrality for all edges.
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn edge_betweenness(
  graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dict(#(NodeId, NodeId), Float) {
  let nodes = model.all_nodes(graph)
  let initial = dict.new()

  let edge_scores =
    list.fold(nodes, initial, fn(acc, s) {
      let discovery =
        run_discovery(
          graph,
          s,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )
      let edge_dependencies = accumulate_edge_dependencies(discovery)

      dict.fold(edge_dependencies, acc, fn(acc2, edge, delta) {
        let current = dict.get(acc2, edge) |> result.unwrap(0.0)
        dict.insert(acc2, edge, current +. delta)
      })
    })

  // Scaling for undirected
  case graph.kind {
    Undirected -> dict.map_values(edge_scores, fn(_k, v) { v /. 2.0 })
    Directed -> edge_scores
  }
}

type BrandesDiscovery =
  #(List(NodeId), Dict(NodeId, List(NodeId)), Dict(NodeId, Int))

fn run_discovery(
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

  do_brandes_dijkstra(
    graph,
    queue,
    dists,
    sigmas,
    preds,
    stack,
    with_add: add,
    with_compare: compare,
  )
}

fn do_brandes_dijkstra(
  graph: Graph(n, e),
  queue: pq.Queue(#(e, NodeId)),
  dists: Dict(NodeId, e),
  sigmas: Dict(NodeId, Int),
  preds: Dict(NodeId, List(NodeId)),
  stack: List(NodeId),
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
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
            with_add: add,
            with_compare: compare,
          )
        _ -> {
          let new_stack = [v, ..stack]

          let #(next_q, next_dists, next_sigmas, next_preds) =
            model.successors(graph, v)
            |> list.fold(#(rest_q, dists, sigmas, preds), fn(state, edge) {
              let #(q, ds, ss, ps) = state
              let #(w, weight) = edge
              let new_dist = add(d_v, weight)

              case dict.get(ds, w) {
                Error(Nil) -> {
                  let q2 = pq.push(q, #(new_dist, w))
                  let ds2 = dict.insert(ds, w, new_dist)
                  let ss2 = dict.insert(ss, w, get_sigma(ss, v))
                  let ps2 = dict.insert(ps, w, [v])
                  #(q2, ds2, ss2, ps2)
                }
                Ok(old_dist) -> {
                  case compare(new_dist, old_dist) {
                    Lt -> {
                      let q2 = pq.push(q, #(new_dist, w))
                      let ds2 = dict.insert(ds, w, new_dist)
                      let ss2 = dict.insert(ss, w, get_sigma(ss, v))
                      let ps2 = dict.insert(ps, w, [v])
                      #(q2, ds2, ss2, ps2)
                    }
                    Eq -> {
                      let ss2 =
                        dict.upsert(ss, w, fn(curr) {
                          option.unwrap(curr, 0) + get_sigma(ss, v)
                        })
                      let ps2 =
                        dict.upsert(ps, w, fn(curr) {
                          [v, ..option.unwrap(curr, [])]
                        })
                      #(q, ds, ss2, ps2)
                    }
                    Gt -> state
                  }
                }
              }
            })

          do_brandes_dijkstra(
            graph,
            next_q,
            next_dists,
            next_sigmas,
            next_preds,
            new_stack,
            with_add: add,
            with_compare: compare,
          )
        }
      }
    }
  }
}

fn get_sigma(sigmas: Dict(NodeId, Int), id: NodeId) -> Int {
  dict.get(sigmas, id) |> result.unwrap(0)
}

fn accumulate_edge_dependencies(
  discovery: BrandesDiscovery,
) -> Dict(#(NodeId, NodeId), Float) {
  let #(stack, preds, sigmas) = discovery
  let node_deltas = dict.new()
  let edge_deltas = dict.new()

  let #(_node_deltas, final_edge_deltas) =
    list.fold(stack, #(node_deltas, edge_deltas), fn(acc, v) {
      let #(nd, ed) = acc
      let sigma_v = int.to_float(get_sigma(sigmas, v))
      let delta_v = dict.get(nd, v) |> result.unwrap(0.0)
      let v_preds = dict.get(preds, v) |> result.unwrap([])

      list.fold(v_preds, #(nd, ed), fn(inner_acc, u) {
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
      })
    })

  final_edge_deltas
}

/// Detects communities using the Girvan-Newman algorithm with default options.
///
/// Returns the community structure at the finest level (most communities).
/// For the full hierarchy, use detect_hierarchical.
pub fn detect(graph: Graph(n, Int)) -> Communities {
  detect_with_options(graph, default_options())
  |> result.unwrap(Communities(dict.new(), 0))
}

/// Detects communities using the Girvan-Newman algorithm with custom options.
pub fn detect_with_options(
  graph: Graph(n, Int),
  options: GirvanNewmanOptions,
) -> Result(Communities, String) {
  let dendrogram =
    detect_hierarchical(
      graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case options.target_communities {
    None ->
      list.last(dendrogram.levels)
      |> result.replace_error("Empty dendrogram")
    Some(num_communities) ->
      list.find(dendrogram.levels, fn(c) {
        c.num_communities >= num_communities
      })
      |> result.or(list.last(dendrogram.levels))
      |> result.replace_error("Could not find suitable community partition")
  }
}

/// Full hierarchical Girvan-Newman detection.
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn detect_hierarchical(
  graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dendrogram {
  do_gn_split(graph, [], with_zero: zero, with_add: add, with_compare: compare)
}

fn do_gn_split(
  graph: Graph(n, e),
  levels: List(Communities),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dendrogram {
  let current_comms = find_connected_components(graph)
  let new_levels = [current_comms, ..levels]

  case model.edge_count(graph) == 0 {
    True -> Dendrogram(levels: list.reverse(new_levels), merge_order: [])
    False -> {
      let ebc =
        edge_betweenness(
          graph,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )
      let max_val =
        dict.values(ebc)
        |> list.fold(0.0, float.max)

      let edge_to_remove =
        dict.to_list(ebc)
        |> list.find(fn(pair) { pair.1 == max_val })
        |> result.map(fn(pair) { pair.0 })
        |> result.unwrap(#(0, 0))
      // Should not happen

      let new_graph =
        model.remove_edge(graph, edge_to_remove.0, edge_to_remove.1)
      do_gn_split(
        new_graph,
        new_levels,
        with_zero: zero,
        with_add: add,
        with_compare: compare,
      )
    }
  }
}

// Helper to find connected components as Communities
fn find_connected_components(graph: Graph(n, e)) -> Communities {
  let nodes = model.all_nodes(graph)
  let #(_visited, assignments, count) =
    list.fold(nodes, #(set.new(), dict.new(), 0), fn(acc, u) {
      let #(visited, assignments, count) = acc
      case set.contains(visited, u) {
        True -> acc
        False -> {
          let component = yog.walk(graph, u, yog.breadth_first)
          let new_visited = list.fold(component, visited, set.insert)
          let new_assignments =
            list.fold(component, assignments, fn(d, v) {
              dict.insert(d, v, count)
            })
          #(new_visited, new_assignments, count + 1)
        }
      }
    })

  Communities(assignments: assignments, num_communities: count)
}
