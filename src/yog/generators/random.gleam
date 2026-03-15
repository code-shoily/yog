//// Stochastic graph generators for random graph models.
////
//// Random generators use randomness to model real-world networks with properties
//// like scale-free distributions, small-world effects, and community structure.
////
//// ## Available Generators
////
//// | Generator | Model | Complexity | Key Property |
//// |-----------|-------|------------|--------------|
//// | `erdos_renyi_gnp` | G(n, p) | O(n²) | Each edge with probability p |
//// | `erdos_renyi_gnm` | G(n, m) | O(m) | Exactly m random edges |
//// | `barabasi_albert` | Preferential | O(nm) | Scale-free (power-law degrees) |
//// | `watts_strogatz` | Small-world | O(nk) | High clustering + short paths |
//// | `random_tree` | Uniform tree | O(n²) | Uniformly random spanning tree |
////
//// ## Quick Start
////
//// ```gleam
//// import yog/generators/random
//// import yog/model
////
//// pub fn main() {
////   // Random network models
////   let sparse = random.erdos_renyi_gnp(100, 0.05)      // Sparse random (p=5%)
////   let exact = random.erdos_renyi_gnm(50, 100)         // Exactly 100 edges
////   let scale_free = random.barabasi_albert(1000, 3)    // Scale-free network
////   let small_world = random.watts_strogatz(100, 6, 0.1) // Small-world (10% rewire)
////   let tree = random.random_tree(50)                   // Random spanning tree
//// }
//// ```
////
//// ## Network Models Explained
////
//// ### Erdős-Rényi G(n, p)
//// - Each possible edge included independently with probability p
//// - Expected edges: p × n(n-1)/2 (undirected) or p × n(n-1) (directed)
//// - Phase transition at p = 1/n (giant component emerges)
//// - **Use for**: Random network modeling, percolation studies
////
//// ### Erdős-Rényi G(n, m)
//// - Exactly m edges added uniformly at random
//// - Uniform distribution over all graphs with n nodes and m edges
//// - **Use for**: Fixed edge count requirements, specific density testing
////
//// ### Barabási-Albert (Preferential Attachment)
//// - Starts with m₀ nodes, adds nodes connecting to m existing nodes
//// - New nodes prefer high-degree nodes ("rich get richer")
//// - Power-law degree distribution: P(k) ~ k^(-3)
//// - **Use for**: Social networks, citation networks, web graphs
////
//// ### Watts-Strogatz (Small-World)
//// - Starts with ring lattice (high clustering)
//// - Rewires edges with probability p (creates shortcuts)
//// - Balances local clustering with global connectivity
//// - **Use for**: Social networks, neural networks, epidemic modeling
////
//// ### Random Tree
//// - Builds tree by connecting new nodes to random existing nodes
//// - Produces uniform distribution over all labeled trees
//// - **Use for**: Spanning trees, hierarchical structures
////
//// ## References
////
//// - [Erdős-Rényi Model](https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model)
//// - [Barabási-Albert Model](https://en.wikipedia.org/wiki/Barab%C3%A1si%E2%80%93Albert_model)
//// - [Watts-Strogatz Model](https://en.wikipedia.org/wiki/Watts%E2%80%93Strogatz_model)
//// - [Scale-Free Networks](https://en.wikipedia.org/wiki/Scale-free_network)
//// - [Small-World Network](https://en.wikipedia.org/wiki/Small-world_network)
//// - [NetworkX Random Graphs](https://networkx.org/documentation/stable/reference/generators.html#random-graphs)

import gleam/float
import gleam/int
import gleam/list
import gleam/set.{type Set}
import yog/internal/utils
import yog/model.{type Graph, type GraphType}

/// Generates a random graph using the Erdős-Rényi G(n, p) model.
///
/// Each possible edge is included independently with probability p.
/// For undirected graphs, each unordered pair is considered once.
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// // Sparse random graph
/// let sparse = random.erdos_renyi_gnp(100, 0.05)
///
/// // Dense random graph
/// let dense = random.erdos_renyi_gnp(50, 0.8)
/// ```
///
/// ## Properties
///
/// - Expected number of edges: p × n(n-1)/2 (undirected) or p × n(n-1) (directed)
/// - Phase transition at p = 1/n (giant component emerges)
///
/// ## Use Cases
///
/// - Random network modeling
/// - Percolation studies
/// - Average-case algorithm analysis
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
/// Unlike G(n, p) which includes each edge independently with probability p,
/// G(n, m) guarantees exactly m edges in the resulting graph.
///
/// **Time Complexity:** O(m) expected
///
/// ## Example
///
/// ```gleam
/// // Random graph with 50 nodes and exactly 100 edges
/// let graph = random.erdos_renyi_gnm(50, 100)
/// ```
///
/// ## Properties
///
/// - Exactly m edges (unlike G(n,p) which has expected m edges)
/// - Uniform distribution over all graphs with n nodes and m edges
///
/// ## Use Cases
///
/// - Fixed edge count requirements
/// - Random graph benchmarking
/// - Testing with specific densities
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
/// Creates a random graph with a power-law degree distribution (scale-free).
/// New nodes preferentially attach to existing high-degree nodes ("rich get richer").
///
/// **Time Complexity:** O(nm)
///
/// ## Example
///
/// ```gleam
/// // Scale-free network with 1000 nodes, each connecting to 3 existing nodes
/// let graph = random.barabasi_albert(1000, 3)
/// ```
///
/// ## Properties
///
/// - Power-law degree distribution: P(k) ~ k^(-3)
/// - Hub nodes with very high degree
/// - Small-world properties
///
/// ## Use Cases
///
/// - Social network modeling
/// - Citation network analysis
/// - Web graph simulation
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
/// Generates a graph with both high clustering (like regular lattices)
/// and short path lengths (like random graphs). Starts with a ring
/// lattice and rewires edges with probability p.
///
/// **Time Complexity:** O(nk)
///
/// ## Example
///
/// ```gleam
/// // Small-world network: 100 nodes, 6 neighbors each, 10% rewiring
/// let graph = random.watts_strogatz(100, 6, 0.1)
/// ```
///
/// ## Properties
///
/// - High clustering coefficient
/// - Short average path length
/// - p=0: regular lattice, p=1: random graph
///
/// ## Use Cases
///
/// - Social network modeling (six degrees of separation)
/// - Neural network topology
/// - Epidemic spread modeling
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
/// Creates a tree by starting with node 0 and repeatedly connecting
/// new nodes to random nodes already in the tree. This produces a
/// uniform distribution over all labeled trees.
///
/// **Time Complexity:** O(n²) expected
///
/// ## Example
///
/// ```gleam
/// let tree = random.random_tree(50)
/// // Random tree with 50 nodes, 49 edges
/// ```
///
/// ## Properties
///
/// - Exactly n-1 edges (tree property)
/// - Connected
/// - Acyclic
/// - Uniform distribution over all labeled trees
///
/// ## Use Cases
///
/// - Random spanning tree generation
/// - Tree algorithm testing
/// - Network topology generation
/// - Phylogenetic tree simulation
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
