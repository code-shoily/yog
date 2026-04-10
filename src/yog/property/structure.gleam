//// Structural properties of graphs.
////
//// This module provides checks for various graph classes and regularities.
////
//// ## Algorithms
////
//// | Problem | Function | Complexity |
//// |---------|----------|------------|
//// | Tree check | `is_tree/1` | O(V + E) |
//// | Arborescence check | `is_arborescence/1` | O(V + E) |
//// | Complete graph check | `is_complete/1` | O(V) |
//// | Regular graph check | `is_regular/2` | O(V) |
//// | Connected check | `is_connected/1` | O(V + E) |
//// | Strongly connected check | `is_strongly_connected/1` | O(V + E) |
//// | Weakly connected check | `is_weakly_connected/1` | O(V + E) |
//// | Planar check | `is_planar/1` | O(V + E) |
//// | Chordal check | `is_chordal/1` | O(V + E) |
////
//// ## Key Concepts
////
//// - **Tree**: Connected acyclic undirected graph.
//// - **Arborescence**: Directed tree with a unique root.
//// - **Complete Graph (Kn)**: Every pair of distinct vertices is connected by an edge.
//// - **Regular Graph**: Every vertex has the same degree k.

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/set.{type Set}
import yog/connectivity
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/property/bipartite

/// Checks if the graph is a tree (connected and acyclic).
/// Works for undirected graphs.
///
/// **Time Complexity:** O(V + E)
pub fn is_tree(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Undirected -> {
      let n = model.node_count(graph)
      let e = model.edge_count(graph)
      n > 0 && e == n - 1 && is_connected(graph)
    }
    Directed -> False
  }
}

/// Checks if the graph is an arborescence (directed tree with a single root).
///
/// A directed graph is an arborescence iff:
/// - It has n nodes and n-1 edges
/// - Exactly one node has in-degree 0 (the root)
/// - All other nodes have in-degree 1
///
/// **Time Complexity:** O(V + E)
pub fn is_arborescence(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Directed -> {
      let n = model.node_count(graph)
      case n > 0 && model.edge_count(graph) == n - 1 {
        False -> False
        True -> {
          let nodes = model.all_nodes(graph)
          let #(roots, valid_non_roots) = {
            use #(roots, valid), node <- list.fold(nodes, #([], 0))
            case model.in_degree(graph, node) {
              0 -> #([node, ..roots], valid)
              1 -> #(roots, valid + 1)
              _ -> #(roots, valid)
            }
          }
          list.length(roots) == 1 && valid_non_roots == n - 1
        }
      }
    }
    Undirected -> False
  }
}

/// Finds the root of an arborescence.
///
/// Returns `Some(root)` if the graph is an arborescence, `None` otherwise.
pub fn arborescence_root(graph: Graph(n, e)) -> Option(NodeId) {
  case is_arborescence(graph) {
    False -> None
    True -> {
      model.all_nodes(graph)
      |> list.find(fn(node) { list.is_empty(model.predecessors(graph, node)) })
      |> option.from_result()
    }
  }
}

/// Checks if the graph is complete (every pair of distinct nodes is connected).
///
/// **Time Complexity:** O(V)
pub fn is_complete(graph: Graph(n, e)) -> Bool {
  let n = model.node_count(graph)
  case n <= 1 {
    True -> True
    False -> {
      let e = model.edge_count(graph)
      let expected = case graph.kind {
        Undirected -> n * { n - 1 } / 2
        Directed -> n * { n - 1 }
      }
      e == expected && has_no_self_loops(graph)
    }
  }
}

/// Checks if the graph is k-regular (every node has degree exactly k).
///
/// For directed graphs, both in-degree and out-degree must equal k.
///
/// **Time Complexity:** O(V)
pub fn is_regular(graph: Graph(n, e), k: Int) -> Bool {
  let nodes = model.all_nodes(graph)
  case list.is_empty(nodes) {
    True -> True
    False ->
      case graph.kind {
        Undirected -> list.all(nodes, fn(u) { model.degree(graph, u) == k })
        Directed ->
          list.all(nodes, fn(u) {
            model.out_degree(graph, u) == k && model.in_degree(graph, u) == k
          })
      }
  }
}

/// Checks if the graph is connected.
///
/// For undirected graphs, every node is reachable from every other node.
/// For directed graphs, this checks for strong connectivity.
///
/// **Time Complexity:** O(V + E)
pub fn is_connected(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Undirected ->
      case connectivity.connected_components(graph) {
        [_] | [] -> True
        _ -> False
      }
    Directed -> is_strongly_connected(graph)
  }
}

/// Checks if a directed graph is strongly connected.
///
/// For undirected graphs, falls back to `is_connected/1`.
///
/// **Time Complexity:** O(V + E)
pub fn is_strongly_connected(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Undirected -> is_connected(graph)
    Directed ->
      case connectivity.strongly_connected_components(graph) {
        [_] | [] -> True
        _ -> False
      }
  }
}

/// Checks if a directed graph is weakly connected.
///
/// For undirected graphs, falls back to `is_connected/1`.
///
/// **Time Complexity:** O(V + E)
pub fn is_weakly_connected(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Undirected -> is_connected(graph)
    Directed ->
      case connectivity.weakly_connected_components(graph) {
        [_] | [] -> True
        _ -> False
      }
  }
}

/// Checks if the graph is planar (necessary conditions only).
///
/// Implements necessary checks: |E| ≤ 3|V| - 6 and bipartite |E| ≤ 2|V| - 4.
///
/// **Time Complexity:** O(V + E)
pub fn is_planar(graph: Graph(n, e)) -> Bool {
  let n = model.node_count(graph)
  let e = model.edge_count(graph)

  case n <= 4 {
    True -> True
    False ->
      case e > 3 * n - 6 {
        True -> False
        False ->
          case bipartite.is_bipartite(graph) && e > 2 * n - 4 {
            True -> False
            False -> True
          }
      }
  }
}

/// Checks if the graph is chordal using Maximum Cardinality Search.
///
/// A chordal graph is one where every induced cycle has length 3.
///
/// **Time Complexity:** O(V + E)
pub fn is_chordal(graph: Graph(n, e)) -> Bool {
  case graph.kind {
    Undirected -> is_peo(graph, mcs_ordering(graph))
    Directed -> False
  }
}

// =============================================================================
// Helpers
// =============================================================================

fn mcs_ordering(graph: Graph(n, e)) -> List(NodeId) {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n {
    0 -> []
    _ -> {
      let buckets = dict.from_list([#(0, set.from_list(nodes))])
      let weights =
        list.fold(nodes, dict.new(), fn(acc, id) { dict.insert(acc, id, 0) })
      do_mcs(graph, weights, [], set.from_list(nodes), buckets, 0)
    }
  }
}

fn do_mcs(
  graph: Graph(n, e),
  weights: Dict(NodeId, Int),
  order: List(NodeId),
  remaining: Set(NodeId),
  buckets: Dict(Int, Set(NodeId)),
  max_weight: Int,
) -> List(NodeId) {
  case set.size(remaining) {
    0 -> list.reverse(order)
    _ -> {
      let #(v, new_buckets, new_max_weight) =
        pop_max_weight_node(buckets, max_weight)
      let neighbors = model.neighbor_ids(graph, v)

      let #(new_weights, new_buckets2, updated_max_weight) = {
        use #(w_acc, b_acc, max_w_acc), u <- list.fold(neighbors, #(
          weights,
          new_buckets,
          new_max_weight,
        ))
        case set.contains(remaining, u) {
          False -> #(w_acc, b_acc, max_w_acc)
          True -> {
            let assert Ok(old_weight) = dict.get(w_acc, u)
            let new_weight = old_weight + 1

            let w_acc2 = dict.insert(w_acc, u, new_weight)

            let old_bucket = case dict.get(b_acc, old_weight) {
              Ok(b) -> b
              Error(_) -> set.new()
            }
            let new_bucket = case dict.get(b_acc, new_weight) {
              Ok(b) -> b
              Error(_) -> set.new()
            }

            let b_acc2 =
              b_acc
              |> dict.insert(old_weight, set.delete(old_bucket, u))
              |> dict.insert(new_weight, set.insert(new_bucket, u))

            let max_w_acc2 = int.max(max_w_acc, new_weight)

            #(w_acc2, b_acc2, max_w_acc2)
          }
        }
      }

      do_mcs(
        graph,
        new_weights,
        [v, ..order],
        set.delete(remaining, v),
        new_buckets2,
        updated_max_weight,
      )
    }
  }
}

fn pop_max_weight_node(
  buckets: Dict(Int, Set(NodeId)),
  max_weight: Int,
) -> #(NodeId, Dict(Int, Set(NodeId)), Int) {
  case max_weight < 0 {
    True -> panic as "Bucket queue empty - no more nodes to process"
    False ->
      case dict.get(buckets, max_weight) {
        Error(_) -> pop_max_weight_node(buckets, max_weight - 1)
        Ok(node_set) ->
          case set.size(node_set) {
            0 -> pop_max_weight_node(buckets, max_weight - 1)
            _ -> {
              let assert Ok(node) = set.to_list(node_set) |> list.first
              let new_set = set.delete(node_set, node)
              let new_buckets = dict.insert(buckets, max_weight, new_set)
              #(node, new_buckets, max_weight)
            }
          }
      }
  }
}

fn is_peo(graph: Graph(n, e), order: List(NodeId)) -> Bool {
  let pos_map =
    list.index_fold(order, dict.new(), fn(acc, node, index) {
      dict.insert(acc, node, index)
    })

  list.all(order, fn(v) {
    let earlier_neighbors = {
      model.neighbor_ids(graph, v)
      |> list.filter(fn(u) {
        let assert Ok(u_pos) = dict.get(pos_map, u)
        let assert Ok(v_pos) = dict.get(pos_map, v)
        u_pos < v_pos
      })
    }
    is_clique(graph, earlier_neighbors)
  })
}

fn is_clique(graph: Graph(n, e), nodes: List(NodeId)) -> Bool {
  use u <- list.all(nodes)
  use v <- list.all(nodes)
  case u == v {
    True -> True
    False -> model.has_edge(graph, from: u, to: v)
  }
}

fn has_no_self_loops(graph: Graph(n, e)) -> Bool {
  model.all_nodes(graph)
  |> list.all(fn(u) { !model.has_edge(graph, from: u, to: u) })
}
