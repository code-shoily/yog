//// Core graph data structures and basic operations for the yog library.
////
//// This module defines the fundamental `Graph` type and provides all basic operations
//// for creating and manipulating graphs. The graph uses an adjacency list representation
//// with dual indexing (both outgoing and incoming edges) for efficient traversal in both
//// directions.
////
//// ## Graph Types
////
//// - **Directed Graph**: Edges have a direction (one-way relationships)
//// - **Undirected Graph**: Edges are bidirectional (mutual relationships)
////
//// ## Type Parameters
////
//// - `node_data`: The type of data stored at each node (e.g., `String`, `City`, `Task`)
//// - `edge_data`: The type of data stored on edges, typically weights (e.g., `Int`, `Float`)
////
//// ## Quick Start
////
//// ```gleam
//// import yog/model
////
//// let assert Ok(graph) =
////   model.new(model.Undirected)
////   |> model.add_node(1, "Alice")
////   |> model.add_node(2, "Bob")
////   |> model.add_edge(from: 1, to: 2, with: 10)  // weight = 10
//// ```
////
//// ## Design Notes
////
//// The dual-map representation enables O(1) edge existence checks and O(1) transpose
//// operations, at the cost of increased memory usage and slightly more complex edge
//// updates.

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/set
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

/// A simple graph data structure that can be directed or undirected.
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
/// Returns `Error` if either endpoint node doesn't exist in `graph.nodes`.
/// Use `add_edge_ensure` to auto-create missing nodes with a default value,
/// or `add_node` to explicitly add nodes before adding edges.
///
/// ## Example
///
/// ```gleam
/// graph
/// |> model.add_node(1, "A")
/// |> model.add_node(2, "B")
/// |> model.add_edge(from: 1, to: 2, with: 10)
/// // => Ok(graph)
/// ```
///
/// ```gleam
/// graph
/// |> model.add_edge(from: 1, to: 2, with: 10)
/// // => Error("Node 1 does not exist")
/// ```
pub fn add_edge(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
) -> Result(Graph(n, e), String) {
  case dict.has_key(graph.nodes, src), dict.has_key(graph.nodes, dst) {
    True, True ->
      Ok(add_edge_unchecked(graph, from: src, to: dst, with: weight))
    False, False ->
      Error(
        "Nodes "
        <> int.to_string(src)
        <> " and "
        <> int.to_string(dst)
        <> " do not exist",
      )
    False, _ -> Error("Node " <> int.to_string(src) <> " does not exist")
    _, False -> Error("Node " <> int.to_string(dst) <> " does not exist")
  }
}

/// Adds an edge without checking if nodes exist (internal use).
///
/// For directed graphs, adds a single edge from `src` to `dst`.
/// For undirected graphs, adds edges in both directions.
///
/// > **Warning:** If `src` or `dst` have not been added via `add_node`,
/// > this creates "ghost nodes" that are traversable but invisible to
/// > functions that iterate over nodes (e.g. `order`, `filter_nodes`).
/// > Prefer using `add_edge` (checked) or `add_edge_ensure` (auto-creates).
fn add_edge_unchecked(
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

/// Ensures both endpoint nodes exist, then adds an edge.
///
/// If `src` or `dst` is not already in the graph, it is created with
/// the supplied `default` node data before the edge is added. Nodes
/// that already exist are left unchanged.
///
/// Always succeeds and returns a `Graph` (never fails).
///
/// ## Example
///
/// ```gleam
/// // Nodes 1 and 2 are created automatically with data "unknown"
/// model.new(model.Directed)
/// |> model.add_edge_ensure(from: 1, to: 2, with: 10, default: "unknown")
/// ```
///
/// ```gleam
/// // Existing nodes keep their data; only missing ones get the default
/// model.new(model.Directed)
/// |> model.add_node(1, "Alice")
/// |> model.add_edge_ensure(from: 1, to: 2, with: 5, default: "anon")
/// // Node 1 is still "Alice", node 2 is "anon"
/// ```
/// ## Future Improvements
///
/// A future version may support separate defaults for each endpoint
/// (`default_from` and `default_to`). If you need this feature, please
/// [open an issue](https://github.com/code-shoily/yog/issues).
///
/// For now, if you need different node values, then call `add_node` before
/// adding edges. Or call `add_edge_with()` with a callback function
/// that fetches the value of the NodeId (i.e. from a dict, database, or `identity`)
pub fn add_edge_ensure(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  default default: n,
) -> Graph(n, e) {
  let graph = ensure_node(graph, src, default)
  let graph = ensure_node(graph, dst, default)
  add_edge_unchecked(graph, from: src, to: dst, with: weight)
}

/// Ensures both endpoint nodes exist using a callback, then adds an edge.
///
/// If `src` or `dst` is not already in the graph, it is created by
/// calling the `by` function with the node ID to generate the node data.
/// Nodes that already exist are left unchanged.
///
/// Always succeeds and returns a `Graph` (never fails).
///
/// ## Example
///
/// ```gleam
/// // Nodes 1 and 2 are created automatically with value that's the same as NodeId
/// model.new(model.Directed)
/// |> model.add_edge_with(from: 1, to: 2, with: 10, by: fn(x) { x })
/// ```
///
/// ```gleam
/// // Existing nodes keep their data; only missing ones get the default
/// model.new(model.Directed)
/// |> model.add_node(1, "1")
/// |> model.add_edge_with(from: 1, to: 2, with: 5, by: fn(n) { int.to_string(n) <> ":new" })
/// // Node 1 is still "1", node 2 is "2:new"
/// ```
pub fn add_edge_with(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  by by: fn(NodeId) -> n,
) -> Graph(n, e) {
  let graph = ensure_node_with(graph, src, by:)
  let graph = ensure_node_with(graph, dst, by:)
  add_edge_unchecked(graph, from: src, to: dst, with: weight)
}

/// Adds multiple edges to the graph in a single operation.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Returns `Error` if any endpoint node doesn't exist.
///
/// This is more ergonomic than chaining multiple `add_edge` calls
/// as it only requires unwrapping a single `Result`.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edges([
///     #(1, 2, 10),
///     #(2, 3, 5),
///     #(1, 3, 15),
///   ])
/// ```
pub fn add_edges(
  graph: Graph(n, e),
  edges: List(#(NodeId, NodeId, e)),
) -> Result(Graph(n, e), String) {
  list.try_fold(edges, graph, fn(g, edge) {
    let #(src, dst, weight) = edge
    add_edge(g, from: src, to: dst, with: weight)
  })
}

/// Adds multiple simple edges (weight = 1) to the graph.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Convenient for unweighted graphs where all edges have weight 1.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_simple_edges([
///     #(1, 2),
///     #(2, 3),
///     #(1, 3),
///   ])
/// ```
pub fn add_simple_edges(
  graph: Graph(n, Int),
  edges: List(#(NodeId, NodeId)),
) -> Result(Graph(n, Int), String) {
  list.try_fold(edges, graph, fn(g, edge) {
    let #(src, dst) = edge
    add_edge(g, from: src, to: dst, with: 1)
  })
}

/// Adds multiple unweighted edges (weight = Nil) to the graph.
///
/// Fails fast on the first edge that references non-existent nodes.
/// Convenient for graphs where edges carry no weight information.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_unweighted_edges([
///     #(1, 2),
///     #(2, 3),
///     #(1, 3),
///   ])
/// ```
pub fn add_unweighted_edges(
  graph: Graph(n, Nil),
  edges: List(#(NodeId, NodeId)),
) -> Result(Graph(n, Nil), String) {
  list.try_fold(edges, graph, fn(g, edge) {
    let #(src, dst) = edge
    add_edge(g, from: src, to: dst, with: Nil)
  })
}

/// Adds a node only if it doesn't already exist.
fn ensure_node(graph: Graph(n, e), id: NodeId, data: n) -> Graph(n, e) {
  case dict.has_key(graph.nodes, id) {
    True -> graph
    False -> add_node(graph, id, data)
  }
}

/// Adds a node only if it doesn't already exist, using a function
/// to create the node data from the node ID.
fn ensure_node_with(
  graph: Graph(n, e),
  id: NodeId,
  by make: fn(NodeId) -> n,
) -> Graph(n, e) {
  case dict.has_key(graph.nodes, id) {
    True -> graph
    False -> add_node(graph, id, make(id))
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
/// Useful for algorithms like finding "connected connectivity."
pub fn neighbors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  case graph.kind {
    Undirected -> successors(graph, id)
    Directed -> {
      let outgoing = successors(graph, id)
      let incoming = predecessors(graph, id)
      let out_ids = set.from_list(list.map(outgoing, pair.first))

      use acc, #(in_id, _) as incoming <- list.fold(incoming, outgoing)
      case set.contains(out_ids, in_id) {
        True -> acc
        False -> [incoming, ..acc]
      }
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

/// Returns the number of nodes in the graph.
/// Equivalent to `order(graph)`.
///
/// **Time Complexity:** O(1)
pub fn node_count(graph: Graph(n, e)) -> Int {
  order(graph)
}

/// Returns the number of edges in the graph.
///
/// For undirected graphs, each edge is counted once (the pair {u, v}).
/// For directed graphs, each directed edge (u -> v) is counted once.
///
/// **Time Complexity:** O(V)
pub fn edge_count(graph: Graph(n, e)) -> Int {
  dict.fold(graph.out_edges, 0, fn(acc, _src, targets) {
    acc + dict.size(targets)
  })
  |> fn(count) {
    case graph.kind {
      Directed -> count
      Undirected -> count / 2
    }
  }
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
      Some(m) -> dict.insert(m, dst, weight)
      None -> dict.from_list([#(dst, weight)])
    }
  }

  let in_update_fn = fn(maybe_inner_map) {
    case maybe_inner_map {
      Some(m) -> dict.insert(m, src, weight)
      None -> dict.from_list([#(src, weight)])
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
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 10)
/// let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 20)
///
/// let graph = model.remove_node(graph, 2)
/// // Node 2 is removed, along with edges 1->2 and 2->3
/// ```
pub fn remove_node(graph: Graph(n, e), id: NodeId) -> Graph(n, e) {
  let targets = successors(graph, id)
  let sources = predecessors(graph, id)

  let new_nodes = dict.delete(graph.nodes, id)

  let new_out = dict.delete(graph.out_edges, id)
  let new_in_cleaned = {
    use acc_in, #(target_id, _) <- list.fold(targets, graph.in_edges)
    utils.dict_update_inner(acc_in, target_id, id, dict.delete)
  }

  let new_in = dict.delete(new_in_cleaned, id)
  let new_out_cleaned = {
    use acc_out, #(source_id, _) <- list.fold(sources, new_out)
    utils.dict_update_inner(acc_out, source_id, id, dict.delete)
  }

  Graph(..graph, nodes: new_nodes, out_edges: new_out_cleaned, in_edges: new_in)
}

/// Removes a directed edge from `src` to `dst`.
///
/// For **directed graphs**, this removes the single directed edge from `src` to `dst`.
/// For **undirected graphs**, this removes the edges in both directions
/// (from `src` to `dst` and from `dst` to `src`).
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// // Directed graph - removes single directed edge
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
/// let graph = model.remove_edge(graph, 1, 2)
/// // Edge 1->2 is removed
/// ```
///
/// ```gleam
/// // Undirected graph - removes both directions
/// let assert Ok(graph) =
///   model.new(Undirected)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
/// let graph = model.remove_edge(graph, 1, 2)
/// // Edge between 1 and 2 is fully removed
/// ```
pub fn remove_edge(
  graph: Graph(node_data, edge_data),
  src: NodeId,
  dst: NodeId,
) -> Graph(node_data, edge_data) {
  let graph = do_remove_directed_edge(graph, src, dst)

  case graph.kind {
    Directed -> graph
    Undirected -> do_remove_directed_edge(graph, dst, src)
  }
}

fn do_remove_directed_edge(
  graph: Graph(node_data, edge_data),
  src: NodeId,
  dst: NodeId,
) -> Graph(node_data, edge_data) {
  let new_out = case dict.get(graph.out_edges, src) {
    Ok(targets) -> dict.insert(graph.out_edges, src, dict.delete(targets, dst))
    Error(_) -> graph.out_edges
  }
  let new_in = case dict.get(graph.in_edges, dst) {
    Ok(sources) -> dict.insert(graph.in_edges, dst, dict.delete(sources, src))
    Error(_) -> graph.in_edges
  }
  Graph(..graph, out_edges: new_out, in_edges: new_in)
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
/// let assert Ok(graph) =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
/// let graph = model.add_edge_with_combine(graph, from: 1, to: 2, with: 5, using: int.add)
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
      Some(m) -> {
        let new_weight = case dict.get(m, dst) {
          Ok(existing) -> with_combine(existing, weight)
          Error(_) -> weight
        }
        dict.insert(m, dst, new_weight)
      }
      None -> dict.from_list([#(dst, weight)])
    }
  }

  let new_out = dict.upsert(graph.out_edges, src, update_fn)
  let new_in =
    dict.upsert(graph.in_edges, dst, fn(maybe_m) {
      case maybe_m {
        Some(m) -> {
          let new_weight = case dict.get(m, src) {
            Ok(existing) -> with_combine(existing, weight)
            Error(_) -> weight
          }
          dict.insert(m, src, new_weight)
        }
        None -> dict.from_list([#(src, weight)])
      }
    })

  Graph(..graph, out_edges: new_out, in_edges: new_in)
}
