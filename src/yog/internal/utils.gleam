import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/result

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
// FISHER-YATES SHUFFLE
// =============================================================================

/// Fisher-Yates shuffle: O(n log n) on Erlang, O(n) on JavaScript.
///
/// Deterministic when given a seed (for reproducibility).
///
/// ## Examples
///
/// ```gleam
/// fisher_yates([1, 2, 3, 4, 5], 42)
/// // => [3, 2, 5, 4, 1]
///
/// fisher_yates([], 123)
/// // => []
/// ```
pub fn fisher_yates(list: List(a), seed: Int) -> List(a) {
  let n = list.length(list)

  case n <= 1 {
    True -> list
    False -> {
      let arr = array_from_list(list)
      let #(shuffled_arr, _final_seed) = do_fisher_yates(arr, 0, n, seed)
      array_to_list(shuffled_arr, n)
    }
  }
}

fn do_fisher_yates(arr: Array(a), i: Int, n: Int, seed: Int) -> #(Array(a), Int) {
  case i >= n - 1 {
    True -> #(arr, seed)
    False -> {
      let a = 1_103_515_245
      let c = 12_345
      let m = 2_147_483_648

      let next_seed = int.modulo(a * seed + c, m) |> result.unwrap(0)
      let j = i + next_seed % { n - i }

      let val_i = array_get(arr, i)
      let val_j = array_get(arr, j)
      let arr = array_set(arr, i, val_j)
      let arr = array_set(arr, j, val_i)

      do_fisher_yates(arr, i + 1, n, next_seed)
    }
  }
}

// =============================================================================
// ARRAY EMULATION (Erlang: tuples, JavaScript: arrays)
// =============================================================================

/// Simple array type for O(1) indexed access.
/// Uses tuples on Erlang and arrays on JavaScript.
pub type Array(a)

/// Creates an array from a list.
@external(erlang, "yog_internal_utils", "array_from_list")
@external(javascript, "./utils_ffi.mjs", "arrayFromList")
pub fn array_from_list(list: List(a)) -> Array(a)

/// Converts an array back to a list.
@external(erlang, "yog_internal_utils", "array_to_list")
@external(javascript, "./utils_ffi.mjs", "arrayToList")
pub fn array_to_list(arr: Array(a), size: Int) -> List(a)

/// Gets an element at the specified index (0-based).
@external(erlang, "yog_internal_utils", "array_get")
@external(javascript, "./utils_ffi.mjs", "arrayGet")
pub fn array_get(arr: Array(a), index: Int) -> a

/// Sets an element at the specified index (0-based).
@external(erlang, "yog_internal_utils", "array_set")
@external(javascript, "./utils_ffi.mjs", "arraySet")
pub fn array_set(arr: Array(a), index: Int, value: a) -> Array(a)

// =============================================================================
// PROCESS CONTROL
// =============================================================================

/// Halts a process immediately.
/// Useful for exploratory programming and fix those
/// annoying pauses before terminal exits.
@external(erlang, "erlang", "halt")
@external(javascript, "node:process", "exit")
pub fn exit(status: Int) -> Nil
