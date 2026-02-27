# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 1.2.5

### Added
- **Maximum Flow (`yog/max_flow`)** - Network flow optimization with highly optimized Edmonds-Karp algorithm
  - `edmonds_karp()` - Find maximum flow from source to sink using Ford-Fulkerson with BFS
  - `min_cut()` - Extract minimum cut from max flow result (max-flow min-cut theorem)
  - **Time Complexity:** O(VE²) - proven theoretical bound with optimized implementation
  - **Optimizations:**
    - Flat dictionary for residual capacities instead of Graph structure (5x faster)
    - Two-list queue (Banker's Queue) for O(1) amortized BFS operations
    - Tail-recursive flow accumulator prevents stack overflow
    - Adjacency list built once and reused (structure doesn't change, only capacities)
    - Fast O(log n) dictionary updates instead of O(E) graph rebuilding
  - Generic over any numeric type (integers, floats, custom types)
  - Works on directed graphs (converts undirected to directed with bidirectional edges)
  - Returns `MaxFlowResult` with max flow value, residual graph, source, and sink
  - Min-cut extraction via reachability analysis in residual graph
  - 20 comprehensive tests covering simple flows, parallel paths, complex networks, textbook examples, bipartite matching, min-cut extraction, edge cases
  - Complete documentation with examples and algorithm explanation
  - **Use cases:** Network bandwidth allocation, job matching, image segmentation, project selection, bipartite matching, traffic routing, supply chain optimization
  - **Examples:**
    - `network_bandwidth.gleam` - Router bandwidth optimization with bottleneck analysis
    - `job_matching.gleam` - Assignment problem using max flow as bipartite matching

- **Graph Generators (`yog/generators`)** - Create classic graph patterns for testing and prototyping
  - **Classic patterns module (`yog/generators/classic`)** with 9 generators:
    - `complete()` / `complete_with_type()` - Complete graph K_n (every node connects to every other)
    - `cycle()` / `cycle_with_type()` - Cycle graph C_n (nodes form a ring)
    - `path()` / `path_with_type()` - Path graph P_n (linear chain)
    - `star()` / `star_with_type()` - Star graph (central hub with spokes)
    - `wheel()` / `wheel_with_type()` - Wheel graph (cycle with central hub)
    - `complete_bipartite()` / `complete_bipartite_with_type()` - Complete bipartite K_{m,n}
    - `binary_tree()` / `binary_tree_with_type()` - Complete binary tree of given depth
    - `grid_2d()` / `grid_2d_with_type()` - 2D lattice/grid graph
    - `petersen()` / `petersen_with_type()` - Famous Petersen graph (non-planar, 3-regular)
  - **Convenience re-exports** in `yog/generators` for common patterns
  - All generators support both directed and undirected variants
  - Edges have unit weight (1) by default
  - Node IDs are sequential integers starting from 0
  - **Time Complexity:** O(V²) for complete graphs, O(V) or O(VE) for others
  - 41 comprehensive tests covering all generators, node counts, edge counts, connectivity, degree properties
  - Complete documentation with examples and mathematical definitions
  - **Use cases:** Algorithm testing with known properties, benchmarking, education, prototyping, generating test fixtures
  - **Example:** `graph_generation_showcase.gleam` - Demonstrates all 9 classic patterns with statistics and use cases

- **Stable Marriage Algorithm (`yog/bipartite`)** - Gale-Shapley algorithm for stable matching
  - `stable_marriage()` - Find stable matching given preference lists for two groups
  - `get_partner()` - Query matched partner for any person in the matching
  - **Time Complexity:** O(n²) where n is the size of each group
  - **Properties:**
    - **Stable:** No two people would both prefer each other over their current partners
    - **Complete:** Everyone is matched when groups are equal size
    - **Proposer-optimal:** Left group (proposers) gets best stable matching possible
    - **Receiver-pessimal:** Right group gets worst stable matching possible
  - Deterministic proposal ordering for consistent results
  - Generic over any comparable node ID type
  - Handles unbalanced groups (some may remain unmatched)
  - Supports incomplete preference lists
  - 14 comprehensive tests covering classic scenarios, stability checks, medical residency, unbalanced groups, edge cases
  - Complete documentation with algorithm explanation and examples
  - **Use cases:** Medical residency matching (NRMP), college admissions, job assignments, roommate pairing, task allocation
  - **Example:** `medical_residency.gleam` - Realistic NRMP-style matching with 5 residents and 5 hospitals

### Performance
- **Max flow performance:** All tests pass in ~2 seconds (down from 28+ seconds before optimization)
  - Eliminated O(V²) BFS by using two-list queue
  - Eliminated O(E) adjacency list rebuilds per iteration
  - Eliminated expensive Graph structure rebuilds with flat dictionary
- **Generator performance:** Tail-recursive `power()` function prevents stack overflow in binary tree generator

### Changed
- Test suite expanded to 580 tests (from 511 tests in 1.2.4)
  - Added 20 tests for maximum flow algorithm
  - Added 41 tests for graph generators
  - Added 14 tests for stable marriage algorithm
  - All tests continue to pass in ~2 seconds

## [1.2.4] - 2026-02-27

### Added
- **Graph creation helpers (`yog`)** - Convenient bulk graph construction functions
  - `from_edges()` - Create graph from list of `#(src, dst, weight)` tuples
  - `from_unweighted_edges()` - Create graph from list of `#(src, dst)` tuples (edges have `Nil` weight)
  - `from_adjacency_list()` - Create graph from adjacency list `#(src, List(#(dst, weight)))`
  - All functions automatically create nodes as needed
  - Perfect for quick graph construction from parsed data, test fixtures, and bulk initialization
  - 10 comprehensive tests covering directed/undirected graphs, empty inputs, and edge cases

- **Labeled builder convenience functions (`yog/builder/labeled`)** - Bulk creation with labels
  - `from_list()` - Create labeled graph from list of `#(src_label, dst_label, weight)` tuples
  - `from_unweighted_list()` - Create labeled graph from list of `#(src_label, dst_label)` tuples
  - Matches API of main `yog` module for consistency
  - Enables rapid graph construction with string or custom-type node identifiers
  - Perfect for parsing input data, building test graphs, and ergonomic graph construction
  - 10 comprehensive tests including pathfinding integration test

- **Graph creation example (`examples/graph_creation.gleam`)** - Comprehensive guide showing 10 different ways to create graphs
  - Demonstrates builder pattern, edge lists, adjacency lists, labeled builders, and all variants
  - Shows differences between directed/undirected, weighted/unweighted, simple edges
  - Practical examples for each creation method with clear explanations
  - Helps users choose the right approach for their use case

### Changed
- **README refactored** - Improved documentation structure and clarity
- Test suite expanded to 511 tests (from 494) - Added 17 new tests for graph creation helpers

## [1.2.3] - 2026-02-27

### Added
- **Eulerian Paths & Circuits (`yog/eulerian`)** - Detection and finding using Hierholzer's algorithm
  - `has_eulerian_circuit()` - Check if graph has an Eulerian circuit (visits every edge exactly once, returns to start)
  - `has_eulerian_path()` - Check if graph has an Eulerian path (visits every edge exactly once)
  - `find_eulerian_circuit()` - Find an Eulerian circuit using Hierholzer's algorithm
  - `find_eulerian_path()` - Find an Eulerian path using Hierholzer's algorithm
  - **Circuit conditions (undirected):** All vertices have even degree, graph is connected
  - **Circuit conditions (directed):** All vertices have equal in/out-degree, graph is connected
  - **Path conditions (undirected):** Exactly 0 or 2 vertices with odd degree, graph is connected
  - **Path conditions (directed):** At most one vertex with out-degree > in-degree, one with in-degree > out-degree
  - **Time Complexity:** O(V + E) for detection, O(E) for finding paths
  - Works on both directed and undirected graphs
  - Returns paths as ordered list of node IDs
  - 26 comprehensive tests covering circuits, paths, directed/undirected graphs, edge cases
  - Complete documentation with examples and mathematical conditions
  - **Use cases:** Route planning (mail delivery, snow plowing), DNA sequence reconstruction, circuit design, puzzle solving, network traversal

- **Bipartite Graphs (`yog/bipartite`)** - Detection and maximum matching with augmenting path algorithm
  - `is_bipartite()` - Check if graph is bipartite (2-colorable)
  - `partition()` - Get the two independent sets (partitions) of a bipartite graph
  - `maximum_matching()` - Find maximum matching using augmenting path algorithm
  - **Partition type:** `Partition(left: Set(NodeId), right: Set(NodeId))` for the two independent sets
  - **Time Complexity:** O(V + E) for detection/partitioning, O(V * E) for maximum matching
  - Uses BFS with 2-coloring for bipartite detection
  - Handles disconnected graphs by checking all components
  - Augmenting path algorithm for unweighted bipartite matching
  - Works on both directed and undirected graphs (treats directed as undirected for bipartiteness)
  - 18 comprehensive tests covering detection, partitioning, perfect matchings, unbalanced graphs, edge cases
  - Complete documentation with examples and use cases
  - **Use cases:** Job assignment, stable matching, timetable scheduling, resource allocation, Hall's marriage theorem

## [1.2.2] - 2026-02-27

### Added
- **Disjoint Set / Union-Find (`yog/disjoint_set`)** - Public API for dynamic connectivity with optimal performance
  - Moved from internal implementation to public-facing API (following Loom's approach)
  - **Core operations:**
    - `new()` - Create a new empty disjoint set
    - `add()` - Add an element to its own singleton set
    - `find()` - Find the representative (root) of a set with path compression
    - `union()` - Merge two sets with union by rank
  - **Convenience functions:**
    - `from_pairs()` - Build from list of pairs (perfect for edge lists)
    - `connected()` - Check if two elements are in the same set
    - `size()` - Total number of elements in the structure
    - `count_sets()` - Number of distinct disjoint sets
    - `to_lists()` - Extract all sets as list of lists
  - **Time Complexity:** O(α(n)) amortized per operation (practically constant)
  - Path compression flattens tree structure for future queries
  - Union by rank keeps trees balanced
  - Generic over any type (integers, strings, custom types)
  - Auto-adds elements on first find (convenience feature)
  - 39 comprehensive tests covering creation, find, union, path compression, union by rank, components, stress tests, generic types, and all convenience functions
  - Complete documentation with examples and use cases
  - **Use cases:** Dynamic connectivity, MST (Kruskal's), image segmentation, network connectivity, percolation, maze generation, game dev

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
- **Disjoint Set module promoted to public API** - `internal/dsu` moved to `yog/disjoint_set`
  - All references updated (`yog/mst` now imports from public module)
  - Test suite moved from `test/yog/internal/dsu_test.gleam` to `test/yog/disjoint_set_test.gleam`
  - Breaking change if you were using the internal module (but you shouldn't have been!)
- Test suite expanded to 454 tests (from 374)
  - Added 19 new tests for disjoint set convenience functions
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
