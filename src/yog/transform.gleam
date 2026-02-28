import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import yog/model.{type Graph, type NodeId, Graph, remove_node}

/// Reverses the direction of every edge in the graph (graph transpose).
///
/// Due to the dual-map representation (storing both out_edges and in_edges),
/// this is an **O(1) operation** - just a pointer swap! This is dramatically
/// faster than most graph libraries where transpose is O(E).
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

/// Transforms node data using a function, preserving graph structure.
///
/// This is a functor operation - it applies a function to every node's data
/// while keeping all edges and the graph structure unchanged.
///
/// **Time Complexity:** O(V) where V is the number of nodes
///
/// **Functor Law:** `map_nodes(map_nodes(g, f), h) = map_nodes(g, fn(x) { h(f(x)) })`
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "alice")
///   |> model.add_node(2, "bob")
///
/// let uppercased = transform.map_nodes(graph, string.uppercase)
/// // Nodes now contain "ALICE" and "BOB"
/// ```
///
/// ## Type Changes
///
/// Can change the node data type:
///
/// ```gleam
/// // Convert string node data to integers
/// transform.map_nodes(graph, fn(s) {
///   case int.parse(s) {
///     Ok(n) -> n
///     Error(_) -> 0
///   }
/// })
/// ```
pub fn map_nodes(graph: Graph(n, e), with fun: fn(n) -> m) -> Graph(m, e) {
  let new_nodes = dict.map_values(graph.nodes, fn(_id, data) { fun(data) })

  Graph(..graph, nodes: new_nodes)
}

/// Transforms edge weights using a function, preserving graph structure.
///
/// This is a functor operation - it applies a function to every edge's weight/data
/// while keeping all nodes and the graph topology unchanged.
///
/// **Time Complexity:** O(E) where E is the number of edges
///
/// **Functor Law:** `map_edges(map_edges(g, f), h) = map_edges(g, fn(x) { h(f(x)) })`
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
/// let doubled = transform.map_edges(graph, fn(w) { w * 2 })
/// // Edges now have weights 20 and 40
/// ```
///
/// ## Type Changes
///
/// Can change the edge weight type:
///
/// ```gleam
/// // Convert integer weights to floats
/// transform.map_edges(graph, int.to_float)
///
/// // Convert weights to labels
/// transform.map_edges(graph, fn(w) {
///   case w < 10 {
///     True -> "short"
///     False -> "long"
///   }
/// })
/// ```
pub fn map_edges(graph: Graph(n, e), with fun: fn(e) -> f) -> Graph(n, f) {
  let transform_inner = fn(inner_map) {
    dict.map_values(inner_map, fn(_dst, weight) { fun(weight) })
  }

  let transform_outer = fn(outer_map) {
    dict.map_values(outer_map, fn(_src, inner_map) {
      transform_inner(inner_map)
    })
  }

  Graph(
    ..graph,
    out_edges: transform_outer(graph.out_edges),
    in_edges: transform_outer(graph.in_edges),
  )
}

/// Filters nodes by a predicate, automatically pruning connected edges.
///
/// Returns a new graph containing only nodes whose data satisfies the predicate.
/// All edges connected to removed nodes (both incoming and outgoing) are
/// automatically removed to maintain graph consistency.
///
/// **Time Complexity:** O(V + E) where V is nodes and E is edges
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "apple")
///   |> model.add_node(2, "banana")
///   |> model.add_node(3, "apricot")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///   |> model.add_edge(from: 2, to: 3, with: 2)
///
/// // Keep only nodes starting with 'a'
/// let filtered = transform.filter_nodes(graph, fn(s) {
///   string.starts_with(s, "a")
/// })
/// // Result has nodes 1 and 3, edge 1->2 is removed (node 2 gone)
/// ```
///
/// ## Use Cases
///
/// - Extract subgraphs based on node properties
/// - Remove inactive/disabled nodes from a network
/// - Filter by node importance/centrality
pub fn filter_nodes(
  graph: Graph(n, e),
  keeping predicate: fn(n) -> Bool,
) -> Graph(n, e) {
  let kept_nodes = dict.filter(graph.nodes, fn(_id, data) { predicate(data) })

  let kept_ids = dict.keys(kept_nodes)

  // Prune edges: keep only if both src and dst are in the kept_ids list
  let prune_edges = fn(outer_map) {
    dict.filter(outer_map, fn(src, _) { list.contains(kept_ids, src) })
    |> dict.map_values(fn(_src, inner_map) {
      dict.filter(inner_map, fn(dst, _) { list.contains(kept_ids, dst) })
    })
  }

  Graph(
    ..graph,
    nodes: kept_nodes,
    out_edges: prune_edges(graph.out_edges),
    in_edges: prune_edges(graph.in_edges),
  )
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
  let merge_inner = fn(m1, m2) {
    dict.merge(m1, m2)
    // Merge the inner neighbor maps (same edge = other wins)
  }

  let merge_outer = fn(outer1, outer2) {
    dict.combine(outer1, outer2, merge_inner)
    // Deep merge: combine both outer maps, merging inner dicts
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

  // Filter nodes to only those in the ID set
  let nodes = dict.filter(graph.nodes, fn(id, _) { set.contains(id_set, id) })

  // Prune edges: keep only if both src and dst are in the ID set
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
  // 1. Process outgoing edges (this handles both directions for Undirected graphs)
  let b_out = dict.get(graph.out_edges, b) |> result.unwrap(dict.new())
  let graph =
    dict.fold(b_out, graph, fn(acc_g, neighbor, weight) {
      case neighbor == a || neighbor == b {
        True -> acc_g
        False ->
          model.add_edge_with_combine(acc_g, a, neighbor, weight, with_combine)
      }
    })

  // 2. Only process incoming edges if the graph is Directed!
  // For Undirected graphs, out_edges already contains all neighbors in both directions
  let graph = case graph.kind {
    model.Undirected -> graph
    model.Directed -> {
      let b_in = dict.get(graph.in_edges, b) |> result.unwrap(dict.new())
      dict.fold(b_in, graph, fn(acc_g, neighbor, weight) {
        case neighbor == a || neighbor == b {
          True -> acc_g
          False ->
            model.add_edge_with_combine(
              acc_g,
              neighbor,
              a,
              weight,
              with_combine,
            )
        }
      })
    }
  }

  remove_node(graph, b)
}
