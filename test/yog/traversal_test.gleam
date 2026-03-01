import gleam/dict
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/traversal.{BreadthFirst, Continue, DepthFirst, Halt, Stop}

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

// ============= fold_walk Tests =============

// Test fold_walk with BFS collecting nodes within distance
pub fn fold_walk_bfs_distance_limit_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  // Collect only nodes within distance 2
  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      with: fn(acc, node_id, meta) {
        case meta.depth <= 2 {
          True -> #(Continue, dict.insert(acc, node_id, meta.depth))
          False -> #(Stop, acc)
        }
      },
    )

  result
  |> dict.get(1)
  |> should.equal(Ok(0))

  result
  |> dict.get(2)
  |> should.equal(Ok(1))

  result
  |> dict.get(3)
  |> should.equal(Ok(2))

  // Node 4 should not be in result (distance 3)
  result
  |> dict.get(4)
  |> should.equal(Error(Nil))
}

// Test fold_walk building parent map
pub fn fold_walk_parent_map_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "LL")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)

  let parents =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      with: fn(acc, node_id, meta) {
        let new_acc = case meta.parent {
          Some(p) -> dict.insert(acc, node_id, p)
          None -> acc
        }
        #(Continue, new_acc)
      },
    )

  // Node 1 has no parent (it's the root)
  parents
  |> dict.get(1)
  |> should.equal(Error(Nil))

  // Node 2's parent is 1
  parents
  |> dict.get(2)
  |> should.equal(Ok(1))

  // Node 3's parent is 1
  parents
  |> dict.get(3)
  |> should.equal(Ok(1))

  // Node 4's parent is 2
  parents
  |> dict.get(4)
  |> should.equal(Ok(2))
}

// Test fold_walk counting nodes at each depth
pub fn fold_walk_depth_count_test() {
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

  let depth_counts =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      with: fn(acc, _node_id, meta) {
        let count = dict.get(acc, meta.depth) |> result.unwrap(0)
        #(Continue, dict.insert(acc, meta.depth, count + 1))
      },
    )

  // Depth 0: 1 node (root)
  depth_counts
  |> dict.get(0)
  |> should.equal(Ok(1))

  // Depth 1: 2 nodes (2 and 3)
  depth_counts
  |> dict.get(1)
  |> should.equal(Ok(2))

  // Depth 2: 2 nodes (4 and 5)
  depth_counts
  |> dict.get(2)
  |> should.equal(Ok(2))
}

// Test fold_walk with DFS
pub fn fold_walk_dfs_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  // Collect nodes in order visited
  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: DepthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // DFS visits in order: 1, 2, 3
  result
  |> should.equal([3, 2, 1])
}

// Test fold_walk with Stop control
pub fn fold_walk_stop_control_test() {
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

  // Stop exploring from node 2 (so nodes 4 and 5 shouldn't be visited)
  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        case node_id == 2 {
          True -> #(Stop, [node_id, ..acc])
          False -> #(Continue, [node_id, ..acc])
        }
      },
    )

  // Should visit 1, 2, and 3, but not 4 or 5
  result
  |> should.equal([3, 2, 1])
}

// Test fold_walk on empty start
pub fn fold_walk_isolated_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Isolated")
    |> model.add_node(2, "Other")

  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: 0,
      with: fn(acc, _node_id, _meta) { #(Continue, acc + 1) },
    )

  // Should only visit node 1
  result
  |> should.equal(1)
}

// Test fold_walk with cycle (should not infinite loop)
pub fn fold_walk_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // Should visit each node exactly once
  result
  |> should.equal([3, 2, 1])
}

// Test fold_walk start node metadata
pub fn fold_walk_start_metadata_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Next")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      with: fn(acc, node_id, meta) {
        #(Continue, dict.insert(acc, node_id, #(meta.depth, meta.parent)))
      },
    )

  // Start node should have depth 0 and no parent
  result
  |> dict.get(1)
  |> should.equal(Ok(#(0, None)))

  // Next node should have depth 1 and parent 1
  result
  |> dict.get(2)
  |> should.equal(Ok(#(1, Some(1))))
}

// Test fold_walk with Halt control (BFS)
pub fn fold_walk_halt_bfs_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)

  // Halt when we find node 2
  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        case node_id == 2 {
          True -> #(Halt, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  // Should only visit 1 and 2, not 3 or 4
  result
  |> should.equal([2, 1])
}

// Test fold_walk with Halt control (DFS)
pub fn fold_walk_halt_dfs_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  // Halt when we find node 3
  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: DepthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        case node_id == 3 {
          True -> #(Halt, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  // Should visit 1, 2, 3 but not 4 (halted at 3)
  result
  |> should.equal([3, 2, 1])
}

// Test fold_walk Halt vs Stop difference
pub fn fold_walk_halt_vs_stop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Root")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "LL")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)

  // With Stop: visits 1, 2, 3 (skips 4 because we stopped at 2)
  let stop_result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        case node_id == 2 {
          True -> #(Stop, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  stop_result
  |> should.equal([3, 2, 1])

  // With Halt: visits 1, 2 only (halts entire traversal)
  let halt_result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        case node_id == 2 {
          True -> #(Halt, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  halt_result
  |> should.equal([2, 1])
}

// Test that Halt at start node returns immediately
pub fn fold_walk_halt_at_start_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result =
    traversal.fold_walk(
      over: graph,
      from: 1,
      using: BreadthFirst,
      initial: [],
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        #(Halt, new_acc)
      },
    )

  // Should only visit start node
  result
  |> should.equal([1])
}
