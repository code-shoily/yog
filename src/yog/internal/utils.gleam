import gleam/dict.{type Dict}
import gleam/list

/// Returns a list of integers from `start` to `end` (inclusive).
/// This is a replacement for the deprecated `list.range`.
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
