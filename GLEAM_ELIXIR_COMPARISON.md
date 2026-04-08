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
| **Total Algorithms** | 60+ | 65+ |
| **Lines of Code** | ~14,000 | ~18,000 |
| **Test Coverage** | 1,500+ tests | 1,450+ tests |

## Core Data Structures

| Feature | Gleam | Elixir | Notes |
| --------- | ------- | ----- | ------- |
| **Graph<'n, 'e>** | ✅ | ✅ | Directed/Undirected with generic node/edge data |
| **MultiGraph** | ✅ | ✅ | Parallel edges between nodes |
| **DAG (Directed Acyclic Graph)** | ✅ | ✅ | Type-safe wrapper with cycle prevention |
| **Disjoint Set (Union-Find)** | ✅ | ✅ | Path compression and union by rank |
| **Functional Graphs (FGL)** | ❌ | ✅ | **Elixir only** - Pure inductive graph library |

## Pathfinding Algorithms

| Algorithm | Gleam | Elixir | Complexity |
| ----------- | ------- | ----- | ------------ |
| **Dijkstra** | ✅ | ✅ | O((V+E) log V) |
| **A\*** | ✅ | ✅ | O((V+E) log V) |
| **Bellman-Ford** | ✅ | ✅ | O(VE) |
| **Floyd-Warshall** | ✅ | ✅ | O(V³) |
| **Shortest Path (Unweighted)** | ✅ | ✅ | O(V+E) |
| **Implicit Pathfinding** | ✅ | ✅ | State-space search |

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

## Flow & Optimization

| Algorithm | Gleam | Elixir | Status |
| ----------- | ------- | ----- | -------- |
| **Edmonds-Karp** (Max Flow) | ✅ | ✅ | Both fully functional |
| **Stoer-Wagner** (Global Min Cut) | ✅ | ✅ | Both fully functional |
| **Network Simplex** (Min Cost Flow) | ✅ | ✅ | Both complete implementations |
| **Successive Shortest Path** | ❌ | ✅ | **Elixir only** - Min-cost flow with potentials |
| **Capacity Scaling** | ❌ | ✅ | **Elixir only** - Max flow with scaling technique |

## Centrality Measures

| Measure | Gleam | Elixir | Notes |
| --------- | ------- | ----- | ------- |
| **Degree Centrality** | ✅ | ✅ | |
| **Betweenness Centrality** | ✅ | ✅ | |
| **Closeness Centrality** | ✅ | ✅ | |
| **PageRank** | ✅ | ✅ | Iterative algorithm |
| **Eigenvector Centrality** | ✅ | ✅ | Power iteration |
| **Katz Centrality** | ✅ | ✅ | |

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

## Minimum Spanning Trees

| Algorithm | Gleam | Elixir | Notes |
| ----------- | ------- | ----- | ------- |
| **Kruskal's MST** | ✅ | ✅ | O(E log E) |
| **Prim's MST** | ✅ | ✅ | O(E log V) |

## Graph Generators

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
| **Erdős-Rényi G(n,p)** | ✅ | ✅ | Edge probability p |
| **Barabási-Albert** | ✅ | ✅ | Scale-free networks |
| **Watts-Strogatz** | ✅ | ✅ | Small-world networks |

## I/O & Visualization

| Format | Gleam | Elixir | Purpose |
| -------- | ------- | ----- | --------- |
| **DOT (Graphviz)** | ✅ | ✅ | Professional visualization |
| **Mermaid** | ✅ | ✅ | Markdown diagrams |
| **ASCII/Unicode Rendering** | ✅ | ✅ | Terminal visualization |

For I/O, see [yog_io](https://hex.pm/packages/yog_io) for JSON, GraphML, and more with Gleam.
---

**Last Updated**: April 2026
**Gleam Version**: 6.0.0 (Unreleased)
**Elixir Version**: 0.95.0
