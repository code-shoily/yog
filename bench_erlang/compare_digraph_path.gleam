////  Yog vs Erlang digraph - Shortest Path Comparison
////
//// This benchmark is Erlang-only and must be copied to src/internal/bench/ first:
////   cp bench_erlang/compare_digraph_path.gleam src/internal/bench/
////   gleam run -m internal/bench/compare_digraph_path
////   rm src/internal/bench/compare_digraph_path.gleam

import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleamy/bench
import internal/bench/bench_utils
import yog/model.{type Graph}
import yog/pathfinding

// Erlang digraph FFI
@external(erlang, "digraph", "new")
fn digraph_new() -> DigraphHandle

@external(erlang, "digraph", "add_vertex")
fn digraph_add_vertex(g: DigraphHandle, v: Int) -> Int

@external(erlang, "digraph", "add_edge")
fn digraph_add_edge(g: DigraphHandle, from: Int, to: Int) -> EdgeHandle

@external(erlang, "digraph", "get_short_path")
fn digraph_get_short_path(
  g: DigraphHandle,
  from: Int,
  to: Int,
) -> Result(List(Int), Nil)

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║        YOG vs ERLANG DIGRAPH - SHORTEST PATH              ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Shortest Path (unweighted)")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create test graphs
  let small_yog =
    bench_utils.random_graph(bench_utils.Small, bench_utils.Sparse, 42)
  let small_dg = yog_to_digraph(small_yog)

  let medium_yog =
    bench_utils.random_graph(bench_utils.Medium, bench_utils.Sparse, 42)
  let medium_dg = yog_to_digraph(medium_yog)

  let inputs = [
    bench.Input("Small: 100 nodes", #(small_yog, small_dg, 0, 99)),
    bench.Input("Medium: 1K nodes", #(medium_yog, medium_dg, 0, 999)),
  ]

  let functions = [
    bench.Function("Yog (Dijkstra)", bench_yog_path),
    bench.Function("Erlang digraph (BFS)", bench_digraph_path),
  ]

  bench.run(inputs, functions, [bench.Duration(2000), bench.Warmup(500)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println

  // Cleanup
  let _ = digraph_delete(small_dg)
  let _ = digraph_delete(medium_dg)

  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║                      BENCHMARK COMPLETE                    ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Note: Yog uses Dijkstra's algorithm (O((V+E) log V)).")
  io.println("digraph:get_short_path/3 uses BFS (O(V+E)).")
  io.println("BFS is optimal for unweighted graphs.\n")
}

fn yog_to_digraph(graph: Graph(Nil, Int)) -> DigraphHandle {
  let dg = digraph_new()

  let nodes = model.all_nodes(graph)
  list.each(nodes, fn(node) {
    let _ = digraph_add_vertex(dg, node)
  })

  let _ = case graph {
    model.Graph(out_edges: out_edges, ..) -> {
      dict.fold(out_edges, Nil, fn(_, from, to_map) {
        dict.fold(to_map, Nil, fn(_, to, _weight) {
          let _ = digraph_add_edge(dg, from, to)
          Nil
        })
      })
    }
  }

  dg
}

fn bench_yog_path(input: #(Graph(Nil, Int), DigraphHandle, Int, Int)) -> Nil {
  let #(yog_graph, _dg, from, to) = input
  let _ =
    pathfinding.shortest_path(
      in: yog_graph,
      from: from,
      to: to,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  Nil
}

fn bench_digraph_path(input: #(Graph(Nil, Int), DigraphHandle, Int, Int)) -> Nil {
  let #(_yog_graph, dg, from, to) = input
  let _ = digraph_get_short_path(dg, from, to)
  Nil
}
