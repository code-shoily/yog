# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 1.3.0

### Added
- **Maximum Flow (`yog/max_flow`)**: Edmonds-Karp algorithm with `edmonds_karp()` and `min_cut()` functions. Supports generic numeric types. Examples: `network_bandwidth.gleam`, `job_matching.gleam`.
- **Graph Generators (`yog/generators`)**: Create classic and random graph patterns for testing and simulation.
  - Classic patterns: `complete`, `cycle`, `path`, `star`, `wheel`, `complete_bipartite`, `binary_tree`, `grid_2d`, `petersen`
  - Random models: `erdos_renyi_gnp`, `erdos_renyi_gnm`, `barabasi_albert`, `watts_strogatz`, `random_tree`
- **Stable Marriage (`yog/bipartite`)**: Gale-Shapley algorithm for stable matching problems. Supports unbalanced groups and incomplete preferences. Example: `medical_residency.gleam`.

### Performance
- Optimized max flow implementation with flat dictionaries and efficient queue operations
- Tail-recursive generators prevent stack overflow

### Changed
- Improved documentation and examples

## [1.2.4] - 2026-02-27

### Added
- Graph creation helpers: `from_edges`, `from_unweighted_edges`, `from_adjacency_list`
- Labeled builder convenience: `from_list`, `from_unweighted_list`
- Example: `graph_creation.gleam`

## [1.2.3] - 2026-02-27

### Added
- Eulerian paths & circuits (`yog/eulerian`): Hierholzer's algorithm
- Bipartite graphs (`yog/bipartite`): Detection and maximum matching

## [1.2.2] - 2026-02-27

### Added
- Disjoint Set / Union-Find (`yog/disjoint_set`): Public API with path compression and union by rank
- Connectivity analysis (`yog/connectivity`): Find bridges and articulation points (Tarjan's algorithm)
- Graph transformations: `subgraph`, `contract`
- Model enhancements: `remove_node`, `add_edge_with_combine`
- Global minimum cut (`yog/min_cut`): Stoer-Wagner algorithm

### Fixed
- Bug in `transform.merge()` with overlapping source nodes

## [1.2.1] - 2026-02-26

### Added
- Floyd-Warshall algorithm: All-pairs shortest paths with negative weight support

### Fixed
- Bug in Floyd-Warshall self-loop handling
- Critical bug in `model.all_nodes()`: Now correctly includes isolated nodes

## [1.2.0] - 2026-02-26

### Added
- Grid graph builder (`yog/builder/grid`): Convert 2D arrays to graphs for pathfinding
- Single-source distances: Compute distances to all reachable nodes
- Convenience functions: `add_unweighted_edge`, `add_simple_edge`

## [1.1.0] - Unreleased

### Added
- Labeled graph builder (`yog/builder/labeled`): Build graphs with arbitrary labels
- Ergonomic API: Convenience functions in `yog` module (`directed`, `undirected`, etc.)
- Visualization (`yog/render`): Export to Mermaid, DOT (Graphviz), and JSON formats

### Fixed
- Undirected graphs now render each edge only once

## [1.0.0] - 2025-02-26

### Added
- Core graph data structures with generic types
- Pathfinding: Dijkstra, A*, Bellman-Ford
- Traversal: BFS, DFS with early termination
- Minimum Spanning Tree: Kruskal's algorithm
- Topological sorting: Kahn's algorithm
- Connected components: Tarjan's SCC
- Graph transformations: transpose, map, filter, merge

[1.3.0]: https://github.com/code-shoily/yog/compare/v1.2.4...v1.3.0
[1.2.4]: https://github.com/code-shoily/yog/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/code-shoily/yog/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/code-shoily/yog/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/code-shoily/yog/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/code-shoily/yog/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/code-shoily/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/code-shoily/yog/releases/tag/v1.0.0
