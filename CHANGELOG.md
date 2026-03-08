# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2026-03-07 - 3.0.0

### Breaking Changes

- **Global Parameter Reordering**: The `graph` argument has been moved to the final position (adhering to the "Data-Last" rule) in all traversal functions to improve pipeline ergonomics. Affected functions include `walk`, `walk_until`, and `fold_walk` in both `yog` and `yog/traversal`.
- **Module Namespace Consolidation**: Several standalone modules have been moved into category-based groups to simplify the API:
  - `yog/components` functions are now in `yog/connectivity`.
  - `yog/min_cut` and `yog/max_flow` are now within the `yog/flow` namespace.
  - `yog/topological_sort` is now integrated into `yog/traversal`.
  - `yog/clique`, `yog/bipartite`, and `yog/eulerian` are now within the `yog/properties` namespace.
- **Top-level Promotion**: Internal submodules have been promoted to top-level category modules, and the former facade modules (e.g., `yog/pathfinding`, `yog/properties`) have been removed. You must now import from the specific algorithm modules:
  - `import yog/pathfinding/dijkstra` instead of `import yog/pathfinding`
  - `import yog/properties/eulerian` instead of `import yog/properties`
  - etc.
- **Rendering & IO**: The `yog/render` module has been completely split into format-specific modules under `yog/io/`: `mermaid` (currently implemented), `dot` (stubbed for v3.1), and `json` (stubbed for v3.1).
- **Type Definitions**: Control flow for traversals (e.g., in `fold_walk` and `implicit_fold`) now exclusively uses the explicit `WalkControl` enum variants (`Continue`, `Stop`, `Halt`) for finer control over the traversal.

### Added

- **Frugal DAG Suite** (`yog/dag`): A strictly typed wrapper `Dag(n, e)` for modeling Directed Acyclic Graphs with fast property validation via `dag.from_graph`.
  - Exposes specialized DAG optimization algorithms in `yog/dag`:
    - **DAG Builders/Mutators:** Safely construct and alter DAGs post-validation using `add_node`, `remove_node`, `remove_edge`, and a strictly cycle-checked `add_edge` returning `Result(Dag, DagError)`.
    - `topological_sort`: Safe topological sort that bypasses general cycle checks.
    - `longest_path`: $O(V+E)$ Dynamic Programming approach for Critical Path tracking in scheduling networks.
    - `transitive_closure` and `transitive_reduction`: Reachability maps and structural deduplication with custom edge weight merging.
    - `lowest_common_ancestors`: Efficient common dependency intersections for DAG hierarchies.
    - `count_reachability`: Computes total ancestors or descendants for all nodes.
- **Network Simplex solver** (`yog/flow/network_simplex`): A high-performance solver for Minimum Cost Flow (MCF) problems using the simplex method on spanning trees.
  - Automatically handles multi-source and multi-sink supply/demand networks.
  - Efficient spanning tree representation for $O(1)$ updates and pivot operations.
  - Guarantees convergence via **Bland's Rule** for edge selection.
- **Property Exports**: `is_acyclic` and `is_cyclic` functions are now re-exported from `yog/properties`, making graph trait querying more accessible without importing the `traversal` module.

## 2026-03-07 - 2.2.1

### Added

- **Top-level ergonomics**: Re-exported common functions and types from `yog/traversal` and `yog/transform` in the main `yog` module.
  - Traversal: `walk`, `walk_until`, `fold_walk`, `Order`, `BreadthFirst`, `DepthFirst`, etc.
  - Transform: `transpose`, `map_nodes`, `map_edges`, `filter_nodes`, `filter_edges`, `subgraph`, `merge`, `contract`, `to_directed`, `to_undirected`, `complement`.

### Fixed

- **`builder/grid` predicates**: Fixed `avoiding`, `walkable`, and `including` to properly filter both the source and destination cells. Previously, they only checked the destination, which allowed invalid cells (like walls) to have outgoing edges.

### Performance

- **`mst.kruskal()`**: Optimized disjoint set initialization by removing redundant node ID extraction and pre-population. Since `disjoint_set.find` automatically adds missing nodes, starting with an empty set is sufficient and prevents unnecessary upfront allocations.

### Changed

- **Benchmark structure**: Moved internal benchmarks from `src/internal/bench` to `src/yog/internal/bench` to comply with Gleam's `internal` visibility rules (internal modules are only restricted when nested within their parent module's directory).
- **Documentation**: Updated all benchmark docstrings and guides to reflect the new internal path structure.

## 2026-03-04 - 2.2.0

### Fixed

- **`mst.prim()`**: Fixed frontier trap where undirected edges with `from > to_id` were dropped during neighbor expansion. Prim's needs to see all outgoing edges to grow the MST correctly; the deduplication filter was only appropriate for Kruskal's global edge processing. Created a separate `get_all_edges_from_node` helper for Prim's that returns all neighbors regardless of ID order.
- **`min_cut.global_min_cut()`**: Fixed incorrect cut weight calculation in Stoer-Wagner's Maximum Adjacency Search. The cut weight was being recalculated by summing all edges of node `t`, which incorrectly included edges outside the current MAS phase. Now uses the accumulated weight from the MAS weights dictionary, which is the mathematically correct cut-of-the-phase value.
- **`traversal` DFS ordering**: Fixed implicit DFS stack order in `do_fold_walk_dfs`, `do_implicit_dfs`, and `do_implicit_dfs_by`. The combination of `list.reverse` + `list.fold` with prepend inadvertently restored the original order, causing the last successor to be explored first. Replaced with `list.fold_right` to ensure the first successor ends up on top of the LIFO stack, matching standard DFS behavior.

### Added

- **`builder/grid.from_2d_list_with_topology()`**: Create grids with custom movement patterns using `#(row_delta, col_delta)` offsets. `from_2d_list` now delegates to this with `rook()` topology.
- **Chess-themed topology presets**: `rook()` (4-way cardinal), `bishop()` (4 diagonals), `queen()` (8-way), `knight()` (L-shaped jumps). Pass to `from_2d_list_with_topology` for instant custom movement graphs.
- **Movement predicate helpers**: `avoiding(wall)` blocks a value, `walkable(tile)` whitelists a value, `always()` allows all movement. Composable with both `from_2d_list` and `from_2d_list_with_topology`.
- **`model.add_edge_ensured()`**: Like `add_edge`, but auto-creates missing endpoint nodes with a caller-supplied `default` value. Prevents "ghost nodes" caused by adding edges to non-existent nodes.
- **`transform.filter_edges()`**: Filters edges by a `(src, dst, weight)` predicate while preserving all nodes. Useful for weight-based pruning, self-loop removal, and graph sparsification.
- **`transform.complement()`**: Creates the graph complement — connects all non-adjacent node pairs, removes existing edges. Useful for independent set analysis and graph coloring.
- **`transform.to_directed()`**: Converts undirected to directed (O(1) — just a flag change since yog stores both directions internally).
- **`transform.to_undirected()`**: Converts directed to undirected by mirroring edges, with a `resolve` function for conflicting weights.

### Performance

- **Bron-Kerbosch (`yog/clique`)**: Precomputed adjacency sets into a `Dict(NodeId, Set(NodeId))` built once per entry point, eliminating repeated `neighbors → list.map → set.from_list` allocations on every recursive iteration. Additionally, replaced the naive `list.first` pivot selection with greedy pivoting that maximizes |P ∩ N(u)|, aggressively pruning the search tree.
- **Directed `neighbors()` (`yog/model`)**: Replaced O(N²) deduplication of incoming vs outgoing edges (using `list.any` inside `list.fold`) with O(N log N) approach that converts outgoing IDs to a `Set` first, then uses `set.contains` for membership checks.
- **`filter_nodes()` (`yog/transform`)**: Replaced O(E×V) edge pruning (using `list.contains` per edge) with O(E log V) approach by converting `kept_ids` to a `Set`, matching the pattern already used in `subgraph`.
- **Hierholzer's algorithm (`yog/eulerian`)**: Replaced flat `List(#(NodeId, NodeId))` edge tracking with `Dict(NodeId, List(NodeId))` adjacency. Edge lookup/removal is now O(1) amortized (pop from neighbor list head) instead of O(E) linear scan per step, bringing Hierholzer's from O(E²) to the expected O(E).

## 2026-03-01 - 2.1.0

### Added

- **`pathfinding.implicit_dijkstra()`**: Find shortest paths in implicit graphs using Dijkstra's algorithm without materializing a `Graph` structure. Like `implicit_fold` but for weighted graphs.
  - Provide `successors_with_cost` function that generates weighted successors on demand
  - Returns shortest distance to any goal state, or `None` if unreachable
  - Ideal for state-space search, puzzles, planning problems, or graphs too large to build upfront
  - Time complexity: O((V + E) log V) where V is visited states and E is explored transitions
  - Works with any cost type (Int, Float, custom) that supports addition and comparison
  - Use cases: Puzzle solving (optimal solutions), game AI (pathfinding with complex state), automated planning, AoC problems (2019 Day 18, 2021 Day 23, 2022 Day 16)
  - Example: Find shortest path in state-space where each state is `#(x, y, collected_keys)` with weighted transitions
- **`pathfinding.implicit_dijkstra_by()`**: Like `implicit_dijkstra`, but deduplicates visited states by a custom key function. Essential when state carries extra data beyond identity.
  - Use `visited_by` parameter to extract deduplication key: states with same key are considered visited, but full state is passed to successor function
  - Internally maintains `Dict(key, cost)` instead of `Dict(state, cost)` for visited tracking
  - Enables "best-cost wins" semantics: when multiple paths reach same logical position with different state, cheapest one is kept
  - Time complexity: O((V + E) log V) where V and E measured in unique keys (not unique states)
  - Use cases: AoC 2019 Day 18 (`#(at_key, collected_mask)` → dedupe by both); puzzle solving (`#(board, moves)` → dedupe by `board`); pathfinding with metadata (`#(pos, history)` → dedupe by `pos`)
  - Similar to SQL's `DISTINCT ON(key)` or Python's `key=` parameter in built-in functions
  - Example: Key collection maze where states are `#(position, collected_keys)` — dedupe by full state for correctness
- **`pathfinding.implicit_a_star()`**: A* search for implicit graphs with heuristic guidance. Like `implicit_dijkstra` but uses heuristics to guide search toward goal.
  - Provide `heuristic` function that estimates remaining cost to goal (must be admissible: never overestimate)
  - Returns shortest distance to goal state, or `None` if unreachable
  - More efficient than Dijkstra when good heuristics available (e.g., Manhattan/Euclidean distance for grids)
  - Time complexity: O((V + E) log V) in worst case, but typically much faster with good heuristics
  - Use cases: Grid pathfinding (Manhattan distance), game AI (goal-directed search), puzzle solving with domain knowledge
  - Example: Navigate grid from start to goal using Manhattan distance heuristic
- **`pathfinding.implicit_a_star_by()`**: Like `implicit_a_star`, but deduplicates visited states by a custom key function.
  - Combines A* heuristic search with custom state deduplication
  - Use `visited_by` parameter to extract deduplication key while preserving full state for heuristic and successor functions
  - Enables "best-cost wins" semantics with heuristic guidance
  - Time complexity: O((V + E) log V) where V and E measured in unique keys
  - Use cases: Grid search with metadata (`#(pos, history)` → dedupe by `pos`); state-space search with heuristics
  - Example: Pathfinding where state includes position + collected items, dedupe by position only, use Manhattan distance heuristic
- **`pathfinding.implicit_bellman_ford()`**: Bellman-Ford algorithm for implicit graphs with negative weight support. Uses SPFA (Shortest Path Faster Algorithm) variant.
  - Handles graphs with negative edge weights (unlike Dijkstra/A*)
  - Detects negative cycles reachable from start
  - Returns `FoundGoal(cost)`, `DetectedNegativeCycle`, or `NoGoal`
  - Time complexity: O(V × E) worst case, often much faster in practice
  - Use cases: Graphs with negative weights, arbitrage detection, time-dependent costs, constraint satisfaction
  - Example: Find shortest path in graph where some edges reduce total cost (discounts, shortcuts)
- **`pathfinding.implicit_bellman_ford_by()`**: Like `implicit_bellman_ford`, but deduplicates visited states by a custom key function.
  - Combines negative weight support with custom state deduplication
  - Use `visited_by` parameter for flexible state management
  - Detects negative cycles considering deduplication keys
  - Time complexity: O(V × E) where V and E measured in unique keys
  - Use cases: State-space search with negative costs, complex state with negative weights
  - Example: Graph where states carry metadata but deduplication by logical position, with negative edge weights
- **`traversal.implicit_fold()`**: Traverse implicit graphs using BFS or DFS without materializing a `Graph` structure. Instead of requiring a pre-built graph, you provide a `successors_of` function that computes neighbors on demand.
  - Ideal for infinite grids, state-space search, or graphs too large/expensive to build upfront
  - Works with any node ID type (integers, strings, tuples, custom types)
  - Provides same metadata (depth, parent) and control flow (`Continue`/`Stop`/`Halt`) as `fold_walk`
  - Time complexity: O(V + E) for both BFS and DFS where V is visited nodes and E is explored edges
  - Use cases: Maze pathfinding on implicit grids, state-space exploration, puzzle solving (e.g., AoC 2016 Day 13), shortest path in procedurally-generated graphs
  - Example: BFS shortest path in an implicit maze by providing a function that computes open neighbors
- **`traversal.implicit_fold_by()`**: Like `implicit_fold`, but deduplicates visited nodes by a custom key function. Essential when node type carries extra state beyond what defines identity.
  - Use `visited_by` parameter to extract deduplication key: nodes with same key are considered identical, but full node (with all state) is passed to folder
  - Internally maintains `Set(key)` instead of `Set(node)` for visited tracking
  - Enables "first-visit wins" semantics: when multiple paths reach same logical position with different state, first one is kept
  - Time complexity: O(V + E) where V and E measured in unique keys (not unique nodes)
  - Use cases: State-space search with `#(position, mask)` → dedupe by `position`; puzzle solving with `#(board, moves)` → dedupe by `board`; pathfinding with `#(pos, fuel)` → dedupe by `pos`
  - Similar to SQL's `DISTINCT ON(key)` or Python's `key=` parameter in built-in functions
  - Example: Maze with nodes carrying position + step count, but only visit each position once
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

[1.3.0]: https://github.com/code-shoily/yog/compare/v1.2.4...v1.3.0
[1.2.4]: https://github.com/code-shoily/yog/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/code-shoily/yog/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/code-shoily/yog/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/code-shoily/yog/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/code-shoily/yog/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/code-shoily/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/code-shoily/yog/releases/tag/v1.0.0
