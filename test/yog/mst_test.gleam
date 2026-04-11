import gleam/int
import gleam/list
import gleam/option
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/mst
import yog/property/structure

// ============= Basic MST Tests =============

pub fn mst_simple_triangle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)

  list.any(result.edges, fn(e) { e.from == 1 && e.to == 2 && e.weight == 1 })
  |> should.be_true()

  list.any(result.edges, fn(e) { e.from == 2 && e.to == 3 && e.weight == 2 })
  |> should.be_true()

  result.algorithm
  |> should.equal(mst.Kruskal)
}

pub fn mst_linear_chain_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(15)
}

pub fn mst_single_edge_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(1)

  case result.edges {
    [edge] -> {
      edge.from
      |> should.equal(1)

      edge.to
      |> should.equal(2)

      edge.weight
      |> should.equal(10)
    }
    _ -> should.fail()
  }
}

pub fn mst_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(0)

  result.total_weight
  |> should.equal(0)

  result.node_count
  |> should.equal(1)
}

pub fn mst_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(0)

  result.total_weight
  |> should.equal(0)

  result.node_count
  |> should.equal(0)
}

// ============= Classic MST Test Cases =============

pub fn mst_square_with_diagonal_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 4, 1),
      #(4, 3, 1),
      #(3, 1, 1),
      #(1, 4, 5),
      #(2, 3, 5),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(3)
}

pub fn mst_classic_kruskal_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(1, 4, 4),
      #(2, 4, 5),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(6)
}

pub fn mst_pentagon_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(4, 5, 4),
      #(5, 1, 5),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(4)

  result.total_weight
  |> should.equal(10)
}

// ============= Disconnected Graph Tests =============

pub fn mst_disconnected_two_components_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 2)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn mst_disconnected_three_components_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 2), #(5, 6, 3)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(3)
}

pub fn mst_with_isolated_nodes_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(1)
}

// ============= Weight Variation Tests =============

pub fn mst_all_same_weights_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 5), #(3, 4, 5), #(1, 4, 5)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(15)
}

pub fn mst_zero_weight_edges_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 0), #(2, 3, 0)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(0)
}

// ============= Complete Graph Tests =============

pub fn mst_complete_graph_k4_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(2, 3, 4),
      #(2, 4, 5),
      #(3, 4, 6),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(6)
}

pub fn mst_complete_graph_k5_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(1, 5, 4),
      #(2, 3, 5),
      #(2, 4, 6),
      #(2, 5, 7),
      #(3, 4, 8),
      #(3, 5, 9),
      #(4, 5, 10),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(4)

  result.total_weight
  |> should.equal(10)
}

// ============= Cycle Detection Tests =============

pub fn mst_avoids_cycle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 100)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(2)

  list.any(result.edges, fn(e) { e.weight == 100 })
  |> should.be_false()
}

// ============= Large Graph Tests =============

pub fn mst_larger_graph_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    |> model.add_node(9, "9")
    |> model.add_node(10, "10")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(4, 5, 4),
      #(5, 6, 5),
      #(6, 7, 6),
      #(7, 8, 7),
      #(8, 9, 8),
      #(9, 10, 9),
      #(1, 10, 100),
      #(5, 10, 50),
    ])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(9)

  result.total_weight
  |> should.equal(45)
}

// ============= Edge Case: Self Loops =============

pub fn mst_with_self_loop_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, 1), #(1, 2, 2)])

  let result = mst.kruskal_int(graph)

  result.edge_count
  |> should.equal(1)

  case result.edges {
    [edge] -> {
      edge.from
      |> should.equal(1)

      edge.to
      |> should.equal(2)
    }
    _ -> should.fail()
  }
}

// ============= Prim's Algorithm Tests =============

pub fn prim_simple_triangle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn prim_linear_chain_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(15)
}

pub fn prim_single_edge_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(1)

  case result.edges {
    [edge] -> {
      edge.weight
      |> should.equal(10)
    }
    _ -> should.fail()
  }
}

pub fn prim_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(0)
}

pub fn prim_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(0)
}

pub fn prim_square_with_diagonal_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 4, 1),
      #(4, 3, 1),
      #(3, 1, 1),
      #(1, 4, 5),
      #(2, 3, 5),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(3)
}

pub fn prim_classic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(1, 4, 4),
      #(2, 4, 5),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(6)
}

pub fn prim_pentagon_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(4, 5, 4),
      #(5, 1, 5),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(4)

  result.total_weight
  |> should.equal(10)
}

pub fn prim_complete_graph_k4_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(2, 3, 4),
      #(2, 4, 5),
      #(3, 4, 6),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(6)
}

pub fn prim_complete_graph_k5_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(1, 5, 4),
      #(2, 3, 5),
      #(2, 4, 6),
      #(2, 5, 7),
      #(3, 4, 8),
      #(3, 5, 9),
      #(4, 5, 10),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(4)

  result.total_weight
  |> should.equal(10)
}

pub fn prim_larger_graph_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "1")
    |> model.add_node(2, "2")
    |> model.add_node(3, "3")
    |> model.add_node(4, "4")
    |> model.add_node(5, "5")
    |> model.add_node(6, "6")
    |> model.add_node(7, "7")
    |> model.add_node(8, "8")
    |> model.add_node(9, "9")
    |> model.add_node(10, "10")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(4, 5, 4),
      #(5, 6, 5),
      #(6, 7, 6),
      #(7, 8, 7),
      #(8, 9, 8),
      #(9, 10, 9),
      #(1, 10, 100),
      #(5, 10, 50),
    ])

  let result = mst.prim_int(graph)

  result.edge_count
  |> should.equal(9)

  result.total_weight
  |> should.equal(45)
}

pub fn prim_vs_kruskal_same_weight_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(1, 4, 4),
      #(2, 4, 5),
    ])

  let kruskal_result = mst.kruskal_int(graph)
  let prim_result = mst.prim_int(graph)

  kruskal_result.edge_count
  |> should.equal(prim_result.edge_count)

  kruskal_result.total_weight
  |> should.equal(prim_result.total_weight)
}

// ============= Boruvka's Algorithm Tests =============

pub fn boruvka_simple_triangle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result = mst.boruvka_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)

  result.algorithm
  |> should.equal(mst.Boruvka)
}

pub fn boruvka_square_with_diagonal_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 4, 1),
      #(4, 3, 1),
      #(3, 1, 1),
      #(1, 4, 5),
      #(2, 3, 5),
    ])

  let result = mst.boruvka_int(graph)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(3)
}

pub fn boruvka_disconnected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 1), #(3, 4, 2)])

  let result = mst.boruvka_int(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn boruvka_vs_kruskal_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(1, 5, 4),
      #(2, 3, 5),
      #(2, 4, 6),
      #(2, 5, 7),
      #(3, 4, 8),
      #(3, 5, 9),
      #(4, 5, 10),
    ])

  let boruvka_result = mst.boruvka_int(graph)
  let kruskal_result = mst.kruskal_int(graph)

  boruvka_result.edge_count
  |> should.equal(kruskal_result.edge_count)

  boruvka_result.total_weight
  |> should.equal(kruskal_result.total_weight)
}

// ============= Edmonds Algorithm Tests =============

pub fn edmonds_basic_arborescence_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(2, 3, 5),
      #(2, 4, 3),
      #(3, 4, 1),
    ])

  let assert Ok(result) = mst.edmonds_int(graph, root: 1)

  result.algorithm
  |> should.equal(mst.ChuLiuEdmonds)

  result.root
  |> should.equal(option.Some(1))

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(4)
}

pub fn edmonds_cycle_contraction_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 2, 1),
      #(3, 4, 1),
    ])

  let assert Ok(result) = mst.edmonds_int(graph, root: 1)

  result.edge_count
  |> should.equal(3)

  result.total_weight
  |> should.equal(3)
}

pub fn edmonds_no_arborescence_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1)])
  // Node 3 has no incoming edges

  let result = mst.edmonds_int(graph, root: 1)

  result
  |> should.equal(Error("No arborescence exists"))
}

pub fn edmonds_undirected_graph_error_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = mst.edmonds_int(graph, root: 1)

  result
  |> should.equal(Error("Edmonds algorithm requires a directed graph"))
}

pub fn edmonds_is_arborescence_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(2, 4, 3),
      #(3, 4, 1),
    ])

  let assert Ok(result) = mst.edmonds_int(graph, root: 1)

  // Build a graph from the arborescence edges to verify structure
  let tree_graph =
    list.fold(result.edges, model.new(Directed), fn(g, e) {
      let g = case model.has_node(g, e.from) {
        True -> g
        False -> model.add_node(g, e.from, "")
      }
      let g = case model.has_node(g, e.to) {
        True -> g
        False -> model.add_node(g, e.to, "")
      }
      let assert Ok(g2) = model.add_edge(g, e.from, e.to, e.weight)
      g2
    })

  structure.is_arborescence(tree_graph)
  |> should.be_true()
}

// ============= Wilson's Algorithm Tests =============

pub fn wilson_basic_tree_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(1, 3, 4),
    ])

  let result = mst.wilson_int_with_seed(graph, seed: 42)

  result.algorithm
  |> should.equal(mst.Wilson)

  result.edge_count
  |> should.equal(3)

  result.node_count
  |> should.equal(4)
}

pub fn wilson_reproducible_with_seed_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(2, 3, 2),
      #(3, 4, 3),
      #(1, 4, 4),
      #(2, 4, 5),
    ])

  let result1 = mst.wilson_int_with_seed(graph, seed: 123)
  let result2 = mst.wilson_int_with_seed(graph, seed: 123)

  result1.total_weight
  |> should.equal(result2.total_weight)

  result1.edges
  |> should.equal(result2.edges)
}

pub fn wilson_empty_graph_test() {
  let graph = model.new(Undirected)
  let result = mst.wilson_int(graph)

  result.edge_count
  |> should.equal(0)

  result.node_count
  |> should.equal(0)
}

pub fn wilson_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = mst.wilson_int(graph)

  result.edge_count
  |> should.equal(0)

  result.node_count
  |> should.equal(1)
}

pub fn wilson_is_tree_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, 1),
      #(1, 3, 2),
      #(1, 4, 3),
      #(2, 3, 4),
      #(2, 4, 5),
      #(3, 4, 6),
    ])

  let result = mst.wilson_int_with_seed(graph, seed: 999)

  // Build undirected graph from result edges
  let tree_graph =
    list.fold(result.edges, model.new(Undirected), fn(g, e) {
      let g = case model.has_node(g, e.from) {
        True -> g
        False -> model.add_node(g, e.from, "")
      }
      let g = case model.has_node(g, e.to) {
        True -> g
        False -> model.add_node(g, e.to, "")
      }
      let assert Ok(g2) = model.add_edge(g, e.from, e.to, e.weight)
      g2
    })

  structure.is_tree(tree_graph)
  |> should.be_true()
}

// ============= MstResult Float Tests =============

pub fn kruskal_float_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 3.5)])

  let result = mst.kruskal_float(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(4.0)
}

pub fn prim_float_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 3.5)])

  let result = mst.prim_float(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(4.0)
}

pub fn boruvka_float_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 3.5)])

  let result = mst.boruvka_float(graph)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(4.0)
}

pub fn edmonds_float_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(1, 3, 2.5), #(2, 3, 0.5)])

  let assert Ok(result) = mst.edmonds_float(graph, root: 1)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(2.0)
}

pub fn wilson_float_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1.5), #(2, 3, 2.5), #(1, 3, 3.5)])

  let result = mst.wilson_float_with_seed(graph, seed: 42)

  result.edge_count
  |> should.equal(2)

  result.node_count
  |> should.equal(3)
}

// ============= Generic API Tests =============

pub fn kruskal_generic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result =
    mst.kruskal(
      graph,
      with_compare: int.compare,
      with_add: int.add,
      with_zero: 0,
    )

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn prim_generic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result =
    mst.prim(graph, with_compare: int.compare, with_add: int.add, with_zero: 0)

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn boruvka_generic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result =
    mst.boruvka(
      graph,
      with_compare: int.compare,
      with_add: int.add,
      with_zero: 0,
    )

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn edmonds_generic_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(1, 3, 2), #(2, 3, 3)])

  let assert Ok(result) =
    mst.edmonds(
      graph,
      root: 1,
      with_compare: int.compare,
      with_add: int.add,
      with_subtract: int.subtract,
      with_zero: 0,
    )

  result.edge_count
  |> should.equal(2)

  result.total_weight
  |> should.equal(3)
}

pub fn wilson_generic_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(1, 3, 3)])

  let result =
    mst.wilson_with_seed(graph, seed: 7, with_add: int.add, with_zero: 0)

  result.edge_count
  |> should.equal(2)

  result.node_count
  |> should.equal(3)
}
