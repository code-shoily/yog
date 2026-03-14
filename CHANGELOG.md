# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.0.0 - Unreleased

### Added

- **Testing**: Exhaustive property-based testing using `qcheck` across core algorithms (pathfinding, connectivity, MST) and properties.

## 3.1.0 - 2026-03-10

### Breaking

  - Removed the `dag` facade module. Instead of `import yog/dag`, you should either import `dag/model` or `dag/algorithms`

### Added

- **Centrality Module** (`yog/centrality`): Graph analysis for identifying important nodes
  - `degree/2`: Local connectivity measure with In/Out/Total modes
  - `closeness/5` & `harmonic_centrality/5`: Distance-based importance (latter handles disconnected graphs)
  - `betweenness/5`: Bridge/gatekeeper detection using Brandes' algorithm
  - `pagerank/2`: Link-quality importance with configurable damping
  - `eigenvector/3`: Influence based on neighbor centrality (power iteration)
  - `katz/5` & `alpha_centrality/5`: Attenuated centrality for directed networks
  - Convenience wrappers: `*_int()`, `*_float()` for common weight types

- **Multigraph Module** (`yog/multi/*`): Initial support for parallel edges (multiple edges between same node pair)
  - `yog/multi/model`: `MultiGraph(n, e)` model with conversion helpers
  - `yog/multi/traversal`: BFS/DFS with edge-aware visited tracking
  - `yog/multi/eulerian`: Hierholzer's algorithm returning `EdgeId` paths for unambiguous parallel edge traversal

## 3.0.0 - 2026-03-08

### Breaking Changes

- **Graph-First API**: `graph` parameter moved to first position in `walk`, `walk_until`, `fold_walk`
- **Module Reorganization**:
  - `yog/components` → `yog/connectivity`
  - `yog/min_cut` → `yog/flow/min_cut`
  - `yog/max_flow` → `yog/flow/max_flow`
  - `yog/topological_sort` → `yog/traversal`
  - `yog/clique` → `yog/properties/clique`
  - `yog/bipartite` → `yog/properties/bipartite`
  - `yog/eulerian` → `yog/properties/eulerian`
  - `yog/pathfinding` → `yog/pathfinding/dijkstra`, `yog/pathfinding/a_star`, `yog/pathfinding/bellman_ford`, `yog/pathfinding/floyd_warshall`
  - Facade modules removed; import specific modules (e.g., `yog/pathfinding/dijkstra`)
- **Rendering**: `yog/render` split into `yog/io/*` (mermaid, dot, json)
- **Traversal Control**: `fold_walk` and `implicit_fold` now use `WalkControl` enum (`Continue`, `Stop`, `Halt`)

### Added

- **Convenience Wrappers**: `*_int()` and `*_float()` functions for common weight types:
  - `dijkstra`: `shortest_path_int`, `shortest_path_float`, `single_source_distances_int`, `single_source_distances_float`
  - `a_star`: `a_star_int`, `a_star_float`
  - `bellman_ford`: `bellman_ford_int`, `bellman_ford_float`
  - `floyd_warshall`: `floyd_warshall_int`, `floyd_warshall_float`
  - `max_flow`: `edmonds_karp_int`
- **Live Builder** (`yog/builder/live`): Transaction-style builder for incremental graph construction with `sync()` for O(ΔE) updates
- **DAG Module** (`yog/dag`): Strict `Dag(n, e)` type with O(V+E) algorithms:
  - `topological_sort`, `longest_path`, `transitive_closure`, `transitive_reduction`
  - `lowest_common_ancestors`, `count_reachability`
- **Network Simplex** (`yog/flow/network_simplex`): Minimum cost flow solver
- `is_acyclic`/`is_cyclic` re-exported from `yog/properties`

## 2.2.1 - 2026-03-07

### Added

- Top-level re-exports: `walk`, `walk_until`, `fold_walk`, `transpose`, `map_nodes`, etc.

### Fixed

- `builder/grid` predicates now filter both source and destination cells

### Performance

- `mst.kruskal()`: Optimized disjoint set initialization

## 2.2.0 - 2026-03-04

### Fixed

- `mst.prim()`: Fixed neighbor expansion for undirected edges
- `min_cut.global_min_cut()`: Fixed cut weight calculation in Stoer-Wagner
- `traversal` DFS: Fixed stack order (now uses `list.fold_right`)

### Added

- `builder/grid.from_2d_list_with_topology()`: Custom movement patterns
  - Chess-themed topologies: `rook()`, `bishop()`, `queen()`, `knight()`
  - Movement predicates: `avoiding()`, `walkable()`, `always()`
- `model.add_edge_ensured()`: Auto-creates missing nodes
- `transform.filter_edges()`, `transform.complement()`, `transform.to_directed()`, `transform.to_undirected()`

### Performance

- `clique`: Precomputed adjacency sets + greedy pivoting
- `model.neighbors()`: O(N log N) deduplication using Sets
- `filter_nodes()`: O(E log V) using Set membership
- `eulerian`: O(E) Hierholzer's using Dict adjacency

## 2.1.0 - 2026-03-01

### Added

- Implicit pathfinding: `implicit_dijkstra`, `implicit_dijkstra_by`, `implicit_a_star`, `implicit_a_star_by`
- Implicit Bellman-Ford: `implicit_bellman_ford`, `implicit_bellman_ford_by`
- `traversal.fold_walk`: Stateful traversal with `WalkControl`
- `traversal.implicit_fold`, `implicit_fold_by`: BFS/DFS on implicit graphs
- Maximum Clique: `max_clique`, `all_maximal_cliques`, `k_cliques` (Bron-Kerbosch)
- `pathfinding.distance_matrix`: Auto-selects Floyd-Warshall vs multiple Dijkstra
- `mst.prim()`: Prim's MST algorithm
- `components.kosaraju()`: Kosaraju's SCC algorithm

## 2.0.0 - 2026-02-27

### Breaking Changes

- `floyd_warshall()`: Return type changed from `Dict(NodeId, Dict(NodeId, e))` to `Dict(#(NodeId, NodeId), e)`
- `lexicographical_topological_sort()`: Changed `compare_ids` to `compare_nodes` (compares node data, not IDs)

### Fixed

- `min_cut.global_min_cut()`: Fixed list reversal bug in MAS
- `transform.contract()`: Fixed weight doubling for undirected graphs

### Performance

- `builder/grid`: O(N²) → O(N) using dict lookups
- `traversal` BFS: O(1) amortized queue operations
- `floyd_warshall`: Flat dictionary structure
- `min_cut`: Heap-based MAS (O(V² log V) vs O(V³))

## 1.3.0 - 2026-02-27

### Added

- Max Flow (`yog/max_flow`): Edmonds-Karp algorithm
- Graph Generators (`yog/generators`): Complete, cycle, path, star, wheel, bipartite, random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz)
- Stable Marriage (`yog/bipartite`): Gale-Shapley algorithm

## 1.2.0 - 2026-02-26

### Added

- Grid builder (`yog/builder/grid`): 2D array to graph conversion
- Single-source distances from Dijkstra
- `add_unweighted_edge`, `add_simple_edge` conveniences

## 1.1.0 - 2026-02-26

### Added

- Labeled builder (`yog/builder/labeled`): String/any type node labels
- `yog` ergonomic API: `directed()`, `undirected()`
- Visualization (`yog/render`): Mermaid, DOT, JSON export

## 1.0.0 - 2025-02-26

### Added

- Initial release
- Core graph structures (directed/undirected)
- Pathfinding: Dijkstra, A*, Bellman-Ford
- Traversal: BFS, DFS
- MST: Kruskal's algorithm
- Topological sort: Kahn's algorithm
- SCC: Tarjan's algorithm
- Transformations: transpose, map, filter, merge
