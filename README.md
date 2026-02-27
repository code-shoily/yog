# Yog 🌳

[![Package Version](https://img.shields.io/hexpm/v/yog)](https://hex.pm/packages/yog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yog/)

A graph algorithm library for Gleam, providing implementations of classic graph algorithms with a functional API.

## Features

- **Graph Data Structures**: Directed and undirected graphs with generic node and edge data
- **Pathfinding Algorithms**: Dijkstra, A*, Bellman-Ford, Floyd-Warshall
- **Maximum Flow**: Highly optimized Edmonds-Karp algorithm with flat dictionary residuals
- **Graph Generators**: Create classic patterns (complete, cycle, path, star, wheel, bipartite, trees, grids, Petersen)
- **Graph Traversal**: BFS and DFS with early termination support
- **Graph Transformations**: Transpose (O(1)!), map, filter, merge, subgraph extraction, edge contraction
- **Graph Visualization**: Mermaid, DOT (Graphviz), and JSON rendering
- **Minimum Spanning Tree**: Kruskal's algorithm with Union-Find
- **Minimum Cut**: Stoer-Wagner algorithm for global min-cut
- **Topological Sorting**: Kahn's algorithm with lexicographical variant
- **Strongly Connected Components**: Tarjan's algorithm
- **Connectivity**: Bridge and articulation point detection
- **Eulerian Paths & Circuits**: Detection and finding using Hierholzer's algorithm
- **Bipartite Graphs**: Detection and maximum matching
- **Disjoint Set (Union-Find)**: With path compression and union by rank
- **Efficient Data Structures**: Pairing heap for priority queues, two-list queue for BFS

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
import yog/pathfinding

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
  case pathfinding.shortest_path(
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

Detailed examples are located in the [examples/](https://github.com/code-shoily/yog/tree/main/examples) directory:

- [Social Network Analysis](examples/social_network_analysis.gleam) - Finding communities using SCCs.
- [Task Scheduling](examples/task_scheduling.gleam) - Basic topological sorting.
- [GPS Navigation](examples/gps_navigation.gleam) - Shortest path using A* and heuristics.
- [Network Cable Layout](examples/network_cable_layout.gleam) - Minimum Spanning Tree using Kruskal's.
- [Network Bandwidth](examples/network_bandwidth.gleam) - ⭐ Max flow for bandwidth optimization with bottleneck analysis.
- [Job Matching](examples/job_matching.gleam) - ⭐ Max flow for bipartite matching and assignment problems.
- [Cave Path Counting](examples/cave_path_counting.gleam) - Custom DFS with backtracking.
- [Task Ordering](examples/task_ordering.gleam) - Lexicographical topological sort.
- [Bridges of Königsberg](examples/bridges_of_konigsberg.gleam) - Eulerian circuit and path detection.
- [Global Minimum Cut](examples/global_min_cut.gleam) - Stoer-Wagner algorithm.
- [Job Assignment](examples/job_assignment.gleam) - Bipartite maximum matching.
- [City Distance Matrix](examples/city_distance_matrix.gleam) - Floyd-Warshall for all-pairs shortest paths.
- [Graph Generation Showcase](examples/graph_generation_showcase.gleam) - ⭐ All 9 classic graph patterns with statistics.
- [DOT rendering](examples/render_dot.gleam) - Exporting graphs to Graphviz format.
- [Mermaid rendering](examples/render_mermaid.gleam) - Generating Mermaid diagrams.
- [JSON rendering](examples/render_json.gleam) - Exporting graphs to JSON for web use.
- [Graph creation](examples/graph_creation.gleam) - Comprehensive guide to 10+ ways of creating graphs.

## Algorithm Selection Guide

Detailed documentation for each algorithm can be found on [HexDocs](https://hexdocs.pm/yog/).

| Algorithm | Use When | Time Complexity |
| ----------- | ---------- | ---------------- |
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
| **Topological Sort** | Ordering tasks with dependencies | O(V+E) |

## Performance Characteristics

- **Graph storage**: O(V + E)
- **Transpose**: O(1) - dramatically faster than typical O(E) implementations
- **Dijkstra/A***: O(V) for visited set and pairing heap
- **Maximum Flow**: Flat dictionary residuals with O(1) amortized BFS queue operations
- **Graph Generators**: O(V²) for complete graphs, O(V) or O(VE) for others
- **Test Suite**: 568 tests pass in ~2 seconds

---

**Yog** - Graph algorithms for Gleam 🌳
