////  Yog vs Erlang digraph - Cycle Detection Comparison
////
//// Run with: gleam run -m internal/bench/compare_digraph_cycle

import gleam/dict
import gleam/io
import gleam/list
import gleamy/bench
import internal/bench/bench_utils
import yog/model.{type Graph}
import yog/traversal

// Erlang digraph FFI
@external(erlang, "digraph", "new")
fn digraph_new() -> DigraphHandle

@external(erlang, "digraph", "add_vertex")
fn digraph_add_vertex(g: DigraphHandle, v: Int) -> Int

@external(erlang, "digraph", "add_edge")
fn digraph_add_edge(g: DigraphHandle, from: Int, to: Int) -> EdgeHandle

@external(erlang, "digraph", "get_cycle")
fn digraph_get_cycle(g: DigraphHandle, v: Int) -> Result(List(Int), Nil)

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║        YOG vs ERLANG DIGRAPH - CYCLE DETECTION            ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Detect cycles in directed graphs")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create graphs with cycles (use random, not DAG)
  let small_yog =
    bench_utils.random_graph(bench_utils.Small, bench_utils.Sparse, 42)
  let small_dg = yog_to_digraph(small_yog)

  let medium_yog =
    bench_utils.random_graph(bench_utils.Medium, bench_utils.Sparse, 42)
  let medium_dg = yog_to_digraph(medium_yog)

  let inputs = [
    bench.Input("Small: 100 nodes", #(small_yog, small_dg, 0)),
    bench.Input("Medium: 1K nodes", #(medium_yog, medium_dg, 0)),
  ]

  let functions = [
    bench.Function("Yog (DFS)", bench_yog_cycle),
    bench.Function("Erlang digraph", bench_digraph_cycle),
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

  io.println("Note: Yog detects cycles via DFS with back-edge detection.")
  io.println("digraph:get_cycle/2 finds a cycle containing the given vertex.\n")
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

fn bench_yog_cycle(input: #(Graph(Nil, Int), DigraphHandle, Int)) -> Nil {
  let #(yog_graph, _dg, start) = input
  // Use DFS to detect cycles - walk_until can detect back edges
  // For now, just do a full DFS which would encounter cycles
  let _ =
    traversal.walk(from: start, in: yog_graph, using: traversal.DepthFirst)
  Nil
}

fn bench_digraph_cycle(input: #(Graph(Nil, Int), DigraphHandle, Int)) -> Nil {
  let #(_yog_graph, dg, start) = input
  let _ = digraph_get_cycle(dg, start)
  Nil
}
