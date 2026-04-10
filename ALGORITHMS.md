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

## Unweighted Pathfinding

Specialized BFS-based algorithms for graphs with uniform edge weights (hop counting).

| Algorithm | Module | Use When | Time Complexity |
| --------- | ------ | -------- | --------------- |
| **BFS Shortest Path** | `yog/pathfinding/unweighted` | Single-pair shortest path by hops | O(V + E) |
| **Single-Source Distances** | `yog/pathfinding/unweighted` | Distances from one node to all others | O(V + E) |
| **All-Pairs Shortest Paths** | `yog/pathfinding/unweighted` | All-pairs hop distances | O(V(V + E)) |

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

## Graph Generators (Classic)

Deterministic generators for well-known graph structures. Module: `yog/generator/classic`

| Generator | Graph | Edges | Description |
|-----------|-------|-------|-------------|
| `complete(n)` | K_n | n(n-1)/2 | Every node connects to every other |
| `cycle(n)` | C_n | n | Nodes form a ring |
| `path(n)` | P_n | n-1 | Linear chain of nodes |
| `star(n)` | S_n | n-1 | One central hub node |
| `wheel(n)` | W_n | 2(n-1) | Cycle with central hub |
| `grid_2d(r, c)` | Lattice | (r-1)c + r(c-1) | 2D rectangular mesh |
| `complete_bipartite(m, n)` | K_{m,n} | mn | Complete bipartite graph |
| `binary_tree(d)` | Tree | 2^(d+1)-2 | Complete binary tree of depth d |
| `kary_tree(d, arity: k)` | Tree | (k^(d+1)-1)/(k-1)-1 | Complete k-ary tree |
| `complete_kary(n, arity: k)` | Tree | n-1 | Complete m-ary tree with n nodes |
| `caterpillar(n, spine_length: s)` | Tree | n-1 | Tree with central path |
| `petersen()` | Petersen | 15 | Famous 10-node, 15-edge graph |
| `hypercube(n)` | Q_n | n × 2^(n-1) | n-dimensional hypercube |
| `ladder(n)` | Ladder | 3n - 2 | Two parallel paths with rungs |
| `circular_ladder(n)` | Prism | 3n | Cycle × edge (Cartesian product) |
| `mobius_ladder(n)` | Möbius | 3n | Circular ladder with half-twist |
| `friendship(n)` | Windmill | 3n | n triangles sharing a vertex |
| `windmill(n, clique_size: k)` | Windmill | n × k(k-1)/2 | n copies of K_k sharing a vertex |
| `book(n)` | Book | 2n + 1 | n triangles sharing an edge |
| `crown(n)` | Crown | n(n-1) | K_{n,n} minus perfect matching |
| `turan(n, r)` | T(n,r) | Varies | Complete r-partite graph |
| `tetrahedron()` | Platonic | 6 | K_4 (complete graph on 4 vertices) |
| `cube()` | Platonic | 12 | 3D hypercube (Q_3) |
| `octahedron()` | Platonic | 12 | Dual of cube |
| `dodecahedron()` | Platonic | 30 | 20 vertices, girth 5 |
| `icosahedron()` | Platonic | 30 | Dual of dodecahedron |
| `empty(n)` | Isolated | 0 | n nodes with no edges |

## Graph Generators (Random)

Stochastic generators for modeling real-world networks. Module: `yog/generator/random`

| Generator | Model | Time | Key Property |
|-----------|-------|------|--------------|
| `erdos_renyi_gnp(n, p)` | G(n, p) | O(n²) | Each edge with probability p |
| `erdos_renyi_gnm(n, m)` | G(n, m) | O(m) | Exactly m random edges |
| `barabasi_albert(n, m)` | Preferential | O(nm) | Scale-free (power-law degrees) |
| `watts_strogatz(n, k, p)` | Small-world | O(nk) | High clustering + short paths |
| `random_tree(n)` | Uniform tree | O(n²) | Uniformly random spanning tree |
| `random_regular(n, d)` | d-regular | O(nd) | All nodes have degree d |
| `sbm(n, k, p_in, p_out)` | SBM | O(n²) | Community structure |
| `dcsbm(n, k, p_in, p_out, thetas)` | DCSBM | O(n²) | Community + degree control |
| `hsbm(n, levels, branching, p_in, p_out)` | Hierarchical | O(n²) | Nested community structure |
| `configuration_model(degrees)` | Fixed Degree | O(M) | Exact degree sequence |
| `rmat(n, m, probs)` | R-MAT | O(m log n) | Fast Kronecker variant |
| `kronecker(k, initiator, m)` | Kronecker | O(m log n) | Recursive matrix expansion |
| `geometric(n, radius)` | RGG | O(n²) | Distance-based edges |

## Maze Generators

Perfect maze generation algorithms (spanning trees on grids). Module: `yog/generator/maze`

| Algorithm | Time | Bias | Best For |
|-----------|------|------|----------|
| `binary_tree(rows, cols)` | O(N) | Diagonal | Simplest, fastest generation |
| `sidewinder(rows, cols)` | O(N) | Vertical | Memory-constrained environments |
| `recursive_backtracker(rows, cols)` | O(N) | Corridors | Games, roguelikes (most popular) |
| `hunt_and_kill(rows, cols)` | O(V²) | Winding | Fewer dead ends |
| `aldous_broder(rows, cols)` | O(V²) | None | Uniform randomness |
| `wilson(rows, cols)` | O(N) avg | None | Efficient uniform spanning tree |
| `kruskal(rows, cols)` | O(N log N) | None | Balanced corridors |
| `prim_simplified(rows, cols)` | O(N log N) | Radial | Many dead ends |
| `prim_true(rows, cols)` | O(N log N) | Jigsaw | Dense texture |
| `ellers(rows, cols)` | O(N) | Horizontal | Infinite height mazes |
| `growing_tree(rows, cols, selector)` | O(N) | Varies | Versatile (simulates others) |
| `recursive_division(rows, cols)` | O(N log N) | Rectangular | Rooms, fractal feel |

*All maze generators return a `yog/builder/grid.Grid` that can be rendered or converted to a graph.*

## Graph Builders

Utilities for constructing graphs from common data structures.

| Builder | Module | Use When | Time Complexity |
|---------|--------|----------|---------------|
| **Grid from 2D List** | `yog/builder/grid` | Heightmaps, game boards, mazes | O(rows × cols) |
| **Grid with Custom Topology** | `yog/builder/grid` | 4-way, 8-way, or custom movement | O(rows × cols) |
| **Labeled Graph Builder** | `yog/builder/labeled` | String-labeled nodes | O(V + E) |
| **Live Graph (Dynamic)** | `yog/builder/live` | Incremental graph construction | O(1) per op |
| **Toroidal Grid** | `yog/builder/toroidal` | Wraparound edges | O(rows × cols) |

## Rendering & Visualization

Export and display graphs in various formats.

| Renderer | Module | Output | Use Case |
|----------|--------|--------|----------|
| **ASCII Grid** | `yog/render/ascii` | Terminal text | Mazes, grids, debugging |
| **DOT Format** | `yog/render/dot` | Graphviz | Publication-quality diagrams |
| **Mermaid** | `yog/render/mermaid` | Markdown diagrams | Documentation, READMEs |

## Data Structures

Specialized data structures used by Yog algorithms.

| Structure | Module | Use Case | Time Complexity |
|-----------|--------|----------|---------------|
| **Pairing Heap** | `yog/internal/pairing_heap` | Priority queue operations | O(1) find-min, O(log n) delete |
| **Disjoint Set** | `yog/disjoint_set` | Union-Find, Kruskal's MST | O(α(n)) per operation |
| **Two-List Queue** | `yog/internal/queue` | BFS, level-order traversal | O(1) push/pop |
| **Priority Queue** | `yog/internal/priority_queue` | Dijkstra, A*, Prim's | O(log n) push/pop |

---

For detailed API documentation, visit [HexDocs](https://hexdocs.pm/yog/).
