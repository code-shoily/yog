# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- **Connected Components Algorithms** (`yog/connectivity`): New functions for finding connected components in undirected and weakly connected components in directed graphs:
  - `connected_components/1` - Find connected components in undirected graphs using DFS
  - `weakly_connected_components/1` - Find weakly connected components in directed graphs (treating edges as undirected)
  - Both algorithms run in O(V + E) time complexity
  - See module documentation for comparison with existing SCC algorithms


## 5.0.0 - 2026-03-20

### Breaking Changes

- **Module Naming Convention**: Renamed plural directories to singular for consistency with Gleam conventions:
  - `yog/properties/*` → `yog/property/*`
  - `yog/generators/*` → `yog/generator/*`

- **Module Rename**: `yog/io/*` → `yog/render/*`
  - The `io` module name was misleading as it only contained rendering/output functionality
  - All rendering modules now live under `yog/render/`:
    - `yog/io/dot` → `yog/render/dot`
    - `yog/io/mermaid` → `yog/render/mermaid`
    - `yog/io/json` → `yog/render/json`
    - `yog/io/ascii` → `yog/render/ascii`
  - Update your imports: `import yog/io/dot` → `import yog/render/dot`

- **Typed Rendering Configuration**:
  - `yog/render/dot`: `DotOptions` now uses robust Algebraic Data Types (ADTs) like `Layout`, `RankDir`, `NodeShape`, and `Style` instead of strings. Numeric values now use `Float` for precision (e.g., `nodesep`, `penwidth`).
  - `yog/render/mermaid`: `MermaidOptions` now uses `Direction`, `NodeShape`, and `CssLength` ADTs, providing a type-safe way to configure diagram appearance.

- **Edge Addition API Changes**: `add_edge()` and `add_edge_with_combine()` now return `Result(Graph, String)` instead of `Graph` to prevent "ghost nodes":
  - `add_edge(graph, from: 1, to: 2, with: 10)` now returns `Error("Node 1 does not exist")` if nodes don't exist
  - `add_edge_with_combine(graph, from: 1, to: 2, with: 5, using: int.add)` also returns `Result`
  - Use `let assert Ok(graph) = add_edge(...)` when nodes are guaranteed to exist
  - Use `result.try(add_edge(...))` for chaining operations
  - For auto-creation of missing nodes, use the renamed functions:
    - `add_edge_ensured()` → `add_edge_ensure()`
    - `add_edge_ensured_with()` → `add_edge_with()`
  - **Rationale**: Previously, these functions could create "ghost nodes" that exist in edge dictionaries but not in the nodes map, causing unexpected behavior in algorithms like centrality calculations and topological sorts. Check [this PR](https://github.com/code-shoily/yog/pull/10) for more info.

### Added

- **Bulk Edge Addition Functions**: New convenience functions for adding multiple edges in a single operation:
  - `add_edges(graph, edges: List(#(NodeId, NodeId, e)))` - Add multiple weighted edges
  - `add_simple_edges(graph, edges: List(#(NodeId, NodeId)))` - Add multiple edges with weight 1
  - `add_unweighted_edges(graph, edges: List(#(NodeId, NodeId)))` - Add multiple edges with weight Nil
  - These functions fail fast on the first missing node, reducing Result-handling boilerplate compared to chaining individual `add_edge` calls

- **Toroidal Grid Builder** (`yog/builder/toroidal`): Support for graphs with wrapping (torus) topology. Includes specialized toroidal distance heuristics: `toroidal_manhattan_distance`, `toroidal_chebyshev_distance`, and `toroidal_octile_distance`.

- **ASCII Art Rendering** (`yog/render/ascii`): New module for rendering grids and mazes as ASCII text, ideal for terminal output and debugging.

- **Network Health Metrics** (`yog/health`): New module for measuring graph structural quality:
  - `diameter/5` - Maximum distance (worst-case reachability)
  - `radius/5` - Minimum eccentricity (best central point)
  - `eccentricity/6` - Maximum distance from a specific node
  - `assortativity/1` - Degree correlation (homophily vs heterophily)
  - `average_path_length/6` - Typical separation between nodes

- **Grid Distance Heuristics**: Added `chebyshev_distance` (for 8-way movement) and `octile_distance` (for realistic diagonal costs) to `yog/builder/grid`.

- **F# Comparison**: Added `GLEAM_FSHARP_COMPARISON.md` documenting feature parity, API differences, and migration guidance between the Gleam and F# implementations of Yog.

- **Community Detection Suite** (`yog/community/*`): Major new module implementing 10 community detection algorithms (~3,400 lines). Community detection identifies densely connected groups of nodes in graphs - essential for social network analysis, biological networks, recommendation systems, and infrastructure analysis.

  **Core Module** (`yog/community`):
  - `Communities` type: Maps nodes to community IDs with count
  - `Dendrogram` type: Hierarchical community structure with merge history
  - Utilities: `communities_to_dict/1`, `largest_community/1`, `community_sizes/1`, `merge_communities/3`

  **Algorithms** (in `yog/community/`):
  | Algorithm | Module | Best For | Complexity |
  |-----------|--------|----------|------------|
  | **Louvain** | `louvain` | Large graphs, speed/quality balance | O(E log V) |
  | **Leiden** | `leiden` | Quality guarantee, well-connected | O(E log V) |
  | **Label Propagation** | `label_propagation` | Very large graphs, speed | O(E × iters) |
  | **Girvan-Newman** | `girvan_newman` | Hierarchical structure | O(E² × V) |
  | **Walktrap** | `walktrap` | Random walk-based communities | O(V² log V) |
  | **Infomap** | `infomap` | Flow-based, information-theoretic | O(E × iters) |
  | **Clique Percolation** | `clique_percolation` | Overlapping communities | O(3^(V/3)) |
  | **Local Community** | `local_community` | Massive graphs, seed expansion | O(S × E_S) |
  | **Fluid Communities** | `fluid_communities`| Exact `k` partitions | O(E × iters) |
  | **Random Walk** | `random_walk` | Primitives for custom algorithms | O(steps × k) |

  **Metrics Module** (`yog/community/metrics`):
  - `modularity/2` - Newman's modularity Q for evaluating partition quality
  - `count_triangles/1`, `triangles_per_node/1` - Triangle counting
  - `clustering_coefficient/2`, `average_clustering_coefficient/1` - Clustering metrics
  - `density/1`, `community_density/2`, `average_community_density/2` - Density metrics

  **Quick Start**:
  ```gleam
  import yog/community/louvain
  
  let communities = louvain.detect(graph)
  io.debug(communities.num_communities)  // => 4
  
  // Hierarchical detection
  let dendrogram = louvain.detect_hierarchical(graph)
  ```

  **Algorithm Selection Guide**:
  - **Speed Priority**: Label Propagation > Fluid Communities > Louvain > Leiden
  - **Quality Priority**: Leiden > Louvain > Infomap > Walktrap
  - **Specific size (k)**: Fluid Communities
  - **Massive/Infinite graphs**: Local Community
  - **Hierarchical Structure**: Girvan-Newman, Louvain, Leiden, Walktrap
  - **Overlapping Communities**: Clique Percolation (nodes can belong to multiple)
  - **Flow-Based**: Infomap (uses PageRank and Map Equation)

### Changed

- **Project Structure Reorganization**:
  - Moved `examples/` → `test/examples/` for simpler execution without symlink hacks
  - Moved `bench/` → `test/bench/` to consolidate test-related code

## 4.0.0 - 2026-03-14

### Breaking Changes

- **Undirected Edge Removal Symmetry**: Calling `model.remove_edge(graph, src, dst)` on an `Undirected` graph now automatically removes both the `src -> dst` **and** the `dst -> src` references in a single call, rather than previously requiring two distinct calls.

### Added

- **Testing**: Exhaustive property-based testing using `qcheck` across core algorithms (pathfinding, connectivity, MST) and properties.

- **Documentation**: Added comprehensive module-level docs to 22 modules including algorithm references with Wikipedia links, complexity tables, and usage examples. Modules: `connectivity`, `disjoint_set`, `model`, `mst`, `transform`, `traversal`, `io/*`, `flow/*`, `pathfinding/*`, `property/*`, `dag`, `centrality`.

- **F# Comparison**: Added `GLEAM_FSHARP_COMPARISON.md` documenting feature parity, API differences, and migration guidance between the Gleam and F# implementations of Yog.

### Changed

- **Project Structure Reorganization**:
  - Moved `examples/` → `test/examples/` for simpler execution without symlink hacks
  - Moved `bench/` → `test/bench/` to consolidate test-related code

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
  - `yog/clique` → `yog/property/clique`
  - `yog/bipartite` → `yog/property/bipartite`
  - `yog/eulerian` → `yog/property/eulerian`
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
- `is_acyclic`/`is_cyclic` re-exported from `yog/property`

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
- Graph Generators (`yog/generator`): Complete, cycle, path, star, wheel, bipartite, random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz)
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
