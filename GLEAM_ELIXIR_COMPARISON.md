# Yog: Gleam vs Elixir (YogEx) Implementation Comparison

This document compares the Gleam and Elixir (YogEx) implementations of the Yog graph algorithm library.

## Quick Summary

| Aspect | Gleam (Yog) | Elixir (YogEx) |
| -------- | ------- | ----- |
| **Repository** | [code-shoily/yog](https://github.com/code-shoily/yog) | [code-shoily/yog_ex](https://github.com/code-shoily/yog_ex) |
| **Language** | Gleam (BEAM/Erlang VM) | Elixir (BEAM/Erlang VM) |
| **Package** | [hex.pm/packages/yog](https://hex.pm/packages/yog) | [hex.pm/packages/yog_ex](https://hex.pm/packages/yog_ex) |
| **Documentation** | [HexDocs](https://hexdocs.pm/yog/) | [HexDocs](https://hexdocs.pm/yog_ex/) |
| **Status** | Stable 6.0.0 | Beta 0.95.x (pre-1.0) |
| **Total Algorithms** | ~70 | ~60 |
| **Lines of Code** | ~14,000 | ~18,000 |
| **Test Coverage** | 1,496 tests | 1,677 unit + 188 property + 611 doctests | Gleam reports all tests under a single counter |
| **Test Execution Time** | ~15s | ~4s | Elixir runs natively on BEAM; Gleam compiles to Erlang first |

## Core Data Structures

| Feature | Gleam | Elixir | Notes |
| --------- | ------- | ----- | ------- |
| **Graph<'n, 'e>** | ✅ | ✅ | Directed/Undirected with generic node/edge data |
| **MultiGraph** | ✅ | ✅ | Parallel edges between nodes |
| **DAG (Directed Acyclic Graph)** | ✅ | ✅ | Type-safe wrapper with cycle prevention |
| **Disjoint Set (Union-Find)** | ✅ | ✅ | Path compression and union by rank |
| **Functional Graphs (FGL)** | ❌ | ✅ | **Elixir only** - Pure inductive graph library with graph transformations and traversals |

## Pathfinding Algorithms

| Algorithm | Gleam | Elixir | Complexity |
| ----------- | ------- | ----- | ------------ |
| **Dijkstra** | ✅ | ✅ | O((V+E) log V) |
| **A\*** | ✅ | ✅ | O((V+E) log V) |
| **Bellman-Ford** | ✅ | ✅ | O(VE) |
| **Floyd-Warshall** | ✅ | ✅ | O(V³) |
| **Johnson's APSP** | ✅ | ✅ | O(V² log V + VE) |
| **Bidirectional Search** | ✅ | ✅ | O(b^(d/2)) |
| **Shortest Path (Unweighted)** | ✅ | ✅¹ | O(V+E) |
| **Implicit Pathfinding** | ✅ | ✅ | State-space search |

¹ In Gleam this lives in `yog/pathfinding/unweighted`; in Elixir it is exposed via `Yog.Traversal.find_path/3`.

## Graph Traversal

| Algorithm | Gleam | Elixir | Notes |
| ----------- | ------- | ----- | ------- |
| **BFS** | ✅ | ✅ | Breadth-first search |
| **DFS** | ✅ | ✅ | Depth-first search |
| **Early Termination** | ✅ | ✅ | Stop on goal found |
| **Implicit Traversal** | ✅ | ✅ | On-demand graph exploration |
| **Topological Sort** | ✅ | ✅ | Kahn's algorithm |
| **Lexicographical Topo Sort** | ✅ | ✅ | Stable ordering |
| **Cycle Detection** | ✅ | ✅ | For directed & undirected graphs |
| **Best-First Walk** | ✅ | ❌ | Greedy heuristic traversal (Gleam only) |
| **Random Walk** | ✅ | ❌ | Stochastic graph exploration (Gleam only) |

## Flow & Optimization

| Algorithm | Gleam | Elixir | Status |
| ----------- | ------- | ----- | -------- |
| **Edmonds-Karp** (Max Flow) | ✅ | ✅ | Both fully functional |
| **Stoer-Wagner** (Global Min Cut) | ✅ | ✅ | Both fully functional |
| **Network Simplex** (Min Cost Flow) | ✅ | ❌ | Gleam only |
| **Successive Shortest Path** | ❌ | ✅ | **Elixir only** - Min-cost flow with potentials |
| **Capacity Scaling** | ❌ | ❌ | Not implemented in either version |

## Centrality Measures

| Measure | Gleam | Elixir | Notes |
| --------- | ------- | ----- | ------- |
| **Degree Centrality** | ✅ | ✅ | |
| **Betweenness Centrality** | ✅ | ✅ | |
| **Closeness Centrality** | ✅ | ✅ | |
| **Harmonic Centrality** | ✅ | ✅ | |
| **PageRank** | ✅ | ✅ | Iterative algorithm |
| **Eigenvector Centrality** | ✅ | ✅ | Power iteration |
| **Katz Centrality** | ✅ | ✅ | |
| **Alpha Centrality** | ✅ | ❌ | Gleam only |

**Convenience wrappers**: Gleam provides `_int` and `_float` variants for closeness, harmonic, and betweenness; Elixir only provides `_int` variants.

## Community Detection

| Algorithm | Gleam | Elixir | Notes |
| --------- | ------- | ----- | ------- |
| **Louvain** | ✅ | ✅ | Fast modularity optimization |
| **Leiden** | ✅ | ✅ | Quality guaranteed partitions |
| **Label Propagation** | ✅ | ✅ | Near-linear time scaling |
| **Girvan-Newman** | ✅ | ✅ | Hierarchical edge betweenness |
| **Walktrap** | ✅ | ✅ | Random walk distances |
| **Infomap** | ✅ | ✅ | Information-theoretic flow |
| **Clique Percolation** | ✅ | ✅ | Overlapping communities |
| **Local Community** | ✅ | ✅ | Massive graphs, seed expansion |
| **Fluid Communities** | ✅ | ✅ | Exact `k` partitions, fast |
| **Random Walk Communities** | ✅ | ❌ | Gleam only (`yog/community/random_walk`) |

## Minimum Spanning Trees

| Algorithm | Gleam | Elixir | Notes |
| ----------- | ------- | ----- | ------- |
| **Kruskal's MST** | ✅ | ✅ | O(E log E) |
| **Prim's MST** | ✅ | ✅ | O(E log V) |
| **MaxST Wrappers** | ❌ | ✅ | **Elixir only** – `kruskal_max`, `prim_max`, `maximum_spanning_tree` |
| **Borůvka's MST** | ❌ | ✅ | **Elixir only** – Parallel component-merging MST |
| **Wilson's UST** | ❌ | ✅ | **Elixir only** – Uniform random spanning tree |
| **Edmonds' Arborescence** | ❌ | ✅ | **Elixir only** – Directed MST (Chu-Liu/Edmonds) |

**API Differences**:
- **Elixir** returns `{:ok, %Yog.MST.Result{}}` with `total_weight`, `edge_count`, and `edges`; enforces `{:error, :undirected_only}` for Kruskal/Prim/Borůvka on directed graphs.
- **Gleam** returns `List(Edge(e))`, has no directed-graph validation, and Prim always starts from the first node in the graph's key order.

## Graph Generators

### Classic / Deterministic

| Generator | Gleam | Elixir | Description |
| ----------- | ------- | ----- | ------------- |
| **Complete (K_n)** | ✅ | ✅ | Every node connected |
| **Cycle (C_n)** | ✅ | ✅ | Ring structure |
| **Path (P_n)** | ✅ | ✅ | Linear chain |
| **Star (S_n)** | ✅ | ✅ | Hub with spokes |
| **Wheel (W_n)** | ✅ | ✅ | Cycle + center hub |
| **Grid 2D** | ✅ | ✅ | Rectangular lattice |
| **Petersen Graph** | ✅ | ✅ | Famous 10-node graph |
| **Platonic Solids** | ✅ | ✅ | Tetrahedron, Cube, Octahedron, Dodecahedron, Icosahedron |
| **k-ary Tree** | ✅ | ✅ | Complete k-ary tree |
| **Empty** | ✅ | ✅ | Isolated vertices |
| **Binary Tree** | ✅ | ✅ | Full binary tree |
| **Complete Bipartite** | ✅ | ✅ | K_{m,n} |
| **Book** | ✅ | ❌ | n triangular prisms sharing a common edge (Gleam only) |
| **Caterpillar** | ✅ | ❌ | Path with pendant vertices (Gleam only) |
| **Circular Ladder** | ✅ | ❌ | Prism graph variant (Gleam only) |
| **Crown** | ✅ | ❌ | Complete bipartite minus a perfect matching (Gleam only) |
| **Friendship** | ✅ | ❌ | Windmill graph W₃ₙ (Gleam only) |
| **Hypercube** | ✅ | ❌ | Q_n binary hypercube (Gleam only) |
| **Ladder** | ✅ | ❌ | P₂ × P_n grid (Gleam only) |
| **Möbius Ladder** | ✅ | ❌ | Cubic graph variant (Gleam only) |
| **Prism** | ✅ | ❌ | C_n × P₂ (Gleam only) |
| **Turán** | ✅ | ❌ | Turán graph T(n,r) (Gleam only) |
| **Windmill** | ✅ | ❌ | Complete graphs joined at a hub (Gleam only) |

### Random / Stochastic

| Generator | Gleam | Elixir | Description |
| ----------- | ------- | ----- | ------------- |
| **Erdős-Rényi G(n,p)** | ✅ | ✅ | Edge probability p |
| **Erdős-Rényi G(n,m)** | ✅ | ❌ | Fixed number of edges (Gleam only) |
| **Barabási-Albert** | ✅ | ✅ | Scale-free networks |
| **Watts-Strogatz** | ✅ | ✅ | Small-world networks |
| **Random Tree** | ✅ | ✅ | Uniform random tree |
| **Configuration Model** | ✅ | ❌ | Prescribed degree sequence (Gleam only) |
| **Geometric** | ✅ | ❌ | Random geometric graph (Gleam only) |
| **Kronecker** | ✅ | ❌ | Recursive tensor product (Gleam only) |
| **RMAT** | ✅ | ❌ | Recursive Matrix model (Gleam only) |
| **SBM** | ✅ | ❌ | Stochastic Block Model (Gleam only) |
| **DCSBM** | ✅ | ❌ | Degree-Corrected SBM (Gleam only) |
| **HSBM** | ✅ | ❌ | Hierarchical SBM (Gleam only) |
| **Random Regular** | ✅ | ❌ | Fixed regular degree (Gleam only) |

### Mazes & Games

| Generator | Gleam | Elixir | Description |
| ----------- | ------- | ----- | ------------- |
| **Maze (Recursive Backtracker)** | ✅ | ❌ | Perfect maze generation (Gleam only) |

## Graph Operations

| Operation | Gleam | Elixir | Notes |
| -------- | ------- | ----- | ------- |
| **Union** | ✅ | ❌ | Set-theoretic union (Gleam only) |
| **Intersection** | ✅ | ❌ | Set-theoretic intersection (Gleam only) |
| **Difference** | ✅ | ❌ | Relative complement (Gleam only) |
| **Symmetric Difference** | ✅ | ❌ | XOR of edge sets (Gleam only) |
| **Cartesian Product** | ✅ | ❌ | Graph Cartesian product (Gleam only) |
| **Disjoint Union** | ✅ | ❌ | Component-wise union (Gleam only) |
| **Composition** | ✅ | ❌ | Graph lexicographic product (Gleam only) |
| **Power Graph** | ✅ | ❌ | k-th power of a graph (Gleam only) |
| **Subgraph Check** | ✅ | ✅ | `is_subgraph` (Gleam) / `subgraph?` (Elixir) |
| **Isomorphism Check** | ✅ | ✅ | `is_isomorphic` (Gleam) / `isomorphic?` (Elixir) |

## Graph Properties

| Property / Algorithm | Gleam | Elixir | Notes |
| -------------------- | ------- | ----- | ------- |
| **Bipartite Check** | ✅ | ✅ | 2-colorability test |
| **Bipartite Partition** | ✅ | ✅ | Returns the two partitions |
| **Bipartite Coloring** | ❌ | ✅ | **Elixir only** – returns the actual 2-color assignment map |
| **Maximum Matching** | ✅ | ✅ | For bipartite graphs |
| **Stable Marriage** | ✅ | ✅ | Gale-Shapley algorithm |
| **Clique Detection** | ✅ | ✅ | Maximal & maximum cliques |
| **k-Cliques** | ✅ | ✅ | Fixed-size cliques |
| **Cycle Detection** | ✅ | ✅ | Directed & undirected |
| **Eulerian Path/Circuit** | ✅ | ✅ | Fleury's algorithm |

## Connectivity

| Feature | Gleam | Elixir | Notes |
| -------- | ------- | ----- | ------- |
| **Connected Components** | ✅ | ✅ | Via `analyze` in Elixir |
| **Strongly Connected Components** | ✅ | ❌ | Kosaraju's algorithm (Gleam only) |
| **Weakly Connected Components** | ✅ | ❌ | Gleam only |
| **Bridge & Articulation Point Detection** | ✅ | ✅ | Both expose via `analyze` |

## I/O & Visualization

| Format | Gleam | Elixir | Purpose |
| -------- | ------- | ----- | --------- |
| **DOT (Graphviz)** | ✅ | ✅ | Professional visualization |
| **Mermaid** | ✅ | ✅ | Markdown diagrams |
| **ASCII/Unicode Rendering** | ✅ | ✅ | Terminal visualization |
| **JSON** | ❌¹ | ✅ | Graph serialization |
| **GraphML** | ❌¹ | ✅ | XML-based graph exchange |
| **GDF** | ❌¹ | ✅ | GUESS graph format |
| **LEDA** | ❌¹ | ✅ | LEDA native format |
| **Pajek** | ❌¹ | ✅ | Pajek .net format |
| **TGF** | ❌¹ | ✅ | Trivial Graph Format |

¹ For I/O, see [yog_io](https://hex.pm/packages/yog_io) for JSON, GraphML, and more with Gleam.

---

## Key Takeaways

- **Gleam is leaner but broader** in algorithms: it has significantly more graph generators, operations, and traversal variants.
- **Elixir's unique features**: Functional Graphs (FGL) inductive graph library, Successive Shortest Path for min-cost flow, and exposed `bipartite_coloring` returning the actual 2-color map.
- **Gleam's unique features**: Network Simplex for min-cost flow, broader graph generators and operations, and more centrality/traversal variants.
- **API style differs**: Elixir provides a keyword-based facade module (`Yog.Pathfinding`) and exposes fewer convenience wrappers; Gleam favors explicit module imports and provides both `Int` and `Float` convenience variants for weighted algorithms.
- **Development velocity**: Elixir's test suite runs ~4× faster in development because it executes natively on the BEAM, whereas Gleam compiles to Erlang before running tests.

**Last Updated**: April 2026
**Gleam Version**: 6.0.0 (Unreleased)
**Elixir Version**: 0.95.0
