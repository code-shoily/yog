//// Maze generation algorithms for creating perfect mazes.
////
//// Perfect mazes are spanning trees on a grid where every cell connects to every
//// other cell via exactly one path (no loops, no isolated areas).
////
//// Based on "Mazes for Programmers" by Jamis Buck.
////
//// ## Quick Start
////
//// ```gleam
//// // Generate a maze using the Recursive Backtracker algorithm
//// let maze = maze.recursive_backtracker(20, 20, seed: Some(42))
//// // Use ascii renderer
//// grid_to_string(maze) |> io.println
//// ```
////
//// ## Algorithms
////
//// | Algorithm | Speed | Bias | Best For |
//// |-----------|-------|------|----------|
//// | `binary_tree` | O(N) | Diagonal | Simplest, fastest |
//// | `sidewinder` | O(N) | Vertical | Memory constrained |
//// | `recursive_backtracker` | O(N) | Corridors | Games, roguelikes |
//// | `hunt_and_kill` | O(V²) | Winding | Few dead ends |
//// | `aldous_broder` | O(V²) | None | Uniform randomness |
//// | `wilson` | O(V) avg | None | Efficient uniform |
//// | `kruskal` | O(N log N) | None | Balanced corridors |
//// | `prim_simplified` | O(N log N) | Radial | Many dead ends |
//// | `prim_true` | O(N log N) | Jigsaw | Dense texture |
//// | `ellers` | O(N) | Horizontal | Infinite height mazes |
//// | `growing_tree` | O(N) | Varies | Versatility |
//// | `recursive_division` | O(N log N) | Rectangular | Rooms, fractal feel |
////
//// ## Output Format
////
//// All algorithms return a `yog/builder/grid.Grid` that can be:
//// - Rendered with `yog/render/ascii`
//// - Converted to a plain graph with `grid.to_graph/1`
//// - Used with pathfinding algorithms
////
//// ## References
////
//// - *Mazes for Programmers* by Jamis Buck (Pragmatic Bookshelf, 2015)
////

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/set
import yog/builder/grid.{type Grid, Grid}
import yog/disjoint_set
import yog/internal/priority_queue
import yog/internal/random
import yog/internal/util
import yog/model.{Undirected}

/// Direction bias for the Binary Tree algorithm.
pub type BinaryTreeBias {
  NorthEast
  NorthWest
  SouthEast
  SouthWest
}

/// Generates a maze using the Binary Tree algorithm.
///
/// The simplest maze algorithm. For each cell, randomly carves a passage
/// to either the north or east neighbor (or other chosen bias). Creates
/// an unbroken corridor along two boundaries.
///
/// ## Characteristics
///
/// - **Time**: O(N) where N = rows × cols
/// - **Space**: O(1) auxiliary
/// - **Bias**: Strong diagonal (NE by default)
/// - **Texture**: Distinctive diagonal corridors
///
/// ## When to Use
///
/// - When speed is critical
/// - For educational demonstrations
/// - When predictable texture is acceptable
///
/// ## When NOT to Use
///
/// - When uniform randomness is required
/// - When aesthetic variety matters
/// ## Examples
///
/// ```gleam
/// let m = maze.binary_tree(5, 5, seed: Some(42))
/// // m.rows == 5
/// ```
pub fn binary_tree(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  binary_tree_with_options(rows, cols, NorthEast, seed)
}

/// Generates a maze using the Binary Tree algorithm with custom bias.
pub fn binary_tree_with_options(
  rows: Int,
  cols: Int,
  bias: BinaryTreeBias,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)

  let #(final_grid, _) = {
    use acc, row <- list.fold(util.range(0, rows - 1), #(base_grid, rng))
    use inner_acc, col <- list.fold(util.range(0, cols - 1), acc)
    let #(g, curr_rng) = inner_acc
    let neighbors = valid_binary_tree_neighbors(row, col, rows, cols, bias)

    case neighbors {
      [] -> #(g, curr_rng)
      [neighbor] -> {
        let next_g = add_passage(g, row, col, neighbor.0, neighbor.1)
        #(next_g, curr_rng)
      }
      _ -> {
        let #(idx, next_rng) = random.next_int(curr_rng, list.length(neighbors))
        let neighbor = case util.list_at(neighbors, idx) {
          Ok(n) -> n
          Error(_) -> #(0, 0)
        }
        let next_g = add_passage(g, row, col, neighbor.0, neighbor.1)
        #(next_g, next_rng)
      }
    }
  }

  final_grid
}

fn valid_binary_tree_neighbors(
  row: Int,
  col: Int,
  rows: Int,
  cols: Int,
  bias: BinaryTreeBias,
) -> List(#(Int, Int)) {
  let n = []

  case bias {
    NorthEast -> {
      let n = case row > 0 {
        True -> [#(row - 1, col), ..n]
        False -> n
      }
      case col < cols - 1 {
        True -> [#(row, col + 1), ..n]
        False -> n
      }
    }
    NorthWest -> {
      let n = case row > 0 {
        True -> [#(row - 1, col), ..n]
        False -> n
      }
      case col > 0 {
        True -> [#(row, col - 1), ..n]
        False -> n
      }
    }
    SouthEast -> {
      let n = case row < rows - 1 {
        True -> [#(row + 1, col), ..n]
        False -> n
      }
      case col < cols - 1 {
        True -> [#(row, col + 1), ..n]
        False -> n
      }
    }
    SouthWest -> {
      let n = case row < rows - 1 {
        True -> [#(row + 1, col), ..n]
        False -> n
      }
      case col > 0 {
        True -> [#(row, col - 1), ..n]
        False -> n
      }
    }
  }
}

/// Direction for the Sidewinder algorithm to carve.
pub type SidewinderDirection {
  North
  South
  East
  West
}

/// Generates a maze using the Sidewinder algorithm.
///
/// Row-based algorithm that creates vertical corridors.
///
/// ## Characteristics
///
/// - **Time**: O(N) where N = rows × cols
/// - **Space**: O(cols) - only tracks current run
/// - **Bias**: Vertical corridors (north-south)
/// - **Texture**: Long vertical passages with horizontal "rungs"
///
/// ## When to Use
///
/// - When you want vertical maze progression
/// - Memory-constrained environments
/// - Creating "floor" separation in games
///
/// ## When NOT to Use
///
/// - When you need horizontal bias
pub fn sidewinder(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  sidewinder_with_options(rows, cols, North, seed)
}

/// Generates a maze using the Sidewinder algorithm with custom direction.
pub fn sidewinder_with_options(
  rows: Int,
  cols: Int,
  direction: SidewinderDirection,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)

  let #(final_grid, _) = {
    use acc, row <- list.fold(util.range(0, rows - 1), #(base_grid, rng))
    let #(row_grid, row_rng) = acc
    let run = []
    carve_sidewinder_row(row_grid, row, cols, 0, run, row_rng, direction)
  }

  final_grid
}

fn carve_sidewinder_row(
  grid: Grid(Nil, Int),
  row: Int,
  cols: Int,
  col: Int,
  run: List(Int),
  rng: random.Rng,
  direction: SidewinderDirection,
) -> #(Grid(Nil, Int), random.Rng) {
  case col >= cols {
    True -> #(grid, rng)
    False -> {
      let run = [col, ..run]
      let at_boundary = col == cols - 1
      let at_secondary_boundary = case direction {
        North -> row == 0
        South -> row == grid.rows - 1
        East -> col == cols - 1
        West -> col == 0
      }

      let #(should_close, next_rng) = {
        let #(chance, r) = random.next_float(rng)
        #(at_boundary || { !at_secondary_boundary && chance >. 0.5 }, r)
      }

      let is_special_north = direction == North && row == grid.rows - 1
      let should_close =
        is_special_north && at_boundary || { !is_special_north && should_close }

      case should_close {
        True -> {
          let #(idx, r2) = random.next_int(next_rng, list.length(run))
          let cell_col = case util.list_at(run, idx) {
            Ok(c) -> c
            Error(_) -> col
          }

          let grid = case at_secondary_boundary {
            True -> grid
            False -> {
              let #(nr, nc) = case direction {
                North -> #(row - 1, cell_col)
                South -> #(row + 1, cell_col)
                East -> #(row, cell_col + 1)
                West -> #(row, cell_col - 1)
              }
              add_passage(grid, row, cell_col, nr, nc)
            }
          }

          let grid = case is_special_north && at_boundary {
            True -> {
              let #(idx, _) = random.next_int(next_rng, list.length(run))
              let r_col = case util.list_at(run, idx) {
                Ok(c) -> c
                Error(_) -> col
              }
              add_passage(grid, row, r_col, row - 1, r_col)
            }
            False -> grid
          }

          carve_sidewinder_row(grid, row, cols, col + 1, [], r2, direction)
        }
        False -> {
          add_passage(grid, row, col, row, col + 1)
          |> carve_sidewinder_row(row, cols, col + 1, run, next_rng, direction)
        }
      }
    }
  }
}

/// Generates a maze using the Recursive Backtracker algorithm (DFS).
///
/// Performs a random walk avoiding visited cells, backtracking when stuck.
/// Creates twisty mazes with long corridors - the most popular algorithm for games.
///
/// ## Characteristics
///
/// - **Time**: O(N) where N = rows × cols
/// - **Space**: O(N) for the explicit stack
/// - **Bias**: Twisty passages, long corridors
/// - **Texture**: Classic "roguelike" maze aesthetic
///
/// ## When to Use
///
/// - Games and roguelikes (most popular choice)
/// - When you want twisty, exploratory mazes
/// - Longest path puzzles
///
/// ## When NOT to Use
///
/// - If memory is extremely limited (N can be large)
/// ## Examples
///
/// ```gleam
/// let m = maze.recursive_backtracker(20, 20, seed: Some(123))
/// // Produces twisty corridors
/// ```
pub fn recursive_backtracker(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let #(start_idx, next_rng) = random.next_int(rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let visited = set.insert(set.new(), start_node)
  let stack = [start_node]

  do_recursive_backtracker(base_grid, stack, visited, rows, cols, next_rng)
}

fn do_recursive_backtracker(
  grid: Grid(Nil, Int),
  stack: List(#(Int, Int)),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case stack {
    [] -> grid
    [current, ..rest] -> {
      let neighbors = unvisited_neighbors(current, visited, rows, cols)
      case neighbors {
        [] -> do_recursive_backtracker(grid, rest, visited, rows, cols, rng)
        _ -> {
          let #(idx, next_rng) = random.next_int(rng, list.length(neighbors))
          let neighbor = case util.list_at(neighbors, idx) {
            Ok(n) -> n
            Error(_) -> current
          }

          grid
          |> add_passage(current.0, current.1, neighbor.0, neighbor.1)
          |> do_recursive_backtracker(
            [neighbor, current, ..rest],
            set.insert(visited, neighbor),
            rows,
            cols,
            next_rng,
          )
        }
      }
    }
  }
}

/// Scan mode for the Hunt-and-Kill algorithm.
pub type HuntScanMode {
  ScanSequential
  ScanRandom
}

/// Generates a maze using the Hunt-and-Kill algorithm.
///
/// Performs a random walk until stuck, then hunts for an unvisited cell
/// adjacent to the visited region.
///
/// ## Characteristics
///
/// - **Time**: O(N²) worst case
/// - **Space**: O(1) auxiliary
/// - **Bias**: High winding, dense
/// - **Texture**: Uniform but with fewer dead ends than others
///
/// ## When to Use
///
/// - When you want a maze with few dead ends
/// - When space is critical but time is less so
///
/// ## When NOT to Use
///
/// - Very large grids (O(N²) can be slow)
pub fn hunt_and_kill(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  hunt_and_kill_with_options(rows, cols, ScanSequential, seed)
}

/// Generates a maze using the Hunt-and-Kill algorithm with custom options.
pub fn hunt_and_kill_with_options(
  rows: Int,
  cols: Int,
  scan_mode: HuntScanMode,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let #(start_idx, next_rng) = random.next_int(rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let visited = set.insert(set.new(), start_node)

  do_hunt_and_kill(
    base_grid,
    start_node,
    visited,
    rows,
    cols,
    scan_mode,
    next_rng,
  )
}

fn do_hunt_and_kill(
  grid: Grid(Nil, Int),
  current: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  scan_mode: HuntScanMode,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  let unvisited = unvisited_neighbors(current, visited, rows, cols)
  case unvisited {
    [_, ..] -> {
      let #(idx, next_rng) = random.next_int(rng, list.length(unvisited))
      let neighbor = case util.list_at(unvisited, idx) {
        Ok(n) -> n
        Error(_) -> current
      }

      grid
      |> add_passage(current.0, current.1, neighbor.0, neighbor.1)
      |> do_hunt_and_kill(
        neighbor,
        set.insert(visited, neighbor),
        rows,
        cols,
        scan_mode,
        next_rng,
      )
    }
    [] -> {
      // Hunt phase
      case hunt(visited, rows, cols, scan_mode, rng) {
        option.Some(#(#(unvisited_cell, visited_neighbor), next_rng)) -> {
          let next_grid =
            add_passage(
              grid,
              unvisited_cell.0,
              unvisited_cell.1,
              visited_neighbor.0,
              visited_neighbor.1,
            )
          do_hunt_and_kill(
            next_grid,
            unvisited_cell,
            set.insert(visited, unvisited_cell),
            rows,
            cols,
            scan_mode,
            next_rng,
          )
        }
        option.None -> grid
      }
    }
  }
}

fn hunt(
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  scan_mode: HuntScanMode,
  rng: random.Rng,
) -> Option(#(#(#(Int, Int), #(Int, Int)), random.Rng)) {
  case scan_mode {
    ScanSequential -> {
      let result = {
        use acc, r <- list.fold(util.range(0, rows - 1), option.None)
        case acc {
          option.Some(_) -> acc
          option.None -> {
            use inner_acc, c <- list.fold(util.range(0, cols - 1), option.None)
            case inner_acc {
              option.Some(_) -> inner_acc
              option.None -> {
                let cell = #(r, c)
                case set.contains(visited, cell) {
                  True -> option.None
                  False -> {
                    let vn = visited_neighbors(cell, visited, rows, cols)
                    case vn {
                      [first, ..rest] -> option.Some(#(cell, [first, ..rest]))
                      [] -> option.None
                    }
                  }
                }
              }
            }
          }
        }
      }

      case result {
        option.Some(#(cell, vn)) -> {
          let #(idx, next_rng) = random.next_int(rng, list.length(vn))
          let neighbor = case util.list_at(vn, idx) {
            Ok(n) -> n
            Error(_) -> #(0, 0)
          }
          option.Some(#(#(cell, neighbor), next_rng))
        }
        option.None -> option.None
      }
    }
    ScanRandom -> {
      let unvisited = {
        util.range(0, rows - 1)
        |> list.map(fn(r) {
          util.range(0, cols - 1)
          |> list.map(fn(c) { #(r, c) })
        })
        |> list.flatten()
        |> list.filter(fn(c) { !set.contains(visited, c) })
      }

      let #(shuffled, next_rng) = random.shuffle(unvisited, rng)

      let res =
        list.find(shuffled, fn(c) {
          !list.is_empty(visited_neighbors(c, visited, rows, cols))
        })

      case res {
        Ok(cell) -> {
          let vn = visited_neighbors(cell, visited, rows, cols)
          let #(idx, final_rng) = random.next_int(next_rng, list.length(vn))
          let neighbor = case util.list_at(vn, idx) {
            Ok(n) -> n
            Error(_) -> #(0, 0)
          }
          option.Some(#(#(cell, neighbor), final_rng))
        }
        Error(_) -> option.None
      }
    }
  }
}

fn neighbors(row: Int, col: Int, rows: Int, cols: Int) -> List(#(Int, Int)) {
  [#(row - 1, col), #(row + 1, col), #(row, col - 1), #(row, col + 1)]
  |> list.filter(fn(pos) {
    pos.0 >= 0 && pos.0 < rows && pos.1 >= 0 && pos.1 < cols
  })
}

fn unvisited_neighbors(
  cell: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
) -> List(#(Int, Int)) {
  neighbors(cell.0, cell.1, rows, cols)
  |> list.filter(fn(n) { !set.contains(visited, n) })
}

fn visited_neighbors(
  cell: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
) -> List(#(Int, Int)) {
  neighbors(cell.0, cell.1, rows, cols)
  |> list.filter(fn(n) { set.contains(visited, n) })
}

/// Generates a maze using the Aldous-Broder algorithm.
///
/// Produces a truly uniform spanning tree using a random walk.
///
/// ## Characteristics
///
/// - **Time**: O(N²) worst case
/// - **Space**: O(1) auxiliary
/// - **Bias**: None
/// - **Texture**: Completely unbiased, uniform corridors
///
/// ## When to Use
///
/// - When mathematical lack of bias is required
/// - Small grids
///
/// ## When NOT to Use
///
/// - Large grids (highly inefficient)
pub fn aldous_broder(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let #(start_idx, next_rng) = random.next_int(rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let visited = set.insert(set.new(), start_node)
  let count = 1
  let total = rows * cols

  do_aldous_broder(
    base_grid,
    start_node,
    visited,
    count,
    total,
    rows,
    cols,
    next_rng,
  )
}

fn do_aldous_broder(
  grid: Grid(Nil, Int),
  current: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  count: Int,
  total: Int,
  rows: Int,
  cols: Int,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case count >= total {
    True -> grid
    False -> {
      let ns = neighbors(current.0, current.1, rows, cols)
      let len = list.length(ns)
      let #(idx, next_rng) = random.next_int(rng, len)
      let neighbor = case util.list_at(ns, idx) {
        Ok(n) -> n
        Error(_) -> current
      }

      case set.contains(visited, neighbor) {
        True ->
          do_aldous_broder(
            grid,
            neighbor,
            visited,
            count,
            total,
            rows,
            cols,
            next_rng,
          )
        False -> {
          let next_grid =
            add_passage(grid, current.0, current.1, neighbor.0, neighbor.1)
          do_aldous_broder(
            next_grid,
            neighbor,
            set.insert(visited, neighbor),
            count + 1,
            total,
            rows,
            cols,
            next_rng,
          )
        }
      }
    }
  }
}

/// Generates a maze using Wilson's algorithm.
///
/// Produces a uniform spanning tree using loop-erased random walks.
///
/// ## Characteristics
///
/// - **Time**: O(N) average
/// - **Space**: O(N) for current walk
/// - **Bias**: None
/// - **Texture**: Completely unbiased, elegant aesthetic
///
/// ## When to Use
///
/// - When you want a truly unbiased maze efficiently
/// - Generating perfect test data
///
/// ## When NOT to Use
///
/// - When you want specific hallway or corridor textures
pub fn wilson(rows: Int, cols: Int, seed seed: Option(Int)) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let cells =
    {
      use r <- list.map(util.range(0, rows - 1))
      use c <- list.map(util.range(0, cols - 1))
      #(r, c)
    }
    |> list.flatten()

  let #(shuffled, next_rng) = random.shuffle(cells, rng)
  let first = case list.first(shuffled) {
    Ok(f) -> f
    Error(_) -> #(0, 0)
  }
  let rest = case list.rest(shuffled) {
    Ok(r) -> r
    Error(_) -> []
  }

  let visited = set.insert(set.new(), first)
  let unvisited = rest

  do_wilson(base_grid, visited, unvisited, rows, cols, next_rng)
}

fn do_wilson(
  grid: Grid(Nil, Int),
  visited: set.Set(#(Int, Int)),
  unvisited: List(#(Int, Int)),
  rows: Int,
  cols: Int,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case unvisited {
    [] -> grid
    _ -> {
      // Pick a random unvisited cell
      let unvisited_len = list.length(unvisited)
      let #(idx, next_rng) = random.next_int(rng, unvisited_len)
      let start_cell = case util.list_at(unvisited, idx) {
        Ok(c) -> c
        Error(_) -> #(0, 0)
      }

      let #(path, _, final_rng) =
        random_walk_to_visited(
          start_cell,
          visited,
          [],
          set.new(),
          rows,
          cols,
          next_rng,
        )
      let #(next_grid, next_visited, next_unvisited) =
        carve_wilson_path(grid, path, visited, unvisited)
      do_wilson(next_grid, next_visited, next_unvisited, rows, cols, final_rng)
    }
  }
}

fn random_walk_to_visited(
  current: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  path: List(#(Int, Int)),
  path_set: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  rng: random.Rng,
) -> #(List(#(Int, Int)), set.Set(#(Int, Int)), random.Rng) {
  let #(new_path, new_path_set) = case set.contains(path_set, current) {
    False -> #([current, ..path], set.insert(path_set, current))
    True -> {
      // Use list.drop instead of custom truncate_at
      let revised = list.drop(path, 1)
      #([current, ..revised], set.insert(path_set, current))
    }
  }

  let ns = neighbors(current.0, current.1, rows, cols)
  let ns_len = list.length(ns)
  let #(idx, next_rng) = random.next_int(rng, ns_len)
  let neighbor = case util.list_at(ns, idx) {
    Ok(n) -> n
    Error(_) -> current
  }

  case set.contains(visited, neighbor) {
    True -> #([neighbor, ..new_path], new_path_set, next_rng)
    False ->
      random_walk_to_visited(
        neighbor,
        visited,
        new_path,
        new_path_set,
        rows,
        cols,
        next_rng,
      )
  }
}

fn carve_wilson_path(
  grid: Grid(Nil, Int),
  path: List(#(Int, Int)),
  visited: set.Set(#(Int, Int)),
  unvisited: List(#(Int, Int)),
) -> #(Grid(Nil, Int), set.Set(#(Int, Int)), List(#(Int, Int))) {
  let path = list.reverse(path)
  case path {
    [] | [_] -> #(grid, visited, unvisited)
    [v1, v2, ..rest] -> {
      let next_grid = add_passage(grid, v1.0, v1.1, v2.0, v2.1)
      let next_visited = set.insert(visited, v1)
      let next_unvisited = list.filter(unvisited, fn(u) { u != v1 })
      carve_wilson_path(next_grid, [v2, ..rest], next_visited, next_unvisited)
    }
  }
}

/// Selector strategy for the Growing Tree algorithm.
pub type GrowingTreeSelector {
  Last
  First
  Random
  Middle
  Mix(GrowingTreeSelector, Float)
}

/// Generates a maze using the Growing Tree algorithm.
///
/// A versatile algorithm that can simulate others depending on selection strategy.
///
/// ## Characteristics
///
/// - **Time**: O(N)
/// - **Space**: O(N) for active list
/// - **Bias**: Varies by strategy
/// - **Texture**: Varies by strategy
///
/// - `Last`: Simulates Recursive Backtracker
/// - `First`: Simulates very long, straight corridors
/// - `Random`: Simulates Simplified Prim's
/// - `Middle`: Unique hybrid texture
pub fn growing_tree(
  rows: Int,
  cols: Int,
  selector: GrowingTreeSelector,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let #(start_idx, next_rng) = random.next_int(rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let active = [start_node]
  let visited = set.insert(set.new(), start_node)

  do_growing_tree(base_grid, active, visited, rows, cols, selector, next_rng)
}

fn do_growing_tree(
  grid: Grid(Nil, Int),
  active: List(#(Int, Int)),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  selector: GrowingTreeSelector,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case active {
    [] -> grid
    _ -> {
      let len = list.length(active)
      let #(idx, next_rng) = case selector {
        Last -> #(len - 1, rng)
        First -> #(0, rng)
        Random -> random.next_int(rng, len)
        Middle -> #(len / 2, rng)
        Mix(s, prob) -> {
          let #(chance, r) = random.next_float(rng)
          case chance <. prob {
            True -> {
              let #(i, _) = select_index_simple(len, s, r)
              #(i, r)
            }
            False -> random.next_int(r, len)
          }
        }
      }

      let cell = case util.list_at(active, idx) {
        Ok(c) -> c
        Error(_) -> #(0, 0)
      }

      let unvisited = unvisited_neighbors(cell, visited, rows, cols)
      case unvisited {
        [] -> {
          // Use swap-and-pop (O(1)) instead of filter (O(N))
          let next_active = list_take_remove(active, idx)
          do_growing_tree(
            grid,
            next_active,
            visited,
            rows,
            cols,
            selector,
            next_rng,
          )
        }
        _ -> {
          let unvisited_len = list.length(unvisited)
          let #(idx2, final_rng) = random.next_int(next_rng, unvisited_len)
          let neighbor = case util.list_at(unvisited, idx2) {
            Ok(n) -> n
            Error(_) -> cell
          }

          let next_grid =
            add_passage(grid, cell.0, cell.1, neighbor.0, neighbor.1)
          do_growing_tree(
            next_grid,
            [neighbor, ..active],
            set.insert(visited, neighbor),
            rows,
            cols,
            selector,
            final_rng,
          )
        }
      }
    }
  }
}

/// Generates a maze using randomized Kruskal's algorithm.
///
/// Produces a uniform spanning tree by randomly merging disjoint sets.
///
/// ## Characteristics
///
/// - **Time**: O(N log N)
/// - **Space**: O(N) for set tracking
/// - **Bias**: None
/// - **Texture**: Balanced corridors, uniform distribution
///
/// ## When to Use
///
/// - When you want unbiased mazes on non-grid topologies
/// - For a balanced roguelike feel
pub fn kruskal(rows: Int, cols: Int, seed seed: Option(Int)) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)

  // Build edge list in a single pass to avoid intermediate lists
  let edges =
    util.range(0, rows - 1)
    |> list.fold([], fn(acc, r) {
      // Horizontal edges
      let h_edges =
        util.range(0, cols - 2)
        |> list.fold(acc, fn(h_acc, c) { [#(#(r, c), #(r, c + 1)), ..h_acc] })
      // Vertical edges
      case r < rows - 1 {
        True ->
          util.range(0, cols - 1)
          |> list.fold(h_edges, fn(v_acc, c) {
            [#(#(r, c), #(r + 1, c)), ..v_acc]
          })
        False -> h_edges
      }
    })

  let #(shuffled_edges, _) = random.shuffle(edges, rng)

  let dsu = disjoint_set.new()

  let #(final_grid, _) = {
    use acc, edge <- list.fold(shuffled_edges, #(base_grid, dsu))
    let #(g, d) = acc
    let #(u, v) = edge
    let #(d_next, are_connected) = disjoint_set.connected(d, u, v)

    case are_connected {
      True -> #(g, d_next)
      False -> {
        let next_g = add_passage(g, u.0, u.1, v.0, v.1)
        let next_d = disjoint_set.union(d_next, u, v)
        #(next_g, next_d)
      }
    }
  }

  final_grid
}

/// Generates a maze using the Simplified Prim's algorithm.
///
/// Creates mazes with strong radial texture and many dead ends.
///
/// ## Characteristics
///
/// - **Time**: O(N log N)
/// - **Space**: O(N) for frontier list
/// - **Bias**: Radial (spreads from start)
/// - **Texture**: Jigsaw-like, very dense with short corridors
///
/// ## When to Use
///
/// - When you want a dense maze with many branches
/// - To create paths that feel "grown" from a source
pub fn prim_simplified(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let #(start_idx, next_rng) = random.next_int(rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let visited = set.insert(set.new(), start_node)
  let frontier = neighbors(start_node.0, start_node.1, rows, cols)

  do_prim_simplified(base_grid, frontier, visited, rows, cols, next_rng)
}

fn do_prim_simplified(
  grid: Grid(Nil, Int),
  frontier: List(#(Int, Int)),
  visited: set.Set(#(Int, Int)),
  rows: Int,
  cols: Int,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case frontier {
    [] -> grid
    _ -> {
      let frontier_len = list.length(frontier)
      let #(idx, next_rng) = random.next_int(rng, frontier_len)
      let cell = case util.list_at(frontier, idx) {
        Ok(c) -> c
        Error(_) -> #(0, 0)
      }

      case set.contains(visited, cell) {
        True -> {
          // Use swap-and-pop (O(1)) instead of filter (O(N))
          let next_frontier = list_take_remove(frontier, idx)
          do_prim_simplified(grid, next_frontier, visited, rows, cols, next_rng)
        }
        False -> {
          let vn = visited_neighbors(cell, visited, rows, cols)
          let neighbor = case vn {
            [first, ..] -> first
            [] -> cell
          }

          let next_grid =
            add_passage(grid, cell.0, cell.1, neighbor.0, neighbor.1)
          let next_visited = set.insert(visited, cell)

          // Use swap-and-pop (O(1)) instead of filter (O(N))
          let frontier_without_cell = list_take_remove(frontier, idx)
          // Prepend new neighbors (O(k)) instead of append (O(N))
          let next_frontier =
            list.append(
              unvisited_neighbors(cell, next_visited, rows, cols),
              frontier_without_cell,
            )

          do_prim_simplified(
            next_grid,
            next_frontier,
            next_visited,
            rows,
            cols,
            next_rng,
          )
        }
      }
    }
  }
}

/// Generates a maze using the Recursive Division algorithm.
///
/// Starts with a full grid and adds walls.
///
/// ## Characteristics
///
/// - **Time**: O(N log N)
/// - **Space**: O(log N) for recursion stack
/// - **Bias**: Rectangular
/// - **Texture**: Room-like, fractal aesthetic
///
/// ## When to Use
///
/// - When you want a maze that feels "built"
/// - Creating architectural layouts
pub fn recursive_division(
  rows: Int,
  cols: Int,
  seed seed: Option(Int),
) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_full_grid(rows, cols)
  let #(final_grid, _) = divide(base_grid, 0, 0, rows, cols, rng)
  final_grid
}

fn create_full_grid(rows: Int, cols: Int) -> Grid(Nil, Int) {
  let empty_grid = create_empty_grid(rows, cols)

  util.range(0, rows - 1)
  |> list.fold(empty_grid, fn(acc_r, r) {
    util.range(0, cols - 2)
    |> list.fold(acc_r, fn(acc_c, c) { add_passage(acc_c, r, c, r, c + 1) })
  })
  |> list.fold(util.range(0, rows - 2), _, fn(acc_r, r) {
    util.range(0, cols - 1)
    |> list.fold(acc_r, fn(acc_c, c) { add_passage(acc_c, r, c, r + 1, c) })
  })
}

fn divide(
  grid: Grid(Nil, Int),
  row: Int,
  col: Int,
  height: Int,
  width: Int,
  rng: random.Rng,
) -> #(Grid(Nil, Int), random.Rng) {
  case height < 2 || width < 2 {
    True -> #(grid, rng)
    False -> {
      let #(horiz, next_rng) = case height > width {
        True -> #(True, rng)
        False ->
          case width > height {
            True -> #(False, rng)
            False -> {
              let #(chance, r) = random.next_float(rng)
              #(chance >. 0.5, r)
            }
          }
      }

      case horiz {
        True -> divide_horizontally(grid, row, col, height, width, next_rng)
        False -> divide_vertically(grid, row, col, height, width, next_rng)
      }
    }
  }
}

fn divide_horizontally(
  grid: Grid(Nil, Int),
  row: Int,
  col: Int,
  height: Int,
  width: Int,
  rng: random.Rng,
) -> #(Grid(Nil, Int), random.Rng) {
  let #(wall_offset, rng1) = random.next_int(rng, height - 1)
  let wall_row = row + wall_offset
  let #(passage_offset, rng2) = random.next_int(rng1, width)
  let passage_col = col + passage_offset

  let grid =
    util.range(col, col + width - 1)
    |> list.fold(grid, fn(acc, c) {
      case c == passage_col {
        True -> acc
        False -> remove_passage(acc, wall_row, c, wall_row + 1, c)
      }
    })

  let #(grid, rng3) = divide(grid, row, col, wall_offset + 1, width, rng2)
  divide(grid, wall_row + 1, col, height - wall_offset - 1, width, rng3)
}

fn divide_vertically(
  grid: Grid(Nil, Int),
  row: Int,
  col: Int,
  height: Int,
  width: Int,
  rng: random.Rng,
) -> #(Grid(Nil, Int), random.Rng) {
  let #(wall_offset, rng1) = random.next_int(rng, width - 1)
  let wall_col = col + wall_offset
  let #(passage_offset, rng2) = random.next_int(rng1, height)
  let passage_row = row + passage_offset

  let grid =
    list.fold(util.range(row, row + height - 1), grid, fn(acc, r) {
      case r == passage_row {
        True -> acc
        False -> remove_passage(acc, r, wall_col, r, wall_col + 1)
      }
    })

  let #(grid, rng3) = divide(grid, row, col, height, wall_offset + 1, rng2)
  divide(grid, row, wall_col + 1, height, width - wall_offset - 1, rng3)
}

fn remove_passage(
  grid: Grid(Nil, Int),
  r1: Int,
  c1: Int,
  r2: Int,
  c2: Int,
) -> Grid(Nil, Int) {
  let id1 = grid.coord_to_id(r1, c1, grid.cols)
  let id2 = grid.coord_to_id(r2, c2, grid.cols)
  let next_graph = model.remove_edge(grid.graph, id1, id2)
  Grid(..grid, graph: next_graph)
}

/// Generates a maze using True Prim's algorithm.
///
/// Uses random weights for each cell to produce a jigsaw-like texture.
///
/// ## Characteristics
///
/// - **Time**: O(N log N)
/// - **Space**: O(N) for weights and frontier
/// - **Bias**: None
/// - **Texture**: Jigsaw texture, balanced but dense
pub fn prim_true(rows: Int, cols: Int, seed seed: Option(Int)) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)

  let #(weights, next_rng) =
    {
      use r <- list.map(util.range(0, rows - 1))
      use c <- list.map(util.range(0, cols - 1))
      #(r, c)
    }
    |> list.flatten()
    |> list.fold(#(dict.new(), rng), fn(acc, cell) {
      let #(d, r) = acc
      let #(w, r2) = random.next_int(r, 1000)
      #(dict.insert(d, cell, w), r2)
    })

  let #(start_idx, _) = random.next_int(next_rng, rows * cols)
  let start_node = grid.id_to_coord(start_idx, cols)
  let visited = set.insert(set.new(), start_node)

  // Use priority queue for O(log N) extraction instead of O(N) linear scan
  let initial_pq =
    neighbors(start_node.0, start_node.1, rows, cols)
    |> list.fold(
      priority_queue.new(fn(a: #(Int, #(Int, Int)), b: #(Int, #(Int, Int))) {
        int.compare(b.0, a.0)
      }),
      fn(pq, n) {
        let w = dict.get(weights, n) |> result.unwrap(0)
        priority_queue.push(pq, #(w, n))
      },
    )

  do_prim_true(base_grid, initial_pq, visited, weights, rows, cols)
}

fn do_prim_true(
  grid: Grid(Nil, Int),
  frontier: priority_queue.Queue(#(Int, #(Int, Int))),
  visited: set.Set(#(Int, Int)),
  weights: dict.Dict(#(Int, Int), Int),
  rows: Int,
  cols: Int,
) -> Grid(Nil, Int) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> grid
    Ok(#(#(_, cell), rest_frontier)) -> {
      case set.contains(visited, cell) {
        True -> do_prim_true(grid, rest_frontier, visited, weights, rows, cols)
        False -> {
          let vn = visited_neighbors(cell, visited, rows, cols)
          let neighbor = case vn {
            [first, ..] -> first
            [] -> cell
          }

          let next_grid =
            add_passage(grid, cell.0, cell.1, neighbor.0, neighbor.1)
          let next_visited = set.insert(visited, cell)

          // Add new neighbors to priority queue
          let next_frontier =
            unvisited_neighbors(cell, next_visited, rows, cols)
            |> list.fold(rest_frontier, fn(pq, n) {
              let w = dict.get(weights, n) |> result.unwrap(0)
              priority_queue.push(pq, #(w, n))
            })

          do_prim_true(
            next_grid,
            next_frontier,
            next_visited,
            weights,
            rows,
            cols,
          )
        }
      }
    }
  }
}

/// Generates a maze using Eller's algorithm.
///
/// A row-by-row algorithm that uses constant memory relative to width.
///
/// ## Characteristics
///
/// - **Time**: O(N)
/// - **Space**: O(cols)
/// - **Bias**: Horizontal
/// - **Texture**: Balanced, consistent corridors
///
/// ## When to Use
///
/// - Generating mazes of infinite/very large height
/// - Memory-critical environments
pub fn ellers(rows: Int, cols: Int, seed seed: Option(Int)) -> Grid(Nil, Int) {
  let rng = random.new(seed)
  let base_grid = create_empty_grid(rows, cols)
  let row_state = dict.new()
  let next_set_id = 0

  do_ellers(base_grid, 0, rows, cols, row_state, next_set_id, rng)
}

fn do_ellers(
  grid: Grid(Nil, Int),
  r: Int,
  rows: Int,
  cols: Int,
  row_state: dict.Dict(Int, Int),
  next_set_id: Int,
  rng: random.Rng,
) -> Grid(Nil, Int) {
  case r == rows - 1 {
    True -> {
      let #(row_state, _) = assign_sets(row_state, cols, next_set_id)
      let #(final_grid, _) = {
        use acc, c <- list.fold(util.range(0, cols - 2), #(grid, row_state))
        let #(g_acc, s_acc) = acc
        let set1 = dict.get(s_acc, c) |> result.unwrap(-1)
        let set2 = dict.get(s_acc, c + 1) |> result.unwrap(-2)

        case set1 != set2 {
          True -> {
            let new_g = add_passage(g_acc, r, c, r, c + 1)
            let new_s = merge_sets(s_acc, set2, set1)
            #(new_g, new_s)
          }
          False -> #(g_acc, s_acc)
        }
      }
      final_grid
    }
    False -> {
      let #(row_state_1, next_set_id) =
        assign_sets(row_state, cols, next_set_id)

      let #(grid_0, row_state_2, rng_1) = {
        use acc, c <- list.fold(util.range(0, cols - 2), #(
          grid,
          row_state_1,
          rng,
        ))
        let #(g_acc, s_acc, r_acc) = acc
        let set1 = dict.get(s_acc, c) |> result.unwrap(-1)
        let set2 = dict.get(s_acc, c + 1) |> result.unwrap(-2)
        let #(chance, r_next) = random.next_float(r_acc)

        case set1 != set2 && chance >. 0.5 {
          True -> {
            let new_g = add_passage(g_acc, r, c, r, c + 1)
            let new_s = merge_sets(s_acc, set2, set1)
            #(new_g, new_s, r_next)
          }
          False -> #(g_acc, s_acc, r_next)
        }
      }

      let sets = dict.values(row_state_2) |> list.unique()

      let #(grid_1, next_row_state, final_rng) = {
        use acc, set_id <- list.fold(sets, #(grid_0, dict.new(), rng_1))
        let #(g_acc, next_s_acc, r_acc) = acc
        let cols_in_set =
          dict.filter(row_state_2, fn(_, s) { s == set_id })
          |> dict.keys()

        let #(count, r_next1) = random.next_int(r_acc, list.length(cols_in_set))
        let count = count + 1
        let #(to_carve, r_next2) =
          random_take_random(cols_in_set, count, r_next1)

        let new_g =
          list.fold(to_carve, g_acc, fn(g, c) { add_passage(g, r, c, r + 1, c) })

        let new_next_s =
          list.fold(to_carve, next_s_acc, fn(s, c) { dict.insert(s, c, set_id) })

        #(new_g, new_next_s, r_next2)
      }

      do_ellers(
        grid_1,
        r + 1,
        rows,
        cols,
        next_row_state,
        next_set_id,
        final_rng,
      )
    }
  }
}

fn assign_sets(
  row_state: dict.Dict(Int, Int),
  cols: Int,
  next_set_id: Int,
) -> #(dict.Dict(Int, Int), Int) {
  use #(s_acc, id_acc), c <- list.fold(util.range(0, cols - 1), #(
    row_state,
    next_set_id,
  ))

  case dict.has_key(s_acc, c) {
    True -> #(s_acc, id_acc)
    False -> #(dict.insert(s_acc, c, id_acc), id_acc + 1)
  }
}

fn merge_sets(
  row_state: dict.Dict(Int, Int),
  old_set: Int,
  new_set: Int,
) -> dict.Dict(Int, Int) {
  use acc, c, s <- dict.fold(row_state, dict.new())
  case s == old_set {
    True -> dict.insert(acc, c, new_set)
    False -> dict.insert(acc, c, s)
  }
}

fn random_take_random(
  list: List(a),
  count: Int,
  rng: random.Rng,
) -> #(List(a), random.Rng) {
  let #(shuffled, next_rng) = random.shuffle(list, rng)
  #(list.take(shuffled, count), next_rng)
}

// =============================================================================
// Helper Functions
// =============================================================================

fn create_empty_grid(rows: Int, cols: Int) -> Grid(Nil, Int) {
  {
    use acc_r, r <- list.fold(util.range(0, rows - 1), model.new(Undirected))
    use acc_c, c <- list.fold(util.range(0, cols - 1), acc_r)
    let id = grid.coord_to_id(r, c, cols)
    model.add_node(acc_c, id, Nil)
  }
  |> Grid(rows: rows, cols: cols)
}

/// Remove element at index using swap-and-pop for O(1) removal.
/// Returns the list with the element at the given index removed.
fn list_take_remove(list: List(a), index: Int) -> List(a) {
  do_list_take_remove(list, index, [])
}

fn do_list_take_remove(list: List(a), index: Int, acc: List(a)) -> List(a) {
  case index, list {
    0, [_, ..rest] -> list.append(list.reverse(acc), rest)
    n, [first, ..rest] if n > 0 ->
      do_list_take_remove(rest, n - 1, [first, ..acc])
    _, _ -> list.append(list.reverse(acc), list)
  }
}

fn add_passage(
  grid: Grid(Nil, Int),
  r1: Int,
  c1: Int,
  r2: Int,
  c2: Int,
) -> Grid(Nil, Int) {
  let id1 = grid.coord_to_id(r1, c1, grid.cols)
  let id2 = grid.coord_to_id(r2, c2, grid.cols)
  case model.add_edge(grid.graph, from: id1, to: id2, with: 1) {
    Ok(new_graph) -> Grid(..grid, graph: new_graph)
    Error(_) -> grid
  }
}

fn select_index_simple(
  len: Int,
  selector: GrowingTreeSelector,
  rng: random.Rng,
) -> #(Int, random.Rng) {
  case selector {
    Last -> #(len - 1, rng)
    First -> #(0, rng)
    Random -> random.next_int(rng, len)
    Middle -> #(len / 2, rng)
    Mix(_, _) -> #(len - 1, rng)
  }
}
