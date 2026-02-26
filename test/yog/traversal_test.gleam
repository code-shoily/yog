import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/traversal.{BreadthFirst, DepthFirst}

// ============= BFS Tests =============

// Test BFS on a simple linear path: 1 -> 2 -> 3
pub fn bfs_linear_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  traversal.walk(from: 1, in: graph, using: BreadthFirst)
  |> should.equal([1, 2, 3])
}

// Test BFS on a tree structure
//     1
//    / \
//   2   3
//  / \
// 4   5
pub fn bfs_tree_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)

  let result = traversal.walk(from: 1, in: graph, using: BreadthFirst)

  // BFS visits level by level: 1, then {2,3}, then {4,5}
  result
  |> should.equal([1, 2, 3, 4, 5])
}

// Test BFS with a cycle (should not infinite loop)
pub fn bfs_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = traversal.walk(from: 1, in: graph, using: BreadthFirst)

  // Should visit each node exactly once
  result
  |> should.equal([1, 2, 3])
}

// Test BFS from an isolated node
pub fn bfs_isolated_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Isolated")
    |> model.add_node(2, "Other")

  traversal.walk(from: 1, in: graph, using: BreadthFirst)
  |> should.equal([1])
}

// Test BFS on an empty graph (node doesn't exist)
pub fn bfs_nonexistent_start_test() {
  let graph = model.new(Directed)

  traversal.walk(from: 99, in: graph, using: BreadthFirst)
  |> should.equal([99])
}

// Test BFS on undirected graph
pub fn bfs_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = traversal.walk(from: 2, in: graph, using: BreadthFirst)

  // From node 2, BFS should reach both 1 and 3
  result
  |> should.equal([2, 1, 3])
}

// ============= DFS Tests =============

// Test DFS on a simple linear path: 1 -> 2 -> 3
pub fn dfs_linear_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  traversal.walk(from: 1, in: graph, using: DepthFirst)
  |> should.equal([1, 2, 3])
}

// Test DFS on a tree structure
//     1
//    / \
//   2   3
//  / \
// 4   5
pub fn dfs_tree_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)

  let result = traversal.walk(from: 1, in: graph, using: DepthFirst)

  // DFS goes deep first: 1 -> 2 -> 4 -> 5 -> 3
  // Note: Order of 2 and 3 depends on insertion order in dict
  // Let's just verify that nodes are visited and 4,5 come before 3
  result
  |> should.equal([1, 2, 4, 5, 3])
}

// Test DFS with a cycle (should not infinite loop)
pub fn dfs_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result = traversal.walk(from: 1, in: graph, using: DepthFirst)

  // Should visit each node exactly once
  result
  |> should.equal([1, 2, 3])
}

// Test DFS from an isolated node
pub fn dfs_isolated_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Isolated")
    |> model.add_node(2, "Other")

  traversal.walk(from: 1, in: graph, using: DepthFirst)
  |> should.equal([1])
}

// Test DFS with a diamond pattern
//   1
//  / \
// 2   3
//  \ /
//   4
pub fn dfs_diamond_test() {
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

  let result = traversal.walk(from: 1, in: graph, using: DepthFirst)

  // DFS should visit node 4 only once, even though it has two paths to it
  result
  |> should.equal([1, 2, 4, 3])
}

// ============= walk_until Tests =============

// Test walk_until stops at target node (BFS)
pub fn walk_until_bfs_stops_at_target_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result =
    traversal.walk_until(from: 1, in: graph, using: BreadthFirst, until: fn(id) {
      id == 3
    })

  // Should stop when reaching node 3 and include it
  result
  |> should.equal([1, 2, 3])
}

// Test walk_until stops at target node (DFS)
pub fn walk_until_dfs_stops_at_target_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result =
    traversal.walk_until(from: 1, in: graph, using: DepthFirst, until: fn(id) {
      id == 3
    })

  // Should stop when reaching node 3 and include it
  result
  |> should.equal([1, 2, 3])
}

// Test walk_until never stops (visits all nodes)
pub fn walk_until_never_stops_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result =
    traversal.walk_until(
      from: 1,
      in: graph,
      using: BreadthFirst,
      until: fn(_id) { False },
    )

  // Should visit all nodes since predicate never returns True
  result
  |> should.equal([1, 2, 3])
}

// Test walk_until stops immediately at start node
pub fn walk_until_stops_at_start_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result =
    traversal.walk_until(from: 1, in: graph, using: BreadthFirst, until: fn(id) {
      id == 1
    })

  // Should stop immediately and return only the start node
  result
  |> should.equal([1])
}

// Test walk_until on a tree with complex stop condition
pub fn walk_until_complex_condition_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "LL")
    |> model.add_node(5, "LR")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)

  let result =
    traversal.walk_until(from: 1, in: graph, using: BreadthFirst, until: fn(id) {
      id > 3
    })

  // Should stop when reaching first node > 3 (which would be 4)
  result
  |> should.equal([1, 2, 3, 4])
}

// ============= Edge Cases =============

// Test with self-loop
pub fn traversal_with_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = traversal.walk(from: 1, in: graph, using: BreadthFirst)

  // Self-loop should not cause infinite recursion
  result
  |> should.equal([1, 2])
}

// Test with disconnected component (shouldn't reach it)
pub fn traversal_disconnected_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
  // Node 3 is disconnected

  let result = traversal.walk(from: 1, in: graph, using: BreadthFirst)

  // Should only visit nodes reachable from start
  result
  |> should.equal([1, 2])
}

// Test BFS vs DFS difference on the same graph
pub fn bfs_vs_dfs_difference_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "L")
    |> model.add_node(3, "R")
    |> model.add_node(4, "LL")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)

  let bfs_result = traversal.walk(from: 1, in: graph, using: BreadthFirst)
  let dfs_result = traversal.walk(from: 1, in: graph, using: DepthFirst)

  // BFS: level by level
  bfs_result
  |> should.equal([1, 2, 3, 4])

  // DFS: goes deep first
  dfs_result
  |> should.equal([1, 2, 4, 3])
}
