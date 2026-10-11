////  Simple Pathfinding Benchmark
////
//// Compares Dijkstra's algorithm across different graph sizes
//// Run with: `gleam run -m bench/simple_pathfinding`

import bench/bench_util
import gleam/int
import gleam/io
import gleamy/bench
import yog/model.{type Graph}
import yog/pathfinding/dijkstra as pathfinding

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║         PATHFINDING BENCHMARK - GRAPH SIZE SCALING        ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: How does Dijkstra scale with graph size?")
  io.println("Expected: O((V+E) log V) complexity\n")

  // Use grid graphs to guarantee full connectivity (no disconnected component bias)
  // Grid 10x10 = 100 nodes, Grid 32x32 ≈ 1,024 nodes
  let small_grid = bench_util.grid_graph(10, 10)
  let medium_grid = bench_util.grid_graph(32, 32)

  let inputs = [
    bench.Input("Grid Small: 100 nodes", #(small_grid, 0)),
    bench.Input("Grid Medium: ~1K nodes", #(medium_grid, 0)),
  ]

  let functions = [
    bench.Function("Single-Source Dijkstra", bench_single_source_dijkstra),
    bench.Function("Point-to-Point Dijkstra", bench_point_to_point_dijkstra),
  ]

  // Run and display results
  bench.run(inputs, functions, [bench.Duration(2000), bench.Warmup(500)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println

  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║                      BENCHMARK COMPLETE                    ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")
}

fn bench_single_source_dijkstra(input: #(Graph(Nil, Int), Int)) -> Nil {
  let #(graph, source) = input
  let _ =
    pathfinding.single_source_distances(
      in: graph,
      from: source,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  Nil
}

fn bench_point_to_point_dijkstra(input: #(Graph(Nil, Int), Int)) -> Nil {
  let #(graph, from) = input
  // Query from corner to opposite corner of the grid
  let target = model.node_count(graph) - 1
  let _ =
    pathfinding.shortest_path(
      in: graph,
      from: from,
      to: target,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  Nil
}
