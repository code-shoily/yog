# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - Unreleased

### Added
- **Graph connectivity analysis (`yog/connectivity`)** - Find bridges and articulation points in undirected graphs
  - `analyze()` - Tarjan's algorithm for finding bridges and articulation points in a single DFS pass
  - `Bridge` type representing critical edges whose removal disconnects the graph
  - `ConnectivityResults` type containing both bridges and articulation points
  - Bridges are stored in canonical order (lower node ID first) for consistency
  - Works on disconnected graphs, handling all components in a single pass
  - Perfect for network vulnerability analysis, finding single points of failure, circuit design
  - 16 comprehensive tests covering linear chains, cycles, complex graphs, disconnected components, edge cases
  - Complete documentation with examples and use cases
  - **Important:** Designed for undirected graphs (use SCC analysis for directed graphs)
  - **Note:** Standard node-based parent tracking doesn't perfectly handle parallel edges (would need edge IDs)

- **Subgraph extraction (`transform.subgraph`)** - Extract specific nodes and their connecting edges
  - Takes a list of node IDs and returns a new graph containing only those nodes
  - Automatically prunes edges whose endpoints are outside the subgraph
  - Perfect for extracting connected components, analyzing k-hop neighborhoods, working with SCCs
  - More efficient than `filter_nodes()` when you have explicit IDs rather than a predicate
  - 10 comprehensive tests covering empty subgraphs, cycles, undirected graphs, complex filtering
  - Complete documentation with examples and comparison to `filter_nodes()`

- **Edge contraction (`transform.contract`)** - Merge nodes by contracting edges
  - Merges node `b` into node `a`, redirecting all of b's edges to a
  - When both nodes share neighbors, edge weights are combined using custom function
  - Self-loops are automatically removed during contraction
  - Essential for Stoer-Wagner min-cut algorithm and Karger's randomized min-cut
  - 11 comprehensive tests covering directed/undirected, weight combining, self-loops, triangles, complex graphs
  - Complete documentation with examples and use cases
  - **Note:** For undirected graphs, edges are processed twice (once per direction) causing weights to double when combined

- **Node removal (`model.remove_node`)** - Remove nodes and their connected edges
  - Efficiently removes a node and all its incoming/outgoing edges
  - Time complexity: O(deg(v)) - proportional to node degree, not entire graph
  - Uses new `dict_update_inner` utility for nested dictionary updates
  - 7 comprehensive tests covering isolated nodes, incoming/outgoing edges, undirected graphs, self-loops
  - Complete documentation with examples

- **Edge combining (`model.add_edge_with_combine`)** - Add edges with custom weight combining
  - When adding an edge that already exists, combines weights using custom function
  - Supports both directed and undirected graphs correctly
  - Essential building block for edge contraction
  - 6 comprehensive tests covering multiple additions, different combine functions, undirected behavior
  - Complete documentation with examples and use cases

- **Dictionary utilities (`internal/utils.dict_update_inner`)** - Helper for nested dictionary updates
  - Updates inner dictionaries within nested dictionary structures
  - Used by `remove_node` for efficient edge cleanup
  - Properly handles missing outer keys

- **Global minimum cut (`yog/min_cut`)** - Find minimum cuts in undirected weighted graphs
  - `global_min_cut()` - Stoer-Wagner algorithm for finding global minimum cut
  - Returns `MinCut` type with cut weight and partition sizes (for AoC 2023 Day 25 style problems)
  - Time complexity: O(V³) or O(VE + V² log V) with optimized priority queue
  - Implements Maximum Adjacency Search (MAS) as core subroutine
  - Works by iteratively contracting edges and tracking minimum cut-of-the-phase
  - Perfect for AoC 2023 Day 25, network reliability, graph partitioning, clustering
  - 14 comprehensive tests covering single edges, triangles, weighted graphs, bottlenecks, complex graphs, AoC scenarios
  - Complete documentation with examples and algorithm explanation
  - **Note:** Weight accumulation during contraction can produce values that differ from simple edge counts, but partitions are correct

### Fixed
- **Critical bug in `transform.merge()`** - Now correctly performs deep merge of edge dictionaries
  - Previously, when both graphs had edges from the same node, all edges from the base graph were lost
  - Example: If base had 1->2, 1->3 and other had 1->4, 1->5, only 1->4 and 1->5 survived (losing 1->2 and 1->3)
  - Now uses `dict.combine()` with inner merge function to correctly combine all edges
  - When the same edge exists in both graphs, edge weight from `other` takes precedence (as documented)
  - Added regression test to prevent future breakage

### Changed
- Test suite expanded to 435 tests (from 374)
- Internal state representation optimized: `visited` changed from `Dict(NodeId, Bool)` to `Set(NodeId)`
- Parent tracking improved: Changed from sentinel value `-1` to type-safe `Option(NodeId)`

## [1.2.1] - 2026-02-26

### Added
- **Floyd-Warshall algorithm (`pathfinding.floyd_warshall`)** - All-pairs shortest path computation
  - Computes shortest paths between all pairs of nodes in O(V³) time
  - Returns nested `Dict(NodeId, Dict(NodeId, distance))` for easy querying
  - Handles negative edge weights and detects negative cycles
  - Perfect for distance matrices, graph diameter, transitive closure, centrality measures
  - Ideal for AoC problems requiring all-pairs distances (e.g., 2022 Day 16)
  - 12 comprehensive tests covering basic cases, negative weights, negative cycles, disconnected graphs, self-loops, and comparison with Dijkstra
  - Complete documentation with examples and usage guidance

### Fixed
- **Bug in Floyd-Warshall self-loop handling** - Fixed incorrect initialization that ignored self-loop edges
  - Initial implementation unconditionally set distance[i][i] = zero, ignoring actual self-loop edges
  - This caused negative self-loops (which should be detected as negative cycles) to be silently ignored
  - Fixed to use `min(zero, self_loop_weight)`: negative self-loops now correctly detected as cycles, positive self-loops correctly ignored (staying put is shorter)
  - Added 2 tests for self-loop edge cases

- **Critical bug in `model.all_nodes()`** - Isolated nodes (nodes with no edges) are now correctly included
  - Previously, `all_nodes()` only returned nodes that appeared in `out_edges` or `in_edges`, silently excluding isolated nodes
  - This affected topological sort (isolated nodes weren't in the ordering) and SCC (isolated nodes weren't returned as single-element components)
  - Now correctly returns ALL nodes from `graph.nodes`, regardless of edge connectivity
  - This is a breaking behavior change if code relied on the old incorrect behavior
  - Updated tests to reflect correct behavior

### Changed
- Test suite expanded to 374 tests (from 355)
- Eliminated all deprecation warnings by replacing `list.range` with internal `utils.range` helper

## [1.2.0] - 2026-02-26

### Added
- **Grid graph builder (`yog/builder/grid`)** - Convert 2D grids to graphs for pathfinding
  - `from_2d_list()` - Build graph from 2D array with custom movement constraints
  - `coord_to_id()` and `id_to_coord()` - Convert between coordinates and node IDs
  - `get_cell()` - Access cell data by coordinates
  - `find_node()` - Search for nodes matching a predicate
  - `manhattan_distance()` - Heuristic for A* on grids
  - `to_graph()` - Convert to standard `Graph` for use with all algorithms
  - Perfect for AoC grid problems, game pathfinding, maze solving, heightmaps
  - 16 comprehensive tests including real AoC 2022 Day 12 example

- **Single-source distances (`pathfinding.single_source_distances`)** - Compute distances to all reachable nodes
  - Returns `Dict(NodeId, distance)` mapping each reachable node to its shortest distance
  - More efficient than running `shortest_path` multiple times
  - Common use cases: finding nearest target among many options, distance maps for AI, reverse pathfinding with `transform.transpose`
  - Time complexity: O((V + E) log V)
  - 12 comprehensive tests covering various graph types and use cases

- **Convenience functions for unweighted edges** - Ergonomic alternatives when weights aren't needed
  - `yog.add_unweighted_edge()` - Add edges with `Nil` weight for truly unweighted graphs
  - `yog.add_simple_edge()` - Add edges with default weight of `1` for integer-weighted graphs
  - `labeled.add_unweighted_edge()` - Add unweighted edges to labeled graphs
  - `labeled.add_simple_edge()` - Add simple edges to labeled graphs with default weight `1`
  - Perfect for use cases like hop counts, orbital maps, or basic connectivity
  - 8 comprehensive tests covering both directed and undirected variants

### Changed
- Test suite expanded to 355 tests (from 326)

## [1.1.0] - Unreleased

### Added
- **Labeled graph builder (`yog/builder/labeled`)** - Build graphs using arbitrary labels instead of integer IDs
  - `Builder` type that manages label-to-ID mapping automatically
  - `new()` - Create a new labeled graph builder
  - `add_node(label)` - Add nodes by label
  - `add_edge(from, to, with)` - Add edges using labels (auto-creates nodes)
  - `to_graph()` - Convert to standard `Graph` for use with all algorithms
  - `get_id(label)` - Look up the internal node ID for a label
  - `ensure_node(label)` - Get or create a node, returning builder and ID
  - `all_labels()` - Get all labels that have been added
  - `successors(label)` and `predecessors(label)` - Query by label
  - Works with any hashable label type (strings, integers, custom types)
  - 18 comprehensive tests covering directed/undirected graphs and algorithm integration
  - Lays foundation for future builders (`yog/builder/matrix`, `yog/builder/rdf`, etc.)

- **Ergonomic API improvements** - Re-exported core functions in `yog` module
  - `yog.directed()` and `yog.undirected()` - Convenience functions for creating graphs with a single import
  - `yog.new()`, `yog.add_node()`, `yog.add_edge()` for more convenient imports
  - `yog.successors()`, `yog.predecessors()`, `yog.neighbors()`, `yog.all_nodes()`, `yog.successor_ids()`
  - `labeled.directed()` and `labeled.undirected()` - Matching convenience functions for labeled graph builder
  - All existing `yog/model` functions remain available (non-breaking)
  - Updated documentation and examples to use new imports
  - 6 additional tests for convenience functions

- **Visualization module (`yog/render`)** - Generate diagrams from graphs in multiple formats
  - `to_mermaid()` - Convert graphs to Mermaid syntax for GitHub/GitLab markdown
  - `to_dot()` - Convert graphs to DOT (Graphviz) format for publication-quality graphics
  - `to_json()` - Export graphs as JSON for web-based visualization libraries (D3.js, Cytoscape, etc.)
  - `path_to_options()` - Helper to highlight pathfinding results in Mermaid diagrams
  - `path_to_dot_options()` - Helper to highlight pathfinding results in DOT diagrams
  - Support for custom node and edge labels across all formats
  - Path highlighting with CSS classes (Mermaid) and color attributes (DOT)
  - Customizable JSON structure via mapper functions
  - Complete test coverage (47 tests)

### Fixed
- Undirected graphs now render each edge only once in all formats (previously showed duplicates)

### Changed
- Test suite expanded to 326 tests (from 302)

## [1.0.0] - 2025-02-26

### Added
- **Core graph data structures** (`yog/model`)
  - Directed and undirected graph support
  - Generic node and edge types
  - Add/remove nodes and edges
  - Query successors, predecessors, neighbors

- **Pathfinding algorithms** (`yog/pathfinding`)
  - Dijkstra's algorithm for non-negative weights
  - A* search with heuristic support
  - Bellman-Ford for negative weights and cycle detection

- **Graph traversal** (`yog/traversal`)
  - Breadth-First Search (BFS)
  - Depth-First Search (DFS)
  - Early termination support

- **Minimum Spanning Tree** (`yog/mst`)
  - Kruskal's algorithm with Union-Find

- **Topological sorting** (`yog/topological_sort`)
  - Kahn's algorithm
  - Lexicographical variant with heap-based implementation

- **Connected components** (`yog/components`)
  - Tarjan's algorithm for Strongly Connected Components (SCC)

- **Graph transformations** (`yog/transform`)
  - Transpose (O(1) edge reversal)
  - Map nodes and edges (functor operations)
  - Filter nodes with automatic edge pruning
  - Merge graphs

- Comprehensive test suite (276 tests)
- Complete documentation with examples
- Published to Hex package manager

[1.1.0]: https://github.com/yourusername/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yourusername/yog/releases/tag/v1.0.0
