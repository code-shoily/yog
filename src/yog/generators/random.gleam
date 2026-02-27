//// Random graph generators for stochastic network models.
////
//// This module provides functions to generate random graphs using well-known
//// probabilistic models:
//// - **Erdős-Rényi**: Random graphs with uniform edge probability
//// - **Barabási-Albert**: Scale-free networks with power-law degree distribution
//// - **Watts-Strogatz**: Small-world networks with high clustering
//// - **Random trees**: Uniformly random spanning trees
////
//// These generators are useful for:
//// - **Testing**: Generate graphs with known statistical properties
//// - **Simulation**: Model real-world networks (social, biological, technological)
//// - **Benchmarking**: Create graphs of various sizes and structures
//// - **Research**: Study network properties and algorithm behavior
////
//// ## Example
////
//// ```gleam
//// import yog/generators/random
////
//// pub fn main() {
////   // Erdős-Rényi: 100 nodes, each edge exists with 5% probability
////   let er_graph = random.erdos_renyi_gnp(100, 0.05)
////
////   // Barabási-Albert: 100 nodes, each new node connects to 3 existing nodes
////   let ba_graph = random.barabasi_albert(100, 3)
////
////   // Watts-Strogatz: 100 nodes in a ring, each connected to 4 neighbors, 10% rewiring
////   let ws_graph = random.watts_strogatz(100, 4, 0.1)
//// }
//// ```

import gleam/float
import gleam/int
import gleam/list
import gleam/set.{type Set}
import yog/internal/utils
import yog/model.{type Graph, type GraphType}

/// Generates a random graph using the Erdős-Rényi G(n, p) model.
///
/// Each possible edge is included independently with probability p.
///
/// **Expected edges:** p * n(n-1)/2 for undirected, p * n(n-1) for directed
///
/// **Time Complexity:** O(n²) - must consider all possible edges
///
/// ## Example
///
/// ```gleam
/// // 50 nodes, each edge exists with 10% probability
/// // Expected ~122 edges for undirected
/// let graph = random.erdos_renyi_gnp(50, 0.1)
/// ```
///
/// ## Use Cases
///
/// - Baseline for comparing other random graph models
/// - Modeling networks with uniform connection probability
/// - Testing graph algorithms on random structures
/// - Phase transitions in network connectivity (p ~ 1/n)
pub fn erdos_renyi_gnp(n: Int, p: Float) -> Graph(Nil, Int) {
  erdos_renyi_gnp_with_type(n, p, model.Undirected)
}

/// Generates an Erdős-Rényi G(n, p) graph with specified graph type.
pub fn erdos_renyi_gnp_with_type(
  n: Int,
  p: Float,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(graph_type), n)

  case graph_type {
    model.Undirected -> {
      // For undirected, only consider i < j pairs
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(i + 1, n - 1)
        |> list.fold(g, fn(acc, j) {
          case float.random() <. p {
            True -> model.add_edge(acc, from: i, to: j, with: 1)
            False -> acc
          }
        })
      })
    }
    model.Directed -> {
      // For directed, consider all i != j pairs
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(0, n - 1)
        |> list.fold(g, fn(acc, j) {
          case i == j {
            True -> acc
            False ->
              case float.random() <. p {
                True -> model.add_edge(acc, from: i, to: j, with: 1)
                False -> acc
              }
          }
        })
      })
    }
  }
}

/// Generates a random graph using the Erdős-Rényi G(n, m) model.
///
/// Exactly m edges are added uniformly at random (without replacement).
///
/// **Time Complexity:** O(m) expected, O(m log m) worst case
///
/// ## Example
///
/// ```gleam
/// // 50 nodes, exactly 100 edges
/// let graph = random.erdos_renyi_gnm(50, 100)
/// ```
///
/// ## Use Cases
///
/// - Control exact edge count for testing
/// - Generate sparse graphs efficiently (m << n²)
/// - Benchmark algorithms with precise graph sizes
pub fn erdos_renyi_gnm(n: Int, m: Int) -> Graph(Nil, Int) {
  erdos_renyi_gnm_with_type(n, m, model.Undirected)
}

/// Generates an Erdős-Rényi G(n, m) graph with specified graph type.
pub fn erdos_renyi_gnm_with_type(
  n: Int,
  m: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let graph = create_nodes(model.new(graph_type), n)

  let max_edges = case graph_type {
    model.Undirected -> n * { n - 1 } / 2
    model.Directed -> n * { n - 1 }
  }

  // Can't have more edges than possible
  let actual_m = int.min(m, max_edges)

  add_random_edges(graph, n, actual_m, set.new(), graph_type)
}

// Add m random edges to graph without duplicates
fn add_random_edges(
  graph: Graph(Nil, Int),
  n: Int,
  m: Int,
  existing: Set(#(Int, Int)),
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case m <= 0 {
    True -> graph
    False -> {
      // Generate random edge
      let i = int.random(n)
      let j = int.random(n)

      case i == j {
        True -> add_random_edges(graph, n, m, existing, graph_type)
        False -> {
          // Normalize edge for undirected graphs
          let edge = case graph_type {
            model.Undirected ->
              case i < j {
                True -> #(i, j)
                False -> #(j, i)
              }
            model.Directed -> #(i, j)
          }

          case set.contains(existing, edge) {
            True -> add_random_edges(graph, n, m, existing, graph_type)
            False -> {
              let new_graph =
                model.add_edge(graph, from: edge.0, to: edge.1, with: 1)
              let new_existing = set.insert(existing, edge)
              add_random_edges(new_graph, n, m - 1, new_existing, graph_type)
            }
          }
        }
      }
    }
  }
}

/// Generates a scale-free network using the Barabási-Albert model.
///
/// Starts with m₀ nodes in a complete graph, then adds n - m₀ nodes.
/// Each new node connects to m existing nodes via preferential attachment
/// (probability proportional to node degree).
///
/// **Properties:**
/// - Power-law degree distribution P(k) ~ k^(-γ)
/// - Scale-free (no characteristic scale)
/// - Robust to random failures, vulnerable to targeted attacks
///
/// **Time Complexity:** O(nm)
///
/// ## Example
///
/// ```gleam
/// // 100 nodes, each new node connects to 3 existing nodes
/// // Results in ~300 edges
/// let graph = random.barabasi_albert(100, 3)
/// ```
///
/// ## Use Cases
///
/// - Model the internet, citation networks, social networks
/// - Study robustness and vulnerability
/// - Test algorithms on scale-free topologies
/// - Simulate viral spread on networks with hubs
pub fn barabasi_albert(n: Int, m: Int) -> Graph(Nil, Int) {
  barabasi_albert_with_type(n, m, model.Undirected)
}

/// Generates a Barabási-Albert graph with specified graph type.
pub fn barabasi_albert_with_type(
  n: Int,
  m: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n < m || m < 1 {
    True -> model.new(graph_type)
    False -> {
      // Start with complete graph on m nodes
      let m0 = int.max(m, 2)
      let initial =
        utils.range(0, m0 - 1)
        |> list.fold(model.new(graph_type), fn(g, i) {
          model.add_node(g, i, Nil)
        })

      // Add initial edges (complete graph on first m0 nodes)
      let initial_with_edges = case graph_type {
        model.Undirected ->
          utils.range(0, m0 - 1)
          |> list.fold(initial, fn(g, i) {
            utils.range(i + 1, m0 - 1)
            |> list.fold(g, fn(acc, j) {
              model.add_edge(acc, from: i, to: j, with: 1)
            })
          })
        model.Directed ->
          utils.range(0, m0 - 1)
          |> list.fold(initial, fn(g, i) {
            utils.range(0, m0 - 1)
            |> list.fold(g, fn(acc, j) {
              case i == j {
                True -> acc
                False -> model.add_edge(acc, from: i, to: j, with: 1)
              }
            })
          })
      }

      // Add remaining nodes with preferential attachment
      utils.range(m0, n - 1)
      |> list.fold(initial_with_edges, fn(g, new_node) {
        add_node_with_preferential_attachment(g, new_node, m, graph_type)
      })
    }
  }
}

// Add a new node and connect it to m existing nodes via preferential attachment
fn add_node_with_preferential_attachment(
  graph: Graph(Nil, Int),
  new_node: Int,
  m: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let with_node = model.add_node(graph, new_node, Nil)

  // Build degree list (each node appears degree times for weighted sampling)
  let degree_list = build_degree_list(graph, graph_type)

  // Select m unique targets using preferential attachment
  let targets = select_preferential_targets(degree_list, m, set.new())

  // Add edges to selected targets
  targets
  |> set.to_list()
  |> list.fold(with_node, fn(g, target) {
    model.add_edge(g, from: new_node, to: target, with: 1)
  })
}

// Build a list where each node appears proportional to its degree
fn build_degree_list(graph: Graph(Nil, Int), graph_type: GraphType) -> List(Int) {
  model.all_nodes(graph)
  |> list.flat_map(fn(node) {
    let degree = case graph_type {
      model.Undirected -> list.length(model.neighbors(graph, node))
      model.Directed -> list.length(model.successors(graph, node))
    }
    // Each node appears 'degree' times (or at least once for isolated nodes)
    list.repeat(node, int.max(degree, 1))
  })
}

// Select m unique targets from degree list using random sampling
fn select_preferential_targets(
  degree_list: List(Int),
  m: Int,
  selected: Set(Int),
) -> Set(Int) {
  case set.size(selected) >= m || list.is_empty(degree_list) {
    True -> selected
    False -> {
      let list_size = list.length(degree_list)
      let index = int.random(list_size)

      case list_at(degree_list, index) {
        Ok(target) -> {
          let new_selected = set.insert(selected, target)
          select_preferential_targets(degree_list, m, new_selected)
        }
        Error(_) -> selected
      }
    }
  }
}

/// Generates a small-world network using the Watts-Strogatz model.
///
/// Creates a ring lattice where each node connects to k nearest neighbors,
/// then rewires each edge with probability p.
///
/// **Properties:**
/// - High clustering coefficient (like regular lattices)
/// - Short average path length (like random graphs)
/// - "Small-world" phenomenon: most nodes reachable in few hops
///
/// **Parameters:**
/// - n: Number of nodes
/// - k: Each node connects to k nearest neighbors (must be even)
/// - p: Rewiring probability (0 = regular lattice, 1 = random graph)
///
/// **Time Complexity:** O(nk)
///
/// ## Example
///
/// ```gleam
/// // 100 nodes, each connected to 4 neighbors, 10% rewiring
/// let graph = random.watts_strogatz(100, 4, 0.1)
/// ```
///
/// ## Use Cases
///
/// - Model social networks (friends of friends, but some random connections)
/// - Neural networks (local connectivity with long-range connections)
/// - Study information diffusion and epidemic spreading
/// - Test algorithms on networks with community structure
pub fn watts_strogatz(n: Int, k: Int, p: Float) -> Graph(Nil, Int) {
  watts_strogatz_with_type(n, k, p, model.Undirected)
}

/// Generates a Watts-Strogatz graph with specified graph type.
pub fn watts_strogatz_with_type(
  n: Int,
  k: Int,
  p: Float,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  case n < 3 || k < 2 || k >= n {
    True -> model.new(graph_type)
    False -> {
      // Start with empty graph
      let graph = create_nodes(model.new(graph_type), n)

      // Build ring lattice with probabilistic rewiring
      let half_k = k / 2
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) {
        utils.range(1, half_k)
        |> list.fold(g, fn(acc, offset) {
          case float.random() <. p {
            False -> {
              // Keep regular edge
              let j = { i + offset } % n
              model.add_edge(acc, from: i, to: j, with: 1)
            }
            True -> {
              // Rewire to random node
              add_random_edge_not_to(acc, i, n)
            }
          }
        })
      })
    }
  }
}

// Add edge from 'from' to a random node (avoiding self-loops and duplicates)
fn add_random_edge_not_to(
  graph: Graph(Nil, Int),
  from: Int,
  n: Int,
) -> Graph(Nil, Int) {
  let to = int.random(n)

  case to == from {
    True -> add_random_edge_not_to(graph, from, n)
    False -> {
      // Check if edge already exists
      let neighbors = model.successors(graph, from)
      let neighbor_ids = list.map(neighbors, fn(pair) { pair.0 })
      case list.contains(neighbor_ids, to) {
        True -> add_random_edge_not_to(graph, from, n)
        False -> model.add_edge(graph, from: from, to: to, with: 1)
      }
    }
  }
}

/// Generates a uniformly random tree on n nodes.
///
/// Uses a random walk approach to generate a spanning tree.
/// Every labeled tree on n vertices has equal probability.
///
/// **Properties:**
/// - Exactly n - 1 edges
/// - Connected and acyclic
/// - Random structure (no preferential attachment or locality bias)
///
/// **Time Complexity:** O(n²) expected
///
/// ## Example
///
/// ```gleam
/// // Random tree with 50 nodes
/// let tree = random.random_tree(50)
/// ```
///
/// ## Use Cases
///
/// - Test tree algorithms (DFS, BFS, LCA, diameter)
/// - Model hierarchical structures with random branching
/// - Generate random spanning trees
/// - Benchmark on tree topologies
pub fn random_tree(n: Int) -> Graph(Nil, Int) {
  random_tree_with_type(n, model.Undirected)
}

/// Generates a random tree with specified graph type.
pub fn random_tree_with_type(n: Int, graph_type: GraphType) -> Graph(Nil, Int) {
  case n < 2 {
    True -> create_nodes(model.new(graph_type), n)
    False -> {
      let graph = create_nodes(model.new(graph_type), n)

      // Start with node 0 in the tree
      let in_tree = set.from_list([0])

      // Add remaining nodes one at a time
      build_random_tree(graph, n, in_tree, 1)
    }
  }
}

// Build random tree by adding nodes one at a time
fn build_random_tree(
  graph: Graph(Nil, Int),
  n: Int,
  in_tree: Set(Int),
  next_node: Int,
) -> Graph(Nil, Int) {
  case next_node >= n {
    True -> graph
    False -> {
      // Connect next_node to a random node already in tree
      let tree_list = set.to_list(in_tree)
      let tree_size = list.length(tree_list)
      let index = int.random(tree_size)

      case list_at(tree_list, index) {
        Ok(parent) -> {
          let new_graph =
            model.add_edge(graph, from: parent, to: next_node, with: 1)
          let new_in_tree = set.insert(in_tree, next_node)
          build_random_tree(new_graph, n, new_in_tree, next_node + 1)
        }
        Error(_) -> graph
      }
    }
  }
}

// Helper: Create n nodes with Nil data and sequential IDs
fn create_nodes(graph: Graph(Nil, e), n: Int) -> Graph(Nil, e) {
  utils.range(0, n - 1)
  |> list.fold(graph, fn(g, i) { model.add_node(g, i, Nil) })
}

// Helper: Get element at index from list
fn list_at(lst: List(a), index: Int) -> Result(a, Nil) {
  case index, lst {
    0, [first, ..] -> Ok(first)
    n, [_, ..rest] if n > 0 -> list_at(rest, n - 1)
    _, _ -> Error(Nil)
  }
}
