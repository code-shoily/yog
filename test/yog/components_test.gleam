import gleam/int
import gleam/list
import gleeunit/should
import yog/components
import yog/model.{Directed}

// ============= Basic SCC Tests =============

// Single node with no edges
pub fn scc_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = components.strongly_connected_components(graph)

  // Each node is its own SCC when no cycles
  list.length(result)
  |> should.equal(2)
}

// Empty graph
pub fn scc_empty_graph_test() {
  let graph = model.new(Directed)

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.strongly_connected_components(graph)

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

  let result = components.kosaraju(graph)

  // Each node is its own SCC when no cycles
  list.length(result)
  |> should.equal(2)
}

pub fn kosaraju_empty_graph_test() {
  let graph = model.new(Directed)

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let result = components.kosaraju(graph)

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

  let tarjan_result = components.strongly_connected_components(graph)
  let kosaraju_result = components.kosaraju(graph)

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
