import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/internal/utils
import yog/model.{Directed, Undirected}
import yog/pathfinding

// ============= Basic Path Tests =============

// Simple linear path: 1 -> 2 -> 3
pub fn shortest_path_linear_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 15)))
}

// Direct path exists
pub fn shortest_path_direct_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2], total_weight: 10)))
}

// Start and goal are the same
pub fn shortest_path_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1], total_weight: 0)))
}

// No path exists
pub fn shortest_path_no_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
  // No edge to node 3

  let result =
    pathfinding.shortest_path(
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
    pathfinding.shortest_path(
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
    pathfinding.shortest_path(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 20)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 15)))
}

// Direct path is shorter than indirect
//   1 --(5)--> 3
//    \        /
//     --(2)--> 2 --(10)--
pub fn shortest_path_direct_shorter_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 3, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 3], total_weight: 5)))
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 1, to: 3, with: 3)
    |> model.add_edge(from: 2, to: 4, with: 4)
    |> model.add_edge(from: 3, to: 4, with: 5)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path through left is 2+4=6, path through right is 3+5=8
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 4], total_weight: 6)))
}

// ============= Complex Graph Tests =============

// Grid-like graph with multiple routes
pub fn shortest_path_grid_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    // Row 1
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    // Row 2
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    // Columns
    |> model.add_edge(from: 1, to: 4, with: 10)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 3, to: 6, with: 10)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Best path: 1->2->5->6 with weight 1+1+1=3
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 5, 6], total_weight: 3)))
}

// Graph with cycle
pub fn shortest_path_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)
  // Cycle: 1->2->3->1

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find direct path, not loop around
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 2)))
}

// ============= Undirected Graph Tests =============

pub fn shortest_path_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  // In undirected graph, can go backwards
  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 3,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [3, 2, 1], total_weight: 15)))
}

// ============= Float Weight Tests =============

pub fn shortest_path_float_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1.5)
    |> model.add_edge(from: 2, to: 3, with: 2.5)
    |> model.add_edge(from: 1, to: 3, with: 5.0)

  let result =
    pathfinding.shortest_path(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 0)
    |> model.add_edge(from: 2, to: 3, with: 0)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 0)))
}

// Single node graph
pub fn shortest_path_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1], total_weight: 0)))
}

// Empty graph
pub fn shortest_path_empty_graph_test() {
  let graph = model.new(Directed)

  let result =
    pathfinding.shortest_path(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take direct path, not loop
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2], total_weight: 10)))
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_node(5, "Goal")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 1, to: 4, with: 4)
    |> model.add_edge(from: 2, to: 5, with: 9)
    |> model.add_edge(from: 3, to: 5, with: 2)

  let result =
    pathfinding.shortest_path(
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
  |> should.equal(Some(pathfinding.Path(nodes: [1, 3, 5], total_weight: 4)))
}

// Longer path test
pub fn shortest_path_long_chain_test() {
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

  let result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    Some(pathfinding.Path(nodes: [1, 2, 3, 4, 5, 6], total_weight: 5)),
  )
}

// Disconnected components
pub fn shortest_path_disconnected_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
  // Two disconnected components: {1,2} and {3,4}

  let result =
    pathfinding.shortest_path(
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

// ============= A* Search Tests =============

// A* with zero heuristic (equivalent to Dijkstra)
pub fn astar_zero_heuristic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let zero_heuristic = fn(_from: Int, _to: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: zero_heuristic,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 15)))
}

// A* with Manhattan distance heuristic (grid)
pub fn astar_manhattan_distance_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "0,0")
    |> model.add_node(2, "1,0")
    |> model.add_node(3, "2,0")
    |> model.add_node(4, "0,1")
    |> model.add_node(5, "1,1")
    |> model.add_node(6, "2,1")
    // Grid connections (each edge cost 1)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 3, to: 6, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)

  // Manhattan distance heuristic
  // Node positions: 1=(0,0), 2=(1,0), 3=(2,0), 4=(0,1), 5=(1,1), 6=(2,1)
  let manhattan = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 6 -> 3
      // |0-2| + |0-1| = 3
      2, 6 -> 2
      // |1-2| + |0-1| = 2
      3, 6 -> 1
      // |2-2| + |0-1| = 1
      4, 6 -> 3
      // |0-2| + |1-1| = 2
      5, 6 -> 1
      // |1-2| + |1-1| = 1
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: manhattan,
    )

  case result {
    Some(path) -> {
      // Should find optimal path with cost 3
      path.total_weight
      |> should.equal(3)
    }
    None -> should.fail()
  }
}

// A* finds better path than greedy
pub fn astar_better_than_greedy_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "Goal")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 2, to: 4, with: 100)
    |> model.add_edge(from: 3, to: 4, with: 1)

  // Heuristic that prefers node 2 initially
  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      2, 4 -> 10
      // Underestimate for node 2
      3, 4 -> 1
      // Good estimate for node 3
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  // Should find path through 3, not 2 (cost 3 vs 101)
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 3, 4], total_weight: 3)))
}

// A* with same start and goal
pub fn astar_same_start_goal_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1], total_weight: 0)))
}

// A* with no path
pub fn astar_no_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(None)
}

// A* with admissible heuristic finds optimal path
pub fn astar_admissible_heuristic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    // Multiple paths from 1 to 5
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 3)
    |> model.add_edge(from: 3, to: 4, with: 2)
    |> model.add_edge(from: 4, to: 5, with: 1)

  // Admissible heuristic (never overestimates)
  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 5 -> 5
      2, 5 -> 4
      3, 5 -> 3
      4, 5 -> 1
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  // Should find optimal path 1->3->4->5 with cost 6
  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 3, 4, 5], total_weight: 6)))
}

// A* on diamond graph
pub fn astar_diamond_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 1, to: 3, with: 3)
    |> model.add_edge(from: 2, to: 4, with: 4)
    |> model.add_edge(from: 3, to: 4, with: 5)

  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 4 -> 5
      2, 4 -> 3
      3, 4 -> 4
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 4], total_weight: 6)))
}

// A* with float weights and heuristic
pub fn astar_float_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1.5)
    |> model.add_edge(from: 2, to: 3, with: 2.5)
    |> model.add_edge(from: 1, to: 3, with: 5.0)

  let h = fn(from: Int, to: Int) -> Float {
    case from, to {
      1, 3 -> 3.0
      2, 3 -> 2.0
      _, _ -> 0.0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
      heuristic: h,
    )

  case result {
    Some(path) -> {
      path.nodes
      |> should.equal([1, 2, 3])

      { path.total_weight >. 3.99 && path.total_weight <. 4.01 }
      |> should.be_true()
    }
    None -> should.fail()
  }
}

// A* with cycle detection
pub fn astar_with_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 2)))
}

// A* perfect heuristic (exact distance)
pub fn astar_perfect_heuristic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 10)

  // Perfect heuristic (exact remaining distance)
  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 4 -> 3
      2, 4 -> 2
      3, 4 -> 1
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3, 4], total_weight: 3)))
}

// A* on undirected graph
pub fn astar_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 3,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [3, 2, 1], total_weight: 15)))
}

// A* comparison with Dijkstra (should find same path)
pub fn astar_vs_dijkstra_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 2, to: 4, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 2)

  let h = fn(_: Int, _: Int) -> Int { 1 }

  let astar_result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  let dijkstra_result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Both should find same optimal path
  astar_result
  |> should.equal(dijkstra_result)
}

// A* empty graph
pub fn astar_empty_graph_test() {
  let graph = model.new(Directed)

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(None)
}

// A* with consistent heuristic (triangle inequality)
pub fn astar_consistent_heuristic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 5)
    |> model.add_edge(from: 1, to: 3, with: 20)

  // Consistent heuristic satisfies h(x) <= cost(x,y) + h(y)
  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 3 -> 8
      2, 3 -> 4
      _, _ -> 0
    }
  }

  let result =
    pathfinding.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: h,
    )

  result
  |> should.equal(Some(pathfinding.Path(nodes: [1, 2, 3], total_weight: 10)))
}

// ============= Bellman-Ford Tests =============

// Basic shortest path (no negative weights)
pub fn bellman_ford_basic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 10)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(
      nodes: [1, 2, 3],
      total_weight: 15,
    )),
  )
}

// Negative edge weights (still finds shortest path)
pub fn bellman_ford_negative_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: -5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1, 2, 3], total_weight: 5)),
  )
}

// Negative weights make different path optimal
pub fn bellman_ford_negative_optimal_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 4, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 4, with: -10)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path through 2,3 is 2+2-10=-6, direct is 5
  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(
      nodes: [1, 2, 3, 4],
      total_weight: -6,
    )),
  )
}

// Detects negative cycle
pub fn bellman_ford_negative_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 1, with: -5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(pathfinding.NegativeCycle)
}

// Negative cycle not reachable from source (should still find path)
pub fn bellman_ford_negative_cycle_elsewhere_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    // Negative cycle: 2->3->4->2 (unreachable from 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 2, with: -5)
    // Path from 1 to 5 (doesn't touch the cycle)
    |> model.add_edge(from: 1, to: 5, with: 10)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Cycle is unreachable from source, so path should be found
  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1, 5], total_weight: 10)),
  )
}

// No path exists
pub fn bellman_ford_no_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(pathfinding.NoPath)
}

// Same start and goal
pub fn bellman_ford_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1], total_weight: 0)),
  )
}

// Zero weight edges
pub fn bellman_ford_zero_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 0)
    |> model.add_edge(from: 2, to: 3, with: 0)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1, 2, 3], total_weight: 0)),
  )
}

// Mix of positive and negative weights
pub fn bellman_ford_mixed_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 4)
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 2, to: 4, with: 3)
    |> model.add_edge(from: 3, to: 2, with: -6)
    |> model.add_edge(from: 3, to: 4, with: 5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Best path: 1->3->2->4 with cost 2+(-6)+3=-1
  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(
      nodes: [1, 3, 2, 4],
      total_weight: -1,
    )),
  )
}

// Self-loop with negative weight (creates negative cycle)
pub fn bellman_ford_negative_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: -1)
    |> model.add_edge(from: 1, to: 2, with: 5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(pathfinding.NegativeCycle)
}

// Self-loop with positive weight (not a negative cycle)
pub fn bellman_ford_positive_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1, 2], total_weight: 10)),
  )
}

// Diamond graph with negative edge
pub fn bellman_ford_diamond_negative_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 4)
    |> model.add_edge(from: 2, to: 4, with: 2)
    |> model.add_edge(from: 3, to: 4, with: -3)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path through right: 4+(-3)=1, path through left: 1+2=3
  result
  |> should.equal(
    pathfinding.ShortestPath(pathfinding.Path(nodes: [1, 3, 4], total_weight: 1)),
  )
}

// Float weights with negatives
pub fn bellman_ford_float_negative_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 2.5)
    |> model.add_edge(from: 2, to: 3, with: -1.5)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  case result {
    pathfinding.ShortestPath(path) -> {
      path.nodes
      |> should.equal([1, 2, 3])

      { path.total_weight >. 0.99 && path.total_weight <. 1.01 }
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// Comparison with Dijkstra on non-negative graph
pub fn bellman_ford_vs_dijkstra_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 2, to: 4, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let bellman_result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let dijkstra_result =
    pathfinding.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case bellman_result, dijkstra_result {
    pathfinding.ShortestPath(bf_path), Some(dijk_path) -> {
      bf_path.total_weight
      |> should.equal(dijk_path.total_weight)

      bf_path.nodes
      |> should.equal(dijk_path.nodes)
    }
    _, _ -> should.fail()
  }
}

// Empty graph
pub fn bellman_ford_empty_graph_test() {
  let graph = model.new(Directed)

  let result =
    pathfinding.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(pathfinding.NoPath)
}

// ============= Single Source Distances Tests =============

// Basic single source distances
pub fn single_source_distances_basic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 4, with: 10)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 10)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 2)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 2, to: 3, with: 5)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 1, with: 1)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1.5)
    |> model.add_edge(from: 2, to: 3, with: 2.5)

  let distances =
    pathfinding.single_source_distances(
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
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Source")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 5)
    |> model.add_edge(from: 1, to: 4, with: 20)

  let distances =
    pathfinding.single_source_distances(
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
    utils.range(1, 10)
    |> list.fold(model.new(Directed), fn(g, i) {
      g
      |> model.add_node(0, "Center")
      |> model.add_node(i, "Node")
      |> model.add_edge(from: 0, to: i, with: i)
    })

  let distances =
    pathfinding.single_source_distances(
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
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 4, with: 10)

  let distances =
    pathfinding.single_source_distances(
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
      pathfinding.shortest_path(
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

// ============= Floyd-Warshall Tests =============

// Basic all-pairs shortest paths
pub fn floyd_warshall_basic_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 3, with: 10)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from 1 to 1 should be 0
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))

      // Distance from 1 to 2 should be 4
      dict.get(distances, #(1, 2)) |> should.equal(Ok(4))

      // Distance from 1 to 3 should be 7 (via 2, not direct 10)
      dict.get(distances, #(1, 3)) |> should.equal(Ok(7))

      // Distance from 2 to 3 should be 3
      dict.get(distances, #(2, 3)) |> should.equal(Ok(3))

      // No path from 3 to 1 (directed graph)
      dict.get(distances, #(3, 1)) |> should.equal(Error(Nil))
    }
    Error(Nil) -> should.fail()
  }
}

// Empty graph
pub fn floyd_warshall_empty_test() {
  let graph = model.new(Directed)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      dict.size(distances) |> should.equal(0)
    }
    Error(Nil) -> should.fail()
  }
}

// Single node
pub fn floyd_warshall_single_node_test() {
  let graph = model.new(Directed) |> model.add_node(1, "A")

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from node 1 to itself should be 0
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))
    }
    Error(Nil) -> should.fail()
  }
}

// Negative weights (valid)
pub fn floyd_warshall_negative_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: -2)
    |> model.add_edge(from: 1, to: 3, with: 6)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from 1 to 3 should be 3 (via 2: 5 + (-2))
      dict.get(distances, #(1, 3)) |> should.equal(Ok(3))
    }
    Error(Nil) -> should.fail()
  }
}

// Negative cycle detection
pub fn floyd_warshall_negative_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 1, with: -10)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Error(Nil))
}

// Disconnected graph
pub fn floyd_warshall_disconnected_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 3)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Path exists from 1 to 2
      dict.get(distances, #(1, 2)) |> should.equal(Ok(5))

      // No path from 1 to 3 (disconnected)
      dict.get(distances, #(1, 3)) |> should.equal(Error(Nil))

      // Path exists from 3 to 4
      dict.get(distances, #(3, 4)) |> should.equal(Ok(3))

      // No path from 3 to 1 (disconnected)
      dict.get(distances, #(3, 1)) |> should.equal(Error(Nil))
    }
    Error(Nil) -> should.fail()
  }
}

// Transitive closure through intermediate nodes
pub fn floyd_warshall_transitive_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 4, with: 3)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // All paths from 1 should be found
      dict.get(distances, #(1, 2)) |> should.equal(Ok(1))
      dict.get(distances, #(1, 3)) |> should.equal(Ok(3))
      dict.get(distances, #(1, 4)) |> should.equal(Ok(6))
    }
    Error(Nil) -> should.fail()
  }
}

// Comparison with shortest_path
pub fn floyd_warshall_vs_shortest_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 4, with: 10)
    |> model.add_edge(from: 4, to: 3, with: 2)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Verify all pairs against shortest_path
      let nodes = [1, 2, 3, 4]
      nodes
      |> list.each(fn(source) {
        nodes
        |> list.each(fn(target) {
          let floyd_dist = dict.get(distances, #(source, target))

          let shortest_path_result =
            pathfinding.shortest_path(
              in: graph,
              from: source,
              to: target,
              with_zero: 0,
              with_add: int.add,
              with_compare: int.compare,
            )

          case shortest_path_result {
            Some(path) -> {
              floyd_dist |> should.equal(Ok(path.total_weight))
            }
            None -> {
              floyd_dist |> should.equal(Error(Nil))
            }
          }
        })
      })
    }
    Error(Nil) -> should.fail()
  }
}

// Undirected graph (symmetric distances)
pub fn floyd_warshall_undirected_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 4)
    |> model.add_edge(from: 2, to: 3, with: 3)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance should be symmetric in undirected graph
      let dist_1_2 = dict.get(distances, #(1, 2))
      let dist_2_1 = dict.get(distances, #(2, 1))
      dist_1_2 |> should.equal(dist_2_1)

      let dist_1_3 = dict.get(distances, #(1, 3))
      let dist_3_1 = dict.get(distances, #(3, 1))
      dist_1_3 |> should.equal(dist_3_1)

      // Distance from 1 to 3 should be 7
      dist_1_3 |> should.equal(Ok(7))
    }
    Error(Nil) -> should.fail()
  }
}

// Float weights
pub fn floyd_warshall_float_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 2.5)
    |> model.add_edge(from: 2, to: 3, with: 1.5)
    |> model.add_edge(from: 1, to: 3, with: 5.0)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from 1 to 3 should be 4.0 (via 2: 2.5 + 1.5)
      dict.get(distances, #(1, 3)) |> should.equal(Ok(4.0))
    }
    Error(Nil) -> should.fail()
  }
}

// Self-loop with negative weight (negative cycle)
pub fn floyd_warshall_negative_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: -5)
    // Negative self-loop
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should detect negative cycle from self-loop
  result |> should.equal(Error(Nil))
}

// Self-loop with positive weight (valid)
pub fn floyd_warshall_positive_self_loop_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 5)
    // Positive self-loop (ignored, not shortest)
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result =
    pathfinding.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from 1 to itself should still be 0 (not 5)
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))
      // Distance from 1 to 2 should be 10
      dict.get(distances, #(1, 2)) |> should.equal(Ok(10))
    }
    Error(Nil) -> should.fail()
  }
}

// ============= Distance Matrix Tests =============

// Test with sparse POIs (should use multiple Dijkstra)
pub fn distance_matrix_sparse_pois_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 4, with: 10)
    |> model.add_edge(from: 4, to: 5, with: 2)
    |> model.add_edge(from: 3, to: 6, with: 1)

  // Only 2 POIs out of 6 nodes (sparse: 2*3 = 6 < 6, uses multiple Dijkstra)
  let pois = [1, 6]

  case
    pathfinding.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Distance from 1 to 1
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))
      // Distance from 1 to 6 (1 -> 2 -> 3 -> 6 = 5 + 3 + 1 = 9)
      dict.get(distances, #(1, 6)) |> should.equal(Ok(9))
      // Distance from 6 to 1 (no path)
      dict.get(distances, #(6, 1)) |> should.equal(Error(Nil))
      // Only POI pairs should be in result
      dict.get(distances, #(1, 2)) |> should.equal(Error(Nil))
    }
    Error(Nil) -> should.fail()
  }
}

// Test with dense POIs (should use Floyd-Warshall)
pub fn distance_matrix_dense_pois_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 3, to: 4, with: 2)
    |> model.add_edge(from: 1, to: 4, with: 15)

  // 3 POIs out of 4 nodes (dense: 3*3 = 9 > 4, uses Floyd-Warshall)
  let pois = [1, 2, 4]

  case
    pathfinding.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Distance from 1 to 2
      dict.get(distances, #(1, 2)) |> should.equal(Ok(5))
      // Distance from 1 to 4 (shorter path: 1 -> 2 -> 3 -> 4 = 10)
      dict.get(distances, #(1, 4)) |> should.equal(Ok(10))
      // Distance from 2 to 4
      dict.get(distances, #(2, 4)) |> should.equal(Ok(5))
      // Non-POI node 3 should not be in result
      dict.get(distances, #(1, 3)) |> should.equal(Error(Nil))
    }
    Error(Nil) -> should.fail()
  }
}

// Test that both sparse and dense paths give same result
pub fn distance_matrix_consistency_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)

  let pois = [1, 3, 6]

  // Get results (this will use multiple Dijkstra)
  let result1 =
    pathfinding.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Build a smaller graph with only POIs to force Floyd-Warshall path
  let small_graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(3, "C")
    |> model.add_node(6, "F")
    |> model.add_edge(from: 1, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 6, with: 3)

  let result2 =
    pathfinding.distance_matrix(
      in: small_graph,
      between: [1, 3, 6],
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result1, result2 {
    Ok(dist1), Ok(dist2) -> {
      // Both should have distance from 1 to 3
      dict.get(dist1, #(1, 3)) |> should.equal(Ok(2))
      dict.get(dist2, #(1, 3)) |> should.equal(Ok(2))
      // Both should have distance from 3 to 6
      dict.get(dist1, #(3, 6)) |> should.equal(Ok(3))
      dict.get(dist2, #(3, 6)) |> should.equal(Ok(3))
    }
    _, _ -> should.fail()
  }
}

// Test with empty POI list
pub fn distance_matrix_empty_pois_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  case
    pathfinding.distance_matrix(
      in: graph,
      between: [],
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Should be empty dict
      dict.size(distances) |> should.equal(0)
    }
    Error(Nil) -> should.fail()
  }
}

// Test with single POI
pub fn distance_matrix_single_poi_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  case
    pathfinding.distance_matrix(
      in: graph,
      between: [1],
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Should only have distance from 1 to itself
      dict.size(distances) |> should.equal(1)
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))
    }
    Error(Nil) -> should.fail()
  }
}

// Test negative cycle detection (when using Floyd-Warshall path)
pub fn distance_matrix_negative_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: -10)
    |> model.add_edge(from: 3, to: 1, with: 2)

  // 3 POIs out of 3 nodes (dense: will use Floyd-Warshall)
  let pois = [1, 2, 3]

  let result =
    pathfinding.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should detect negative cycle
  result |> should.equal(Error(Nil))
}

// Test with disconnected POIs
pub fn distance_matrix_disconnected_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 3, to: 4, with: 3)

  let pois = [1, 4]

  case
    pathfinding.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Distance from 1 to 1
      dict.get(distances, #(1, 1)) |> should.equal(Ok(0))
      // Distance from 1 to 4 (no path)
      dict.get(distances, #(1, 4)) |> should.equal(Error(Nil))
      // Distance from 4 to 4
      dict.get(distances, #(4, 4)) |> should.equal(Ok(0))
    }
    Error(Nil) -> should.fail()
  }
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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
    pathfinding.implicit_dijkstra_by(
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

// ===== implicit_a_star tests =====

pub fn implicit_a_star_grid_manhattan_test() {
  // 3x3 grid, find shortest path from (0,0) to (2,2)
  // Each move costs 1
  let successors_with_cost = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
    |> list.filter_map(fn(delta) {
      let #(dx, dy) = delta
      let new_pos = #(x + dx, y + dy)
      let #(nx, ny) = new_pos
      case nx >= 0 && nx < 3 && ny >= 0 && ny < 3 {
        True -> Ok(#(new_pos, 1))
        False -> Error(Nil)
      }
    })
  }

  let manhattan_heuristic = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    int.absolute_value(2 - x) + int.absolute_value(2 - y)
  }

  let result =
    pathfinding.implicit_a_star(
      from: #(0, 0),
      successors_with_cost: successors_with_cost,
      heuristic: manhattan_heuristic,
      is_goal: fn(pos) { pos == #(2, 2) },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Shortest path is 4 moves (right, right, down, down or variations)
  result |> should.equal(Some(4))
}

pub fn implicit_a_star_linear_path_test() {
  // Linear: 1 -> 2 -> 3 -> 4
  let successors_with_cost = fn(n: Int) {
    case n < 4 {
      True -> [#(n + 1, 1)]
      False -> []
    }
  }

  let heuristic = fn(n: Int) { 4 - n }

  let result =
    pathfinding.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(3))
}

pub fn implicit_a_star_no_path_test() {
  // 1 -> 2, 3 -> 4, no path from 1 to 4
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 1)]
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let heuristic = fn(_n: Int) { 0 }

  let result =
    pathfinding.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(None)
}

pub fn implicit_a_star_start_is_goal_test() {
  let successors_with_cost = fn(_n: Int) { [] }
  let heuristic = fn(_n: Int) { 0 }

  let result =
    pathfinding.implicit_a_star(
      from: 42,
      successors_with_cost: successors_with_cost,
      heuristic: heuristic,
      is_goal: fn(n) { n == 42 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(0))
}

pub fn implicit_a_star_multiple_paths_test() {
  // Diamond: 1 -> 2 -> 4 (cost 2)
  //          1 -> 3 -> 4 (cost 11)
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 1), #(3, 10)]
      2 -> [#(4, 1)]
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let heuristic = fn(n: Int) {
    case n {
      4 -> 0
      _ -> 1
    }
  }

  let result =
    pathfinding.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(2))
}

pub fn implicit_a_star_admissible_heuristic_test() {
  // Test that A* works correctly with admissible heuristic
  // Grid with obstacles: need to go around
  let successors_with_cost = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
    |> list.filter_map(fn(delta) {
      let #(dx, dy) = delta
      let new_pos = #(x + dx, y + dy)
      let #(nx, ny) = new_pos
      // Block position (1, 1) - force going around
      case nx >= 0 && nx < 3 && ny >= 0 && ny < 3 && new_pos != #(1, 1) {
        True -> Ok(#(new_pos, 1))
        False -> Error(Nil)
      }
    })
  }

  let manhattan_heuristic = fn(pos: #(Int, Int)) {
    let #(x, y) = pos
    int.absolute_value(2 - x) + int.absolute_value(2 - y)
  }

  let result =
    pathfinding.implicit_a_star(
      from: #(0, 0),
      successors_with_cost: successors_with_cost,
      heuristic: manhattan_heuristic,
      is_goal: fn(pos) { pos == #(2, 2) },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Path must go around the obstacle
  result |> should.equal(Some(4))
}

// ===== implicit_a_star_by tests =====

pub fn implicit_a_star_by_position_mask_test() {
  // State is #(position, keys_collected), dedupe by both
  // @ -> a -> b (costs 1 each)
  // Can only reach b after collecting a
  let successors = fn(state: #(String, Int)) {
    let #(pos, collected) = state
    case pos {
      "@" -> [#(#("a", int.bitwise_or(collected, 1)), 1)]
      "a" ->
        case int.bitwise_and(collected, 1) == 1 {
          True -> [#(#("b", int.bitwise_or(collected, 2)), 1)]
          False -> []
        }
      _ -> []
    }
  }

  let heuristic = fn(state: #(String, Int)) {
    let #(pos, _collected) = state
    case pos {
      "b" -> 0
      "a" -> 1
      _ -> 2
    }
  }

  let result =
    pathfinding.implicit_a_star_by(
      from: #("@", 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state },
      heuristic: heuristic,
      is_goal: fn(state) { state.0 == "b" },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(Some(2))
}

pub fn implicit_a_star_by_best_cost_wins_test() {
  // Multiple ways to reach same position with different costs
  // State is #(position, history)
  // Dedupe by position only, best cost should win
  let successors = fn(state: #(Int, String)) {
    let #(pos, history) = state
    case pos {
      1 -> [
        #(#(2, history <> "->2"), 1),
        #(#(3, history <> "->3"), 10),
      ]
      2 -> [#(#(4, history <> "->4"), 1)]
      3 -> [#(#(4, history <> "->4"), 1)]
      _ -> []
    }
  }

  let heuristic = fn(state: #(Int, String)) {
    let #(pos, _history) = state
    case pos {
      4 -> 0
      _ -> 1
    }
  }

  let result =
    pathfinding.implicit_a_star_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      heuristic: heuristic,
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take cheaper path through position 2 (total cost 2)
  result |> should.equal(Some(2))
}

pub fn implicit_a_star_by_identity_equivalence_test() {
  // Using identity function for visited_by should behave like base version
  let successors_with_cost = fn(n: Int) {
    case n < 4 {
      True -> [#(n + 1, 1)]
      False -> []
    }
  }

  let heuristic = fn(n: Int) { 4 - n }

  let result_by =
    pathfinding.implicit_a_star_by(
      from: 1,
      successors_with_cost: successors_with_cost,
      visited_by: fn(n) { n },
      heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let result_base =
    pathfinding.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result_by |> should.equal(result_base)
  result_by |> should.equal(Some(3))
}

// ===== implicit_bellman_ford tests =====

pub fn implicit_bellman_ford_linear_path_test() {
  // Linear: 1 -> 2 -> 3 -> 4
  let successors_with_cost = fn(n: Int) {
    case n < 4 {
      True -> [#(n + 1, 1)]
      False -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.FoundGoal(3))
}

pub fn implicit_bellman_ford_negative_weights_test() {
  // Path with negative weights
  // 1 -> 2 (cost 5) -> 3 (cost -2) -> 4 (cost 1)
  // Total: 5 + (-2) + 1 = 4
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 5)]
      2 -> [#(3, -2)]
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.FoundGoal(4))
}

pub fn implicit_bellman_ford_negative_cycle_test() {
  // Negative cycle: 1 -> 2 -> 3 -> 2 (total cost -1)
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 1)]
      2 -> [#(3, -1)]
      3 -> [#(2, -2), #(4, 10)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.DetectedNegativeCycle)
}

pub fn implicit_bellman_ford_no_path_test() {
  // 1 -> 2, 3 -> 4, no path from 1 to 4
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 1)]
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.NoGoal)
}

pub fn implicit_bellman_ford_start_is_goal_test() {
  let successors_with_cost = fn(_n: Int) { [] }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 42,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 42 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.FoundGoal(0))
}

pub fn implicit_bellman_ford_chooses_cheaper_path_test() {
  // Diamond with negative edge
  // 1 -> 2 (cost 1) -> 4 (cost 1) = total 2
  // 1 -> 3 (cost 10) -> 4 (cost -8) = total 2
  // Both equal cost, should find at least one
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 1), #(3, 10)]
      2 -> [#(4, 1)]
      3 -> [#(4, -8)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.FoundGoal(2))
}

// ===== implicit_bellman_ford_by tests =====

pub fn implicit_bellman_ford_by_position_mask_test() {
  // State is #(position, keys_collected), dedupe by both
  // @ -> a -> b (costs 1 each, negative edge at end)
  let successors = fn(state: #(String, Int)) {
    let #(pos, collected) = state
    case pos {
      "@" -> [#(#("a", int.bitwise_or(collected, 1)), 1)]
      "a" ->
        case int.bitwise_and(collected, 1) == 1 {
          True -> [#(#("b", int.bitwise_or(collected, 2)), -1)]
          False -> []
        }
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford_by(
      from: #("@", 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state },
      is_goal: fn(state) { state.0 == "b" },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.FoundGoal(0))
}

pub fn implicit_bellman_ford_by_negative_cycle_test() {
  // State with cycle, dedupe by position only
  let successors = fn(state: #(Int, Int)) {
    let #(pos, count) = state
    case pos {
      1 -> [#(#(2, count + 1), 1)]
      2 -> [#(#(3, count + 1), -1)]
      3 -> [#(#(2, count + 1), -2), #(#(4, count + 1), 10)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford_by(
      from: #(1, 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(pathfinding.DetectedNegativeCycle)
}

pub fn implicit_bellman_ford_by_best_cost_wins_test() {
  // Multiple ways to reach same position with different costs
  // State is #(position, history)
  // Dedupe by position only, best cost should win
  let successors = fn(state: #(Int, String)) {
    let #(pos, history) = state
    case pos {
      1 -> [
        #(#(2, history <> "->2"), 1),
        #(#(3, history <> "->3"), 10),
      ]
      2 -> [#(#(4, history <> "->4"), 1)]
      3 -> [#(#(4, history <> "->4"), -8)]
      _ -> []
    }
  }

  let result =
    pathfinding.implicit_bellman_ford_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find cost 2 (either path works)
  result |> should.equal(pathfinding.FoundGoal(2))
}

pub fn implicit_bellman_ford_by_identity_equivalence_test() {
  // Using identity function for visited_by should behave like base version
  let successors_with_cost = fn(n: Int) {
    case n {
      1 -> [#(2, 5)]
      2 -> [#(3, -2)]
      3 -> [#(4, 1)]
      _ -> []
    }
  }

  let result_by =
    pathfinding.implicit_bellman_ford_by(
      from: 1,
      successors_with_cost: successors_with_cost,
      visited_by: fn(n) { n },
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let result_base =
    pathfinding.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result_by |> should.equal(result_base)
  result_by |> should.equal(pathfinding.FoundGoal(4))
}
