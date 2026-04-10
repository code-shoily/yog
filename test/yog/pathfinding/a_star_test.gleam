import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/model.{Directed}
import yog/pathfinding/a_star
import yog/pathfinding/dijkstra
import yog/pathfinding/path

// ============= A* Search Tests =============

// A* with zero heuristic (equivalent to Dijkstra)
pub fn astar_zero_heuristic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let zero_heuristic = fn(_from: Int, _to: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: zero_heuristic,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1, 2, 3], total_weight: 15)))
}

// A* with Manhattan distance heuristic (grid)
pub fn astar_manhattan_distance_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "0,0")
    |> model.add_node(2, "1,0")
    |> model.add_node(3, "2,0")
    |> model.add_node(4, "0,1")
    |> model.add_node(5, "1,1")
    |> model.add_node(6, "2,1")
    |> model.add_edges([
      // Grid connections (each edge cost 1)
      #(1, 2, 1),
      #(2, 3, 1),
      #(1, 4, 1),
      #(2, 5, 1),
      #(3, 6, 1),
      #(4, 5, 1),
      #(5, 6, 1),
    ])

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
    a_star.a_star(
      in: graph,
      from: 1,
      to: 6,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: manhattan,
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "A")
    |> model.add_node(3, "B")
    |> model.add_node(4, "Goal")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 2), #(2, 4, 100), #(3, 4, 1)])

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
    a_star.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  // Should find path through 3, not 2 (cost 3 vs 101)
  result
  |> should.equal(Some(path.Path(nodes: [1, 3, 4], total_weight: 3)))
}

// A* with same start and goal
pub fn astar_same_start_goal_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1], total_weight: 0)))
}

// A* with no path
pub fn astar_no_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5)])

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(None)
}

// A* with admissible heuristic finds optimal path
pub fn astar_admissible_heuristic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      // Multiple paths from 1 to 5
      #(1, 2, 1),
      #(2, 5, 10),
      #(1, 3, 3),
      #(3, 4, 2),
      #(4, 5, 1),
    ])

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
    a_star.a_star(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  // Should find optimal path 1->3->4->5 with cost 6
  result
  |> should.equal(Some(path.Path(nodes: [1, 3, 4, 5], total_weight: 6)))
}

// A* on diamond graph
pub fn astar_diamond_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Top")
    |> model.add_node(2, "Left")
    |> model.add_node(3, "Right")
    |> model.add_node(4, "Bottom")
    |> model.add_edges([#(1, 2, 2), #(1, 3, 3), #(2, 4, 4), #(3, 4, 5)])

  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 4 -> 5
      2, 4 -> 3
      3, 4 -> 4
      _, _ -> 0
    }
  }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1, 2, 4], total_weight: 6)))
}

// A* with cycle detection
pub fn astar_with_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1, 2, 3], total_weight: 2)))
}

// A* perfect heuristic (exact distance)
pub fn astar_perfect_heuristic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 4, 1), #(1, 4, 10)])

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
    a_star.a_star(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1, 2, 3, 4], total_weight: 3)))
}

// A* consistent heuristic (consistent triangle inequality)
pub fn astar_consistent_heuristic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 5), #(1, 3, 20)])

  // Consistent heuristic satisfies h(x) <= cost(x,y) + h(y)
  let h = fn(from: Int, to: Int) -> Int {
    case from, to {
      1, 3 -> 8
      2, 3 -> 4
      _, _ -> 0
    }
  }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [1, 2, 3], total_weight: 10)))
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
    a_star.implicit_a_star(
      from: #(0, 0),
      successors_with_cost: successors_with_cost,
      with_heuristic: manhattan_heuristic,
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
    a_star.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      with_heuristic: heuristic,
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
    a_star.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      with_heuristic: heuristic,
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
    a_star.implicit_a_star(
      from: 42,
      successors_with_cost: successors_with_cost,
      with_heuristic: heuristic,
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
    a_star.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      with_heuristic: heuristic,
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
    a_star.implicit_a_star(
      from: #(0, 0),
      successors_with_cost: successors_with_cost,
      with_heuristic: manhattan_heuristic,
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
    a_star.implicit_a_star_by(
      from: #("@", 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state },
      with_heuristic: heuristic,
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
    a_star.implicit_a_star_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      with_heuristic: heuristic,
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
    a_star.implicit_a_star_by(
      from: 1,
      successors_with_cost: successors_with_cost,
      visited_by: fn(n) { n },
      with_heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let result_base =
    a_star.implicit_a_star(
      from: 1,
      successors_with_cost: successors_with_cost,
      with_heuristic: heuristic,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result_by |> should.equal(result_base)
  result_by |> should.equal(Some(3))
}

pub fn astar_float_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 5.0)])

  let h = fn(from: Int, to: Int) -> Float {
    case from, to {
      1, 3 -> 3.0
      2, 3 -> 2.0
      _, _ -> 0.0
    }
  }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
      with_heuristic: h,
    )

  case result {
    Some(path) -> {
      path.total_weight |> should.equal(4.0)
      path.nodes |> should.equal([1, 2, 3])
    }
    None -> should.fail()
  }
}

pub fn astar_undirected_test() {
  let assert Ok(graph) =
    model.new(model.Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 3,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result
  |> should.equal(Some(path.Path(nodes: [3, 2, 1], total_weight: 15)))
}

pub fn astar_vs_dijkstra_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 4),
      #(2, 3, 2),
      #(2, 4, 5),
      #(3, 4, 1),
      #(4, 5, 2),
    ])

  let h = fn(_: Int, _: Int) -> Int { 1 }

  let dijkstra_result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let astar_result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  astar_result |> should.equal(dijkstra_result)
  astar_result
  |> should.equal(Some(path.Path(nodes: [1, 2, 3, 4, 5], total_weight: 6)))
}

pub fn astar_empty_graph_test() {
  let graph = model.new(Directed)

  let h = fn(_: Int, _: Int) -> Int { 0 }

  let result =
    a_star.a_star(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      with_heuristic: h,
    )

  result |> should.equal(None)
}
