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

## Why Yog?

In many Indic languages, **Yog** (pronounced like "yoke") translates to "Union," "Addition," or "Connection." It stems from the ancient root *yuj*, meaning to join or to fasten together.

In the world of computer science, this is the literal definition of Graph Theory. A graph is nothing more than the union of independent points through purposeful connections.

## Features

- **Graph Data Structures**: Directed and undirected graphs with generic node and edge data
- **Pathfinding Algorithms**: Dijkstra, A*, Bellman-Ford, Floyd-Warshall, and **Implicit Variants** (state-space search)
- **Maximum Flow**: Highly optimized Edmonds-Karp algorithm with flat dictionary residuals
- **Graph Generators**: Create classic patterns (complete, cycle, path, star, wheel, bipartite, trees, grids) and random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz)
- **Graph Traversal**: BFS and DFS with early termination and **Implicit Variants**
- **Graph Transformations**: Transpose (O(1)!), map, filter, merge, subgraph extraction, edge contraction
- **Graph Visualization**: Mermaid, DOT (Graphviz), and JSON rendering
- **Minimum Spanning Tree**: Kruskal's and Prim's algorithms with Union-Find and Priority Queues
- **Minimum Cut**: Stoer-Wagner algorithm for global min-cut
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
    |> yog.add_edge(from: 1, to: 2, with: 5)
    |> yog.add_edge(from: 2, to: 3, with: 3)
    |> yog.add_edge(from: 1, to: 3, with: 10)

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

Detailed examples are located in the [examples/](https://github.com/code-shoily/yog/tree/main/examples) directory:

- [Social Network Analysis](https://github.com/code-shoily/yog/blob/main/examples/social_network_analysis.gleam) - Finding communities using SCCs.
- [Task Scheduling](https://github.com/code-shoily/yog/blob/main/examples/task_scheduling.gleam) - Basic topological sorting.
- [GPS Navigation](https://github.com/code-shoily/yog/blob/main/examples/gps_navigation.gleam) - Shortest path using A* and heuristics.
- [Network Cable Layout](https://github.com/code-shoily/yog/blob/main/examples/network_cable_layout.gleam) - Minimum Spanning Tree using Kruskal's.
- [Network Bandwidth](https://github.com/code-shoily/yog/blob/main/examples/network_bandwidth.gleam) - ⭐ Max flow for bandwidth optimization with bottleneck analysis.
- [Job Matching](https://github.com/code-shoily/yog/blob/main/examples/job_matching.gleam) - ⭐ Max flow for bipartite matching and assignment problems.
- [Cave Path Counting](https://github.com/code-shoily/yog/blob/main/examples/cave_path_counting.gleam) - Custom DFS with backtracking.
- [Task Ordering](https://github.com/code-shoily/yog/blob/main/examples/task_ordering.gleam) - Lexicographical topological sort.
- [Bridges of Königsberg](https://github.com/code-shoily/yog/blob/main/examples/bridges_of_konigsberg.gleam) - Eulerian circuit and path detection.
- [Global Minimum Cut](https://github.com/code-shoily/yog/blob/main/examples/global_min_cut.gleam) - Stoer-Wagner algorithm.
- [Job Assignment](https://github.com/code-shoily/yog/blob/main/examples/job_assignment.gleam) - Bipartite maximum matching.
- [Medical Residency](https://github.com/code-shoily/yog/blob/main/examples/medical_residency.gleam) - Stable marriage matching (Gale-Shapley algorithm).
- [City Distance Matrix](https://github.com/code-shoily/yog/blob/main/examples/city_distance_matrix.gleam) - Floyd-Warshall for all-pairs shortest paths.
- [Graph Generation Showcase](https://github.com/code-shoily/yog/blob/main/examples/graph_generation_showcase.gleam) - ⭐ All 9 classic graph patterns with statistics.
- [DOT rendering](https://github.com/code-shoily/yog/blob/main/examples/render_dot.gleam) - Exporting graphs to Graphviz format.
- [Mermaid rendering](https://github.com/code-shoily/yog/blob/main/examples/render_mermaid.gleam) - Generating Mermaid diagrams.
- [JSON rendering](https://github.com/code-shoily/yog/blob/main/examples/render_json.gleam) - Exporting graphs to JSON for web use.
- [Graph creation](https://github.com/code-shoily/yog/blob/main/examples/graph_creation.gleam) - Comprehensive guide to 10+ ways of creating graphs.

### Running Examples Locally

The examples live in the `examples/` directory. To run them with `gleam run`, create a one-time symlink that makes Gleam's module system aware of them:

```sh
ln -sf "$(pwd)/examples" src/yog/internal/examples
```

Then run any example by its module name:

```sh
gleam run -m yog/internal/examples/gps_navigation
gleam run -m yog/internal/examples/network_bandwidth
# etc.
```

> The symlink is listed in `.gitignore` and is not committed to the repository, so it won't affect CI or other contributors' environments.

## Algorithm Selection Guide

Detailed documentation for each algorithm can be found on [HexDocs](https://hexdocs.pm/yog/).

| Algorithm | Use When | Time Complexity |
| --------- | -------- | --------------- |
| **Dijkstra** | Non-negative weights, single shortest path | O((V+E) log V) |
| **A*** | Non-negative weights + good heuristic | O((V+E) log V) |
| **Bellman-Ford** | Negative weights OR cycle detection needed | O(VE) |
| **Floyd-Warshall** | All-pairs shortest paths, distance matrices | O(V³) |
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

## Benchmarking

Yog includes built-in benchmarking utilities using `gleamy/bench`. Run the example benchmark:

```bash
gleam run -m internal/bench/simple_pathfinding
```

Or use the provided script to run all benchmarks:

```bash
./run_benchmarks.sh
```

For detailed instructions on creating custom benchmarks, interpreting results, and comparing against reference implementations, see the [Benchmarking Guide](BENCHMARKING_GUIDE.md).

## AI Assistance

Parts of this project were developed with the assistance of AI coding tools. All AI-generated code has been reviewed, tested, and validated by the maintainer.

---

**Yog** - Graph algorithms for Gleam
