import gleam/int
import gleam/option.{None, Some}
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/bidirectional
import yog/pathfinding/dijkstra
import yog/pathfinding/path.{Path}

// ============= Basic BFS Tests =============

/// Simple linear path: 1 -> 2 -> 3
pub fn bfs_linear_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 3)

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 2)))
}

/// Direct edge exists
pub fn bfs_direct_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 1)])

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 2)

  result
  |> should.equal(Some(Path(nodes: [1, 2], total_weight: 1)))
}

/// Start and goal are the same node
pub fn bfs_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 1)

  result
  |> should.equal(Some(Path(nodes: [1], total_weight: 0)))
}

/// No path exists (disconnected nodes)
pub fn bfs_no_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1)])
  // No edge to node 3

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 3)

  result
  |> should.equal(None)
}

/// Diamond pattern - multiple paths
///   1 -> 2 -> 4
///    \       /
///     -> 3 ->
pub fn bfs_diamond_pattern_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(3, 4, 1)])

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 4)

  // Should find one of the two shortest paths (both have length 2)
  result
  |> option.map(fn(path) { path.total_weight })
  |> should.equal(Some(2))
}

/// Longer path - test search meets in the middle
pub fn bfs_long_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 6, 1),
    ])

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 6)

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3, 4, 5, 6], total_weight: 5)))
}

/// Undirected graph - bidirectional should work both ways
pub fn bfs_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  // Forward direction
  let forward =
    bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 3)

  forward
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 2)))

  // Reverse direction
  let reverse =
    bidirectional.shortest_path_unweighted(in: graph, from: 3, to: 1)

  reverse
  |> should.equal(Some(Path(nodes: [3, 2, 1], total_weight: 2)))
}

/// Grid-like structure
pub fn bfs_grid_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    // Grid connections: 1-2-3
    //                   |   |
    //                   4-5-6
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(1, 4, 1),
      #(4, 5, 1),
      #(2, 5, 1),
      #(5, 6, 1),
      #(3, 6, 1),
    ])

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 6)

  // Multiple paths of length 3 exist
  result
  |> option.map(fn(path) { path.total_weight })
  |> should.equal(Some(3))
}

// ============= Weighted Dijkstra Tests =============

/// Simple linear path with weights
pub fn dijkstra_linear_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 15)))
}

/// Two paths, one is shorter
///   1 --(5)--> 2 --(10)--> 3
///    \                    /
///     --------(20)--------
pub fn dijkstra_multiple_paths_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10), #(1, 3, 20)])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 15)))
}

/// Direct path is shorter than indirect
pub fn dijkstra_direct_shorter_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 15), #(2, 3, 15), #(1, 3, 10)])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 3], total_weight: 10)))
}

/// Same node
pub fn dijkstra_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1], total_weight: 0)))
}

/// No path exists
pub fn dijkstra_no_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5)])
  // No edge to node 3

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(None)
}

/// Complex diamond with weights
///     2 --(3)--> 4
///    /          / \
///   1           |  6
///    \          \ /
///     3 --(1)--> 5
pub fn dijkstra_complex_diamond_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 1),
      #(2, 4, 3),
      #(3, 5, 1),
      #(4, 6, 1),
      #(5, 6, 1),
    ])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path should be 1 -> 3 -> 5 -> 6 (total: 3)
  result
  |> should.equal(Some(Path(nodes: [1, 3, 5, 6], total_weight: 3)))
}

/// Long chain
pub fn dijkstra_long_chain_test() {
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
      #(1, 2, 2),
      #(2, 3, 3),
      #(3, 4, 1),
      #(4, 5, 4),
      #(5, 6, 2),
      #(6, 7, 1),
      #(7, 8, 3),
    ])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 8,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3, 4, 5, 6, 7, 8], total_weight: 16)))
}

/// Undirected weighted graph
pub fn dijkstra_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 15)))
}

// ============= Comparison Tests with Standard Dijkstra =============

/// Verify bidirectional gives same result as standard Dijkstra
pub fn compare_with_standard_dijkstra_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 4),
      #(1, 3, 2),
      #(2, 4, 5),
      #(3, 4, 8),
      #(3, 5, 10),
      #(4, 5, 2),
    ])

  let bidirectional_result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let standard_result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Both should find the same shortest distance
  case bidirectional_result, standard_result {
    Some(bi), Some(std) ->
      bi.total_weight
      |> should.equal(std.total_weight)
    _, _ -> should.fail()
  }
}

/// Verify on complex graph
pub fn compare_complex_graph_test() {
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
      #(1, 2, 7),
      #(1, 3, 9),
      #(1, 6, 14),
      #(2, 3, 10),
      #(2, 4, 15),
      #(3, 4, 11),
      #(3, 6, 2),
      #(4, 5, 6),
      #(5, 7, 9),
      #(6, 7, 14),
    ])

  let bidirectional_result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 7,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let standard_result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 7,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case bidirectional_result, standard_result {
    Some(bi), Some(std) ->
      bi.total_weight
      |> should.equal(std.total_weight)
    _, _ -> should.fail()
  }
}

// ============= Convenience Wrapper Tests =============

/// Test integer convenience wrapper
pub fn shortest_path_int_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result = bidirectional.shortest_path_int(in: graph, from: 1, to: 3)

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 15)))
}

/// Test float convenience wrapper
pub fn shortest_path_float_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5.5), #(2, 3, 10.5)])

  let result = bidirectional.shortest_path_float(in: graph, from: 1, to: 3)

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 16.0)))
}

// ============= Edge Cases =============

/// Single node graph
pub fn single_node_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 1)

  result
  |> should.equal(Some(Path(nodes: [1], total_weight: 0)))
}

/// Two disconnected components
pub fn disconnected_components_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 1)])
  // 1->2 and 3->4 are disconnected

  let result = bidirectional.shortest_path_unweighted(in: graph, from: 1, to: 4)

  result
  |> should.equal(None)
}

/// Graph with cycle
pub fn graph_with_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10), #(3, 1, 2), #(2, 4, 3)])

  let result =
    bidirectional.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 4], total_weight: 8)))
}
