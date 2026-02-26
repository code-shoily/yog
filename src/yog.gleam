//// Yog - A comprehensive graph algorithm library for Gleam.
////
//// Provides efficient implementations of classic graph algorithms with a
//// clean, functional API.
////
//// ## Quick Start
////
//// ```gleam
//// import yog.{type Graph}
//// import yog/model.{Directed}
//// import yog/pathfinding
//// import gleam/int
////
//// pub fn main() {
////   let graph =
////     model.new(Directed)
////     |> model.add_node(1, "Start")
////     |> model.add_node(2, "Middle")
////     |> model.add_node(3, "End")
////     |> model.add_edge(from: 1, to: 2, with: 5)
////     |> model.add_edge(from: 2, to: 3, with: 3)
////     |> model.add_edge(from: 1, to: 3, with: 10)
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
//// ### Transformations
//// - **`yog/transform`** - Graph transformations
////   - Transpose (O(1) edge reversal!)
////   - Map nodes and edges (functor operations)
////   - Filter nodes with auto-pruning
////   - Merge graphs
////
//// ## Features
////
//// - **Functional and Immutable**: All operations return new graphs
//// - **Generic**: Works with any node/edge data types
//// - **Type-Safe**: Leverages Gleam's type system
//// - **Well-Tested**: 256+ tests covering all algorithms
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
