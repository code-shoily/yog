# Property-Based Testing Reference

Property-based testing for Yog graph algorithms using `qcheck` v1.0.4.

## Test Statistics

| Metric | Count |
|--------|-------|
| Total tests | 950 |
| Property tests | 34 |
| Basic properties | 12 |
| Edge case tests | 8 |
| Algorithm tests | 14 |

## Running Tests

```bash
gleam test
```

## Test Files

| File | Lines | Purpose |
|------|-------|---------|

| `test/yog/property_tests.gleam` | 462 | Basic structural properties |
| `test/yog/aggressive_property_tests.gleam` | 216 | Edge cases and boundary conditions |
| `test/yog/algorithm_property_tests.gleam` | 466 | Algorithm correctness and cross-validation |

## Category 1: Structural Properties

### Graph Transformations

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 1 | Transpose is involutive: `transpose(transpose(G)) = G` | `transpose_involutive_test()` | Validates O(1) transpose implementation used by SCC algorithms | ✅ |
| 2 | Edge count consistency | `edge_count_consistency_test()` | Ensures graph statistics match actual edge storage | ✅ |
| 3 | Undirected graphs are symmetric | `undirected_symmetry_test()` | For undirected graphs, every edge appears in both directions | ✅ |
| 4 | Neighbors equals successors (undirected) | `undirected_neighbors_equal_successors_test()` | API consistency for undirected graphs | ✅ |

### Data Transformations

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 5 | `map_nodes` preserves structure | `map_nodes_preserves_structure_test()` | Node transformations don't alter graph topology | ✅ |
| 6 | `map_edges` preserves structure | `map_edges_preserves_structure_test()` | Edge transformations don't alter graph topology | ✅ |
| 7 | `filter_nodes` removes incident edges | `filter_nodes_removes_incident_edges_test()` | No dangling edge references after node removal | ✅ |
| 8 | `to_undirected` creates symmetry | `to_undirected_creates_symmetry_test()` | Directed to undirected conversion adds reverse edges | ✅ |

### Operations

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 9 | Add/remove edge (directed) | `add_remove_edge_inverse_directed_test()` | Edge operations are inverse for directed graphs | ✅ |
| 10 | Add/remove edge (undirected) | `add_remove_edge_inverse_undirected_test()` | Documents asymmetric behavior (v3.x) | ✅ ⚠️ |

**Note on Property 10:** Currently documents known asymmetry where `remove_edge` only removes one direction for undirected graphs. Planned fix in v4.0.

### Traversals

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 11 | BFS produces no duplicates | `traversal_no_duplicates_bfs_test()` | Breadth-first search visits each node once | ✅ |
| 12 | DFS produces no duplicates | `traversal_no_duplicates_dfs_test()` | Depth-first search visits each node once, even with cycles | ✅ |

## Category 2: Edge Cases

| # | Case | Test Function | Rationale | Status |
|---|------|---------------|-----------|--------|

| 1 | Empty graphs | `empty_graph_edge_count_test()`, `empty_graph_transpose_test()` | Operations on graphs with no nodes/edges | ✅ |
| 2 | Self-loops (directed) | `self_loop_directed_test()` | Node pointing to itself in directed graph | ✅ |
| 3 | Self-loops (undirected) | `self_loop_undirected_test()` | Node pointing to itself in undirected graph | ✅ |
| 4 | Multiple edges same pair | `multiple_edges_same_pair_test()` | Duplicate edge insertion replaces weight | ✅ |
| 5 | Remove nonexistent edge | `remove_nonexistent_edge_test()` | Removing missing edge is no-op | ✅ |
| 6 | Undirected edge removal asymmetry | `undirected_edge_removal_asymmetry_test()` | Documents v3.x behavior requiring two removals | ✅ ⚠️ |
| 7 | Filter all nodes | `filter_all_nodes_test()` | Filtering removes all nodes and edges | ✅ |
| 8 | Transpose with self-loop | `transpose_with_self_loop_test()` | Self-loops remain after transpose | ✅ |
| 9 | Isolated nodes | `isolated_node_test()` | Nodes with no incoming/outgoing edges | ✅ |

## Category 3: Algorithm Correctness

### Cross-Validation

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 1 | Tarjan SCC = Kosaraju SCC | `scc_tarjan_equals_kosaraju_test()` | Different SCC algorithms produce same components | ✅ |
| 2 | Kruskal MST weight = Prim MST weight | `mst_kruskal_equals_prim_weight_test()` | Different MST algorithms produce same total weight | ✅ |
| 3 | Bellman-Ford = Dijkstra (non-negative) | `bellman_ford_equals_dijkstra_test()` | Algorithms agree on non-negative weighted graphs | ✅ |

### Pathfinding Correctness

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 4 | Dijkstra path validity | `dijkstra_path_validity_test()` | Path starts/ends correctly, edges exist, weight accurate | ✅ |
| 5 | No-path detection | `dijkstra_no_path_confirmed_by_bfs_test()` | Dijkstra None confirmed by BFS unreachability | ✅ |
| 6 | Undirected path symmetry | `undirected_path_symmetry_test()` | Path weight A→B equals B→A in undirected graphs | ✅ |
| 7 | Triangle inequality | `triangle_inequality_test()` | Direct path ≤ path via intermediate node | ✅ |

### Complex Invariants

| # | Property | Test Function | Rationale | Status |
|---|----------|---------------|-----------|--------|

| 8 | SCC components partition graph | `scc_partition_test()` | Components are disjoint and cover all nodes | ✅ |
| 9 | MST is spanning tree | `mst_spanning_tree_test()` | MST reaches all nodes in connected graph | ✅ |
| 10 | Bridge removal disconnects graph | `bridge_removal_test()` | Removing bridge increases connected components | ✅ |
| 11 | Degree centrality correctness | `degree_centrality_correctness_test()` | Normalized degree values match expectations | ✅ |
| 12 | Betweenness centrality non-negative | `betweenness_centrality_non_negative_test()` | All betweenness scores ≥ 0 | ✅ |
| 13 | Closeness centrality range | `closeness_centrality_in_valid_range_test()` | All closeness scores in [0, 1] | ✅ |

## Testing Strategy

### Hybrid Approach

Two complementary strategies are used:

**1. Property-Based Testing (PBT)**

- Random graph generation via `qcheck`
- ~100 test cases per property
- Graph sizes: 0-15 nodes, 0-30 edges
- Best for: Structural properties, transformations

**2. Example-Based Testing**

- Specific graph configurations
- Deterministic, fast execution
- Best for: Complex algorithms, performance-sensitive operations

### Graph Generators

```gleam
graph_generator()                    // Random directed/undirected
undirected_graph_generator()         // Random undirected
directed_graph_generator()           // Random directed
graph_generator_custom(kind, n, e)   // Custom size
```

## Known Issues

### Undirected Edge Removal Asymmetry

**Status:** Documented, planned fix in v4.0

**Behavior (v3.x):**

```gleam
graph
|> model.add_edge(0, 1, 10)    // Adds BOTH 0→1 and 1→0
|> model.remove_edge(0, 1)     // Removes ONLY 0→1
```

**Workaround:**

```gleam
graph
|> model.remove_edge(0, 1)
|> model.remove_edge(1, 0)      // Must remove both directions
```

**Reference:** `model.gleam` lines 293-295, 324-328

## Implementation Details

### Dependencies

```toml
[dev-dependencies]
qcheck = ">= 1.0.0 and < 2.0.0"
```

### Configuration

- Test framework: `gleeunit`
- Property library: `qcheck` v1.0.4
- Test timeout: 120s default
- Shrinking: Automatic (qcheck)

## References

- qcheck documentation: https://hexdocs.pm/qcheck/
- QuickCheck paper: https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf
- Property-Based Testing: https://hypothesis.works/articles/what-is-property-based-testing/