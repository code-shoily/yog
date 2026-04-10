import gleam/int
import gleam/list
import gleam/option.{Some}
import gleeunit/should
import yog
import yog/builder/labeled
import yog/builder/live
import yog/internal/util
import yog/model
import yog/pathfinding/dijkstra

pub fn new_creates_empty_builder_test() {
  let builder = live.new()

  live.node_count(builder) |> should.equal(0)
  live.pending_count(builder) |> should.equal(0)
}

pub fn add_edge_creates_pending_transition_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)

  live.node_count(builder) |> should.equal(2)
  live.pending_count(builder) |> should.equal(3)
  // 2 AddNode + 1 AddEdge
}

pub fn ensure_node_is_idempotent_test() {
  // Adding same edge twice should not create duplicate nodes
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "A", 20)
  // Reverses labels

  live.node_count(builder) |> should.equal(2)
  // Still just A and B
  live.pending_count(builder) |> should.equal(4)
  // 2 AddNode + 2 AddEdge
}

pub fn get_id_returns_registered_ids_test() {
  let builder =
    live.new()
    |> live.add_edge("home", "work", 10)

  let assert Ok(home_id) = live.get_id(builder, "home")
  let assert Ok(work_id) = live.get_id(builder, "work")

  // IDs should be sequential starting from 0
  home_id |> should.equal(0)
  work_id |> should.equal(1)
}

pub fn get_id_returns_error_for_unknown_label_test() {
  let builder = live.new()

  live.get_id(builder, "unknown")
  |> should.be_error
}

pub fn sync_applies_pending_changes_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)

  let #(builder, graph) = live.sync(builder, yog.directed())

  // Pending should be cleared
  live.pending_count(builder) |> should.equal(0)

  // Graph should have the edge
  let assert Ok(a_id) = live.get_id(builder, "A")
  let successors = model.successors(graph, a_id)

  // Should have one successor (B) with weight 10
  list.length(successors) |> should.equal(1)
  let assert [#(_b_id, weight)] = successors
  weight |> should.equal(10)
}

pub fn sync_is_idempotent_when_no_pending_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)

  let #(_builder, graph) = live.sync(builder, yog.directed())
  let #(builder2, graph2) = live.sync(builder, graph)

  // Second sync should be a no-op
  live.pending_count(builder2) |> should.equal(0)

  // Graphs should be identical
  graph2 |> should.equal(graph)
}

pub fn incremental_sync_updates_existing_graph_test() {
  // Initial build
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)

  let #(builder, graph) = live.sync(builder, yog.directed())

  // Incremental update
  let builder = live.add_edge(builder, "B", "C", 5)
  let #(builder, graph) = live.sync(builder, graph)

  // All nodes should exist
  live.node_count(builder) |> should.equal(3)

  // Verify edges
  let assert Ok(a_id) = live.get_id(builder, "A")
  let assert Ok(b_id) = live.get_id(builder, "B")
  let assert Ok(c_id) = live.get_id(builder, "C")

  model.successors(graph, a_id) |> should.equal([#(b_id, 10)])
  model.successors(graph, b_id) |> should.equal([#(c_id, 5)])
  model.successors(graph, c_id) |> should.equal([])
}

pub fn checkpoint_discards_pending_changes_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.checkpoint()

  live.pending_count(builder) |> should.equal(0)
  live.node_count(builder) |> should.equal(2)
  // Registry preserved

  // Sync should produce empty graph
  let #(_builder, graph) = live.sync(builder, yog.directed())
  model.all_nodes(graph) |> should.equal([])
}

pub fn all_labels_returns_registered_labels_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "C", 20)

  let labels = live.all_labels(builder)

  list.length(labels) |> should.equal(3)
  list.contains(labels, "A") |> should.be_true
  list.contains(labels, "B") |> should.be_true
  list.contains(labels, "C") |> should.be_true
}

pub fn add_unweighted_edge_test() {
  let builder: live.LiveBuilder(String, Nil) =
    live.directed()
    |> live.add_unweighted_edge("A", "B")

  let #(builder, graph) = live.sync(builder, yog.directed())

  let assert Ok(a_id) = live.get_id(builder, "A")
  model.successors(graph, a_id)
  |> should.equal([#(1, Nil)])
}

pub fn add_simple_edge_test() {
  let builder =
    live.directed()
    |> live.add_simple_edge("A", "B")

  let #(builder, graph) = live.sync(builder, yog.directed())

  let assert Ok(a_id) = live.get_id(builder, "A")
  model.successors(graph, a_id)
  |> should.equal([#(1, 1)])
}

pub fn pathfinding_with_live_builder_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "C", 5)
    |> live.add_edge("A", "C", 20)

  let #(builder, graph) = live.sync(builder, yog.directed())

  let assert Ok(a_id) = live.get_id(builder, "A")
  let assert Ok(c_id) = live.get_id(builder, "C")

  // Shortest path should be A -> B -> C (cost 15)
  let path =
    dijkstra.shortest_path(
      in: graph,
      from: a_id,
      to: c_id,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let assert Some(_p) = path
  let Some(p) = path
  p.nodes |> should.equal([a_id, 1, c_id])
  // A -> B -> C
  p.total_weight |> should.equal(15)
}

pub fn undirected_graph_test() {
  let builder =
    live.undirected()
    |> live.add_edge("A", "B", 10)

  let #(builder, graph) = live.sync(builder, yog.undirected())

  let assert Ok(a_id) = live.get_id(builder, "A")
  let assert Ok(b_id) = live.get_id(builder, "B")

  // In undirected graph, edges go both ways
  model.successors(graph, a_id) |> should.equal([#(b_id, 10)])
  model.successors(graph, b_id) |> should.equal([#(a_id, 10)])
}

pub fn multiple_incremental_updates_test() {
  // Simulate streaming data
  let #(builder, graph) = {
    let b = live.new() |> live.add_edge("N1", "N2", 1)
    let #(b, g) = live.sync(b, yog.directed())

    let b = live.add_edge(b, "N2", "N3", 2)
    let #(b, g) = live.sync(b, g)

    let b = live.add_edge(b, "N3", "N4", 3)
    let #(b, g) = live.sync(b, g)

    let b = live.add_edge(b, "N1", "N4", 10)
    live.sync(b, g)
  }

  live.node_count(builder) |> should.equal(4)
  live.pending_count(builder) |> should.equal(0)

  // Verify the path
  let assert Ok(n1_id) = live.get_id(builder, "N1")
  let assert Ok(n4_id) = live.get_id(builder, "N4")

  let path =
    dijkstra.shortest_path(
      in: graph,
      from: n1_id,
      to: n4_id,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let assert Some(_p) = path
  // Should prefer 1+2+3 = 6 over direct 10
  let Some(p) = path
  p.total_weight |> should.equal(6)
}

pub fn from_labeled_migration_test() {
  // Start with static builder
  let static =
    labeled.directed()
    |> labeled.add_edge("A", "B", 10)

  let graph = labeled.to_graph(static)

  // Convert to live
  let live_builder = live.from_labeled(static)

  // Should have existing registry but no pending
  live.node_count(live_builder) |> should.equal(2)
  live.pending_count(live_builder) |> should.equal(0)

  // Can add new edges incrementally
  let live_builder = live.add_edge(live_builder, "B", "C", 5)
  let #(live_builder, _graph) = live.sync(live_builder, graph)

  live.node_count(live_builder) |> should.equal(3)

  // Verify IDs are preserved
  let assert Ok(a_id) = live.get_id(live_builder, "A")
  let assert Ok(b_id) = live.get_id(live_builder, "B")
  let assert Ok(c_id) = live.get_id(live_builder, "C")

  a_id |> should.equal(0)
  b_id |> should.equal(1)
  c_id |> should.equal(2)
}

pub fn remove_edge_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "C", 20)
    |> live.remove_edge("A", "B")

  // 3 AddNode (A, B, C) + 2 AddEdge + 1 RemoveEdge = 6 pending
  live.node_count(builder) |> should.equal(3)
  live.pending_count(builder) |> should.equal(6)

  // Sync and verify
  let #(builder, graph) = live.sync(builder, yog.directed())

  let assert Ok(a_id) = live.get_id(builder, "A")
  let assert Ok(b_id) = live.get_id(builder, "B")

  // A should have no successors (edge removed)
  model.successors(graph, a_id) |> should.equal([])

  // B should still have C
  model.successors(graph, b_id) |> list.length |> should.equal(1)
}

pub fn remove_edge_nonexistent_test() {
  // Removing an edge where nodes don't exist should be a no-op
  let builder =
    live.new()
    |> live.remove_edge("X", "Y")

  live.node_count(builder) |> should.equal(0)
  live.pending_count(builder) |> should.equal(0)
}

pub fn remove_node_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "C", 20)
    |> live.remove_node("B")

  // Registry should no longer have B (3 AddNode + 2 AddEdge + 1 RemoveNode = 6)
  live.node_count(builder) |> should.equal(2)
  // A and C remain
  live.pending_count(builder) |> should.equal(6)
  live.get_id(builder, "B") |> should.be_error

  // Sync and verify
  let #(builder, graph) = live.sync(builder, yog.directed())

  // A should have no successors (B was removed)
  let assert Ok(a_id) = live.get_id(builder, "A")
  model.successors(graph, a_id) |> should.equal([])
}

pub fn remove_node_nonexistent_test() {
  // Removing a non-existent node should be a no-op
  let builder =
    live.new()
    |> live.remove_node("Z")

  live.node_count(builder) |> should.equal(0)
  live.pending_count(builder) |> should.equal(0)
}

pub fn purge_pending_test() {
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)
    |> live.add_edge("B", "C", 20)

  // Should have pending changes
  live.pending_count(builder) |> should.equal(5)

  // Purge without syncing
  let builder = live.purge_pending(builder)

  // Pending cleared, but registry still has the nodes
  live.pending_count(builder) |> should.equal(0)
  live.node_count(builder) |> should.equal(3)

  // Sync should produce empty graph (no pending to apply)
  let #(_builder, graph) = live.sync(builder, yog.directed())
  model.all_nodes(graph) |> should.equal([])
}

pub fn pending_queue_growth_pattern_test() {
  // Simulate a streaming scenario where we sync periodically
  let initial = live.new()

  // Add 100 edges (chain: 1->2, 2->3, ..., 100->101)
  // int.range is inclusive of both ends, so we use 1 to 100 for 100 edges
  let numbers = util.range(1, 100)
  let builder =
    list.fold(numbers, initial, fn(b, i) {
      live.add_edge(
        b,
        "node_" <> int.to_string(i),
        "node_" <> int.to_string(i + 1),
        i,
      )
    })

  // 101 unique nodes + 100 edges = 201 pending transitions
  live.pending_count(builder) |> should.equal(201)

  // Sync to clear
  let #(builder, graph) = live.sync(builder, yog.directed())
  live.pending_count(builder) |> should.equal(0)

  // Add more and sync again
  let builder = live.add_edge(builder, "node_101", "node_102", 101)
  // 1 new node (102) + 1 edge = 2 pending
  live.pending_count(builder) |> should.equal(2)
  let #(builder, _graph) = live.sync(builder, graph)
  live.pending_count(builder) |> should.equal(0)
}

pub fn remove_and_readd_node_gets_new_id_test() {
  // When you remove a node and re-add it, it should get a new ID
  let builder =
    live.new()
    |> live.add_edge("A", "B", 10)

  let assert Ok(original_a_id) = live.get_id(builder, "A")
  original_a_id |> should.equal(0)

  // Remove A and re-add via new edge
  let builder = live.remove_node(builder, "A")
  let builder = live.add_edge(builder, "A", "C", 20)
  // Re-adds A, creates C

  // A should have a new ID (2, since B=1, C gets next which would be 2?)
  // Actually: A was 0, B was 1. Remove A (next_id still 2). Add A->C:
  // ensure_node("A") sees A not in registry, assigns next_id=2
  // ensure_node("C") sees C not in registry, assigns next_id=3
  let assert Ok(new_a_id) = live.get_id(builder, "A")
  new_a_id |> should.equal(2)
  // Not 0 anymore! Gets the next available ID
}
