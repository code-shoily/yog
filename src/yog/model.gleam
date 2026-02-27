import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/result
import yog/internal/utils

/// Unique identifier for a node in the graph.
pub type NodeId =
  Int

/// The type of graph: directed or undirected.
pub type GraphType {
  /// A directed graph where edges have a direction from source to destination.
  Directed
  /// An undirected graph where edges are bidirectional.
  Undirected
}

/// A graph data structure that can be directed or undirected.
///
/// - `node_data`: The type of data stored at each node
/// - `edge_data`: The type of data (usually weight) stored on each edge
pub type Graph(node_data, edge_data) {
  Graph(
    kind: GraphType,
    nodes: Dict(NodeId, node_data),
    out_edges: Dict(NodeId, Dict(NodeId, edge_data)),
    in_edges: Dict(NodeId, Dict(NodeId, edge_data)),
  )
}

/// Creates a new empty graph of the specified type.
///
/// ## Example
///
/// ```gleam
/// let graph = model.new(Directed)
/// ```
pub fn new(graph_type: GraphType) -> Graph(n, e) {
  Graph(
    kind: graph_type,
    nodes: dict.new(),
    out_edges: dict.new(),
    in_edges: dict.new(),
  )
}

/// Adds a node to the graph with the given ID and data.
/// If a node with this ID already exists, its data will be replaced.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> model.add_node(1, "Node A")
/// |> model.add_node(2, "Node B")
/// ```
pub fn add_node(graph: Graph(n, e), id: NodeId, data: n) -> Graph(n, e) {
  let new_nodes = dict.insert(graph.nodes, id, data)
  Graph(..graph, nodes: new_nodes)
}

/// Adds an edge to the graph with the given weight.
///
/// For directed graphs, adds a single edge from `src` to `dst`.
/// For undirected graphs, adds edges in both directions.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> model.add_edge(from: 1, to: 2, with: 10)
/// ```
pub fn add_edge(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
) -> Graph(n, e) {
  let graph = do_add_directed_edge(graph, src, dst, weight)

  case graph.kind {
    Directed -> graph
    Undirected -> do_add_directed_edge(graph, dst, src, weight)
  }
}

/// Gets nodes you can travel TO (Successors).
pub fn successors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  graph.out_edges
  |> dict.get(id)
  |> result.map(dict.to_list)
  |> result.unwrap([])
}

/// Gets nodes you came FROM (Predecessors).
pub fn predecessors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  graph.in_edges
  |> dict.get(id)
  |> result.map(dict.to_list)
  |> result.unwrap([])
}

/// Gets everyone connected to the node, regardless of direction.
/// Useful for algorithms like finding "connected components."
pub fn neighbors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  case graph.kind {
    Undirected -> successors(graph, id)
    // In Undirected, out_edges == in_edges
    Directed -> {
      let out = successors(graph, id)
      let in_ = predecessors(graph, id)
      // Combine them and remove duplicates if an edge exists in both directions
      list.fold(in_, out, fn(acc, incoming) {
        let #(in_id, _) = incoming
        case list.any(out, fn(o) { o.0 == in_id }) {
          True -> acc
          False -> [incoming, ..acc]
        }
      })
    }
  }
}

/// Returns all node IDs in the graph.
/// This includes all nodes, even isolated nodes with no edges.
pub fn all_nodes(graph: Graph(n, e)) -> List(NodeId) {
  dict.keys(graph.nodes)
}

/// Returns the number of nodes in the graph (graph order).
///
/// **Time Complexity:** O(1)
pub fn order(graph: Graph(n, e)) -> Int {
  dict.size(graph.nodes)
}

/// Returns just the NodeIds of successors (without edge weights).
/// Convenient for traversal algorithms that only need the IDs.
pub fn successor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  successors(graph, id)
  |> list.map(fn(edge) { edge.0 })
}

fn do_add_directed_edge(
  graph: Graph(n, e),
  src: NodeId,
  dst: NodeId,
  weight: e,
) -> Graph(n, e) {
  let out_update_fn = fn(maybe_inner_map) {
    case maybe_inner_map {
      option.Some(m) -> dict.insert(m, dst, weight)
      option.None -> dict.from_list([#(dst, weight)])
    }
  }

  let in_update_fn = fn(maybe_inner_map) {
    case maybe_inner_map {
      option.Some(m) -> dict.insert(m, src, weight)
      option.None -> dict.from_list([#(src, weight)])
    }
  }

  let new_out = dict.upsert(graph.out_edges, src, out_update_fn)
  let new_in = dict.upsert(graph.in_edges, dst, in_update_fn)

  Graph(..graph, out_edges: new_out, in_edges: new_in)
}

/// Removes a node and all its connected edges (incoming and outgoing).
///
/// **Time Complexity:** O(deg(v)) - proportional to the number of edges
/// connected to the node, not the whole graph.
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 2, to: 3, with: 20)
///
/// let graph = model.remove_node(graph, 2)
/// // Node 2 is removed, along with edges 1->2 and 2->3
/// ```
pub fn remove_node(graph: Graph(n, e), id: NodeId) -> Graph(n, e) {
  let targets = successors(graph, id)
  let sources = predecessors(graph, id)

  let new_nodes = dict.delete(graph.nodes, id)

  let new_out = dict.delete(graph.out_edges, id)
  let new_in_cleaned =
    list.fold(targets, graph.in_edges, fn(acc_in, target) {
      let #(target_id, _) = target
      utils.dict_update_inner(acc_in, target_id, id, dict.delete)
    })

  let new_in = dict.delete(new_in_cleaned, id)
  let new_out_cleaned =
    list.fold(sources, new_out, fn(acc_out, source) {
      let #(source_id, _) = source
      utils.dict_update_inner(acc_out, source_id, id, dict.delete)
    })

  Graph(..graph, nodes: new_nodes, out_edges: new_out_cleaned, in_edges: new_in)
}

/// Adds an edge, but if an edge already exists between `src` and `dst`,
/// it combines the new weight with the existing one using `with_combine`.
///
/// The combine function receives `(existing_weight, new_weight)` and should
/// return the combined weight.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge_with_combine(from: 1, to: 2, with: 5, using: int.add)
/// // Edge 1->2 now has weight 15 (10 + 5)
/// ```
///
/// ## Use Cases
///
/// - **Edge contraction** in graph algorithms (Stoer-Wagner min-cut)
/// - **Multi-graph support** (adding parallel edges with combined weights)
/// - **Incremental graph building** (accumulating weights from multiple sources)
pub fn add_edge_with_combine(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  using with_combine: fn(e, e) -> e,
) -> Graph(n, e) {
  let graph = do_add_directed_combine(graph, src, dst, weight, with_combine)

  case graph.kind {
    Directed -> graph
    Undirected -> do_add_directed_combine(graph, dst, src, weight, with_combine)
  }
}

fn do_add_directed_combine(
  graph: Graph(n, e),
  src: NodeId,
  dst: NodeId,
  weight: e,
  with_combine: fn(e, e) -> e,
) -> Graph(n, e) {
  let update_fn = fn(maybe_inner_map) {
    case maybe_inner_map {
      option.Some(m) -> {
        let new_weight = case dict.get(m, dst) {
          Ok(existing) -> with_combine(existing, weight)
          Error(_) -> weight
        }
        dict.insert(m, dst, new_weight)
      }
      option.None -> dict.from_list([#(dst, weight)])
    }
  }

  let new_out = dict.upsert(graph.out_edges, src, update_fn)
  let new_in =
    dict.upsert(graph.in_edges, dst, fn(maybe_m) {
      case maybe_m {
        option.Some(m) -> {
          let new_weight = case dict.get(m, src) {
            Ok(existing) -> with_combine(existing, weight)
            Error(_) -> weight
          }
          dict.insert(m, src, new_weight)
        }
        option.None -> dict.from_list([#(src, weight)])
      }
    })

  Graph(..graph, out_edges: new_out, in_edges: new_in)
}
