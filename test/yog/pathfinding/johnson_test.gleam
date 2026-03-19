import gleam/dict
import gleam/float
import gleam/int
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/floyd_warshall
import yog/pathfinding/johnson

// ============= Johnson's Algorithm Tests =============

// Basic Johnson's algorithm
pub fn johnson_basic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10), #(1, 3, 20)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // 1 to 3 should be 15 (via 2), not 20
      distances
      |> dict.get(#(1, 3))
      |> should.equal(Ok(15))

      distances
      |> dict.get(#(1, 2))
      |> should.equal(Ok(5))

      distances
      |> dict.get(#(2, 3))
      |> should.equal(Ok(10))
    }
    Error(_) -> should.fail()
  }
}

// Johnson's algorithm with negative weights
pub fn johnson_negative_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 1, -5), #(2, 3, 5)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      distances
      |> dict.get(#(1, 3))
      |> should.equal(Ok(15))

      distances
      |> dict.get(#(2, 3))
      |> should.equal(Ok(5))

      // Distance from 1 to itself should be 0
      distances
      |> dict.get(#(1, 1))
      |> should.equal(Ok(0))
    }
    Error(_) -> should.fail()
  }
}

// Detecting negative cycles with Johnson's
pub fn johnson_negative_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 5), #(2, 1, -10)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  result
  |> should.equal(Error(Nil))
}

// Multiple paths, choose shortest
pub fn johnson_multiple_paths_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(2, 4, 1), #(1, 3, 5), #(3, 4, 5)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      distances
      |> dict.get(#(1, 4))
      |> should.equal(Ok(2))
    }
    Error(_) -> should.fail()
  }
}

// Disconnected components
pub fn johnson_disconnected_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(3, 4, 5)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      distances
      |> dict.get(#(1, 4))
      |> should.equal(Error(Nil))

      distances
      |> dict.get(#(1, 2))
      |> should.equal(Ok(5))
    }
    Error(_) -> should.fail()
  }
}

// Single node graph
pub fn johnson_single_node_test() {
  let graph = model.new(Directed) |> model.add_node(1, "A")

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      distances
      |> dict.get(#(1, 1))
      |> should.equal(Ok(0))
    }
    Error(_) -> should.fail()
  }
}

pub fn johnson_empty_test() {
  let graph = model.new(Directed)

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      dict.size(distances) |> should.equal(0)
    }
    Error(Nil) -> should.fail()
  }
}

pub fn johnson_transitive_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      dict.get(distances, #(1, 3)) |> should.equal(Ok(2))
    }
    Error(Nil) -> should.fail()
  }
}

// Johnson's vs Floyd-Warshall - should get same results
pub fn johnson_vs_floyd_warshall_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(1, 3, 10)])

  let johnson_result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  let fw_result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case johnson_result, fw_result {
    Ok(johnson_distances), Ok(fw_distances) -> {
      dict.get(johnson_distances, #(1, 3))
      |> should.equal(dict.get(fw_distances, #(1, 3)))
    }
    _, _ -> should.fail()
  }
}

pub fn johnson_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 5)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      dict.get(distances, #(1, 2)) |> should.equal(Ok(5))
      dict.get(distances, #(2, 1)) |> should.equal(Ok(5))
    }
    Error(Nil) -> should.fail()
  }
}

pub fn johnson_float_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5)])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0.0,
      with_add: float.add,
      with_subtract: float.subtract,
      with_compare: float.compare,
    )

  case result {
    Ok(distances) -> {
      // Distance from 1 to 3 should be 4.0 (via 2: 1.5 + 2.5)
      dict.get(distances, #(1, 3)) |> should.equal(Ok(4.0))
    }
    Error(Nil) -> should.fail()
  }
}

pub fn johnson_negative_self_loop_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, -5), #(1, 2, 10)])
  // Negative self-loop

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  // Should detect negative cycle from self-loop
  result |> should.equal(Error(Nil))
}

pub fn johnson_positive_self_loop_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, 5), #(1, 2, 10)])
  // Positive self-loop (ignored, not shortest)

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
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

// Test with larger graph with negative edges
pub fn johnson_complex_negative_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 4),
      #(1, 3, 2),
      #(2, 3, -3),
      #(3, 4, 2),
      #(2, 4, 5),
    ])

  let result =
    johnson.johnson(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_subtract: int.subtract,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      // Path from 1 to 4: 1->2->3->4 = 4 + (-3) + 2 = 3
      dict.get(distances, #(1, 4)) |> should.equal(Ok(3))
      // Path from 1 to 3: 1->2->3 = 4 + (-3) = 1 (better than direct 1->3 = 2)
      dict.get(distances, #(1, 3)) |> should.equal(Ok(1))
    }
    Error(Nil) -> should.fail()
  }
}

// Convenience wrapper tests
pub fn johnson_int_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result = johnson.johnson_int(in: graph)

  case result {
    Ok(distances) -> {
      dict.get(distances, #(1, 3)) |> should.equal(Ok(15))
    }
    Error(Nil) -> should.fail()
  }
}

pub fn johnson_float_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5)])

  let result = johnson.johnson_float(in: graph)

  case result {
    Ok(distances) -> {
      dict.get(distances, #(1, 3)) |> should.equal(Ok(4.0))
    }
    Error(Nil) -> should.fail()
  }
}
