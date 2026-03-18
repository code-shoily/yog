import gleam/dict
import gleam/float
import gleam/int
import gleam/option.{Some}
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/dijkstra
import yog/pathfinding/floyd_warshall

// ============= Floyd-Warshall Tests =============

// Basic Floyd-Warshall
pub fn floyd_warshall_basic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 10)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 3, with: 20)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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

// Floyd-Warshall with negative weights
pub fn floyd_warshall_negative_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 1, with: -5)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 5)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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

      // Self distances can become negative if there's a negative cycle
      // but here there is no negative cycle (1->2->1 is 10-5=5)
      distances
      |> dict.get(#(1, 1))
      |> should.equal(Ok(0))
    }
    Error(_) -> should.fail()
  }
}

// Detecting negative cycles with Floyd-Warshall
pub fn floyd_warshall_negative_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 1, with: -10)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  result
  |> should.equal(Error(Nil))
}

// Multiple paths, choose shortest
pub fn floyd_warshall_multiple_paths_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 4, with: 1)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 3, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 3, to: 4, with: 5)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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
pub fn floyd_warshall_disconnected_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 5)
  let assert Ok(graph) = model.add_edge(graph, from: 3, to: 4, with: 5)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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
pub fn floyd_warshall_single_node_test() {
  let graph = model.new(Directed) |> model.add_node(1, "A")

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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

pub fn floyd_warshall_empty_test() {
  let graph = model.new(Directed)

  let result =
    floyd_warshall.floyd_warshall(
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

pub fn floyd_warshall_transitive_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 1)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case result {
    Ok(distances) -> {
      dict.get(distances, #(1, 3)) |> should.equal(Ok(2))
    }
    Error(Nil) -> should.fail()
  }
}

pub fn floyd_warshall_vs_shortest_path_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 1)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 3, with: 10)

  let fw_result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  let dijkstra_result =
    dijkstra.shortest_path(
      in: graph,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  case fw_result, dijkstra_result {
    Ok(distances), Some(path) -> {
      dict.get(distances, #(1, 3)) |> should.equal(Ok(path.total_weight))
    }
    _, _ -> should.fail()
  }
}

pub fn floyd_warshall_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
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

pub fn floyd_warshall_float_weights_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1.5)
  let assert Ok(graph) = model.add_edge(graph, from: 2, to: 3, with: 2.5)

  let result =
    floyd_warshall.floyd_warshall(
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

pub fn floyd_warshall_negative_self_loop_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: -5)
  // Negative self-loop
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 2, with: 10)

  let result =
    floyd_warshall.floyd_warshall(
      in: graph,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should detect negative cycle from self-loop
  result |> should.equal(Error(Nil))
}

pub fn floyd_warshall_positive_self_loop_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 1, with: 5)
  // Positive self-loop (ignored, not shortest)
  let assert Ok(graph) = model.add_edge(graph, from: 1, to: 2, with: 10)

  let result =
    floyd_warshall.floyd_warshall(
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
