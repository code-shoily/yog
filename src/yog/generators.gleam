//// Graph generators for creating various types of graphs.
////
//// This module provides convenient re-exports of graph generation functions
//// from specialized sub-modules:
////
//// - **`yog/generators/classic`** - Deterministic graph patterns (complete, cycle, path, star, etc.)
//// - **`yog/generators/random`** - Stochastic graph models (Erdős-Rényi, Barabási-Albert, Watts-Strogatz, etc.)
////
//// ## Quick Start
////
//// ```gleam
//// import yog/generators
////
//// pub fn main() {
////   // Generate classic patterns
////   let complete = generators.complete(5)
////   let cycle = generators.cycle(6)
////   let tree = generators.binary_tree(3)
////
////   // Generate random graphs
////   let random = generators.erdos_renyi_gnp(100, 0.05)
////   let scale_free = generators.barabasi_albert(100, 3)
////   let small_world = generators.watts_strogatz(100, 4, 0.1)
//// }
//// ```
////
//// For more specialized generators, import the specific module:
////
//// ```gleam
//// import yog/generators/classic
//// import yog/generators/random
////
//// let petersen = classic.petersen()
//// let er_graph = random.erdos_renyi_gnm(50, 100)
//// ```

// Re-export commonly used patterns for convenience
import yog/generators/classic
import yog/generators/random

// Complete graphs
pub const complete = classic.complete

pub const complete_with_type = classic.complete_with_type

// Cycles
pub const cycle = classic.cycle

pub const cycle_with_type = classic.cycle_with_type

// Paths
pub const path = classic.path

pub const path_with_type = classic.path_with_type

// Stars
pub const star = classic.star

pub const star_with_type = classic.star_with_type

// Wheels
pub const wheel = classic.wheel

pub const wheel_with_type = classic.wheel_with_type

// Bipartite
pub const complete_bipartite = classic.complete_bipartite

pub const complete_bipartite_with_type = classic.complete_bipartite_with_type

// Empty graphs
pub const empty = classic.empty

pub const empty_with_type = classic.empty_with_type

// Trees
pub const binary_tree = classic.binary_tree

pub const binary_tree_with_type = classic.binary_tree_with_type

// Grids
pub const grid_2d = classic.grid_2d

pub const grid_2d_with_type = classic.grid_2d_with_type

// Famous graphs
pub const petersen = classic.petersen

pub const petersen_with_type = classic.petersen_with_type

// Random graphs
pub const erdos_renyi_gnp = random.erdos_renyi_gnp

pub const erdos_renyi_gnp_with_type = random.erdos_renyi_gnp_with_type

pub const erdos_renyi_gnm = random.erdos_renyi_gnm

pub const erdos_renyi_gnm_with_type = random.erdos_renyi_gnm_with_type

pub const barabasi_albert = random.barabasi_albert

pub const barabasi_albert_with_type = random.barabasi_albert_with_type

pub const watts_strogatz = random.watts_strogatz

pub const watts_strogatz_with_type = random.watts_strogatz_with_type

pub const random_tree = random.random_tree

pub const random_tree_with_type = random.random_tree_with_type
