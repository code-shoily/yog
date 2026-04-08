# Yog 🌳

> **যোগ** • (*jōg*)
> *noun*
> 1. connection, link, union
> 2. addition, sum

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

Yog is a comprehensive graph algorithm library for Gleam, providing implementations of classic and research-grade graph algorithms with a functional API.

🔷 **[YogEx](https://github.com/code-shoily/yog_ex)** - Elixir implementation of Yog with a superset of features. | 📊 **[Gleam vs Elixir Comparison](GLEAM_ELIXIR_COMPARISON.md)** - Detailed feature comparison.

## Features

Yog provides balanced graph algorithms across multiple domains:

### Core Capabilities

**[Pathfinding & Flow](ALGORITHMS.md#pathfinding--traversal)** — Shortest paths (Dijkstra, A*, Bellman-Ford, Floyd-Warshall, Johnson's), maximum flow (Edmonds-Karp), min-cost flow (Network Simplex), min-cut (Stoer-Wagner), and implicit state-space search.

**[Network Analysis](ALGORITHMS.md#network-analysis--centrality)** — Centrality measures (PageRank, betweenness, closeness, eigenvector, Katz), community detection (Louvain, Leiden, Infomap, Walktrap), and network metrics (assortativity, diameter).

**[Connectivity & Structure](ALGORITHMS.md#connectivity--structure)** — SCCs (Tarjan/Kosaraju), bridges, articulation points, cyclicity detection, and reachability (transitive closure/reduction).

**[Graph Operations](ALGORITHMS.md#graph-transformations)** — Mapping, filtering, subgraph extraction, merge, and O(1) transpose.

**[Directed Acyclic Graphs (DAG)](ALGORITHMS.md#directed-acyclic-graphs-dag)** — Stable `Dag(n, e)` wrapper with strictly-enforced acyclicity and O(V+E) DP routines like `longest_path` (Critical Path).

### Developer Experience

**[Generators & Builders](ALGORITHMS.md#graph-generators)** — 40+ generators including classic patterns (complete, grid, trees, Platonic solids) and random models (Erdős-Rényi, Barabási-Albert, Watts-Strogatz).

**[I/O & Visualization](ALGORITHMS.md)** — Mermaid, DOT (Graphviz), and high-quality ASCII/Unicode grid rendering for terminal diagnostic.

**[Efficient Data Structures](ALGORITHMS.md)** — Built-in Pairing Heaps for priority queues, Disjoint Set (Union-Find) with path compression, and optimized two-list Queues.

**[Complete Algorithm Catalog](ALGORITHMS.md)** — See all 60+ algorithms, selection guidance, and Big-O complexities.

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

## Algorithm & Generator Catalog

Yog provides a vast library of algorithms and graph generators. See the **[Algorithm Catalog](ALGORITHMS.md)** for a complete list including time complexities and use cases.

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
