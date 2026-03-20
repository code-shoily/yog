# Yog: Gleam vs F# Implementation Comparison

This document compares the Gleam and F# implementations of the Yog graph algorithm library.

## Quick Summary

| Aspect | Gleam | F# |
| -------- | ------- | ----- |
| **Repository** | [code-shoily/yog](https://github.com/code-shoily/yog) | [code-shoily/yog-fsharp](https://github.com/code-shoily/yog-fsharp) |
| **Language** | Gleam (BEAM/Erlang VM) | F# (.NET) |
| **Package** | [hex.pm/packages/yog](https://hex.pm/packages/yog) | [nuget.org/packages/Yog.FSharp](https://www.nuget.org/packages/Yog.FSharp/) |
| **Documentation** | [HexDocs](https://hexdocs.pm/yog/) | [GitHub Pages](https://code-shoily.github.io/yog-fsharp) |
| **Status** | Stable, Production Ready | 0.5.0 Pre-release |
| **Total Algorithms** | 60+ | 50+ |
| **Lines of Code** | ~13,000 | ~8,500 |

## Core Data Structures

| Feature | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Graph<'n, 'e>** | ✅ | ✅ | Directed/Undirected with generic node/edge data |
| **MultiGraph** | ✅ | ✅ | Parallel edges between nodes |
| **DAG (Directed Acyclic Graph)** | ✅ | ✅ | Type-safe wrapper with cycle prevention |
| **Disjoint Set (Union-Find)** | ✅ | ✅ | Path compression and union by rank |

## Pathfinding Algorithms

| Algorithm | Gleam | F# | Complexity |
| ----------- | ------- | ----- | ------------ |
| **Dijkstra** | ✅ | ✅ | O((V+E) log V) |
| **A\*** | ✅ | ✅ | O((V+E) log V) |
| **Bellman-Ford** | ✅ | ✅ | O(VE) |
| **Floyd-Warshall** | ✅ | ✅ | O(V³) |
| **Distance Matrix** | ✅ | ✅ | All-pairs distances |
| **Implicit Pathfinding** | ✅ | ✅ | State-space search |

**Status**: ✅ Feature parity - All algorithms present in both

## Graph Traversal

| Algorithm | Gleam | F# | Notes |
| ----------- | ------- | ----- | ------- |
| **BFS** | ✅ | ✅ | Breadth-first search |
| **DFS** | ✅ | ✅ | Depth-first search |
| **Early Termination** | ✅ | ✅ | Stop on goal found |
| **Implicit Traversal** | ✅ | ✅ | On-demand graph exploration |
| **Topological Sort** | ✅ | ✅ | Kahn's algorithm |
| **Lexicographical Topo Sort** | ✅ | ✅ | Stable ordering |

**Status**: ✅ Feature parity

## Flow & Optimization

| Algorithm | Gleam | F# | Status |
| ----------- | ------- | ----- | -------- |
| **Edmonds-Karp** (Max Flow) | ✅ | ✅ | Both fully functional |
| **Min Cut from Max Flow** | ✅ | ✅ | Both fully functional |
| **Stoer-Wagner** (Global Min Cut) | ✅ | ✅ | Both fully functional |
| **Network Simplex** (Min Cost Flow) | ✅ ✅ | ⚠️ ❌ | **Gleam: Complete (930 LOC)**, **F#: Incomplete (349 LOC)** |

**Status**: ✅ **Gleam has complete, production-ready Network Simplex**

### Network Simplex Details

| Component | Gleam | F# |
| ----------- | ------- | ----- |
| Initial state setup | ✅ | ✅ |
| Demand validation | ✅ | ✅ |
| Entering edge selection | ✅ | ✅ |
| **find_cycle** | ✅ | ❌ |
| **find_leaving_edge** | ✅ | ❌ |
| **augment_flow** | ✅ | ❌ |
| **Tree updates** | ✅ | ❌ |
| **Potential updates** | ✅ | ❌ |
| Tests pass | ✅ All tests | ❌ Fails all tests |

> **Gleam Advantage**: Full Network Simplex implementation with all pivot logic, extensively tested.

## Graph Properties & Analysis

| Feature | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Connectivity** | ✅ | ✅ | |
| - Bridges | ✅ | ✅ | Tarjan's algorithm |
| - Articulation Points | ✅ | ✅ | Tarjan's algorithm |
| - Strong Components (SCC) | ✅ | ✅ | Tarjan's & Kosaraju's |
| **Cyclicity** | ✅ | ✅ | Cycle detection |
| **Eulerian Paths/Circuits** | ✅ | ✅ | Hierholzer's algorithm |
| **Bipartite Graphs** | ✅ | ✅ | Detection & max matching |
| **Stable Marriage** | ✅ | ✅ | Gale-Shapley algorithm |
| **Cliques** | ✅ | ✅ | Bron-Kerbosch algorithm |

**Status**: ✅ Feature parity

## Centrality Measures

| Measure | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Degree Centrality** | ✅ | ✅ | |
| **Betweenness Centrality** | ✅ | ✅ | Int & Float variants |
| **Closeness Centrality** | ✅ | ✅ | Int & Float variants |
| **Harmonic Centrality** | ✅ | ✅ | Int & Float variants |
| **PageRank** | ✅ | ✅ | Iterative algorithm |
| **Eigenvector Centrality** | ✅ | ✅ | Power iteration |
| **Katz Centrality** | ✅ | ✅ | |
| **Alpha Centrality** | ✅ | ✅ | |

**Status**: ✅ Feature parity - All 8 centrality measures in both

## Community Detection

| Algorithm | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Louvain** | ✅ | ❌ | Fast modularity optimization |
| **Leiden** | ✅ | ❌ | Quality guaranteed partitions |
| **Label Propagation** | ✅ | ❌ | Near-linear time scaling |
| **Girvan-Newman** | ✅ | ❌ | Hierarchical edge betweenness |
| ** Walktrap** | ✅ | ❌ | Random walk distances |
| **Infomap** | ✅ | ❌ | Information-theoretic flow |
| **Clique Percolation** | ✅ | ❌ | Overlapping communities |
| **Local Community** | ✅ | ❌ | Massive graphs, seed expansion |
| **Fluid Communities** | ✅ | ❌ | Exact `k` partitions, fast |
| **Metrics & Modularity** | ✅ | ❌ | Quality evaluation |

**Status**: ✅ **Gleam exclusive feature**

## Minimum Spanning Trees

| Algorithm | Gleam | F# | Notes |
| ----------- | ------- | ----- | ------- |
| **Kruskal's MST** | ✅ | ✅ | O(E log E) |
| **Prim's MST** | ✅ | ✅ | O(E log V) |

**Status**: ✅ Feature parity

## Graph Generators

### Classic Deterministic Graphs

| Generator | Gleam | F# | Description |
| ----------- | ------- | ----- | ------------- |
| **Complete (K_n)** | ✅ | ✅ | Every node connected |
| **Cycle (C_n)** | ✅ | ✅ | Ring structure |
| **Path (P_n)** | ✅ | ✅ | Linear chain |
| **Star (S_n)** | ✅ | ✅ | Hub with spokes |
| **Wheel (W_n)** | ✅ | ✅ | Cycle + center hub |
| **Grid 2D** | ✅ | ✅ | Rectangular lattice |
| **Binary Tree** | ✅ | ✅ | Complete binary tree |
| **Complete Bipartite** | ✅ | ✅ | K_{m,n} |
| **Petersen Graph** | ✅ | ✅ | Famous 10-node graph |
| **Empty Graph** | ✅ | ✅ | Isolated nodes |

**Status**: ✅ Feature parity - All 10 classic generators

### Random Network Models

| Generator | Gleam | F# | Description |
| ----------- | ------- | ----- | ------------- |
| **Erdős-Rényi G(n,p)** | ✅ | ✅ | Edge probability p |
| **Erdős-Rényi G(n,m)** | ✅ | ✅ | Exactly m edges |
| **Barabási-Albert** | ✅ | ✅ | Scale-free networks |
| **Watts-Strogatz** | ✅ | ✅ | Small-world networks |
| **Random Trees** | ✅ | ✅ | Uniformly random spanning trees |

**Status**: ✅ Feature parity - All 5 random generators

## Graph Builders

| Builder | Gleam | F# | Use Case |
| --------- | ------- | ----- | ---------- |
| **Labeled Builder** | ✅ | ✅ | Use custom labels instead of IDs |
| **Live Builder** | ✅ | ✅ | Interactive construction |
| **Grid Builder** | ✅ | ✅ | Lattice/grid graphs |

**Status**: ✅ Feature parity

## Graph Transformations

| Operation | Gleam | F# | Notes |
| ----------- | ------- | ----- | ------- |
| **Transpose** | ✅ | ✅ | O(1) edge reversal |
| **Map Nodes** | ✅ | ✅ | Transform node data |
| **Map Edges** | ✅ | ✅ | Transform edge data |
| **Filter Nodes** | ✅ | ✅ | Remove nodes by predicate |
| **Filter Edges** | ✅ | ✅ | Remove edges by predicate |
| **Subgraph** | ✅ | ✅ | Extract by node set |
| **Merge** | ✅ | ✅ | Combine graphs |
| **Contract Edges** | ✅ | ❌ | **Gleam only** - Merge nodes |

**Status**: ✅ **Gleam has edge contraction**

## Visualization & I/O

| Format | Gleam | F# | Purpose |
| -------- | ------- | ----- | --------- |
| **DOT (Graphviz)** | ✅ | ✅ | Professional visualization |
| **JSON** | ✅ | ✅ | Web APIs, data interchange |
| **Mermaid** | ✅ | ✅ | Markdown diagrams |
| **GraphML** | 🔶 Planned | ✅ | XML format for Gephi, yEd, Cytoscape |
| **GDF** | 🔶 Planned | ✅ | Gephi lightweight format |

**Status**: ⚠️ F# has 2 additional export formats (planned for Gleam)

> **Future Enhancement**: GraphML and GDF export would be valuable additions to Gleam's I/O capabilities for better integration with tools like Gephi and yEd.

## DAG-Specific Algorithms

| Feature | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Type-safe DAG wrapper** | ✅ | ✅ | Prevents cycles at compile time |
| **Longest Path** | ✅ | ✅ | Critical path analysis |
| **Topological Sort** | ✅ | ✅ | Guaranteed success on DAG |
| **Transitive Closure** | ✅ | ✅ | Reachability matrix |
| **Transitive Reduction** | ✅ | ✅ | Minimal equivalent DAG |

**Status**: ✅ Feature parity

## MultiGraph Support

| Feature | Gleam | F# | Notes |
| --------- | ------- | ----- | ------- |
| **Parallel Edges** | ✅ | ✅ | Multiple edges between nodes |
| **Edge IDs** | ✅ | ✅ | Unique identification |
| **Eulerian for MultiGraphs** | ✅ | ✅ | Specialized implementation |
| **MultiGraph Traversal** | ✅ | ✅ | BFS/DFS with edge IDs |

**Status**: ✅ Feature parity

## Performance Optimizations

| Feature | Gleam | F# |
| --------- | ------- | ----- |
| **Pairing Heap (Priority Queue)** | ✅ | ❌ |
| **Two-List Queue (BFS)** | ✅ | ❌ |
| **Mutable Arrays for Hot Paths** | Limited | ✅ |
| **O(1) Transpose** | ✅ | ✅ |

> **Gleam Advantage**: Custom data structures (Pairing Heap, Two-List Queue) optimized for graph algorithms.

## Testing & Quality

| Aspect | Gleam | F# |
| -------- | ------- | ----- |
| **Unit Tests** | ✅ Extensive | ✅ Extensive |
| **Property-Based Tests** | ✅ qcheck | ✅ FsCheck |
| **Example Count** | 25+ | 37+ |
| **Documentation Coverage** | ✅ Complete | ✅ Complete |
| **CI/CD** | ✅ GitHub Actions | ✅ GitHub Actions |

## Platform & Ecosystem

| Aspect | Gleam | F# |
| -------- | ------- | ----- |
| **Runtime** | BEAM/Erlang VM | .NET CLR |
| **Target Platforms** | Erlang, JavaScript | Windows, Linux, macOS |
| **Concurrency Model** | Actor model (OTP) | async/await, Tasks |
| **Package Manager** | Hex | NuGet |
| **Interactive** | Gleam REPL | F# Interactive (FSI) |

## Unique Features

### Gleam Only

- ✅ **Community Detection Suite** - 10 algorithms including Louvain, Leiden, Infomap, Fluid
- ✅ **Complete Network Simplex** - Full min cost flow implementation (930 LOC)
- ✅ **Edge Contraction** - Graph transformation
- ✅ **Pairing Heap** - Custom priority queue for pathfinding
- ✅ **Two-List Queue** - Optimized BFS queue
- ✅ **Production Ready** - Stable 5.0.0 release

### F# Only

- ✅ **GraphML Export/Import** - XML graph format for Gephi, yEd, Cytoscape
- ✅ **GDF Export** - Gephi lightweight format
- ✅ **More Examples** (37 vs 25)
- ✅ **.NET Integration** - Seamless with C#/VB.NET

## Migration Guide

### F# → Gleam

**Straightforward migration**, but note:

- ✅ Network Simplex works correctly in Gleam
- ✅ All core algorithms present and tested
- ❌ No GraphML/GDF support yet (coming soon)

### Gleam →  

**Mostly straightforward**, but watch for:

- ⚠️ Network Simplex is incomplete in F# (use Gleam or wait for update)
- ✅ All other algorithms are functionally equivalent
- ✅ F# has additional export formats (GraphML, GDF)

## Version History

| Version | Gleam | F# |
| --------- | ------- | ----- |
| **Latest** | 5.0.0 | 0.5.0 |
| **First Release** | 2024 | 2025 |
| **Stability** | Stable | Pre-release |

## Recommendations

### Choose Gleam If

- ✅ Building BEAM/Erlang applications or microservices
- ✅ Need **min cost flow** (Network Simplex) in production
- ✅ Want battle-tested, stable code (0.6.0+)
- ✅ Prefer functional programming on Erlang VM
- ✅ Building fault-tolerant, distributed systems
- ✅ Using Phoenix, Nerves, or other BEAM ecosystem tools

### Choose F# If

- ✅ Working in **.NET ecosystem**
- ✅ Need **GraphML/GDF** export for Gephi/yEd integration
- ✅ Want seamless C# interop
- ✅ Can wait for Network Simplex completion or use alternatives
- ✅ Prefer statically typed .NET with excellent tooling
- ✅ Building desktop or Windows-centric applications

## Roadmap

### Gleam Planned

- [ ] **GraphML Export/Import** - Add XML-based graph format support
- [ ] **GDF Export** - Add Gephi lightweight format
- [ ] More examples to match F# (target: 35+)
- [ ] Performance benchmarks vs F#
- [ ] Additional random graph models

### F# Planned

- [ ] **Complete Network Simplex** - Port full pivot logic from Gleam
- [ ] Edge contraction transformation
- [ ] Custom data structures (Pairing Heap, Two-List Queue)

### Both

- [ ] Additional centrality measures
- [ ] Graph isomorphism detection
- [ ] Graph coloring algorithms

## Contributing

Both implementations welcome contributions!

- **Gleam**: [github.com/code-shoily/yog](https://github.com/code-shoily/yog)
- **F#**: [github.com/code-shoily/yog-fsharp](https://github.com/code-shoily/yog-fsharp)

## Summary

Both implementations are **high-quality, feature-rich graph libraries** with excellent documentation and test coverage.

**Algorithm Coverage**: ~98% feature parity
**Quality**: Both production-ready (Gleam has complete Network Simplex)
**Documentation**: Excellent in both
**Community**: Active maintenance in both

### Key Differentiators

**Gleam Strengths:**

- ✅ Community Detection Suite (10 algorithms)
- ✅ Complete Network Simplex (production-ready min cost flow)
- ✅ Edge contraction
- ✅ Battle-tested on BEAM VM
- ✅ Stable 5.0.0 release
- ✅ Custom optimized data structures

**F# Strengths:**

- ✅ GraphML/GDF export formats
- ✅ More examples (37 vs 25)
- ✅ .NET ecosystem integration

**Recommended Use:**

- **Production min cost flow problems**: Choose Gleam
- **Gephi/yEd visualization workflows**: Choose F# (or wait for Gleam support)
- **Platform-specific**: BEAM → Gleam, .NET → F#

---

**Last Updated**: March 2025
**Gleam Version**: 5.0.0
**F# Version**: 0.5.0
