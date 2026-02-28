import gleam/list

/// Two-list queue for O(1) amortized enqueue/dequeue operations.
///
/// This is much more efficient than using `list.append` for queue operations,
/// which has O(n) complexity and would make BFS O(V²) instead of O(V + E).
///
/// The queue maintains two lists:
/// - `front`: elements ready to be dequeued (head is next)
/// - `back`: newly enqueued elements (in reverse order)
///
/// When `front` is empty and we need to dequeue, we reverse `back` to become
/// the new `front`. This gives O(1) amortized time per operation.
///
/// This is a standard functional queue implementation (Okasaki-style).
pub type Queue(a) {
  Queue(front: List(a), back: List(a))
}

/// Creates a new empty queue.
pub fn new() -> Queue(a) {
  Queue(front: [], back: [])
}

/// Adds a single item to the back of the queue. O(1).
pub fn push(queue: Queue(a), item: a) -> Queue(a) {
  Queue(front: queue.front, back: [item, ..queue.back])
}

/// Adds multiple items to the back of the queue. O(n) where n is the length of items.
///
/// Since the back list is in reverse order (to support O(1) push),
/// we need to reverse the items before prepending them to maintain correct order.
pub fn push_list(queue: Queue(a), items: List(a)) -> Queue(a) {
  Queue(front: queue.front, back: list.append(list.reverse(items), queue.back))
}

/// Removes and returns the front item from the queue. O(1) amortized.
///
/// Returns `Ok(#(item, new_queue))` if the queue is not empty,
/// or `Error(Nil)` if the queue is empty.
pub fn pop(queue: Queue(a)) -> Result(#(a, Queue(a)), Nil) {
  case queue.front {
    [item, ..rest] -> Ok(#(item, Queue(front: rest, back: queue.back)))
    [] ->
      case list.reverse(queue.back) {
        [] -> Error(Nil)
        [item, ..rest] -> Ok(#(item, Queue(front: rest, back: [])))
      }
  }
}
