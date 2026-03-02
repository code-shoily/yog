////  Yog vs Erlang digraph Comparison Benchmark
////
//// Compares Yog's SCC implementation against Erlang's built-in digraph
////
//// This benchmark is Erlang-only and must be copied to src/internal/bench/ first:
////   cp bench_erlang/compare_digraph.gleam src/internal/bench/
////   gleam run -m internal/bench/compare_digraph
////   rm src/internal/bench/compare_digraph.gleam

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

@external(erlang, "digraph_utils", "strong_components")
fn digraph_strong_components(g: DigraphHandle) -> List(List(Int))

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║         YOG vs ERLANG DIGRAPH - SCC COMPARISON            ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Strongly Connected Components")
  io.println("Comparing: Yog (Tarjan) vs Erlang digraph")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create test graphs - convert to both representations
  let small_yog =
    bench_utils.random_graph(bench_utils.Small, bench_utils.Sparse, 42)
  let small_dg = yog_to_digraph(small_yog)

  let medium_yog =
    bench_utils.random_graph(bench_utils.Medium, bench_utils.Sparse, 42)
  let medium_dg = yog_to_digraph(medium_yog)

  // Pass both representations to each benchmark
  let inputs = [
    bench.Input("Small: 100 nodes", #(small_yog, small_dg)),
    bench.Input("Medium: 1K nodes", #(medium_yog, medium_dg)),
  ]

  let functions = [
    bench.Function("Yog (Tarjan)", bench_yog_scc),
    bench.Function("Erlang digraph", bench_digraph_scc),
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

  io.println("Note: Both use Tarjan's algorithm (single-pass).")
  io.println("Graphs pre-built - only measuring SCC computation.\n")
}

// Convert Yog graph to digraph (done once, outside benchmark)
fn yog_to_digraph(graph: Graph(Nil, Int)) -> DigraphHandle {
  let dg = digraph_new()

  // Add vertices
  let nodes = model.all_nodes(graph)
  list.each(nodes, fn(node) {
    let _ = digraph_add_vertex(dg, node)
  })

  // Add edges
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

fn bench_yog_scc(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(yog_graph, _dg) = input
  let _ = components.strongly_connected_components(yog_graph)
  Nil
}

fn bench_digraph_scc(input: #(Graph(Nil, Int), DigraphHandle)) -> Nil {
  let #(_yog_graph, dg) = input
  let _ = digraph_strong_components(dg)
  Nil
}
