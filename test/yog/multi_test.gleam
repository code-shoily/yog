import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/model
import yog/multi/model as multi

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

pub fn directed_new_test() {
  let g = multi.directed()
  multi.order(g) |> should.equal(0)
  multi.size(g) |> should.equal(0)
}

pub fn undirected_new_test() {
  let g = multi.undirected()
  multi.order(g) |> should.equal(0)
  multi.size(g) |> should.equal(0)
}

// ---------------------------------------------------------------------------
// Nodes
// ---------------------------------------------------------------------------

pub fn add_node_test() {
  let g =
    multi.directed()
    |> multi.add_node(1, "A")
    |> multi.add_node(2, "B")
  multi.order(g) |> should.equal(2)
  multi.all_nodes(g) |> list.sort(int.compare) |> should.equal([1, 2])
}

pub fn replace_node_data_test() {
  let g =
    multi.directed()
    |> multi.add_node(1, "A")
    |> multi.add_node(1, "A-updated")
  multi.order(g) |> should.equal(1)
  dict.get(g.nodes, 1) |> should.equal(Ok("A-updated"))
}

pub fn remove_node_also_removes_edges_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _e1) = multi.add_edge(g, from: 1, to: 2, with: 10)
  let #(g, _e2) = multi.add_edge(g, from: 1, to: 2, with: 20)
  let g = multi.remove_node(g, 1)
  multi.order(g) |> should.equal(1)
  multi.size(g) |> should.equal(0)
}

// ---------------------------------------------------------------------------
// Edges — parallel edges
// ---------------------------------------------------------------------------

pub fn parallel_edges_distinct_ids_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: 5)
  let #(g, e2) = multi.add_edge(g, from: 1, to: 2, with: 10)
  let #(_g, e3) = multi.add_edge(g, from: 1, to: 2, with: 15)
  should.not_equal(e1, e2)
  should.not_equal(e2, e3)
}

pub fn parallel_edges_size_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 2)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 3)
  multi.size(g) |> should.equal(3)
}

pub fn edges_between_parallel_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: "fast")
  let #(g, e2) = multi.add_edge(g, from: 1, to: 2, with: "slow")
  let between = multi.edges_between(g, from: 1, to: 2)
  list.length(between) |> should.equal(2)
  list.map(between, fn(p) { p.0 })
  |> list.sort(int.compare)
  |> should.equal(list.sort([e1, e2], int.compare))
}

pub fn edges_between_empty_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  multi.edges_between(g, from: 1, to: 2) |> should.equal([])
}

pub fn remove_one_parallel_edge_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: "flight")
  let #(g, _e2) = multi.add_edge(g, from: 1, to: 2, with: "train")
  let g = multi.remove_edge(g, e1)
  multi.size(g) |> should.equal(1)
  let between = multi.edges_between(g, from: 1, to: 2)
  list.length(between) |> should.equal(1)
  // The remaining edge should NOT be e1
  list.map(between, fn(p) { p.0 }) |> list.contains(e1) |> should.be_false()
}

pub fn has_edge_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, e1) = multi.add_edge(g, from: 1, to: 2, with: 0)
  multi.has_edge(g, e1) |> should.be_true()
  let g = multi.remove_edge(g, e1)
  multi.has_edge(g, e1) |> should.be_false()
}

// ---------------------------------------------------------------------------
// Successors / predecessors
// ---------------------------------------------------------------------------

pub fn successors_parallel_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "b")
  // Two parallel edges → two entries in successors
  multi.successors(g, 1) |> list.length() |> should.equal(2)
}

pub fn predecessors_parallel_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "a")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: "b")
  multi.predecessors(g, 2) |> list.length() |> should.equal(2)
}

pub fn undirected_successors_test() {
  let g = multi.undirected() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 5)
  // Undirected: 1 can reach 2 and 2 can reach 1
  multi.successors(g, 1) |> list.length() |> should.equal(1)
  multi.successors(g, 2) |> list.length() |> should.equal(1)
}

// ---------------------------------------------------------------------------
// Degrees
// ---------------------------------------------------------------------------

pub fn out_degree_parallel_test() {
  let g = multi.directed() |> multi.add_node(1, Nil) |> multi.add_node(2, Nil)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 1)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 2)
  multi.out_degree(g, 1) |> should.equal(2)
  multi.in_degree(g, 1) |> should.equal(0)
  multi.in_degree(g, 2) |> should.equal(2)
}

// ---------------------------------------------------------------------------
// to_simple_graph
// ---------------------------------------------------------------------------

pub fn to_simple_graph_min_weight_test() {
  let g = multi.directed() |> multi.add_node(1, "A") |> multi.add_node(2, "B")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 10)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 3)
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 7)
  let simple =
    multi.to_simple_graph(g, fn(a, b) {
      case a < b {
        True -> a
        False -> b
      }
    })
  // Only one edge should survive (minimum weight = 3)
  let succs = model.successors(simple, 1)
  list.length(succs) |> should.equal(1)
  let assert Ok(#(_, w)) = list.first(succs)
  w |> should.equal(3)
}

pub fn to_simple_graph_preserves_nodes_test() {
  let g = multi.directed() |> multi.add_node(1, "A") |> multi.add_node(2, "B")
  let #(g, _) = multi.add_edge(g, from: 1, to: 2, with: 5)
  let simple = multi.to_simple_graph(g, fn(a, _) { a })
  model.all_nodes(simple) |> list.sort(int.compare) |> should.equal([1, 2])
}
