import gleam/int
import gleam/list
import gleeunit
import qcheck
import yog/internal/pairing_heap as heap

const test_count = 100

pub fn main() {
  gleeunit.main()
}

fn int_list_generator() {
  use length <- qcheck.bind(qcheck.bounded_int(0, 50))
  qcheck.fixed_length_list_from(qcheck.bounded_int(-100, 100), length)
}

fn heap_from_list(items: List(Int)) {
  list.fold(items, heap.new(int.compare), fn(h, item) { heap.insert(h, item) })
}

fn extract_all(h, acc) {
  case heap.delete_min(h) {
    Error(_) -> list.reverse(acc)
    Ok(#(min, new_heap)) -> extract_all(new_heap, [min, ..acc])
  }
}

fn triple_generator() {
  use items1 <- qcheck.bind(int_list_generator())
  use items2 <- qcheck.bind(int_list_generator())
  use items3 <- qcheck.map(int_list_generator())
  #(items1, items2, items3)
}

pub fn prop_extract_all_yields_sorted_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    int_list_generator(),
    fn(items) {
      let h = heap_from_list(items)
      let extracted = extract_all(h, [])
      assert extracted == list.sort(items, int.compare)
    },
  )
}

pub fn prop_merge_contains_all_elements_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bind(int_list_generator(), fn(items1) {
      qcheck.map(int_list_generator(), fn(items2) { #(items1, items2) })
    }),
    fn(pair) {
      let #(items1, items2) = pair
      let h1 = heap_from_list(items1)
      let h2 = heap_from_list(items2)
      let merged = heap.merge(h1, h2)
      let extracted = extract_all(merged, [])
      let expected = list.sort(list.append(items1, items2), int.compare)
      assert extracted == expected
    },
  )
}

pub fn prop_empty_heap_no_min_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.return(Nil),
    fn(_) {
      let h = heap.new(int.compare)
      assert heap.find_min(h) == Error(Nil)
    },
  )
}

pub fn prop_merge_associative_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    triple_generator(),
    fn(triple) {
      let #(items1, items2, items3) = triple
      let h1 = heap_from_list(items1)
      let h2 = heap_from_list(items2)
      let h3 = heap_from_list(items3)
      let left = heap.merge(heap.merge(h1, h2), h3)
      let right = heap.merge(h1, heap.merge(h2, h3))
      assert extract_all(left, []) == extract_all(right, [])
    },
  )
}
