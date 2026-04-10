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

- **High-Performance Set Operations** (`yog/operation`):
  - Re-implemented `union`, `intersection`, `difference`, and `symmetric_difference` as declarative pipelines for $O(V+E)$ complexity.
  - Optimized `cartesian_product` and `power` (k-th graph power) implementations.

- **Core Model Enhancements** (`yog/model`):
  - `add_edge_with/5` - Adds an edge while ensuring endpoints exist with a generator function.
  - Migrated core creation functions (`from_edges`, `from_unweighted_edges`, `from_adjacency_list`) to the model module.

### Changed

- **Promoted Multigraph and DAG Modules**: The `yog/multi/*` and `yog/dag/*` modules are now mature, stable, and fully documented.
- **Consolidated Transform Operations** (`yog/transform`): Migrated reachability-based transformations (`transitive_closure`, `transitive_reduction`) from DAG-specific algorithms to the core transform module for use on all graph types.
- **Refactored DAG Algorithms**: Simplified internal path reconstruction and consolidated redundant helper functions.

### Fixed

- **Edge Pruning Consistency** (`yog/transform`): Fixed a bug in `filter_edges` where inbound edges in directed graphs were not being correctly pruned.
- **Enhanced DAG Testing**: Established a robust property-based testing suite using `qcheck` to ensure correctness across topological sorting and reachability analysis.

## 5.2.1 - 2026-04-08

### Removed

- **Cyclicity from Traversal** (`yog/traversal`): Removed `is_cyclic/1` and `is_acyclic/1` from the traversal module. Use `yog/property/cyclicity` instead, which is now the sole source of truth for graph cyclicity analysis.

## 5.2.0 - 2026-04-08

### Added

- **Enhanced Internal Utilities** (`yog/internal/utils`): Unified utility functions for vector analysis and randomization:
  - `norm_diff/3` - Calculates vector distances between node score maps supporting L1, L2, and Max norms.
  - `fisher_yates/2` - High-performance list shuffling using platform-specific FFI (native tuples in Erlang, arrays in JS) for $O(n)$ complexity.

- **Polished ASCII Rendering** (`yog/render/ascii`): Major improvements to terminal-based grid and maze visualization:
  - `grid_to_string_unicode/1` - Renders grids using high-quality Unicode box-drawing characters (┌───┬───┐) for a professional terminal look.
  - **Cell Rendering (Occupants)** - New support for displaying markers or data inside cells (e.g., "S" for start, "G" for goal) via `grid_to_string_with_occupants` and its Unicode variant.
  - **Toroidal Support** - Added Unicode-enabled rendering for toroidal grids with wrap-around indicators.

## 5.1.1 - 2026-03-23

### Changed

- **Internal Priority Queue Implementation** (`yog/internal/priority_queue`, `yog/internal/pairing_heap`): Removed dependency on `gleamy_structures` by implementing our own pairing heap and priority queue with the same contract. This reduces external dependencies while maintaining identical functionality.

### Removed

- **JSON Rendering Module** (`yog/render/json`): Removed in favor of `yog_io` package for JSON serialization.
- **gleamy_structures dependency**: No longer required, replaced by internal implementations.
- **Deprecated DAG Modules** (`yog/dag/algorithms`, `yog/dag/models`): Removed deprecated plural module names. Use the singular versions (`yog/dag/algorithm`, `yog/dag/model`) instead. These were deprecated in v5.1.0.

## 5.1.0 - 2026-03-22

### Added

- **Bidirectional Search** (`yog/pathfinding/bidirectional`): Meet-in-the-middle pathfinding algorithms for dramatic speedup:
  - `shortest_path_unweighted/3` - Bidirectional BFS for unweighted graphs with O(b^(d/2)) complexity (up to 500× faster than standard BFS!)
  - `shortest_path/6` - Bidirectional Dijkstra for weighted graphs (approximately 2× faster than standard Dijkstra)
  - Works with both directed and undirected graphs, leveraging yog's efficient `in_edges` structure for backward search
  - Proper termination conditions ensuring optimality
  - Comprehensive path reconstruction from meeting point
  - Convenience wrappers: `shortest_path_int/3` and `shortest_path_float/3`
  - **Performance Example**: With branching factor 10 and depth 6: standard BFS explores 1,000,000 nodes vs bidirectional BFS explores only 2,000 nodes

- **Graph Operations Module** (`yog/operation`): New module implementing set-theoretic graph operations following NetworkX's "Graph as a Set" philosophy:
  - **Set-Theoretic Operations**: `union/2`, `intersection/2`, `difference/2`, `symmetric_difference/2` for combining and comparing graphs
  - **Composition & Joins**: `disjoint_union/2` (safe combination with auto re-indexing), `cartesian_product/2` (for grids and hypercubes), `compose/2` (merge overlapping graphs)
  - **Graph Powers**: `power/2` creates the k-th power of a graph (connects nodes within distance k), useful for reachability analysis
  - **Structural Comparison**: `is_subgraph/2` for subset validation, `is_isomorphic/2` for checking structural identity (with quick checks for node/edge counts and degree sequences)
  - All operations preserve graph structure and handle edge data appropriately
  - See module documentation for algorithm complexities and use cases

- **Connected Components Algorithms** (`yog/connectivity`): New functions for finding connected components in undirected and weakly connected components in directed graphs:
  - `connected_components/1` - Find connected components in undirected graphs using DFS
  - `weakly_connected_components/1` - Find weakly connected components in directed graphs (treating edges as undirected)
  - Both algorithms run in O(V + E) time complexity
  - See module documentation for comparison with existing SCC algorithms

- **Enhanced DOT Rendering** (`yog/render/dot`): Major improvements to Graphviz export functionality:
  - **Generic Data Types**: `DotOptions` is now generic over node data `n` and edge data `e`, allowing it to work with any graph types without manual conversion
    - Use `default_dot_options()` for `String` edge data (backward compatible)
    - Use `default_dot_options_with_edge_formatter(fn(e) -> String)` for custom edge types (e.g., `Int`, `Float`, custom records)
    - Use `default_dot_options_with()` for full control over both node and edge labeling
  - **Per-Element Styling**: New callback functions for fine-grained visual control:
    - `node_attributes: fn(NodeId, n) -> List(#(String, String))` - Set custom DOT attributes per node (e.g., `[#("fillcolor", "green"), #("shape", "diamond")]`)
    - `edge_attributes: fn(NodeId, NodeId, e) -> List(#(String, String))` - Set custom DOT attributes per edge (e.g., `[#("color", "red"), #("penwidth", "2")]`)
    - Custom attributes override highlighting and default styles
  - **Subgraphs and Clusters**: New `Subgraph` type for visual node grouping:
    - Create visual clusters with `Subgraph(name: "cluster_0", label: Some("Group A"), node_ids: [1, 2, 3], ...)`
    - Supports all Graphviz subgraph attributes: `style`, `fillcolor`, `color`
    - Use `cluster_` prefix in name for bounded rectangle visualization
  - Improved attribute formatting with consistent `key="value"` syntax
  - **Example**:

    ```gleam
    let options = DotOptions(
      ..dot.default_dot_options_with_edge_formatter(int.to_string),
      node_attributes: fn(id, _) {
        case id == start_node { True -> [#("fillcolor", "green")] False -> [] }
      },
      subgraphs: Some([Subgraph(name: "cluster_a", label: Some("Module A"), node_ids: [1, 2])]),
    )
    let dot_string = dot.to_dot(my_graph, options)
    ```

### Documentation

- **Experimental Module Notices**: Added experimental status warnings to `yog/multi/*` (multigraphs) and `yog/dag/*` (DAG-specific operations) modules:
  - These modules are functional with minimal, working implementations
  - May not be fully optimized for performance
  - Additional features and performance enhancements planned
  - API may be subject to change in future versions
  - Notice added to all module files and documented in README under "⚠️ Experimental Features" section

### Changed

- **DAG Module Naming Convention**: Renamed plural files to singular for consistency with Gleam conventions:
  - `yog/dag/algorithms` → `yog/dag/algorithm`
  - `yog/dag/models` → `yog/dag/model`
  - Follows the same pluralization cleanup done in v5.0.0 for `property/` and `generator/` modules

- **Consistent Parameter Labels**: Added descriptive labels to all semiring and algorithm parameters across pathfinding, centrality, health, and community detection modules for improved API consistency and self-documentation:
  - **Pathfinding**: `bellman_ford`, `floyd_warshall`, `a_star` (including helper functions like `relaxation_passes`, `has_negative_cycle`)
  - **Centrality**: `closeness`, `harmonic_centrality`, `betweenness` and all convenience wrappers
  - **Health**: `diameter`, `radius`, `eccentricity`, `average_path_length`
  - **Community Detection**: `girvan_newman` (including `edge_betweenness` and helper functions)
  - All functions now use consistent labels: `with_zero`, `with_add`, `with_compare`, `with_to_float`, `with_heuristic`, `with`
  - **Backward compatible**: Both labeled and unlabeled calls are supported (e.g., `dijkstra.shortest_path(graph, 1, 5, 0, int.add, int.compare)` and `dijkstra.shortest_path(in: graph, from: 1, to: 5, with_zero: 0, with_add: int.add, with_compare: int.compare)` both work)
  - Follows the pattern established by Dijkstra's algorithm for a more uniform and intuitive API

### Fixed

- **Clique Detection Empty Graph Bug** (`yog/property/clique`): Fixed `all_maximal_cliques` to return an empty list `[]` for empty graphs instead of a list containing one empty set `[set.new()]`:
  - **Problem**: `all_maximal_cliques` on an empty graph would return `[set.new()]`, inconsistent with `max_clique` (returns empty set) and `k_cliques` (returns empty list)
  - **Root Cause**: The Bron-Kerbosch algorithm would report the empty set as a maximal clique when all candidate sets (R, P, X) were empty
  - **Solution**: Added check to only report non-empty cliques as maximal cliques in `bron_kerbosch_all`
  - **Impact**: Empty graphs now correctly return no maximal cliques, consistent with other clique functions
  - **Test Added**: `all_maximal_cliques_empty_graph_test` validates the fix

- **Eigenvector Centrality Oscillation Bug** (`yog/centrality`): Fixed critical bug where eigenvector centrality would oscillate and never converge for symmetric graphs:
  - **Problem**: Star graphs and other symmetric structures caused the power iteration algorithm to oscillate between two states indefinitely (e.g., [0.816, 0.408, 0.408] ↔ [0.577, 0.577, 0.577])
  - **Root Cause**: Uniform initialization [1/√n, 1/√n, ...] contained equal components of eigenspaces with eigenvalues of equal magnitude but opposite signs (e.g., +√2 and -√2), causing 2-cycle oscillation
  - **Solution**:
    - Added small node-ID-based perturbation to initial vector to break symmetry: `1.0 + (id / 1000.0)`
    - Implemented 2-cycle oscillation detection by tracking state from 2 iterations ago
    - When oscillation is detected, returns the normalized average of the two oscillating states, which approximates the true principal eigenvector
  - **Impact**: 2-leaf star graphs now correctly return center ≈ 0.707, leaves ≈ 0.5 (ratio √2 ≈ 1.414) instead of all nodes ≈ 0.577
  - **Tests Added**:
    - `eigenvector_2leaf_star_exact_test` - Validates exact eigenvector values with mathematical precision
    - `eigenvector_triangle_exact_test` - Tests complete triangle (K3) for equal centrality
    - `eigenvector_linear_chain_test` - Validates 5-node chain with symmetry properties
    - `eigenvector_barbell_test` - Tests two triangles connected by bridge, validates bridge nodes have higher centrality
  - All existing tests continue to pass with improved numerical accuracy

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
- **Rendering**: `yog/render` split into `yog/io/*` (mermaid, dot, ascii)
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
- Visualization (`yog/render`): Mermaid, DOT, ASCII

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
