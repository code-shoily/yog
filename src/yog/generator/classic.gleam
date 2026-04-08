//// Deterministic graph generators for common graph structures.
////
//// Deterministic generators produce identical graphs given the same parameters,
//// useful for testing algorithms, benchmarking, and creating known structures.
////
//// ## Available Generators
////
//// | Generator | Graph Type | Complexity | Edges |
//// |-----------|------------|------------|-------|
//// | `complete` | K_n | O(n²) | n(n-1)/2 |
//// | `cycle` | C_n | O(n) | n |
//// | `path` | P_n | O(n) | n-1 |
//// | `star` | S_n | O(n) | n-1 |
//// | `wheel` | W_n | O(n) | 2(n-1) |
//// | `grid_2d` | Lattice | O(mn) | (m-1)n + m(n-1) |
//// | `complete_bipartite` | K_{m,n} | O(mn) | mn |
//// | `binary_tree` | Tree | O(2^d) | 2^(d+1) - 2 |
//// | `kary_tree` | Tree | O(k^d) | (k^(d+1)-1)/(k-1) - 1 |
//// | `complete_kary` | Tree | O(n) | n-1 |
//// | `caterpillar` | Tree | O(n) | n-1 |
//// | `petersen` | Petersen | O(1) | 15 |
//// | `empty` | Isolated | O(n) | 0 |
//// | `hypercube` | Q_n | O(n × 2^n) | n × 2^(n-1) |
//// | `ladder` | Ladder | O(n) | 3n - 2 |
//// | `circular_ladder` | Prism | O(n) | 3n |
//// | `mobius_ladder` | Möbius | O(n) | 3n |
//// | `friendship` | Windmill | O(n) | 3n |
//// | `windmill` | Windmill | O(nk²) | n × k(k-1)/2 |
//// | `book` | Book | O(n) | 2n + 1 |
//// | `crown` | Crown | O(n²) | n(n-1) |
//// | `turan` | T(n,r) | O(n²) | Complete r-partite |
//// | `tetrahedron` | Platonic | O(1) | 6 |
//// | `cube` | Platonic | O(1) | 12 |
//// | `octahedron` | Platonic | O(1) | 12 |
//// | `dodecahedron` | Platonic | O(1) | 30 |
//// | `icosahedron` | Platonic | O(1) | 30 |
////
//// ## Quick Start
////
//// ```gleam
//// import yog/generator/classic
//// import yog/model
////
//// pub fn main() {
////   // Classic structures
////   let cycle = classic.cycle(5)                    // C5 cycle graph
////   let complete = classic.complete(4)              // K4 complete graph
////   let grid = classic.grid_2d(3, 4)                // 3x4 lattice mesh
////   let tree = classic.binary_tree(3)               // Depth-3 binary tree
////   let bipartite = classic.complete_bipartite(3, 4) // K_{3,4}
////   let petersen = classic.petersen()               // Famous Petersen graph
////   let hypercube = classic.hypercube(4)            // 4D hypercube (Q4)
////   let ladder = classic.ladder(5)                  // 5-rung ladder
//// }
//// ```
////
//// ## Use Cases
////
//// - **Algorithm testing**: Verify correctness on known structures
//// - **Benchmarking**: Compare performance across standard graphs
//// - **Network modeling**: Represent specific topologies (star, grid, tree)
//// - **Graph theory**: Study properties of well-known graphs
////
//// ## References
////
//// - [Wikipedia: Graph Generators](https://en.wikipedia.org/wiki/Graph_theory#Graph_generators)
//// - [Complete Graph](https://en.wikipedia.org/wiki/Complete_graph)
//// - [Cycle Graph](https://en.wikipedia.org/wiki/Cycle_graph)
//// - [Petersen Graph](https://en.wikipedia.org/wiki/Petersen_graph)
//// - [NetworkX Generators](https://networkx.org/documentation/stable/reference/generators.html)

import gleam/int
import gleam/list
import yog/internal/utils
import yog/model.{type Graph, type GraphType}

/// Generates a complete graph K_n where every node connects to every other.
///
/// In a complete graph with n nodes, there are n(n-1)/2 edges for undirected
/// graphs and n(n-1) edges for directed graphs. All edges have unit weight (1).
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// let k5 = classic.complete(5)
/// // K5 has 5 nodes and 10 edges
/// ```
///
/// ## Use Cases
///
/// - Testing algorithms on dense graphs
/// - Maximum connectivity scenarios
/// - Clique detection benchmarks
pub fn complete(n: Int) -> Graph(Nil, Int) {
  complete_with_type(n, model.Undirected)
}

/// Generates a complete graph with specified graph type.
///
/// ## Example
///
/// ```gleam
/// let directed_k4 = classic.complete_with_type(4, model.Directed)
/// ```
pub fn complete_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      case graph_type {
        model.Undirected -> {
          // For undirected, only add edge once between each pair
          utils.range(0, n - 1)
          |> list.fold(graph, fn(g, i) {
            utils.range(i + 1, n - 1)
            |> list.fold(g, fn(acc, j) {
              model.add_edge_ensure(acc, from: i, to: j, with: 1, default: Nil)
            })
          })
        }
        model.Directed -> {
          // For directed, add edge from every node to every other node
          utils.range(0, n - 1)
          |> list.fold(graph, fn(g, i) {
            utils.range(0, n - 1)
            |> list.fold(g, fn(acc, j) {
              case i == j {
                True -> acc
                // No self-loops
                False ->
                  model.add_edge_ensure(
                    acc,
                    from: i,
                    to: j,
                    with: 1,
                    default: Nil,
                  )
              }
            })
          })
        }
      }
    }
  }
}

/// Generates a cycle graph C_n where nodes form a ring.
///
/// A cycle graph connects n nodes in a circular pattern:
/// 0 -> 1 -> 2 -> ... -> (n-1) -> 0. Each node has degree 2.
///
/// Returns an empty graph if n < 3 (cycles require at least 3 nodes).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let c6 = classic.cycle(6)
/// // C6: 0-1-2-3-4-5-0 (a hexagon)
/// ```
///
/// ## Use Cases
///
/// - Ring network topologies
/// - Circular dependency testing
/// - Hamiltonian cycle benchmarks
pub fn cycle(n: Int) -> Graph(Nil, Int) {
  cycle_with_type(n, model.Undirected)
}

/// Generates a cycle graph with specified graph type.
pub fn cycle_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 3 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      // Add edges in a cycle
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        let next = case i == n - 1 {
          True -> 0
          False -> i + 1
        }
        model.add_edge_ensure(g, from: i, to: next, with: 1, default: Nil)
      })
    }
  }
}

/// Generates a path graph P_n where nodes form a linear chain.
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let p5 = classic.path(5)
/// ```
pub fn path(n: Int) -> Graph(Nil, Int) {
  path_with_type(n, model.Undirected)
}

/// Generates a path graph with specified graph type.
pub fn path_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      case n < 2 {
        True -> graph
        False -> {
          // Add edges in a line
          utils.range(0, n - 2)
          |> list.fold(graph, fn(g, i) {
            model.add_edge_ensure(g, from: i, to: i + 1, with: 1, default: Nil)
          })
        }
      }
    }
  }
}

/// Generates a star graph where one central node is connected to all others.
///
/// Node 0 is the center, connected to nodes 1 through n-1. All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let s6 = classic.star(6)
/// ```
pub fn star(n: Int) -> Graph(Nil, Int) {
  star_with_type(n, model.Undirected)
}

/// Generates a star graph with specified graph type.
pub fn star_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      case n < 2 {
        True -> graph
        False -> {
          // Connect center (0) to all other nodes
          utils.range(1, n - 1)
          |> list.fold(graph, fn(g, i) {
            model.add_edge_ensure(g, from: 0, to: i, with: 1, default: Nil)
          })
        }
      }
    }
  }
}

/// Generates a wheel graph: a cycle with a central hub.
///
/// A wheel graph combines a star and a cycle: node 0 is the hub,
/// and nodes 1..(n-1) form a cycle.
///
/// Returns an empty graph if n < 4 (wheels require at least 4 nodes).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let w6 = classic.wheel(6)
/// // W6: hub 0 connected to cycle 1-2-3-4-5-1
/// ```
///
/// ## Use Cases
///
/// - Hybrid network topologies
/// - Fault-tolerant network design
/// - Routing algorithm benchmarks
pub fn wheel(n: Int) -> Graph(Nil, Int) {
  wheel_with_type(n, model.Undirected)
}

/// Generates a wheel graph with specified graph type.
pub fn wheel_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 4 {
    True -> model.new(graph_type)
    False -> {
      // Start with a star (center to all)
      let with_star = star_with_type(n, graph_type)

      // Add cycle edges around the rim
      utils.range(1, n - 1)
      |> list.fold(with_star, fn(g, i) {
        let next = case i == n - 1 {
          True -> 1
          False -> i + 1
        }
        model.add_edge_ensure(g, from: i, to: next, with: 1, default: Nil)
      })
    }
  }
}

/// Generates a complete bipartite graph K_{m,n}.
///
/// A complete bipartite graph has two disjoint sets of nodes (left and right partitions),
/// where every node in the left partition connects to every node in the right partition.
/// Left partition: nodes 0..(m-1), Right partition: nodes m..(m+n-1).
///
/// **Time Complexity:** O(mn)
///
/// ## Example
///
/// ```gleam
/// let k33 = classic.complete_bipartite(3, 3)
/// // K_{3,3}: 3 nodes in each partition, 9 edges
/// ```
///
/// ## Use Cases
///
/// - Matching problems (job assignment, pairing)
/// - Bipartite graph algorithms
/// - Network flow modeling
pub fn complete_bipartite(m: Int, n: Int) -> Graph(Nil, Int) {
  complete_bipartite_with_type(m, n, model.Undirected)
}

/// Generates a complete bipartite graph with specified graph type.
pub fn complete_bipartite_with_type(
  m: Int,
  n: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case m < 0 || n < 0 {
    True -> model.new(graph_type)
    False -> {
      let total = m + n
      let graph = create_nodes(model.new(graph_type), total)

      // Connect every node in left partition to every node in right partition
      utils.range(0, m - 1)
      |> list.fold(graph, fn(g, left) {
        utils.range(m, total - 1)
        |> list.fold(g, fn(acc, right) {
          model.add_edge_ensure(
            acc,
            from: left,
            to: right,
            with: 1,
            default: Nil,
          )
        })
      })
    }
  }
}

/// Generates an empty graph with n nodes and no edges.
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let empty = classic.empty(10)
/// ```
pub fn empty(n: Int) -> Graph(Nil, Int) {
  empty_with_type(n, model.Undirected)
}

/// Generates an empty graph with specified graph type.
pub fn empty_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> create_nodes(model.new(graph_type), n)
  }
}

/// Generates a complete binary tree of given depth.
///
/// Node 0 is the root. For node i: left child is 2i+1, right child is 2i+2.
/// Total nodes: 2^(depth+1) - 1. All edges have unit weight (1).
///
/// **Time Complexity:** O(2^depth)
///
/// ## Example
///
/// ```gleam
/// let tree = classic.binary_tree(3)
/// // Complete binary tree with depth 3, total 15 nodes
/// ```
///
/// ## Use Cases
///
/// - Hierarchical structures
/// - Binary search tree modeling
/// - Heap data structure visualization
/// - Tournament brackets
pub fn binary_tree(depth: Int) -> Graph(Nil, Int) {
  binary_tree_with_type(depth, model.Undirected)
}

/// Generates a complete binary tree with specified graph type.
pub fn binary_tree_with_type(
  depth: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  kary_tree_with_type(depth, 2, graph_type)
}

/// Generates a complete k-ary tree of given depth.
///
/// A complete k-ary tree where each node has exactly k children (except leaves).
/// Total nodes = (k^(depth+1) - 1) / (k - 1) for k > 1.
/// For k = 1, this is a path with depth+1 nodes.
///
/// ## Options
/// - `depth` - The depth of the tree (root is at depth 0)
/// - `arity` - The branching factor k (default: 2, binary tree)
///
/// ## Example
///
/// ```gleam
/// // Ternary tree (arity 3) of depth 2
/// let tree = classic.kary_tree(2, arity: 3)
/// // 1 + 3 + 9 = 13 nodes
/// ```
///
/// ## Properties
///
/// - Node i has parent at (i-1)/k
/// - Node i has children at k*i+1 through k*i+k
pub fn kary_tree(depth: Int, arity k: Int) -> Graph(Nil, Int) {
  kary_tree_with_type(depth, k, model.Undirected)
}

/// Generates a k-ary tree with specified graph type.
pub fn kary_tree_with_type(
  depth: Int,
  arity: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case depth < 0 || arity < 1 {
    True -> model.new(graph_type)
    False -> {
      case arity == 1 {
        // k=1 is a path
        True -> path_with_type(depth + 1, graph_type)
        False -> {
          // Total nodes: (arity^(depth+1) - 1) / (arity - 1)
          let total_nodes = { power(arity, depth + 1) - 1 } / { arity - 1 }
          let graph = create_nodes(model.new(graph_type), total_nodes)

          // Number of non-leaf nodes: (arity^depth - 1) / (arity - 1)
          let non_leaf_count = { power(arity, depth) - 1 } / { arity - 1 }

          // For each non-leaf node, add edges to its k children
          utils.range(0, non_leaf_count - 1)
          |> list.fold(graph, fn(g, i) {
            let child_start = arity * i + 1
            let child_end = arity * i + arity
            utils.range(child_start, int.min(child_end, total_nodes - 1))
            |> list.fold(g, fn(acc, child) {
              model.add_edge_ensure(
                acc,
                from: i,
                to: child,
                with: 1,
                default: Nil,
              )
            })
          })
        }
      }
    }
  }
}

/// Generates a complete m-ary tree with exactly n nodes.
///
/// Creates a tree that is as complete as possible - all levels are fully
/// filled except possibly the last, which is filled from left to right.
///
/// ## Options
/// - `n` - Number of nodes
/// - `arity` - Branching factor (default: 2)
///
/// ## Example
///
/// ```gleam
/// let tree = classic.complete_kary(20, arity: 3)
/// // Complete 3-ary tree with 20 nodes
/// ```
pub fn complete_kary(n: Int, arity k: Int) -> Graph(Nil, Int) {
  complete_kary_with_type(n, k, model.Undirected)
}

/// Generates a complete m-ary tree with specified graph type.
pub fn complete_kary_with_type(
  n: Int,
  arity: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n <= 0 || arity < 1 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      case n <= 1 {
        True -> graph
        False -> {
          // For node i, children are at k*i+1 to k*i+k, if they exist
          utils.range(0, n - 2)
          |> list.fold(graph, fn(g, i) {
            let child_start = arity * i + 1
            let child_end = int.min(arity * i + arity, n - 1)
            case child_start <= child_end {
              True ->
                utils.range(child_start, child_end)
                |> list.fold(g, fn(acc, child) {
                  model.add_edge_ensure(
                    acc,
                    from: i,
                    to: child,
                    with: 1,
                    default: Nil,
                  )
                })
              False -> g
            }
          })
        }
      }
    }
  }
}

/// Generates a caterpillar tree.
///
/// A caterpillar is a tree where removing all leaves leaves a path (the "spine").
///
/// ## Options
/// - `n` - Total number of nodes
/// - `spine_length` - Length of central path (default: max(1, n/3))
///
/// ## Example
///
/// ```gleam
/// let cat = classic.caterpillar(20, spine_length: 5)
/// // Caterpillar with 20 nodes, 5 nodes on spine
/// ```
///
/// ## Properties
///
/// - All vertices are within distance 1 of the central path
/// - Interpolates between paths (spine_length = n) and stars (spine_length = 1)
pub fn caterpillar(n: Int, spine_length spine_len: Int) -> Graph(Nil, Int) {
  caterpillar_with_type(n, spine_len, model.Undirected)
}

/// Generates a caterpillar tree with specified graph type.
pub fn caterpillar_with_type(
  n: Int,
  spine_length: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> {
      case n == 1 {
        True -> create_nodes(model.new(graph_type), 1)
        False -> {
          let spine_len = int.min(spine_length, n)
          let leaf_count = n - spine_len

          let graph = create_nodes(model.new(graph_type), n)

          // Create spine path (nodes 0 to spine_len-1)
          let graph_with_spine = case spine_len >= 2 {
            True ->
              utils.range(0, spine_len - 2)
              |> list.fold(graph, fn(g, i) {
                model.add_edge_ensure(
                  g,
                  from: i,
                  to: i + 1,
                  with: 1,
                  default: Nil,
                )
              })
            False -> graph
          }

          // Distribute leaves evenly across spine nodes
          // Leaves are numbered from spine_len to n-1
          let leaves_per_spine = leaf_count / spine_len
          let extra_leaves = leaf_count % spine_len

          let #(_, _, graph_with_leaves) =
            utils.range(0, spine_len - 1)
            |> list.fold(
              #(spine_len, 0, graph_with_spine),
              fn(state, spine_idx) {
                let #(next_leaf, extra_used, g) = state
                let num_leaves =
                  leaves_per_spine
                  + case spine_idx < extra_leaves {
                    True -> 1
                    False -> 0
                  }

                let new_g = case num_leaves > 0 {
                  True ->
                    utils.range(0, num_leaves - 1)
                    |> list.fold(g, fn(acc, i) {
                      model.add_edge_ensure(
                        acc,
                        from: spine_idx,
                        to: next_leaf + i,
                        with: 1,
                        default: Nil,
                      )
                    })
                  False -> g
                }
                #(next_leaf + num_leaves, extra_used, new_g)
              },
            )

          graph_with_leaves
        }
      }
    }
  }
}

/// Generates a 2D grid graph (lattice).
///
/// Creates a rectangular grid where each node is connected to its
/// orthogonal neighbors (up, down, left, right). Nodes are numbered
/// row by row: node at (r, c) has ID = r * cols + c.
///
/// **Time Complexity:** O(rows * cols)
///
/// ## Example
///
/// ```gleam
/// let grid = classic.grid_2d(3, 4)
/// // 3x4 grid with 12 nodes
/// // Node numbering: 0-1-2-3
/// //                 | | | |
/// //                 4-5-6-7
/// //                 | | | |
/// //                 8-9-10-11
/// ```
///
/// ## Use Cases
///
/// - Mesh network topologies
/// - Spatial/grid-based algorithms
/// - Image processing graph models
/// - Game board representations
pub fn grid_2d(rows: Int, cols: Int) -> Graph(Nil, Int) {
  grid_2d_with_type(rows, cols, model.Undirected)
}

/// Generates a 2D grid graph with specified graph type.
pub fn grid_2d_with_type(
  rows: Int,
  cols: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case rows <= 0 || cols <= 0 {
    True -> model.new(graph_type)
    False -> {
      let n = rows * cols
      let graph = create_nodes(model.new(graph_type), n)

      // Add horizontal edges
      let with_horizontal =
        utils.range(0, rows - 1)
        |> list.fold(graph, fn(g, row) {
          utils.range(0, cols - 2)
          |> list.fold(g, fn(acc, col) {
            let node = row * cols + col
            model.add_edge_ensure(
              acc,
              from: node,
              to: node + 1,
              with: 1,
              default: Nil,
            )
          })
        })

      // Add vertical edges
      utils.range(0, rows - 2)
      |> list.fold(with_horizontal, fn(g, row) {
        utils.range(0, cols - 1)
        |> list.fold(g, fn(acc, col) {
          let node = row * cols + col
          let below = node + cols
          model.add_edge_ensure(
            acc,
            from: node,
            to: below,
            with: 1,
            default: Nil,
          )
        })
      })
    }
  }
}

/// Generates the Petersen graph.
///
/// The [Petersen graph](https://en.wikipedia.org/wiki/Petersen_graph) is a famous
/// undirected graph with 10 nodes and 15 edges. It is often used as a counterexample
/// in graph theory due to its unique properties.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let petersen = classic.petersen()
/// // 10 nodes, 15 edges
/// ```
///
/// ## Properties
///
/// - 3-regular (every node has degree 3)
/// - Diameter 2
/// - Not planar
/// - Not Hamiltonian
///
/// ## Use Cases
///
/// - Graph theory counterexamples
/// - Algorithm testing
/// - Theoretical research
pub fn petersen() -> Graph(Nil, Int) {
  petersen_with_type(model.Undirected)
}

/// Generates a Petersen graph with specified graph type.
pub fn petersen_with_type(graph_type: GraphType) -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(graph_type), 10)

  // Outer pentagon: 0-1-2-3-4-0
  let with_outer =
    graph
    |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 4, to: 0, with: 1, default: Nil)

  // Inner pentagram: 5-7-9-6-8-5
  let with_inner =
    with_outer
    |> model.add_edge_ensure(from: 5, to: 7, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 7, to: 9, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 9, to: 6, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 6, to: 8, with: 1, default: Nil)
    |> model.add_edge_ensure(from: 8, to: 5, with: 1, default: Nil)

  // Connect outer to inner (spokes)
  with_inner
  |> model.add_edge_ensure(from: 0, to: 5, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 1, to: 6, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 2, to: 7, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 3, to: 8, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 4, to: 9, with: 1, default: Nil)
}

/// Generates an n-dimensional hypercube graph Q_n.
///
/// The hypercube is a classic topology where each node represents a binary
/// string of length n, and edges connect nodes that differ in exactly one bit.
///
/// **Properties:**
/// - Nodes: 2^n
/// - Edges: n × 2^(n-1)
/// - Regular degree: n
/// - Diameter: n
/// - Bipartite: yes
///
/// **Time Complexity:** O(n × 2^n)
///
/// ## Example
///
/// ```gleam
/// let cube = classic.hypercube(3)
/// // 3-cube has 8 nodes, each with degree 3
/// ```
///
/// ## Use Cases
///
/// - Distributed systems and parallel computing topologies
/// - Error-correcting codes
/// - Testing algorithms on regular, bipartite structures
/// - Gray code applications
pub fn hypercube(n: Int) -> Graph(Nil, Int) {
  hypercube_with_type(n, model.Undirected)
}

/// Generates a hypercube graph with specified graph type.
pub fn hypercube_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 0 {
    True -> model.new(graph_type)
    False -> {
      case n == 0 {
        True -> create_nodes(model.new(graph_type), 1)
        False -> {
          let num_nodes = power(2, n)
          let graph = create_nodes(model.new(graph_type), num_nodes)

          // Add edges: connect nodes that differ by exactly one bit
          utils.range(0, num_nodes - 1)
          |> list.fold(graph, fn(g, i) {
            utils.range(0, n - 1)
            |> list.fold(g, fn(acc, bit) {
              let j = int.bitwise_exclusive_or(i, power(2, bit))
              // Avoid duplicates for undirected
              case i < j {
                True ->
                  model.add_edge_ensure(
                    acc,
                    from: i,
                    to: j,
                    with: 1,
                    default: Nil,
                  )
                False -> acc
              }
            })
          })
        }
      }
    }
  }
}

/// Generates a ladder graph with n rungs.
///
/// A ladder graph consists of two parallel paths (rails) connected by n rungs.
/// It is the Cartesian product of a path P_n and an edge K_2.
///
/// **Properties:**
/// - Nodes: 2n
/// - Edges: 3n - 2
/// - Planar: yes
/// - Equivalent to grid_2d(2, n)
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let ladder = classic.ladder(4)
/// // 4-rung ladder has 8 nodes
/// ```
///
/// ## Use Cases
///
/// - Basic network topologies
/// - DNA and molecular structure modeling
/// - Pathfinding benchmarks
pub fn ladder(n: Int) -> Graph(Nil, Int) {
  ladder_with_type(n, model.Undirected)
}

/// Generates a ladder graph with specified graph type.
pub fn ladder_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 {
    True -> model.new(graph_type)
    False -> {
      // Nodes 0..n-1 are the bottom rail, n..2n-1 are the top rail
      let graph = create_nodes(model.new(graph_type), 2 * n)

      // Bottom rail edges: (i, i+1) for i in 0..n-2
      let bottom_edges = case n >= 2 {
        True ->
          utils.range(0, n - 2)
          |> list.fold(graph, fn(g, i) {
            model.add_edge_ensure(g, from: i, to: i + 1, with: 1, default: Nil)
          })
        False -> graph
      }

      // Top rail edges: (i, i+1) for i in n..2n-2
      let top_edges = case n >= 2 {
        True ->
          utils.range(n, 2 * n - 2)
          |> list.fold(bottom_edges, fn(g, i) {
            model.add_edge_ensure(g, from: i, to: i + 1, with: 1, default: Nil)
          })
        False -> bottom_edges
      }

      // Rung edges: (i, i+n) for i in 0..n-1
      utils.range(0, n - 1)
      |> list.fold(top_edges, fn(g, i) {
        model.add_edge_ensure(g, from: i, to: i + n, with: 1, default: Nil)
      })
    }
  }
}

/// Generates a circular ladder graph (prism graph) with n rungs.
///
/// The circular ladder CL_n consists of two concentric n-cycles with
/// corresponding vertices connected by rungs. It's equivalent to the
/// Cartesian product C_n × K_2 (cycle × edge).
///
/// ## Example
///
/// ```gleam
/// let cl = classic.circular_ladder(5)
/// // CL_5 has 10 nodes
///
/// // CL_4 is the cube graph (isomorphic to hypercube(3))
/// let cl4 = classic.circular_ladder(4)
/// ```
///
/// ## Properties
///
/// - Vertices: 2n
/// - Edges: 3n (2n cycle edges + n rungs)
/// - 3-regular (cubic) for n > 2
/// - Planar (can be drawn on a cylinder)
/// - Hamiltonian
/// - Bipartite when n is even
///
/// ## Use Cases
///
/// - Prism graphs in chemistry (molecular structures)
/// - Network topologies with wraparound
/// - Topological graph theory (cylindrical embeddings)
pub fn circular_ladder(n: Int) -> Graph(Nil, Int) {
  circular_ladder_with_type(n, model.Undirected)
}

/// Alias for `circular_ladder/1`.
///
/// The n-sided prism graph is exactly the circular ladder CL_n.
pub fn prism(n: Int) -> Graph(Nil, Int) {
  circular_ladder(n)
}

/// Generates a circular ladder graph with specified graph type.
pub fn circular_ladder_with_type(
  n: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n < 3 {
    True -> model.new(graph_type)
    False -> {
      // Nodes 0..n-1 are inner cycle, n..2n-1 are outer cycle
      let graph = create_nodes(model.new(graph_type), 2 * n)

      // Inner cycle edges: (i, (i+1) mod n) for i in 0..n-1
      let inner_edges =
        utils.range(0, n - 1)
        |> list.fold(graph, fn(g, i) {
          let next = { i + 1 } % n
          model.add_edge_ensure(g, from: i, to: next, with: 1, default: Nil)
        })

      // Outer cycle edges: (i+n, ((i+1) mod n)+n) for i in 0..n-1
      let outer_edges =
        utils.range(0, n - 1)
        |> list.fold(inner_edges, fn(g, i) {
          let next = { i + 1 } % n + n
          model.add_edge_ensure(g, from: i + n, to: next, with: 1, default: Nil)
        })

      // Rung edges: (i, i+n) for i in 0..n-1
      utils.range(0, n - 1)
      |> list.fold(outer_edges, fn(g, i) {
        model.add_edge_ensure(g, from: i, to: i + n, with: 1, default: Nil)
      })
    }
  }
}

/// Generates a Möbius ladder graph with n rungs.
///
/// The Möbius ladder ML_n is formed from a circular ladder by giving it
/// a half-twist before connecting the ends, creating a Möbius strip topology.
///
/// ## Example
///
/// ```gleam
/// let ml = classic.mobius_ladder(6)
/// // ML_6 has 12 nodes
///
/// // ML_4 is K_{3,3} (complete bipartite graph)
/// let ml4 = classic.mobius_ladder(4)
/// ```
///
/// ## Properties
///
/// - Vertices: 2n
/// - Edges: 3n
/// - 3-regular (cubic)
/// - Non-planar for n ≥ 3
/// - ML_4 = K_{3,3} (canonical non-planar graph)
/// - ML_3 = 6-vertex utility graph (K_{3,3} minus an edge)
/// - Bipartite when n is odd
///
/// ## Use Cases
///
/// - Non-orientable embeddings in topological graph theory
/// - Planarity testing (contains K_{3,3} minor)
/// - Chemical graph theory (Möbius molecules)
/// - Network design with twisted topology
pub fn mobius_ladder(n: Int) -> Graph(Nil, Int) {
  mobius_ladder_with_type(n, model.Undirected)
}

/// Generates a Möbius ladder graph with specified graph type.
pub fn mobius_ladder_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 2 {
    True -> model.new(graph_type)
    False -> {
      // Nodes 0..2n-1 arranged in a cycle
      let graph = create_nodes(model.new(graph_type), 2 * n)

      // Cycle edges: (i, (i+1) mod 2n) for i in 0..2n-1
      let cycle_edges =
        utils.range(0, 2 * n - 1)
        |> list.fold(graph, fn(g, i) {
          let next = { i + 1 } % { 2 * n }
          model.add_edge_ensure(g, from: i, to: next, with: 1, default: Nil)
        })

      // Twist edges (rungs with twist): (i, (i+n) mod 2n) for i in 0..n-1
      // These connect opposite vertices in the cycle, creating the twist
      utils.range(0, n - 1)
      |> list.fold(cycle_edges, fn(g, i) {
        let twisted = { i + n } % { 2 * n }
        model.add_edge_ensure(g, from: i, to: twisted, with: 1, default: Nil)
      })
    }
  }
}

/// Generates the friendship graph F_n with n triangles.
///
/// The friendship graph consists of n triangles all sharing a common vertex.
/// Also known as the Dutch windmill graph.
///
/// Famous for the **Friendship Theorem**: if every pair of vertices in a finite
/// graph has exactly one common neighbor, then the graph must be a friendship graph.
///
/// ## Example
///
/// ```gleam
/// let f3 = classic.friendship(3)
/// // F_3 has 7 nodes (1 center + 6 outer)
/// // F_3 has 9 edges (3 triangles)
/// ```
///
/// ## Properties
///
/// - Vertices: 2n + 1 (1 center + 2n outer vertices)
/// - Edges: 3n (n triangles, each with 3 edges)
/// - Center has degree 2n, outer vertices have degree 2
/// - Chromatic number: 3
/// - Diameter: 2, Radius: 1
/// - Planar
///
/// ## Use Cases
///
/// - Graph theory education (Friendship Theorem)
/// - Testing graphs with specific local properties
/// - Social network models (hub with triadic closure)
pub fn friendship(n: Int) -> Graph(Nil, Int) {
  friendship_with_type(n, model.Undirected)
}

/// Generates a friendship graph with specified graph type.
pub fn friendship_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 1 {
    True -> model.new(graph_type)
    False -> {
      // Node 0 is the center
      // Nodes 1..2n are outer vertices (n pairs forming triangles with center)
      let total_vertices = 2 * n + 1
      let graph = create_nodes(model.new(graph_type), total_vertices)

      // Create n triangles: (0, 2i-1, 2i) for i in 1..n
      utils.range(1, n)
      |> list.fold(graph, fn(g, i) {
        let outer1 = 2 * i - 1
        let outer2 = 2 * i
        g
        |> model.add_edge_ensure(from: 0, to: outer1, with: 1, default: Nil)
        |> model.add_edge_ensure(from: 0, to: outer2, with: 1, default: Nil)
        |> model.add_edge_ensure(
          from: outer1,
          to: outer2,
          with: 1,
          default: Nil,
        )
      })
    }
  }
}

/// Generates the windmill graph W_n^{(k)}.
///
/// Generalization of the friendship graph where n copies of K_k (complete graph
/// on k vertices) share a common vertex. The friendship graph is W_n^{(3)}.
///
/// ## Options
/// - `n` - Number of cliques
/// - `clique_size` - Size k of the cliques (default: 3)
///
/// ## Example
///
/// ```gleam
/// // Windmill of 4 triangles (same as friendship(4))
/// let w4 = classic.windmill(4, clique_size: 3)
///
/// // Windmill of 3 squares (4-cliques sharing a vertex)
/// let w3_4 = classic.windmill(3, clique_size: 4)
/// ```
///
/// ## Properties
///
/// - Vertices: 1 + n(k-1)
/// - Edges: n × C(k,2) = n × k(k-1)/2
/// - Center has degree n(k-1)
///
/// ## Use Cases
///
/// - Generalized friendship graphs
/// - Intersection graph theory
/// - Clique decomposition studies
pub fn windmill(n: Int, clique_size k: Int) -> Graph(Nil, Int) {
  windmill_with_type(n, k, model.Undirected)
}

/// Generates a windmill graph with specified graph type.
pub fn windmill_with_type(
  n: Int,
  k: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n < 1 || k < 2 {
    True -> model.new(graph_type)
    False -> {
      // Node 0 is the center shared by all cliques
      // Each clique adds k-1 new vertices
      let total_vertices = 1 + n * { k - 1 }
      let graph = create_nodes(model.new(graph_type), total_vertices)

      // For each of the n cliques, add all edges within the clique
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        // Vertices in this clique (excluding center)
        let clique_start = 1 + i * { k - 1 }
        let clique_vertices = [
          0,
          ..utils.range(clique_start, clique_start + k - 2)
        ]

        // Add all pairs in the clique as edges (complete graph)
        add_all_pairs(g, clique_vertices)
      })
    }
  }
}

/// Generates the book graph B_n.
///
/// The book graph consists of n triangles (or 4-cycles in some definitions)
/// all sharing a common edge (the "spine").
///
/// ## Example
///
/// ```gleam
/// let book = classic.book(3)
/// // B_3 has 5 nodes (2 spine + 3 page vertices)
/// // B_3 has 7 edges
/// ```
///
/// ## Properties
///
/// - Vertices: n + 2 (2 spine vertices + n page vertices)
/// - Edges: 2n + 1 (n triangles sharing the spine edge)
/// - Planar
/// - Outerplanar
///
/// ## Use Cases
///
/// - Graph drawing and book embeddings
/// - Outerplanar graph studies
/// - Pagenumber of graphs
pub fn book(n: Int) -> Graph(Nil, Int) {
  book_with_type(n, model.Undirected)
}

/// Generates a book graph with specified graph type.
pub fn book_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 1 {
    True -> model.new(graph_type)
    False -> {
      // Nodes 0 and 1 form the spine (shared edge)
      // Nodes 2..(n+1) are the page vertices (each forms a triangle with spine)
      let total_vertices = n + 2
      let graph = create_nodes(model.new(graph_type), total_vertices)

      // Spine edge
      let with_spine =
        model.add_edge_ensure(graph, from: 0, to: 1, with: 1, default: Nil)

      // Each page vertex forms a triangle with the spine
      utils.range(2, total_vertices - 1)
      |> list.fold(with_spine, fn(g, i) {
        g
        |> model.add_edge_ensure(from: 0, to: i, with: 1, default: Nil)
        |> model.add_edge_ensure(from: 1, to: i, with: 1, default: Nil)
      })
    }
  }
}

/// Generates the crown graph S_n^0 with 2n vertices.
///
/// The crown graph is the complete bipartite graph K_{n,n} minus a perfect
/// matching. It has important applications in edge coloring and extremal
/// graph theory.
///
/// ## Example
///
/// ```gleam
/// let crown = classic.crown(4)
/// // S_4^0 has 8 nodes
/// // S_4^0 has 12 edges (16 - 4)
///
/// // crown(2) is C_4 (cycle on 4 vertices)
/// let c2 = classic.crown(2)
/// ```
///
/// ## Properties
///
/// - Vertices: 2n
/// - Edges: n(n-1) = n² - n
/// - (n-1)-regular (each vertex has degree n-1)
/// - Bipartite
/// - Diameter: 3 for n ≥ 3
/// - Girth: 4 for n ≥ 3
///
/// ## Special Cases
///
/// - crown(2) = C₄ (4-cycle)
/// - crown(3) is the utility graph (K_{3,3} minus a perfect matching)
///
/// ## Use Cases
///
/// - Edge coloring tests (chromatic index demonstrations)
/// - Extremal graph theory examples
/// - Bipartite graph testing with symmetric structure
pub fn crown(n: Int) -> Graph(Nil, Int) {
  crown_with_type(n, model.Undirected)
}

/// Generates a crown graph with specified graph type.
pub fn crown_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 2 {
    True -> model.new(graph_type)
    False -> {
      // Two partitions: U = {0, ..., n-1}, V = {n, ..., 2n-1}
      let graph = create_nodes(model.new(graph_type), 2 * n)

      // All edges between U and V EXCEPT (i, n+i) for i in 0..n-1
      // This removes the perfect matching
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(0, n - 1)
        |> list.fold(g, fn(acc, j) {
          // Skip the perfect matching edges where i == j
          case i == j {
            True -> acc
            False ->
              model.add_edge_ensure(
                acc,
                from: i,
                to: n + j,
                with: 1,
                default: Nil,
              )
          }
        })
      })
    }
  }
}

/// Generates the Turán graph T(n, r).
///
/// The Turán graph is a complete r-partite graph with n vertices where
/// partitions are as equal as possible. It maximizes the number of edges
/// among all n-vertex graphs that do not contain K_{r+1} as a subgraph.
///
/// **Properties:**
/// - Complete r-partite with balanced partitions
/// - Maximum edge count without containing K_{r+1}
/// - Chromatic number: r (for n >= r)
/// - Turán's theorem: extremal graph for forbidden cliques
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// let turan = classic.turan(10, 3)
/// // T(10, 3) has 10 nodes with balanced partitions: 4, 3, 3
///
/// // T(n, 2) is the complete bipartite graph
/// let k33 = classic.turan(6, 2)
/// ```
///
/// ## Use Cases
///
/// - Extremal graph theory testing
/// - Chromatic number benchmarks
/// - Anti-clique (independence number) studies
/// - Balanced multi-partite networks
pub fn turan(n: Int, r: Int) -> Graph(Nil, Int) {
  turan_with_type(n, r, model.Undirected)
}

/// Generates a Turán graph with specified graph type.
pub fn turan_with_type(n: Int, r: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n <= 0 || r <= 0 {
    True -> model.new(graph_type)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      // Partition function: determines which partition a node belongs to
      let partition_of = fn(node: Int) -> Int {
        case r >= n {
          True -> node
          False -> {
            let base_size = n / r
            let remainder = n % r

            case node < remainder * { base_size + 1 } {
              True -> node / { base_size + 1 }
              False -> {
                case base_size == 0 {
                  True -> remainder - 1
                  False ->
                    remainder
                    + { node - remainder * { base_size + 1 } }
                    / base_size
                }
              }
            }
          }
        }
      }

      // Add edges between nodes in different partitions
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(i + 1, n - 1)
        |> list.fold(g, fn(acc, j) {
          case partition_of(i) != partition_of(j) {
            True ->
              model.add_edge_ensure(acc, from: i, to: j, with: 1, default: Nil)
            False -> acc
          }
        })
      })
    }
  }
}

/// Generates the tetrahedron graph K₄.
///
/// The tetrahedron is the simplest Platonic solid with 4 vertices and 6 edges.
/// Each vertex has degree 3. It is a complete graph K₄.
///
/// ## Example
///
/// ```gleam
/// let tetra = classic.tetrahedron()
/// // Tetrahedron has 4 nodes and 6 edges
/// ```
///
/// ## Properties
///
/// - Vertices: 4
/// - Edges: 6
/// - Degree: 3 (regular)
/// - Diameter: 1
/// - Girth: 3
/// - Chromatic number: 4
pub fn tetrahedron() -> Graph(Nil, Int) {
  // Tetrahedron is K₄ - complete graph on 4 vertices
  complete(4)
}

/// Generates the cube graph Q₃ (3-dimensional hypercube).
///
/// The cube has 8 vertices and 12 edges. Each vertex has degree 3.
/// It is bipartite, planar, and is the 3D hypercube.
///
/// ## Example
///
/// ```gleam
/// let cube = classic.cube()
/// // Cube has 8 nodes and 12 edges
/// ```
///
/// ## Properties
///
/// - Vertices: 8
/// - Edges: 12
/// - Degree: 3 (regular)
/// - Diameter: 3
/// - Girth: 4
/// - Chromatic number: 2 (bipartite)
pub fn cube() -> Graph(Nil, Int) {
  // Cube is the 3D hypercube
  hypercube(3)
}

/// Generates the octahedron graph.
///
/// The octahedron has 6 vertices and 12 edges. Each vertex has degree 4.
/// It is the dual of the cube.
///
/// ## Example
///
/// ```gleam
/// let octa = classic.octahedron()
/// // Octahedron has 6 nodes and 12 edges
/// ```
///
/// ## Properties
///
/// - Vertices: 6
/// - Edges: 12
/// - Degree: 4 (regular)
/// - Diameter: 2
/// - Girth: 3
/// - Chromatic number: 3
pub fn octahedron() -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(model.Undirected), 6)

  // Octahedron: opposite pairs are (0,3), (1,4), (2,5)
  // Each vertex connects to all vertices EXCEPT its opposite
  graph
  // Vertex 0 connects to 1,2,4,5 (not 3)
  |> model.add_edge_ensure(from: 0, to: 1, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 0, to: 2, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 0, to: 4, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 0, to: 5, with: 1, default: Nil)
  // Vertex 1 connects to 0,2,3,5 (not 4)
  |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 1, to: 3, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 1, to: 5, with: 1, default: Nil)
  // Vertex 2 connects to 0,1,3,4 (not 5)
  |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 2, to: 4, with: 1, default: Nil)
  // Vertex 3 connects to 1,2,4,5 (not 0)
  |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: Nil)
  |> model.add_edge_ensure(from: 3, to: 5, with: 1, default: Nil)
  // Vertex 4 connects to 0,2,3,5 (not 1)
  |> model.add_edge_ensure(from: 4, to: 5, with: 1, default: Nil)
}

/// Generates the dodecahedron graph.
///
/// The dodecahedron has 20 vertices and 30 edges. Each vertex has degree 3.
/// Famous as the basis of Hamilton's "Icosian game" and Hamiltonian cycle puzzles.
/// It has girth 5 (smallest cycle has 5 edges).
///
/// ## Example
///
/// ```gleam
/// let dodec = classic.dodecahedron()
/// // Dodecahedron has 20 nodes and 30 edges
/// ```
///
/// ## Properties
///
/// - Vertices: 20
/// - Edges: 30
/// - Degree: 3 (regular)
/// - Diameter: 5
/// - Girth: 5
/// - Chromatic number: 3
pub fn dodecahedron() -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(model.Undirected), 20)

  // Dodecahedron edge structure:
  // Three concentric rings: outer pentagon (0-4), middle decagon (5-14), inner pentagon (15-19)
  let edges = [
    // Outer pentagon
    #(0, 1),
    #(1, 2),
    #(2, 3),
    #(3, 4),
    #(4, 0),
    // Inner pentagon
    #(15, 16),
    #(16, 17),
    #(17, 18),
    #(18, 19),
    #(19, 15),
    // Middle ring (two intertwined pentagons)
    #(5, 6),
    #(6, 7),
    #(7, 8),
    #(8, 9),
    #(9, 10),
    #(10, 11),
    #(11, 12),
    #(12, 13),
    #(13, 14),
    #(14, 5),
    // Connections: outer to middle
    #(0, 5),
    #(1, 6),
    #(2, 7),
    #(3, 8),
    #(4, 9),
    // Connections: middle to inner
    #(10, 15),
    #(11, 16),
    #(12, 17),
    #(13, 18),
    #(14, 19),
  ]

  edges
  |> list.fold(graph, fn(g, edge) {
    let #(u, v) = edge
    model.add_edge_ensure(g, from: u, to: v, with: 1, default: Nil)
  })
}

/// Generates the icosahedron graph.
///
/// The icosahedron has 12 vertices and 30 edges. Each vertex has degree 5.
/// It is the dual of the dodecahedron.
///
/// ## Example
///
/// ```gleam
/// let icosa = classic.icosahedron()
/// // Icosahedron has 12 nodes and 30 edges
/// ```
///
/// ## Properties
///
/// - Vertices: 12
/// - Edges: 30
/// - Degree: 5 (regular)
/// - Diameter: 3
/// - Girth: 3
/// - Chromatic number: 4
pub fn icosahedron() -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(model.Undirected), 12)

  // Icosahedron: can be thought of as two pentagonal pyramids (top/bottom)
  // with a ring of 10 vertices between them
  // Layout: 0 = north pole, 11 = south pole, 1-5 and 6-10 in alternating rings
  let edges = [
    // North pole (0) connects to vertices 1-5
    #(0, 1),
    #(0, 2),
    #(0, 3),
    #(0, 4),
    #(0, 5),
    // South pole (11) connects to vertices 6-10
    #(11, 6),
    #(11, 7),
    #(11, 8),
    #(11, 9),
    #(11, 10),
    // Upper ring connections (1-5)
    #(1, 2),
    #(2, 3),
    #(3, 4),
    #(4, 5),
    #(5, 1),
    // Lower ring connections (6-10)
    #(6, 7),
    #(7, 8),
    #(8, 9),
    #(9, 10),
    #(10, 6),
    // Cross connections between rings (each upper connects to 2 lower)
    #(1, 6),
    #(1, 10),
    #(2, 6),
    #(2, 7),
    #(3, 7),
    #(3, 8),
    #(4, 8),
    #(4, 9),
    #(5, 9),
    #(5, 10),
  ]

  edges
  |> list.fold(graph, fn(g, edge) {
    let #(u, v) = edge
    model.add_edge_ensure(g, from: u, to: v, with: 1, default: Nil)
  })
}

// Helper: Create n nodes with Nil data and sequential IDs
fn create_nodes(graph: Graph(Nil, e), n: Int) -> Graph(Nil, e) {
  case n <= 0 {
    True -> graph
    False ->
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) { model.add_node(g, i, Nil) })
  }
}

// Helper: Integer exponentiation (tail-recursive)
fn power(base: Int, exp: Int) -> Int {
  do_power(base, exp, 1)
}

fn do_power(base: Int, exp: Int, acc: Int) -> Int {
  case exp {
    0 -> acc
    _ -> do_power(base, exp - 1, acc * base)
  }
}

// Helper: Add all pairs from a list of nodes as edges
fn add_all_pairs(graph: Graph(Nil, Int), nodes: List(Int)) -> Graph(Nil, Int) {
  case nodes {
    [] -> graph
    [_] -> graph
    [h, ..t] -> {
      let with_head =
        t
        |> list.fold(graph, fn(g, node) {
          model.add_edge_ensure(g, from: h, to: node, with: 1, default: Nil)
        })
      add_all_pairs(with_head, t)
    }
  }
}
