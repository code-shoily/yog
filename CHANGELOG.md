# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 6.0.0 (Unreleased)

### Breaking Changes

- **Unified Transformation API** (`yog/transform`, `yog`):
  - Consolidated `map_nodes`, `map_edges`, and `filter_nodes` to always include node and edge identifiers in their callbacks by default. This provides 
    immediate topological context to all transformation operations.
  - Removed redundant `_indexed` variants: `map_nodes_indexed`, `map_edges_indexed`, and `filter_nodes_indexed` are now fully merged into their base functions.
  - Updated signatures:
    - `map_nodes` / `filter_nodes`: `fn(NodeId, n) -> m / Bool`
    - `map_edges`: `fn(NodeId, NodeId, e) -> m`

- **Relocated Dijkstra Traversal** (`yog/traversal`):
  - Removed `implicit_dijkstra` from the generic traversal module. This function has been relocated to `yog/pathfinding/dijkstra` as `fold` to better align with the library's module-based organization of algorithms.

- **Edge Addition API Changes**: `add_edge()` and `add_edge_with_combine()` now return `Result(Graph, String)` instead of `Graph` to prevent "ghost nodes". For auto-creation of missing nodes, use `add_edge_ensure()` or `add_edge_with()`.

### Added

- **Stochastic Graph Generators** (`yog/generator/random`): Added full parity with Elixir implementation:
  - `rmat`, `kronecker` - Recursive Kronecker graph generation for realistic network structures.
  - `geometric` - Random geometric graphs connection nodes within distance thresholds.
  - `dcsbm`, `hsbm`, `sbm` - Advanced Stochastic Block Models for hierarchical and degree-controlled community structure.
  - `configuration_model`, `randomize_degree_sequence` - Degree-preserving graph generation and randomization.
  - All generators support `seed` for reproducibility and include `*_with_type` variants.
  - **Maze Generation Algorithms** (`yog/generator/maze`): New module for creating perfect mazes on grids:
    - **P0**: `binary_tree`, `sidewinder`, `recursive_backtracker`, `hunt_and_kill`.
    - **P1**: `aldous_broder`, `wilson`, `kruskal`, `growing_tree` (with `Last`, `First`, `Random`, `Middle` selectors).
    - **P2**: `prim_simplified`, `prim_true`, `ellers`, `recursive_division`.
    - All algorithms return `Grid` types, fully integrated with pathfinding and ASCII renderers.

- **Classic Graph Generators** (`yog/generator/classic`): Fully synchronized with Elixir's suite:
  - **Platonic Solids**: `tetrahedron`, `cube`, `octahedron`, `dodecahedron`, `icosahedron`.
  - **Special Bipartite**: `crown`, `turan`.
  - **Trees & Structures**: `kary_tree`, `complete_kary`, `caterpillar`, `friendship`, `windmill`, `book`.
  - Grid/Ladder Variants: `hypercube`, `ladder`, `circular_ladder`, `mobius_ladder`.

- **Pathfinding Optimizations** (`yog/pathfinding`):
  - **Dijkstra Refactor**: Now implemented as a 0-heuristic application of the A* engine for unified code paths.
  - **Bellman-Ford**: Optimized with early-exit (Syme-opt) logic, matching Elixir's performance on graphs without negative cycles.
  - **Unweighted Pathfinding**: New BFS-based `shortest_path`, `single_source_distances`, and `all_pairs_shortest_paths` (APSP) for high-speed topological analysis.

- **New Traversal Algorithms** (`yog/traversal`):
  - Added `best_first_walk` and `best_first_fold` for Greedy Best-First Search exploration.
  - Added `random_walk` for stochastic path simulation.

- **K-Core Decomposition** (`yog/connectivity`): New functions for analyzing graph resilience and core structure, ported from Elixir:
  - `k_core/2` - Returns the maximal subgraph where every node has at least degree `k`.
  - `core_numbers/1` - Returns the largest core number for each node (Batagelj-Zaversnik O(V+E) algorithm).
  - `degeneracy/1` - Returns the maximum core number in the graph.
  - `shell_decomposition/1` - Groups nodes by their core number (k-shells).

- **Path Hydration** (`yog/pathfinding/path`): Added `hydrate_path/2` to reconstruct a sequence of edges from a list of node IDs.
  - Given a path like `[1, 2, 3]`, returns `[#(1, 2, edge_data), #(2, 3, edge_data)]`.
  - Works with both directed and undirected graphs.

- **High-Performance Set Operations** (`yog/operation`):
  - Re-implemented `union`, `intersection`, `difference`, and `symmetric_difference` as declarative pipelines for $O(V+E)$ complexity.
  - Optimized `cartesian_product` and `power` (k-th graph power) implementations.

- **Graph Structure Properties** (`yog/property/structure`): New module for checking broad graph class memberships, ported from Elixir:
  - `is_tree/1` - Checks if an undirected graph is a tree (connected, acyclic, `|E| = |V| - 1`).
  - `is_arborescence/1` - Checks if a directed graph is an arborescence (single root, all others have in-degree 1, `|E| = |V| - 1`).
  - `is_complete/1` - Checks if every pair of distinct nodes is connected by a unique edge.
  - `is_regular/2` - Checks if every node has exactly degree `k`.
  - `is_connected/1`, `is_strongly_connected/1`, `is_weakly_connected/1` - Connectivity wrappers delegating to `yog/connectivity`.
  - `is_planar/1` - Necessary-condition planarity check using Euler's formula and bipartite edge bounds.
  - `is_chordal/1` - Chordal graph detection via Maximum Cardinality Search (MCS) and Perfect Elimination Order (PEO) verification.

- **Core Model Enhancements** (`yog/model`):
  - `add_edge_with/5` - Adds an edge while ensuring endpoints exist with a generator function.
  - Migrated core creation functions (`from_edges`, `from_unweighted_edges`, `from_adjacency_list`) to the model module.

### Changed

- **Renamed `utils` modules to `util`**: Following Gleam's singular naming convention:
  - `yog/internal/utils` → `yog/internal/util`
  - Corresponding test files, FFI files (`utils_ffi.mjs` → `util_ffi.mjs`), and Erlang helper modules (`yog_internal_utils` → `yog_internal_util`) have been renamed accordingly.
  - Update your imports: `import yog/internal/utils` → `import yog/internal/util`.

- **Renamed `pathfinding/util` to `pathfinding/path`**: The pathfinding utility module has been renamed to better reflect its purpose as the home of the `Path` type and path-related helpers:
  - `yog/pathfinding/util` → `yog/pathfinding/path`
  - Internal pathfinding helpers (`compare_frontier`, `compare_distance_frontier`, `compare_a_star_frontier`, `should_explore_node`) have been moved to `yog/internal/util`.
  - Update your imports: `import yog/pathfinding/util` → `import yog/pathfinding/path`.

- **Promoted Multigraph and DAG Modules**: The `yog/multi/*` and `yog/dag/*` modules are now mature, stable, and fully documented.
- **Consolidated Transform Operations** (`yog/transform`): Migrated reachability-based transformations (`transitive_closure`, `transitive_reduction`) from DAG-specific algorithms to the core transform module for use on all graph types.
- **Refactored DAG Algorithms**: Simplified internal path reconstruction and consolidated redundant helper functions.

### Fixed

- **Edge Pruning Consistency** (`yog/transform`): Fixed a bug in `filter_edges` where inbound edges in directed graphs were not being correctly pruned.
- **Enhanced DAG Testing**: Established a robust property-based testing suite using `qcheck` to ensure correctness across topological sorting and reachability analysis.

- **Deterministic Label Propagation** (`yog/community/label_propagation`): Fixed a critical source of non-determinism where `most_frequent` tie-breaking used an unseeded `float.random()` instead of the algorithm's RNG. LPA is now fully deterministic for a given seed, and the default seed has been updated to `42` for reliable behavior in tests and documentation examples.

## 5.2.1 - 2026-04-08

### Removed

- **Cyclicity from Traversal** (`yog/traversal`): Removed `is_cyclic/1` and `is_acyclic/1`. Use `yog/property/cyclicity` instead.

## 5.2.0 - 2026-04-08

### Added

- **Enhanced Internal Utilities** (`yog/internal/utils`): Added `norm_diff/3` and `fisher_yates/2`.
- **Polished ASCII Rendering** (`yog/render/ascii`): Unicode box-drawing, cell occupants, and toroidal grid rendering.

## 5.1.1 - 2026-03-23

### Changed

- Replaced `gleamy_structures` with internal `priority_queue` and `pairing_heap` implementations.

### Removed

- `yog/render/json` module (use `yog_io` instead).
- `gleamy_structures` dependency.
- Deprecated `yog/dag/algorithms` and `yog/dag/models` (use singular `algorithm` / `model`).

## 5.1.0 - 2026-03-22

### Added

- **Bidirectional Search** (`yog/pathfinding/bidirectional`): `shortest_path_unweighted/3`, `shortest_path/6`, and convenience wrappers.
- **Graph Operations** (`yog/operation`): `union`, `intersection`, `difference`, `symmetric_difference`, `disjoint_union`, `cartesian_product`, `compose`, `power`, `is_subgraph`, `is_isomorphic`.
- **Connected Components** (`yog/connectivity`): `connected_components/1`, `weakly_connected_components/1`.
- **Enhanced DOT Rendering** (`yog/render/dot`): Generic `DotOptions`, per-element styling, and subgraph/cluster support.

### Documentation

- Marked `yog/multi/*` and `yog/dag/*` as experimental.

### Changed

- Renamed `yog/dag/algorithms` → `yog/dag/algorithm` and `yog/dag/models` → `yog/dag/model`.
- Added descriptive labels to semiring and algorithm parameters across pathfinding, centrality, health, and community modules.

### Fixed

- `all_maximal_cliques` empty graph bug (returns `[]` instead of `[set.new()]`).
- Eigenvector centrality oscillation bug on symmetric graphs.

## 5.0.0 - 2026-03-20

### Breaking Changes

- Renamed plural modules to singular: `yog/properties/*` → `yog/property/*`, `yog/generators/*` → `yog/generator/*`.
- Renamed `yog/io/*` → `yog/render/*` (dot, mermaid, json, ascii).
- `DotOptions` and `MermaidOptions` now use ADTs instead of strings.
- `add_edge()` and `add_edge_with_combine()` now return `Result(Graph, String)`; use `add_edge_ensure()` or `add_edge_with()` for auto-node creation.

### Added

- Bulk edge addition: `add_edges`, `add_simple_edges`, `add_unweighted_edges`.
- Toroidal grid builder (`yog/builder/toroidal`).
- ASCII art rendering (`yog/render/ascii`).
- Network health metrics (`yog/health`): `diameter`, `radius`, `eccentricity`, `assortativity`, `average_path_length`.
- Grid heuristics: `chebyshev_distance`, `octile_distance`.
- `GLEAM_FSHARP_COMPARISON.md`.
- **Community Detection Suite** (`yog/community/*`): 10 algorithms (Louvain, Leiden, Label Propagation, Girvan-Newman, Walktrap, Infomap, Clique Percolation, Local Community, Fluid Communities, Random Walk) plus metrics module.

### Changed

- Moved `examples/` → `test/examples/` and `bench/` → `test/bench/`.

## 4.0.0 - 2026-03-14

### Breaking Changes

- `model.remove_edge` on undirected graphs now removes both directions automatically.

### Added

- Property-based testing with `qcheck` across core algorithms.
- Comprehensive module-level docs for 22 modules.
- `GLEAM_FSHARP_COMPARISON.md`.

### Changed

- Moved `examples/` → `test/examples/` and `bench/` → `test/bench/`.

## 3.1.0 - 2026-03-10

### Breaking

- Removed `yog/dag` facade module. Import `yog/dag/algorithm` or `yog/dag/model` directly.

### Added

- **Centrality** (`yog/centrality`): `degree`, `closeness`, `harmonic_centrality`, `betweenness`, `pagerank`, `eigenvector`, `katz`, `alpha_centrality`.
- **Multigraph** (`yog/multi/*`): `multi/model`, `multi/traversal`, `multi/eulerian`.

## 3.0.0 - 2026-03-08

### Breaking Changes

- Graph-first API: `graph` parameter moved to first position in traversal functions.
- Module reorganization:
  - `yog/components` → `yog/connectivity`
  - `yog/min_cut` → `yog/flow/min_cut`
  - `yog/max_flow` → `yog/flow/max_flow`
  - `yog/topological_sort` → `yog/traversal`
  - `yog/clique` → `yog/property/clique`
  - `yog/bipartite` → `yog/property/bipartite`
  - `yog/eulerian` → `yog/property/eulerian`
  - `yog/pathfinding` → split into `dijkstra`, `a_star`, `bellman_ford`, `floyd_warshall`
- Rendering split into `yog/io/*`.
- `fold_walk` uses `WalkControl` (`Continue`, `Stop`, `Halt`).

### Added

- `*_int` and `*_float` convenience wrappers for common weight types.
- Live builder (`yog/builder/live`).
- DAG module (`yog/dag`): topological sort, longest path, transitive closure/reduction, LCA, reachability counting.
- Network simplex (`yog/flow/network_simplex`).
- `is_acyclic`/`is_cyclic` re-exported from `yog/property`.

## 2.2.1 - 2026-03-07

### Added

- Top-level re-exports: `walk`, `walk_until`, `fold_walk`, `transpose`, `map_nodes`, etc.

### Fixed

- `builder/grid` predicates now filter both source and destination cells.

### Performance

- Optimized `mst.kruskal()` disjoint set initialization.

## 2.2.0 - 2026-03-04

### Fixed

- `mst.prim()`: undirected neighbor expansion.
- `min_cut.global_min_cut()`: Stoer-Wagner cut weight calculation.
- `traversal` DFS: corrected stack order.

### Added

- `builder/grid.from_2d_list_with_topology()` with chess topologies and movement predicates.
- `model.add_edge_ensured()`: auto-creates missing nodes.
- `transform.filter_edges()`, `transform.complement()`, `transform.to_directed()`, `transform.to_undirected()`.

### Performance

- `clique`: adjacency sets + greedy pivoting.
- `model.neighbors()`: O(N log N) deduplication.
- `filter_nodes()`: O(E log V) with Set membership.
- `eulerian`: O(E) Hierholzer's algorithm.

## 2.1.0 - 2026-03-01

### Added

- Implicit pathfinding: `implicit_dijkstra`, `implicit_a_star`, and `*_by` variants.
- Implicit Bellman-Ford: `implicit_bellman_ford` and `implicit_bellman_ford_by`.
- `traversal.fold_walk`, `traversal.implicit_fold`, `implicit_fold_by`.
- Maximum clique: `max_clique`, `all_maximal_cliques`, `k_cliques` (Bron-Kerbosch).
- `pathfinding.distance_matrix`.
- `mst.prim()`.
- `components.kosaraju()`.

## 2.0.0 - 2026-02-27

### Breaking Changes

- `floyd_warshall()`: return type changed to `Dict(#(NodeId, NodeId), e)`.
- `lexicographical_topological_sort()`: `compare_ids` → `compare_nodes`.

### Fixed

- `min_cut.global_min_cut()`: list reversal bug in MAS.
- `transform.contract()`: weight doubling for undirected graphs.

### Performance

- `builder/grid`: O(N²) → O(N).
- `traversal` BFS: O(1) amortized queue.
- `floyd_warshall`: flat dictionary structure.
- `min_cut`: heap-based MAS.

## 1.3.0 - 2026-02-27

### Added

- Max Flow (`yog/max_flow`): Edmonds-Karp.
- Graph Generators (`yog/generator`): complete, cycle, path, star, wheel, bipartite, random graphs.
- Stable Marriage (`yog/bipartite`): Gale-Shapley.

## 1.2.0 - 2026-02-26

### Added

- Grid builder (`yog/builder/grid`).
- Single-source distances from Dijkstra.
- `add_unweighted_edge`, `add_simple_edge` conveniences.

## 1.1.0 - 2026-02-26

### Added

- Labeled builder (`yog/builder/labeled`).
- `yog` ergonomic API: `directed()`, `undirected()`.
- Visualization (`yog/render`): Mermaid, DOT, ASCII.

## 1.0.0 - 2025-02-26

### Added

- Initial release.
- Core graph structures (directed/undirected).
- Pathfinding: Dijkstra, A*, Bellman-Ford.
- Traversal: BFS, DFS.
- MST: Kruskal's algorithm.
- Topological sort: Kahn's algorithm.
- SCC: Tarjan's algorithm.
- Transformations: transpose, map, filter, merge.
