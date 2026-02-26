import gleam/order.{type Order}

/// A pairing heap - an efficient self-adjusting heap data structure.
///
/// Supports O(1) insertion and find-min, O(log n) amortized delete-min.
/// Useful for priority queues in graph algorithms.
pub type Heap(a) {
  Empty
  Heap(value: a, subheaps: List(Heap(a)))
}

/// Creates a new empty heap.
pub fn new() -> Heap(a) {
  Empty
}

/// Checks if the heap is empty.
pub fn is_empty(heap: Heap(a)) -> Bool {
  heap == Empty
}

/// Returns the minimum element without removing it.
///
/// Returns `Error(Nil)` if the heap is empty.
pub fn find_min(heap: Heap(a)) -> Result(a, Nil) {
  case heap {
    Empty -> Error(Nil)
    Heap(value: v, ..) -> Ok(v)
  }
}

/// Merges two heaps into one.
///
/// The resulting heap contains all elements from both heaps.
/// Takes O(1) time.
pub fn merge(h1: Heap(a), h2: Heap(a), compare: fn(a, a) -> Order) -> Heap(a) {
  case h1, h2 {
    Empty, h -> h
    h, Empty -> h
    Heap(v1, s1), Heap(v2, s2) ->
      case compare(v1, v2) {
        order.Lt | order.Eq -> Heap(v1, [h2, ..s1])
        order.Gt -> Heap(v2, [h1, ..s2])
      }
  }
}

/// Inserts a new element into the heap.
///
/// Takes O(1) time.
pub fn insert(heap: Heap(a), value: a, compare: fn(a, a) -> Order) -> Heap(a) {
  merge(Heap(value, []), heap, compare)
}

/// Removes and returns the heap without its minimum element.
///
/// Returns `Error(Nil)` if the heap is empty.
/// Takes O(log n) amortized time.
pub fn delete_min(
  heap: Heap(a),
  compare: fn(a, a) -> Order,
) -> Result(Heap(a), Nil) {
  case heap {
    Empty -> Error(Nil)
    Heap(_, subheaps) -> Ok(merge_pairs(subheaps, compare))
  }
}

fn merge_pairs(heaps: List(Heap(a)), compare: fn(a, a) -> Order) -> Heap(a) {
  case heaps {
    [] -> Empty
    [h] -> h
    [h1, h2, ..rest] ->
      merge(merge(h1, h2, compare), merge_pairs(rest, compare), compare)
  }
}
