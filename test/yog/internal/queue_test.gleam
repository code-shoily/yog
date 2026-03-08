import gleeunit/should
import yog/internal/queue

pub fn new_test() {
  let q = queue.new()
  queue.pop(q) |> should.be_error
}

pub fn push_pop_test() {
  let q = queue.new()
  let q = queue.push(q, 1)
  let q = queue.push(q, 2)

  let assert Ok(#(val1, q)) = queue.pop(q)
  val1 |> should.equal(1)

  let assert Ok(#(val2, q)) = queue.pop(q)
  val2 |> should.equal(2)

  queue.pop(q) |> should.be_error
}

pub fn push_list_test() {
  let q = queue.new()
  let q = queue.push_list(q, [1, 2, 3])

  let assert Ok(#(val1, q)) = queue.pop(q)
  val1 |> should.equal(1)

  let assert Ok(#(val2, q)) = queue.pop(q)
  val2 |> should.equal(2)

  let assert Ok(#(val3, q)) = queue.pop(q)
  val3 |> should.equal(3)

  queue.pop(q) |> should.be_error
}

pub fn order_test() {
  let q = queue.new()
  let q = queue.push(q, 1)
  // front: [], back: [1]
  let q = queue.push_list(q, [2, 3])
  // front: [], back: [3, 2, 1] (append reverse 2,3 to 1) -> Actually push_list reverses items
  // Let's re-verify queue.gleam push_list:
  // Queue(front: queue.front, back: list.append(list.reverse(items), queue.back))
  // push_list(Queue([], [1]), [2, 3]) -> Queue([], [3, 2, 1])

  let assert Ok(#(val1, q)) = queue.pop(q)
  val1 |> should.equal(1)
  // pop reverses back: [3, 2] -> front: [2, 3]

  let assert Ok(#(val2, q)) = queue.pop(q)
  val2 |> should.equal(2)

  let assert Ok(#(val3, q)) = queue.pop(q)
  val3 |> should.equal(3)

  queue.pop(q) |> should.be_error
}
