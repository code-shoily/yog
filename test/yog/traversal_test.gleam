import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
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

// ============= implicit_fold Tests =============

// Test implicit_fold BFS on simple chain: 1 -> 2 -> 3 -> 4
pub fn implicit_fold_bfs_chain_test() {
  // Simple successor function: each node points to next
  let successors = fn(n) {
    case n < 4 {
      True -> [n + 1]
      False -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  result
  |> should.equal([4, 3, 2, 1])
}

// Test implicit_fold DFS on simple chain
pub fn implicit_fold_dfs_chain_test() {
  let successors = fn(n) {
    case n < 4 {
      True -> [n + 1]
      False -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: DepthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  result
  |> should.equal([4, 3, 2, 1])
}

// Test implicit_fold BFS on tree structure
//     1
//    / \
//   2   3
//  / \
// 4   5
pub fn implicit_fold_bfs_tree_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4, 5]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // BFS visits level by level: 1, then {2,3}, then {4,5}
  result
  |> should.equal([5, 4, 3, 2, 1])
}

// Test implicit_foldDFS on tree structure
pub fn implicit_fold_dfs_tree_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4, 5]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: DepthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // DFS goes deep first: 1 -> 2 -> 4 -> 5 -> 3
  result
  |> should.equal([3, 5, 4, 2, 1])
}

// Test implicit_foldwith cycle detection
pub fn implicit_fold_with_cycle_test() {
  // Create a cycle: 1 -> 2 -> 3 -> 1
  let successors = fn(n) {
    case n {
      1 -> [2]
      2 -> [3]
      3 -> [1]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // Should visit each node exactly once despite the cycle
  result
  |> should.equal([3, 2, 1])
}

// Test implicit_foldwith isolated node (no successors)
pub fn implicit_fold_isolated_node_test() {
  let successors = fn(_n) { [] }

  let result =
    traversal.implicit_fold(
      from: 42,
      using: BreadthFirst,
      initial: 0,
      successors_of: successors,
      with: fn(acc, _node_id, _meta) { #(Continue, acc + 1) },
    )

  // Should only visit the start node
  result
  |> should.equal(1)
}

// Test implicit_foldcollecting depth metadata
pub fn implicit_fold_depth_metadata_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4, 5]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      successors_of: successors,
      with: fn(acc, node_id, meta) {
        #(Continue, dict.insert(acc, node_id, meta.depth))
      },
    )

  // Verify depths
  result
  |> dict.get(1)
  |> should.equal(Ok(0))

  result
  |> dict.get(2)
  |> should.equal(Ok(1))

  result
  |> dict.get(3)
  |> should.equal(Ok(1))

  result
  |> dict.get(4)
  |> should.equal(Ok(2))

  result
  |> dict.get(5)
  |> should.equal(Ok(2))
}

// Test implicit_foldbuilding parent map
pub fn implicit_fold_parent_map_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4]
      _ -> []
    }
  }

  let parents =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      successors_of: successors,
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

// Test implicit_foldwith Stop control
pub fn implicit_fold_stop_control_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4, 5]
      _ -> []
    }
  }

  // Stop exploring from node 2 (so nodes 4 and 5 shouldn't be visited)
  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
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

// Test implicit_foldwith Halt control (BFS)
pub fn implicit_fold_halt_bfs_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4]
      _ -> []
    }
  }

  // Halt when we find node 2
  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
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

// Test implicit_foldwith Halt control (DFS)
pub fn implicit_fold_halt_dfs_test() {
  let successors = fn(n) {
    case n < 5 {
      True -> [n + 1]
      False -> []
    }
  }

  // Halt when we find node 3
  let result =
    traversal.implicit_fold(
      from: 1,
      using: DepthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) {
        let new_acc = [node_id, ..acc]
        case node_id == 3 {
          True -> #(Halt, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  // Should visit 1, 2, 3 but not 4 or 5 (halted at 3)
  result
  |> should.equal([3, 2, 1])
}

// Test implicit_foldHalt vs Stop difference
pub fn implicit_fold_halt_vs_stop_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4]
      _ -> []
    }
  }

  // With Stop: visits 1, 2, 3 (skips 4 because we stopped at 2)
  let stop_result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
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
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
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

// Test implicit_foldwith 2D grid coordinates (tuples as node IDs)
pub fn implicit_fold_2d_grid_test() {
  // 3x3 grid, only move right and down
  let successors = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    let right = #(x + 1, y)
    let down = #(x, y + 1)

    case x < 2, y < 2 {
      True, True -> [right, down]
      True, False -> [right]
      False, True -> [down]
      False, False -> []
    }
  }

  // Find shortest path to bottom-right corner
  let result =
    traversal.implicit_fold(
      from: #(0, 0),
      using: BreadthFirst,
      initial: -1,
      successors_of: successors,
      with: fn(acc, pos, meta) {
        case pos == #(2, 2) {
          True -> #(Halt, meta.depth)
          False -> #(Continue, acc)
        }
      },
    )

  // Distance from (0,0) to (2,2) is 4 (2 right + 2 down)
  result
  |> should.equal(4)
}

// Test implicit_foldwith string node IDs
pub fn implicit_fold_string_ids_test() {
  let successors = fn(node: String) {
    case node {
      "start" -> ["a", "b"]
      "a" -> ["c"]
      "b" -> ["c"]
      "c" -> ["end"]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: "start",
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // Should visit all nodes
  result
  |> should.equal(["end", "c", "b", "a", "start"])
}

// Test implicit_foldwith distance limit (like fold_walk example)
pub fn implicit_fold_distance_limit_test() {
  let successors = fn(n) {
    case n < 5 {
      True -> [n + 1]
      False -> []
    }
  }

  // Collect only nodes within distance 2
  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: dict.new(),
      successors_of: successors,
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

// Test implicit_foldwith self-loop
pub fn implicit_fold_self_loop_test() {
  let successors = fn(n) {
    case n {
      1 -> [1, 2]
      // Self-loop at 1
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // Self-loop should not cause infinite recursion
  result
  |> should.equal([2, 1])
}

// Test implicit_folddiamond pattern
//   1
//  / \
// 2   3
//  \ /
//   4
pub fn implicit_fold_diamond_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4]
      3 -> [4]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // Should visit node 4 only once, even though it has two paths to it
  result
  |> should.equal([4, 3, 2, 1])
}

// Test implicit_foldBFS vs DFS difference
pub fn implicit_fold_bfs_vs_dfs_difference_test() {
  let successors = fn(n) {
    case n {
      1 -> [2, 3]
      2 -> [4]
      _ -> []
    }
  }

  let bfs_result =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  let dfs_result =
    traversal.implicit_fold(
      from: 1,
      using: DepthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, node_id, _meta) { #(Continue, [node_id, ..acc]) },
    )

  // BFS: level by level
  bfs_result
  |> should.equal([4, 3, 2, 1])

  // DFS: goes deep first
  dfs_result
  |> should.equal([3, 4, 2, 1])
}

// ============= implicit_fold_by Tests =============

// Test implicit_fold_by with position + mask (canonical use case)
// Nodes carry extra state (mask) but dedupe by position only
pub fn implicit_fold_by_position_mask_test() {
  // Each node is #(position, bitmask) but we only want to visit each position once
  let successors = fn(node: #(Int, Int)) {
    let #(pos, mask) = node
    case pos {
      1 -> [#(2, mask + 1), #(3, mask + 10)]
      2 -> [#(4, mask + 1)]
      3 -> [#(4, mask + 10)]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #(1, 0),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      // Dedupe by position only
      with: fn(acc, node, _meta) { #(Continue, [node, ..acc]) },
    )

  // Should visit positions 1,2,3,4 exactly once
  // Even though successors return different masks
  result
  |> list.length()
  |> should.equal(4)

  // Check all positions were visited
  result
  |> list.map(fn(node) { node.0 })
  |> list.sort(by: int.compare)
  |> should.equal([1, 2, 3, 4])
}

// Test that first-visit wins: earlier mask value is kept
pub fn implicit_fold_by_first_visit_wins_test() {
  // Node 2 can be reached from 1 with mask=100 or mask=999
  // BFS should visit it with mask=100 first, ignoring the second path
  let successors = fn(node: #(Int, Int)) {
    let #(pos, _mask) = node
    case pos {
      1 -> [#(2, 100), #(2, 999)]
      // Both paths to same position!
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #(1, 0),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      with: fn(acc, node, _meta) { #(Continue, [node, ..acc]) },
    )

  // Should visit node 1 and node 2 (with mask=100, first visit)
  result
  |> list.length()
  |> should.equal(2)

  // Find the node with position 2
  let node2 =
    result
    |> list.find(fn(node) { node.0 == 2 })

  node2
  |> should.equal(Ok(#(2, 100)))
  // First visit wins!
}

// Test implicit_fold_by with string keys on complex nodes
// Node is #(room, health, gold) but we dedupe by room name only
pub fn implicit_fold_by_string_key_test() {
  let successors = fn(state: #(String, Int, Int)) {
    let #(room, health, gold) = state
    case room {
      "start" -> [
        #("armory", health, gold + 10),
        #("dungeon", health - 5, gold + 50),
      ]
      "armory" -> [#("boss", health + 20, gold)]
      "dungeon" -> [#("boss", health, gold + 20)]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #("start", 100, 0),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(state) { state.0 },
      // Dedupe by room name
      with: fn(acc, state, _meta) { #(Continue, [state, ..acc]) },
    )

  // Should visit 4 unique rooms
  result
  |> list.length()
  |> should.equal(4)

  // All rooms visited
  result
  |> list.map(fn(s) { s.0 })
  |> list.sort(by: string.compare)
  |> should.equal(["armory", "boss", "dungeon", "start"])
}

// Test implicit_fold_by with DFS (not just BFS)
pub fn implicit_fold_by_dfs_test() {
  let successors = fn(node: #(Int, String)) {
    let #(pos, _extra) = node
    case pos {
      1 -> [#(2, "a"), #(3, "b")]
      2 -> [#(4, "c")]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #(1, "start"),
      using: DepthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      with: fn(acc, node, _meta) { #(Continue, [node.0, ..acc]) },
    )

  // DFS order: 1 -> 2 -> 4 -> 3
  result
  |> should.equal([3, 4, 2, 1])
}

// Test implicit_fold_by with Stop control
pub fn implicit_fold_by_stop_control_test() {
  let successors = fn(node: #(Int, Int)) {
    let #(pos, mask) = node
    case pos {
      1 -> [#(2, mask), #(3, mask)]
      2 -> [#(4, mask)]
      3 -> [#(5, mask)]
      _ -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #(1, 0),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      with: fn(acc, node, _meta) {
        let #(pos, _) = node
        case pos == 2 {
          True -> #(Stop, [pos, ..acc])
          // Don't explore from 2
          False -> #(Continue, [pos, ..acc])
        }
      },
    )

  // Should visit 1, 2, 3, 5 but NOT 4 (stopped at 2)
  result
  |> list.sort(by: int.compare)
  |> should.equal([1, 2, 3, 5])
}

// Test implicit_fold_by with Halt control
pub fn implicit_fold_by_halt_control_test() {
  let successors = fn(node: #(Int, Bool)) {
    let #(pos, flag) = node
    case pos < 5 {
      True -> [#(pos + 1, flag)]
      False -> []
    }
  }

  let result =
    traversal.implicit_fold_by(
      from: #(1, False),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      with: fn(acc, node, _meta) {
        let #(pos, _) = node
        case pos == 3 {
          True -> #(Halt, [pos, ..acc])
          // Halt entire traversal
          False -> #(Continue, [pos, ..acc])
        }
      },
    )

  // Should only visit 1, 2, 3 (halted at 3)
  result
  |> list.sort(by: int.compare)
  |> should.equal([1, 2, 3])
}

// Test implicit_fold_by preserves metadata (depth, parent)
pub fn implicit_fold_by_metadata_test() {
  let successors = fn(node: #(Int, String)) {
    let #(pos, _) = node
    case pos {
      1 -> [#(2, "x"), #(3, "y")]
      2 -> [#(4, "z")]
      _ -> []
    }
  }

  let depths =
    traversal.implicit_fold_by(
      from: #(1, "root"),
      using: BreadthFirst,
      initial: dict.new(),
      successors_of: successors,
      visited_by: fn(node) { node.0 },
      with: fn(acc, node, meta) {
        #(Continue, dict.insert(acc, node.0, meta.depth))
      },
    )

  depths
  |> dict.get(1)
  |> should.equal(Ok(0))

  depths
  |> dict.get(2)
  |> should.equal(Ok(1))

  depths
  |> dict.get(4)
  |> should.equal(Ok(2))
}

// Test implicit_fold_by with tuple as key
// Node is #(x, y, steps, gold) but we dedupe by #(x, y) only
pub fn implicit_fold_by_tuple_key_test() {
  let successors = fn(node: #(Int, Int, Int, Int)) {
    let #(x, y, steps, gold) = node
    [#(x + 1, y, steps + 1, gold), #(x, y + 1, steps + 1, gold + 5)]
    |> list.filter(fn(n) { n.0 <= 2 && n.1 <= 2 })
  }

  let result =
    traversal.implicit_fold_by(
      from: #(0, 0, 0, 0),
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(node) { #(node.0, node.1) },
      // Dedupe by position tuple
      with: fn(acc, node, _meta) { #(Continue, [node, ..acc]) },
    )

  // Should visit all 9 positions in 3x3 grid exactly once
  result
  |> list.length()
  |> should.equal(9)

  // Verify all positions covered
  let positions =
    result
    |> list.map(fn(n) { #(n.0, n.1) })
    |> set.from_list()

  set.contains(positions, #(0, 0))
  |> should.be_true()

  set.contains(positions, #(2, 2))
  |> should.be_true()
}

// Test that implicit_fold_by behaves like implicit_fold when key is identity
pub fn implicit_fold_by_identity_key_test() {
  let successors = fn(n: Int) {
    case n < 4 {
      True -> [n + 1]
      False -> []
    }
  }

  let result_by =
    traversal.implicit_fold_by(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      visited_by: fn(n) { n },
      // Identity function
      with: fn(acc, n, _meta) { #(Continue, [n, ..acc]) },
    )

  let result_regular =
    traversal.implicit_fold(
      from: 1,
      using: BreadthFirst,
      initial: [],
      successors_of: successors,
      with: fn(acc, n, _meta) { #(Continue, [n, ..acc]) },
    )

  // Should produce identical results
  result_by
  |> should.equal(result_regular)
}
