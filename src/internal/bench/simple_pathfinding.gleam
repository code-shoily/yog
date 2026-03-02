////  Simple Pathfinding Benchmark
////
//// Compares Dijkstra's algorithm across different graph sizes
//// Run with: gleam run -m internal/bench/simple_pathfinding

import gleam/int
import gleam/io
import gleamy/bench
import internal/bench/bench_utils
import yog/model.{type Graph}
import yog/pathfinding

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║         PATHFINDING BENCHMARK - GRAPH SIZE SCALING        ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: How does Dijkstra scale with graph size?")
  io.println("Expected: O((V+E) log V) complexity\n")

  // Create test graphs of different sizes
  let small =
    bench_utils.random_graph(bench_utils.Small, bench_utils.Sparse, 42)
  let medium =
    bench_utils.random_graph(bench_utils.Medium, bench_utils.Sparse, 42)

  // Wrap inputs in bench.Input
  let inputs = [
    bench.Input("Small: 100 nodes", #(small, 0, 99)),
    bench.Input("Medium: 1K nodes", #(medium, 0, 999)),
  ]

  // Wrap function in bench.Function
  let functions = [bench.Function("Dijkstra", bench_dijkstra)]

  // Run and display results
  bench.run(inputs, functions, [bench.Duration(2000), bench.Warmup(500)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println

  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║                      BENCHMARK COMPLETE                    ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")
}

fn bench_dijkstra(input: #(Graph(Nil, Int), Int, Int)) -> Nil {
  let #(graph, from, to) = input
  let _ =
    pathfinding.shortest_path(
      in: graph,
      from: from,
      to: to,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  Nil
}
