//// Yog - A comprehensive graph algorithm library for Gleam.
////
//// Provides efficient implementations of classic graph algorithms with a
//// clean, functional API.
////
//// ## Quick Start
////
//// ```gleam
//// import yog
//// import yog/pathfinding
//// import gleam/int
////
//// pub fn main() {
////   let graph =
////     yog.directed()
////     |> yog.add_node(1, "Start")
////     |> yog.add_node(2, "Middle")
////     |> yog.add_node(3, "End")
////     |> yog.add_edge(from: 1, to: 2, with: 5)
////     |> yog.add_edge(from: 2, to: 3, with: 3)
////     |> yog.add_edge(from: 1, to: 3, with: 10)
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
////
//// - **`yog/topological_sort`** - Topological ordering
////   - Kahn's algorithm
////   - Lexicographical variant (heap-based)
////
//// - **`yog/components`** - Connected components
////   - Tarjan's algorithm for Strongly Connected Components (SCC)
////
//// - **`yog/connectivity`** - Graph connectivity analysis
////   - Tarjan's algorithm for bridges and articulation points
////
//// - **`yog/min_cut`** - Minimum cut algorithms
////   - Stoer-Wagner algorithm for global minimum cut
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
//// - **Well-Tested**: 435+ tests covering all algorithms and data structures
//// - **Efficient**: Optimal data structures (pairing heaps, union-find)
//// - **Documented**: Every function has examples

import yog/model

// Re-export commonly used types for convenience
pub type Graph(node_data, edge_data) =
  model.Graph(node_data, edge_data)

pub type NodeId =
  model.NodeId

pub type GraphType =
  model.GraphType

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
/// ## Example
///
/// ```gleam
/// graph
/// |> yog.add_edge(from: 1, to: 2, with: 10)
/// ```
pub fn add_edge(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
) -> Graph(n, e) {
  model.add_edge(graph, from: src, to: dst, with: weight)
}

/// Adds an unweighted edge to the graph.
///
/// This is a convenience function for graphs where edges have no meaningful weight.
/// Uses `Nil` as the edge data type.
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
) -> Graph(n, Nil) {
  model.add_edge(graph, from: src, to: dst, with: Nil)
}

/// Adds a simple edge with weight 1.
///
/// This is a convenience function for graphs with integer weights where
/// a default weight of 1 is appropriate (e.g., unweighted graphs, hop counts).
///
/// ## Example
///
/// ```gleam
/// graph
/// |> yog.add_simple_edge(from: 1, to: 2)
/// |> yog.add_simple_edge(from: 2, to: 3)
/// // Both edges have weight 1
/// ```
pub fn add_simple_edge(
  graph: Graph(n, Int),
  from src: NodeId,
  to dst: NodeId,
) -> Graph(n, Int) {
  model.add_edge(graph, from: src, to: dst, with: 1)
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

/// Returns just the NodeIds of successors (without edge data).
/// Convenient for traversal algorithms that only need the IDs.
pub fn successor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  model.successor_ids(graph, id)
}
