import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog
import yog/eulerian

// ============= Eulerian Circuit Tests (Undirected) =============

pub fn has_eulerian_circuit_triangle_test() {
  // Triangle: all vertices have even degree (degree 2)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_true()
}

pub fn has_eulerian_circuit_square_test() {
  // Square: all vertices have even degree (degree 2)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 1, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_true()
}

pub fn has_eulerian_circuit_line_fails_test() {
  // Line: endpoints have odd degree (degree 1)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()
}

pub fn has_eulerian_circuit_star_fails_test() {
  // Star: center has degree 3 (odd), leaves have degree 1 (odd)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()
}

pub fn has_eulerian_circuit_disconnected_fails_test() {
  // Two triangles, disconnected
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)
    |> yog.add_edge(from: 4, to: 5, with: 1)
    |> yog.add_edge(from: 5, to: 6, with: 1)
    |> yog.add_edge(from: 6, to: 4, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()
}

pub fn has_eulerian_circuit_empty_graph_test() {
  let graph = yog.undirected()

  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()
}

// ============= Eulerian Path Tests (Undirected) =============

pub fn has_eulerian_path_line_test() {
  // Line: exactly 2 vertices with odd degree (the endpoints)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  eulerian.has_eulerian_path(graph)
  |> should.be_true()
}

pub fn has_eulerian_path_triangle_test() {
  // Triangle: 0 vertices with odd degree (also has circuit)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  eulerian.has_eulerian_path(graph)
  |> should.be_true()
}

pub fn has_eulerian_path_star_fails_test() {
  // Star: 4 vertices with odd degree (too many)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)

  eulerian.has_eulerian_path(graph)
  |> should.be_false()
}

pub fn has_eulerian_path_house_test() {
  // House shape: square with diagonal
  // Vertices 2,4 have odd degree (3), others even (2)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 1, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)

  eulerian.has_eulerian_path(graph)
  |> should.be_true()
}

// ============= Find Eulerian Circuit Tests =============

pub fn find_eulerian_circuit_triangle_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  case eulerian.find_eulerian_circuit(graph) {
    None -> should.fail()
    Some(path) -> {
      // Path should start and end at same vertex
      let assert [first, ..] = path
      let assert Ok(last) = list.last(path)
      first
      |> should.equal(last)

      // Path should have 4 vertices (3 edges + return to start)
      list.length(path)
      |> should.equal(4)
    }
  }
}

pub fn find_eulerian_circuit_square_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 1, with: 1)

  case eulerian.find_eulerian_circuit(graph) {
    None -> should.fail()
    Some(path) -> {
      // Path should start and end at same vertex
      let assert [first, ..] = path
      let assert Ok(last) = list.last(path)
      first
      |> should.equal(last)

      // Path should have 5 vertices (4 edges + return to start)
      list.length(path)
      |> should.equal(5)
    }
  }
}

pub fn find_eulerian_circuit_line_fails_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  eulerian.find_eulerian_circuit(graph)
  |> should.equal(None)
}

// ============= Find Eulerian Path Tests =============

pub fn find_eulerian_path_line_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  case eulerian.find_eulerian_path(graph) {
    None -> should.fail()
    Some(path) -> {
      // Path should have 3 vertices (2 edges)
      list.length(path)
      |> should.equal(3)

      // Path should start at one endpoint and end at the other
      let assert [first, ..] = path
      let assert Ok(last) = list.last(path)

      // Either starts at 1 and ends at 3, or vice versa
      case first, last {
        1, 3 | 3, 1 -> should.be_true(True)
        _, _ -> should.fail()
      }
    }
  }
}

pub fn find_eulerian_path_triangle_returns_circuit_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  case eulerian.find_eulerian_path(graph) {
    None -> should.fail()
    Some(path) -> {
      // Since all vertices have even degree, it finds a circuit
      list.length(path)
      |> should.equal(4)
    }
  }
}

pub fn find_eulerian_path_star_fails_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)

  eulerian.find_eulerian_path(graph)
  |> should.equal(None)
}

// ============= Directed Graph Tests =============

pub fn has_eulerian_circuit_directed_cycle_test() {
  // Simple directed cycle: 1 -> 2 -> 3 -> 1
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_true()
}

pub fn has_eulerian_circuit_directed_unbalanced_fails_test() {
  // Directed path: 1 -> 2 -> 3 (no circuit)
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()
}

pub fn has_eulerian_path_directed_line_test() {
  // Directed path: 1 -> 2 -> 3
  // Node 1: out=1, in=0 (start)
  // Node 2: out=1, in=1 (balanced)
  // Node 3: out=0, in=1 (end)
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  eulerian.has_eulerian_path(graph)
  |> should.be_true()
}

pub fn find_eulerian_circuit_directed_cycle_test() {
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  case eulerian.find_eulerian_circuit(graph) {
    None -> should.fail()
    Some(path) -> {
      // Check it's a valid circuit
      let assert [first, ..] = path
      let assert Ok(last) = list.last(path)
      first
      |> should.equal(last)

      list.length(path)
      |> should.equal(4)
    }
  }
}

pub fn find_eulerian_path_directed_line_test() {
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)

  case eulerian.find_eulerian_path(graph) {
    None -> should.fail()
    Some(path) -> {
      list.length(path)
      |> should.equal(3)

      // Should go from 1 to 3
      let assert [first, ..] = path
      let assert Ok(last) = list.last(path)

      first
      |> should.equal(1)

      last
      |> should.equal(3)
    }
  }
}

// ============= Complex Graph Tests =============

pub fn eulerian_circuit_k4_minus_edge_test() {
  // Complete graph K4 minus one edge (still has Eulerian circuit)
  // All vertices will have even degree
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
  // Missing: 3-4

  // Degrees: 1=3(odd), 2=3(odd), 3=2(even), 4=2(even)
  // This should have Eulerian path but not circuit
  eulerian.has_eulerian_circuit(graph)
  |> should.be_false()

  eulerian.has_eulerian_path(graph)
  |> should.be_true()
}
