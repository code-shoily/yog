//// Classic graph patterns generator.
////
//// This module provides functions to generate well-known graph structures:
//// - **Complete graphs**: K_n where every node connects to every other
//// - **Cycles**: C_n nodes forming a ring
//// - **Paths**: P_n linear chains
//// - **Stars**: Central hub with spokes
//// - **Wheels**: Cycle with central hub
//// - **Bipartite**: Complete bipartite graphs K_{m,n}
//// - **Trees**: Binary trees, hierarchical structures
//// - **Grids**: 2D lattices
//// - **Famous graphs**: Petersen graph
////
//// These generators are useful for:
//// - **Testing**: Create graphs with known properties
//// - **Benchmarking**: Generate graphs of various sizes
//// - **Education**: Demonstrate algorithms on well-known structures
//// - **Prototyping**: Quickly create graph structures
////
//// ## Example
////
//// ```gleam
//// import yog/generators/classic
////
//// pub fn main() {
////   // Generate a cycle graph with 5 nodes
////   let cycle = classic.cycle(5)
////
////   // Generate a complete graph with 4 nodes
////   let complete = classic.complete(4)
////
////   // Generate a binary tree of depth 3
////   let tree = classic.binary_tree(3)
//// }
//// ```

import gleam/list
import yog/internal/utils
import yog/model.{type Graph, type GraphType}

/// Generates a complete graph K_n where every node is connected to every other node.
///
/// In a complete graph with n nodes, there are n(n-1)/2 edges for undirected
/// graphs and n(n-1) edges for directed graphs.
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// let k5 = generate.complete(5)
/// // Creates a complete graph with 5 nodes
/// // Each node connected to all other 4 nodes
/// ```
pub fn complete(n: Int) -> Graph(Nil, Int) {
  complete_with_type(n, model.Undirected)
}

/// Generates a complete graph with specified graph type.
///
/// ## Example
///
/// ```gleam
/// let directed_k4 = generate.complete_with_type(4, model.Directed)
/// ```
pub fn complete_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(graph_type), n)

  case graph_type {
    model.Undirected -> {
      // For undirected, only add edge once between each pair
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(i + 1, n - 1)
        |> list.fold(g, fn(acc, j) {
          model.add_edge(acc, from: i, to: j, with: 1)
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
            False -> model.add_edge(acc, from: i, to: j, with: 1)
          }
        })
      })
    }
  }
}

/// Generates a cycle graph C_n where nodes form a ring.
///
/// A cycle graph connects n nodes in a circular pattern:
/// 0 -> 1 -> 2 -> ... -> (n-1) -> 0
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let c6 = generate.cycle(6)
/// // Creates a cycle: 0-1-2-3-4-5-0
/// ```
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
        model.add_edge(g, from: i, to: next, with: 1)
      })
    }
  }
}

/// Generates a path graph P_n where nodes form a linear chain.
///
/// A path graph connects n nodes in a line:
/// 0 - 1 - 2 - ... - (n-1)
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let p5 = generate.path(5)
/// // Creates a path: 0-1-2-3-4
/// ```
pub fn path(n: Int) -> Graph(Nil, Int) {
  path_with_type(n, model.Undirected)
}

/// Generates a path graph with specified graph type.
pub fn path_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 2 {
    True -> create_nodes(model.new(graph_type), n)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      // Add edges in a line
      utils.range(0, n - 2)
      |> list.fold(graph, fn(g, i) {
        model.add_edge(g, from: i, to: i + 1, with: 1)
      })
    }
  }
}

/// Generates a star graph where one central node is connected to all others.
///
/// Node 0 is the center, connected to nodes 1 through n-1.
/// A star with n nodes has n-1 edges.
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let s6 = generate.star(6)
/// // Center node 0 connected to nodes 1, 2, 3, 4, 5
/// ```
pub fn star(n: Int) -> Graph(Nil, Int) {
  star_with_type(n, model.Undirected)
}

/// Generates a star graph with specified graph type.
pub fn star_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 2 {
    True -> create_nodes(model.new(graph_type), n)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      // Connect center (0) to all other nodes
      utils.range(1, n - 1)
      |> list.fold(graph, fn(g, i) {
        model.add_edge(g, from: 0, to: i, with: 1)
      })
    }
  }
}

/// Generates a wheel graph: a cycle with a central hub.
///
/// A wheel graph is a cycle of n-1 nodes with an additional central node
/// connected to all nodes in the cycle.
///
/// Node 0 is the center, nodes 1 through n-1 form the cycle.
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let w6 = generate.wheel(6)
/// // Center node 0, cycle 1-2-3-4-5-1, center connected to all
/// ```
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
        model.add_edge(g, from: i, to: next, with: 1)
      })
    }
  }
}

/// Generates a complete bipartite graph K_{m,n}.
///
/// A complete bipartite graph has two partitions of nodes where every node
/// in the first partition is connected to every node in the second partition.
///
/// Nodes 0 to m-1 form the left partition.
/// Nodes m to m+n-1 form the right partition.
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(mn)
///
/// ## Example
///
/// ```gleam
/// let k33 = generate.complete_bipartite(3, 3)
/// // Nodes 0,1,2 on left, nodes 3,4,5 on right
/// // All left nodes connected to all right nodes
/// ```
pub fn complete_bipartite(m: Int, n: Int) -> Graph(Nil, Int) {
  complete_bipartite_with_type(m, n, model.Undirected)
}

/// Generates a complete bipartite graph with specified graph type.
pub fn complete_bipartite_with_type(
  m: Int,
  n: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let total = m + n
  let graph = create_nodes(model.new(graph_type), total)

  // Connect every node in left partition to every node in right partition
  utils.range(0, m - 1)
  |> list.fold(graph, fn(g, left) {
    utils.range(m, total - 1)
    |> list.fold(g, fn(acc, right) {
      model.add_edge(acc, from: left, to: right, with: 1)
    })
  })
}

/// Generates an empty graph with n nodes and no edges.
///
/// Useful as a starting point for custom graph construction.
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let empty = generate.empty(10)
/// // 10 isolated nodes, no edges
/// ```
pub fn empty(n: Int) -> Graph(Nil, Int) {
  empty_with_type(n, model.Undirected)
}

/// Generates an empty graph with specified graph type.
pub fn empty_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  create_nodes(model.new(graph_type), n)
}

/// Generates a complete binary tree of given depth.
///
/// A complete binary tree where:
/// - Node 0 is the root
/// - For node i: left child is 2i+1, right child is 2i+2
/// - Total nodes: 2^(depth+1) - 1
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(2^depth)
///
/// ## Example
///
/// ```gleam
/// let tree = generate.binary_tree(3)
/// // Creates a binary tree with 15 nodes (depth 3)
/// //        0
/// //      /   \
/// //     1     2
/// //    / \   / \
/// //   3   4 5   6
/// //  /|\ /|\ ...
/// ```
pub fn binary_tree(depth: Int) -> Graph(Nil, Int) {
  binary_tree_with_type(depth, model.Undirected)
}

/// Generates a complete binary tree with specified graph type.
pub fn binary_tree_with_type(
  depth: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case depth < 0 {
    True -> model.new(graph_type)
    False -> {
      let n = power(2, depth + 1) - 1
      let graph = create_nodes(model.new(graph_type), n)

      // Add edges from each parent to its children
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        let left_child = 2 * i + 1
        let right_child = 2 * i + 2

        let with_left = case left_child < n {
          True -> model.add_edge(g, from: i, to: left_child, with: 1)
          False -> g
        }

        case right_child < n {
          True -> model.add_edge(with_left, from: i, to: right_child, with: 1)
          False -> with_left
        }
      })
    }
  }
}

/// Generates a 2D grid graph (lattice).
///
/// Creates a grid of rows × cols nodes arranged in a rectangular lattice.
/// Each internal node has 4 neighbors (up, down, left, right).
/// Edge nodes have fewer neighbors.
///
/// Node IDs are assigned row-major: node_id = row * cols + col
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(rows * cols)
///
/// ## Example
///
/// ```gleam
/// let grid = generate.grid_2d(3, 4)
/// // Creates a 3×4 grid:
/// //   0 - 1 - 2 - 3
/// //   |   |   |   |
/// //   4 - 5 - 6 - 7
/// //   |   |   |   |
/// //   8 - 9 -10 -11
/// ```
pub fn grid_2d(rows: Int, cols: Int) -> Graph(Nil, Int) {
  grid_2d_with_type(rows, cols, model.Undirected)
}

/// Generates a 2D grid graph with specified graph type.
pub fn grid_2d_with_type(
  rows: Int,
  cols: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let n = rows * cols
  let graph = create_nodes(model.new(graph_type), n)

  // Add horizontal edges
  let with_horizontal =
    utils.range(0, rows - 1)
    |> list.fold(graph, fn(g, row) {
      utils.range(0, cols - 2)
      |> list.fold(g, fn(acc, col) {
        let node = row * cols + col
        model.add_edge(acc, from: node, to: node + 1, with: 1)
      })
    })

  // Add vertical edges
  utils.range(0, rows - 2)
  |> list.fold(with_horizontal, fn(g, row) {
    utils.range(0, cols - 1)
    |> list.fold(g, fn(acc, col) {
      let node = row * cols + col
      let below = node + cols
      model.add_edge(acc, from: node, to: below, with: 1)
    })
  })
}

/// Generates a Petersen graph.
///
/// The Petersen graph is a famous graph in graph theory, often used as
/// a counterexample. It has 10 nodes and 15 edges, and is non-planar.
///
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(1) - fixed size
///
/// ## Example
///
/// ```gleam
/// let petersen = generate.petersen()
/// // Creates the classic Petersen graph with 10 nodes
/// ```
pub fn petersen() -> Graph(Nil, Int) {
  petersen_with_type(model.Undirected)
}

/// Generates a Petersen graph with specified graph type.
pub fn petersen_with_type(graph_type: GraphType) -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(graph_type), 10)

  // Outer pentagon: 0-1-2-3-4-0
  let with_outer =
    graph
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 0, with: 1)

  // Inner pentagram: 5-7-9-6-8-5
  let with_inner =
    with_outer
    |> model.add_edge(from: 5, to: 7, with: 1)
    |> model.add_edge(from: 7, to: 9, with: 1)
    |> model.add_edge(from: 9, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 8, with: 1)
    |> model.add_edge(from: 8, to: 5, with: 1)

  // Connect outer to inner (spokes)
  with_inner
  |> model.add_edge(from: 0, to: 5, with: 1)
  |> model.add_edge(from: 1, to: 6, with: 1)
  |> model.add_edge(from: 2, to: 7, with: 1)
  |> model.add_edge(from: 3, to: 8, with: 1)
  |> model.add_edge(from: 4, to: 9, with: 1)
}

// Helper: Create n nodes with Nil data and sequential IDs
fn create_nodes(graph: Graph(Nil, e), n: Int) -> Graph(Nil, e) {
  utils.range(0, n - 1)
  |> list.fold(graph, fn(g, i) { model.add_node(g, i, Nil) })
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
