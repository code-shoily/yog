# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2.0.1

### Added
- **`traversal.fold_walk()`**: Fold over nodes during traversal with metadata (depth, parent). Enables state accumulation during BFS/DFS with fine-grained control via `Continue`/`Stop`/`Halt`. Perfect for building parent maps, collecting nodes within distance limits, or computing statistics during traversal.
  - New types: `WalkControl` (`Continue`, `Stop`, `Halt`), `WalkMetadata` (depth, parent)
  - `Halt` control: Stop the entire traversal immediately and return the accumulator (makes `walk_until` a special case of `fold_walk`)
  - Works with both `BreadthFirst` and `DepthFirst` traversal orders
  - Examples: Distance-limited search, shortest path tree construction, depth distribution analysis, early termination with accumulated state
- **Maximum Clique (`yog/clique`)**: Bron-Kerbosch algorithm with pivoting for finding maximum and all maximal cliques
  - `max_clique()`: Find the largest clique (complete subgraph) in O(3^(n/3)) worst case, efficient in practice
  - `all_maximal_cliques()`: Find all maximal cliques (cliques that cannot be extended)
  - `k_cliques()`: Find all cliques of exactly size k with early pruning for efficiency. Particularly useful for finding triangles (k=3) in social networks
  - Use cases: Social network analysis, protein complex identification, graph coloring bounds, pattern matching in biological networks
  - Works on undirected graphs
- **`pathfinding.distance_matrix()`**: Compute shortest distances between points of interest with automatic algorithm selection
  - Automatically chooses Floyd-Warshall (O(V³)) for dense POIs or multiple Dijkstra (O(P×(V+E) log V)) for sparse POIs
  - Crossover heuristic: Uses Floyd-Warshall when POIs > 1/3 of total nodes
  - Returns only POI-to-POI distances, not all node pairs
  - Use cases: AoC 2016 Day 24, TSP-like problems, network analysis with specific landmarks
- **`mst.prim()`**: Prim's algorithm for Minimum Spanning Tree. Grows MST from a starting node by repeatedly adding minimum-weight edges connecting visited to unvisited nodes
  - Time complexity: O(E log V) where E is edges and V is vertices
  - Alternative to Kruskal's algorithm with different performance characteristics
  - Works on both directed and undirected graphs (treats directed as undirected)
- **`components.kosaraju()`**: Kosaraju's algorithm for finding Strongly Connected Components
  - Two-pass DFS approach: computes finishing times, transposes graph, processes in reverse order
  - Time complexity: O(V + E) where V is vertices and E is edges
  - Alternative to Tarjan's algorithm, simpler to understand with clear separation of concerns
  - Use cases: Analyzing directed graph connectivity, finding cycles, dependency analysis

## 2026-02-27 - 2.0.0

### Breaking Changes
- **`pathfinding.floyd_warshall()`**: Return type changed from `Result(Dict(NodeId, Dict(NodeId, e)), Nil)` to `Result(Dict(#(NodeId, NodeId), e), Nil)`
  - **Before**: `let assert Ok(row) = dict.get(distances, 1); dict.get(row, 2)`
  - **After**: `dict.get(distances, #(1, 2))`
  - **Benefit**: Eliminates one layer of dictionary lookups for better performance

- **`topological_sort.lexicographical_topological_sort()`**: Parameter changed from `compare_ids: fn(NodeId, NodeId) -> Order` to `compare_nodes: fn(n, n) -> Order` ([#3](https://github.com/code-shoily/yog/issues/3))
  - **Before**: `lexicographical_topological_sort(graph, int.compare)` // Compared node IDs
  - **After**: `lexicographical_topological_sort(graph, string.compare)` // Compares node data
  - **Benefit**: Intuitive API that allows comparison by actual node data (e.g., alphabetical sorting by name, priority sorting by timestamp) without encoding sort logic into node IDs

### Fixed
- **Critical bug in `min_cut.global_min_cut()`**: Fixed incorrect list reversal in Maximum Adjacency Search (MAS) that caused the algorithm to use the starting node instead of the last-added node, preventing it from finding the true minimum cut
- **Critical bug in `transform.contract()`**: Fixed weight doubling for undirected graphs where edge weights were incorrectly combined twice during node contraction
- These fixes enable correct minimum cut detection for unweighted graphs (e.g., AoC 2023 Day 25)

### Performance
- **Grid builder (`builder/grid.from_2d_list`)**: Optimized from O(N²) to O(N) by using dictionary lookups instead of `list.drop` traversals when checking neighbor cell data. For a 100×100 grid, this eliminates ~40,000 unnecessary list traversals
- **BFS traversal**: Optimized with O(1) amortized queue operations instead of O(n) `list.append`, improving BFS from O(V²) to O(V + E)
- **Floyd-Warshall**: Flat dictionary structure eliminates nested lookups
- **Maximum Adjacency Search**: Heap-based priority queue with lazy deletion, improving time complexity from O(V³) to O(V² log V)
- **Priority queue migration**: Replaced custom heap implementation with `gleamy_structures` priority queue for better maintainability and performance in pathfinding, topological sort, and minimum cut algorithms
- New shared `yog/internal/queue` module (Okasaki-style two-list queue) used by both `max_flow` and `traversal`

## [1.3.0] - 2026-02-27

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

[1.3.1]: https://github.com/code-shoily/yog/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/code-shoily/yog/compare/v1.2.4...v1.3.0
[1.2.4]: https://github.com/code-shoily/yog/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/code-shoily/yog/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/code-shoily/yog/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/code-shoily/yog/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/code-shoily/yog/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/code-shoily/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/code-shoily/yog/releases/tag/v1.0.0
