//// Graph generators for creating various types of graphs.
////
//// This module provides functions to generate well-known graph structures,
//// including both classic deterministic patterns and random (stochastic) models.
////
//// ## Classic Generators
////
//// - **Complete graphs**: K_n where every node connects to every other.
//// - **Cycles**: C_n nodes forming a ring.
//// - **Paths**: P_n linear chains.
//// - **Stars**: Central hub with spokes.
//// - **Wheels**: Cycle with a central hub.
//// - **Bipartite**: Complete bipartite graphs K_{m,n}.
//// - **Trees**: Binary trees and hierarchical structures.
//// - **Grids**: 2D lattices.
//// - **Famous graphs**: The Petersen graph.
////
//// ## Random Generators
////
//// - **Erdős-Rényi**: Random graphs with uniform edge probability.
//// - **Barabási-Albert**: Scale-free networks with preferential attachment.
//// - **Watts-Strogatz**: Small-world networks with high clustering.
//// - **Random trees**: Uniformly random spanning trees.
////
//// ## Example
////
//// ```gleam
//// import yog/generators
////
//// pub fn main() {
////   // Generate classic patterns
////   let complete = generators.complete(5)
////   let cycle = generators.cycle(6)
////
////   // Generate random graphs
////   let random = generators.erdos_renyi_gnp(100, 0.05)
//// }
//// ```

import yog/internal/generators/classic
import yog/internal/generators/random

// --- Classic Generators ---

/// Generates a complete graph K_n where every node is connected to every other node.
///
/// In a complete graph with n nodes, there are n(n-1)/2 edges for undirected
/// graphs and n(n-1) edges for directed graphs. All edges have unit weight (1).
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// let k5 = generators.complete(5)
/// ```
pub const complete = classic.complete

/// Generates a complete graph with specified graph type.
pub const complete_with_type = classic.complete_with_type

/// Generates a cycle graph C_n where nodes form a ring.
///
/// A cycle graph connects n nodes in a circular pattern:
/// 0 -> 1 -> 2 -> ... -> (n-1) -> 0. All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let c6 = generators.cycle(6)
/// ```
pub const cycle = classic.cycle

/// Generates a cycle graph with specified graph type.
pub const cycle_with_type = classic.cycle_with_type

/// Generates a path graph P_n where nodes form a linear chain.
///
/// A path graph connects n nodes in a line: 0 - 1 - 2 - ... - (n-1).
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let p5 = generators.path(5)
/// ```
pub const path = classic.path

/// Generates a path graph with specified graph type.
pub const path_with_type = classic.path_with_type

/// Generates a star graph where one central node is connected to all others.
///
/// Node 0 is the center, connected to nodes 1 through n-1. All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let s6 = generators.star(6)
/// ```
pub const star = classic.star

/// Generates a star graph with specified graph type.
pub const star_with_type = classic.star_with_type

/// Generates a wheel graph: a cycle with a central hub.
///
/// A wheel graph is a cycle of n-1 nodes with an additional central node
/// connected to all nodes in the cycle. Node 0 is the center.
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let w6 = generators.wheel(6)
/// ```
pub const wheel = classic.wheel

/// Generates a wheel graph with specified graph type.
pub const wheel_with_type = classic.wheel_with_type

/// Generates a complete bipartite graph K_{m,n}.
///
/// A complete bipartite graph has two partitions of nodes where every node
/// in the first partition is connected to every node in the second partition.
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(mn)
///
/// ## Example
///
/// ```gleam
/// let k33 = generators.complete_bipartite(3, 3)
/// ```
pub const complete_bipartite = classic.complete_bipartite

/// Generates a complete bipartite graph with specified graph type.
pub const complete_bipartite_with_type = classic.complete_bipartite_with_type

/// Generates an empty graph with n nodes and no edges.
///
/// **Time Complexity:** O(n)
///
/// ## Example
///
/// ```gleam
/// let empty = generators.empty(10)
/// ```
pub const empty = classic.empty

/// Generates an empty graph with specified graph type.
pub const empty_with_type = classic.empty_with_type

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
/// let tree = generators.binary_tree(3)
/// ```
pub const binary_tree = classic.binary_tree

/// Generates a complete binary tree with specified graph type.
pub const binary_tree_with_type = classic.binary_tree_with_type

/// Generates a 2D grid graph (lattice).
///
/// Creates a grid of rows × cols nodes arranged in a rectangular lattice.
/// Node IDs are assigned row-major: node_id = row * cols + col.
/// All edges have unit weight (1).
///
/// **Time Complexity:** O(rows * cols)
///
/// ## Example
///
/// ```gleam
/// let grid = generators.grid_2d(3, 4)
/// ```
pub const grid_2d = classic.grid_2d

/// Generates a 2D grid graph with specified graph type.
pub const grid_2d_with_type = classic.grid_2d_with_type

/// Generates a Petersen graph.
///
/// The Petersen graph has 10 nodes and 15 edges. All edges have unit weight (1).
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let petersen = generators.petersen()
/// ```
pub const petersen = classic.petersen

/// Generates a Petersen graph with specified graph type.
pub const petersen_with_type = classic.petersen_with_type

// --- Random Generators ---

/// Generates a random graph using the Erdős-Rényi G(n, p) model.
///
/// Each possible edge is included independently with probability p.
///
/// **Time Complexity:** O(n²)
///
/// ## Example
///
/// ```gleam
/// let graph = generators.erdos_renyi_gnp(50, 0.1)
/// ```
pub const erdos_renyi_gnp = random.erdos_renyi_gnp

/// Generates an Erdős-Rényi G(n, p) graph with specified graph type.
pub const erdos_renyi_gnp_with_type = random.erdos_renyi_gnp_with_type

/// Generates a random graph using the Erdős-Rényi G(n, m) model.
///
/// Exactly m edges are added uniformly at random (without replacement).
///
/// **Time Complexity:** O(m) expected
///
/// ## Example
///
/// ```gleam
/// let graph = generators.erdos_renyi_gnm(50, 100)
/// ```
pub const erdos_renyi_gnm = random.erdos_renyi_gnm

/// Generates an Erdős-Rényi G(n, m) graph with specified graph type.
pub const erdos_renyi_gnm_with_type = random.erdos_renyi_gnm_with_type

/// Generates a scale-free network using the Barabási-Albert model.
///
/// Starts with m₀ nodes in a complete graph, then adds nodes using preferential attachment
/// (probability proportional to node degree).
///
/// **Time Complexity:** O(nm)
///
/// ## Example
///
/// ```gleam
/// let graph = generators.barabasi_albert(100, 3)
/// ```
pub const barabasi_albert = random.barabasi_albert

/// Generates a Barabási-Albert graph with specified graph type.
pub const barabasi_albert_with_type = random.barabasi_albert_with_type

/// Generates a small-world network using the Watts-Strogatz model.
///
/// Creates a ring lattice where each node connects to k nearest neighbors,
/// then rewires each edge with probability p.
///
/// **Time Complexity:** O(nk)
///
/// ## Example
///
/// ```gleam
/// let graph = generators.watts_strogatz(100, 4, 0.1)
/// ```
pub const watts_strogatz = random.watts_strogatz

/// Generates a Watts-Strogatz graph with specified graph type.
pub const watts_strogatz_with_type = random.watts_strogatz_with_type

/// Generates a uniformly random tree on n nodes.
///
/// Uses a random walk approach to generate a spanning tree.
///
/// **Time Complexity:** O(n²) expected
///
/// ## Example
///
/// ```gleam
/// let tree = generators.random_tree(50)
/// ```
pub const random_tree = random.random_tree

/// Generates a random tree with specified graph type.
pub const random_tree_with_type = random.random_tree_with_type
