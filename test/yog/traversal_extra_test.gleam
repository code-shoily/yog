//// Unit tests for Best-First and Random walks in yog/traversal.gleam.

import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog
import yog/generator/classic
import yog/traversal

pub fn best_first_walk_test() {
  // Graph where BFS/DFS and Best-First would produce different results
  // 1 -> 2 (score 10)
  // 1 -> 3 (score 5)
  // 3 -> 4 (score 1)
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge_ensure(from: 1, to: 2, with: 1, default: Nil)
    |> yog.add_edge_ensure(from: 1, to: 3, with: 1, default: Nil)
    |> yog.add_edge_ensure(from: 3, to: 4, with: 1, default: Nil)

  let score_fn = fn(id) {
    case id {
      1 -> 0
      2 -> 10
      3 -> 5
      4 -> 1
      _ -> 100
    }
  }

  // BFS would visit [1, 2, 3, 4] or [1, 3, 2, 4]
  // Best-First with greedy scores:
  // 1 is visited. Successors 2 (10) and 3 (5) are queued.
  // 3 (5) is visited next because 5 < 10. Successor 4 (1) is queued.
  // 4 (1) is visited next because 1 < 10.
  // 2 (10) is visited last.
  traversal.best_first_walk(graph, from: 1, scored_by: score_fn)
  |> should.equal([1, 3, 4, 2])
}

pub fn random_walk_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge_ensure(from: 1, to: 2, with: 1, default: Nil)
    |> yog.add_edge_ensure(from: 2, to: 3, with: 1, default: Nil)

  // Deterministic seed
  let path = traversal.random_walk(graph, from: 1, steps: 5, seed: Some(42))

  // Path should start with 1
  list.first(path) |> should.equal(Ok(1))

  // Path should have length up to (steps + 1)
  { list.length(path) <= 6 } |> should.be_true()

  // Every transition should be valid
  check_path_validity(graph, path)
}

fn check_path_validity(graph, path) {
  case path {
    [] | [_] -> Nil
    [u, v, ..rest] -> {
      let neighbors = yog.successor_ids(graph, u)
      list.contains(neighbors, v) |> should.be_true()
      check_path_validity(graph, [v, ..rest])
    }
  }
}

pub fn random_walk_sink_test() {
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_edge_ensure(from: 1, to: 2, with: 1, default: Nil)
  // 2 is a sink

  // Should stop at 2 even if steps remain
  let path = traversal.random_walk(graph, from: 1, steps: 10, seed: None)
  path |> should.equal([1, 2])
}

pub fn random_walk_determinism_test() {
  let graph = classic.cycle(10)

  let seed = Some(12_345)
  let path1 = traversal.random_walk(graph, from: 0, steps: 20, seed: seed)
  let path2 = traversal.random_walk(graph, from: 0, steps: 20, seed: seed)

  path1 |> should.equal(path2)
}
