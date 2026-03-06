import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import yog/model.{type Graph, type GraphType, type NodeId, Directed, Undirected}

/// Unique identifier for an edge in a multigraph.
/// Unlike node IDs, edge IDs are assigned automatically by `add_edge`.
pub type EdgeId =
  Int

/// A multigraph that can hold multiple (parallel) edges between the same pair
/// of nodes.  Both directed and undirected variants are supported.
///
/// - `node_data`: Data stored at each node
/// - `edge_data`: Data (weight) stored on each edge
///
/// The internal representation keeps three indices:
/// - `edges`:        EdgeId → #(from, to, data)   – canonical edge store
/// - `out_edge_ids`: NodeId → List(EdgeId)         – outgoing edges per node
/// - `in_edge_ids`:  NodeId → List(EdgeId)         – incoming edges per node
pub type MultiGraph(node_data, edge_data) {
  MultiGraph(
    kind: GraphType,
    nodes: Dict(NodeId, node_data),
    edges: Dict(EdgeId, #(NodeId, NodeId, edge_data)),
    out_edge_ids: Dict(NodeId, List(EdgeId)),
    in_edge_ids: Dict(NodeId, List(EdgeId)),
    next_edge_id: EdgeId,
  )
}

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

/// Creates a new, empty multigraph of the given type.
pub fn new(graph_type: GraphType) -> MultiGraph(n, e) {
  MultiGraph(
    kind: graph_type,
    nodes: dict.new(),
    edges: dict.new(),
    out_edge_ids: dict.new(),
    in_edge_ids: dict.new(),
    next_edge_id: 0,
  )
}

/// Creates a new, empty **directed** multigraph.
pub fn directed() -> MultiGraph(n, e) {
  new(Directed)
}

/// Creates a new, empty **undirected** multigraph.
pub fn undirected() -> MultiGraph(n, e) {
  new(Undirected)
}

// ---------------------------------------------------------------------------
// Nodes
// ---------------------------------------------------------------------------

/// Adds a node with the given ID and data.
/// If the node already exists its data is replaced (edges are unaffected).
pub fn add_node(
  graph: MultiGraph(n, e),
  id: NodeId,
  data: n,
) -> MultiGraph(n, e) {
  MultiGraph(..graph, nodes: dict.insert(graph.nodes, id, data))
}

/// Removes a node and **all** edges connected to it.
pub fn remove_node(graph: MultiGraph(n, e), id: NodeId) -> MultiGraph(n, e) {
  // Collect edge IDs to remove: all out- and in-edge IDs for this node
  let out_ids = dict.get(graph.out_edge_ids, id) |> result.unwrap([])
  let in_ids = dict.get(graph.in_edge_ids, id) |> result.unwrap([])
  let ids_to_remove = list.append(out_ids, in_ids) |> list.unique()

  list.fold(ids_to_remove, graph, fn(g, eid) { do_remove_edge(g, eid) })
  |> fn(g) {
    MultiGraph(
      ..g,
      nodes: dict.delete(g.nodes, id),
      out_edge_ids: dict.delete(g.out_edge_ids, id),
      in_edge_ids: dict.delete(g.in_edge_ids, id),
    )
  }
}

/// Returns all node IDs in the graph.
pub fn all_nodes(graph: MultiGraph(n, e)) -> List(NodeId) {
  dict.keys(graph.nodes)
}

/// Returns the number of nodes (graph order).
pub fn order(graph: MultiGraph(n, e)) -> Int {
  dict.size(graph.nodes)
}

// ---------------------------------------------------------------------------
// Edges
// ---------------------------------------------------------------------------

/// Adds an edge from `from` to `to` with the given data.
///
/// Returns `#(updated_graph, new_edge_id)` so the caller can reference
/// this specific edge later (e.g. for `remove_edge`).
///
/// For undirected graphs a **single** `EdgeId` is issued and the reverse
/// direction is indexed automatically — removing by ID removes both directions.
///
/// ## Example
/// ```gleam
/// let graph = multi.directed()
/// let #(graph, e1) = multi.add_edge(graph, from: 1, to: 2, with: "flight")
/// let #(graph, e2) = multi.add_edge(graph, from: 1, to: 2, with: "train")
/// // e1 != e2 — two independent parallel edges
/// ```
pub fn add_edge(
  graph: MultiGraph(n, e),
  from src: NodeId,
  to dst: NodeId,
  with data: e,
) -> #(MultiGraph(n, e), EdgeId) {
  let eid = graph.next_edge_id
  let new_edges = dict.insert(graph.edges, eid, #(src, dst, data))

  let new_out =
    dict.upsert(graph.out_edge_ids, src, fn(maybe) {
      case maybe {
        Some(ids) -> [eid, ..ids]
        None -> [eid]
      }
    })

  let new_in =
    dict.upsert(graph.in_edge_ids, dst, fn(maybe) {
      case maybe {
        Some(ids) -> [eid, ..ids]
        None -> [eid]
      }
    })

  // For undirected graphs also index the reverse direction under the same EdgeId
  let #(new_out2, new_in2) = case graph.kind {
    Directed -> #(new_out, new_in)
    Undirected -> {
      let rev_out =
        dict.upsert(new_out, dst, fn(maybe) {
          case maybe {
            Some(ids) -> [eid, ..ids]
            None -> [eid]
          }
        })
      let rev_in =
        dict.upsert(new_in, src, fn(maybe) {
          case maybe {
            Some(ids) -> [eid, ..ids]
            None -> [eid]
          }
        })
      #(rev_out, rev_in)
    }
  }

  let updated =
    MultiGraph(
      ..graph,
      edges: new_edges,
      out_edge_ids: new_out2,
      in_edge_ids: new_in2,
      next_edge_id: eid + 1,
    )

  #(updated, eid)
}

/// Removes a single edge by its `EdgeId`.
/// For undirected graphs both direction-index entries are removed.
pub fn remove_edge(graph: MultiGraph(n, e), edge_id: EdgeId) -> MultiGraph(n, e) {
  do_remove_edge(graph, edge_id)
}

/// Returns `True` if an edge with this ID exists in the graph.
pub fn has_edge(graph: MultiGraph(n, e), edge_id: EdgeId) -> Bool {
  dict.has_key(graph.edges, edge_id)
}

/// Returns all edge IDs in the graph.
pub fn all_edge_ids(graph: MultiGraph(n, e)) -> List(EdgeId) {
  dict.keys(graph.edges)
}

/// Returns the total number of edges (graph size).
/// For undirected graphs each physical edge is counted once.
pub fn size(graph: MultiGraph(n, e)) -> Int {
  dict.size(graph.edges)
}

/// Returns all parallel edges between `from` and `to` as
/// `List(#(EdgeId, edge_data))`.
pub fn edges_between(
  graph: MultiGraph(n, e),
  from src: NodeId,
  to dst: NodeId,
) -> List(#(EdgeId, e)) {
  dict.get(graph.out_edge_ids, src)
  |> result.unwrap([])
  |> list.filter_map(fn(eid) {
    case dict.get(graph.edges, eid) {
      Ok(#(_, d, data)) if d == dst -> Ok(#(eid, data))
      _ -> Error(Nil)
    }
  })
}

// ---------------------------------------------------------------------------
// Traversal helpers
// ---------------------------------------------------------------------------

/// Returns all outgoing edges from `id` as `List(#(NodeId, EdgeId, e))`.
pub fn successors(
  graph: MultiGraph(n, e),
  id: NodeId,
) -> List(#(NodeId, EdgeId, e)) {
  dict.get(graph.out_edge_ids, id)
  |> result.unwrap([])
  |> list.filter_map(fn(eid) {
    case dict.get(graph.edges, eid) {
      Ok(#(src, dst, data)) if src == id -> Ok(#(dst, eid, data))
      // For undirected: edge may be indexed "backwards"
      Ok(#(src, dst, data)) if dst == id ->
        case graph.kind {
          Undirected -> Ok(#(src, eid, data))
          Directed -> Error(Nil)
        }
      _ -> Error(Nil)
    }
  })
}

/// Returns all incoming edges to `id` as `List(#(NodeId, EdgeId, e))`.
pub fn predecessors(
  graph: MultiGraph(n, e),
  id: NodeId,
) -> List(#(NodeId, EdgeId, e)) {
  dict.get(graph.in_edge_ids, id)
  |> result.unwrap([])
  |> list.filter_map(fn(eid) {
    case dict.get(graph.edges, eid) {
      Ok(#(src, dst, data)) if dst == id -> Ok(#(src, eid, data))
      Ok(#(src, dst, data)) if src == id ->
        case graph.kind {
          Undirected -> Ok(#(dst, eid, data))
          Directed -> Error(Nil)
        }
      _ -> Error(Nil)
    }
  })
}

/// Returns the out-degree of a node (number of outgoing edges).
/// For undirected graphs this equals the total degree.
pub fn out_degree(graph: MultiGraph(n, e), id: NodeId) -> Int {
  list.length(successors(graph, id))
}

/// Returns the in-degree of a node (number of incoming edges).
pub fn in_degree(graph: MultiGraph(n, e), id: NodeId) -> Int {
  list.length(predecessors(graph, id))
}

// ---------------------------------------------------------------------------
// Conversion
// ---------------------------------------------------------------------------

/// Collapses the multigraph into a simple `yog/model.Graph` by combining
/// parallel edges with `combine_fn(existing, new)`.
///
/// ## Example
/// ```gleam
/// // Keep minimum weight among parallel edges
/// multi.to_simple_graph(mg, fn(a, b) { int.min(a, b) })
/// ```
pub fn to_simple_graph(
  graph: MultiGraph(n, e),
  combine_fn: fn(e, e) -> e,
) -> Graph(n, e) {
  // Start with a simple graph carrying over node data
  let base =
    dict.fold(graph.nodes, model.new(graph.kind), fn(g, id, data) {
      model.add_node(g, id, data)
    })

  dict.fold(graph.edges, base, fn(g, _eid, edge) {
    let #(src, dst, data) = edge
    model.add_edge_with_combine(
      g,
      from: src,
      to: dst,
      with: data,
      using: combine_fn,
    )
  })
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn do_remove_edge(graph: MultiGraph(n, e), eid: EdgeId) -> MultiGraph(n, e) {
  case dict.get(graph.edges, eid) {
    Error(_) -> graph
    Ok(#(src, dst, _)) -> {
      let new_edges = dict.delete(graph.edges, eid)

      let remove_id = fn(maybe_ids) {
        case maybe_ids {
          Some(ids) -> list.filter(ids, fn(id) { id != eid })
          None -> []
        }
      }

      let new_out = dict.upsert(graph.out_edge_ids, src, remove_id)
      let new_in = dict.upsert(graph.in_edge_ids, dst, remove_id)

      // For undirected, also remove from the reverse index
      let #(new_out2, new_in2) = case graph.kind {
        Directed -> #(new_out, new_in)
        Undirected -> {
          let rev_out = dict.upsert(new_out, dst, remove_id)
          let rev_in = dict.upsert(new_in, src, remove_id)
          #(rev_out, rev_in)
        }
      }

      MultiGraph(
        ..graph,
        edges: new_edges,
        out_edge_ids: new_out2,
        in_edge_ids: new_in2,
      )
    }
  }
}
