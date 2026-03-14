import gleam/list
import qcheck
import yog/model.{type Graph, type GraphType}
import yog/traversal

/// Generate a random GraphType (Directed or Undirected)
pub fn graph_type_generator() {
  use is_directed <- qcheck.map(qcheck.bool())
  case is_directed {
    True -> model.Directed
    False -> model.Undirected
  }
}

/// Generate a random graph with Int node data and Int edge weights
/// - Nodes: 0 to max_nodes-1
/// - Edges: Random connections with positive weights
pub fn graph_generator() {
  use kind <- qcheck.bind(graph_type_generator())
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(kind, num_nodes, num_edges)
}

fn build_nodes(graph: Graph(Int, e), current: Int, max: Int) -> Graph(Int, e) {
  case current > max {
    True -> graph
    False ->
      build_nodes(model.add_node(graph, current, current), current + 1, max)
  }
}

/// Generate a graph with specific parameters
pub fn graph_generator_custom(
  kind: GraphType,
  num_nodes: Int,
  num_edges: Int,
) -> qcheck.Generator(Graph(Int, Int)) {
  use edges <- qcheck.map(qcheck.fixed_length_list_from(
    edge_triple_generator(num_nodes),
    num_edges,
  ))

  // Build graph: add nodes first, then edges
  let graph = build_nodes(model.new(kind), 0, num_nodes - 1)

  let valid_edges = case num_nodes {
    0 -> []
    _ -> edges
  }

  valid_edges
  |> list.fold(graph, fn(g, edge) {
    let #(src, dst, weight) = edge
    model.add_edge(g, from: src, to: dst, with: weight)
  })
}

/// Generate an undirected graph
pub fn undirected_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Undirected, num_nodes, num_edges)
}

/// Generate a directed graph
pub fn directed_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Directed, num_nodes, num_edges)
}

/// Generate an edge triple #(src, dst, weight)
pub fn edge_triple_generator(num_nodes: Int) {
  case num_nodes {
    0 -> qcheck.return(#(0, 0, 1))
    _ -> {
      use src <- qcheck.bind(qcheck.bounded_int(0, num_nodes - 1))
      use dst <- qcheck.bind(qcheck.bounded_int(0, num_nodes - 1))
      use weight <- qcheck.map(qcheck.bounded_int(1, 100))
      #(src, dst, weight)
    }
  }
}

/// Generate a traversal order (BFS or DFS)
pub fn traversal_order_generator() {
  use is_bfs <- qcheck.map(qcheck.bool())
  case is_bfs {
    True -> traversal.BreadthFirst
    False -> traversal.DepthFirst
  }
}

pub fn graph_and_edge_generator(kind: GraphType) {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(1, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))
  use graph <- qcheck.bind(graph_generator_custom(kind, num_nodes, num_edges))
  use edge <- qcheck.map(edge_triple_generator(num_nodes))
  #(graph, edge)
}
