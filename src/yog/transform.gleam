//// Graph transformations and mappings - functor operations on graphs.
////
//// This module provides operations that transform graphs while preserving their structure.
//// These are useful for adapting graph data types, creating derived graphs, and
//// preparing graphs for specific algorithms.
////
//// ## Available Transformations
////
//// | Transformation | Function | Complexity | Use Case |
//// |----------------|----------|------------|----------|
//// | Transpose | `transpose/1` | O(1) | Reverse edge directions |
//// | Map Nodes | `map_nodes/2` | O(V) | Transform node data |
//// | Map Edges | `map_edges/2` | O(E) | Transform edge weights |
//// | Filter Nodes | `filter_nodes/2` | O(V) | Subgraph extraction |
//// | Filter Edges | `filter_edges/2` | O(E) | Remove unwanted edges |
//// | Transitive Closure | `transitive_closure/2` | O(V × E) | Add all reachable edges |
//// | Transitive Reduction | `transitive_reduction/2` | O(V × E) | Remove redundant edges |
////
//// ## The O(1) Transpose Operation
////
//// Due to yog's dual-map representation (storing both outgoing and incoming edges),
//// transposing a graph is a single pointer swap - dramatically faster than O(E)
//// implementations in traditional adjacency list libraries.
////
//// ## Functor Laws
////
//// The mapping operations satisfy functor laws:
//// - Identity: `map_nodes(g, fn(x) { x }) == g`
//// - Composition: `map_nodes(map_nodes(g, f), h) == map_nodes(g, fn(x) { h(f(x)) })`
////
//// ## Use Cases
////
//// - **Kosaraju's Algorithm**: Requires transposed graph for SCC finding
//// - **Type Conversion**: Changing node/edge data types for algorithm requirements
//// - **Subgraph Extraction**: Working with portions of large graphs
//// - **Weight Normalization**: Preprocessing edge weights

import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import yog/model.{type Graph, type NodeId, Directed, Graph, Undirected}
import yog/traversal

// =============================================================================
// STRUCTURE TRANSFORMATIONS
// =============================================================================

/// Reverses the direction of every edge in the graph (graph transpose).
///
/// Due to the dual-map representation (storing both out_edges and in_edges),
/// this is an **O(1) operation** that makes transposing large graphs extremely fast.
///
/// **Time Complexity:** O(1)
///
/// **Property:** `transpose(transpose(G)) = G`
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 2, to: 3, with: 20)
///
/// let reversed = transform.transpose(graph)
/// // Now has edges: 2->1 and 3->2
/// ```
///
/// ## Use Cases
///
/// - Computing strongly connected components (Kosaraju's algorithm)
/// - Finding all nodes that can reach a target node
/// - Reversing dependencies in a DAG
pub fn transpose(graph: Graph(n, e)) -> Graph(n, e) {
  Graph(..graph, out_edges: graph.in_edges, in_edges: graph.out_edges)
}

/// Converts an undirected graph to a directed graph.
///
/// Since yog internally stores undirected edges as bidirectional directed edges,
/// this is essentially free — it just changes the `kind` flag. The resulting
/// directed graph has two directed edges (A→B and B→A) for each original
/// undirected edge.
///
/// If the graph is already directed, it is returned unchanged.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let undirected =
///   model.new(Undirected)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///
/// let directed = transform.to_directed(undirected)
/// // Has edges: 1->2 and 2->1 (both with weight 10)
/// ```
pub fn to_directed(graph: Graph(n, e)) -> Graph(n, e) {
  Graph(..graph, kind: Directed)
}

/// Converts a directed graph to an undirected graph.
///
/// For each directed edge A→B, ensures B→A also exists. If both A→B and B→A
/// already exist with different weights, the `resolve` function decides which
/// weight to keep.
///
/// If the graph is already undirected, it is returned unchanged.
///
/// **Time Complexity:** O(E) where E is the number of edges
///
/// ## Example
///
/// ```gleam
/// let directed =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 2, to: 1, with: 20)
///
/// // When both directions exist, keep the smaller weight
/// let undirected = transform.to_undirected(directed, resolve: int.min)
/// // Edge 1-2 has weight 10 (min of 10 and 20)
/// ```
///
/// ```gleam
/// // One-directional edges get mirrored automatically
/// let directed =
///   model.new(Directed)
///   |> model.add_edge(from: 1, to: 2, with: 5)
///
/// let undirected = transform.to_undirected(directed, resolve: int.min)
/// // Edge exists in both directions with weight 5
/// ```
pub fn to_undirected(
  graph: Graph(n, e),
  resolve resolve: fn(e, e) -> e,
) -> Graph(n, e) {
  case graph.kind {
    Undirected -> graph
    Directed -> {
      let symmetric_out = {
        use acc_outer, src, inner <- dict.fold(graph.out_edges, graph.out_edges)
        use acc, dst, weight <- dict.fold(inner, acc_outer)
        let dst_inner = case dict.get(acc, dst) {
          Ok(m) -> m
          Error(_) -> dict.new()
        }
        let updated_inner = case dict.get(dst_inner, src) {
          Ok(existing) -> dict.insert(dst_inner, src, resolve(existing, weight))
          Error(_) -> dict.insert(dst_inner, src, weight)
        }
        dict.insert(acc, dst, updated_inner)
      }
      Graph(
        ..graph,
        kind: Undirected,
        out_edges: symmetric_out,
        in_edges: symmetric_out,
      )
    }
  }
}

// =============================================================================
// NODE TRANSFORMATIONS
// =============================================================================

/// Transforms node data using a function, preserving graph structure.
///
/// This is a functor-like operation that applies a function to every node's data
/// while keeping all edges and the graph structure unchanged. The transformation
/// function receives both the `NodeId` and the node data.
///
/// **Time Complexity:** O(V) where V is the number of nodes
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "alice")
///   |> model.add_node(2, "bob")
///
/// let uppercased = transform.map_nodes(graph, fn(_id, name) { string.uppercase(name) })
/// // Nodes now contain "ALICE" and "BOB"
/// ```
///
/// ## Accessing Identifiers
///
/// The function can use the node ID to calculate new values:
///
/// ```gleam
/// // Prefix node values with their IDs
/// transform.map_nodes(graph, fn(id, name) {
///   int.to_string(id) <> ": " <> name
/// })
/// ```
pub fn map_nodes(
  graph: Graph(n, e),
  applying transform: fn(NodeId, n) -> m,
) -> Graph(m, e) {
  let new_nodes = dict.map_values(graph.nodes, transform)
  Graph(..graph, nodes: new_nodes)
}

/// Updates a specific node's data using an updater function.
///
/// Similar to `dict.upsert`, but specialized for graphs.
/// If the node doesn't exist, it is created with the `default` value.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let graph = model.new(Directed) |> model.add_node(1, 100)
/// let updated = transform.update_node(graph, 1, 0, fn(x) { x + 50 })
/// // Node 1 now has data 150
/// ```
pub fn update_node(
  graph: Graph(n, e),
  id: NodeId,
  default: n,
  fun: fn(n) -> n,
) -> Graph(n, e) {
  let new_nodes =
    dict.upsert(graph.nodes, id, fn(maybe_data) {
      case maybe_data {
        Some(data) -> fun(data)
        None -> default
      }
    })
  Graph(..graph, nodes: new_nodes)
}

/// Creates a new graph containing only the nodes that satisfy the predicate.
///
/// Nodes are filtered based on both their ID and their associated data.
/// Removing a node automatically removes all of its incident edges (both inbound
/// and outbound).
///
/// **Time Complexity:** O(V + E)
///
/// ## Use Cases
///
/// - Filter nodes by ID range or specific identifiers
/// - Complex filtering requiring both identity and data
/// - Efficiently removing common nodes between two graphs
pub fn filter_nodes(
  graph: Graph(n, e),
  keeping predicate: fn(NodeId, n) -> Bool,
) -> Graph(n, e) {
  let kept_nodes = dict.filter(graph.nodes, predicate)
  let kept_ids = set.from_list(dict.keys(kept_nodes))

  let prune_edges = fn(outer_map) {
    outer_map
    |> dict.filter(fn(src, _) { set.contains(kept_ids, src) })
    |> dict.map_values(fn(_src, inner_map) {
      dict.filter(inner_map, fn(dst, _) { set.contains(kept_ids, dst) })
    })
  }

  Graph(
    ..graph,
    nodes: kept_nodes,
    out_edges: prune_edges(graph.out_edges),
    in_edges: prune_edges(graph.in_edges),
  )
}

// =============================================================================
// EDGE TRANSFORMATIONS
// =============================================================================

/// Transforms edge weights using a function, preserving graph structure.
///
/// This is a functor-like operation that applies a function to every edge's weight
/// while keeping all nodes and the graph topology unchanged. The transformation
/// function receives the source node ID, destination node ID, and the edge weight.
///
/// **Time Complexity:** O(E) where E is the number of edges
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 2, to: 3, with: 20)
///
/// // Double all weights
/// let doubled = transform.map_edges(graph, fn(_u, _v, w) { w * 2 })
/// // Edges now have weights 20 and 40
/// ```
///
/// ## Accessing Identifiers
///
/// The function can use endpoint identifiers to calculate new weights:
///
/// ```gleam
/// // Include path context in edge data
/// let result = transform.map_edges(graph, fn(u, v, _w) {
///   int.to_string(u) <> "->" <> int.to_string(v)
/// })
/// ```
pub fn map_edges(
  graph: Graph(n, e),
  applying transform: fn(NodeId, NodeId, e) -> f,
) -> Graph(n, f) {
  let map_outer = fn(edge_map) {
    dict.map_values(edge_map, fn(src, inner_map) {
      dict.map_values(inner_map, fn(dst, weight) { transform(src, dst, weight) })
    })
  }

  Graph(
    ..graph,
    out_edges: map_outer(graph.out_edges),
    in_edges: map_outer(graph.in_edges),
  )
}

/// Updates a specific edge's weight/metadata safely.
///
/// Ensures both `in_edges` and `out_edges` stay in sync. Properly handles
/// undirected graphs by updating both directions.
///
/// If either node `src` or `dst` does not exist, the graph is returned unchanged.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(1, 2, 10)
///
/// let updated = transform.update_edge(graph, 1, 2, 0, fn(w) { w + 5 })
/// // Edge 1->2 now has weight 15
/// ```
pub fn update_edge(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with_default default: e,
  using fun: fn(e) -> e,
) -> Graph(n, e) {
  case dict.has_key(graph.nodes, src), dict.has_key(graph.nodes, dst) {
    True, True -> {
      let graph = do_update_directed_edge(graph, src, dst, default, fun)
      case graph.kind {
        Directed -> graph
        Undirected -> {
          case src == dst {
            True -> graph
            False -> do_update_directed_edge(graph, dst, src, default, fun)
          }
        }
      }
    }
    False, _ | _, False -> graph
  }
}

/// Filters edges by a predicate, preserving all nodes.
///
/// Returns a new graph with the same nodes but only the edges where the
/// predicate returns `True`. The predicate receives `(src, dst, weight)`.
///
/// **Time Complexity:** O(E) where E is the number of edges
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 5)
///   |> model.add_edge(from: 1, to: 3, with: 15)
///   |> model.add_edge(from: 2, to: 3, with: 3)
///
/// // Keep only edges with weight >= 10
/// let heavy = transform.filter_edges(graph, fn(_src, _dst, w) { w >= 10 })
/// // Result: edges [1->3 (15)], edges 1->2 and 2->3 removed
/// ```
///
/// ## Use Cases
///
/// - Pruning low-weight edges in weighted networks
/// - Removing self-loops: `filter_edges(g, fn(s, d, _) { s != d })`
/// - Threshold-based graph sparsification
pub fn filter_edges(
  graph: Graph(n, e),
  keeping predicate: fn(NodeId, NodeId, e) -> Bool,
) -> Graph(n, e) {
  let filter_out = fn(outer_map) {
    outer_map
    |> dict.map_values(fn(src, inner_map) {
      dict.filter(inner_map, fn(dst, weight) { predicate(src, dst, weight) })
    })
    |> dict.filter(fn(_src, inner_map) { dict.size(inner_map) > 0 })
  }

  let filter_in = fn(outer_map) {
    outer_map
    |> dict.map_values(fn(dst, inner_map) {
      dict.filter(inner_map, fn(src, weight) { predicate(src, dst, weight) })
    })
    |> dict.filter(fn(_dst, inner_map) { dict.size(inner_map) > 0 })
  }

  Graph(
    ..graph,
    out_edges: filter_out(graph.out_edges),
    in_edges: filter_in(graph.in_edges),
  )
}

// =============================================================================
// GRAPH COMBINATIONS
// =============================================================================

/// Creates the complement of a graph.
///
/// The complement contains the same nodes but connects all pairs of nodes
/// that are **not** connected in the original graph, and removes all edges
/// that **are** present. Each new edge gets the supplied `default_weight`.
///
/// Self-loops are never added in the complement.
///
/// **Time Complexity:** O(V² + E)
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Undirected)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///
/// let comp = transform.complement(graph, default_weight: 1)
/// // Original: 1-2 connected, 1-3 and 2-3 not
/// // Complement: 1-3 and 2-3 connected, 1-2 not
/// ```
///
/// ## Use Cases
///
/// - Finding independent sets (cliques in the complement)
/// - Graph coloring via complement analysis
/// - Testing graph density (sparse ↔ dense complement)
pub fn complement(
  graph: Graph(n, e),
  default_weight default_weight: e,
) -> Graph(n, e) {
  let node_ids = dict.keys(graph.nodes)
  let init_graph = Graph(..graph, out_edges: dict.new(), in_edges: dict.new())

  use g, src <- list.fold(node_ids, init_graph)
  use acc, dst <- list.fold(node_ids, g)

  case src == dst {
    True -> acc
    False -> {
      let has_edge = case dict.get(graph.out_edges, src) {
        Ok(inner) -> dict.has_key(inner, dst)
        Error(_) -> False
      }

      case has_edge {
        True -> acc
        False -> {
          let assert Ok(new_graph) =
            model.add_edge(acc, from: src, to: dst, with: default_weight)
          new_graph
        }
      }
    }
  }
}

/// Combines two graphs, with the second graph's data taking precedence on conflicts.
///
/// Merges nodes, out_edges, and in_edges from both graphs. When a node exists in
/// both graphs, the node data from `other` overwrites `base`. When the same edge
/// exists in both graphs, the edge weight from `other` overwrites `base`.
///
/// Importantly, edges from different nodes are combined - if `base` has edges
/// 1->2 and 1->3, and `other` has edges 1->4 and 1->5, the result will have
/// all four edges from node 1.
///
/// The resulting graph uses the `kind` (Directed/Undirected) from the base graph.
///
/// **Time Complexity:** O(V + E) for both graphs combined
///
/// ## Example
///
/// ```gleam
/// let base =
///   model.new(Directed)
///   |> model.add_node(1, "Original")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 1, to: 3, with: 15)
///
/// let other =
///   model.new(Directed)
///   |> model.add_node(1, "Updated")
///   |> model.add_edge(from: 1, to: 4, with: 20)
///   |> model.add_edge(from: 2, to: 3, with: 25)
///
/// let merged = transform.merge(base, other)
/// // Node 1 has "Updated" (from other)
/// // Node 1 has edges to: 2, 3, and 4 (all edges combined)
/// // Node 2 has edge to: 3
/// ```
///
/// ## Use Cases
///
/// - Combining disjoint subgraphs
/// - Applying updates/patches to a graph
/// - Building graphs incrementally from multiple sources
pub fn merge(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  let merge_inner = fn(m1, m2) { dict.merge(m1, m2) }

  let merge_outer = fn(outer1, outer2) {
    dict.combine(outer1, outer2, merge_inner)
  }

  Graph(
    kind: base.kind,
    nodes: dict.merge(base.nodes, other.nodes),
    out_edges: merge_outer(base.out_edges, other.out_edges),
    in_edges: merge_outer(base.in_edges, other.in_edges),
  )
}

/// Extracts a subgraph containing only the specified nodes and their connecting edges.
///
/// Returns a new graph with only the nodes whose IDs are in the provided list,
/// along with any edges that connect nodes within this subset. Nodes not in the
/// list are removed, and all edges touching removed nodes are pruned.
///
/// **Time Complexity:** O(V + E) where V is nodes and E is edges
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_node(4, "D")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 2, to: 3, with: 20)
///   |> model.add_edge(from: 3, to: 4, with: 30)
///
/// // Extract only nodes 2 and 3
/// let sub = transform.subgraph(graph, keeping: [2, 3])
/// // Result has nodes 2, 3 and edge 2->3
/// // Edges 1->2 and 3->4 are removed (endpoints outside subgraph)
/// ```
///
/// ## Use Cases
///
/// - Extracting connected components found by algorithms
/// - Analyzing k-hop neighborhoods around specific nodes
/// - Working with strongly connected components (extract each SCC)
/// - Removing nodes found by some criteria (keep the inverse set)
/// - Visualizing specific portions of large graphs
///
/// ## Comparison with `filter_nodes()`
///
/// - `filter_nodes()` - Filters by predicate on node data (e.g., "keep active users")
/// - `subgraph()` - Filters by explicit node IDs (e.g., "keep nodes [1, 5, 7]")
pub fn subgraph(graph: Graph(n, e), keeping ids: List(NodeId)) -> Graph(n, e) {
  let id_set = set.from_list(ids)

  let nodes = dict.filter(graph.nodes, fn(id, _) { set.contains(id_set, id) })

  let prune = fn(outer) {
    dict.filter(outer, fn(src, _) { set.contains(id_set, src) })
    |> dict.map_values(fn(_, inner) {
      dict.filter(inner, fn(dst, _) { set.contains(id_set, dst) })
    })
  }

  Graph(
    ..graph,
    nodes:,
    out_edges: prune(graph.out_edges),
    in_edges: prune(graph.in_edges),
  )
}

/// Contracts an edge by merging node `b` into node `a`.
///
/// Node `b` is removed from the graph, and all edges connected to `b` are
/// redirected to `a`. If both `a` and `b` had edges to the same neighbor,
/// their weights are combined using `with_combine`.
///
/// Self-loops (edges from a node to itself) are removed during contraction.
///
/// **Important for undirected graphs:** Since undirected edges are stored
/// bidirectionally, each logical edge is processed twice during contraction,
/// causing weights to be combined twice. For example, if edge weights represent
/// capacities, this effectively doubles them. Consider dividing weights by 2
/// or using a custom combine function if this behavior is undesired.
///
/// **Time Complexity:** O(deg(a) + deg(b)) - proportional to the combined
/// degree of both nodes.
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Undirected)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 5)
///   |> model.add_edge(from: 2, to: 3, with: 10)
///
/// let contracted = transform.contract(
///   in: graph,
///   merge: 1,
///   with: 2,
///   combine_weights: int.add,
/// )
/// // Result: nodes [1, 3], edge 1-3 with weight 10
/// // Node 2 is merged into node 1
/// ```
///
/// ## Combining Weights
///
/// When both `a` and `b` have edges to the same neighbor `c`:
///
/// ```gleam
/// // Before: a-[5]->c, b-[10]->c
/// let contracted = transform.contract(
///   in: graph,
///   merge: a,
///   with: b,
///   combine_weights: int.add,
/// )
/// // After: a-[15]->c (5 + 10)
/// ```
///
/// ## Use Cases
///
/// - **Stoer-Wagner algorithm** for minimum cut
/// - **Graph simplification** by merging strongly connected nodes
/// - **Community detection** by contracting nodes in the same community
/// - **Karger's algorithm** for minimum cut (randomized)
pub fn contract(
  in graph: Graph(n, e),
  merge a: NodeId,
  with b: NodeId,
  combine_weights with_combine: fn(e, e) -> e,
) -> Graph(n, e) {
  let b_out = dict.get(graph.out_edges, b) |> result.unwrap(dict.new())
  let graph =
    dict.fold(b_out, graph, fn(acc_g, neighbor, weight) {
      case neighbor == a || neighbor == b {
        True -> acc_g
        False -> {
          let assert Ok(g) =
            model.add_edge_with_combine(
              acc_g,
              a,
              neighbor,
              weight,
              with_combine,
            )
          g
        }
      }
    })

  let graph = case graph.kind {
    model.Undirected -> graph
    model.Directed -> {
      let b_in = dict.get(graph.in_edges, b) |> result.unwrap(dict.new())
      dict.fold(b_in, graph, fn(acc_g, neighbor, weight) {
        case neighbor == a || neighbor == b {
          True -> acc_g
          False -> {
            let assert Ok(g) =
              model.add_edge_with_combine(
                acc_g,
                neighbor,
                a,
                weight,
                with_combine,
              )
            g
          }
        }
      })
    }
  }

  model.remove_node(graph, b)
}

// =============================================================================
// REACHABILITY TRANSFORMATIONS
// =============================================================================

/// Computes the transitive closure of a graph.
///
/// The transitive closure adds edges between all pairs of nodes where a path
/// exists in the original graph. If `u` can reach `v` through any path, the
/// closure will have a direct edge `u -> v`.
///
/// The `merge_fn` is used to combine edge weights when multiple paths exist
/// between the same pair of nodes.
///
/// **Complexity:**
/// - For DAGs: O(V × E) using topological sort
/// - For general graphs: O(V × (V + E)) using multiple traversals
///
/// ## Example
///
/// ```gleam
/// // Original edges: A->B (weight 2), B->C (weight 3)
/// // Closure adds: A->C (weight 5 = 2+3)
/// let closure = transform.transitive_closure(graph, int.add)
/// ```
pub fn transitive_closure(
  graph: Graph(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Graph(n, e) {
  case traversal.topological_sort(graph) {
    Ok(sorted) -> do_transitive_closure_dag(graph, sorted, merge_fn)
    Error(Nil) -> do_transitive_closure_general(graph, merge_fn)
  }
}

/// Computes the transitive reduction of a graph.
///
/// The transitive reduction removes all edges that are redundant - i.e., edges
/// `u -> v` where there exists an indirect path from `u` to `v` through other
/// nodes.
///
/// **Note:** For graphs with cycles (non-DAGs), the transitive reduction
/// is not always unique and can be more complex to compute. This implementation
/// focuses on the DAG case.
///
/// **Time Complexity:** O(V × E)
///
/// ## Example
///
/// ```gleam
/// // Original: A->B, B->C, A->C (A->C is implied by A->B->C)
/// // Reduction removes: A->C
/// // Result: A->B, B->C
/// let minimal = transform.transitive_reduction(graph, int.add)
/// ```
pub fn transitive_reduction(
  graph: Graph(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Graph(n, e) {
  let reach_graph = transitive_closure(graph, merge_fn)

  use g_acc, u, targets <- dict.fold(graph.out_edges, graph)
  use g_inner, v, _w <- dict.fold(targets, g_acc)

  let is_redundant = {
    use found_redundant, w, _ <- dict.fold(targets, False)
    case found_redundant, w == v {
      True, _ -> True
      False, True -> False
      False, False -> {
        case dict.get(reach_graph.out_edges, w) {
          Ok(w_targets) -> dict.has_key(w_targets, v)
          Error(_) -> False
        }
      }
    }
  }

  case is_redundant {
    True -> model.remove_edge(g_inner, u, v)
    False -> g_inner
  }
}

// =============================================================================
// PRIVATE HELPERS
// =============================================================================

fn do_transitive_closure_dag(
  graph: Graph(n, e),
  sorted: List(NodeId),
  merge_fn: fn(e, e) -> e,
) -> Graph(n, e) {
  let reachability_map = {
    use acc, node <- list.fold(list.reverse(sorted), dict.new())
    let edges = dict.get(graph.out_edges, node) |> result.unwrap(dict.new())

    let reachable_from_node = {
      use reachable_acc, child, w_node_child <- dict.fold(edges, edges)
      let child_reachable = dict.get(acc, child) |> result.unwrap(dict.new())

      child_reachable
      |> dict.map_values(fn(_, w) { merge_fn(w_node_child, w) })
      |> dict.combine(reachable_acc, merge_fn)
    }
    dict.insert(acc, node, reachable_from_node)
  }

  use g_acc, src, targets <- dict.fold(reachability_map, graph)
  use g_inner, dst, w <- dict.fold(targets, g_acc)
  let assert Ok(g) = model.add_edge(g_inner, from: src, to: dst, with: w)
  g
}

// Fallback for graphs with cycles - BFS/DFS from every node
fn do_transitive_closure_general(
  graph: Graph(n, e),
  merge_fn: fn(e, e) -> e,
) -> Graph(n, e) {
  model.all_nodes(graph)
  |> list.fold(graph, fn(acc_graph, start_node) {
    let reachable = find_all_reachable_weighted(graph, start_node, merge_fn)
    dict.fold(reachable, acc_graph, fn(inner_graph, target_node, weight) {
      let assert Ok(g) =
        model.add_edge(
          inner_graph,
          from: start_node,
          to: target_node,
          with: weight,
        )
      g
    })
  })
}

fn find_all_reachable_weighted(
  graph: Graph(n, e),
  start: NodeId,
  merge_fn: fn(e, e) -> e,
) -> dict.Dict(NodeId, e) {
  let neighbors = model.successors(graph, start)
  let initial_queue = list.map(neighbors, fn(nb) { #(nb.0, nb.1) })
  do_weighted_reachability(graph, initial_queue, dict.new(), merge_fn)
}

fn do_weighted_reachability(
  graph: Graph(n, e),
  queue: List(#(NodeId, e)),
  visited: dict.Dict(NodeId, e),
  merge_fn: fn(e, e) -> e,
) -> dict.Dict(NodeId, e) {
  case queue {
    [] -> visited
    [#(current, weight_to_current), ..rest] -> {
      case dict.get(visited, current) {
        Ok(_) -> do_weighted_reachability(graph, rest, visited, merge_fn)
        Error(_) -> {
          let new_visited = dict.insert(visited, current, weight_to_current)
          let neighbors = model.successors(graph, current)
          let next_steps =
            list.map(neighbors, fn(nb) {
              #(nb.0, merge_fn(weight_to_current, nb.1))
            })
          let next_queue = list.append(rest, next_steps)
          do_weighted_reachability(graph, next_queue, new_visited, merge_fn)
        }
      }
    }
  }
}

fn do_update_directed_edge(
  graph: Graph(n, e),
  src: NodeId,
  dst: NodeId,
  default: e,
  fun: fn(e) -> e,
) -> Graph(n, e) {
  let update_fn = fn(maybe_inner) {
    case maybe_inner {
      Some(m) ->
        dict.upsert(m, dst, fn(maybe_w) {
          case maybe_w {
            Some(w) -> fun(w)
            None -> default
          }
        })
      None -> dict.from_list([#(dst, default)])
    }
  }

  let new_out = dict.upsert(graph.out_edges, src, update_fn)

  let update_in_fn = fn(maybe_inner) {
    case maybe_inner {
      Some(m) ->
        dict.upsert(m, src, fn(maybe_w) {
          case maybe_w {
            Some(w) -> fun(w)
            None -> default
          }
        })
      None -> dict.from_list([#(src, default)])
    }
  }

  let new_in = dict.upsert(graph.in_edges, dst, update_in_fn)

  Graph(..graph, out_edges: new_out, in_edges: new_in)
}
