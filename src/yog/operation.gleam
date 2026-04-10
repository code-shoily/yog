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
//// let combined = operation.disjoint_union(triangle1, triangle2)
//// // Result: 6 nodes (0-5), two separate triangles
//// ```
////
//// ## Example: Finding Common Structure
////
//// ```gleam
//// let common = operation.intersection(graph_a, graph_b)
//// // Returns only nodes and edges present in both graphs
//// ```

import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import yog/model.{type Graph, type NodeId}
import yog/transform
import yog/traversal

// ============================================================================
// SET-THEORETIC OPERATIONS
// ============================================================================

/// Returns a graph containing all nodes and edges from both input graphs.
///
/// If a node or edge exists in both graphs, the one from `other` takes
/// precedence for data/weights.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(1, 2)])
/// let g2 = yog.from_simple_edges(Directed, [#(2, 3)])
/// let result = operation.union(g1, g2)
/// // order(result) == 3, edge_count(result) == 2
/// ```
pub fn union(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  transform.merge(base, other)
}

/// Returns a graph containing only nodes and edges that exist in both input graphs.
///
/// For an edge to be present in the intersection, it must exist between the
/// same nodes in both graphs.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(1, 2), #(2, 3)])
/// let g2 = yog.from_simple_edges(Directed, [#(2, 3), #(3, 4)])
/// let result = operation.intersection(g1, g2)
/// // Result contains node 2, 3 and edge 2->3
/// ```
pub fn intersection(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  first
  |> transform.filter_nodes(fn(id, _) { dict.has_key(second.nodes, id) })
  |> transform.filter_edges(fn(u, v, _) { has_edge(second, u, v) })
}

/// Returns a graph containing nodes and edges that exist in the first graph
/// but not in the second.
///
/// An edge is removed if it exists in both graphs. A node is removed if it
/// exists in both graphs AND it has no remaining unique edges incident to it.
/// If a node exists in the first graph but not the second, it is always kept.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(1, 2), #(2, 3)])
/// let g2 = yog.from_simple_edges(Directed, [#(1, 2)])
/// let result = operation.difference(g1, g2)
/// // Result retains node 2, 3 and edge 2->3. Node 1 is removed.
/// ```
pub fn difference(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  let filtered_edges_graph =
    first
    |> transform.filter_edges(fn(u, v, _) { !has_edge(second, u, v) })

  filtered_edges_graph
  |> transform.filter_nodes(fn(id, _) {
    !dict.has_key(second.nodes, id)
    || model.degree(filtered_edges_graph, id) > 0
  })
}

/// Returns a graph containing edges that exist in exactly one of the input graphs.
///
/// Also includes all nodes that are incident to these unique edges, or nodes
/// that exist in only one of the graphs.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(1, 2)])
/// let g2 = yog.from_simple_edges(Directed, [#(2, 3)])
/// let result = operation.symmetric_difference(g1, g2)
/// // Result contains edges 1->2 and 2->3
/// ```
pub fn symmetric_difference(
  first: Graph(n, e),
  second: Graph(n, e),
) -> Graph(n, e) {
  difference(first, second)
  |> union(difference(second, first))
}

// ============================================================================
// COMPOSITION & JOINS
// ============================================================================

/// Combines two graphs assuming they are separate entities with automatic re-indexing.
///
/// The second graph's node IDs are shifted by `order(base)` to ensure they
/// do not collide with IDs in the first graph.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(0, 1)])
/// let g2 = yog.from_simple_edges(Directed, [#(0, 1)])
/// let result = operation.disjoint_union(g1, g2)
/// // Result has nodes 0, 1, 2, 3 and edges 0->1, 2->3
/// ```
pub fn disjoint_union(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  let offset = model.order(base)
  let reindexed_other = shift_node_ids(other, offset)
  union(base, reindexed_other)
}

/// Returns the Cartesian product of two graphs.
///
/// Every node in the result is a pair `#(u, v)` where `u` is from the first graph
/// and `v` is from the second graph. Node IDs in the result are integers
/// calculated as `u_index * order(second) + v_index`.
///
/// ## Example
///
/// ```gleam
/// // Product of two paths of length 1 (single edge) is a 2x2 grid
/// let path = yog.from_simple_edges(Undirected, [#(0, 1)])
/// let grid = operation.cartesian_product(path, path, 0, 0)
/// // order(grid) == 4, edge_count(grid) == 4
/// ```
pub fn cartesian_product(
  first: Graph(n, e),
  second: Graph(m, f),
  with_first default_first: f,
  with_second default_second: e,
) -> Graph(#(n, m), #(e, f)) {
  let first_nodes = dict.to_list(first.nodes)
  let second_nodes = dict.to_list(second.nodes)
  let second_order = model.order(second)

  // 1. Initialize graph and add all node pairs (u, v)
  let graph_with_nodes = {
    use g_acc, #(u, u_data) <- list.fold(first_nodes, model.new(first.kind))
    use g, #(v, v_data) <- list.fold(second_nodes, g_acc)
    model.add_node(g, u * second_order + v, #(u_data, v_data))
  }

  // 2. Add edges from the second graph for every node in the first graph
  let graph_with_second_edges = {
    let second_edges = model.all_edges(second)
    use g_acc, #(u, _) <- list.fold(first_nodes, graph_with_nodes)
    use g, #(v_src, v_dst, weight) <- list.fold(second_edges, g_acc)
    let src_id = u * second_order + v_src
    let dst_id = u * second_order + v_dst
    let weight = #(default_second, weight)
    case model.add_edge(g, from: src_id, to: dst_id, with: weight) {
      Ok(new_g) -> new_g
      Error(_) -> g
    }
  }

  // 3. Add edges from the first graph for every node in the second graph
  {
    let first_edges = model.all_edges(first)
    use g_acc, #(v, _) <- list.fold(second_nodes, graph_with_second_edges)
    use g, #(u_src, u_dst, weight) <- list.fold(first_edges, g_acc)
    let src_id = u_src * second_order + v
    let dst_id = u_dst * second_order + v
    let weight = #(weight, default_first)
    case model.add_edge(g, from: src_id, to: dst_id, with: weight) {
      Ok(new_g) -> new_g
      Error(_) -> g
    }
  }
}

/// Composes two graphs by merging overlapping nodes and combining their edges.
///
/// This is a simple merge where nodes with the same ID are identified.
///
/// ## Example
///
/// ```gleam
/// let composed = operation.compose(g1, g2)
/// ```
pub fn compose(first: Graph(n, e), second: Graph(n, e)) -> Graph(n, e) {
  union(first, second)
}

/// Returns the k-th power of a graph.
///
/// The k-th power of a graph G, denoted G^k, is a graph where two nodes are
/// adjacent if and only if their distance in G is at most k.
///
/// New edges are created with the provided `default_weight`.
///
/// **Time Complexity:** O(V * (V + E))
pub fn power(graph: Graph(n, e), k: Int, default_weight: e) -> Graph(n, e) {
  use g_acc, u <- list.fold(model.all_nodes(graph), graph)
  let reachable = nodes_within_distance(graph, u, k)
  use g, v <- list.fold(reachable, g_acc)
  case u == v || has_edge(g, u, v) {
    True -> g
    False -> {
      let assert Ok(new_g) =
        model.add_edge(g, from: u, to: v, with: default_weight)
      new_g
    }
  }
}

// ============================================================================
// STRUCTURAL COMPARISON
// ============================================================================

/// Checks if the first graph is a subgraph of the second graph.
///
/// Returns true if every node in the first graph exists in the second, and
/// every edge in the first graph also exists in the second.
///
/// ## Example
///
/// ```gleam
/// let g1 = yog.from_simple_edges(Directed, [#(1, 2)])
/// let g2 = yog.from_simple_edges(Directed, [#(1, 2), #(2, 3)])
/// operation.is_subgraph(g1, g2) // True
/// ```
pub fn is_subgraph(potential: Graph(n, e), container: Graph(n, e)) -> Bool {
  let potential_nodes = dict.keys(potential.nodes)

  use <- bool.guard(
    !list.all(potential_nodes, fn(node) { model.has_node(container, node) }),
    False,
  )

  use src <- list.all(potential_nodes)
  let successors =
    dict.get(potential.out_edges, src) |> result.unwrap(dict.new())
  use #(dst, _weight) <- list.all(dict.to_list(successors))
  has_edge(container, src, dst)
}

/// Checks if two graphs are isomorphic (structurally identical).
///
/// Two graphs are isomorphic if there exists a bijection between their vertices
/// that preserves adjacency. This function uses a backtracking algorithm
/// with degree-sequence pruning.
///
/// **Note:** Graph isomorphism is a computationally hard problem. This
/// implementation is suitable for small to medium-sized graphs.
///
/// ## Example
///
/// ```gleam
/// // Triangle (0-1-2) is isomorphic to (10-20-30)
/// let g1 = yog.from_simple_edges(Undirected, [#(0, 1), #(1, 2), #(2, 0)])
/// let g2 = yog.from_simple_edges(Undirected, [#(10, 20), #(20, 30), #(30, 10)])
/// operation.is_isomorphic(g1, g2) // True
/// ```
pub fn is_isomorphic(first: Graph(n, e), second: Graph(n, e)) -> Bool {
  let first_order = model.order(first)
  let second_order = model.order(second)

  use <- bool.guard(first_order != second_order, False)
  use <- bool.guard(model.edge_count(first) != model.edge_count(second), False)

  let first_degrees = degree_sequence(first) |> list.sort(compare_degrees)
  let second_degrees = degree_sequence(second) |> list.sort(compare_degrees)

  use <- bool.guard(first_degrees != second_degrees, False)

  attempt_isomorphism(first, second)
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Shifts all node IDs in a graph by a given offset.
fn shift_node_ids(graph: Graph(n, e), offset: Int) -> Graph(n, e) {
  let map_id = fn(id) { id + offset }

  let new_nodes =
    dict.fold(graph.nodes, dict.new(), fn(acc, id, data) {
      dict.insert(acc, map_id(id), data)
    })

  let map_edges = fn(edge_map) {
    dict.fold(edge_map, dict.new(), fn(acc, src, targets) {
      let new_targets =
        dict.fold(targets, dict.new(), fn(inner_acc, dst, weight) {
          dict.insert(inner_acc, map_id(dst), weight)
        })
      dict.insert(acc, map_id(src), new_targets)
    })
  }

  model.Graph(
    kind: graph.kind,
    nodes: new_nodes,
    out_edges: map_edges(graph.out_edges),
    in_edges: map_edges(graph.in_edges),
  )
}

/// Computes the degree sequence of a graph.
fn degree_sequence(graph: Graph(n, e)) -> List(#(Int, Int)) {
  dict.keys(graph.nodes)
  |> list.map(fn(node) {
    let out_deg =
      dict.get(graph.out_edges, node)
      |> result.map(dict.size)
      |> result.unwrap(0)
    let in_deg =
      dict.get(graph.in_edges, node)
      |> result.map(dict.size)
      |> result.unwrap(0)
    #(in_deg, out_deg)
  })
}

fn compare_degrees(a: #(Int, Int), b: #(Int, Int)) -> order.Order {
  case int.compare(a.0, b.0) {
    order.Eq -> int.compare(a.1, b.1)
    other -> other
  }
}

/// Attempts backtracking isomorphism check.
fn attempt_isomorphism(first: Graph(n, e), second: Graph(n, e)) -> Bool {
  let first_nodes =
    dict.keys(first.nodes)
    |> list.sort(fn(a, b) {
      int.compare(model.degree(first, b), model.degree(first, a))
    })

  let second_nodes = dict.keys(second.nodes)
  try_mapping(first, second, first_nodes, second_nodes, dict.new())
}

fn try_mapping(
  first: Graph(n, e),
  second: Graph(n, e),
  remaining_first: List(NodeId),
  available_second: List(NodeId),
  mapping: dict.Dict(NodeId, NodeId),
) -> Bool {
  case remaining_first {
    [] -> True
    [src, ..rest] -> {
      let src_out = out_degree(first, src)
      let src_in = in_degree(first, src)

      let candidates =
        list.filter(available_second, fn(cand) {
          out_degree(second, cand) == src_out
          && in_degree(second, cand) == src_in
        })

      use cand <- list.any(candidates)
      case is_mapping_valid(first, second, src, cand, mapping) {
        False -> False
        True -> {
          let new_mapping = dict.insert(mapping, src, cand)
          let new_available = list.filter(available_second, fn(n) { n != cand })
          try_mapping(first, second, rest, new_available, new_mapping)
        }
      }
    }
  }
}

fn is_mapping_valid(
  graph1: Graph(n, e),
  graph2: Graph(n, e),
  src: NodeId,
  cand: NodeId,
  mapping: dict.Dict(NodeId, NodeId),
) -> Bool {
  use #(src_prev, cand_prev) <- list.all(dict.to_list(mapping))
  let g1_forward = has_edge(graph1, src_prev, src)
  let g2_forward = has_edge(graph2, cand_prev, cand)
  use <- bool.guard(g1_forward != g2_forward, False)

  let g1_backward = has_edge(graph1, src, src_prev)
  let g2_backward = has_edge(graph2, cand, cand_prev)
  use <- bool.guard(g1_backward != g2_backward, False)

  True
}

fn out_degree(graph: Graph(n, e), id: NodeId) -> Int {
  dict.get(graph.out_edges, id) |> result.map(dict.size) |> result.unwrap(0)
}

fn in_degree(graph: Graph(n, e), id: NodeId) -> Int {
  dict.get(graph.in_edges, id) |> result.map(dict.size) |> result.unwrap(0)
}

/// Finds all nodes within distance k using BFS.
fn nodes_within_distance(
  graph: Graph(n, e),
  src: NodeId,
  max_dist: Int,
) -> List(NodeId) {
  traversal.fold_walk(
    over: graph,
    from: src,
    using: traversal.BreadthFirst,
    initial: [],
    with: fn(acc, node_id, meta) {
      case meta.depth > 0, meta.depth <= max_dist {
        True, True -> #(traversal.Continue, [node_id, ..acc])
        False, _ -> #(traversal.Continue, acc)
        _, False -> #(traversal.Stop, acc)
      }
    },
  )
}

/// Efficient edge existence check.
fn has_edge(graph: Graph(n, e), u: NodeId, v: NodeId) -> Bool {
  case dict.get(graph.out_edges, u) {
    Ok(targets) -> dict.has_key(targets, v)
    Error(_) -> False
  }
}
