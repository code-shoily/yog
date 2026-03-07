import gleam/int
import gleam/list
import gleeunit/should
import yog/connectivity
import yog/model.{Directed, Undirected}

// ============= Basic SCC Tests =============

// Single node with no edges
pub fn scc_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Each node is its own SCC when no cycles
  list.length(result)
  |> should.equal(2)
}

// Empty graph
pub fn scc_empty_graph_test() {
  let graph = model.new(Directed)

  let result = connectivity.strongly_connected_components(graph)

  result
  |> should.equal([])
}

// Two separate nodes
pub fn scc_two_separate_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Linear chain - each node is separate SCC
  list.length(result)
  |> should.equal(3)
}

// Simple cycle - single SCC
pub fn scc_simple_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // All three nodes form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(3)

      list.contains(component, 1)
      |> should.be_true()

      list.contains(component, 2)
      |> should.be_true()

      list.contains(component, 3)
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// Self-loop - SCC of size 1
pub fn scc_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_edge(from: 1, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  list.length(result)
  |> should.equal(1)

  case result {
    [[node]] -> {
      node
      |> should.equal(1)
    }
    _ -> should.fail()
  }
}

// Two-node cycle
pub fn scc_two_node_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(2)
    }
    _ -> should.fail()
  }
}

// ============= Multiple SCC Tests =============

// Two separate cycles
pub fn scc_two_separate_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // Cycle 1: 1->2->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    // Cycle 2: 3->4->3
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 2 SCCs
  list.length(result)
  |> should.equal(2)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

// Mixed: cycle and non-cycle nodes
pub fn scc_mixed_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // Cycle: 1->2->3->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    // Non-cycle node: 4
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 2 SCCs: {1,2,3} and {4}
  list.length(result)
  |> should.equal(2)

  // One component should have 3 nodes, one should have 1
  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 3])
}

// ============= Classic Test Cases =============

// Kosaraju's example graph
pub fn scc_kosaraju_example_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 4, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 2 SCCs: {1,2,3} and {4,5}
  list.length(result)
  |> should.equal(2)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([2, 3])
}

// Diamond with cycle at bottom
pub fn scc_diamond_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 2, with: 1)
  // Cycle: 2->4->2

  let result = connectivity.strongly_connected_components(graph)

  // Should have 3 SCCs: {1}, {3}, {2,4}
  list.length(result)
  |> should.equal(3)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 1, 2])
}

// Complete directed graph (all pairs connected both ways)
pub fn scc_complete_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    // All edges in both directions
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // All nodes form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(3)
    }
    _ -> should.fail()
  }
}

// ============= Complex Graph Tests =============

// Multiple cycles connected in chain
pub fn scc_chain_of_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    // Cycle 1: 1<->2
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    // Connection: 2->3
    |> model.add_edge(from: 2, to: 3, with: 1)
    // Cycle 2: 3<->4
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)
    // Connection: 4->5
    |> model.add_edge(from: 4, to: 5, with: 1)
    // Cycle 3: 5<->6
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 5, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 3 SCCs
  list.length(result)
  |> should.equal(3)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

// Large SCC with small SCCs
pub fn scc_large_and_small_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    // Large cycle: 1->2->3->4->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 1, with: 1)
    // Small cycle: 5<->6
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 5, with: 1)
    // Single node
    |> model.add_edge(from: 7, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 3 SCCs
  list.length(result)
  |> should.equal(3)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 2, 4])
}

// Tree structure (no cycles)
pub fn scc_tree_no_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Each node is its own SCC (no cycles)
  list.length(result)
  |> should.equal(5)

  // Each component has 1 node
  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// ============= Edge Cases =============

// Graph with all self-loops
pub fn scc_all_self_loops_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 1, with: 1)
    |> model.add_edge(from: 2, to: 2, with: 1)
    |> model.add_edge(from: 3, to: 3, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Each node is its own SCC
  list.length(result)
  |> should.equal(3)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// Single large cycle
pub fn scc_single_large_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    // Cycle: 1->2->3->4->5->6->7->8->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 7, with: 1)
    |> model.add_edge(from: 7, to: 8, with: 1)
    |> model.add_edge(from: 8, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // All form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(8)
    }
    _ -> should.fail()
  }
}

// Nested cycles
pub fn scc_nested_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    // Outer cycle: 1->2->3->4->5->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 1, with: 1)
    // Inner shortcuts
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 5, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // All nodes form one large SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(5)
    }
    _ -> should.fail()
  }
}

// ============= Disconnected Components =============

// Multiple disconnected subgraphs
pub fn scc_disconnected_subgraphs_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A1")
    |> model.add_node(2, "A2")
    |> model.add_node(3, "B1")
    |> model.add_node(4, "B2")
    |> model.add_node(5, "C1")
    // Subgraph A: 1<->2
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    // Subgraph B: 3<->4
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)
    // Subgraph C: 5 (isolated with self-loop)
    |> model.add_edge(from: 5, to: 5, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 3 SCCs
  list.length(result)
  |> should.equal(3)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 2, 2])
}

// ============= Real-World-Like Examples =============

// Call graph with mutual recursion
pub fn scc_call_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "main")
    |> model.add_node(2, "funcA")
    |> model.add_node(3, "funcB")
    |> model.add_node(4, "funcC")
    |> model.add_node(5, "helper")
    // main calls funcA
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Mutual recursion: funcA <-> funcB
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)
    // funcB calls funcC
    |> model.add_edge(from: 3, to: 4, with: 1)
    // funcC calls helper
    |> model.add_edge(from: 4, to: 5, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // Should have 4 SCCs: {main}, {funcA,funcB}, {funcC}, {helper}
  list.length(result)
  |> should.equal(4)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 1, 1, 2])
}

// Web page link structure
pub fn scc_web_pages_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "index")
    |> model.add_node(2, "about")
    |> model.add_node(3, "contact")
    |> model.add_node(4, "blog")
    |> model.add_node(5, "archive")
    // index links to everything
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    // about and contact link to each other
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)
    // blog and archive link to each other
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 4, with: 1)
    // Everything links back to index
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 4, to: 1, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // All pages are in one SCC because:
  // - index can reach all pages
  // - about/contact can reach index (and thus all)
  // - blog/archive can reach index (and thus all)
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(5)
    }
    _ -> should.fail()
  }
}

// Package dependencies (should have no cycles in real world)
pub fn scc_package_deps_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "app")
    |> model.add_node(2, "libA")
    |> model.add_node(3, "libB")
    |> model.add_node(4, "core")
    // app depends on libA and libB
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    // Both libs depend on core
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.strongly_connected_components(graph)

  // No cycles - each is its own SCC
  list.length(result)
  |> should.equal(4)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// ============= Kosaraju's Algorithm Tests =============

pub fn kosaraju_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.kosaraju(graph)

  // Each node is its own SCC when no cycles
  list.length(result)
  |> should.equal(2)
}

pub fn kosaraju_empty_graph_test() {
  let graph = model.new(Directed)

  let result = connectivity.kosaraju(graph)

  result
  |> should.equal([])
}

pub fn kosaraju_simple_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = connectivity.kosaraju(graph)

  // All three nodes form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(3)

      list.contains(component, 1)
      |> should.be_true()

      list.contains(component, 2)
      |> should.be_true()

      list.contains(component, 3)
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn kosaraju_two_separate_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // Cycle 1: 1->2->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    // Cycle 2: 3->4->3
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)

  let result = connectivity.kosaraju(graph)

  // Should have 2 SCCs
  list.length(result)
  |> should.equal(2)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn kosaraju_classic_example_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 4, with: 1)

  let result = connectivity.kosaraju(graph)

  // Should have 2 SCCs: {1,2,3} and {4,5}
  list.length(result)
  |> should.equal(2)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([2, 3])
}

pub fn kosaraju_complete_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    // All edges in both directions
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)

  let result = connectivity.kosaraju(graph)

  // All nodes form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(3)
    }
    _ -> should.fail()
  }
}

pub fn kosaraju_chain_of_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    // Cycle 1: 1<->2
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)
    // Connection: 2->3
    |> model.add_edge(from: 2, to: 3, with: 1)
    // Cycle 2: 3<->4
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)
    // Connection: 4->5
    |> model.add_edge(from: 4, to: 5, with: 1)
    // Cycle 3: 5<->6
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 5, with: 1)

  let result = connectivity.kosaraju(graph)

  // Should have 3 SCCs
  list.length(result)
  |> should.equal(3)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn kosaraju_tree_no_cycles_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)

  let result = connectivity.kosaraju(graph)

  // Each node is its own SCC (no cycles)
  list.length(result)
  |> should.equal(5)

  // Each component has 1 node
  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

pub fn kosaraju_single_large_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    // Cycle: 1->2->3->4->5->6->7->8->1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 7, with: 1)
    |> model.add_edge(from: 7, to: 8, with: 1)
    |> model.add_edge(from: 8, to: 1, with: 1)

  let result = connectivity.kosaraju(graph)

  // All form one SCC
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(8)
    }
    _ -> should.fail()
  }
}

// Compare Tarjan vs Kosaraju - should produce same number of SCCs with same sizes
pub fn tarjan_vs_kosaraju_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 4, with: 1)

  let tarjan_result = connectivity.strongly_connected_components(graph)
  let kosaraju_result = connectivity.kosaraju(graph)

  // Both should find same number of SCCs
  list.length(tarjan_result)
  |> should.equal(list.length(kosaraju_result))

  // Both should have same distribution of component sizes
  let tarjan_sizes =
    list.map(tarjan_result, list.length) |> list.sort(int.compare)
  let kosaraju_sizes =
    list.map(kosaraju_result, list.length) |> list.sort(int.compare)

  tarjan_sizes
  |> should.equal(kosaraju_sizes)
}

// ============= Basic Connectivity Tests =============

pub fn connectivity_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = connectivity.analyze(in: graph)

  result.bridges
  |> should.equal([])

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = connectivity.analyze(in: graph)

  result.bridges
  |> should.equal([])

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_two_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Single edge is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  // Neither node is an articulation point (only 2 nodes)
  result.articulation_points
  |> should.equal([])
}

// ============= Bridge Detection Tests =============

pub fn connectivity_linear_chain_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges in a linear chain
  result.bridges
  |> list.length()
  |> should.equal(3)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(2, 3))
  |> should.be_true()

  result.bridges
  |> list.contains(#(3, 4))
  |> should.be_true()

  // Middle nodes are articulation points
  result.articulation_points
  |> list.length()
  |> should.equal(2)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()

  result.articulation_points
  |> list.contains(3)
  |> should.be_true()
}

pub fn connectivity_triangle_no_bridges_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges in a cycle (triangle)
  result.bridges
  |> should.equal([])

  // No articulation points in a triangle
  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_bridge_between_triangles_test() {
  // Two triangles connected by a single edge (bridge)
  //   1 - 2      4 - 5
  //    \ /        \ /
  //     3 ------- 6
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    // First triangle
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    // Second triangle
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 6, to: 4, with: 1)
    // Bridge connecting the triangles
    |> model.add_edge(from: 3, to: 6, with: 1)

  let result = connectivity.analyze(in: graph)

  // Only the connecting edge is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(3, 6))
  |> should.be_true()

  // The endpoints of the bridge are articulation points
  result.articulation_points
  |> list.length()
  |> should.equal(2)

  result.articulation_points
  |> list.contains(3)
  |> should.be_true()

  result.articulation_points
  |> list.contains(6)
  |> should.be_true()
}

// ============= Articulation Point Detection Tests =============

pub fn connectivity_star_graph_test() {
  // Star graph: center node connected to all others
  //     2
  //     |
  // 3 - 1 - 4
  //     |
  //     5
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_node(5, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 1, to: 5, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges in a star
  result.bridges
  |> list.length()
  |> should.equal(4)

  // Only the center is an articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(1)
  |> should.be_true()
}

pub fn connectivity_diamond_test() {
  // Diamond shape: two paths from 1 to 4
  //   1
  //  / \
  // 2   3
  //  \ /
  //   4
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges (multiple paths between all pairs)
  result.bridges
  |> should.equal([])

  // No articulation points in a diamond
  // (removing any node leaves remaining nodes connected)
  result.articulation_points
  |> should.equal([])
}

// ============= Complex Graph Tests =============

pub fn connectivity_complex_graph_test() {
  // Complex graph with multiple bridges and articulation points
  //     1 - 2 - 3
  //         |   |
  //         4 - 5 - 6
  //             |
  //             7 - 8
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_node(7, "G")
    |> model.add_node(8, "H")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 5, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 5, to: 7, with: 1)
    |> model.add_edge(from: 7, to: 8, with: 1)

  let result = connectivity.analyze(in: graph)

  // Bridges: 1-2, 5-6, 5-7, 7-8
  result.bridges
  |> list.length()
  |> should.equal(4)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(5, 6))
  |> should.be_true()

  result.bridges
  |> list.contains(#(5, 7))
  |> should.be_true()

  result.bridges
  |> list.contains(#(7, 8))
  |> should.be_true()

  // Articulation points: 2, 5, 7
  result.articulation_points
  |> list.length()
  |> should.equal(3)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()

  result.articulation_points
  |> list.contains(5)
  |> should.be_true()

  result.articulation_points
  |> list.contains(7)
  |> should.be_true()
}

// ============= Disconnected Graph Tests =============

pub fn connectivity_disconnected_components_test() {
  // Two separate components
  // Component 1: 1 - 2
  // Component 2: 3 - 4 - 5
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)

  let result = connectivity.analyze(in: graph)

  // All edges are bridges (within their components)
  result.bridges
  |> list.length()
  |> should.equal(3)

  // Middle node of second component is articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(4)
  |> should.be_true()
}

pub fn connectivity_isolated_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Only the edge between connected nodes is a bridge
  result.bridges
  |> list.length()
  |> should.equal(1)

  // Isolated node doesn't affect articulation points
  result.articulation_points
  |> should.equal([])
}

// ============= Edge Case Tests =============

pub fn connectivity_self_loop_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Self-loop doesn't affect bridge detection
  result.bridges
  |> list.length()
  |> should.equal(1)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_parallel_edges_test() {
  // Multiple edges between the same pair of nodes
  // Note: Standard Tarjan's algorithm with node-based parent tracking
  // doesn't handle parallel edges perfectly - it would need edge IDs.
  // This test documents the actual behavior.
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 2)
    // Duplicate edge with different weight
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = connectivity.analyze(in: graph)

  // With node-based parent tracking, parallel edges are detected
  // Both edges 1-2 and 2-3 are detected as bridges
  result.bridges
  |> list.length()
  |> should.equal(2)

  result.bridges
  |> list.contains(#(1, 2))
  |> should.be_true()

  result.bridges
  |> list.contains(#(2, 3))
  |> should.be_true()

  // Node 2 is an articulation point
  result.articulation_points
  |> list.length()
  |> should.equal(1)

  result.articulation_points
  |> list.contains(2)
  |> should.be_true()
}

pub fn connectivity_complete_graph_test() {
  // Complete graph K4: every node connected to every other node
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = connectivity.analyze(in: graph)

  // No bridges in a complete graph
  result.bridges
  |> should.equal([])

  // No articulation points in a complete graph
  result.articulation_points
  |> should.equal([])
}

pub fn connectivity_square_with_diagonal_test() {
  // Square with one diagonal
  //   1 - 2
  //   | X |
  //   3 - 4
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
  // Diagonal

  let result = connectivity.analyze(in: graph)

  // No bridges (multiple paths between all pairs)
  result.bridges
  |> should.equal([])

  // No articulation points (removing any node leaves graph connected)
  result.articulation_points
  |> should.equal([])
}

// ============= Bridge Ordering Test =============

pub fn connectivity_bridge_ordering_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(5, "A")
    |> model.add_node(3, "B")
    |> model.add_edge(from: 5, to: 3, with: 1)

  let result = connectivity.analyze(in: graph)

  // Bridges should be stored in canonical order (lower ID first)
  result.bridges
  |> should.equal([#(3, 5)])
}
