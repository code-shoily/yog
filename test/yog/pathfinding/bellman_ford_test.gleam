import gleam/float
import gleam/int
import gleam/option.{Some}
import gleeunit/should
import yog/model.{Directed}
import yog/pathfinding/bellman_ford
import yog/pathfinding/dijkstra
import yog/pathfinding/utils

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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 2, 3], total_weight: 15)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 2, 3], total_weight: 5)),
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
    bellman_ford.bellman_ford(
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
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 2, 3, 4], total_weight: -6)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(bellman_ford.NegativeCycle)
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
    bellman_ford.bellman_ford(
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
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 5], total_weight: 10)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(bellman_ford.NoPath)
}

// Same start and goal
pub fn bellman_ford_same_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let result =
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    bellman_ford.ShortestPath(utils.Path(nodes: [1], total_weight: 0)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 2, 3], total_weight: 0)),
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
    bellman_ford.bellman_ford(
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
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 3, 2, 4], total_weight: -1)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(bellman_ford.NegativeCycle)
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 2], total_weight: 10)),
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
    bellman_ford.bellman_ford(
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
    bellman_ford.ShortestPath(utils.Path(nodes: [1, 3, 4], total_weight: 1)),
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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0.0,
      with_add: float.add,
      with_compare: float.compare,
    )

  case result {
    bellman_ford.ShortestPath(path) -> {
      path.nodes
      |> should.equal([1, 2, 3])

      { path.total_weight >. 0.99 && path.total_weight <. 1.01 }
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// Empty graph
pub fn bellman_ford_empty_graph_test() {
  let graph = model.new(Directed)

  let result =
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(bellman_ford.NoPath)
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
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.FoundGoal(3))
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
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.FoundGoal(4))
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
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.DetectedNegativeCycle)
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
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.NoGoal)
}

pub fn implicit_bellman_ford_start_is_goal_test() {
  let successors_with_cost = fn(_n: Int) { [] }

  let result =
    bellman_ford.implicit_bellman_ford(
      from: 42,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 42 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.FoundGoal(0))
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
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.FoundGoal(2))
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
    bellman_ford.implicit_bellman_ford_by(
      from: #("@", 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state },
      is_goal: fn(state) { state.0 == "b" },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.FoundGoal(0))
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
    bellman_ford.implicit_bellman_ford_by(
      from: #(1, 0),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result |> should.equal(bellman_ford.DetectedNegativeCycle)
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
    bellman_ford.implicit_bellman_ford_by(
      from: #(1, "start"),
      successors_with_cost: successors,
      visited_by: fn(state) { state.0 },
      is_goal: fn(state) { state.0 == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should find cost 2 (either path works)
  result |> should.equal(bellman_ford.FoundGoal(2))
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
    bellman_ford.implicit_bellman_ford_by(
      from: 1,
      successors_with_cost: successors_with_cost,
      visited_by: fn(n) { n },
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let result_base =
    bellman_ford.implicit_bellman_ford(
      from: 1,
      successors_with_cost: successors_with_cost,
      is_goal: fn(n) { n == 4 },
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result_by |> should.equal(result_base)
  result_by |> should.equal(bellman_ford.FoundGoal(4))
}

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
    bellman_ford.bellman_ford(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let dijkstra_result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case bellman_result {
    bellman_ford.ShortestPath(path) ->
      Some(path) |> should.equal(dijkstra_result)
    _ -> should.fail()
  }
}
