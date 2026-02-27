import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/model.{Directed, Undirected}

// Test creating a new directed graph
pub fn new_directed_graph_test() {
  let graph = model.new(Directed)

  graph.kind
  |> should.equal(Directed)

  graph.nodes
  |> dict.size()
  |> should.equal(0)

  graph.out_edges
  |> dict.size()
  |> should.equal(0)

  graph.in_edges
  |> dict.size()
  |> should.equal(0)
}

// Test creating a new undirected graph
pub fn new_undirected_graph_test() {
  let graph = model.new(Undirected)

  graph.kind
  |> should.equal(Undirected)
}

// Test adding a single node
pub fn add_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")

  graph.nodes
  |> dict.size()
  |> should.equal(1)

  graph.nodes
  |> dict.get(1)
  |> should.equal(Ok("Node A"))
}

// Test adding multiple nodes
pub fn add_multiple_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")

  graph.nodes
  |> dict.size()
  |> should.equal(3)

  graph.nodes
  |> dict.get(2)
  |> should.equal(Ok("Node B"))
}

// Test updating a node (adding with same ID replaces)
pub fn update_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Original")
    |> model.add_node(1, "Updated")

  graph.nodes
  |> dict.size()
  |> should.equal(1)

  graph.nodes
  |> dict.get(1)
  |> should.equal(Ok("Updated"))
}

// Test adding a directed edge
pub fn add_directed_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  // Check out_edges
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 10)])))

  // Check in_edges
  graph.in_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(1, 10)])))

  // Node 2 should have no outgoing edges
  graph.out_edges
  |> dict.get(2)
  |> should.equal(Error(Nil))

  // Node 1 should have no incoming edges
  graph.in_edges
  |> dict.get(1)
  |> should.equal(Error(Nil))
}

// Test adding multiple directed edges from one node
pub fn add_multiple_outgoing_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)

  // Node 1 should have two outgoing edges
  let out_edges =
    graph.out_edges
    |> dict.get(1)
    |> should.be_ok()

  out_edges
  |> dict.size()
  |> should.equal(2)

  out_edges
  |> dict.get(2)
  |> should.equal(Ok(10))

  out_edges
  |> dict.get(3)
  |> should.equal(Ok(20))
}

// Test adding multiple directed edges to one node
pub fn add_multiple_incoming_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 3, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)

  // Node 3 should have two incoming edges
  let in_edges =
    graph.in_edges
    |> dict.get(3)
    |> should.be_ok()

  in_edges
  |> dict.size()
  |> should.equal(2)

  in_edges
  |> dict.get(1)
  |> should.equal(Ok(10))

  in_edges
  |> dict.get(2)
  |> should.equal(Ok(20))
}

// Test undirected edge creates bidirectional edges
pub fn add_undirected_edge_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 15)

  // Both nodes should have outgoing edges to each other
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 15)])))

  graph.out_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(1, 15)])))

  // Both nodes should have incoming edges from each other
  graph.in_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 15)])))

  graph.in_edges
  |> dict.get(2)
  |> should.equal(Ok(dict.from_list([#(1, 15)])))
}

// Test updating an edge (adding same edge replaces weight)
pub fn update_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 2, with: 25)

  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(2, 25)])))
}

// Test graph with different data types - String edge weights
pub fn graph_with_string_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, 100)
    |> model.add_node(2, 200)
    |> model.add_edge(from: 1, to: 2, with: "labeled_edge")

  graph.nodes
  |> dict.get(1)
  |> should.equal(Ok(100))

  let edges =
    graph.out_edges
    |> dict.get(1)
    |> should.be_ok()

  edges
  |> dict.get(2)
  |> should.equal(Ok("labeled_edge"))
}

// Test complex directed graph
pub fn complex_directed_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1.0)
    |> model.add_edge(from: 1, to: 3, with: 2.0)
    |> model.add_edge(from: 2, to: 3, with: 1.5)
    |> model.add_edge(from: 3, to: 4, with: 3.0)
    |> model.add_edge(from: 2, to: 4, with: 2.5)

  graph.nodes
  |> dict.size()
  |> should.equal(4)

  // Verify node 1 has 2 outgoing edges
  graph.out_edges
  |> dict.get(1)
  |> should.be_ok()
  |> dict.size()
  |> should.equal(2)

  // Verify node 4 has 2 incoming edges
  graph.in_edges
  |> dict.get(4)
  |> should.be_ok()
  |> dict.size()
  |> should.equal(2)

  // Verify node 3 has 1 incoming and 1 outgoing
  graph.out_edges
  |> dict.get(3)
  |> should.be_ok()
  |> dict.size()
  |> should.equal(1)

  graph.in_edges
  |> dict.get(3)
  |> should.be_ok()
  |> dict.size()
  |> should.equal(2)
}

// Test self-loop
pub fn self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_edge(from: 1, to: 1, with: 5)

  // Node should have edge to itself in both out and in
  graph.out_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(1, 5)])))

  graph.in_edges
  |> dict.get(1)
  |> should.equal(Ok(dict.from_list([#(1, 5)])))
}

// ============= Tests for successors() =============

// Test successors with no outgoing edges
pub fn successors_empty_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")

  model.successors(graph, 1)
  |> should.equal([])
}

// Test successors for nonexistent node
pub fn successors_nonexistent_node_test() {
  let graph = model.new(Directed)

  model.successors(graph, 99)
  |> should.equal([])
}

// Test successors with single outgoing edge
pub fn successors_single_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = model.successors(graph, 1)

  result
  |> should.equal([#(2, 10)])
}

// Test successors with multiple outgoing edges
pub fn successors_multiple_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_node(4, "Node D")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)
    |> model.add_edge(from: 1, to: 4, with: 30)

  let result = model.successors(graph, 1)

  // Check that we have 3 successors
  list.length(result)
  |> should.equal(3)

  // Verify all expected edges are present
  list.contains(result, #(2, 10))
  |> should.be_true()

  list.contains(result, #(3, 20))
  |> should.be_true()

  list.contains(result, #(4, 30))
  |> should.be_true()
}

// ============= Tests for predecessors() =============

// Test predecessors with no incoming edges
pub fn predecessors_empty_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")

  model.predecessors(graph, 1)
  |> should.equal([])
}

// Test predecessors for nonexistent node
pub fn predecessors_nonexistent_node_test() {
  let graph = model.new(Directed)

  model.predecessors(graph, 99)
  |> should.equal([])
}

// Test predecessors with single incoming edge
pub fn predecessors_single_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = model.predecessors(graph, 2)

  result
  |> should.equal([#(1, 10)])
}

// Test predecessors with multiple incoming edges
pub fn predecessors_multiple_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_node(4, "Node D")
    |> model.add_edge(from: 1, to: 4, with: 10)
    |> model.add_edge(from: 2, to: 4, with: 20)
    |> model.add_edge(from: 3, to: 4, with: 30)

  let result = model.predecessors(graph, 4)

  list.length(result)
  |> should.equal(3)

  list.contains(result, #(1, 10))
  |> should.be_true()

  list.contains(result, #(2, 20))
  |> should.be_true()

  list.contains(result, #(3, 30))
  |> should.be_true()
}

// ============= Tests for neighbors() =============

// Test neighbors on undirected graph (should equal successors)
pub fn neighbors_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)

  let neighbors = model.neighbors(graph, 1)
  let successors = model.successors(graph, 1)

  // In undirected graphs, neighbors should equal successors
  neighbors
  |> should.equal(successors)

  list.length(neighbors)
  |> should.equal(2)
}

// Test neighbors on directed graph with only outgoing edges
pub fn neighbors_directed_outgoing_only_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)

  let neighbors = model.neighbors(graph, 1)

  list.length(neighbors)
  |> should.equal(2)

  list.contains(neighbors, #(2, 10))
  |> should.be_true()

  list.contains(neighbors, #(3, 20))
  |> should.be_true()
}

// Test neighbors on directed graph with only incoming edges
pub fn neighbors_directed_incoming_only_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 2, to: 1, with: 10)
    |> model.add_edge(from: 3, to: 1, with: 20)

  let neighbors = model.neighbors(graph, 1)

  list.length(neighbors)
  |> should.equal(2)

  list.contains(neighbors, #(2, 10))
  |> should.be_true()

  list.contains(neighbors, #(3, 20))
  |> should.be_true()
}

// Test neighbors on directed graph with both incoming and outgoing edges
pub fn neighbors_directed_both_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_node(4, "Node D")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)
    |> model.add_edge(from: 4, to: 1, with: 30)

  let neighbors = model.neighbors(graph, 1)

  list.length(neighbors)
  |> should.equal(3)

  list.contains(neighbors, #(2, 10))
  |> should.be_true()

  list.contains(neighbors, #(3, 20))
  |> should.be_true()

  list.contains(neighbors, #(4, 30))
  |> should.be_true()
}

// Test neighbors with bidirectional edges (should deduplicate)
pub fn neighbors_directed_bidirectional_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 1, with: 20)

  let neighbors = model.neighbors(graph, 1)

  // Should only include node 2 once, even though there are edges in both directions
  list.length(neighbors)
  |> should.equal(1)

  list.contains(neighbors, #(2, 10))
  |> should.be_true()
}

// Test neighbors with no connections
pub fn neighbors_empty_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")

  model.neighbors(graph, 1)
  |> should.equal([])
}

// ============= Tests for all_nodes() =============

// Test all_nodes on empty graph
pub fn all_nodes_empty_test() {
  let graph = model.new(Directed)

  model.all_nodes(graph)
  |> should.equal([])
}

// Test all_nodes on graph with only nodes (no edges)
pub fn all_nodes_no_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")

  // all_nodes returns ALL nodes, including isolated nodes with no edges
  let result = model.all_nodes(graph)
  list.length(result) |> should.equal(3)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
}

// Test all_nodes on directed graph with edges
pub fn all_nodes_directed_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_node(4, "Node D")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)

  let result = model.all_nodes(graph)

  // Should include ALL nodes, including isolated node 4
  list.length(result)
  |> should.equal(4)

  list.contains(result, 1)
  |> should.be_true()

  list.contains(result, 2)
  |> should.be_true()

  list.contains(result, 3)
  |> should.be_true()

  // Node 4 has no edges, but should still be included
  list.contains(result, 4)
  |> should.be_true()
}

// Test all_nodes on undirected graph
pub fn all_nodes_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = model.all_nodes(graph)

  // Should include ALL nodes, including isolated node 3
  list.length(result)
  |> should.equal(3)

  list.contains(result, 1)
  |> should.be_true()

  list.contains(result, 2)
  |> should.be_true()

  list.contains(result, 3)
  |> should.be_true()
}

// Test all_nodes with self-loop
pub fn all_nodes_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_edge(from: 1, to: 1, with: 5)

  let result = model.all_nodes(graph)

  result
  |> should.equal([1])
}

// Test all_nodes returns unique values (no duplicates)
pub fn all_nodes_unique_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 1, with: 20)

  let result = model.all_nodes(graph)

  // Should have exactly 2 nodes, not 4
  list.length(result)
  |> should.equal(2)

  list.contains(result, 1)
  |> should.be_true()

  list.contains(result, 2)
  |> should.be_true()
}

// ============= Tests for successor_ids() =============

// Test successor_ids with no successors
pub fn successor_ids_empty_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")

  model.successor_ids(graph, 1)
  |> should.equal([])
}

// Test successor_ids for nonexistent node
pub fn successor_ids_nonexistent_node_test() {
  let graph = model.new(Directed)

  model.successor_ids(graph, 99)
  |> should.equal([])
}

// Test successor_ids with single successor
pub fn successor_ids_single_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  model.successor_ids(graph, 1)
  |> should.equal([2])
}

// Test successor_ids with multiple successors
pub fn successor_ids_multiple_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_node(4, "Node D")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)
    |> model.add_edge(from: 1, to: 4, with: 30)

  let result = model.successor_ids(graph, 1)

  // Should return just the IDs, without weights
  list.length(result)
  |> should.equal(3)

  list.contains(result, 2)
  |> should.be_true()

  list.contains(result, 3)
  |> should.be_true()

  list.contains(result, 4)
  |> should.be_true()
}

// Test successor_ids with self-loop
pub fn successor_ids_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_edge(from: 1, to: 1, with: 5)

  model.successor_ids(graph, 1)
  |> should.equal([1])
}

// Test successor_ids is equivalent to successors without weights
pub fn successor_ids_consistency_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")
    |> model.add_edge(from: 1, to: 2, with: 100)
    |> model.add_edge(from: 1, to: 3, with: 200)

  let successor_ids = model.successor_ids(graph, 1)
  let successors =
    model.successors(graph, 1)
    |> list.map(fn(edge) { edge.0 })

  // successor_ids should match successors with weights stripped
  successor_ids
  |> should.equal(successors)
}

// ============= Remove Node Tests =============

pub fn remove_node_basic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let graph = model.remove_node(graph, 2)

  dict.size(graph.nodes)
  |> should.equal(2)

  dict.get(graph.nodes, 2)
  |> should.equal(Error(Nil))

  dict.get(graph.nodes, 1)
  |> should.equal(Ok("A"))
}

pub fn remove_node_with_outgoing_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)

  let graph = model.remove_node(graph, 2)

  // Edge 1->2 should be removed
  model.successors(graph, 1)
  |> should.equal([])

  // Edge 2->3 should be removed
  model.predecessors(graph, 3)
  |> should.equal([])
}

pub fn remove_node_with_incoming_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 3, to: 2, with: 30)

  let graph = model.remove_node(graph, 2)

  // Both edges to 2 should be removed
  model.successors(graph, 1)
  |> should.equal([])

  model.successors(graph, 3)
  |> should.equal([])
}

pub fn remove_node_with_both_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)

  let graph = model.remove_node(graph, 2)

  // Both incoming and outgoing edges removed
  dict.size(graph.nodes)
  |> should.equal(2)

  model.successors(graph, 1)
  |> should.equal([])

  model.predecessors(graph, 3)
  |> should.equal([])
}

pub fn remove_node_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)

  let graph = model.remove_node(graph, 2)

  // Both undirected edges removed
  model.neighbors(graph, 1)
  |> should.equal([])

  model.neighbors(graph, 3)
  |> should.equal([])
}

pub fn remove_node_isolated_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 3, with: 10)

  let graph = model.remove_node(graph, 2)

  dict.size(graph.nodes)
  |> should.equal(2)

  // Edge 1->3 should still exist
  model.successors(graph, 1)
  |> should.equal([#(3, 10)])
}

pub fn remove_node_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 2, to: 2, with: 10)

  let graph = model.remove_node(graph, 2)

  dict.size(graph.nodes)
  |> should.equal(1)

  dict.get(graph.nodes, 2)
  |> should.equal(Error(Nil))
}

// ============= Add Edge With Combine Tests =============

pub fn add_edge_with_combine_new_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge_with_combine(from: 1, to: 2, with: 10, using: int.add)

  model.successors(graph, 1)
  |> should.equal([#(2, 10)])
}

pub fn add_edge_with_combine_existing_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 5, using: int.add)

  model.successors(graph, 1)
  |> should.equal([#(2, 15)])
}

pub fn add_edge_with_combine_multiple_times_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 5, using: int.add)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 3, using: int.add)

  model.successors(graph, 1)
  |> should.equal([#(2, 18)])
}

pub fn add_edge_with_combine_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 5, using: int.add)

  // Both directions should be updated
  model.successors(graph, 1)
  |> list.contains(#(2, 15))
  |> should.be_true()

  model.successors(graph, 2)
  |> list.contains(#(1, 15))
  |> should.be_true()
}

pub fn add_edge_with_combine_different_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge_with_combine(from: 1, to: 3, with: 20, using: int.add)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 5, using: int.add)

  let edges = model.successors(graph, 1)
  list.length(edges)
  |> should.equal(2)

  edges
  |> list.contains(#(2, 15))
  |> should.be_true()

  edges
  |> list.contains(#(3, 20))
  |> should.be_true()
}

pub fn add_edge_with_combine_max_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge_with_combine(from: 1, to: 2, with: 15, using: int.max)

  model.successors(graph, 1)
  |> should.equal([#(2, 15)])
}
