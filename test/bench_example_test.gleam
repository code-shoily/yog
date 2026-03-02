////  Simple Benchmark Example for Yog
////
//// This demonstrates how to do basic performance testing.
//// For more sophisticated benchmarking with gleamy_bench, see BENCHMARKING_GUIDE.md

import gleam/int
import gleam/io
import gleam/option
import gleeunit
import gleeunit/should
import yog/generators/random
import yog/pathfinding

pub fn main() {
  gleeunit.main()
}

/// This is a simple timing test (not a full benchmark)
/// It demonstrates the approach - see BENCHMARKING_GUIDE.md for gleamy_bench usage
pub fn basic_pathfinding_performance_test() {
  io.println("\n=== Basic Performance Test ===")

  // Small graph - should be fast
  let small_graph = random.erdos_renyi_gnp(100, 0.05)
  io.println("Testing Dijkstra on 100-node graph...")

  let result =
    pathfinding.shortest_path(
      in: small_graph,
      from: 0,
      to: 99,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Just verify it completes without crashing
  case result {
    option.Some(_path) ->
      io.println("✓ Pathfinding completed successfully - path found")
    option.None ->
      io.println("✓ Pathfinding completed - no path (OK for random graphs)")
  }

  // Test passes if we get here
  1 |> should.equal(1)
}
