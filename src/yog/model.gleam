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
import yog/internal/util

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

// =============================================================================
// CREATE/UPDATE GRAPH
// =============================================================================

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

/// Creates a graph from a list of edges #(src, dst, weight).
///
/// ## Example
///
/// ```gleam
/// let graph = model.from_edges(Directed, [#(1, 2, 10), #(2, 3, 5)])
/// ```
pub fn from_edges(
  graph_type: GraphType,
  edges: List(#(NodeId, NodeId, e)),
) -> Graph(Nil, e) {
  use g, #(src, dst, weight) <- list.fold(edges, new(graph_type))
  add_edge_ensure(g, src, dst, weight, Nil)
}

/// Creates a graph from a list of unweighted edges #(src, dst).
///
/// ## Example
///
/// ```gleam
/// let graph = model.from_unweighted_edges(Directed, [#(1, 2), #(2, 3)])
/// ```
pub fn from_unweighted_edges(
  graph_type: GraphType,
  edges: List(#(NodeId, NodeId)),
) -> Graph(Nil, Nil) {
  use g, #(src, dst) <- list.fold(edges, new(graph_type))
  add_edge_ensure(g, src, dst, Nil, Nil)
}

/// Creates a graph from an adjacency list #(src, List(#(dst, weight))).
///
/// ## Example
///
/// ```gleam
/// let graph = model.from_adjacency_list(Directed, [#(1, [#(2, 10), #(3, 5)])])
/// ```
pub fn from_adjacency_list(
  graph_type: GraphType,
  adj_list: List(#(NodeId, List(#(NodeId, e)))),
) -> Graph(Nil, e) {
  use g0, #(src, edges) <- list.fold(adj_list, new(graph_type))
  let g1 = add_node(g0, src, Nil)
  use graph, #(dst, weight) <- list.fold(edges, g1)
  add_edge_ensure(graph, src, dst, weight, Nil)
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
///   |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])
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
    util.dict_update_inner(acc_in, target_id, id, dict.delete)
  }

  let new_in = dict.delete(new_in_cleaned, id)
  let new_out_cleaned = {
    use acc_out, #(source_id, _) <- list.fold(sources, new_out)
    util.dict_update_inner(acc_out, source_id, id, dict.delete)
  }

  Graph(..graph, nodes: new_nodes, out_edges: new_out_cleaned, in_edges: new_in)
}

// =============================================================================
// EDGES
// =============================================================================

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
pub fn add_edge_ensure(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  default default: n,
) -> Graph(n, e) {
  graph
  |> ensure_node(src, default)
  |> ensure_node(dst, default)
  |> add_edge_unchecked(src, dst, weight)
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
  graph
  |> ensure_node_with(src, by)
  |> ensure_node_with(dst, by)
  |> add_edge_unchecked(src, dst, weight)
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
  use g, #(src, dst, weight) <- list.try_fold(edges, graph)
  add_edge(g, from: src, to: dst, with: weight)
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
  do_add_edges_with(graph, edges, 1)
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
  do_add_edges_with(graph, edges, Nil)
}

/// Adds an edge, but if an edge already exists between `src` and `dst`,
/// it combines the new weight with the existing one using `with_combine`.
///
/// The combine function receives `(existing_weight, new_weight)` and should
/// return the combined weight.
///
/// Returns `Error` if either endpoint node doesn't exist in `graph.nodes`.
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
/// let assert Ok(graph) = model.add_edge_with_combine(graph, from: 1, to: 2, with: 5, using: int.add)
/// // Edge 1->2 now has weight 15 (10 + 5)
/// ```
pub fn add_edge_with_combine(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with weight: e,
  using with_combine: fn(e, e) -> e,
) -> Result(Graph(n, e), String) {
  case dict.has_key(graph.nodes, src), dict.has_key(graph.nodes, dst) {
    True, True -> {
      let graph = do_add_directed_combine(graph, src, dst, weight, with_combine)
      let result = case graph.kind {
        Directed -> graph
        Undirected ->
          do_add_directed_combine(graph, dst, src, weight, with_combine)
      }
      Ok(result)
    }
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

// =============================================================================
// BASIC QUERIES
// =============================================================================

/// Gets the type of the graph (Directed or Undirected).
pub fn kind(graph: Graph(n, e)) -> GraphType {
  graph.kind
}

/// Returns the number of nodes in the graph (graph order).
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// model.new(model.Directed)
/// |> model.add_node(1, "A")
/// |> model.add_node(2, "B")
/// |> model.order
/// // => 2
/// ```
pub fn order(graph: Graph(n, e)) -> Int {
  dict.size(graph.nodes)
}

/// Returns the number of nodes in the graph.
/// Equivalent to `order(graph)`.
///
/// **Time Complexity:** O(1)
///
/// ## Example
///
/// ```gleam
/// model.new(model.Directed)
/// |> model.add_node(1, "A")
/// |> model.add_node(2, "B")
/// |> model.node_count
/// // => 2
/// ```
pub fn node_count(graph: Graph(n, e)) -> Int {
  order(graph)
}

/// Returns the number of edges in the graph.
///
/// For undirected graphs, each edge is counted once (the pair {u, v}).
/// For directed graphs, each directed edge (u -> v) is counted once.
///
/// **Time Complexity:** O(V)
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(model.Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///
/// model.edge_count(graph)
/// // => 1
/// ```
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

/// Checks if the graph contains a node with the given ID.
///
/// **Time Complexity:** O(1)
pub fn has_node(graph: Graph(n, e), id: NodeId) -> Bool {
  dict.has_key(graph.nodes, id)
}

/// Checks if the graph contains an edge between `src` and `dst`.
///
/// **Time Complexity:** O(1)
pub fn has_edge(graph: Graph(n, e), from src: NodeId, to dst: NodeId) -> Bool {
  dict.get(graph.out_edges, src)
  |> result.map(dict.has_key(_, dst))
  |> result.unwrap(False)
}

// =============================================================================
// TOPOLOGY
// =============================================================================

/// Gets nodes you can travel TO (Successors).
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(model.Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///
/// model.successors(graph, 1)
/// // => [#(2, 10)]
/// ```
pub fn successors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  graph.out_edges
  |> dict.get(id)
  |> result.map(dict.to_list)
  |> result.unwrap([])
}

/// Gets nodes you came FROM (Predecessors).
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(model.Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///
/// model.predecessors(graph, 2)
/// // => [#(1, 10)]
/// ```
pub fn predecessors(graph: Graph(n, e), id: NodeId) -> List(#(NodeId, e)) {
  graph.in_edges
  |> dict.get(id)
  |> result.map(dict.to_list)
  |> result.unwrap([])
}

/// Gets everyone connected to the node, regardless of direction.
/// Useful for algorithms like finding "connected connectivity."
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(model.Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///   |> model.add_edge(from: 3, to: 1, with: 5)
///
/// model.neighbors(graph, 1)
/// // => [#(2, 10), #(3, 5)]
/// ```
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

/// Returns all successor node IDs (without weights).
/// Convenient for traversal algorithms that only need the IDs.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(graph) =
///   model.new(model.Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_edge(from: 1, to: 2, with: 10)
///
/// model.successor_ids(graph, 1)
/// // => [2]
/// ```
pub fn successor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  graph
  |> successors(id)
  |> list.map(fn(edge) { edge.0 })
}

/// Returns all predecessor node IDs (without weights).
pub fn predecessor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  graph
  |> predecessors(id)
  |> list.map(fn(edge) { edge.0 })
}

/// Returns all neighbor node IDs (without weights).
pub fn neighbor_ids(graph: Graph(n, e), id: NodeId) -> List(NodeId) {
  graph
  |> neighbors(id)
  |> list.map(fn(edge) { edge.0 })
}

/// Returns the out-degree of a node.
///
/// For undirected graphs, this returns the total degree.
///
/// **Time Complexity:** O(1)
pub fn out_degree(graph: Graph(n, e), id: NodeId) -> Int {
  graph.out_edges
  |> dict.get(id)
  |> result.map(dict.size)
  |> result.unwrap(0)
}

/// Returns the in-degree of a node.
///
/// For undirected graphs, this returns the total degree.
///
/// **Time Complexity:** O(1)
pub fn in_degree(graph: Graph(n, e), id: NodeId) -> Int {
  graph.in_edges
  |> dict.get(id)
  |> result.map(dict.size)
  |> result.unwrap(0)
}

/// Returns the total degree of a node.
///
/// For directed graphs, this is the sum of in-degree and out-degree.
/// For undirected graphs, self-loops count as 2.
///
/// **Time Complexity:** O(1)
pub fn degree(graph: Graph(n, e), id: NodeId) -> Int {
  case graph.kind {
    Undirected -> {
      case dict.get(graph.out_edges, id) {
        Ok(targets) -> {
          let base = dict.size(targets)
          case dict.has_key(targets, id) {
            True -> base + 1
            False -> base
          }
        }
        Error(_) -> 0
      }
    }
    Directed -> in_degree(graph, id) + out_degree(graph, id)
  }
}

// =============================================================================
// DATA ACCESS
// =============================================================================

/// Returns all node IDs in the graph.
/// This includes all nodes, even isolated nodes with no edges.
///
/// ## Example
///
/// ```gleam
/// model.new(model.Directed)
/// |> model.add_node(1, "A")
/// |> model.add_node(2, "B")
/// |> model.all_nodes
/// // => [1, 2]
/// ```
pub fn all_nodes(graph: Graph(n, e)) -> List(NodeId) {
  dict.keys(graph.nodes)
}

/// Returns all nodes data in the graph as a Dict.
pub fn nodes(graph: Graph(n, e)) -> Dict(NodeId, n) {
  graph.nodes
}

/// Gets the data associated with a node.
pub fn node(graph: Graph(n, e), id: NodeId) -> Result(n, Nil) {
  dict.get(graph.nodes, id)
}

/// Gets the weight/data of an edge between two nodes.
pub fn edge_data(
  graph: Graph(n, e),
  from src: NodeId,
  to dst: NodeId,
) -> Result(e, Nil) {
  graph.out_edges
  |> dict.get(src)
  |> result.try(dict.get(_, dst))
}

/// Returns all edges in the graph as triplets `#(from, to, weight)`.
///
/// For directed graphs, returns all edges.
/// For undirected graphs, returns each edge only once where `from <= to`.
pub fn all_edges(graph: Graph(n, e)) -> List(#(NodeId, NodeId, e)) {
  case graph.kind {
    Directed -> {
      use acc, from, dests <- dict.fold(graph.out_edges, [])
      use acc, to, weight <- dict.fold(dests, acc)
      [#(from, to, weight), ..acc]
    }
    Undirected -> {
      use acc, from, dests <- dict.fold(graph.out_edges, [])
      use acc, to, weight <- dict.fold(dests, acc)
      case from <= to {
        True -> [#(from, to, weight), ..acc]
        False -> acc
      }
    }
  }
}

// =============================================================================
// PRIVATE HELPERS
// =============================================================================

/// Adds an edge without checking if nodes exist (internal use).
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

fn do_add_edges_with(
  graph: Graph(n, e),
  edges: List(#(NodeId, NodeId)),
  weight: e,
) -> Result(Graph(n, e), String) {
  use g, #(src, dst) <- list.try_fold(edges, graph)
  add_edge(g, from: src, to: dst, with: weight)
}
