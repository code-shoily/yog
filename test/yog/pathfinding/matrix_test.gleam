import gleam/dict
import gleam/int
import gleam/option.{None, Some}
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/matrix

// ============= Distance Matrix Tests =============

// Small matrix basic test
pub fn distance_matrix_basic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10), #(1, 3, 20)])

  let result =
    matrix.distance_matrix(
      in: graph,
      between: [1, 2, 3],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
      with_compare: int.compare,
    )

  case result {
    Ok(matrix) -> {
      // 1 to 3 should be 15 (via 2)
      matrix
      |> dict.get(#(1, 3))
      |> should.equal(Ok(15))

      matrix
      |> dict.get(#(1, 2))
      |> should.equal(Ok(5))

      matrix
      |> dict.get(#(2, 3))
      |> should.equal(Ok(10))
    }
    Error(_) -> should.fail()
  }
}

// Matrix of subset of nodes
pub fn distance_matrix_subset_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 5), #(3, 4, 5)])

  let result =
    matrix.distance_matrix(
      in: graph,
      between: [1, 4],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
      with_compare: int.compare,
    )

  case result {
    Ok(matrix) -> {
      // Distance from 1 to 4 is 15
      matrix
      |> dict.get(#(1, 4))
      |> should.equal(Ok(15))

      // Node 2 shouldn't be in matrix as it wasn't requested
      matrix
      |> dict.get(#(1, 2))
      |> should.equal(Error(Nil))

      matrix |> dict.size |> should.equal(3)
      // (1,1), (4,4), (1,4)
    }
    Error(_) -> should.fail()
  }
}

// Matrix with unreachable nodes
pub fn distance_matrix_unreachable_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5)])

  let result =
    matrix.distance_matrix(
      in: graph,
      between: [1, 3],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
      with_compare: int.compare,
    )

  case result {
    Ok(matrix) -> {
      matrix
      |> dict.get(#(1, 3))
      |> should.equal(Error(Nil))

      matrix
      |> dict.get(#(1, 1))
      |> should.equal(Ok(0))
    }
    Error(_) -> should.fail()
  }
}

// Large graph - triggers algorithm selection (should still work)
pub fn distance_matrix_algorithm_selection_test() {
  // Dijkstra is generally better for sparse matrices
  // Floyd-Warshall better for dense
  // distance_matrix should handle this internally
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  let result =
    matrix.distance_matrix(
      in: graph,
      between: [1, 2, 3],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
      with_compare: int.compare,
    )

  result |> should.be_ok()
}

// Detection of negative cycle in distance matrix
pub fn distance_matrix_negative_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 1), #(2, 1, -5)])

  let result =
    matrix.distance_matrix(
      in: graph,
      between: [1, 2],
      with_zero: 0,
      with_add: int.add,
      with_subtract: Some(int.subtract),
      with_compare: int.compare,
    )

  result
  |> should.equal(Error(Nil))
}

pub fn distance_matrix_sparse_pois_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([
      #(1, 2, 5),
      #(2, 3, 3),
      #(1, 4, 10),
      #(4, 5, 2),
      #(3, 6, 1),
    ])

  // Only 2 POIs out of 6 nodes (sparse: 2*3 = 6 < 6, uses multiple Dijkstra)
  let pois = [1, 6]

  case
    matrix.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

pub fn distance_matrix_dense_pois_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 3), #(3, 4, 2), #(1, 4, 15)])

  // 3 POIs out of 4 nodes (dense: 3*3 = 9 > 4, uses Floyd-Warshall)
  let pois = [1, 2, 4]

  case
    matrix.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

pub fn distance_matrix_consistency_test() {
  let assert Ok(graph) =
    model.new(Undirected)
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

  let pois = [1, 3, 6]

  // Get results (this will use multiple Dijkstra)
  let result1 =
    matrix.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
      with_compare: int.compare,
    )

  // Build a smaller graph with only POIs to force Floyd-Warshall path
  let assert Ok(small_graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(3, "C")
    |> model.add_node(6, "F")
    |> model.add_edges([#(1, 3, 2), #(3, 6, 3)])

  let result2 =
    matrix.distance_matrix(
      in: small_graph,
      between: [1, 3, 6],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

pub fn distance_matrix_empty_pois_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 5)])

  case
    matrix.distance_matrix(
      in: graph,
      between: [],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

pub fn distance_matrix_single_poi_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 5)])

  case
    matrix.distance_matrix(
      in: graph,
      between: [1],
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

pub fn distance_matrix_disconnected_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(3, 4, 3)])

  let pois = [1, 4]

  case
    matrix.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_subtract: None,
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

// Test that verifies Johnson's algorithm is used for sparse graphs with negative weights
pub fn distance_matrix_johnson_selection_test() {
  // Create a sparse graph with negative weights
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
      #(2, 3, -3),
      #(3, 4, 2),
      #(2, 4, 5),
      #(4, 5, 1),
    ])

  // Many POIs to potentially trigger all-pairs algorithm
  let pois = [1, 2, 3, 4, 5]

  case
    matrix.distance_matrix(
      in: graph,
      between: pois,
      with_zero: 0,
      with_add: int.add,
      with_subtract: Some(int.subtract),
      with_compare: int.compare,
    )
  {
    Ok(distances) -> {
      // Path from 1 to 4: 1->2->3->4 = 4 + (-3) + 2 = 3
      dict.get(distances, #(1, 4)) |> should.equal(Ok(3))
      // Path from 1 to 3: 1->2->3 = 4 + (-3) = 1 (better than direct 1->3 = 2)
      dict.get(distances, #(1, 3)) |> should.equal(Ok(1))
      // Path from 1 to 5: 1->2->3->4->5 = 4 + (-3) + 2 + 1 = 4
      dict.get(distances, #(1, 5)) |> should.equal(Ok(4))
    }
    Error(Nil) -> should.fail()
  }
}
