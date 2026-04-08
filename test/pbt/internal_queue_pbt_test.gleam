import gleam/list
import gleeunit
import qcheck
import yog/internal/queue

const test_count = 100

pub fn main() {
  gleeunit.main()
}

/// Generate a random list of integers for queue testing.
///
/// **Generates:** `List(Int)` with length 0-50 and values -100 to 100.
fn int_list_generator() {
  use length <- qcheck.bind(qcheck.bounded_int(0, 50))
  qcheck.fixed_length_list_from(qcheck.bounded_int(-100, 100), length)
}

fn queue_from_list(items: List(Int)) {
  queue.push_list(queue.new(), items)
}

fn pop_all(q, acc) {
  case queue.pop(q) {
    Error(_) -> list.reverse(acc)
    Ok(#(item, new_q)) -> pop_all(new_q, [item, ..acc])
  }
}

fn pop_n(q, n, acc) {
  case n {
    0 -> #(list.reverse(acc), q)
    _ -> {
      case queue.pop(q) {
        Error(_) -> #(list.reverse(acc), q)
        Ok(#(item, new_q)) -> pop_n(new_q, n - 1, [item, ..acc])
      }
    }
  }
}

pub fn prop_queue_is_fifo_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    int_list_generator(),
    fn(items) {
      let q = queue_from_list(items)
      let popped = pop_all(q, [])
      assert popped == items
    },
  )
}

pub fn prop_empty_queue_pop_fails_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.return(Nil),
    fn(_) {
      let q = queue.new()
      assert queue.pop(q) == Error(Nil)
    },
  )
}

pub fn prop_interleaved_operations_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.bind(int_list_generator(), fn(items1) {
      qcheck.map(int_list_generator(), fn(items2) { #(items1, items2) })
    }),
    fn(pair) {
      let #(items1, items2) = pair
      let q = queue_from_list(items1)
      let num_pop1 = list.length(items1) / 2
      let #(popped1, q_after_pop1) = pop_n(q, num_pop1, [])
      let q_after_push = queue.push_list(q_after_pop1, items2)
      let remaining_items1 = list.drop(items1, num_pop1)
      let expected = list.append(remaining_items1, items2)
      let actual = pop_all(q_after_push, [])
      assert popped1 == list.take(items1, num_pop1)
      assert actual == expected
    },
  )
}
