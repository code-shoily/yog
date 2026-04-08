import gleam/list
import qcheck
import yog/internal/utils
import yog/model.{type Graph, type GraphType}
import yog/traversal

/// Generate a random GraphType (Directed or Undirected)
///
/// **Generates:** `model.Directed` | `model.Undirected`
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
///
/// **Generates:** `Graph(Int, Int)` with 0-15 nodes and 0-30 edges.
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
///
/// **Generates:** `Graph(Int, Int)` with `num_nodes` and `num_edges`.
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
    let assert Ok(g) = model.add_edge(g, from: src, to: dst, with: weight)
    g
  })
}

/// Generate an undirected graph
///
/// **Generates:** `Graph(Int, Int)` with `model.Undirected` kind.
pub fn undirected_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Undirected, num_nodes, num_edges)
}

/// Generate a directed graph
///
/// **Generates:** `Graph(Int, Int)` with `model.Directed` kind.
pub fn directed_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(0, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  graph_generator_custom(model.Directed, num_nodes, num_edges)
}

/// Generate an edge triple #(src, dst, weight) with a custom weight generator
///
/// **Generates:** `#(Int, Int, Int)` where `src`, `dst` < `num_nodes`.
pub fn edge_triple_generator_custom(
  num_nodes: Int,
  weight_gen: qcheck.Generator(Int),
) {
  case num_nodes {
    0 -> qcheck.return(#(0, 0, 1))
    _ -> {
      use src <- qcheck.bind(qcheck.bounded_int(0, num_nodes - 1))
      use dst <- qcheck.bind(qcheck.bounded_int(0, num_nodes - 1))
      use weight <- qcheck.map(weight_gen)
      #(src, dst, weight)
    }
  }
}

/// Generate a standard edge triple #(src, dst, weight).
///
/// **Generates:** `#(Int, Int, Int)` with weight in range `[1, 100]`.
pub fn edge_triple_generator(num_nodes: Int) {
  edge_triple_generator_custom(num_nodes, qcheck.bounded_int(1, 100))
}

/// Generate a traversal order (BFS or DFS)
///
/// **Generates:** `traversal.BreadthFirst` | `traversal.DepthFirst`
pub fn traversal_order_generator() {
  use is_bfs <- qcheck.map(qcheck.bool())
  case is_bfs {
    True -> traversal.BreadthFirst
    False -> traversal.DepthFirst
  }
}

/// Generate a graph and a single edge triple compatible with it.
///
/// **Generates:** `#(Graph(Int, Int), #(Int, Int, Int))`
pub fn graph_and_edge_generator(kind: GraphType) {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(1, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))
  use graph <- qcheck.bind(graph_generator_custom(kind, num_nodes, num_edges))
  use edge <- qcheck.map(edge_triple_generator(num_nodes))
  #(graph, edge)
}

/// Generate a star graph with a center and leaves
///
/// **Generates:** `#(Graph(Int, Int), center_id, leaf_ids)`
/// - Center: `0`
/// - Leaves: `1` to `num_nodes - 1`
pub fn star_graph_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(3, 10))
  let center = 0
  let leaves = utils.range(1, num_nodes - 1)

  let graph = build_nodes(model.new(model.Undirected), 0, num_nodes - 1)

  let graph =
    list.fold(leaves, graph, fn(g, leaf) {
      let assert Ok(g) = model.add_edge(g, from: center, to: leaf, with: 1)
      g
    })

  qcheck.return(#(graph, center, leaves))
}

fn unweighted_edge_generator(num_nodes: Int) {
  use src <- qcheck.bind(qcheck.bounded_int(0, num_nodes - 1))
  use dst <- qcheck.map(qcheck.bounded_int(0, num_nodes - 1))
  #(src, dst)
}

/// Generate an unweighted graph (all edge weights are 1)
///
/// **Generates:** `Graph(Int, Int)` with all edge weights set to `1`.
pub fn unweighted_graph_generator(kind: GraphType) {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(1, 15))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 30))

  use edges <- qcheck.bind(qcheck.fixed_length_list_from(
    unweighted_edge_generator(num_nodes),
    num_edges,
  ))

  let graph = build_nodes(model.new(kind), 0, num_nodes - 1)

  let graph =
    edges
    |> list.fold(graph, fn(g, edge) {
      let #(src, dst) = edge
      let assert Ok(g) = model.add_edge(g, from: src, to: dst, with: 1)
      g
    })

  qcheck.return(graph)
}

/// Generate a graph with potentially negative weights (-20 to 50)
///
/// **Generates:** `Graph(Int, Int)` with weights in range `[-20, 50]`.
pub fn graph_generator_negative_weights(kind: GraphType) {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(3, 10))
  use num_edges <- qcheck.bind(qcheck.bounded_int(0, 20))

  use edges <- qcheck.map(qcheck.fixed_length_list_from(
    edge_triple_generator_custom(num_nodes, qcheck.bounded_int(-20, 50)),
    num_edges,
  ))

  let graph = build_nodes(model.new(kind), 0, num_nodes - 1)

  edges
  |> list.fold(graph, fn(g, edge) {
    let #(src, dst, weight) = edge
    let assert Ok(g) = model.add_edge(g, from: src, to: dst, with: weight)
    g
  })
}

/// Generate a random tree
///
/// **Generates:** A connected, acyclic undirected `Graph(Int, Int)`.
pub fn tree_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(2, 15))
  let graph = build_nodes(model.new(model.Undirected), 0, num_nodes - 1)

  // i > 0 connects to some j < i
  add_tree_edges(graph, 1, num_nodes)
}

fn add_tree_edges(g, i, n) {
  case i >= n {
    True -> qcheck.return(g)
    False -> {
      use parent <- qcheck.bind(qcheck.bounded_int(0, i - 1))
      let assert Ok(next_g) = model.add_edge(g, from: parent, to: i, with: 1)
      add_tree_edges(next_g, i + 1, n)
    }
  }
}
