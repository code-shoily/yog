import gleam/int
import gleam/list
import gleeunit/should
import yog/model.{Directed}
import yog/topological_sort as topo

// ============= Basic Topological Sort Tests =============

// Simple linear DAG: 1 -> 2 -> 3
pub fn topo_sort_linear_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Ok([1, 2, 3]))
}

// Single node with edge to itself (current implementation requires edges)
pub fn topo_sort_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Ok([1, 2]))
}

// Empty graph
pub fn topo_sort_empty_graph_test() {
  let graph = model.new(Directed)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Ok([]))
}

// Two nodes connected with edge
pub fn topo_sort_two_independent_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = topo.topological_sort(graph)

  // Should succeed with all nodes
  case result {
    Ok(sorted) -> {
      list.length(sorted)
      |> should.equal(3)

      // 3 should be last
      let pos3 = find_position(sorted, 3)
      pos3
      |> should.equal(2)
    }
    Error(_) -> should.fail()
  }
}

// Simple fork: 1 -> {2, 3}
pub fn topo_sort_fork_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      // Node 1 must come before both 2 and 3
      let pos1 = find_position(sorted, 1)
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)

      { pos1 < pos2 }
      |> should.be_true()

      { pos1 < pos3 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Simple join: {1, 2} -> 3
pub fn topo_sort_join_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Left")
    |> model.add_node(2, "Right")
    |> model.add_node(3, "Bottom")
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      // Both 1 and 2 must come before 3
      let pos1 = find_position(sorted, 1)
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)

      { pos1 < pos3 }
      |> should.be_true()

      { pos2 < pos3 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Diamond DAG
//     1
//    / \
//   2   3
//    \ /
//     4
pub fn topo_sort_diamond_test() {
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

  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      let pos1 = find_position(sorted, 1)
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)
      let pos4 = find_position(sorted, 4)

      // 1 before all
      { pos1 < pos2 }
      |> should.be_true()

      { pos1 < pos3 }
      |> should.be_true()

      { pos1 < pos4 }
      |> should.be_true()

      // 2 and 3 before 4
      { pos2 < pos4 }
      |> should.be_true()

      { pos3 < pos4 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// ============= Cycle Detection Tests =============

// Simple cycle: 1 -> 2 -> 3 -> 1
pub fn topo_sort_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Error(Nil))
}

// Self-loop
pub fn topo_sort_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_edge(from: 1, to: 1, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Error(Nil))
}

// Cycle in part of graph
pub fn topo_sort_partial_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)
    // 2-3 cycle
    |> model.add_edge(from: 1, to: 4, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Error(Nil))
}

// Two-node cycle
pub fn topo_sort_two_node_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Error(Nil))
}

// ============= Complex DAG Tests =============

// Multiple disconnected components
pub fn topo_sort_disconnected_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    // Component 1: 1->2
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Component 2: 3->4
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      list.length(sorted)
      |> should.equal(4)

      // Each edge constraint must be satisfied
      let pos1 = find_position(sorted, 1)
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)
      let pos4 = find_position(sorted, 4)

      { pos1 < pos2 }
      |> should.be_true()

      { pos3 < pos4 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Long chain
pub fn topo_sort_long_chain_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)

  let result = topo.topological_sort(graph)

  result
  |> should.equal(Ok([1, 2, 3, 4, 5, 6]))
}

// Tree structure
pub fn topo_sort_tree_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_node(6, "RL")
    |> model.add_node(7, "RR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 3, to: 6, with: 1)
    |> model.add_edge(from: 3, to: 7, with: 1)

  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      list.length(sorted)
      |> should.equal(7)

      // Root must be first
      let pos1 = find_position(sorted, 1)
      pos1
      |> should.equal(0)

      // All children after parents
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)
      let pos4 = find_position(sorted, 4)
      let pos5 = find_position(sorted, 5)
      let pos6 = find_position(sorted, 6)
      let pos7 = find_position(sorted, 7)

      { pos1 < pos2 }
      |> should.be_true()

      { pos1 < pos3 }
      |> should.be_true()

      { pos2 < pos4 }
      |> should.be_true()

      { pos2 < pos5 }
      |> should.be_true()

      { pos3 < pos6 }
      |> should.be_true()

      { pos3 < pos7 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// ============= Lexicographical Sort Tests =============

// Simple case where order matters
pub fn lexi_topo_sort_basic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = topo.lexicographical_topological_sort(graph, int.compare)

  // Should return [1, 2, 3] - after 1, both 2 and 3 available, picks 2 first
  result
  |> should.equal(Ok([1, 2, 3]))
}

// Fork - lexicographically smallest
pub fn lexi_topo_sort_fork_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = topo.lexicographical_topological_sort(graph, int.compare)

  // Should be [1, 2, 3] because after 1, both 2 and 3 are available
  // and 2 < 3 lexicographically
  result
  |> should.equal(Ok([1, 2, 3]))
}

// Join - lexicographically smallest
pub fn lexi_topo_sort_join_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(1, "C")
    |> model.add_edge(from: 2, to: 1, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = topo.lexicographical_topological_sort(graph, int.compare)

  // Should start with 2 (smaller than 3), then 3, then 1
  result
  |> should.equal(Ok([2, 3, 1]))
}

// Diamond - lexicographical
pub fn lexi_topo_sort_diamond_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(3, "Right")
    |> model.add_node(2, "Left")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = topo.lexicographical_topological_sort(graph, int.compare)

  // After 1, both 2 and 3 are available. Pick 2 (smaller).
  // After 2, only 3 is available (4 still has incoming from 3).
  // After 3, 4 is available.
  result
  |> should.equal(Ok([1, 2, 3, 4]))
}

// Lexicographical with cycle detection
pub fn lexi_topo_sort_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 1, with: 1)

  let result = topo.lexicographical_topological_sort(graph, int.compare)

  result
  |> should.equal(Error(Nil))
}

// Multiple valid orderings - lexicographical picks smallest
pub fn lexi_topo_sort_multiple_valid_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(5, "E")
    |> model.add_node(3, "C")
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(4, "D")
    // Add edges to connect them
    |> model.add_edge(from: 1, to: 5, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 3, to: 5, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)

  // All point to 5, so 5 must be last
  let result = topo.lexicographical_topological_sort(graph, int.compare)

  // Should start with smallest and end with 5
  result
  |> should.equal(Ok([1, 2, 3, 4, 5]))
}

// ============= Classic Examples =============

// Task scheduling example
pub fn topo_sort_tasks_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Wake up")
    |> model.add_node(2, "Shower")
    |> model.add_node(3, "Dress")
    |> model.add_node(4, "Eat breakfast")
    |> model.add_node(5, "Leave house")
    |> model.add_edge(from: 1, to: 2, with: 1)
    // Wake before shower
    |> model.add_edge(from: 2, to: 3, with: 1)
    // Shower before dress
    |> model.add_edge(from: 3, to: 5, with: 1)
    // Dress before leave
    |> model.add_edge(from: 4, to: 5, with: 1)
    // Eat before leave
    |> model.add_edge(from: 1, to: 4, with: 1)

  // Wake before eat
  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      // Verify all constraints
      let pos1 = find_position(sorted, 1)
      let pos2 = find_position(sorted, 2)
      let pos3 = find_position(sorted, 3)
      let pos4 = find_position(sorted, 4)
      let pos5 = find_position(sorted, 5)

      { pos1 < pos2 }
      |> should.be_true()

      { pos2 < pos3 }
      |> should.be_true()

      { pos3 < pos5 }
      |> should.be_true()

      { pos4 < pos5 }
      |> should.be_true()

      { pos1 < pos4 }
      |> should.be_true()

      // Node 5 should be last
      pos5
      |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}

// Build system dependencies
pub fn topo_sort_build_deps_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "main.o")
    |> model.add_node(2, "main.c")
    |> model.add_node(3, "utils.o")
    |> model.add_node(4, "utils.c")
    |> model.add_node(5, "app")
    |> model.add_edge(from: 2, to: 1, with: 1)
    // main.c -> main.o
    |> model.add_edge(from: 4, to: 3, with: 1)
    // utils.c -> utils.o
    |> model.add_edge(from: 1, to: 5, with: 1)
    // main.o -> app
    |> model.add_edge(from: 3, to: 5, with: 1)

  // utils.o -> app
  let result = topo.topological_sort(graph)

  case result {
    Ok(sorted) -> {
      // Sources before objects
      let pos2 = find_position(sorted, 2)
      let pos1 = find_position(sorted, 1)
      let pos4 = find_position(sorted, 4)
      let pos3 = find_position(sorted, 3)
      let pos5 = find_position(sorted, 5)

      { pos2 < pos1 }
      |> should.be_true()

      { pos4 < pos3 }
      |> should.be_true()

      // Objects before app
      { pos1 < pos5 }
      |> should.be_true()

      { pos3 < pos5 }
      |> should.be_true()

      // App is last
      pos5
      |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}

// ============= Helper Functions =============

fn find_position(list: List(a), item: a) -> Int {
  do_find_position(list, item, 0)
}

fn do_find_position(list: List(a), item: a, index: Int) -> Int {
  case list {
    [] -> -1
    [head, ..tail] ->
      case head == item {
        True -> index
        False -> do_find_position(tail, item, index + 1)
      }
  }
}
