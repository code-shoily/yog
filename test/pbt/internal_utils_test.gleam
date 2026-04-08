import gleam/list
import gleeunit
import qcheck
import yog/internal/utils

const test_count = 100

pub fn main() {
  gleeunit.main()
}

fn generate_range(start: Int, end: Int) -> List(Int) {
  case start > end {
    True -> []
    False -> [start, ..generate_range(start + 1, end)]
  }
}

pub fn prop_range_contains_all_integers_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bind(qcheck.bounded_int(-50, 50), fn(start) {
      qcheck.map(qcheck.bounded_int(-50, 100), fn(end) { #(start, end) })
    }),
    fn(pair) {
      let #(start, end) = pair
      let result = utils.range(start, end)
      let expected = generate_range(start, end)
      assert result == expected
    },
  )
}

pub fn prop_reverse_range_empty_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bind(qcheck.bounded_int(0, 50), fn(start) {
      qcheck.map(qcheck.bounded_int(-50, start - 1), fn(end) { #(start, end) })
    }),
    fn(pair) {
      let #(start, end) = pair
      let result = utils.range(start, end)
      assert result == []
    },
  )
}

pub fn prop_range_concatenation_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bind(qcheck.bounded_int(-30, 30), fn(mid) {
      qcheck.bind(qcheck.bounded_int(-100, mid), fn(start) {
        qcheck.map(qcheck.bounded_int(mid, 100), fn(end) { #(mid, start, end) })
      })
    }),
    fn(triple) {
      let #(mid, start, end) = triple
      let range1 = utils.range(start, mid)
      let range2 = utils.range(mid + 1, end)
      let combined = list.append(range1, range2)
      let full_range = utils.range(start, end)
      assert combined == full_range
    },
  )
}
