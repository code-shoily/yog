import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/multi/model as multi
import yog/multi/traversal.{Continue, Halt, Stop}

// Test graph:
//     1 --e0--> 2
//     |         |
//    e1        e2
//     |         |
//     v         v
//     3 --e3--> 4
//
// With parallel edges from 1->2 (e0 and e4)

fn build_test_graph() {
  let g = multi.directed()
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "e0")
  let #(g, _) = multi.add_edge(g, from: 1, to: 3, with: "e1")
  let #(g, _) = multi.add_edge(g, from: 2, to: 4, with: "e2")
  let #(g, _) = multi.add_edge(g, from: 3, to: 4, with: "e3")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "e4")
  g
}

// Undirected graph:
//     1 --e0-- 2
//     |        |
//    e1       e2
//     |        |
//     3 --e3-- 4

fn build_undirected_graph() {
  let g = multi.undirected()
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "e0")
  let #(g, _) = multi.add_edge(g, from: 1, to: 3, with: "e1")
  let #(g, _) = multi.add_edge(g, from: 2, to: 4, with: "e2")
  let #(g, _) = multi.add_edge(g, from: 3, to: 4, with: "e3")
  g
}

pub fn bfs_directed_test() {
  let g = build_test_graph()
  let result = traversal.bfs(g, 1)

  // BFS should visit all reachable nodes
  list.length(result) |> should.equal(4)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  list.contains(result, 4) |> should.be_true()

  // First node should be the start
  list.first(result) |> should.equal(Ok(1))
}

pub fn bfs_from_middle_test() {
  let g = build_test_graph()
  let result = traversal.bfs(g, 2)

  result |> should.equal([2, 4])
}

pub fn bfs_undirected_test() {
  let g = build_undirected_graph()
  let result = traversal.bfs(g, 1)

  // Should visit all nodes from node 1
  list.length(result) |> should.equal(4)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  list.contains(result, 4) |> should.be_true()
}

pub fn dfs_directed_test() {
  let g = build_test_graph()
  let result = traversal.dfs(g, 1)

  // DFS should visit all reachable nodes
  list.length(result) |> should.equal(4)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  list.contains(result, 4) |> should.be_true()

  // First node should be the start
  list.first(result) |> should.equal(Ok(1))
}

pub fn dfs_from_leaf_test() {
  let g = build_test_graph()
  let result = traversal.dfs(g, 4)

  // Node 4 has no outgoing edges
  result |> should.equal([4])
}

pub fn dfs_undirected_test() {
  let g = build_undirected_graph()
  let result = traversal.dfs(g, 1)

  // Should visit all nodes
  list.length(result) |> should.equal(4)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  list.contains(result, 4) |> should.be_true()
}

pub fn bfs_empty_graph_test() {
  let g = multi.directed()
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "e0")

  // Start from non-existent node
  let result = traversal.bfs(g, 99)
  result |> should.equal([99])
}

pub fn bfs_with_parallel_edges_test() {
  // Graph with multiple parallel edges
  let g = multi.directed()
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "b")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "c")

  let result = traversal.bfs(g, 1)

  // Should visit 1, then 2 (only once despite 3 edges)
  result |> should.equal([1, 2])
}

pub fn dfs_with_parallel_edges_test() {
  // Graph with multiple parallel edges
  let g = multi.directed()
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "b")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "c")

  let result = traversal.dfs(g, 1)

  // Should visit 1, then 2 (only once despite 3 edges)
  result |> should.equal([1, 2])
}

// ---------------------------------------------------------------------------
// fold_walk tests
// ---------------------------------------------------------------------------

pub fn fold_walk_collect_nodes_test() {
  let g = build_test_graph()
  let result =
    traversal.fold_walk(over: g, from: 1, initial: [], with: fn(acc, node, _) {
      #(Continue, [node, ..acc])
    })

  list.length(result) |> should.equal(4)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  list.contains(result, 4) |> should.be_true()
}

pub fn fold_walk_with_metadata_test() {
  let g = build_test_graph()

  // Build a depth map
  let depth_map =
    traversal.fold_walk(
      over: g,
      from: 1,
      initial: dict.new(),
      with: fn(acc, node, meta) {
        #(Continue, dict.insert(acc, node, meta.depth))
      },
    )

  dict.get(depth_map, 1) |> should.equal(Ok(0))
  dict.get(depth_map, 2) |> should.equal(Ok(1))
  dict.get(depth_map, 3) |> should.equal(Ok(1))
  dict.get(depth_map, 4) |> should.equal(Ok(2))
}

pub fn fold_walk_parent_tracking_test() {
  let g = build_test_graph()

  // Build a parent map with edge IDs
  let parent_map =
    traversal.fold_walk(
      over: g,
      from: 1,
      initial: dict.new(),
      with: fn(acc, node, meta) {
        let new_acc = case meta.parent {
          Some(#(parent_node, edge_id)) ->
            dict.insert(acc, node, #(parent_node, edge_id))
          None -> acc
        }
        #(Continue, new_acc)
      },
    )

  // Node 1 has no parent
  dict.has_key(parent_map, 1) |> should.be_false()

  // Nodes 2 and 3 have parent 1
  case dict.get(parent_map, 2) {
    Ok(#(parent, _edge)) -> parent |> should.equal(1)
    _ -> should.fail()
  }

  case dict.get(parent_map, 3) {
    Ok(#(parent, _edge)) -> parent |> should.equal(1)
    _ -> should.fail()
  }

  // Node 4 has parent 2 or 3
  case dict.get(parent_map, 4) {
    Ok(#(parent, _edge)) -> {
      { parent == 2 || parent == 3 } |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn fold_walk_halt_test() {
  let g = build_test_graph()

  // Stop when we find node 2
  let result =
    traversal.fold_walk(
      over: g,
      from: 1,
      initial: [],
      with: fn(acc, node, _meta) {
        let new_acc = [node, ..acc]
        case node == 2 {
          True -> #(Halt, new_acc)
          False -> #(Continue, new_acc)
        }
      },
    )

  // Should have visited 1 and 2, then halted
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  // Should NOT have visited all nodes (halted early)
  list.length(result) |> should.not_equal(4)
}

pub fn fold_walk_stop_test() {
  let g = build_test_graph()

  // Don't explore from node 2 (but continue with other nodes)
  let result =
    traversal.fold_walk(
      over: g,
      from: 1,
      initial: [],
      with: fn(acc, node, _meta) {
        case node == 2 {
          True -> #(Stop, [node, ..acc])
          False -> #(Continue, [node, ..acc])
        }
      },
    )

  // Should have visited 1, 2, 3
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()

  // Node 4 might or might not be visited depending on whether we reached it from node 3
  // (This test is checking that Stop doesn't halt entirely)
  list.length(result) |> should.equal(4)
}

pub fn fold_walk_depth_limit_test() {
  let g = build_test_graph()

  // Collect only nodes within depth 1
  let result =
    traversal.fold_walk(
      over: g,
      from: 1,
      initial: [],
      with: fn(acc, node, meta) {
        case meta.depth <= 1 {
          True -> #(Continue, [node, ..acc])
          False -> #(Stop, acc)
        }
      },
    )

  // Should have 1, 2, 3 (depth 0 and 1)
  list.contains(result, 1) |> should.be_true()
  list.contains(result, 2) |> should.be_true()
  list.contains(result, 3) |> should.be_true()
  // Should NOT have 4 (depth 2)
  list.contains(result, 4) |> should.be_false()
}
