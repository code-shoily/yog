////  Yog vs Erlang digraph - Condensation Comparison
////
//// This benchmark is Erlang-only and must be copied to src/internal/bench/ first:
////   cp bench_erlang/compare_digraph_condensation.gleam src/internal/bench/
////   gleam run -m internal/bench/compare_digraph_condensation
////   rm src/internal/bench/compare_digraph_condensation.gleam

import gleam/dict
import gleam/io
import gleam/list
import gleamy/bench
import internal/bench/bench_utils
import yog/components
import yog/model.{type Graph}

// Erlang digraph FFI
@external(erlang, "digraph", "new")
fn digraph_new() -> DigraphHandle

@external(erlang, "digraph", "add_vertex")
fn digraph_add_vertex(g: DigraphHandle, v: Int) -> Int

@external(erlang, "digraph", "add_edge")
fn digraph_add_edge(g: DigraphHandle, from: Int, to: Int) -> EdgeHandle

@external(erlang, "digraph_utils", "condensation")
fn digraph_condensation(g: DigraphHandle) -> DigraphHandle

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║       YOG vs ERLANG DIGRAPH - CONDENSATION                ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Create condensation graph (SCC → nodes)")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create graphs with multiple SCCs
  let small_yog =
    bench_utils.random_graph(bench_utils.Small, bench_utils.Sparse, 42)
  let small_dg = yog_to_digraph(small_yog)

  let medium_yog =
    bench_utils.random_graph(bench_utils.Medium, bench_utils.Sparse, 42)
  let medium_dg = yog_to_digraph(medium_yog)

  let inputs = [
    bench.Input("Small: 100 nodes", #(small_yog, small_dg)),
    bench.Input("Medium: 1K nodes", #(medium_yog, medium_dg)),
  ]

  let functions = [
    bench.Function("Yog (SCC-based)", bench_yog_condensation),
    bench.Function("Erlang digraph", bench_digraph_condensation),
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

  io.println("Note: Yog computes SCCs (base for condensation).")
  io.println("digraph_utils:condensation/1 builds full condensation graph.\n")
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

fn bench_yog_condensation(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(yog_graph, _dg) = input
  // Find SCCs - this is the core computation for condensation
  let _ = components.strongly_connected_components(yog_graph)
  // Note: Not building the full condensation graph structure,
  // just computing the SCCs which is the expensive part
  Nil
}

fn bench_digraph_condensation(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(_yog_graph, dg) = input
  let condensed = digraph_condensation(dg)
  // Clean up the condensed graph
  let _ = digraph_delete(condensed)
  Nil
}
