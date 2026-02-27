import gleam/int
import gleam/list
import gleam/order
import gleeunit/should
import yog/internal/heap
import yog/internal/utils

// ============= Creation Tests =============

pub fn new_heap_test() {
  heap.new()
  |> heap.is_empty()
  |> should.be_true()
}

pub fn new_heap_find_min_test() {
  heap.new()
  |> heap.find_min()
  |> should.equal(Error(Nil))
}

// ============= Insertion Tests =============

pub fn insert_single_element_test() {
  heap.new()
  |> heap.insert(5, int.compare)
  |> heap.is_empty()
  |> should.be_false()
}

pub fn insert_single_element_find_min_test() {
  heap.new()
  |> heap.insert(5, int.compare)
  |> heap.find_min()
  |> should.equal(Ok(5))
}

pub fn insert_multiple_elements_test() {
  let h =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(7, int.compare)
    |> heap.insert(1, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(1))
}

pub fn insert_maintains_min_property_test() {
  let h =
    heap.new()
    |> heap.insert(10, int.compare)
    |> heap.insert(20, int.compare)
    |> heap.insert(5, int.compare)
    |> heap.insert(15, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(5))
}

pub fn insert_descending_order_test() {
  let h =
    heap.new()
    |> heap.insert(10, int.compare)
    |> heap.insert(9, int.compare)
    |> heap.insert(8, int.compare)
    |> heap.insert(7, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(7))
}

pub fn insert_ascending_order_test() {
  let h =
    heap.new()
    |> heap.insert(1, int.compare)
    |> heap.insert(2, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(4, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(1))
}

pub fn insert_duplicates_test() {
  let h =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(5, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(3))
}

// ============= Find Min Tests =============

pub fn find_min_empty_heap_test() {
  heap.new()
  |> heap.find_min()
  |> should.equal(Error(Nil))
}

pub fn find_min_after_insertions_test() {
  let h =
    heap.new()
    |> heap.insert(42, int.compare)
    |> heap.insert(10, int.compare)
    |> heap.insert(99, int.compare)

  heap.find_min(h)
  |> should.equal(Ok(10))
}

// ============= Delete Min Tests =============

pub fn delete_min_empty_heap_test() {
  heap.new()
  |> heap.delete_min(int.compare)
  |> should.equal(Error(Nil))
}

pub fn delete_min_single_element_test() {
  let h =
    heap.new()
    |> heap.insert(5, int.compare)

  let result = heap.delete_min(h, int.compare)

  result
  |> should.be_ok()
  |> heap.is_empty()
  |> should.be_true()
}

pub fn delete_min_maintains_heap_property_test() {
  let h =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(7, int.compare)
    |> heap.insert(1, int.compare)

  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  heap.find_min(h2)
  |> should.equal(Ok(3))
}

pub fn delete_min_twice_test() {
  let h =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(7, int.compare)
    |> heap.insert(1, int.compare)
    |> heap.insert(9, int.compare)

  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  heap.find_min(h2)
  |> should.equal(Ok(3))

  let h3 =
    heap.delete_min(h2, int.compare)
    |> should.be_ok()

  heap.find_min(h3)
  |> should.equal(Ok(5))
}

pub fn delete_min_with_duplicates_test() {
  let h =
    heap.new()
    |> heap.insert(3, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(5, int.compare)

  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  heap.find_min(h2)
  |> should.equal(Ok(3))
}

// ============= Merge Tests =============

pub fn merge_two_empty_heaps_test() {
  let h1 = heap.new()
  let h2 = heap.new()

  heap.merge(h1, h2, int.compare)
  |> heap.is_empty()
  |> should.be_true()
}

pub fn merge_empty_with_nonempty_test() {
  let h1 = heap.new()
  let h2 =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)

  let merged = heap.merge(h1, h2, int.compare)

  heap.find_min(merged)
  |> should.equal(Ok(3))
}

pub fn merge_nonempty_with_empty_test() {
  let h1 =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(3, int.compare)
  let h2 = heap.new()

  let merged = heap.merge(h1, h2, int.compare)

  heap.find_min(merged)
  |> should.equal(Ok(3))
}

pub fn merge_two_nonempty_heaps_test() {
  let h1 =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(7, int.compare)

  let h2 =
    heap.new()
    |> heap.insert(3, int.compare)
    |> heap.insert(9, int.compare)

  let merged = heap.merge(h1, h2, int.compare)

  heap.find_min(merged)
  |> should.equal(Ok(3))
}

pub fn merge_maintains_all_elements_test() {
  let h1 =
    heap.new()
    |> heap.insert(10, int.compare)
    |> heap.insert(20, int.compare)

  let h2 =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(15, int.compare)

  let merged = heap.merge(h1, h2, int.compare)

  // Extract all elements in sorted order
  let sorted = extract_all(merged, int.compare)

  sorted
  |> should.equal([5, 10, 15, 20])
}

pub fn merge_symmetric_test() {
  let h1 =
    heap.new()
    |> heap.insert(10, int.compare)
    |> heap.insert(20, int.compare)

  let h2 =
    heap.new()
    |> heap.insert(5, int.compare)
    |> heap.insert(15, int.compare)

  let merged1 = heap.merge(h1, h2, int.compare)
  let merged2 = heap.merge(h2, h1, int.compare)

  // Both should have the same minimum
  heap.find_min(merged1)
  |> should.equal(heap.find_min(merged2))

  // Both should extract to the same sorted list
  extract_all(merged1, int.compare)
  |> should.equal(extract_all(merged2, int.compare))
}

// ============= Heap Sort Tests =============

pub fn heap_sort_random_elements_test() {
  let unsorted = [5, 2, 8, 1, 9, 3, 7, 4, 6]

  let h =
    list.fold(unsorted, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  extract_all(h, int.compare)
  |> should.equal([1, 2, 3, 4, 5, 6, 7, 8, 9])
}

pub fn heap_sort_already_sorted_test() {
  let sorted = [1, 2, 3, 4, 5]

  let h =
    list.fold(sorted, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  extract_all(h, int.compare)
  |> should.equal([1, 2, 3, 4, 5])
}

pub fn heap_sort_reverse_sorted_test() {
  let reverse = [5, 4, 3, 2, 1]

  let h =
    list.fold(reverse, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  extract_all(h, int.compare)
  |> should.equal([1, 2, 3, 4, 5])
}

pub fn heap_sort_with_duplicates_test() {
  let with_dups = [5, 2, 5, 1, 3, 2, 1, 5]

  let h =
    list.fold(with_dups, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  extract_all(h, int.compare)
  |> should.equal([1, 1, 2, 2, 3, 5, 5, 5])
}

pub fn heap_sort_single_element_test() {
  let h =
    heap.new()
    |> heap.insert(42, int.compare)

  extract_all(h, int.compare)
  |> should.equal([42])
}

pub fn heap_sort_empty_test() {
  heap.new()
  |> extract_all(int.compare)
  |> should.equal([])
}

// ============= Pairing-Specific Tests =============

pub fn two_pass_pairing_odd_children_test() {
  // Build a heap where delete_min will need to pair an odd number of children
  let h =
    heap.new()
    |> heap.insert(1, int.compare)
    |> heap.insert(2, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(4, int.compare)
    |> heap.insert(5, int.compare)

  // Remove min, which should trigger two-pass pairing
  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  // Verify heap property is maintained
  heap.find_min(h2)
  |> should.equal(Ok(2))
}

pub fn two_pass_pairing_even_children_test() {
  // Build a heap where delete_min will need to pair an even number of children
  let h =
    heap.new()
    |> heap.insert(1, int.compare)
    |> heap.insert(2, int.compare)
    |> heap.insert(3, int.compare)
    |> heap.insert(4, int.compare)

  // Remove min
  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  // Verify heap property is maintained
  heap.find_min(h2)
  |> should.equal(Ok(2))
}

// ============= Stress Tests =============

pub fn large_heap_operations_test() {
  // Build a heap with 100 elements
  let numbers = utils.range(1, 100)

  let h =
    list.fold(numbers, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  // Verify min
  heap.find_min(h)
  |> should.equal(Ok(1))

  // Delete min and verify next
  let h2 =
    heap.delete_min(h, int.compare)
    |> should.be_ok()

  heap.find_min(h2)
  |> should.equal(Ok(2))
}

pub fn shuffled_large_heap_test() {
  // Create a shuffled list (simulated with reverse and interleaving)
  let numbers = utils.range(1, 50)
  let shuffled = list.reverse(numbers)

  let h =
    list.fold(shuffled, heap.new(), fn(h, v) { heap.insert(h, v, int.compare) })

  // Extract first 10 elements
  let first_10 = extract_n(h, 10, int.compare)

  first_10
  |> should.equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
}

pub fn multiple_heap_merge_test() {
  // Create 5 small heaps
  let h1 =
    heap.new() |> heap.insert(10, int.compare) |> heap.insert(20, int.compare)
  let h2 =
    heap.new() |> heap.insert(5, int.compare) |> heap.insert(15, int.compare)
  let h3 =
    heap.new() |> heap.insert(25, int.compare) |> heap.insert(30, int.compare)
  let h4 =
    heap.new() |> heap.insert(1, int.compare) |> heap.insert(35, int.compare)
  let h5 =
    heap.new() |> heap.insert(12, int.compare) |> heap.insert(18, int.compare)

  // Merge them all
  let merged =
    heap.merge(h1, h2, int.compare)
    |> heap.merge(h3, _, int.compare)
    |> heap.merge(h4, _, int.compare)
    |> heap.merge(h5, _, int.compare)

  // Verify minimum
  heap.find_min(merged)
  |> should.equal(Ok(1))

  // Verify all 10 elements are present in sorted order
  extract_all(merged, int.compare)
  |> should.equal([1, 5, 10, 12, 15, 18, 20, 25, 30, 35])
}

// ============= Custom Comparison Tests =============

// Max-heap using reverse comparison
pub fn max_heap_test() {
  let max_compare = fn(a: Int, b: Int) -> order.Order {
    case int.compare(a, b) {
      order.Lt -> order.Gt
      order.Eq -> order.Eq
      order.Gt -> order.Lt
    }
  }

  let h =
    heap.new()
    |> heap.insert(5, max_compare)
    |> heap.insert(10, max_compare)
    |> heap.insert(3, max_compare)
    |> heap.insert(7, max_compare)

  // In max-heap, find_min should return the maximum value
  heap.find_min(h)
  |> should.equal(Ok(10))

  // Delete and check next max
  let h2 =
    heap.delete_min(h, max_compare)
    |> should.be_ok()

  heap.find_min(h2)
  |> should.equal(Ok(7))
}

// ============= Helper Functions =============

// Recursively extract all elements from heap in sorted order
fn extract_all(
  h: heap.Heap(Int),
  compare: fn(Int, Int) -> order.Order,
) -> List(Int) {
  case heap.find_min(h) {
    Error(Nil) -> []
    Ok(min) -> {
      case heap.delete_min(h, compare) {
        Error(Nil) -> [min]
        Ok(h2) -> [min, ..extract_all(h2, compare)]
      }
    }
  }
}

// Extract first n elements from heap
fn extract_n(
  h: heap.Heap(Int),
  n: Int,
  compare: fn(Int, Int) -> order.Order,
) -> List(Int) {
  case n <= 0 {
    True -> []
    False -> {
      case heap.find_min(h) {
        Error(Nil) -> []
        Ok(min) -> {
          case heap.delete_min(h, compare) {
            Error(Nil) -> [min]
            Ok(h2) -> [min, ..extract_n(h2, n - 1, compare)]
          }
        }
      }
    }
  }
}
