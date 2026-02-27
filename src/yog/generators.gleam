//// Graph generators for creating various types of graphs.
////
//// This module provides convenient re-exports of graph generation functions
//// from specialized sub-modules:
////
//// - **`yog/generators/classic`** - Classic graph patterns (complete, cycle, path, star, etc.)
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
//// }
//// ```
////
//// For more specialized generators, import the specific module:
////
//// ```gleam
//// import yog/generators/classic
////
//// let petersen = classic.petersen()
//// ```

// Re-export commonly used classic patterns for convenience
import yog/generators/classic

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
