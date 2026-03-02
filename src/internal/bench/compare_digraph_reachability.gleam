////  Yog vs Erlang digraph - Reachability Comparison
////
//// Run with: gleam run -m internal/bench/compare_digraph_reachability

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

@external(erlang, "digraph_utils", "reachable")
fn digraph_reachable(vertices: List(Int), g: DigraphHandle) -> List(Int)

@external(erlang, "digraph", "delete")
fn digraph_delete(g: DigraphHandle) -> Bool

type DigraphHandle

type EdgeHandle

pub fn main() {
  io.println("\n╔════════════════════════════════════════════════════════════╗")
  io.println("║       YOG vs ERLANG DIGRAPH - REACHABILITY QUERIES        ║")
  io.println("╚════════════════════════════════════════════════════════════╝\n")

  io.println("Benchmarking: Find all reachable vertices from a starting point")
  io.println("Both graphs pre-built - measuring algorithm only\n")

  // Create test graphs
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
    bench.Function("Yog (BFS)", bench_yog_reachable),
    bench.Function("Erlang digraph", bench_digraph_reachable),
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

  io.println("Note: Yog uses BFS traversal.")
  io.println("digraph_utils:reachable/2 uses depth-first traversal.\n")
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

fn bench_yog_reachable(input: #(Graph(Nil, Int), DigraphHandle, Int)) -> Nil {
  let #(yog_graph, _dg, start) = input
  // BFS traversal gives us all reachable nodes
  let _ =
    traversal.walk(from: start, in: yog_graph, using: traversal.BreadthFirst)
  Nil
}

fn bench_digraph_reachable(input: #(Graph(Nil, Int), DigraphHandle, Int)) -> Nil {
  let #(_yog_graph, dg, start) = input
  let _ = digraph_reachable([start], dg)
  Nil
}
