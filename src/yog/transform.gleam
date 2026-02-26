import gleam/dict
import gleam/list
import yog/model.{type Graph, Graph}

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
  let new_nodes =
    dict.to_list(graph.nodes)
    |> list.map(fn(pair) { #(pair.0, fun(pair.1)) })
    |> dict.from_list()

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
    dict.to_list(inner_map)
    |> list.map(fn(pair) { #(pair.0, fun(pair.1)) })
    |> dict.from_list()
  }

  let transform_outer = fn(outer_map) {
    dict.to_list(outer_map)
    |> list.map(fn(pair) { #(pair.0, transform_inner(pair.1)) })
    |> dict.from_list()
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
/// Merges nodes, out_edges, and in_edges from both graphs. When a node or edge
/// exists in both graphs, the data from the `other` graph overwrites the `base`.
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
///
/// let other =
///   model.new(Directed)
///   |> model.add_node(1, "Updated")
///   |> model.add_edge(from: 2, to: 3, with: 20)
///
/// let merged = transform.merge(base, other)
/// // Node 1 has "Updated" (from other)
/// // Has edges: 1->2 (weight 10) and 2->3 (weight 20)
/// ```
///
/// ## Use Cases
///
/// - Combining disjoint subgraphs
/// - Applying updates/patches to a graph
/// - Building graphs incrementally from multiple sources
pub fn merge(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  let merge_outer = fn(m1, m2) {
    dict.merge(m1, m2)
    // Simple merge of the outer maps
  }

  Graph(
    kind: base.kind,
    nodes: dict.merge(base.nodes, other.nodes),
    out_edges: merge_outer(base.out_edges, other.out_edges),
    in_edges: merge_outer(base.in_edges, other.in_edges),
  )
}
