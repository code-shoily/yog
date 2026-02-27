# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 1.2.5

### Added
- **Maximum Flow (`yog/max_flow`)**: Highly optimized Edmonds-Karp implementation (O(VE²)).
  - Includes `edmonds_karp()` for max flow and `min_cut()` for bottleneck analysis.
  - Supports integers, floats, and custom numeric types.
  - Features 5x performance boost via flat dictionary residual capacities and Banker's Queue for O(1) BFS.
  - Demonstrates practical usage in `network_bandwidth.gleam` and `job_matching.gleam`.
- **Graph Generators (`yog/generators`)**: Specialized module for creating 9+ classic graph patterns.
  - Generates `complete`, `cycle`, `path`, `star`, `wheel`, `complete_bipartite`, `binary_tree`, `grid_2d`, and `petersen` graphs.
  - Supports both directed and undirected variants with sequential Node IDs.
  - Showcased in `graph_generation_showcase.gleam`.
- **Stable Marriage Algorithm (`yog/bipartite`)**: Gale-Shapley implementation (O(n²)) for stable matchings.
  - Proposer-optimal results with support for unbalanced groups and incomplete preferences.
  - Useful for NRMP-style matching, job assignments, and resource allocation.
  - Realistic example provided in `medical_residency.gleam`.

### Performance
- **Max Flow Optimization**: Reduced test suite execution time from 28s to ~2s by eliminating Graph structure rebuilds and O(V²) BFS operations.
- **Recursion Safety**: Implemented tail-recursive generators to prevent stack overflow on deep structures.

### Changed
- Refactored README for better clarity and structure.

## [1.2.4] - 2026-02-27

### Added
- **Graph Creation Helpers**: Bulk construction via `from_edges`, `from_unweighted_edges`, and `from_adjacency_list`.
- **Labeled Builder Convenience**: Added `from_list` and `from_unweighted_list` to `yog/builder/labeled`.
- **New Example**: `examples/graph_creation.gleam` demonstrating 10+ ways to initialize graphs.

### Changed
- Refactored README for better clarity and structure.

## [1.2.3] - 2026-02-27

### Added
- **Eulerian Paths & Circuits (`yog/eulerian`)**: Detection and pathfinding via Hierholzer's algorithm (O(V+E)).
- **Bipartite Graphs (`yog/bipartite`)**: 2-coloring detection and maximum matching via augmenting paths.

## [1.2.2] - 2026-02-27

### Added
- **Disjoint Set / Union-Find (`yog/disjoint_set`)**: Promoted to public API with O(α(n)) amortized operations. Supports `find`, `union`, `connected`, and `to_lists`.
- **Connectivity Analysis (`yog/connectivity`)**: New module for finding bridges and articulation points in undirected graphs via Tarjan's algorithm.
- **Improved Transformations**:
  - `transform.subgraph`: Efficiently extract nodes and connecting edges.
  - `transform.contract`: Merge nodes and combine edge weights.
- **Model Enhancements**:
  - `remove_node`: proportional cleanup of edges.
  - `add_edge_with_combine`: Custom weight merging for existing edges.
- **Global Minimum Cut (`yog/min_cut`)**: Stoer-Wagner algorithm for undirected weighted graphs.

### Fixed
- **Bug in `transform.merge()`**: Fixed deep merge logic to prevent data loss when merging graphs with overlapping source nodes.

### Changed
- Promoted Disjoint Set to public API (moved from `internal/dsu`).
- Optimized internal state using `Set` for visits and `Option` for parent tracking.

## [1.2.1] - 2026-02-26

### Added
- **Floyd-Warshall algorithm (`pathfinding.floyd_warshall`)** - All-pairs shortest path computation
  - Computes shortest paths between all pairs of nodes in O(V³) time
  - Returns nested `Dict(NodeId, Dict(NodeId, distance))` for easy querying
  - Handles negative edge weights and detects negative cycles
  - Perfect for distance matrices, graph diameter, transitive closure, centrality measures
  - Ideal for AoC problems requiring all-pairs distances (e.g., 2022 Day 16)
  - Complete documentation with examples and usage guidance

### Fixed
- **Bug in Floyd-Warshall self-loop handling** - Fixed incorrect initialization that ignored self-loop edges
  - Initial implementation unconditionally set distance[i][i] = zero, ignoring actual self-loop edges
  - This caused negative self-loops (which should be detected as negative cycles) to be silently ignored
  - Fixed to use `min(zero, self_loop_weight)`: negative self-loops now correctly detected as cycles, positive self-loops correctly ignored (staying put is shorter)

- **Critical bug in `model.all_nodes()`** - Isolated nodes (nodes with no edges) are now correctly included
  - Previously, `all_nodes()` only returned nodes that appeared in `out_edges` or `in_edges`, silently excluding isolated nodes
  - This affected topological sort (isolated nodes weren't in the ordering) and SCC (isolated nodes weren't returned as single-element components)
  - Now correctly returns ALL nodes from `graph.nodes`, regardless of edge connectivity
  - This is a breaking behavior change if code relied on the old incorrect behavior

### Changed
- Eliminated all deprecation warnings by replacing `list.range` with internal `utils.range` helper.

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

- **Single-source distances (`pathfinding.single_source_distances`)** - Compute distances to all reachable nodes
  - Returns `Dict(NodeId, distance)` mapping each reachable node to its shortest distance
  - More efficient than running `shortest_path` multiple times
  - Common use cases: finding nearest target among many options, distance maps for AI, reverse pathfinding with `transform.transpose`
  - Time complexity: O((V + E) log V)

- **Convenience functions for unweighted edges** - Ergonomic alternatives when weights aren't needed
  - `yog.add_unweighted_edge()` - Add edges with `Nil` weight for truly unweighted graphs
  - `yog.add_simple_edge()` - Add edges with default weight of `1` for integer-weighted graphs
  - `labeled.add_unweighted_edge()` - Add unweighted edges to labeled graphs
  - `labeled.add_simple_edge()` - Add simple edges to labeled graphs with default weight `1`
  - Perfect for use cases like hop counts, orbital maps, or basic connectivity

### Changed
- No notable changes.

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
  - Lays foundation for future builders (`yog/builder/matrix`, `yog/builder/rdf`, etc.)

- **Ergonomic API improvements** - Re-exported core functions in `yog` module
  - `yog.directed()` and `yog.undirected()` - Convenience functions for creating graphs with a single import
  - `yog.new()`, `yog.add_node()`, `yog.add_edge()` for more convenient imports
  - `yog.successors()`, `yog.predecessors()`, `yog.neighbors()`, `yog.all_nodes()`, `yog.successor_ids()`
  - `labeled.directed()` and `labeled.undirected()` - Matching convenience functions for labeled graph builder
  - All existing `yog/model` functions remain available (non-breaking)
  - Updated documentation and examples to use new imports

- **Visualization module (`yog/render`)** - Generate diagrams from graphs in multiple formats
  - `to_mermaid()` - Convert graphs to Mermaid syntax for GitHub/GitLab markdown
  - `to_dot()` - Convert graphs to DOT (Graphviz) format for publication-quality graphics
  - `to_json()` - Export graphs as JSON for web-based visualization libraries (D3.js, Cytoscape, etc.)
  - `path_to_options()` - Helper to highlight pathfinding results in Mermaid diagrams
  - `path_to_dot_options()` - Helper to highlight pathfinding results in DOT diagrams
  - Support for custom node and edge labels across all formats
  - Path highlighting with CSS classes (Mermaid) and color attributes (DOT)
  - Customizable JSON structure via mapper functions

### Fixed
- Undirected graphs now render each edge only once in all formats (previously showed duplicates)

### Changed
- No notable changes.

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

- Complete documentation with examples
- Published to Hex package manager

[1.2.5]: https://github.com/code-shoily/yog/compare/v1.2.4...v1.2.5
[1.2.4]: https://github.com/code-shoily/yog/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/code-shoily/yog/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/code-shoily/yog/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/code-shoily/yog/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/code-shoily/yog/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/code-shoily/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/code-shoily/yog/releases/tag/v1.0.0
