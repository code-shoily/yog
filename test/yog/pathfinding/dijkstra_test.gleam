import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/internal/util as internal_utils
import yog/model.{Directed, Undirected}
import yog/pathfinding/dijkstra
import yog/pathfinding/path.{Path}

// ============= Basic Path Tests =============

// Simple linear path: 1 -> 2 -> 3
pub fn shortest_path_linear_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result =
    dijkstra.shortest_path(
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

// Direct path exists
pub fn shortest_path_direct_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 10)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2], total_weight: 10)))
}

// Start and goal are the same
pub fn shortest_path_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    dijkstra.shortest_path(
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

// No path exists
pub fn shortest_path_no_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5)])
  // No edge to node 3

  let result =
    dijkstra.shortest_path(
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

// Start node doesn't exist
pub fn shortest_path_invalid_start_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 99,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(None)
}

// Goal node doesn't exist
pub fn shortest_path_invalid_goal_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 99,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(None)
}

// ============= Multiple Path Tests =============

// Two paths, one is shorter
//   1 --(5)--> 2 --(10)--> 3
//    \                    /
//     --------(20)-------
pub fn shortest_path_two_paths_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10), #(1, 3, 20)])

  let result =
    dijkstra.shortest_path(
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

// Direct path is shorter than indirect
//   1 --(5)--> 3
//    \        /
//     --(2)--> 2 --(10)--
pub fn shortest_path_direct_shorter_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 3, 5), #(1, 2, 2), #(2, 3, 10)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 3], total_weight: 5)))
}

// Diamond graph - multiple paths
//      1
//     / \
//   (2) (3)
//   /     \
//  2       3
//  |       |
// (4)     (5)
//   \     /
//     \ /
//      4
pub fn shortest_path_diamond_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edges([#(1, 2, 2), #(1, 3, 3), #(2, 4, 4), #(3, 4, 5)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path through left is 2+4=6, path through right is 3+5=8
  result
  |> should.equal(Some(Path(nodes: [1, 2, 4], total_weight: 6)))
}

// ============= Complex Graph Tests =============

// Grid-like graph with multiple routes
pub fn shortest_path_grid_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([
      // Row 1
      #(1, 2, 1),
      #(2, 3, 1),
      // Row 2
      #(4, 5, 1),
      #(5, 6, 1),
      // Columns
      #(1, 4, 10),
      #(2, 5, 1),
      #(3, 6, 10),
    ])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Best path: 1->2->5->6 with weight 1+1+1=3
  result
  |> should.equal(Some(Path(nodes: [1, 2, 5, 6], total_weight: 3)))
}

// Graph with cycle
pub fn shortest_path_with_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])
  // Cycle: 1->2->3->1

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find direct path, not loop around
  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 2)))
}

// ============= Undirected Graph Tests =============

pub fn shortest_path_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  // In undirected graph, can go backwards
  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 3,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [3, 2, 1], total_weight: 15)))
}

// ============= Float Weight Tests =============

pub fn shortest_path_float_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 5.0)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  case result {
    Some(path) -> {
      path.nodes
      |> should.equal([1, 2, 3])

      // Check weight is approximately 4.0
      { path.total_weight >. 3.99 && path.total_weight <. 4.01 }
      |> should.be_true()
    }
    None -> should.fail()
  }
}

// ============= Edge Cases =============

// Zero weight edges
pub fn shortest_path_zero_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 0), #(2, 3, 0)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3], total_weight: 0)))
}

// Single node graph
pub fn shortest_path_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    dijkstra.shortest_path(
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

// Empty graph
pub fn shortest_path_empty_graph_test() {
  let graph = model.new(Directed)

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(None)
}

// Self-loop
pub fn shortest_path_with_self_loop_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, 5), #(1, 2, 10)])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take direct path, not loop
  result
  |> should.equal(Some(Path(nodes: [1, 2], total_weight: 10)))
}

// ============= Classic Test Cases =============

// Classic "why Dijkstra" example - greedy fails but Dijkstra succeeds
//      1
//     /|\
//   (1)(2)(4)
//   /  |  \
//  2   3   4
//  |   |
// (9) (2)
//  |   |
//  5   5
pub fn shortest_path_classic_dijkstra_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_node(5, "Goal")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 4),
      #(2, 5, 9),
      #(3, 5, 2),
    ])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Greedy would pick 1->2->5 (cost 10)
  // Dijkstra finds 1->3->5 (cost 4)
  result
  |> should.equal(Some(Path(nodes: [1, 3, 5], total_weight: 4)))
}

// Longer path test
pub fn shortest_path_long_chain_test() {
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
      #(2, 3, 1),
      #(3, 4, 1),
      #(4, 5, 1),
      #(5, 6, 1),
    ])

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(Path(nodes: [1, 2, 3, 4, 5, 6], total_weight: 5)))
}

// Disconnected components
pub fn shortest_path_disconnected_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 1)])
  // Two disconnected components: {1,2} and {3,4}

  let result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(None)
}

// ============= Single Source Distances Tests =============

// Basic single source distances
pub fn single_source_distances_basic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 3), #(1, 4, 10)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should have distances to all reachable nodes
  distances
  |> dict.get(1)
  |> should.equal(Ok(0))

  distances
  |> dict.get(2)
  |> should.equal(Ok(5))

  distances
  |> dict.get(3)
  |> should.equal(Ok(8))

  distances
  |> dict.get(4)
  |> should.equal(Ok(10))
}

// Single source with unreachable nodes
pub fn single_source_distances_unreachable_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(3, 4, 10)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Can reach 1 and 2
  distances
  |> dict.get(1)
  |> should.equal(Ok(0))

  distances
  |> dict.get(2)
  |> should.equal(Ok(5))

  // Cannot reach 3 and 4
  distances
  |> dict.get(3)
  |> should.equal(Error(Nil))

  distances
  |> dict.get(4)
  |> should.equal(Error(Nil))
}

// Single source on complete graph
pub fn single_source_distances_complete_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 4), #(2, 3, 2)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  distances
  |> dict.get(1)
  |> should.equal(Ok(0))

  distances
  |> dict.get(2)
  |> should.equal(Ok(1))

  // Should use path 1->2->3 (cost 3) not 1->3 (cost 4)
  distances
  |> dict.get(3)
  |> should.equal(Ok(3))
}

// Single source from isolated node
pub fn single_source_distances_isolated_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 2, to: 3, with: 5)

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Only distance to self
  distances
  |> dict.size
  |> should.equal(1)

  distances
  |> dict.get(1)
  |> should.equal(Ok(0))
}

// Single source with cycles
pub fn single_source_distances_with_cycles_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find shortest paths despite cycle
  distances
  |> dict.get(1)
  |> should.equal(Ok(0))

  distances
  |> dict.get(2)
  |> should.equal(Ok(1))

  distances
  |> dict.get(3)
  |> should.equal(Ok(2))
}

// Single source on undirected graph
pub fn single_source_distances_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 3)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // All nodes reachable in undirected graph
  distances
  |> dict.get(1)
  |> should.equal(Ok(0))

  distances
  |> dict.get(2)
  |> should.equal(Ok(5))

  distances
  |> dict.get(3)
  |> should.equal(Ok(8))
}

// Single source with float weights
pub fn single_source_distances_float_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  case dict.get(distances, 1) {
    Ok(d) -> {
      { d >. -0.01 && d <. 0.01 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }

  case dict.get(distances, 3) {
    Ok(d) -> {
      { d >. 3.99 && d <. 4.01 }
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Single source empty graph
pub fn single_source_distances_empty_test() {
  let graph = model.new(Directed)

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Source doesn't exist in graph, but distance to itself is 0
  distances
  |> dict.size
  |> should.equal(1)

  distances
  |> dict.get(1)
  |> should.equal(Ok(0))
}

// Finding closest target among multiple options
pub fn single_source_distances_find_closest_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Source")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_edges([#(1, 2, 10), #(1, 3, 5), #(3, 4, 20)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Find closest target among 2, 3, 4
  let targets = [2, 3, 4]
  let closest =
    targets
    |> list.filter_map(fn(t) { dict.get(distances, t) })
    |> list.sort(int.compare)
    |> list.first

  closest
  |> should.equal(Ok(5))
}

// Large star graph (one center, many spokes)
pub fn single_source_distances_star_test() {
  let graph =
    internal_utils.range(1, 10)
    |> list.fold(model.new(Directed), fn(g, i) {
      let assert Ok(g) =
        g
        |> model.add_node(0, "Center")
        |> model.add_node(i, "Node")
        |> model.add_edge(from: 0, to: i, with: i)
      g
    })

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 0,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // All spokes directly reachable
  distances
  |> dict.size
  |> should.equal(11)

  // Distance to each spoke equals its ID
  distances
  |> dict.get(5)
  |> should.equal(Ok(5))
}

// Comparison with individual shortest_path calls
pub fn single_source_distances_vs_shortest_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 3), #(1, 4, 10)])

  let distances =
    dijkstra.single_source_distances(
      in: graph,
      from: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Verify against individual shortest_path calls
  let targets = [2, 3, 4]
  targets
  |> list.each(fn(target) {
    let expected =
      dijkstra.shortest_path(
        in: graph,
        from: 1,
        to: target,
        with_zero: 0,
        with_add: int.add,
        with_compare: int.compare,
      )

    case expected {
      Some(path) -> {
        dict.get(distances, target)
        |> should.equal(Ok(path.total_weight))
      }
      None -> {
        dict.get(distances, target)
        |> should.equal(Error(Nil))
      }
    }
  })
}

// ============= Implicit Dijkstra Tests =============

// Simple linear implicit graph: states 1->2->3->4->5
pub fn implicit_dijkstra_linear_test() {
  let successors = fn(n: Int) {
    case n < 5 {
      True -> [#(n + 1, 10)]
      False -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 5 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(40))
}

// Test with multiple paths - should find shortest
pub fn implicit_dijkstra_multiple_paths_test() {
  // State is position, edges have different costs
  let successors = fn(pos: Int) {
    case pos {
      1 -> [#(2, 100), #(3, 10)]
      // Two paths: expensive direct, cheap via 3
      2 -> [#(4, 1)]
      3 -> [#(2, 5)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 2 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take path 1->3->2 (cost 15) not 1->2 (cost 100)
  result |> should.equal(Some(15))
}

// Test with grid-like state space (using tuples for position)
pub fn implicit_dijkstra_grid_test() {
  let successors = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    [
      #(#(x + 1, y), 1),
      #(#(x - 1, y), 1),
      #(#(x, y + 1), 1),
      #(#(x, y - 1), 1),
    ]
    |> list.filter(fn(next) { next.0.0 >= 0 && next.0.1 >= 0 })
    |> list.filter(fn(next) { next.0.0 <= 3 && next.0.1 <= 3 })
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: #(0, 0),
      successors_with_cost: successors,
      is_goal: fn(pos) { pos.0 == 3 && pos.1 == 3 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Manhattan distance from (0,0) to (3,3) is 6
  result |> should.equal(Some(6))
}

// Test with no path to goal
pub fn implicit_dijkstra_no_path_test() {
  let successors = fn(n: Int) {
    case n < 3 {
      True -> [#(n + 1, 1)]
      False -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 10 },
      // Goal unreachable
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(None)
}

// Test with start == goal
pub fn implicit_dijkstra_start_is_goal_test() {
  let successors = fn(n: Int) { [#(n + 1, 10)] }

  let result =
    dijkstra.implicit_dijkstra(
      from: 42,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 42 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(0))
}

// Test with weighted edges (non-uniform)
pub fn implicit_dijkstra_weighted_test() {
  let successors = fn(n: Int) {
    case n {
      1 -> [#(2, 5), #(3, 100)]
      2 -> [#(3, 10)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 3 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take path 1->2->3 (cost 15) not 1->3 (cost 100)
  result |> should.equal(Some(15))
}

// Test with cycle (should handle correctly)
pub fn implicit_dijkstra_with_cycle_test() {
  let successors = fn(n: Int) {
    case n {
      1 -> [#(2, 10)]
      2 -> [#(3, 5), #(1, 1)]
      // Cycle back to 1
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(16))
}

// Test with float costs
pub fn implicit_dijkstra_float_costs_test() {
  let successors = fn(n: Int) {
    case n {
      1 -> [#(2, 1.5), #(3, 10.0)]
      2 -> [#(3, 2.5)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 3 },
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  result |> should.equal(Some(4.0))
}

// ============= Implicit Dijkstra By Tests =============

// Test deduplication by position while carrying extra state
pub fn implicit_dijkstra_by_position_mask_test() {
  // State is #(position, mask) but dedupe by position only
  let successors = fn(state: #(Int, Int)) {
    let #(pos, mask) = state
    case pos {
      1 -> [#(#(2, mask + 1), 10), #(#(3, mask + 100), 5)]
      2 -> [#(#(4, mask + 1), 1)]
      3 -> [#(#(4, mask + 100), 2)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(1, 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      // Dedupe by position only
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find path 1->3->4 (cost 7) even though masks differ
  result |> should.equal(Some(7))
}

// Test that first visit wins when deduping by key
pub fn implicit_dijkstra_by_first_visit_wins_test() {
  // Two paths to position 2 with different masks
  let successors = fn(state: #(Int, String)) {
    let #(pos, _metadata) = state
    case pos {
      1 -> [#(#(2, "fast"), 5), #(#(2, "slow"), 100)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 2 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take cheaper path (cost 5)
  result |> should.equal(Some(5))
}

// Test with complex state carrying path history
pub fn implicit_dijkstra_by_with_history_test() {
  // State is #(pos, history)
  let successors = fn(state: #(Int, List(Int))) {
    let #(pos, history) = state
    case pos {
      1 -> [#(2, [1, ..history]), #(3, [1, ..history])]
      2 -> [#(4, [2, ..history])]
      3 -> [#(4, [3, ..history])]
      _ -> []
    }
    |> list.map(fn(s) { #(s, 1) })
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(1, []),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      // Dedupe by position
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(2))
}

// Test with tuple as deduplication key
pub fn implicit_dijkstra_by_tuple_key_test() {
  // State is #(x, y, collected_items) but dedupe by #(x, y)
  let successors = fn(state: #(Int, Int, Int)) {
    let #(x, y, items) = state
    [#(x + 1, y, items), #(x, y + 1, items + 1)]
    |> list.filter(fn(s) { s.0 <= 2 && s.1 <= 2 })
    |> list.map(fn(s) { #(s, 1) })
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(0, 0, 0),
      successors_with_cost: successors,
      visited_by: fn(state) { #(state.0, state.1) },
      is_goal: fn(state) { state.0 == 2 && state.1 == 2 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(4))
}

// Test that _by version behaves like regular when key is identity
pub fn implicit_dijkstra_by_identity_key_test() {
  let successors = fn(n: Int) {
    case n < 5 {
      True -> [#(n + 1, 3)]
      False -> []
    }
  }

  let result_by =
    dijkstra.implicit_dijkstra_by(
      from: 1,
      successors_with_cost: successors,
      visited_by: fn(n) { n },
      // Identity
      is_goal: fn(n) { n == 5 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let result_regular =
    dijkstra.implicit_dijkstra(
      from: 1,
      successors_with_cost: successors,
      is_goal: fn(n) { n == 5 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result_by |> should.equal(result_regular)
  result_by |> should.equal(Some(12))
}

// Test with no path using _by
pub fn implicit_dijkstra_by_no_path_test() {
  let successors = fn(state: #(Int, String)) {
    let #(pos, tag) = state
    case pos < 3 {
      True -> [#(#(pos + 1, tag), 1)]
      False -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 10 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(None)
}

// Test with start == goal using _by
pub fn implicit_dijkstra_by_start_is_goal_test() {
  let successors = fn(state: #(Int, Int)) { [#(#(state.0 + 1, state.1), 1)] }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(5, 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 5 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(0))
}

// AoC-style test: simplified key collection
pub fn implicit_dijkstra_by_key_collection_test() {
  // Simplified version of key collection problem
  // State is #(at_key, collected_mask)
  // Keys: "a"=bit 0, "b"=bit 1
  let successors = fn(state: #(String, Int)) {
    let #(at, collected) = state
    case at {
      "@" -> [#("a", collected), #("b", collected)]
      "a" -> [#("@", int.bitwise_or(collected, 1))]
      // Collect key a (bit 0)
      "b" -> [#("@", int.bitwise_or(collected, 2))]
      // Collect key b (bit 1)
      _ -> []
    }
    |> list.map(fn(s) { #(s, 1) })
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #("@", 0),
      successors_with_cost: successors,
      visited_by: fn(state) { #(state.0, state.1) },
      // Dedupe by both
      is_goal: fn(state) { state.1 == 3 },
      // Both keys collected
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(4))
}

// Test diamond pattern with different costs
pub fn implicit_dijkstra_by_diamond_test() {
  let successors = fn(state: #(Int, String)) {
    let #(pos, label) = state
    case pos {
      1 -> [#(#(2, label <> "->2"), 1), #(#(3, label <> "->3"), 10)]
      2 -> [#(#(4, label <> "->4"), 1)]
      3 -> [#(#(4, label <> "->4"), 1)]
      _ -> []
    }
  }

  let result =
    dijkstra.implicit_dijkstra_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take cheaper path through node 2 (cost 2) not 3 (cost 11)
  result |> should.equal(Some(2))
}
