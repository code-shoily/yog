# Yog

```text
                    ★
                   /|\
                  / | \
                 /  |  \
                Y   |   O--------G
               /    |    \      /
              /     |     \    /
             /      |      \  /
            যো------+-------গ
           / \      |      / \
          /   \     |     /   \
         /     \    |    /     \
        ✦       ✦   |   ✦       ✦
                   
```

[![Package Version](https://img.shields.io/hexpm/v/yog)](https://hex.pm/packages/yog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yog/)

A graph algorithm library for Gleam, providing implementations of classic graph algorithms with a functional API.

🔷 **[F# Port](https://github.com/code-shoily/yog-fsharp)** - Also available for F# with similar functional APIs | 📊 **[Gleam vs F# Comparison](GLEAM_FSHARP_COMPARISON.md)** - Detailed feature comparison

## Features

- **Graph Data Structures**: Directed and undirected graphs with generic node and edge data
- **Pathfinding Algorithms**: Dijkstra, A*, Bellman-Ford, Floyd-Warshall, Johnson's, and **Implicit Variants** (state-space search)
- **Maximum Flow**: Highly optimized Edmonds-Karp algorithm with flat dictionary residuals
- **Graph Generators**: Create classic patterns (complete, cycle, path, star, wheel, bipartite, trees, grids) and random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz)
- **Graph Traversal**: BFS and DFS with early termination and **Implicit Variants**
- **Graph Transformations**: Transpose (O(1)!), map, filter, merge, subgraph extraction, edge contraction
- **Graph Visualization**: Mermaid, DOT (Graphviz), and ASCII rendering
- **Minimum Spanning Tree**: Kruskal's and Prim's algorithms with Union-Find and Priority Queues
- **Minimum Cut**: Stoer-Wagner algorithm for global min-cut
- **Network Health**: Diameter, radius, eccentricity, assortativity, average path length
- **Directed Acyclic Graphs (DAG)**: Strictly-validated `Dag(n, e)` wrapper bringing O(V+E) DP routines like `longest_path` (Critical Path), LCA, and transitive structures
- **Topological Sorting**: Kahn's algorithm with lexicographical variant, alongside guaranteed cycle-free DAG-specific sorts
- **Strongly Connected Components**: Tarjan's and Kosaraju's algorithms
- **Maximum Clique**: Bron-Kerbosch algorithm for maximal and all maximal cliques
- **Connectivity**: Bridge and articulation point detection
- **Eulerian Paths & Circuits**: Detection and finding using Hierholzer's algorithm
- **Bipartite Graphs**: Detection, maximum matching, and stable marriage (Gale-Shapley)
- **Minimum Cost Flow (MCF)**: Global optimization using the robust **Network Simplex** algorithm
- **Disjoint Set (Union-Find)**: With path compression and union by rank
- **Efficient Data Structures**: Pairing heap for priority queues, two-list queue for BFS
- **Property-Based Testing**: Exhaustively tested across core graph operations and invariants using `qcheck`

## Installation

Add Yog to your Gleam project:

```sh
gleam add yog
```

## Quick Start

```gleam
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog
import yog/pathfinding/dijkstra

pub fn main() {
  // Create a directed graph
  let graph =
    yog.directed()
    |> yog.add_node(1, "Start")
    |> yog.add_node(2, "Middle")
    |> yog.add_node(3, "End")

  let assert Ok(graph) =
    yog.add_edges(graph, [
      #(1, 2, 5),
      #(2, 3, 3),
      #(1, 3, 10)
    ])

  // Find shortest path
  case dijkstra.shortest_path(
    in: graph,
    from: 1,
    to: 3,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare
  ) {
    Some(path) -> {
      io.println("Found path with weight: " <> int.to_string(path.total_weight))
    }
    None -> io.println("No path found")
  }
}
```

## Examples

We have some real-world projects that use Yog for graph algorithms:

- [Lustre Graph Generator](https://github.com/code-shoily/lustre_graph_generator) ([Demo](https://code-shoily.github.io/lustre_graph_generator/)) - Showcases graph generation, topological sort and shortest distance feature of Yog.
- [Advent of Code Solutions](https://github.com/code-shoily/aocgl/blob/main/wiki/tags/graph.md) - Multiple AoC puzzles solved using Yog's graph capabilities.

Detailed examples are located in the [test/examples/](https://github.com/code-shoily/yog/tree/main/test/examples) directory:

- [Social Network Analysis](https://github.com/code-shoily/yog/blob/main/test/examples/social_network_analysis.gleam) - Finding communities using SCCs.
- [Task Scheduling](https://github.com/code-shoily/yog/blob/main/test/examples/task_scheduling.gleam) - Basic topological sorting.
- [GPS Navigation](https://github.com/code-shoily/yog/blob/main/test/examples/gps_navigation.gleam) - Shortest path using A* and heuristics.
- [Network Cable Layout](https://github.com/code-shoily/yog/blob/main/test/examples/network_cable_layout.gleam) - Minimum Spanning Tree using Kruskal's.
- [Network Bandwidth](https://github.com/code-shoily/yog/blob/main/test/examples/network_bandwidth.gleam) - ⭐ Max flow for bandwidth optimization with bottleneck analysis.
- [Job Matching](https://github.com/code-shoily/yog/blob/main/test/examples/job_matching.gleam) - ⭐ Max flow for bipartite matching and assignment problems.
- [Cave Path Counting](https://github.com/code-shoily/yog/blob/main/test/examples/cave_path_counting.gleam) - Custom DFS with backtracking.
- [Task Ordering](https://github.com/code-shoily/yog/blob/main/test/examples/task_ordering.gleam) - Lexicographical topological sort.
- [Bridges of Königsberg](https://github.com/code-shoily/yog/blob/main/test/examples/bridges_of_konigsberg.gleam) - Eulerian circuit and path detection.
- [Global Minimum Cut](https://github.com/code-shoily/yog/blob/main/test/examples/global_min_cut.gleam) - Stoer-Wagner algorithm.
- [Job Assignment](https://github.com/code-shoily/yog/blob/main/test/examples/job_assignment.gleam) - Bipartite maximum matching.
- [Medical Residency](https://github.com/code-shoily/yog/blob/main/test/examples/medical_residency.gleam) - Stable marriage matching (Gale-Shapley algorithm).
- [City Distance Matrix](https://github.com/code-shoily/yog/blob/main/test/examples/city_distance_matrix.gleam) - Floyd-Warshall for all-pairs shortest paths.
- [Graph Generation Showcase](https://github.com/code-shoily/yog/blob/main/test/examples/graph_generation_showcase.gleam) - ⭐ All 9 classic graph patterns with statistics.
- [DOT rendering](https://github.com/code-shoily/yog/blob/main/test/examples/render_dot.gleam) - Exporting graphs to Graphviz format.
- [Mermaid rendering](https://github.com/code-shoily/yog/blob/main/test/examples/render_mermaid.gleam) - Generating Mermaid diagrams.
- [Graph creation](https://github.com/code-shoily/yog/blob/main/test/examples/graph_creation.gleam) - Comprehensive guide to 10+ ways of creating graphs.

### Running Examples Locally

The examples live in the `test/examples/` directory and can be run directly:

```sh
gleam run -m examples/gps_navigation
gleam run -m examples/network_bandwidth
# etc.
```

## Algorithm Selection Guide

Detailed documentation for each algorithm can be found on [HexDocs](https://hexdocs.pm/yog/).

| Algorithm | Use When | Time Complexity |
| --------- | -------- | --------------- |
| **Dijkstra** | Non-negative weights, single shortest path | O((V+E) log V) |
| **Bidirectional Dijkstra** | Known target, weighted graphs, ~2× faster | O((V+E) log V / 2) |
| **Bidirectional BFS** | Known target, unweighted graphs, up to 500× faster | O(b^(d/2)) |
| **A*** | Non-negative weights + good heuristic | O((V+E) log V) |
| **Bellman-Ford** | Negative weights OR cycle detection needed | O(VE) |
| **Floyd-Warshall** | All-pairs shortest paths, distance matrices | O(V³) |
| **Johnson's** | All-pairs shortest paths in sparse graphs with negative weights | O(V² log V + VE) |
| **Edmonds-Karp** | Maximum flow, bipartite matching, network optimization | O(VE²) |
| **BFS/DFS** | Unweighted graphs, exploring reachability | O(V+E) |
| **Kruskal's MST** | Finding minimum spanning tree | O(E log E) |
| **Stoer-Wagner** | Global minimum cut, graph partitioning | O(V³) |
| **Tarjan's SCC** | Finding strongly connected components | O(V+E) |
| **Tarjan's Connectivity** | Finding bridges and articulation points | O(V+E) |
| **Hierholzer** | Eulerian paths/circuits, route planning | O(V+E) |
| **DAG Longest Path** | Critical path analysis on strictly directed acyclic graphs | O(V+E) |
| **Topological Sort** | Ordering tasks with dependencies | O(V+E) |
| **Gale-Shapley** | Stable matching, college admissions, medical residency | O(n²) |
| **Prim's MST** | Minimum spanning tree (starts from node) | O(E log V) |
| **Kosaraju's SCC** | Strongly connected components (two-pass) | O(V + E) |
| **Bron-Kerbosch** | Maximum and all maximal cliques | O(3^(n/3)) |
| **Network Simplex** | Global minimum cost flow optimization | O(E) pivots |
| **Implicit Search** | Pathfinding/Traversal on on-demand graphs | O((V+E) log V) |
| **PageRank** | Link-quality node importance | O(V+E) per iter |
| **Betweenness** | Bridge/gatekeeper detection | O(VE) or O(V³) |
| **Closeness / Harmonic** | Distance-based importance | O(VE log V) |
| **Eigenvector / Katz** | Influence based on neighbor centrality | O(V+E) per iter |
| **Louvain** | Modularity optimization, large graphs | O(E log V) |
| **Leiden** | Quality guarantee, well-connected communities | O(E log V) |
| **Label Propagation** | Very large graphs, extreme speed | O(E) per iter |
| **Infomap** | Information-theoretic flow tracking | O(E) per iter |
| **Walktrap** | Random-walk structural communities | O(V² log V) |
| **Girvan-Newman** | Hierarchical edge betweenness | O(E²V) |
| **Clique Percolation** | Overlapping community discovery | O(3^(V/3)) |
| **Local Community** | Massive/infinite graphs, seed expansion | O(S × E_S) |
| **Fluid Communities** | Exact `k` partitions, fast | O(E) per iter |

## Benchmarking

Yog includes built-in benchmarking utilities using `gleamy/bench`. Run the example benchmark:

```bash
gleam run -m bench/simple_pathfinding
```

For detailed instructions on creating custom benchmarks, interpreting results, and comparing against reference implementations, see the [Benchmarking Guide](BENCHMARKING_GUIDE.md).

## Development

### Running Tests

Run the full test suite:

```bash
gleam test
```

Run tests for a specific module:

```bash
./test_module.sh yog/pathfinding/bidirectional_test
```

Run a specific test function:

```bash
./test_module.sh yog/pathfinding/bidirectional_test dijkstra_complex_diamond_test
```

### Running Examples

Run all examples at once:

```bash
./run_examples.sh
```

Run a specific example:

```bash
gleam run -m examples/gps_navigation
```

### Project Structure

- `src/yog/` - Core graph library modules
- `test/` - Unit tests and property-based tests
- `test/examples/` - Real-world usage examples
- `test/bench/` - Performance benchmarks

## AI Assistance

Parts of this project were developed with the assistance of AI coding tools. All AI-generated code has been reviewed, tested, and validated by the maintainer.

---

**Yog** - Graph algorithms for Gleam
