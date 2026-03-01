import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import yog/multi
import yog/multi/eulerian

// ---------------------------------------------------------------------------
// has_eulerian_circuit
// ---------------------------------------------------------------------------

pub fn circuit_triangle_undirected_test() {
  // Triangle: 1-2-3-1, all even degree → Eulerian circuit
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, _) = multi.add_edge(g, from: 2, to: 3, with: 1)
  let #(g, _) = multi.add_edge(g, from: 3, to: 1, with: 1)
  eulerian.has_eulerian_circuit(g) |> should.be_true()
}

pub fn circuit_parallel_edges_undirected_test() {
  // Two nodes with 2 parallel edges each → degrees are 2 (even) → circuit
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "b")
  eulerian.has_eulerian_circuit(g) |> should.be_true()
}

pub fn circuit_konigsberg_not_eulerian_test() {
  // Königsberg-style: 4 nodes where some have odd degree → not Eulerian
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
    |> multi.add_node(4, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 2)
  let #(g, _) = multi.add_edge(g, from: 1, to: 3, with: 3)
  let #(g, _) = multi.add_edge(g, from: 1, to: 3, with: 4)
  let #(g, _) = multi.add_edge(g, from: 1, to: 4, with: 5)
  let #(g, _) = multi.add_edge(g, from: 2, to: 4, with: 6)
  let #(g, _) = multi.add_edge(g, from: 3, to: 4, with: 7)
  eulerian.has_eulerian_circuit(g) |> should.be_false()
}

pub fn circuit_empty_graph_test() {
  eulerian.has_eulerian_circuit(multi.directed()) |> should.be_false()
}

// ---------------------------------------------------------------------------
// has_eulerian_path
// ---------------------------------------------------------------------------

pub fn path_two_nodes_single_edge_test() {
  // 1→2 with one edge: exactly 2 odd-degree nodes → path
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  eulerian.has_eulerian_path(g) |> should.be_true()
}

pub fn path_triangle_is_also_path_test() {
  // A triangle also has an Eulerian path (it has a circuit)
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, _) = multi.add_edge(g, from: 2, to: 3, with: 1)
  let #(g, _) = multi.add_edge(g, from: 3, to: 1, with: 1)
  eulerian.has_eulerian_path(g) |> should.be_true()
}

// ---------------------------------------------------------------------------
// find_eulerian_circuit
// ---------------------------------------------------------------------------

pub fn find_circuit_covers_all_edges_test() {
  // Triangle → circuit should use all 3 edges
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, e2) = multi.add_edge(g, from: 2, to: 3, with: 1)
  let #(g, e3) = multi.add_edge(g, from: 3, to: 1, with: 1)
  case eulerian.find_eulerian_circuit(g) {
    None -> should.fail()
    Some(path) -> {
      list.length(path) |> should.equal(3)
      list.contains(path, e1) |> should.be_true()
      list.contains(path, e2) |> should.be_true()
      list.contains(path, e3) |> should.be_true()
    }
  }
}

pub fn find_circuit_parallel_edges_test() {
  // Two parallel edges → circuit uses both
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, e2) = multi.add_edge(g, from: 1, to: 2, with: "b")
  case eulerian.find_eulerian_circuit(g) {
    None -> should.fail()
    Some(path) -> {
      list.length(path) |> should.equal(2)
      list.contains(path, e1) |> should.be_true()
      list.contains(path, e2) |> should.be_true()
    }
  }
}

pub fn find_circuit_none_when_no_circuit_test() {
  // Single edge → no circuit (degree 1 on each endpoint)
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  eulerian.find_eulerian_circuit(g) |> should.equal(None)
}

// ---------------------------------------------------------------------------
// find_eulerian_path
// ---------------------------------------------------------------------------

pub fn find_path_covers_all_edges_test() {
  // Path graph 1-2-3 → Eulerian path uses both edges
  let g =
    multi.undirected()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, e2) = multi.add_edge(g, from: 2, to: 3, with: 1)
  case eulerian.find_eulerian_path(g) {
    None -> should.fail()
    Some(path) -> {
      list.length(path) |> should.equal(2)
      list.contains(path, e1) |> should.be_true()
      list.contains(path, e2) |> should.be_true()
    }
  }
}

pub fn find_path_directed_test() {
  // 1→2→3 directed path
  let g =
    multi.directed()
    |> multi.add_node(1, Nil)
    |> multi.add_node(2, Nil)
    |> multi.add_node(3, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, e2) = multi.add_edge(g, from: 2, to: 3, with: 1)
  case eulerian.find_eulerian_path(g) {
    None -> should.fail()
    Some(path) -> {
      list.length(path) |> should.equal(2)
      list.contains(path, e1) |> should.be_true()
      list.contains(path, e2) |> should.be_true()
    }
  }
}
