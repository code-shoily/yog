//// Yog - A comprehensive graph algorithm library for Gleam.
////
//// Provides efficient implementations of classic graph algorithms with a
//// clean, functional API.
////
//// ## Quick Start
////
//// ```gleam
//// import yog
//// import yog/pathfinding/dijkstra as pathfinding
//// import gleam/int
////
//// pub fn main() {
////   let assert Ok(graph) =
////     yog.directed()
////     |> yog.add_node(1, "Start")
////     |> yog.add_node(2, "Middle")
////     |> yog.add_node(3, "End")
////     |> yog.add_edges([#(1, 2, 5), #(2, 3, 3), #(1, 3, 10))
////
////   case pathfinding.shortest_path(
////     in: graph,
////     from: 1,
////     to: 3,
////     with_zero: 0,
////     with_add: int.add,
////     with_compare: int.compare
////   ) {
////     Some(path) -> {
////       // Path(nodes: [1, 2, 3], total_weight: 8)
////       io.println("Shortest path found!")
////     }
////     None -> io.println("No path exists")
////   }
//// }
//// ```
////
//// ## Modules
////
//// ### Core
//// - **`yog/model`** - Graph data structures and basic operations
////   - Create directed/undirected graphs
////   - Add nodes and edges
////   - Query successors, predecessors, neighbors
////
//// - **`yog/builder/labeled`** - Build graphs with arbitrary labels
////   - Use strings or any type as node identifiers
////   - Automatically maps labels to internal integer IDs
////   - Convert to standard Graph for use with all algorithms
////
//// ### Algorithms
//// - **`yog/pathfinding`** - Shortest path algorithms
////   - Dijkstra's algorithm (non-negative weights)
////   - A* search (with heuristics)
////   - Bellman-Ford (negative weights, cycle detection)
////
//// - **`yog/traversal`** - Graph traversal
////   - Breadth-First Search (BFS)
////   - Depth-First Search (DFS)
////   - Early termination support
////
//// - **`yog/mst`** - Minimum Spanning Tree
////   - Kruskal's algorithm with Union-Find
////   - Prim's algorithm with priority queue
////
//// - **`yog/traversal`** - Topological ordering
////   - Kahn's algorithm
////   - Lexicographical variant (heap-based)
////
//// - **`yog/connectivity`** - Connected components
////   - Tarjan's algorithm for Strongly Connected Components (SCC)
////   - Kosaraju's algorithm for SCC (two-pass with transpose)
////
//// - **`yog/connectivity`** - Graph connectivity analysis
////   - Tarjan's algorithm for bridges and articulation points
////
//// - **`yog/flow`** - Minimum cut algorithms
////   - Stoer-Wagner algorithm for global minimum cut
////
//// - **`yog/property`** - Eulerian paths and circuits
////   - Detection of Eulerian paths and circuits
////   - Hierholzer's algorithm for finding paths
////   - Works on both directed and undirected graphs
////
//// - **`yog/property`** - Bipartite graph detection and matching
////   - Bipartite detection (2-coloring)
////   - Partition extraction (independent sets)
////   - Maximum matching (augmenting path algorithm)
////
//// ### Data Structures
//// - **`yog/disjoint_set`** - Union-Find / Disjoint Set
////   - Path compression and union by rank
////   - O(α(n)) amortized operations (practically constant)
////   - Dynamic connectivity queries
////   - Generic over any type
////
//// ### Transformations
//// - **`yog/transform`** - Graph transformations
////   - Transpose (O(1) edge reversal!)
////   - Map nodes and edges (functor operations)
////   - Filter nodes with auto-pruning
////   - Merge graphs
////
//// ### Visualization
//// - **`yog/render`** - Graph visualization
////   - Mermaid diagram generation (GitHub/GitLab compatible)
////   - Path highlighting for algorithm results
////   - Customizable node and edge labels
////
//// ## Features
////
//// - **Functional and Immutable**: All operations return new graphs
//// - **Generic**: Works with any node/edge data types
//// - **Type-Safe**: Leverages Gleam's type system
//// - **Well-Tested**: 494+ tests covering all algorithms and data structures
//// - **Efficient**: Optimal data structures (pairing heaps, union-find)
//// - **Documented**: Every function has examples

import gleam/list
import yog/model
import yog/property/cyclicity
import yog/transform
import yog/traversal

// Re-export commonly used types for convenience
pub type Graph(node_data, edge_data) =
  model.Graph(node_data, edge_data)

pub type NodeId =
  model.NodeId

pub type GraphType =
  model.GraphType

pub type Order =
  traversal.Order

pub const breadth_first = traversal.BreadthFirst

pub const depth_first = traversal.DepthFirst

pub type WalkControl =
  traversal.WalkControl

pub const continue = traversal.Continue

pub const stop = traversal.Stop

pub const halt = traversal.Halt

pub type WalkMetadata(nid) =
  traversal.WalkMetadata(nid)

// Re-export core graph operations for convenience
// This allows users to do: import yog; yog.new(Directed)
// Instead of: import yog/model; model.new(model.Directed)

/// Creates a new empty graph of the specified type.
///
/// ## Example
///
/// ```gleam
/// import yog
/// import yog/model.{Directed}
///
/// let graph = yog.new(Directed)
/// ```
pub fn new(graph_type: GraphType) -> Graph(n, e) {
  model.new(graph_type)
}

/// Creates a new empty directed graph.
///
/// This is a convenience function that's equivalent to `yog.new(Directed)`,
/// but requires only a single import.
///
/// ## Example
///
/// ```gleam
/// import yog
///
/// let graph =
///   yog.directed()
///   |> yog.add_node(1, "Start")
///   |> yog.add_node(2, "End")
///   |> yog.add_edge(from: 1, to: 2, with: 10)
/// ```
pub fn directed() -> Graph(n, e) {
  model.new(model.Directed)
}

/// Creates a new empty undirected graph.
///
/// This is a convenience function that's equivalent to `yog.new(Undirected)`,
/// but requires only a single import.
///
/// ## Example
///
/// ```gleam
/// import yog
///
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_edge(from: 1, to: 2, with: 5)
/// ```
pub fn undirected() -> Graph(n, e) {
  model.new(model.Undirected)
}

/// Adds a node to the graph with the given ID and data.
/// If a node with this ID already exists, its data will be replaced.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> yog.add_node(1, "Node A")
/// |> yog.add_node(2, "Node B")
/// ```
pub fn add_node(graph: Graph(n, e), id: NodeId, data: n) -> Graph(n, e) {
  model.add_node(graph, id, data)
}

/// Adds an edge to the graph with the given weight.
///
/// For directed graphs, adds a single edge from `src` to `dst`.
/// For undirected graphs, adds edges in both directions.
///
/// Returns `Error` if either endpoint node doesn't exist.
/// Use `add_edge_ensure` to auto-create missing nodes, or add nodes first with `add_node`.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> yog.add_node(1, "A")
/// |> yog.add_node(2, "B")
/// |> yog.add_edge(from: 1, to: 2, with: 10)
/// // => Ok(graph)
/// ```
///
/// ## With result.try for chaining
///
/// ```gleam
/// use graph <- result.try(yog.add_edge(graph, from: 1, to: 2, with: 10))
/// use graph <- result.try(yog.add_edge(graph, from: 2, to: 3, with: 5))
/// Ok(graph)
/// ```
pub fn add_edge(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
) -> Result(Graph(n, e), String) {
  model.add_edge(graph, from: src, to: dst, with: weight)
}

/// Ensures both endpoint nodes exist, then adds an edge.
///
/// If `src` or `dst` is not already in the graph, it is created with
/// the supplied `default` node data. Existing nodes are left unchanged.
///
/// Always succeeds and returns a `Graph` (never fails).
/// Use this when you want to build graphs quickly without pre-creating nodes.
///
/// ## Example
///
/// ```gleam
/// yog.directed()
/// |> yog.add_edge_ensure(from: 1, to: 2, with: 10, default: "anon")
/// // Nodes 1 and 2 are auto-created with data "anon"
/// ```
pub fn add_edge_ensure(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  default default: n,
) -> Graph(n, e) {
  model.add_edge_ensure(graph, from: src, to: dst, with: weight, default:)
}

/// Ensures both endpoint nodes exist using a callback, then adds an edge.
///
/// If `src` or `dst` is not already in the graph, it is created by
/// calling the `by` function with the node ID to generate the node data.
/// Existing nodes are left unchanged.
///
/// Always succeeds and returns a `Graph` (never fails).
///
/// ## Example
///
/// ```gleam
/// yog.directed()
/// |> yog.add_edge_with(from: 1, to: 2, with: 10, by: fn(id) {
///   "Node" <> int.to_string(id)
/// })
/// // Nodes 1 and 2 are auto-created with "Node1" and "Node2"
/// ```
pub fn add_edge_with(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  by by: fn(NodeId) -> n,
) -> Graph(n, e) {
  model.add_edge_with(graph, from: src, to: dst, with: weight, by:)
}

/// Adds an unweighted edge to the graph.
///
/// This is a convenience function for graphs where edges have no meaningful weight.
/// Uses `Nil` as the edge data type.
///
/// Returns `Error` if either endpoint node doesn't exist.
///
/// ## Example
///
/// ```gleam
/// let graph: Graph(String, Nil) = yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_unweighted_edge(from: 1, to: 2)
/// ```
pub fn add_unweighted_edge(
  graph: Graph(n, Nil),
  from src: NodeId,
  to dst: NodeId,
) -> Result(Graph(n, Nil), String) {
  model.add_edge(graph, from: src, to: dst, with: Nil)
}

/// Adds a simple edge with weight 1.
///
/// This is a convenience function for graphs with integer weights where
/// a default weight of 1 is appropriate (e.g., unweighted graphs, hop counts).
///
/// Returns `Error` if either endpoint node doesn't exist.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> yog.add_node(1, "A")
/// |> yog.add_node(2, "B")
/// |> yog.add_simple_edge(from: 1, to: 2)
/// ```
pub fn add_simple_edge(
  graph: Graph(n, Int),
  from src: NodeId,
  to dst: NodeId,
) -> Result(Graph(n, Int), String) {
  model.add_edge(graph, from: src, to: dst, with: 1)
}

/// Adds multiple edges to the graph in a single operation.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Returns `Error` if any endpoint node doesn't exist.
///
/// This is more ergonomic than chaining multiple `add_edge` calls
/// as it only requires unwrapping a single `Result`.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_edges([
///     #(1, 2, 10),
///     #(2, 3, 5),
///     #(1, 3, 15),
///   ])
/// ```
pub fn add_edges(
  graph: Graph(n, e),
  edges: List(#(NodeId, NodeId, e)),
) -> Result(Graph(n, e), String) {
  model.add_edges(graph, edges)
}

/// Adds multiple simple edges (weight = 1) to the graph.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Convenient for unweighted graphs where all edges have weight 1.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_simple_edges([
///     #(1, 2),
///     #(2, 3),
///     #(1, 3),
///   ])
/// ```
pub fn add_simple_edges(
  graph: Graph(n, Int),
  edges: List(#(NodeId, NodeId)),
) -> Result(Graph(n, Int), String) {
  model.add_simple_edges(graph, edges)
}

/// Adds multiple unweighted edges (weight = Nil) to the graph.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Convenient for graphs where edges carry no weight information.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_unweighted_edges([
///     #(1, 2),
///     #(2, 3),
///     #(1, 3),
///   ])
/// ```
pub fn add_unweighted_edges(
  graph: Graph(n, Nil),
  edges: List(#(NodeId, NodeId)),
) -> Result(Graph(n, Nil), String) {
  model.add_unweighted_edges(graph, edges)
}

/// Gets nodes you can travel TO from the given node (successors).
/// Returns a list of tuples containing the destination node ID and edge data.
pub fn successors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  model.successors(graph, id)
}

/// Gets nodes you came FROM to reach the given node (predecessors).
/// Returns a list of tuples containing the source node ID and edge data.
pub fn predecessors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  model.predecessors(graph, id)
}

/// Gets all nodes connected to the given node, regardless of direction.
/// For undirected graphs, this is equivalent to successors.
/// For directed graphs, this combines successors and predecessors.
pub fn neighbors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  model.neighbors(graph, id)
}

/// Returns all unique node IDs that have edges in the graph.
pub fn all_nodes(graph: Graph(n, e)) -> List(NodeId) {
  model.all_nodes(graph)
}

/// Creates a graph from a list of edges #(src, dst, weight).
///
/// ## Example
///
/// ```gleam
/// let graph = yog.from_edges(model.Directed, [#(1, 2, 10), #(2, 3, 5)])
/// ```
pub fn from_edges(
  graph_type: GraphType,
  edges: List(#(NodeId, NodeId, e)),
) -> Graph(Nil, e) {
  list.fold(edges, new(graph_type), fn(g, edge) {
    let #(src, dst, weight) = edge
    g
    |> add_edge_ensure(from: src, to: dst, with: weight, default: Nil)
  })
}

/// Creates a graph from a list of unweighted edges #(src, dst).
///
/// ## Example
///
/// ```gleam
/// let graph = yog.from_unweighted_edges(model.Directed, [#(1, 2), #(2, 3)])
/// ```
pub fn from_unweighted_edges(
  graph_type: GraphType,
  edges: List(#(NodeId, NodeId)),
) -> Graph(Nil, Nil) {
  list.fold(edges, new(graph_type), fn(g, edge) {
    let #(src, dst) = edge
    g
    |> add_edge_ensure(from: src, to: dst, with: Nil, default: Nil)
  })
}

/// Creates a graph from an adjacency list #(src, List(#(dst, weight))).
///
/// ## Example
///
/// ```gleam
/// let graph = yog.from_adjacency_list(model.Directed, [#(1, [#(2, 10), #(3, 5)])])
/// ```
pub fn from_adjacency_list(
  graph_type: GraphType,
  adj_list: List(#(NodeId, List(#(NodeId, e)))),
) -> Graph(Nil, e) {
  list.fold(adj_list, new(graph_type), fn(g, entry) {
    let #(src, edges) = entry
    // First, ensure the source node exists
    let g = add_node(g, src, Nil)
    // Then add all edges
    list.fold(edges, g, fn(acc, edge) {
      let #(dst, weight) = edge
      acc
      |> add_edge_ensure(from: src, to: dst, with: weight, default: Nil)
    })
  })
}

/// Returns just the NodeIds of successors (without edge data).
/// Convenient for traversal algorithms that only need the IDs.
pub fn successor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  model.successor_ids(graph, id)
}

/// Determines if a graph contains any cycles.
/// 
/// For directed graphs, a cycle exists if there is a path from a node back to itself.
/// For undirected graphs, a cycle exists if there is a path of length >= 3 from a node back to itself,
/// or a self-loop.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// yog.is_cyclic(graph)
/// // => True // Cycle detected
/// ```
pub fn is_cyclic(graph: Graph(n, e)) -> Bool {
  cyclicity.is_cyclic(graph)
}

/// Determines if a graph is acyclic (contains no cycles).
///
/// This is the logical opposite of `is_cyclic`. For directed graphs, returning
/// `True` means the graph is a Directed Acyclic Graph (DAG).
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// yog.is_acyclic(graph)
/// // => True // Valid DAG or undirected forest
/// ```
pub fn is_acyclic(graph: Graph(n, e)) -> Bool {
  cyclicity.is_acyclic(graph)
}

// Re-export traversal operations
pub fn walk(
  in graph: Graph(n, e),
  from start_id: NodeId,
  using order: Order,
) -> List(NodeId) {
  traversal.walk(graph, from: start_id, using: order)
}

pub fn walk_until(
  in graph: Graph(n, e),
  from start_id: NodeId,
  using order: Order,
  until should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  traversal.walk_until(graph, from: start_id, using: order, until: should_stop)
}

pub fn fold_walk(
  over graph: Graph(n, e),
  from start: NodeId,
  using order: Order,
  initial acc: a,
  with folder: fn(a, NodeId, WalkMetadata(NodeId)) -> #(WalkControl, a),
) -> a {
  traversal.fold_walk(
    graph,
    from: start,
    using: order,
    initial: acc,
    with: folder,
  )
}

// Re-export transform operations
pub fn transpose(graph: Graph(n, e)) -> Graph(n, e) {
  transform.transpose(graph)
}

pub fn map_nodes(graph: Graph(n, e), with fun: fn(n) -> m) -> Graph(m, e) {
  transform.map_nodes(graph, with: fun)
}

pub fn map_edges(graph: Graph(n, e), with fun: fn(e) -> f) -> Graph(n, f) {
  transform.map_edges(graph, with: fun)
}

pub fn filter_nodes(
  graph: Graph(n, e),
  keeping predicate: fn(n) -> Bool,
) -> Graph(n, e) {
  transform.filter_nodes(graph, keeping: predicate)
}

pub fn filter_edges(
  graph: Graph(n, e),
  keeping predicate: fn(NodeId, NodeId, e) -> Bool,
) -> Graph(n, e) {
  transform.filter_edges(graph, keeping: predicate)
}

pub fn complement(
  graph: Graph(n, e),
  default_weight default_weight: e,
) -> Graph(n, e) {
  transform.complement(graph, default_weight: default_weight)
}

pub fn merge(base: Graph(n, e), other: Graph(n, e)) -> Graph(n, e) {
  transform.merge(base, other)
}

pub fn subgraph(graph: Graph(n, e), keeping ids: List(NodeId)) -> Graph(n, e) {
  transform.subgraph(graph, keeping: ids)
}

pub fn contract(
  in graph: Graph(n, e),
  merge a: NodeId,
  with b: NodeId,
  combine_weights with_combine: fn(e, e) -> e,
) -> Graph(n, e) {
  transform.contract(
    in: graph,
    merge: a,
    with: b,
    combine_weights: with_combine,
  )
}

pub fn to_directed(graph: Graph(n, e)) -> Graph(n, e) {
  transform.to_directed(graph)
}

pub fn to_undirected(
  graph: Graph(n, e),
  resolve resolve: fn(e, e) -> e,
) -> Graph(n, e) {
  transform.to_undirected(graph, resolve: resolve)
}
