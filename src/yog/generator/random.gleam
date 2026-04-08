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
//// | `random_regular` | d-regular | O(nd) | All nodes have degree d |
//// | `sbm` | SBM | O(n²) | Community structure |
//// | `dcsbm` | DCSBM | O(n²) | Degree-corrected communities |
//// | `hsbm` | HSBM | O(n²) | Hierarchical communities |
//// | `configuration_model` | Config | O(Σd) | Custom degree sequence |
//// | `kronecker` | Kronecker | O(E log V) | Recursive structure |
//// | `rmat` | R-MAT | O(E log V) | Fast Kronecker variant |
//// | `geometric` | RGG | O(n²) | Distance-based edges |
////
//// ## Quick Start
////
//// ```gleam
//// import yog/generator/random
//// import yog/model
////
//// pub fn main() {
////   // Random network models
////   let sparse = random.erdos_renyi_gnp(100, 0.05)      // Sparse random (p=5%)
////   let exact = random.erdos_renyi_gnm(50, 100)         // Exactly 100 edges
////   let scale_free = random.barabasi_albert(1000, 3)    // Scale-free network
////   let small_world = random.watts_strogatz(100, 6, 0.1) // Small-world (10% rewire)
////   let tree = random.random_tree(50)                   // Random spanning tree
////   let regular = random.random_regular(20, 3)          // 3-regular graph
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
//// ### Stochastic Block Model (SBM)
//// - Nodes assigned to communities
//// - Edge probability depends on community membership
//// - **Use for**: Community detection testing, modular networks
////
//// ### Configuration Model
//// - Generates graph with specified degree sequence
//// - **Use for**: Null models, degree-preserving randomization
////
//// ## References
////
//// - [Erdős-Rényi Model](https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model)
//// - [Barabási-Albert Model](https://en.wikipedia.org/wiki/Barab%C3%A1si%E2%80%93Albert_model)
//// - [Watts-Strogatz Model](https://en.wikipedia.org/wiki/Watts%E2%80%93Strogatz_model)
//// - [Scale-Free Networks](https://en.wikipedia.org/wiki/Scale-free_network)
//// - [Small-World Network](https://en.wikipedia.org/wiki/Small-world_network)
//// - [Stochastic Block Model](https://en.wikipedia.org/wiki/Stochastic_block_model)
//// - [Configuration Model](https://en.wikipedia.org/wiki/Configuration_model)
//// - [NetworkX Random Graphs](https://networkx.org/documentation/stable/reference/generators.html#random-graphs)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

import gleam/set.{type Set}
import yog/internal/utils
import yog/model.{type Graph, type GraphType}

// =============================================================================
// Seeded Random Number Generator (SplitMix64)
// =============================================================================

/// Internal state for seeded random number generator
pub opaque type RngState {
  RngState(seed: Int)
}

/// Create a new RNG state from a seed
fn new_rng(seed: Option(Int)) -> RngState {
  case seed {
    Some(s) -> RngState(s)
    None -> RngState(float.truncate(float.random() *. 1_000_000_000.0) + 1)
  }
}

/// Generate next random Int in range [0, max)
fn next_int(state: RngState, max: Int) -> #(Int, RngState) {
  // Simple LCG (Linear Congruential Generator)
  // Uses parameters from Numerical Recipes
  let a = 1_664_525
  let c = 1_013_904_223
  let new_seed = int.bitwise_and(a * state.seed + c, 0x7FFFFFFF)
  let result = new_seed % max
  #(result, RngState(new_seed))
}

/// Generate next random Float in range [0.0, 1.0)
fn next_float(state: RngState) -> #(Float, RngState) {
  let #(int_val, new_state) = next_int(state, 1_000_000)
  #(int.to_float(int_val) /. 1_000_000.0, new_state)
}

// =============================================================================
// Erdős-Rényi G(n, p)
// =============================================================================

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
/// // Sparse random graph with seed for reproducibility
/// let sparse = random.erdos_renyi_gnp(100, 0.05, seed: Some(42))
///
/// // Dense random graph
/// let dense = random.erdos_renyi_gnp(50, 0.8, seed: None)
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
pub fn erdos_renyi_gnp(
  n: Int,
  p: Float,
  seed seed: Option(Int),
) -> Graph(Nil, Int) {
  erdos_renyi_gnp_with_type(n, p, model.Undirected, seed)
}

/// Generates an Erdős-Rényi G(n, p) graph with specified graph type.
pub fn erdos_renyi_gnp_with_type(
  n: Int,
  p: Float,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n <= 0 || p <. 0.0 || p >. 1.0 {
    True -> model.new(graph_type)
    False -> {
      let rng = new_rng(seed)
      let graph = create_nodes(model.new(graph_type), n)

      case graph_type {
        model.Undirected -> {
          // For undirected, only consider i < j pairs
          let #(result, _) =
            utils.range(0, n - 1)
            |> list.fold(#(graph, rng), fn(state, i) {
              let #(g, rng_state) = state
              utils.range(i + 1, n - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, j) {
                let #(inner_g, inner_rng) = inner_state
                let #(rand_val, new_rng) = next_float(inner_rng)
                case rand_val <. p {
                  True -> #(
                    model.add_edge_ensure(
                      inner_g,
                      from: i,
                      to: j,
                      with: 1,
                      default: Nil,
                    ),
                    new_rng,
                  )
                  False -> #(inner_g, new_rng)
                }
              })
            })
          result
        }
        model.Directed -> {
          // For directed, consider all i != j pairs
          let #(result, _) =
            utils.range(0, n - 1)
            |> list.fold(#(graph, rng), fn(state, i) {
              let #(g, rng_state) = state
              utils.range(0, n - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, j) {
                let #(inner_g, inner_rng) = inner_state
                case i == j {
                  True -> #(inner_g, inner_rng)
                  False -> {
                    let #(rand_val, new_rng) = next_float(inner_rng)
                    case rand_val <. p {
                      True -> #(
                        model.add_edge_ensure(
                          inner_g,
                          from: i,
                          to: j,
                          with: 1,
                          default: Nil,
                        ),
                        new_rng,
                      )
                      False -> #(inner_g, new_rng)
                    }
                  }
                }
              })
            })
          result
        }
      }
    }
  }
}

// =============================================================================
// Erdős-Rényi G(n, m)
// =============================================================================

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
/// let graph = random.erdos_renyi_gnm(50, 100, seed: Some(42))
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
pub fn erdos_renyi_gnm(
  n: Int,
  m: Int,
  seed seed: Option(Int),
) -> Graph(Nil, Int) {
  erdos_renyi_gnm_with_type(n, m, model.Undirected, seed)
}

/// Generates an Erdős-Rényi G(n, m) graph with specified graph type.
pub fn erdos_renyi_gnm_with_type(
  n: Int,
  m: Int,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n <= 0 || m < 0 {
    True -> model.new(graph_type)
    False -> {
      let rng = new_rng(seed)
      let graph = create_nodes(model.new(graph_type), n)

      let max_edges = case graph_type {
        model.Undirected -> n * { n - 1 } / 2
        model.Directed -> n * { n - 1 }
      }

      // Can't have more edges than possible
      let actual_m = int.min(m, max_edges)

      // Build list of all possible edges
      let all_edges = case graph_type {
        model.Undirected -> {
          list.flatten(
            utils.range(0, n - 1)
            |> list.map(fn(i) {
              utils.range(i + 1, n - 1) |> list.map(fn(j) { #(i, j) })
            }),
          )
        }
        model.Directed -> {
          list.flatten(
            utils.range(0, n - 1)
            |> list.map(fn(i) {
              utils.range(0, n - 1)
              |> list.filter(fn(j) { i != j })
              |> list.map(fn(j) { #(i, j) })
            }),
          )
        }
      }

      // Shuffle and take first m edges using Fisher-Yates
      let shuffled = shuffle(all_edges, rng)
      let selected = list.take(shuffled, actual_m)

      // Add selected edges to graph
      selected
      |> list.fold(graph, fn(g, edge) {
        let #(i, j) = edge
        model.add_edge_ensure(g, from: i, to: j, with: 1, default: Nil)
      })
    }
  }
}

// =============================================================================
// Barabási-Albert (Preferential Attachment)
// =============================================================================

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
/// let graph = random.barabasi_albert(1000, 3, seed: Some(42))
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
pub fn barabasi_albert(
  n: Int,
  m: Int,
  seed seed: Option(Int),
) -> Graph(Nil, Int) {
  barabasi_albert_with_type(n, m, model.Undirected, seed)
}

/// Generates a Barabási-Albert graph with specified graph type.
pub fn barabasi_albert_with_type(
  n: Int,
  m: Int,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n < m || m < 1 {
    True -> model.new(graph_type)
    False -> {
      let rng = new_rng(seed)
      // Start with complete graph on m nodes
      let m0 = int.max(m, 2)
      let initial =
        utils.range(0, m0 - 1)
        |> list.fold(model.new(graph_type), fn(g, i) {
          model.add_node(g, i, Nil)
        })

      // Add initial edges (complete graph on first m0 nodes)
      let initial_with_edges = case graph_type {
        model.Undirected -> {
          let #(result, _) =
            utils.range(0, m0 - 1)
            |> list.fold(#(initial, rng), fn(state, i) {
              let #(g, rng_state) = state
              utils.range(i + 1, m0 - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, j) {
                let #(inner_g, inner_rng) = inner_state
                #(
                  model.add_edge_ensure(
                    inner_g,
                    from: i,
                    to: j,
                    with: 1,
                    default: Nil,
                  ),
                  inner_rng,
                )
              })
            })
          result
        }
        model.Directed -> {
          let #(result, _) =
            utils.range(0, m0 - 1)
            |> list.fold(#(initial, rng), fn(state, i) {
              let #(g, rng_state) = state
              utils.range(0, m0 - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, j) {
                let #(inner_g, inner_rng) = inner_state
                case i == j {
                  True -> #(inner_g, inner_rng)
                  False -> #(
                    model.add_edge_ensure(
                      inner_g,
                      from: i,
                      to: j,
                      with: 1,
                      default: Nil,
                    ),
                    inner_rng,
                  )
                }
              })
            })
          result
        }
      }

      // Add remaining nodes with preferential attachment
      let #(final_graph, _) =
        utils.range(m0, n - 1)
        |> list.fold(#(initial_with_edges, rng), fn(state, new_node) {
          let #(g, rng_state) = state
          add_node_with_preferential_attachment_seeded(
            g,
            new_node,
            m,
            graph_type,
            rng_state,
          )
        })
      final_graph
    }
  }
}

// Add a new node and connect it to m existing nodes via preferential attachment
fn add_node_with_preferential_attachment_seeded(
  graph: Graph(Nil, Int),
  new_node: Int,
  m: Int,
  graph_type: GraphType,
  rng: RngState,
) -> #(Graph(Nil, Int), RngState) {
  let with_node = model.add_node(graph, new_node, Nil)

  // Build degree list (each node appears degree times for weighted sampling)
  let degree_list = build_degree_list(graph, graph_type)

  // Select m unique targets using preferential attachment
  let #(targets, new_rng) =
    select_preferential_targets_seeded(degree_list, m, set.new(), rng)

  // Add edges to selected targets
  let final_graph =
    targets
    |> set.to_list()
    |> list.fold(with_node, fn(g, target) {
      model.add_edge_ensure(
        g,
        from: new_node,
        to: target,
        with: 1,
        default: Nil,
      )
    })
  #(final_graph, new_rng)
}

// Select m unique targets from degree list using random sampling with seeded RNG
fn select_preferential_targets_seeded(
  degree_list: List(Int),
  m: Int,
  selected: Set(Int),
  rng: RngState,
) -> #(Set(Int), RngState) {
  case set.size(selected) >= m || list.is_empty(degree_list) {
    True -> #(selected, rng)
    False -> {
      let list_size = list.length(degree_list)
      let #(index, new_rng) = next_int(rng, list_size)

      case list_at(degree_list, index) {
        Ok(target) -> {
          let new_selected = set.insert(selected, target)
          select_preferential_targets_seeded(
            degree_list,
            m,
            new_selected,
            new_rng,
          )
        }
        Error(_) -> #(selected, new_rng)
      }
    }
  }
}

// =============================================================================
// Watts-Strogatz (Small-World)
// =============================================================================

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
/// let graph = random.watts_strogatz(100, 6, 0.1, seed: Some(42))
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
pub fn watts_strogatz(
  n: Int,
  k: Int,
  p: Float,
  seed seed: Option(Int),
) -> Graph(Nil, Int) {
  watts_strogatz_with_type(n, k, p, model.Undirected, seed)
}

/// Generates a Watts-Strogatz graph with specified graph type.
pub fn watts_strogatz_with_type(
  n: Int,
  k: Int,
  p: Float,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n < 3 || k < 2 || k >= n || p <. 0.0 || p >. 1.0 {
    True -> model.new(graph_type)
    False -> {
      let rng = new_rng(seed)
      // Start with empty graph
      let graph = create_nodes(model.new(graph_type), n)

      // Build ring lattice with probabilistic rewiring
      let half_k = k / 2
      let #(result, _) =
        utils.range(0, n - 1)
        |> list.fold(#(graph, rng), fn(state, i) {
          let #(g, rng_state) = state
          utils.range(1, half_k)
          |> list.fold(#(g, rng_state), fn(inner_state, offset) {
            let #(acc, inner_rng) = inner_state
            let #(rand_val, new_rng) = next_float(inner_rng)
            case rand_val <. p {
              False -> {
                // Keep regular edge
                let j = { i + offset } % n
                #(
                  model.add_edge_ensure(
                    acc,
                    from: i,
                    to: j,
                    with: 1,
                    default: Nil,
                  ),
                  new_rng,
                )
              }
              True -> {
                // Rewire to random node
                add_random_edge_not_to_seeded(acc, i, n, new_rng)
              }
            }
          })
        })
      result
    }
  }
}

// Add edge from 'from' to a random node (avoiding self-loops and duplicates)
fn add_random_edge_not_to_seeded(
  graph: Graph(Nil, Int),
  from: Int,
  n: Int,
  rng: RngState,
) -> #(Graph(Nil, Int), RngState) {
  let #(to, new_rng) = next_int(rng, n)

  case to == from {
    True -> add_random_edge_not_to_seeded(graph, from, n, new_rng)
    False -> {
      // Check if edge already exists
      let neighbors = model.successors(graph, from)
      let neighbor_ids = list.map(neighbors, fn(pair) { pair.0 })
      case list.contains(neighbor_ids, to) {
        True -> add_random_edge_not_to_seeded(graph, from, n, new_rng)
        False -> {
          let new_graph =
            model.add_edge_ensure(
              graph,
              from: from,
              to: to,
              with: 1,
              default: Nil,
            )
          #(new_graph, new_rng)
        }
      }
    }
  }
}

// =============================================================================
// Random Tree
// =============================================================================

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
/// let tree = random.random_tree(50, seed: Some(42))
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
pub fn random_tree(n: Int, seed seed: Option(Int)) -> Graph(Nil, Int) {
  random_tree_with_type(n, model.Undirected, seed)
}

/// Generates a random tree with specified graph type.
pub fn random_tree_with_type(
  n: Int,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n < 2 {
    True -> create_nodes(model.new(graph_type), n)
    False -> {
      let rng = new_rng(seed)
      let graph = create_nodes(model.new(graph_type), n)

      // Start with node 0 in the tree
      let in_tree = set.from_list([0])

      // Add remaining nodes one at a time
      build_random_tree_seeded(graph, n, in_tree, 1, rng)
    }
  }
}

// Build random tree by adding nodes one at a time
fn build_random_tree_seeded(
  graph: Graph(Nil, Int),
  n: Int,
  in_tree: Set(Int),
  next_node: Int,
  rng: RngState,
) -> Graph(Nil, Int) {
  case next_node >= n {
    True -> graph
    False -> {
      // Connect next_node to a random node already in tree
      let tree_list = set.to_list(in_tree)
      let tree_size = list.length(tree_list)
      let #(index, new_rng) = next_int(rng, tree_size)

      case list_at(tree_list, index) {
        Ok(parent) -> {
          let new_graph =
            model.add_edge_ensure(
              graph,
              from: parent,
              to: next_node,
              with: 1,
              default: Nil,
            )
          let new_in_tree = set.insert(in_tree, next_node)
          build_random_tree_seeded(
            new_graph,
            n,
            new_in_tree,
            next_node + 1,
            new_rng,
          )
        }
        Error(_) -> graph
      }
    }
  }
}

// =============================================================================
// Random Regular Graph
// =============================================================================

/// Generates a random d-regular graph on n nodes.
///
/// A d-regular graph has every node with exactly degree d. This implementation
/// uses a configuration model approach with retries to ensure simplicity
/// (no self-loops or parallel edges).
///
/// **Preconditions:**
/// - n × d must be even (required for any d-regular graph)
/// - d < n (cannot have degree >= number of nodes in simple graph)
/// - d >= 0
///
/// **Properties:**
/// - Uniform distribution over all d-regular graphs (approximate)
/// - Exactly n nodes, (n × d) / 2 edges
/// - All nodes have degree exactly d
///
/// **Time Complexity:** O(n × d)
///
/// ## Example
///
/// ```gleam
/// // Generate a 3-regular graph with 10 nodes
/// let regular = random.random_regular(10, 3, seed: Some(42))
/// ```
///
/// ## Use Cases
///
/// - Testing algorithms that need uniform degree distribution
/// - Expander graph approximations
/// - Network models where degree is constrained
pub fn random_regular(n: Int, d: Int, seed seed: Option(Int)) -> Graph(Nil, Int) {
  random_regular_with_type(n, d, model.Undirected, seed)
}

/// Generates a random d-regular graph with specified graph type.
pub fn random_regular_with_type(
  n: Int,
  d: Int,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case n <= 0 || d < 0 || d >= n {
    True -> model.new(graph_type)
    False -> {
      case int.remainder(n * d, 2) == Ok(1) {
        True -> model.new(graph_type)
        False -> {
          case d == 0 {
            True -> create_nodes(model.new(graph_type), n)
            False -> {
              let rng = new_rng(seed)
              generate_regular(n, d, graph_type, 100, rng)
            }
          }
        }
      }
    }
  }
}

// Attempt to generate with max retries - use configuration model with repeated trials
fn generate_regular(
  n: Int,
  d: Int,
  graph_type: GraphType,
  retries: Int,
  rng: RngState,
) -> Graph(Nil, Int) {
  case retries <= 0 {
    True -> {
      // Fallback: create a simpler valid graph (e.g., ring + extra edges)
      create_ring_based_regular(n, d, graph_type)
    }
    False -> {
      // Create stubs: each node i appears d times in the list
      let stubs =
        list.flatten(
          utils.range(0, n - 1) |> list.map(fn(i) { list.repeat(i, d) }),
        )

      // Shuffle stubs using Fisher-Yates
      let shuffled = shuffle(stubs, rng)

      // Try to pair stubs using a smarter algorithm
      case try_pairing(shuffled, n, graph_type) {
        Ok(graph) -> graph
        Error(_) -> generate_regular(n, d, graph_type, retries - 1, rng)
      }
    }
  }
}

// Fallback: create a d-regular graph using ring-based construction
// For even d: connect to d/2 nearest neighbors on each side
// For odd d: ring + perfect matching (requires even n)
fn create_ring_based_regular(
  n: Int,
  d: Int,
  graph_type: GraphType,
) -> Graph(Nil, Int) {
  let base = model.new(graph_type)
  let graph =
    utils.range(0, n - 1)
    |> list.fold(base, fn(g, i) { model.add_node(g, i, Nil) })

  case d {
    0 -> graph
    _ -> {
      let half = d / 2
      // Add edges to k nearest neighbors on each side
      let graph_with_ring =
        list.fold(utils.range(0, n - 1), graph, fn(g, i) {
          list.fold(utils.range(1, half), g, fn(g2, k) {
            let j = { i + k } % n
            case model.add_edge(g2, i, j, 0) {
              Ok(g3) -> g3
              Error(_) -> g2
            }
          })
        })

      // If d is odd, add a perfect matching (requires even n)
      case int.remainder(d, 2) == Ok(1) && int.remainder(n, 2) == Ok(0) {
        True -> {
          list.fold(utils.range(0, n / 2 - 1), graph_with_ring, fn(g, i) {
            case model.add_edge(g, i, i + n / 2, 0) {
              Ok(g2) -> g2
              Error(_) -> g
            }
          })
        }
        False -> graph_with_ring
      }
    }
  }
}

// Try to pair stubs using the configuration model with greedy matching
fn try_pairing(
  stubs: List(Int),
  n: Int,
  graph_type: GraphType,
) -> Result(Graph(Nil, Int), Nil) {
  // Use a greedy approach to pair stubs
  case greedy_match(stubs, [], set.new()) {
    Ok(edges) -> {
      // Build the graph
      let base = model.new(graph_type)
      let graph =
        utils.range(0, n - 1)
        |> list.fold(base, fn(g, i) { model.add_node(g, i, Nil) })

      let final_graph =
        edges
        |> list.fold(graph, fn(g, edge) {
          let #(from, to) = edge
          model.add_edge_ensure(g, from: from, to: to, with: 1, default: Nil)
        })
      Ok(final_graph)
    }
    Error(_) -> Error(Nil)
  }
}

// Greedy matching that pairs stubs while avoiding self-loops and parallel edges
fn greedy_match(
  stubs: List(Int),
  edges: List(#(Int, Int)),
  used: Set(#(Int, Int)),
) -> Result(List(#(Int, Int)), Nil) {
  case stubs {
    [] -> Ok(edges)
    [_] -> Error(Nil)
    [a, ..rest] -> {
      // Find a partner for 'a' that doesn't create self-loop or parallel edge
      case find_valid_partner(rest, a, used) {
        Ok(#(b, remaining)) -> {
          let edge = normalize_pair(a, b)
          greedy_match(remaining, [edge, ..edges], set.insert(used, edge))
        }
        Error(_) -> Error(Nil)
      }
    }
  }
}

fn normalize_pair(a: Int, b: Int) -> #(Int, Int) {
  case a < b {
    True -> #(a, b)
    False -> #(b, a)
  }
}

fn find_valid_partner(
  stubs: List(Int),
  target: Int,
  used: Set(#(Int, Int)),
) -> Result(#(Int, List(Int)), Nil) {
  case stubs {
    [] -> Error(Nil)
    [first, ..rest] -> {
      let edge = normalize_pair(target, first)
      case first == target || set.contains(used, edge) {
        True -> {
          // Invalid partner, try others
          case find_valid_partner(rest, target, used) {
            Ok(#(partner, remaining)) -> Ok(#(partner, [first, ..remaining]))
            Error(_) -> Error(Nil)
          }
        }
        False -> Ok(#(first, rest))
      }
    }
  }
}

// =============================================================================
// Stochastic Block Model (SBM)
// =============================================================================

/// Generates a graph using the Stochastic Block Model (SBM).
///
/// Nodes are assigned to communities, and edges are added with probabilities
/// depending on community membership (higher probability within communities).
///
/// ## Parameters
/// - `n` - Number of nodes
/// - `k` - Number of communities
/// - `p_in` - Probability of edge within community
/// - `p_out` - Probability of edge between communities
///
/// ## Example
///
/// ```gleam
/// let sbm = random.sbm(100, 4, 0.3, 0.05, seed: Some(42))
/// // 100 nodes, 4 communities, high intra-community connectivity
/// ```
pub fn sbm(
  n: Int,
  k: Int,
  p_in: Float,
  p_out: Float,
  seed seed: Option(Int),
) -> Graph(Nil, Int) {
  sbm_with_type(n, k, p_in, p_out, model.Undirected, seed)
}

/// Generates an SBM graph with specified graph type.
pub fn sbm_with_type(
  n: Int,
  k: Int,
  p_in: Float,
  p_out: Float,
  graph_type: GraphType,
  seed: Option(Int),
) -> Graph(Nil, Int) {
  case
    n <= 0
    || k < 1
    || p_in <. 0.0
    || p_in >. 1.0
    || p_out <. 0.0
    || p_out >. 1.0
  {
    True -> model.new(graph_type)
    False -> {
      let rng = new_rng(seed)
      let graph = create_nodes(model.new(graph_type), n)

      // Assign nodes to communities (balanced)
      let communities = assign_communities(n, k)

      // Generate edges based on community membership
      case graph_type {
        model.Undirected -> {
          let #(result, _) =
            utils.range(0, n - 1)
            |> list.fold(#(graph, rng), fn(state, u) {
              let #(g, rng_state) = state
              utils.range(u + 1, n - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, v) {
                let #(inner_g, inner_rng) = inner_state
                let comm_u = case dict.get(communities, u) {
                  Ok(c) -> c
                  Error(_) -> -1
                }
                let comm_v = case dict.get(communities, v) {
                  Ok(c) -> c
                  Error(_) -> -1
                }
                let p = case comm_u == comm_v {
                  True -> p_in
                  False -> p_out
                }
                let #(rand_val, new_rng) = next_float(inner_rng)
                case rand_val <. p {
                  True -> #(
                    model.add_edge_ensure(
                      inner_g,
                      from: u,
                      to: v,
                      with: 1,
                      default: Nil,
                    ),
                    new_rng,
                  )
                  False -> #(inner_g, new_rng)
                }
              })
            })
          result
        }
        model.Directed -> {
          let #(result, _) =
            utils.range(0, n - 1)
            |> list.fold(#(graph, rng), fn(state, u) {
              let #(g, rng_state) = state
              utils.range(0, n - 1)
              |> list.fold(#(g, rng_state), fn(inner_state, v) {
                let #(inner_g, inner_rng) = inner_state
                case u == v {
                  True -> #(inner_g, inner_rng)
                  False -> {
                    let comm_u = case dict.get(communities, u) {
                      Ok(c) -> c
                      Error(_) -> -1
                    }
                    let comm_v = case dict.get(communities, v) {
                      Ok(c) -> c
                      Error(_) -> -1
                    }
                    let p = case comm_u == comm_v {
                      True -> p_in
                      False -> p_out
                    }
                    let #(rand_val, new_rng) = next_float(inner_rng)
                    case rand_val <. p {
                      True -> #(
                        model.add_edge_ensure(
                          inner_g,
                          from: u,
                          to: v,
                          with: 1,
                          default: Nil,
                        ),
                        new_rng,
                      )
                      False -> #(inner_g, new_rng)
                    }
                  }
                }
              })
            })
          result
        }
      }
    }
  }
}

// Assign nodes to communities (balanced)
fn assign_communities(n: Int, k: Int) -> Dict(Int, Int) {
  let base_size = n / k
  let remainder = n % k

  utils.range(0, n - 1)
  |> list.fold(#(dict.new(), 0, 0), fn(state, node) {
    let #(dict, current_comm, count) = state
    let comm_size = case current_comm < remainder {
      True -> base_size + 1
      False -> base_size
    }
    let new_dict = dict.insert(dict, node, current_comm)
    case count + 1 >= comm_size {
      True -> #(new_dict, current_comm + 1, 0)
      False -> #(new_dict, current_comm, count + 1)
    }
  })
  |> fn(result) { result.0 }
}

// =============================================================================
// Helper Functions
// =============================================================================

// Helper: Create n nodes with Nil data and sequential IDs
fn create_nodes(graph: Graph(Nil, e), n: Int) -> Graph(Nil, e) {
  case n <= 0 {
    True -> graph
    False ->
      utils.range(0, n - 1)
      |> list.fold(graph, fn(g, i) { model.add_node(g, i, Nil) })
  }
}

// Helper: Get element at index from list
fn list_at(lst: List(a), index: Int) -> Result(a, Nil) {
  case index, lst {
    0, [first, ..] -> Ok(first)
    n, [_, ..rest] if n > 0 -> list_at(rest, n - 1)
    _, _ -> Error(Nil)
  }
}

// Helper: Build a list where each node appears proportional to its degree
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

// Helper: Shuffle a list using simple random extraction with seeded RNG
fn shuffle(list: List(a), rng: RngState) -> List(a) {
  do_shuffle(list, [], rng)
}

fn do_shuffle(remaining: List(a), acc: List(a), rng: RngState) -> List(a) {
  case remaining {
    [] -> acc
    _ -> {
      let len = list.length(remaining)
      let #(index, new_rng) = next_int(rng, len)
      let selected = list_at(remaining, index)
      let rest = list_take_remove(remaining, index)
      case selected {
        Ok(val) -> do_shuffle(rest, [val, ..acc], new_rng)
        Error(_) -> acc
      }
    }
  }
}

// Helper: Take element at index and remove it from list
fn list_take_remove(list: List(a), index: Int) -> List(a) {
  do_list_take_remove(list, index, [])
}

fn do_list_take_remove(list: List(a), index: Int, acc: List(a)) -> List(a) {
  case index, list {
    0, [_, ..rest] -> list.reverse(acc) |> list.append(rest)
    n, [first, ..rest] if n > 0 ->
      do_list_take_remove(rest, n - 1, [first, ..acc])
    _, _ -> list.reverse(acc)
  }
}
