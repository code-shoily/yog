import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/connectivity
import yog/model.{Directed, Undirected}

// ============= Basic SCC Tests =============

// Single node with no edges
pub fn scc_single_node_test() {
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  let result = connectivity.strongly_connected_components(graph)

  // Linear chain - each node is separate SCC
  list.length(result)
  |> should.equal(3)
}

// Simple cycle - single SCC
pub fn scc_simple_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 1), #(2, 1, 1)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 1, 1), #(3, 4, 1), #(4, 3, 1)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1), #(3, 4, 1)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 4, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(2, 4, 1),
      #(3, 4, 1),
      #(4, 2, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(1, 3, 1),
      #(3, 1, 1),
      #(2, 3, 1),
      #(3, 2, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 3, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 5, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 1, 1),
      #(5, 6, 1),
      #(6, 5, 1),
      #(7, 1, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(2, 5, 1)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 1, 1), #(2, 2, 1), #(3, 3, 1)])

  let result = connectivity.strongly_connected_components(graph)

  // Each node is its own SCC
  list.length(result)
  |> should.equal(3)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// Single large cycle
pub fn scc_single_large_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 7, 1),
      #(7, 8, 1),
      #(8, 1, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 1, 1),
      #(2, 4, 1),
      #(3, 5, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A1")
    |> model.add_node(2, "A2")
    |> model.add_node(3, "B1")
    |> model.add_node(4, "B2")
    |> model.add_node(5, "C1")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(3, 4, 1),
      #(4, 3, 1),
      #(5, 5, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "main")
    |> model.add_node(2, "funcA")
    |> model.add_node(3, "funcB")
    |> model.add_node(4, "funcC")
    |> model.add_node(5, "helper")
    // main calls funcA
    |> model.add_simple_edges([
      #(1, 2),
      #(2, 3),
      // Mutual recursion: funcA <-> funcB
      #(3, 2),
      // funcB calls funcC
      #(3, 4),
      // funcC calls helper
      #(4, 5),
    ])
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "index")
    |> model.add_node(2, "about")
    |> model.add_node(3, "contact")
    |> model.add_node(4, "blog")
    |> model.add_node(5, "archive")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(1, 4, 1),
      #(2, 3, 1),
      #(3, 2, 1),
      #(4, 5, 1),
      #(5, 4, 1),
      #(2, 1, 1),
      #(4, 1, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "app")
    |> model.add_node(2, "libA")
    |> model.add_node(3, "libB")
    |> model.add_node(4, "core")
    // app depends on libA and libB
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(3, 4, 1)])

  let result = connectivity.strongly_connected_components(graph)

  // No cycles - each is its own SCC
  list.length(result)
  |> should.equal(4)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// ============= Kosaraju's Algorithm Tests =============

pub fn kosaraju_single_node_test() {
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 1, 1), #(3, 4, 1), #(4, 3, 1)])

  let result = connectivity.kosaraju(graph)

  // Should have 2 SCCs
  list.length(result)
  |> should.equal(2)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn kosaraju_classic_example_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 4, 1),
    ])

  let result = connectivity.kosaraju(graph)

  // Should have 2 SCCs: {1,2,3} and {4,5}
  list.length(result)
  |> should.equal(2)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([2, 3])
}

pub fn kosaraju_complete_graph_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(1, 3, 1),
      #(3, 1, 1),
      #(2, 3, 1),
      #(3, 2, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 3, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 5, 1),
    ])

  let result = connectivity.kosaraju(graph)

  // Should have 3 SCCs
  list.length(result)
  |> should.equal(3)

  // Each should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn kosaraju_tree_no_cycles_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(2, 5, 1)])

  let result = connectivity.kosaraju(graph)

  // Each node is its own SCC (no cycles)
  list.length(result)
  |> should.equal(5)

  // Each component has 1 node
  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

pub fn kosaraju_single_large_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 7, 1),
      #(7, 8, 1),
      #(8, 1, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 4, 1),
    ])

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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 4, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 4, 1),
      #(3, 6, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_node(5, "D")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(1, 4, 1), #(1, 5, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(3, 4, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_node(7, "G")
    |> model.add_node(8, "H")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(2, 4, 1),
      #(3, 5, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(5, 7, 1),
      #(7, 8, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 1), #(4, 5, 1)])

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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, 1), #(1, 2, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(1, 2, 2), #(2, 3, 1)])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(1, 4, 1),
      #(2, 3, 1),
      #(2, 4, 1),
      #(3, 4, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 4, 1),
      #(4, 3, 1),
      #(3, 1, 1),
      #(1, 4, 1),
    ])

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
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(5, "A")
    |> model.add_node(3, "B")
    |> model.add_edge(from: 5, to: 3, with: 1)

  let result = connectivity.analyze(in: graph)

  // Bridges should be stored in canonical order (lower ID first)
  result.bridges
  |> should.equal([#(3, 5)])
}

// ============= Connected Components Tests (Undirected) =============

pub fn cc_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = connectivity.connected_components(graph)

  result
  |> should.equal([])
}

pub fn cc_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = connectivity.connected_components(graph)

  list.length(result)
  |> should.equal(1)

  case result {
    [[node]] -> node |> should.equal(1)
    _ -> should.fail()
  }
}

pub fn cc_two_connected_nodes_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.connected_components(graph)

  // One component with both nodes
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(2)

      list.contains(component, 1)
      |> should.be_true()

      list.contains(component, 2)
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn cc_two_separate_components_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")

  let result = connectivity.connected_components(graph)

  // Two separate components
  list.length(result)
  |> should.equal(2)

  // Each component should have 2 nodes
  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn cc_triangle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

  let result = connectivity.connected_components(graph)

  // One component with all three nodes
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(3)
    _ -> should.fail()
  }
}

pub fn cc_linear_chain_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 4, 1), #(4, 5, 1)])

  let result = connectivity.connected_components(graph)

  // One component - all connected
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(5)
    _ -> should.fail()
  }
}

pub fn cc_star_graph_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_node(5, "D")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(1, 4, 1), #(1, 5, 1)])

  let result = connectivity.connected_components(graph)

  // One component
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(5)
    _ -> should.fail()
  }
}

pub fn cc_multiple_components_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A1")
    |> model.add_node(2, "A2")
    |> model.add_node(3, "A3")
    |> model.add_node(4, "B1")
    |> model.add_node(5, "B2")
    |> model.add_node(6, "C")
    // Component A: triangle
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 3, to: 1, with: 1, default: "")
    // Component B: edge
    |> model.add_edge_ensure(from: 4, to: 5, with: 1, default: "")
  // Component C: isolated node (no edges added)

  let result = connectivity.connected_components(graph)

  // Three components
  list.length(result)
  |> should.equal(3)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 2, 3])
}

pub fn cc_complete_graph_test() {
  // K4 - complete graph with 4 nodes
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(1, 4, 1),
      #(2, 3, 1),
      #(2, 4, 1),
      #(3, 4, 1),
    ])

  let result = connectivity.connected_components(graph)

  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(4)
    _ -> should.fail()
  }
}

pub fn cc_isolated_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let result = connectivity.connected_components(graph)

  // Each isolated node is its own component
  list.length(result)
  |> should.equal(3)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

// ============= Weakly Connected Components Tests (Directed) =============

pub fn wcc_empty_graph_test() {
  let graph = model.new(Directed)

  let result = connectivity.weakly_connected_components(graph)

  result
  |> should.equal([])
}

pub fn wcc_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result = connectivity.weakly_connected_components(graph)

  list.length(result)
  |> should.equal(1)

  case result {
    [[node]] -> node |> should.equal(1)
    _ -> should.fail()
  }
}

pub fn wcc_two_nodes_one_direction_test() {
  // 1 -> 2
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.weakly_connected_components(graph)

  // Weakly connected (treating as undirected)
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> {
      list.length(component)
      |> should.equal(2)

      list.contains(component, 1)
      |> should.be_true()

      list.contains(component, 2)
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn wcc_two_nodes_opposite_directions_test() {
  // 1 -> 2 and 2 -> 1 (strongly connected)
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 1), #(2, 1, 1)])

  let result = connectivity.weakly_connected_components(graph)

  // Still one component
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(2)
    _ -> should.fail()
  }
}

pub fn wcc_diverging_arrows_test() {
  // 1 -> 2 and 1 -> 3 (star from center)
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Center")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1)])

  let result = connectivity.weakly_connected_components(graph)

  // All weakly connected via node 1
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(3)
    _ -> should.fail()
  }
}

pub fn wcc_converging_arrows_test() {
  // 1 -> 3 and 2 -> 3 (both point to 3)
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 3, 1), #(2, 3, 1)])

  let result = connectivity.weakly_connected_components(graph)

  // All weakly connected via node 3
  list.length(result)
  |> should.equal(1)

  case result {
    [component] -> list.length(component) |> should.equal(3)
    _ -> should.fail()
  }
}

pub fn wcc_opposing_arrows_test() {
  // 1 -> 2 <- 3 (opposing directions, no path 1 -> 3 or 3 -> 1)
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(3, 2, 1)])

  let wccs = connectivity.weakly_connected_components(graph)
  let sccs = connectivity.strongly_connected_components(graph)

  // WCC: All one component (treating edges as undirected)
  list.length(wccs)
  |> should.equal(1)

  // SCC: Three separate components (no cycles)
  list.length(sccs)
  |> should.equal(3)
}

pub fn wcc_linear_chain_directed_test() {
  // 1 -> 2 -> 3 -> 4
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 4, 1)])

  let wccs = connectivity.weakly_connected_components(graph)
  let sccs = connectivity.strongly_connected_components(graph)

  // WCC: One component
  list.length(wccs)
  |> should.equal(1)

  case wccs {
    [component] -> list.length(component) |> should.equal(4)
    _ -> should.fail()
  }

  // SCC: Four separate components (no cycles)
  list.length(sccs)
  |> should.equal(4)
}

pub fn wcc_two_separate_components_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A1")
    |> model.add_node(2, "A2")
    |> model.add_node(3, "B1")
    |> model.add_node(4, "B2")
    // Component A: 1 -> 2
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    // Component B: 3 -> 4
    |> model.add_edge_ensure(from: 3, to: 4, with: 1, default: "")

  let result = connectivity.weakly_connected_components(graph)

  list.length(result)
  |> should.equal(2)

  list.all(result, fn(comp) { list.length(comp) == 2 })
  |> should.be_true()
}

pub fn wcc_with_cycle_test() {
  // 1 -> 2 -> 3 -> 1 (cycle) and 3 -> 4
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1), #(3, 4, 1)])

  let wccs = connectivity.weakly_connected_components(graph)
  let sccs = connectivity.strongly_connected_components(graph)

  // WCC: One component (all connected when ignoring direction)
  list.length(wccs)
  |> should.equal(1)

  case wccs {
    [component] -> list.length(component) |> should.equal(4)
    _ -> should.fail()
  }

  // SCC: Two components - {1,2,3} and {4}
  list.length(sccs)
  |> should.equal(2)

  let scc_sizes = list.map(sccs, list.length) |> list.sort(int.compare)
  scc_sizes
  |> should.equal([1, 3])
}

pub fn wcc_vs_cc_equivalence_test() {
  // Create undirected graph
  let assert Ok(undirected) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(4, 4, 1)])
  // Self-loop on 4

  // Create equivalent directed graph (edges one way)
  let assert Ok(directed) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(4, 4, 1)])

  let cc_result = connectivity.connected_components(undirected)
  let wcc_result = connectivity.weakly_connected_components(directed)

  // Both should find same number of components
  list.length(cc_result)
  |> should.equal(list.length(wcc_result))

  // Both should have same component size distribution
  let cc_sizes = list.map(cc_result, list.length) |> list.sort(int.compare)
  let wcc_sizes = list.map(wcc_result, list.length) |> list.sort(int.compare)

  cc_sizes
  |> should.equal(wcc_sizes)
}

pub fn wcc_isolated_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let result = connectivity.weakly_connected_components(graph)

  // Each isolated node is its own component
  list.length(result)
  |> should.equal(3)

  list.all(result, fn(comp) { list.length(comp) == 1 })
  |> should.be_true()
}

pub fn wcc_complex_graph_test() {
  // Complex directed graph with multiple WCCs
  // WCC 1: 1 -> 2 -> 3, 4 -> 2 (all connected via 2)
  // WCC 2: 5 -> 6 -> 7, 7 -> 5 (cycle)
  // WCC 3: 8 (isolated)
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_node(7, "G")
    |> model.add_node(8, "H")
    // WCC 1
    |> model.add_edge_ensure(from: 1, to: 2, with: 1, default: "")
    |> model.add_edge_ensure(from: 2, to: 3, with: 1, default: "")
    |> model.add_edge_ensure(from: 4, to: 2, with: 1, default: "")
    // WCC 2 (cycle)
    |> model.add_edge_ensure(from: 5, to: 6, with: 1, default: "")
    |> model.add_edge_ensure(from: 6, to: 7, with: 1, default: "")
    |> model.add_edge_ensure(from: 7, to: 5, with: 1, default: "")
  // WCC 3 (no edges)

  let result = connectivity.weakly_connected_components(graph)

  // Three WCCs
  list.length(result)
  |> should.equal(3)

  let sizes = list.map(result, list.length) |> list.sort(int.compare)
  sizes
  |> should.equal([1, 3, 4])
}

pub fn wcc_bidirectional_edges_test() {
  // 1 <-> 2 and 2 <-> 3 (strongly connected triangle via bidirectional edges)
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 1, 1),
      #(2, 3, 1),
      #(3, 2, 1),
    ])

  let wccs = connectivity.weakly_connected_components(graph)
  let sccs = connectivity.strongly_connected_components(graph)

  // WCC and SCC should be the same (all strongly connected)
  list.length(wccs)
  |> should.equal(1)

  list.length(sccs)
  |> should.equal(1)

  case wccs, sccs {
    [wcc], [scc] -> {
      list.length(wcc) |> should.equal(3)
      list.length(scc) |> should.equal(3)
    }
    _, _ -> should.fail()
  }
}

// ============= K-Core Tests =============

pub fn k_core_square_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(4, 1, with: 1, default: Nil)

  let core_2 = connectivity.k_core(graph, 2)
  model.node_count(core_2) |> should.equal(4)

  let core_3 = connectivity.k_core(graph, 3)
  model.node_count(core_3) |> should.equal(0)
}

pub fn k_core_empty_graph_test() {
  let graph = model.new(Undirected)
  connectivity.k_core(graph, 1) |> model.node_count |> should.equal(0)
}

pub fn k_core_two_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)

  connectivity.k_core(graph, 1)
  |> model.node_count
  |> should.equal(2)

  connectivity.k_core(graph, 2)
  |> model.node_count
  |> should.equal(0)
}

pub fn core_numbers_two_nodes_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)

  let cores = connectivity.core_numbers(graph)
  dict.get(cores, 1) |> should.be_ok |> should.equal(1)
  dict.get(cores, 2) |> should.be_ok |> should.equal(1)
}

pub fn core_numbers_triangle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 1, with: 1, default: Nil)

  let cores = connectivity.core_numbers(graph)
  dict.get(cores, 1) |> should.be_ok |> should.equal(2)
  dict.get(cores, 2) |> should.be_ok |> should.equal(2)
  dict.get(cores, 3) |> should.be_ok |> should.equal(2)
}

pub fn degeneracy_square_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(4, 1, with: 1, default: Nil)

  connectivity.degeneracy(graph) |> should.equal(2)
}

pub fn degeneracy_empty_test() {
  model.new(Undirected) |> connectivity.degeneracy |> should.equal(0)
}

pub fn shell_decomposition_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_edge_ensure(1, 2, with: 1, default: Nil)
    |> model.add_edge_ensure(2, 3, with: 1, default: Nil)
    |> model.add_edge_ensure(3, 4, with: 1, default: Nil)
    |> model.add_edge_ensure(4, 1, with: 1, default: Nil)

  let shells = connectivity.shell_decomposition(graph)
  dict.get(shells, 2) |> should.be_ok |> list.length |> should.equal(4)
}
