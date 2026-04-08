# Algorithm Catalog

Comprehensive guide to graph algorithms available in Yog.

## Pathfinding & Traversal

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Dijkstra** | `yog/pathfinding/dijkstra` | Non-negative weights, single shortest path | O((V+E) log V) |
| **Bidirectional Dijkstra** | `yog/pathfinding/bidirectional` | Known target, weighted graphs, ~2× faster | O((V+E) log V / 2) |
| **Bidirectional BFS** | `yog/pathfinding/bidirectional` | Known target, unweighted graphs, up to 500× faster | O(b^(d/2)) |
| **A*** | `yog/pathfinding/astar` | Non-negative weights + good heuristic | O((V+E) log V) |
| **Bellman-Ford** | `yog/pathfinding/bellman_ford` | Negative weights OR cycle detection needed | O(VE) |
| **Floyd-Warshall** | `yog/pathfinding/floyd_warshall` | All-pairs shortest paths, distance matrices | O(V³) |
| **Johnson's** | `yog/pathfinding/johnson` | All-pairs shortest paths in sparse graphs with negative weights | O(V² log V + VE) |
| **BFS/DFS** | `yog/traversal` | Unweighted graphs, exploring reachability | O(V+E) |
| **Implicit Search** | `yog/pathfinding/implicit` | Pathfinding/Traversal on on-demand graphs | O((V+E) log V) |

## Connectivity & Structure

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Tarjan's SCC** | `yog/connectivity` | Finding strongly connected components | O(V+E) |
| **Kosaraju's SCC** | `yog/connectivity` | Strongly connected components (two-pass) | O(V + E) |
| **Tarjan's Connectivity** | `yog/connectivity` | Finding bridges and articulation points | O(V+E) |
| **Stoer-Wagner** | `yog/connectivity` | Global minimum cut, graph partitioning | O(V³) |
| **Bron-Kerbosch** | `yog/connectivity` | Maximum and all maximal cliques | O(3^(n/3)) |
| **Bipartite Detection** | `yog/property/bipartite` | Checking if graph is 2-colorable | O(V+E) |
| **Cyclicity Detection** | `yog/property/cyclicity` | Finding cycles in directed/undirected graphs | O(V+E) |

## Spanning Trees & Routing

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Kruskal's MST** | `yog/mst` | Finding minimum spanning tree using Union-Find | O(E log E) |
| **Prim's MST** | `yog/mst` | Minimum spanning tree (starts from node) | O(E log V) |
| **Hierholzer** | `yog/traversal` | Eulerian paths/circuits, route planning | O(V+E) |

## Flow & Matchings

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Edmonds-Karp** | `yog/flow/max_flow` | Maximum flow, bipartite matching, network optimization | O(VE²) |
| **Gale-Shapley** | `yog/flow/matching` | Stable matching, college admissions | O(n²) |
| **Network Simplex** | `yog/flow/min_cost` | Global minimum cost flow optimization | O(E) pivots |

## Network Analysis & Centrality

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **PageRank** | `yog/centrality` | Link-quality node importance | O(V+E) per iter |
| **Betweenness** | `yog/centrality` | Bridge/gatekeeper detection | O(VE) or O(V³) |
| **Closeness / Harmonic** | `yog/centrality` | Distance-based importance | O(VE log V) |
| **Eigenvector / Katz** | `yog/centrality` | Influence based on neighbor centrality | O(V+E) per iter |

## Community Detection

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Louvain** | `yog/community` | Modularity optimization, large graphs | O(E log V) |
| **Leiden** | `yog/community` | Quality guarantee, well-connected communities | O(E log V) |
| **Label Propagation** | `yog/community` | Very large graphs, extreme speed | O(E) per iter |
| **Infomap** | `yog/community` | Information-theoretic flow tracking | O(E) per iter |
| **Walktrap** | `yog/community` | Random-walk structural communities | O(V² log V) |
| **Girvan-Newman** | `yog/community` | Hierarchical edge betweenness | O(E²V) |
| **Clique Percolation** | `yog/community` | Overlapping community discovery | O(3^(V/3)) |
| **Fluid Communities** | `yog/community` | Exact `k` partitions, fast | O(E) per iter |

## Directed Acyclic Graphs (DAG)

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **Topological Sort** | `yog/traversal` | Ordering tasks with dependencies | O(V+E) |
| **DAG Longest Path** | `yog/dag/algorithm` | Critical path analysis | O(V+E) |
| **Transitive Closure** | `yog/transform` | Reachability matrix (fast for DAGs) | O(VE) |
| **Transitive Reduction** | `yog/transform` | Minimal edge set (fast for DAGs) | O(VE) |
| **Lowest Common Ancestor** | `yog/dag/algorithm` | Version control merge bases | O(V(V+E)) |

---

For detailed API documentation, visit [HexDocs](https://hexdocs.pm/yog/).
