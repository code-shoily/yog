import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/order.{type Order, Lt}
import gleam/result
import yog/internal/random

/// Returns a list of integers from `start` to `end` (inclusive).
///
/// ## Examples
///
/// ```gleam
/// range(1, 5)
/// // => [1, 2, 3, 4, 5]
///
/// range(0, 3)
/// // => [0, 1, 2, 3]
/// ```
pub fn range(start: Int, end: Int) -> List(Int) {
  do_range(start, end, [])
  |> list.reverse()
}

fn do_range(current: Int, end: Int, acc: List(Int)) -> List(Int) {
  case current > end {
    True -> acc
    False -> do_range(current + 1, end, [current, ..acc])
  }
}

/// Updates an inner dictionary within a nested dictionary structure.
pub fn dict_update_inner(
  outer: Dict(k1, Dict(k2, v)),
  key1: k1,
  key2: k2,
  fun: fn(Dict(k2, v), k2) -> Dict(k2, v),
) -> Dict(k1, Dict(k2, v)) {
  case dict.get(outer, key1) {
    Ok(inner) -> dict.insert(outer, key1, fun(inner, key2))
    Error(_) -> outer
  }
}

// =============================================================================
// NORM DIFF - Vector distance calculations
// =============================================================================

/// Norm type for vector distance calculations.
pub type NormType {
  /// L1 norm - Manhattan Distance (Sum of absolute differences)
  L1
  /// L2 norm - Euclidean Distance (Square root of sum of squares)
  L2
  /// Max norm - Chebyshev Distance (Maximum absolute difference)
  Max
}

/// Calculates the difference (distance) between two vectors (dicts of scores)
/// using the specified norm type.
///
/// ## Supported Types
/// - `L1`  - Manhattan Distance (Sum of absolute differences)
/// - `L2`  - Euclidean Distance (Square root of sum of squares)
/// - `Max` - Chebyshev Distance (Maximum absolute difference)
///
/// ## Examples
///
/// ```gleam
/// import gleam/dict
/// 
/// let m1 = dict.from_list([#("a", 1.0), #("b", 2.0)])
/// let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])
/// 
/// norm_diff(m1, m2, L1)
/// // => 4.0
///
/// norm_diff(m1, m2, L2)
/// // => 2.8284271247461903
/// ```
pub fn norm_diff(
  m1: Dict(k, Float),
  m2: Dict(k, Float),
  norm_type: NormType,
) -> Float {
  case norm_type {
    L1 -> norm_diff_l1(m1, m2)
    L2 -> norm_diff_l2(m1, m2)
    Max -> norm_diff_max(m1, m2)
  }
}

fn norm_diff_l1(m1: Dict(k, Float), m2: Dict(k, Float)) -> Float {
  dict.combine(m1, m2, fn(v1, v2) { v1 -. v2 })
  |> dict.fold(0.0, fn(acc, _, v) { acc +. float.absolute_value(v) })
}

fn norm_diff_l2(m1: Dict(k, Float), m2: Dict(k, Float)) -> Float {
  let sum_sq =
    dict.combine(m1, m2, fn(v1, v2) { v1 -. v2 })
    |> dict.fold(0.0, fn(acc, _, v) { acc +. v *. v })
  float.square_root(sum_sq)
  |> result.unwrap(0.0)
}

fn norm_diff_max(m1: Dict(k, Float), m2: Dict(k, Float)) -> Float {
  dict.combine(m1, m2, fn(v1, v2) { v1 -. v2 })
  |> dict.fold(0.0, fn(acc, _, v) {
    let d = float.absolute_value(v)
    case d >. acc {
      True -> d
      False -> acc
    }
  })
}

// =============================================================================
// ARRAY EMULATION (Erlang: tuples, JavaScript: arrays)
// =============================================================================

/// Simple array type for O(1) indexed access.
/// Uses tuples on Erlang and arrays on JavaScript.
pub type Array(a)

/// Creates an array from a list.
@external(erlang, "yog_internal_util", "array_from_list")
@external(javascript, "./util_ffi.mjs", "arrayFromList")
pub fn array_from_list(list: List(a)) -> Array(a)

/// Converts an array back to a list.
@external(erlang, "yog_internal_util", "array_to_list")
@external(javascript, "./util_ffi.mjs", "arrayToList")
pub fn array_to_list(arr: Array(a), size: Int) -> List(a)

/// Gets an element at the specified index (0-based).
@external(erlang, "yog_internal_util", "array_get")
@external(javascript, "./util_ffi.mjs", "arrayGet")
pub fn array_get(arr: Array(a), index: Int) -> a

/// Sets an element at the specified index (0-based).
@external(erlang, "yog_internal_util", "array_set")
@external(javascript, "./util_ffi.mjs", "arraySet")
pub fn array_set(arr: Array(a), index: Int, value: a) -> Array(a)

/// Returns the element at the given index in the list, or `Error(Nil)` if the
/// index is out of bounds.
pub fn list_at(lst: List(a), index: Int) -> Result(a, Nil) {
  case index, lst {
    0, [first, ..] -> Ok(first)
    n, [_, ..rest] if n > 0 -> list_at(rest, n - 1)
    _, _ -> Error(Nil)
  }
}

// =============================================================================
// FISHER-YATES SHUFFLE
// =============================================================================

/// Shuffles a list using the Fisher-Yates algorithm.
///
/// This is an O(N) algorithm that produces an unbiased permutation.
/// Uses the Array emulation for O(1) indexed access.
///
/// ## Example
///
/// ```gleam
/// let rng = random.new(Some(42))
/// let #(shuffled, next_rng) = shuffle([1, 2, 3, 4, 5], rng)
/// ```
pub fn shuffle(list: List(a), rng: random.Rng) -> #(List(a), random.Rng) {
  let n = list.length(list)
  case n <= 1 {
    True -> #(list, rng)
    False -> {
      let arr = array_from_list(list)
      let #(shuffled_arr, final_rng) = do_shuffle(arr, n - 1, rng)
      #(array_to_list(shuffled_arr, n), final_rng)
    }
  }
}

fn do_shuffle(arr: Array(a), i: Int, rng: random.Rng) -> #(Array(a), random.Rng) {
  case i <= 0 {
    True -> #(arr, rng)
    False -> {
      let #(j, next_rng) = random.next_int(rng, i + 1)
      let temp_i = array_get(arr, i)
      let temp_j = array_get(arr, j)
      let swapped =
        arr
        |> array_set(i, temp_j)
        |> array_set(j, temp_i)
      do_shuffle(swapped, i - 1, next_rng)
    }
  }
}

// =============================================================================
// PATHFINDING INTERNAL HELPERS
// =============================================================================

/// Compares two frontier entries by their priority value.
pub fn compare_frontier(
  a: #(e, List(a)),
  b: #(e, List(a)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Compares two distance-based frontier entries.
pub fn compare_distance_frontier(
  a: #(e, b),
  b: #(e, b),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Compares two A* frontier entries by their f-score.
pub fn compare_a_star_frontier(
  a: #(e, e, List(b)),
  b: #(e, e, List(b)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Determines if a node should be explored based on distance comparison.
pub fn should_explore_node(
  visited: Dict(k, e),
  node: k,
  new_dist: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  case dict.get(visited, node) {
    Ok(prev_dist) ->
      case compare(new_dist, prev_dist) {
        Lt -> True
        _ -> False
      }
    Error(Nil) -> True
  }
}

// =============================================================================
// PROCESS CONTROL
// =============================================================================

/// Halts a process immediately.
/// Useful for exploratory programming and fix those
/// annoying pauses before terminal exits.
@external(erlang, "erlang", "halt")
@external(javascript, "node:process", "exit")
pub fn exit(status: Int) -> Nil
