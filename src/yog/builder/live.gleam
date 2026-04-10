//// A live builder for incremental graph construction with label-to-ID registry.
////
//// Unlike the static `labeled` builder which follows a "Build-Freeze-Analyze" pattern,
//// `LiveBuilder` provides a **Transaction-style API** that tracks pending changes.
//// This allows efficient synchronization of an existing `Graph` with new labeled edges
//// in $O(\Delta E)$ time, where $\Delta E$ is the number of new edges since last sync.
////
//// ## Use Cases
////
//// - **REPL environments**: Incrementally build and analyze graphs
//// - **UI editors**: Add nodes/edges interactively without rebuilding
//// - **Streaming data**: Ingest new relationships as they arrive
//// - **Large graphs**: Avoid $O(E)$ rebuild for single-edge updates
////
//// ## Guarantees
////
//// - **ID Stability:** Once a label is mapped to a `NodeId`, that mapping is immutable
//// - **Idempotency:** Calling `sync` with no pending changes is effectively free
//// - **Opaque Integration:** Uses the same ID generation as static builders
////
//// ## Important: Managing the Pending Queue
////
//// The `LiveBuilder` queues changes in memory until `sync()` is called. In streaming
//// scenarios, if you add edges continuously without syncing, the pending queue will
//// grow unbounded and consume memory.
////
//// **Best Practice:** Sync periodically based on your workload:
////
//// ```gleam
//// // For high-frequency streaming (e.g., Kafka consumer)
//// // Sync every N messages or every T seconds
//// let #(builder, graph) = case live.pending_count(builder) > 1000 {
////   True -> live.sync(builder, graph)
////   False -> #(builder, graph)
//// }
////
//// // For batch processing
//// // Build up a batch, then sync once
//// let builder = list.fold(batch, builder, fn(b, edge) {
////   live.add_edge(b, edge.0, edge.1, edge.2)
//// })
//// let #(builder, graph) = live.sync(builder, graph)
//// ```
////
//// **Recovery:** If you need to discard pending changes without applying them,
//// use `purge_pending()` (abandon changes) or `checkpoint()` (keep registry).
////
//// ## Limitations
////
//// - **Memory:** Pending changes are stored in memory until synced
//// - **No Persistence:** The pending queue is lost if the process crashes
//// - **Single-threaded:** Not designed for concurrent updates from multiple actors
////
//// ## Example
////
//// ```gleam
//// import yog/builder/live
//// import yog/pathfinding/dijkstra as pathfinding
//// import gleam/int
////
//// // Initial setup - build base graph
//// let builder = live.new() |> live.add_edge("A", "B", 10)
//// let #(builder, graph) = live.sync(builder, yog.directed())
////
//// // Incremental update - add new edge efficiently
//// let builder = builder |> live.add_edge("B", "C", 5)
//// let #(builder, graph) = live.sync(builder, graph)  // O(1) for just this edge!
////
//// // Use with algorithms - get IDs from registry
//// let assert Ok(a_id) = live.get_id(builder, "A")
//// let assert Ok(c_id) = live.get_id(builder, "C")
//// let path = pathfinding.shortest_path(graph, a_id, c_id, ...)
//// ```

import gleam/dict.{type Dict}
import gleam/list

import yog/builder/labeled
import yog/model.{type Graph, type NodeId}

// =============================================================================
// Types
// =============================================================================

/// A pending transition to be applied during sync.
type Transition(n, e) {
  /// Add a node with the given ID and label.
  AddNode(id: NodeId, label: n)
  /// Add an edge between two node IDs with the given weight.
  AddEdge(from: NodeId, to: NodeId, weight: e)
  /// Remove an edge between two node IDs.
  RemoveEdge(from: NodeId, to: NodeId)
  /// Remove a node by its ID.
  RemoveNode(id: NodeId)
}

/// Opaque type for the live builder.
///
/// Tracks a registry of label-to-ID mappings and pending transitions
/// that haven't been applied to a graph yet.
pub opaque type LiveBuilder(n, e) {
  LiveBuilder(
    /// Maps labels to their assigned NodeIds.
    registry: Dict(n, NodeId),
    /// The next available integer ID for new nodes.
    next_id: NodeId,
    /// Pending transitions waiting to be applied.
    pending: List(Transition(n, e)),
  )
}

/// Creates a new empty live builder.
///
/// ## Example
///
/// ```gleam
/// let builder = live.new()
/// ```
pub fn new() -> LiveBuilder(n, e) {
  LiveBuilder(registry: dict.new(), next_id: 0, pending: [])
}

// =============================================================================
// Constructors
// =============================================================================

/// Creates a new live builder with a directed graph type in mind.
///
/// This is a convenience function - the builder itself doesn't store
/// the graph type, but it helps document intent.
///
/// ## Example
///
/// ```gleam
/// let builder = live.directed()
/// ```
pub fn directed() -> LiveBuilder(n, e) {
  new()
}

/// Creates a new live builder with an undirected graph type in mind.
///
/// This is a convenience function - the builder itself doesn't store
/// the graph type, but it helps document intent.
///
/// ## Example
///
/// ```gleam
/// let builder = live.undirected()
/// ```
pub fn undirected() -> LiveBuilder(n, e) {
  new()
}

// =============================================================================
// Node & Edge Operations
// =============================================================================

/// Gets or creates a node ID for the given label.
///
/// If the label already exists in the registry, returns its existing ID.
/// If not, assigns a new ID and queues an `AddNode` transition.
///
/// > **Note:** This function is idempotent - calling it multiple times with the
/// > same label always returns the same ID without adding duplicate transitions.
///
/// ## Complexity
///
/// - $O(\log N)$ for dict lookup/insert where N is number of registered labels
fn ensure_node(
  builder: LiveBuilder(n, e),
  label: n,
) -> #(LiveBuilder(n, e), NodeId) {
  case dict.get(builder.registry, label) {
    Ok(id) -> #(builder, id)
    Error(_) -> {
      let id = builder.next_id
      let new_registry = dict.insert(builder.registry, label, id)
      let transition = AddNode(id: id, label: label)
      let new_pending = [transition, ..builder.pending]
      #(
        LiveBuilder(
          registry: new_registry,
          next_id: id + 1,
          pending: new_pending,
        ),
        id,
      )
    }
  }
}

/// Adds an edge between two labeled nodes.
///
/// If either label doesn't exist in the registry, new nodes are created.
/// The edge is queued as a pending transition and will be applied on next `sync`.
///
/// ## Example
///
/// ```gleam
/// let builder =
///   live.new()
///   |> live.add_edge("home", "work", 10)
///   |> live.add_edge("work", "gym", 5)
/// ```
///
/// ## Complexity
///
/// - $O(\log N)$ per label lookup/insert
pub fn add_edge(
  builder: LiveBuilder(n, e),
  from src_label: n,
  to dst_label: n,
  with weight: e,
) -> LiveBuilder(n, e) {
  let #(builder, src_id) = ensure_node(builder, src_label)
  let #(builder, dst_id) = ensure_node(builder, dst_label)

  let transition = AddEdge(from: src_id, to: dst_id, weight: weight)
  LiveBuilder(..builder, pending: [transition, ..builder.pending])
}

/// Adds an unweighted edge between two labeled nodes.
///
/// This is a convenience function for graphs where edges have no meaningful weight.
/// Uses `Nil` as the edge data type.
///
/// ## Example
///
/// ```gleam
/// let builder: live.LiveBuilder(String, Nil) =
///   live.directed()
///   |> live.add_unweighted_edge("A", "B")
/// ```
pub fn add_unweighted_edge(
  builder: LiveBuilder(n, Nil),
  from src_label: n,
  to dst_label: n,
) -> LiveBuilder(n, Nil) {
  add_edge(builder, from: src_label, to: dst_label, with: Nil)
}

/// Adds a simple edge with weight 1 between two labeled nodes.
///
/// This is a convenience function for graphs with integer weights where
/// a default weight of 1 is appropriate (e.g., unweighted graphs, hop counts).
///
/// ## Example
///
/// ```gleam
/// let builder =
///   live.directed()
///   |> live.add_simple_edge("A", "B")
///   |> live.add_simple_edge("B", "C")
/// ```
pub fn add_simple_edge(
  builder: LiveBuilder(n, Int),
  from src_label: n,
  to dst_label: n,
) -> LiveBuilder(n, Int) {
  add_edge(builder, from: src_label, to: dst_label, with: 1)
}

/// Removes an edge between two labeled nodes.
///
/// If either label doesn't exist, no transition is queued.
/// The removal is queued as a pending transition.
///
/// ## Example
///
/// ```gleam
/// let builder =
///   builder
///   |> live.remove_edge("A", "B")
/// ```
///
/// ## Complexity
///
/// - $O(\log N)$ per label lookup
pub fn remove_edge(
  builder: LiveBuilder(n, e),
  from src_label: n,
  to dst_label: n,
) -> LiveBuilder(n, e) {
  case
    dict.get(builder.registry, src_label),
    dict.get(builder.registry, dst_label)
  {
    Ok(src_id), Ok(dst_id) -> {
      let transition = RemoveEdge(from: src_id, to: dst_id)
      LiveBuilder(..builder, pending: [transition, ..builder.pending])
    }
    _, _ -> builder
    // One or both nodes don't exist, nothing to remove
  }
}

/// Removes a node by its label.
///
/// The node and all its connected edges are removed. The ID is NOT reused.
/// The label is removed from the registry so a future add would get a new ID.
///
/// > **Warning:** Removing a node invalidates any cached IDs for that label.
/// > After sync, `get_id(builder, label)` will return `Error(Nil)`.
///
/// ## Example
///
/// ```gleam
/// let builder =
///   builder
///   |> live.remove_node("obsolete_node")
/// ```
///
/// ## Complexity
///
/// - $O(\log N)$ for dict lookup/removal
pub fn remove_node(builder: LiveBuilder(n, e), label: n) -> LiveBuilder(n, e) {
  case dict.get(builder.registry, label) {
    Ok(id) -> {
      let new_registry = dict.delete(builder.registry, label)
      let transition = RemoveNode(id: id)
      LiveBuilder(..builder, registry: new_registry, pending: [
        transition,
        ..builder.pending
      ])
    }
    Error(_) -> builder
  }
}

// =============================================================================
// Sync & Transactions
// =============================================================================

/// Synchronizes pending changes to the given graph.
///
/// Applies all pending transitions (in order) to the provided graph,
/// then returns a new builder with an empty pending list and the updated graph.
///
/// > **Note:** If there are no pending changes, this returns immediately
/// > with the same builder and graph (effectively O(1)).
///
/// > **Warning:** The graph type (directed/undirected) is determined by the
/// > input graph. Make sure to provide a graph of the correct type on first sync.
///
/// > **Performance:** For large pending queues (>1000 items), consider syncing
/// > more frequently to avoid memory pressure and reduce sync latency.
///
/// ## Example
///
/// ```gleam
/// // Initial build
/// let builder = live.new() |> live.add_edge("A", "B", 10)
/// let #(builder, graph) = live.sync(builder, yog.directed())
///
/// // Incremental update
/// let builder = builder |> live.add_edge("B", "C", 5)
/// let #(builder, graph) = live.sync(builder, graph)  // Only applies B->C!
/// ```
///
/// ## Complexity
///
/// - $O(\Delta E)$ where $\Delta E$ is the number of pending transitions
pub fn sync(
  builder: LiveBuilder(n, e),
  graph: Graph(n, e),
) -> #(LiveBuilder(n, e), Graph(n, e)) {
  case builder.pending {
    [] -> #(builder, graph)
    pending -> {
      let transitions = list.reverse(pending)
      let new_graph = apply_transitions(graph, transitions)
      #(LiveBuilder(..builder, pending: []), new_graph)
    }
  }
}

fn apply_transitions(
  graph: Graph(n, e),
  transitions: List(Transition(n, e)),
) -> Graph(n, e) {
  use g, transition <- list.fold(transitions, graph)
  case transition {
    AddNode(id: id, label: label) -> model.add_node(g, id, label)
    AddEdge(from: src, to: dst, weight: weight) -> {
      let assert Ok(g) = model.add_edge(g, from: src, to: dst, with: weight)
      g
    }
    RemoveEdge(from: src, to: dst) -> model.remove_edge(g, src, dst)
    RemoveNode(id: id) -> model.remove_node(g, id)
  }
}

/// Discards all pending transitions without applying them.
///
/// This is a "hard reset" that abandons all queued changes. The registry
/// (label→ID mappings) is preserved. Use this when you detect an error
/// in your batch and want to start fresh.
///
/// > **Compare:** `checkpoint()` also clears pending but is intended for
/// > marking progress. `purge_pending()` is for abandoning work.
///
/// ## Example
///
/// ```gleam
/// // Queue some changes
/// let builder = live.add_edge(builder, "A", "B", 10)
///
/// // Oops, wrong data! Purge and start over.
/// let builder = live.purge_pending(builder)
/// // builder has no pending changes, registry still has A and B
/// ```
pub fn purge_pending(builder: LiveBuilder(n, e)) -> LiveBuilder(n, e) {
  LiveBuilder(..builder, pending: [])
}

/// Marks a checkpoint by discarding pending transitions.
///
/// This is useful when you want to "commit" progress and discard the
/// pending queue without applying it to a graph. The registry is preserved.
///
/// > **Compare:** `purge_pending()` has the same effect but different intent.
/// > Use `checkpoint()` for progress tracking, `purge_pending()` for error recovery.
///
/// ## Example
///
/// ```gleam
/// let builder =
///   live.new()
///   |> live.add_edge("A", "B", 10)
///   |> live.checkpoint()  // Discard the pending edge
///
/// // builder now has no pending changes
/// let #(builder, graph) = live.sync(builder, yog.directed())
/// // graph is empty - the edge was discarded
/// ```
pub fn checkpoint(builder: LiveBuilder(n, e)) -> LiveBuilder(n, e) {
  LiveBuilder(..builder, pending: [])
}

// =============================================================================
// Queries
// =============================================================================

/// Looks up the node ID for a given label.
///
/// Returns `Ok(id)` if the label has been registered, `Error(Nil)` if not.
/// Use this to get node IDs for use with graph algorithms.
///
/// > **Note:** After `remove_node`, this will return `Error(Nil)` for that label.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(home_id) = live.get_id(builder, "home")
/// let path = dijkstra.shortest_path(graph, home_id, ...)
/// ```
///
/// ## Complexity
///
/// - $O(\log N)$ for dict lookup
pub fn get_id(builder: LiveBuilder(n, e), label: n) -> Result(NodeId, Nil) {
  dict.get(builder.registry, label)
}

/// Returns all labels that have been registered.
///
/// ## Example
///
/// ```gleam
/// let labels = live.all_labels(builder)
/// // ["A", "B", "C"]
/// ```
pub fn all_labels(builder: LiveBuilder(n, e)) -> List(n) {
  dict.keys(builder.registry)
}

/// Returns the number of registered labels (nodes).
///
/// ## Example
///
/// ```gleam
/// live.node_count(builder)  // 5
/// ```
pub fn node_count(builder: LiveBuilder(n, e)) -> Int {
  dict.size(builder.registry)
}

/// Returns the number of pending transitions.
///
/// Useful for debugging or deciding whether to sync based on batch size.
///
/// ## Example
///
/// ```gleam
/// // Sync every 1000 changes to avoid unbounded growth
/// case live.pending_count(builder) > 1000 {
///   True -> live.sync(builder, graph)
///   False -> #(builder, graph)
/// }
/// ```
pub fn pending_count(builder: LiveBuilder(n, e)) -> Int {
  list.length(builder.pending)
}

/// Creates a live builder from an existing labeled builder.
///
/// This allows migration from static to incremental building.
/// The pending list starts empty - call `sync` separately to apply changes.
///
/// > **Note:** This uses the labeled builder's exported registry. The label→ID
/// > mappings are preserved exactly.
///
/// ## Example
///
/// ```gleam
/// import yog/builder/labeled
///
/// // Start with static builder
/// let static = labeled.directed() |> labeled.add_edge("A", "B", 10)
/// let graph = labeled.to_graph(static)
///
/// // Convert to live for incremental updates
/// let live_builder = live.from_labeled(static)
/// let live_builder = live.add_edge(live_builder, "B", "C", 5)
/// let #(live_builder, graph) = live.sync(live_builder, graph)
/// ```
pub fn from_labeled(labeled_builder: labeled.Builder(n, e)) -> LiveBuilder(n, e) {
  // Extract the registry from the labeled builder using its public API
  let registry = labeled.to_registry(labeled_builder)
  let next_id = labeled.next_id(labeled_builder)

  LiveBuilder(registry: registry, next_id: next_id, pending: [])
}
