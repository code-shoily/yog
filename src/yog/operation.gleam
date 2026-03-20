//// Graph operations - Set-theoretic operations, composition, and structural comparison.
////
//// This module implements binary operations that treat graphs as sets of nodes and edges,
//// following NetworkX's "Graph as a Set" philosophy. These operations allow you to combine,
//// compare, and analyze structural differences between graphs.
////
//// ## Set-Theoretic Operations
////
//// | Function | Description | Use Case |
//// |----------|-------------|----------|
//// | `union/2` | All nodes and edges from both graphs | Combine graph data |
//// | `intersection/2` | Only nodes and edges common to both | Find common structure |
//// | `difference/2` | Nodes/edges in first but not second | Find unique structure |
//// | `symmetric_difference/2` | Edges in exactly one graph | Find differing structure |
////
//// ## Composition & Joins
////
//// | Function | Description | Use Case |
//// |----------|-------------|----------|
//// | `disjoint_union/2` | Combine with automatic ID re-indexing | Safe graph combination |
//// | `cartesian_product/2` | Multiply graphs (grids, hypercubes) | Generate complex structures |
//// | `compose/2` | Merge overlapping graphs with combined edges | Layered systems |
//// | `power/2` | k-th power (connect nodes within distance k) | Reachability analysis |
////
//// ## Structural Comparison
////
//// | Function | Description | Use Case |
//// |----------|-------------|----------|
//// | `is_subgraph/2` | Check if first is subset of second | Validation, pattern matching |
//// | `is_isomorphic/2` | Check if graphs are structurally identical | Graph comparison |
////
//// ## Example: Combining Graphs Safely
////
//// ```gleam
//// import yog
//// import yog/operation
////
//// // Two triangle graphs with overlapping IDs
//// let triangle1 = yog.from_simple_edges(Directed, [#(0, 1), #(1, 2), #(2, 0)])
//// let triangle2 = yog.from_simple_edges(Directed, [#(0, 1), #(1, 2), #(2, 0)])
////
//// // disjoint_union re-indexes the second graph automatically
//// let combined = operations.disjoint_union(triangle1, triangle2)
//// // Result: 6 nodes (0-5), two separate triangles
//// ```
////
//// ## Example: Finding Common Structure
////
//// ```gleam
//// let common = operations.intersection(graph_a, graph_b)
//// // Returns only nodes and edges present in both graphs
//// ```

import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import yog/model.{type Graph, type NodeId}
import yog/transform

// ============= Set-Theoretic Operations =============

/// Returns a graph containing all nodes and edges from both input graphs.
pub fn union(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  transform.merge(base, other)
}

/// Returns a graph containing only nodes and edges that exist in both input graphs.
pub fn intersection(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  let first_nodes = set.from_list(model.all_nodes(first))
  let second_nodes = set.from_list(model.all_nodes(second))
  let common_nodes = set.intersection(first_nodes, second_nodes)

  let filtered_first =
    transform.filter_nodes(first, fn(_data) { True })
    |> filter_nodes_by_set(common_nodes)

  filter_edges_by_existence(filtered_first, second)
}

/// Returns a graph containing nodes and edges that exist in the first graph
/// but not in the second.
pub fn difference(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  let first_nodes = set.from_list(model.all_nodes(first))
  let second_nodes = set.from_list(model.all_nodes(second))
  let nodes_only_in_first = set.difference(first_nodes, second_nodes)

  let without_common_edges = filter_edges_not_in(first, second)
  let nodes_common = set.intersection(first_nodes, second_nodes)
  let nodes_to_check = set.to_list(nodes_common)

  list.fold(nodes_to_check, without_common_edges, fn(g, node) {
    let has_edges =
      !list.is_empty(model.successor_ids(g, node))
      || !list.is_empty(model.predecessors(g, node) |> list.map(fn(t) { t.0 }))

    case has_edges {
      True -> g
      False -> {
        case set.contains(nodes_only_in_first, node) {
          True -> g
          False -> model.remove_node(g, node)
        }
      }
    }
  })
}

/// Returns a graph containing edges that exist in exactly one of the input graphs.
pub fn symmetric_difference(
  first: Graph(n, e),
  second: Graph(n, e),
) -> Graph(n, e) {
  let first_only = difference(first, second)
  let second_only = difference(second, first)
  union(first_only, second_only)
}

// ============= Composition & Joins =============

/// Combines two graphs assuming they are separate entities with automatic re-indexing.
pub fn disjoint_union(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  let offset = model.order(base)
  let reindexed_other = shift_node_ids(other, offset)
  union(base, reindexed_other)
}

/// Returns the Cartesian product of two graphs.
pub fn cartesian_product(
  first: Graph(n, e),
  second: Graph(m, f),
  with_first default_first: f,
  with_second default_second: e,
) -> Graph(#(n, m), #(e, f)) {
  let first_nodes = model.all_nodes(first)
  let second_nodes = model.all_nodes(second)
  let second_order = model.order(second)

  let init_graph = model.new(first.kind)

  let graph_with_nodes =
    list.fold(first_nodes, init_graph, fn(g_acc, u) {
      list.fold(second_nodes, g_acc, fn(g, v) {
        let new_id = u * second_order + v
        let assert Ok(u_data) = dict.get(first.nodes, u)
        let assert Ok(v_data) = dict.get(second.nodes, v)
        model.add_node(g, new_id, #(u_data, v_data))
      })
    })

  let graph_with_second_edges =
    list.fold(first_nodes, graph_with_nodes, fn(g_acc, u) {
      list.fold(second_nodes, g_acc, fn(g, v) {
        let v_successors = model.successors(second, v)
        list.fold(v_successors, g, fn(g_inner, edge) {
          let #(v_succ, edge_weight) = edge
          let src_id = u * second_order + v
          let dst_id = u * second_order + v_succ
          let edge_data = #(default_second, edge_weight)
          case
            model.add_edge(g_inner, from: src_id, to: dst_id, with: edge_data)
          {
            Ok(new_g) -> new_g
            Error(_) -> g_inner
          }
        })
      })
    })

  list.fold(second_nodes, graph_with_second_edges, fn(g_acc, v) {
    list.fold(first_nodes, g_acc, fn(g, u) {
      let u_successors = model.successors(first, u)
      list.fold(u_successors, g, fn(g_inner, edge) {
        let #(u_succ, edge_weight) = edge
        let src_id = u * second_order + v
        let dst_id = u_succ * second_order + v
        let edge_data = #(edge_weight, default_first)
        case
          model.add_edge(g_inner, from: src_id, to: dst_id, with: edge_data)
        {
          Ok(new_g) -> new_g
          Error(_) -> g_inner
        }
      })
    })
  })
}

/// Composes two graphs by merging overlapping nodes and combining their edges.
pub fn compose(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  union(first, second)
}

/// Returns the k-th power of a graph.
///
/// The k-th power of a graph G, denoted G^k, is a graph where two nodes are
/// adjacent if and only if their distance in G is at most k.
///
/// New edges are created with the provided `default_weight`.
pub fn power(graph: Graph(n, e), k: Int, default_weight: e) -> Graph(n, e) {
  case k <= 1 {
    True -> graph
    False -> {
      let nodes = model.all_nodes(graph)

      let result_with_edges =
        list.fold(nodes, graph, fn(acc_graph, src) {
          let reachable = nodes_within_distance(graph, src, k)
          list.fold(reachable, acc_graph, fn(g, dst) {
            case src == dst {
              True -> g
              False -> {
                case edge_exists_in(g, src, dst) {
                  True -> g
                  False -> {
                    case
                      model.add_edge(
                        g,
                        from: src,
                        to: dst,
                        with: default_weight,
                      )
                    {
                      Ok(new_g) -> new_g
                      Error(_) -> g
                    }
                  }
                }
              }
            }
          })
        })

      result_with_edges
    }
  }
}

/// Finds all nodes within distance k from a source node using BFS.
fn nodes_within_distance(
  graph: Graph(n, e),
  src: NodeId,
  max_dist: Int,
) -> List(NodeId) {
  bfs_distances(graph, [src], dict.from_list([#(src, 0)]), max_dist)
}

fn bfs_distances(
  graph: Graph(n, e),
  queue: List(NodeId),
  distances: dict.Dict(NodeId, Int),
  max_dist: Int,
) -> List(NodeId) {
  case queue {
    [] -> dict.keys(distances)
    [current, ..rest] -> {
      let current_dist =
        dict.get(distances, current) |> result.unwrap(max_dist + 1)

      case current_dist >= max_dist {
        True -> bfs_distances(graph, rest, distances, max_dist)
        False -> {
          let neighbors = model.successor_ids(graph, current)
          let #(new_queue, new_distances) =
            list.fold(neighbors, #(rest, distances), fn(acc, neighbor) {
              let #(q, dists) = acc
              case dict.has_key(dists, neighbor) {
                True -> acc
                False -> {
                  let new_dist = current_dist + 1
                  case new_dist <= max_dist {
                    True -> #(
                      [neighbor, ..q],
                      dict.insert(dists, neighbor, new_dist),
                    )
                    False -> acc
                  }
                }
              }
            })

          bfs_distances(graph, new_queue, new_distances, max_dist)
        }
      }
    }
  }
}

// ============= Structural Comparison =============

/// Checks if the first graph is a subgraph of the second graph.
pub fn is_subgraph(potential: Graph(n, e), container: Graph(n, e)) -> Bool {
  let potential_nodes = model.all_nodes(potential)
  let container_nodes = set.from_list(model.all_nodes(container))

  let all_nodes_exist =
    list.all(potential_nodes, fn(node) { set.contains(container_nodes, node) })

  case all_nodes_exist {
    False -> False
    True -> {
      list.all(potential_nodes, fn(src) {
        let potential_successors = model.successors(potential, src)
        list.all(potential_successors, fn(edge) {
          let #(dst, _weight) = edge
          edge_exists_in(container, src, dst)
        })
      })
    }
  }
}

/// Checks if two graphs are isomorphic (structurally identical).
pub fn is_isomorphic(first: Graph(n, e), second: Graph(n, e)) -> Bool {
  let first_order = model.order(first)
  let second_order = model.order(second)

  case first_order == second_order {
    False -> False
    True -> {
      let first_edges = model.edge_count(first)
      let second_edges = model.edge_count(second)

      case first_edges == second_edges {
        False -> False
        True -> {
          let degree_compare = fn(a: #(Int, Int), b: #(Int, Int)) {
            case int.compare(a.0, b.0) {
              order.Eq -> int.compare(a.1, b.1)
              other -> other
            }
          }
          let first_degrees =
            degree_sequence(first) |> list.sort(degree_compare)
          let second_degrees =
            degree_sequence(second) |> list.sort(degree_compare)

          case first_degrees == second_degrees {
            False -> False
            True -> {
              attempt_isomorphism(first, second)
            }
          }
        }
      }
    }
  }
}

/// Computes the degree sequence of a graph, dropping node uniqueness but preserving in/out combinations.
fn degree_sequence(graph: Graph(n, e)) -> List(#(Int, Int)) {
  model.all_nodes(graph)
  |> list.map(fn(node) {
    let out_deg = list.length(model.successor_ids(graph, node))
    let in_deg = list.length(model.predecessors(graph, node))
    #(in_deg, out_deg)
  })
}

/// Attempts to find an isomorphism between two graphs using backtracking.
fn attempt_isomorphism(first: Graph(n, e), second: Graph(n, e)) -> Bool {
  let degree = fn(node) {
    list.length(model.predecessors(first, node))
    + list.length(model.successor_ids(first, node))
  }
  let first_nodes =
    model.all_nodes(first)
    |> list.sort(fn(a, b) { int.compare(degree(b), degree(a)) })
  let second_nodes = model.all_nodes(second)
  try_mapping(first, second, first_nodes, second_nodes, dict.new())
}

fn try_mapping(
  first: Graph(n, e),
  second: Graph(n, e),
  remaining_first: List(NodeId),
  available_second: List(NodeId),
  current_mapping: dict.Dict(NodeId, NodeId),
) -> Bool {
  case remaining_first {
    [] -> True
    [src, ..rest] -> {
      let src_in = list.length(model.predecessors(first, src))
      let src_out = list.length(model.successor_ids(first, src))
      let valid_candidates =
        list.filter(available_second, fn(candidate) {
          let cand_in = list.length(model.predecessors(second, candidate))
          let cand_out = list.length(model.successor_ids(second, candidate))
          src_in == cand_in && src_out == cand_out
        })
      list.any(valid_candidates, fn(candidate) {
        case is_mapping_valid(first, second, src, candidate, current_mapping) {
          False -> False
          True -> {
            let new_mapping = dict.insert(current_mapping, src, candidate)
            let new_available =
              list.filter(available_second, fn(n) { n != candidate })
            try_mapping(first, second, rest, new_available, new_mapping)
          }
        }
      })
    }
  }
}

/// Checks if mapping src -> candidate is consistent with current mapping.
fn is_mapping_valid(
  first: Graph(n, e),
  second: Graph(n, e),
  src: NodeId,
  candidate: NodeId,
  mapping: dict.Dict(NodeId, NodeId),
) -> Bool {
  let src_successors = model.successor_ids(first, src)
  let candidate_successors = model.successor_ids(second, candidate)

  let inconsistent_edges =
    dict.fold(mapping, 0, fn(count, src_neighbor, candidate_neighbor) {
      case list.contains(src_successors, src_neighbor) {
        False -> count
        True -> {
          case list.contains(candidate_successors, candidate_neighbor) {
            True -> count
            False -> count + 1
          }
        }
      }
    })

  let src_predecessors =
    model.predecessors(first, src) |> list.map(fn(t) { t.0 })
  let candidate_predecessors =
    model.predecessors(second, candidate) |> list.map(fn(t) { t.0 })

  let inconsistent_incoming =
    dict.fold(mapping, 0, fn(count, src_neighbor, candidate_neighbor) {
      case list.contains(src_predecessors, src_neighbor) {
        False -> count
        True -> {
          case list.contains(candidate_predecessors, candidate_neighbor) {
            True -> count
            False -> count + 1
          }
        }
      }
    })

  inconsistent_edges == 0 && inconsistent_incoming == 0
}

// ============= Helper Functions =============

/// Shifts all node IDs in a graph by a given offset.
fn shift_node_ids(graph: Graph(n, e), offset: Int) -> Graph(n, e) {
  let nodes = model.all_nodes(graph)

  let id_mapping =
    list.fold(nodes, dict.new(), fn(acc, node) {
      dict.insert(acc, node, node + offset)
    })

  let new_nodes =
    dict.fold(graph.nodes, dict.new(), fn(acc, id, data) {
      let new_id = dict.get(id_mapping, id) |> result.unwrap(id)
      dict.insert(acc, new_id, data)
    })

  let new_out_edges =
    dict.fold(graph.out_edges, dict.new(), fn(acc, src, targets) {
      let new_src = dict.get(id_mapping, src) |> result.unwrap(src)
      let new_targets =
        dict.fold(targets, dict.new(), fn(inner_acc, dst, weight) {
          let new_dst = dict.get(id_mapping, dst) |> result.unwrap(dst)
          dict.insert(inner_acc, new_dst, weight)
        })
      dict.insert(acc, new_src, new_targets)
    })

  let new_in_edges =
    dict.fold(graph.in_edges, dict.new(), fn(acc, dst, sources) {
      let new_dst = dict.get(id_mapping, dst) |> result.unwrap(dst)
      let new_sources =
        dict.fold(sources, dict.new(), fn(inner_acc, src, weight) {
          let new_src = dict.get(id_mapping, src) |> result.unwrap(src)
          dict.insert(inner_acc, new_src, weight)
        })
      dict.insert(acc, new_dst, new_sources)
    })

  model.Graph(
    kind: graph.kind,
    nodes: new_nodes,
    out_edges: new_out_edges,
    in_edges: new_in_edges,
  )
}

/// Filters nodes to only those in the given set.
fn filter_nodes_by_set(graph: Graph(n, e), keep: set.Set(NodeId)) -> Graph(n, e) {
  transform.filter_nodes(graph, fn(_data) { True })
  |> remove_nodes_not_in_set(keep)
}

/// Removes nodes not in the given set.
fn remove_nodes_not_in_set(
  graph: Graph(n, e),
  keep: set.Set(NodeId),
) -> Graph(n, e) {
  let nodes_to_remove =
    model.all_nodes(graph)
    |> list.filter(fn(node) { !set.contains(keep, node) })

  list.fold(nodes_to_remove, graph, fn(g, node) { model.remove_node(g, node) })
}

/// Filters edges to only those that exist in both graphs.
fn filter_edges_by_existence(
  first: Graph(n, e),
  second: Graph(n, e),
) -> Graph(n, e) {
  let first_nodes = model.all_nodes(first)

  list.fold(first_nodes, first, fn(g, src) {
    let successors = model.successors(g, src)
    list.fold(successors, g, fn(acc_g, edge) {
      let #(dst, _weight) = edge
      case edge_exists_in(second, src, dst) {
        True -> acc_g
        False -> model.remove_edge(acc_g, src, dst)
      }
    })
  })
}

/// Filters out edges that exist in the second graph.
fn filter_edges_not_in(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  let first_nodes = model.all_nodes(first)

  list.fold(first_nodes, first, fn(g, src) {
    let successors = model.successors(g, src)
    list.fold(successors, g, fn(acc_g, edge) {
      let #(dst, _weight) = edge
      case edge_exists_in(second, src, dst) {
        True -> model.remove_edge(acc_g, src, dst)
        False -> acc_g
      }
    })
  })
}

/// Checks if an edge exists in the graph.
fn edge_exists_in(graph: Graph(n, e), src: NodeId, dst: NodeId) -> Bool {
  model.successors(graph, src)
  |> list.any(fn(edge) { edge.0 == dst })
}
