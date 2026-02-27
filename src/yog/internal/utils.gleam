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
