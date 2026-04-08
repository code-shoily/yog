import gleam/int
import gleam/list
import gleam/order
import gleeunit
import qcheck
import yog/internal/priority_queue as pq

const test_count = 100

pub fn main() {
  gleeunit.main()
}

fn int_list_generator() {
  use length <- qcheck.bind(qcheck.bounded_int(0, 50))
  qcheck.fixed_length_list_from(qcheck.bounded_int(-100, 100), length)
}

fn pq_from_list(items: List(Int)) {
  pq.from_list(items, int.compare)
}

fn pop_all(q, acc) {
  case pq.pop(q) {
    Error(_) -> list.reverse(acc)
    Ok(#(item, new_q)) -> pop_all(new_q, [item, ..acc])
  }
}

pub fn prop_pop_returns_sorted_order_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    int_list_generator(),
    fn(items) {
      let queue = pq_from_list(items)
      let popped = pop_all(queue, [])
      assert popped == list.sort(items, int.compare)
    },
  )
}

pub fn prop_peek_does_not_remove_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    int_list_generator(),
    fn(items) {
      case items {
        [] -> Nil
        _ -> {
          let queue = pq_from_list(items)
          let assert Ok(peeked) = pq.peek(queue)
          let assert Ok(peeked_again) = pq.peek(queue)
          let assert Ok(#(first_pop, _)) = pq.pop(queue)
          assert peeked == peeked_again
          assert peeked == first_pop
        }
      }
    },
  )
}

pub fn prop_empty_queue_pop_fails_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    qcheck.return(Nil),
    fn(_) {
      let queue = pq.new(int.compare)
      assert pq.pop(queue) == Error(Nil)
    },
  )
}

pub fn prop_reorder_changes_ordering_test() {
  qcheck.run(
    qcheck.default_config() |> qcheck.with_test_count(test_count),
    int_list_generator(),
    fn(items) {
      case items {
        [] -> Nil
        [_] -> Nil
        _ -> {
          let queue = pq_from_list(items)
          let reversed =
            pq.reorder(queue, fn(a, b) {
              case int.compare(a, b) {
                order.Lt -> order.Gt
                order.Gt -> order.Lt
                order.Eq -> order.Eq
              }
            })
          let original_popped = pop_all(queue, [])
          let reversed_popped = pop_all(reversed, [])
          assert reversed_popped == list.reverse(original_popped)
        }
      }
    },
  )
}
