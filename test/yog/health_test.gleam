import gleam/int
import gleam/option.{None, Some}
import gleeunit/should
import yog
import yog/health

// Simple path graph: 1 -- 2 -- 3
fn path_graph() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)

  let assert Ok(graph) = yog.add_edges(graph, [#(1, 2, 1), #(2, 3, 1)])

  graph
}

// Complete graph K3: 1 -- 2
//                    |  X  |
//                    3 ----+
fn complete_graph_k3() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)

  let assert Ok(graph) =
    yog.add_edges(graph, [#(1, 2, 1), #(2, 3, 1), #(1, 3, 1)])

  graph
}

// Star graph: 1 -- 2
//              |
//              3
//              |
//              4
fn star_graph() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)

  let assert Ok(graph) =
    yog.add_edges(graph, [#(1, 2, 1), #(1, 3, 1), #(1, 4, 1)])

  graph
}

// Disconnected graph
fn disconnected_graph() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)

  let assert Ok(graph) = yog.add_edges(graph, [#(1, 2, 1)])

  graph
}

pub fn diameter_path_test() {
  let graph = path_graph()
  let diam = health.diameter(graph, 0, int.add, int.compare, fn(w) { w })

  diam |> should.equal(Some(2))
}

pub fn diameter_complete_test() {
  let graph = complete_graph_k3()
  let diam = health.diameter(graph, 0, int.add, int.compare, fn(w) { w })

  diam |> should.equal(Some(1))
}

pub fn diameter_star_test() {
  let graph = star_graph()
  let diam = health.diameter(graph, 0, int.add, int.compare, fn(w) { w })

  diam |> should.equal(Some(2))
}

pub fn diameter_disconnected_test() {
  let graph = disconnected_graph()
  let diam = health.diameter(graph, 0, int.add, int.compare, fn(w) { w })

  diam |> should.equal(None)
}

pub fn diameter_empty_test() {
  let graph = yog.undirected()
  let diam = health.diameter(graph, 0, int.add, int.compare, fn(w) { w })

  diam |> should.equal(None)
}

pub fn radius_path_test() {
  let graph = path_graph()
  let rad = health.radius(graph, 0, int.add, int.compare, fn(w) { w })

  rad |> should.equal(Some(1))
}

pub fn radius_complete_test() {
  let graph = complete_graph_k3()
  let rad = health.radius(graph, 0, int.add, int.compare, fn(w) { w })

  rad |> should.equal(Some(1))
}

pub fn radius_star_test() {
  let graph = star_graph()
  let rad = health.radius(graph, 0, int.add, int.compare, fn(w) { w })

  rad |> should.equal(Some(1))
}

pub fn radius_disconnected_test() {
  let graph = disconnected_graph()
  let rad = health.radius(graph, 0, int.add, int.compare, fn(w) { w })

  rad |> should.equal(None)
}

pub fn eccentricity_path_center_test() {
  let graph = path_graph()
  // Node 2 is in the center
  let ecc = health.eccentricity(graph, 2, 0, int.add, int.compare, fn(w) { w })

  ecc |> should.equal(Some(1))
}

pub fn eccentricity_path_end_test() {
  let graph = path_graph()
  // Node 1 is at the end
  let ecc = health.eccentricity(graph, 1, 0, int.add, int.compare, fn(w) { w })

  ecc |> should.equal(Some(2))
}

pub fn eccentricity_star_center_test() {
  let graph = star_graph()
  // Node 1 is the center
  let ecc = health.eccentricity(graph, 1, 0, int.add, int.compare, fn(w) { w })

  ecc |> should.equal(Some(1))
}

pub fn eccentricity_star_leaf_test() {
  let graph = star_graph()
  // Node 2 is a leaf
  let ecc = health.eccentricity(graph, 2, 0, int.add, int.compare, fn(w) { w })

  ecc |> should.equal(Some(2))
}

pub fn assortativity_complete_test() {
  let graph = complete_graph_k3()
  let assort = health.assortativity(graph)

  // All nodes have same degree, so should be 0
  assort |> should.equal(0.0)
}

pub fn assortativity_star_test() {
  let graph = star_graph()
  let assort = health.assortativity(graph)

  // Center (high degree) connects to leaves (low degree)
  // Should be negative (disassortative)
  { assort <. 0.0 } |> should.be_true()
}

pub fn assortativity_empty_test() {
  let graph = yog.undirected()
  let assort = health.assortativity(graph)

  assort |> should.equal(0.0)
}

pub fn average_path_length_complete_test() {
  let graph = complete_graph_k3()
  let avg =
    health.average_path_length(
      graph,
      0,
      int.add,
      int.compare,
      fn(w) { w },
      int.to_float,
    )

  // All pairs have distance 1
  avg |> should.equal(Some(1.0))
}

pub fn average_path_length_path_test() {
  let graph = path_graph()
  let avg =
    health.average_path_length(
      graph,
      0,
      int.add,
      int.compare,
      fn(w) { w },
      int.to_float,
    )

  // Average of: 1->2=1, 1->3=2, 2->1=1, 2->3=1, 3->1=2, 3->2=1
  // = (1+2+1+1+2+1) / 6 = 8/6 = 1.333...
  case avg {
    Some(a) -> {
      { a >. 1.3 && a <. 1.4 } |> should.be_true()
    }
    None -> should.fail()
  }
}

pub fn average_path_length_disconnected_test() {
  let graph = disconnected_graph()
  let avg =
    health.average_path_length(
      graph,
      0,
      int.add,
      int.compare,
      fn(w) { w },
      int.to_float,
    )

  avg |> should.equal(None)
}

pub fn average_path_length_empty_test() {
  let graph = yog.undirected()
  let avg =
    health.average_path_length(
      graph,
      0,
      int.add,
      int.compare,
      fn(w) { w },
      int.to_float,
    )

  avg |> should.equal(None)
}
