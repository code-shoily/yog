////  Yog vs Erlang digraph - Topological Sort Comparison
////
//// This benchmark is Erlang-only and must be copied to src/internal/bench/ first:
////   cp bench_erlang/compare_digraph_topsort.gleam src/internal/bench/
////   gleam run -m internal/bench/compare_digraph_topsort
////   rm src/internal/bench/compare_digraph_topsort.gleam

import gleam/dict
import gleam/io
import gleam/list
import gleamy/bench
import internal/bench/bench_utils
import yog/model.{type Graph}
import yog/topological_sort

// Erlang digraph FFI
@external(erlang, "digraph", "new")
fn digraph_new() -> DigraphHandle

@external(erlang, "digraph", "add_vertex")
fn digraph_add_vertex(g: DigraphHandle, v: Int) -> Int

@external(erlang, "digraph", "add_edge")
fn digraph_add_edge(g: DigraphHandle, from: Int, to: Int) -> EdgeHandle

@external(erlang, "digraph_utils", "topsort")
fn digraph_topsort(g: DigraphHandle) -> Result(List(Int), Nil)

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║       YOG vs ERLANG DIGRAPH - TOPOLOGICAL SORT            ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Topological Sort on DAGs")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create DAGs (directed acyclic graphs)
  let small_yog = bench_utils.random_dag(100, 42)
  let small_dg = yog_to_digraph(small_yog)

  let medium_yog = bench_utils.random_dag(1000, 42)
  let medium_dg = yog_to_digraph(medium_yog)

  let inputs = [
    bench.Input("Small DAG: 100 nodes", #(small_yog, small_dg)),
    bench.Input("Medium DAG: 1K nodes", #(medium_yog, medium_dg)),
  ]

  let functions = [
    bench.Function("Yog (Kahn)", bench_yog_topsort),
    bench.Function("Erlang digraph", bench_digraph_topsort),
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

  io.println("Note: Yog uses Kahn's algorithm.")
  io.println("digraph_utils:topsort/1 uses depth-first search.\n")
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

fn bench_yog_topsort(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(yog_graph, _dg) = input
  let _ = topological_sort.topological_sort(yog_graph)
  Nil
}

fn bench_digraph_topsort(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(_yog_graph, dg) = input
  let _ = digraph_topsort(dg)
  Nil
}
