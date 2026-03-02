import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import yog
import yog/generators/classic
import yog/generators/random
import yog/internal/utils
import yog/model.{type Graph}

/// Graph size configurations for benchmarking
pub type GraphSize {
  Small
  Medium
  Large
  XLarge
}

pub fn size_to_nodes(size: GraphSize) -> Int {
  case size {
    Small -> 100
    Medium -> 1000
    Large -> 10_000
    XLarge -> 100_000
  }
}

/// Graph density configurations
pub type GraphDensity {
  Sparse
  MediumDensity
  Dense
}

pub fn density_to_probability(density: GraphDensity) -> Float {
  case density {
    Sparse -> 0.01
    // Sparse: E ≈ V
    MediumDensity -> 0.05
    // Medium: E ≈ 5V
    Dense -> 0.2
    // Dense: E ≈ 20% of V²
  }
}

/// Generate a random graph for benchmarking
pub fn random_graph(
  size: GraphSize,
  density: GraphDensity,
  _seed: Int,
) -> Graph(Nil, Int) {
  let nodes = size_to_nodes(size)
  let prob = density_to_probability(density)
  random.erdos_renyi_gnp(nodes, prob)
}

/// Generate a grid graph (useful for pathfinding benchmarks)
pub fn grid_graph(width: Int, height: Int) -> Graph(Nil, Int) {
  let graph = yog.undirected()

  // Create nodes
  let graph =
    utils.range(0, width * height - 1)
    |> list.fold(graph, fn(g, id) { yog.add_node(g, id, Nil) })

  // Add edges (4-connected grid)
  utils.range(0, height - 1)
  |> list.fold(graph, fn(g, y) {
    utils.range(0, width - 1)
    |> list.fold(g, fn(gg, x) {
      let node = y * width + x
      let gg = case x < width - 1 {
        True -> yog.add_edge(gg, node, node + 1, 1)
        False -> gg
      }
      case y < height - 1 {
        True -> yog.add_edge(gg, node, node + width, 1)
        False -> gg
      }
    })
  })
}

/// Generate a complete graph for worst-case testing
pub fn complete_graph(nodes: Int) -> Graph(Nil, Int) {
  classic.complete(nodes)
}

/// Generate a DAG for topological sort benchmarks
pub fn random_dag(nodes: Int, seed: Int) -> Graph(Nil, Int) {
  let graph = yog.directed()

  // Add nodes
  let graph =
    utils.range(0, nodes - 1)
    |> list.fold(graph, fn(g, id) { yog.add_node(g, id, Nil) })

  // Add edges only from lower to higher node IDs (ensures DAG property)
  utils.range(0, nodes - 1)
  |> list.fold(graph, fn(g, from) {
    utils.range(from + 1, nodes - 1)
    |> list.fold(g, fn(gg, to) {
      // Use simple pseudo-random check
      let should_add = { from * 31 + to * 17 + seed } % 10 < 3
      case should_add {
        True -> yog.add_edge(gg, from, to, 1)
        False -> gg
      }
    })
  })
}

/// Generate a bipartite graph for matching benchmarks
pub fn bipartite_graph(left_nodes: Int, right_nodes: Int) -> Graph(Nil, Int) {
  classic.complete_bipartite(left_nodes, right_nodes)
}

/// Format benchmark results for display
pub fn format_time(microseconds: Float) -> String {
  case microseconds <. 1000.0, microseconds <. 1_000_000.0 {
    True, _ -> float_to_string(microseconds) <> " μs"
    False, True -> float_to_string(microseconds /. 1000.0) <> " ms"
    False, False -> float_to_string(microseconds /. 1_000_000.0) <> " s"
  }
}

fn float_to_string(f: Float) -> String {
  // Simple approximation - round to nearest integer
  let rounded = f |> float.round |> int.to_string
  rounded
}

/// Extract graph statistics for reporting
pub fn graph_stats(graph: Graph(a, b)) -> #(Int, Int) {
  let nodes = yog.all_nodes(graph) |> list.length

  // Count edges by iterating through out_edges
  let edge_count = case graph {
    model.Graph(out_edges: out_edges, kind: kind, ..) -> {
      dict.fold(out_edges, 0, fn(count, _from, to_edges) {
        count + dict.size(to_edges)
      })
      |> fn(c) {
        // For undirected graphs, each edge is stored once
        // For directed graphs, edges are already counted correctly
        case kind {
          model.Undirected -> c
          model.Directed -> c
        }
      }
    }
  }

  #(nodes, edge_count)
}
