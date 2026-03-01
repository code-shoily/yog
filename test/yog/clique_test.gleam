import gleam/list
import gleam/set
import gleeunit/should
import yog/clique
import yog/model.{Undirected}

// Test finding max clique in a triangle (3-clique)
pub fn max_clique_triangle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = clique.max_clique(graph)

  result
  |> set.size
  |> should.equal(3)

  result
  |> should.equal(set.from_list([1, 2, 3]))
}

// Test finding max clique in a 4-clique
pub fn max_clique_four_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.max_clique(graph)

  result
  |> set.size
  |> should.equal(4)

  result
  |> should.equal(set.from_list([1, 2, 3, 4]))
}

// Test max clique with disconnected node
pub fn max_clique_with_isolated_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "Isolated")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = clique.max_clique(graph)

  // Should find the triangle, not the isolated node
  result
  |> set.size
  |> should.equal(3)

  result
  |> should.equal(set.from_list([1, 2, 3]))
}

// Test max clique in a path graph (no clique larger than 2)
pub fn max_clique_path_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.max_clique(graph)

  // Maximum clique in a path is just an edge (size 2)
  result
  |> set.size
  |> should.equal(2)
}

// Test max clique with two separate cliques
pub fn max_clique_two_cliques_test() {
  let graph =
    model.new(Undirected)
    // First triangle
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    // Second, larger clique (4-clique)
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_node(6, "F")
    |> model.add_node(7, "G")
    |> model.add_edge(from: 4, to: 5, with: 1)
    |> model.add_edge(from: 4, to: 6, with: 1)
    |> model.add_edge(from: 4, to: 7, with: 1)
    |> model.add_edge(from: 5, to: 6, with: 1)
    |> model.add_edge(from: 5, to: 7, with: 1)
    |> model.add_edge(from: 6, to: 7, with: 1)

  let result = clique.max_clique(graph)

  // Should find the larger 4-clique
  result
  |> set.size
  |> should.equal(4)

  result
  |> should.equal(set.from_list([4, 5, 6, 7]))
}

// Test max clique in complete graph (all nodes form a clique)
pub fn max_clique_complete_graph_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = clique.max_clique(graph)

  result
  |> set.size
  |> should.equal(3)

  result
  |> should.equal(set.from_list([1, 2, 3]))
}

// Test max clique in empty graph
pub fn max_clique_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = clique.max_clique(graph)

  result
  |> set.size
  |> should.equal(0)
}

// Test max clique with single node
pub fn max_clique_single_node_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = clique.max_clique(graph)

  result
  |> should.equal(set.from_list([1]))
}

// ============= all_maximal_cliques Tests =============

// Test finding all maximal cliques in a simple graph
pub fn all_maximal_cliques_simple_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)

  let result = clique.all_maximal_cliques(graph)

  // Should find two maximal cliques: {1,2} and {2,3}
  result
  |> list.length
  |> should.equal(2)

  result
  |> list.contains(set.from_list([1, 2]))
  |> should.be_true

  result
  |> list.contains(set.from_list([2, 3]))
  |> should.be_true
}

// Test finding all maximal cliques in a triangle
pub fn all_maximal_cliques_triangle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = clique.all_maximal_cliques(graph)

  // Should find one maximal clique: the triangle itself
  result
  |> list.length
  |> should.equal(1)

  result
  |> list.first
  |> should.equal(Ok(set.from_list([1, 2, 3])))
}

// Test finding all maximal cliques with disconnected components
pub fn all_maximal_cliques_disconnected_test() {
  let graph =
    model.new(Undirected)
    // First triangle
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    // Second edge (disconnected)
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edge(from: 4, to: 5, with: 1)

  let result = clique.all_maximal_cliques(graph)

  // Should find two maximal cliques
  result
  |> list.length
  |> should.equal(2)

  result
  |> list.contains(set.from_list([1, 2, 3]))
  |> should.be_true

  result
  |> list.contains(set.from_list([4, 5]))
  |> should.be_true
}

// Test that all_maximal_cliques finds the same max as max_clique
pub fn all_maximal_contains_max_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let max = clique.max_clique(graph)
  let all = clique.all_maximal_cliques(graph)

  // The list of all maximal cliques should contain the maximum clique
  all
  |> list.contains(max)
  |> should.be_true
}

// ============= k_cliques Tests =============

// Test finding all 2-cliques (edges) in a triangle
pub fn k_cliques_size_2_triangle_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = clique.k_cliques(graph, 2)

  // Should find 3 edges (2-cliques)
  result
  |> list.length
  |> should.equal(3)

  result
  |> list.contains(set.from_list([1, 2]))
  |> should.be_true

  result
  |> list.contains(set.from_list([2, 3]))
  |> should.be_true

  result
  |> list.contains(set.from_list([1, 3]))
  |> should.be_true
}

// Test finding all 3-cliques (triangles) in a graph
pub fn k_cliques_size_3_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.k_cliques(graph, 3)

  // Should find exactly 1 triangle
  result
  |> list.length
  |> should.equal(1)

  result
  |> list.first
  |> should.equal(Ok(set.from_list([1, 2, 3])))
}

// Test finding all 4-cliques in a complete graph K4
pub fn k_cliques_size_4_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.k_cliques(graph, 4)

  // Should find exactly 1 4-clique (the whole graph)
  result
  |> list.length
  |> should.equal(1)

  result
  |> list.first
  |> should.equal(Ok(set.from_list([1, 2, 3, 4])))
}

// Test k_cliques with k larger than any clique
pub fn k_cliques_too_large_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)

  let result = clique.k_cliques(graph, 5)

  // No 5-cliques exist in a triangle
  result
  |> list.length
  |> should.equal(0)
}

// Test k_cliques with k=1 (all individual nodes)
pub fn k_cliques_size_1_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = clique.k_cliques(graph, 1)

  // Should find 3 1-cliques (each node)
  result
  |> list.length
  |> should.equal(3)

  result
  |> list.contains(set.from_list([1]))
  |> should.be_true

  result
  |> list.contains(set.from_list([2]))
  |> should.be_true

  result
  |> list.contains(set.from_list([3]))
  |> should.be_true
}

// Test k_cliques on empty graph
pub fn k_cliques_empty_graph_test() {
  let graph = model.new(Undirected)

  let result = clique.k_cliques(graph, 3)

  result
  |> list.length
  |> should.equal(0)
}

// Test k_cliques with k=0 (edge case)
pub fn k_cliques_zero_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = clique.k_cliques(graph, 0)

  // k=0 should return empty list
  result
  |> list.length
  |> should.equal(0)
}

// Test k_cliques with negative k
pub fn k_cliques_negative_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")

  let result = clique.k_cliques(graph, -1)

  result
  |> list.length
  |> should.equal(0)
}

// Test finding triangles in a graph with multiple triangles
pub fn k_cliques_multiple_triangles_test() {
  let graph =
    model.new(Undirected)
    // First triangle
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    // Second triangle (shares edge with first)
    |> model.add_node(4, "D")
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.k_cliques(graph, 3)

  // Should find 2 triangles
  result
  |> list.length
  |> should.equal(2)

  result
  |> list.contains(set.from_list([1, 2, 3]))
  |> should.be_true

  result
  |> list.contains(set.from_list([2, 3, 4]))
  |> should.be_true
}

// Test k_cliques on a path (no triangles)
pub fn k_cliques_path_no_triangles_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)

  let result = clique.k_cliques(graph, 3)

  // No triangles in a path
  result
  |> list.length
  |> should.equal(0)
}

// Test k_cliques finds all 3-cliques in K5
pub fn k_cliques_k5_triangles_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    // Complete graph K5 - all pairs connected
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 3, with: 1)
    |> model.add_edge(from: 1, to: 4, with: 1)
    |> model.add_edge(from: 1, to: 5, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 2, to: 4, with: 1)
    |> model.add_edge(from: 2, to: 5, with: 1)
    |> model.add_edge(from: 3, to: 4, with: 1)
    |> model.add_edge(from: 3, to: 5, with: 1)
    |> model.add_edge(from: 4, to: 5, with: 1)

  let result = clique.k_cliques(graph, 3)

  // K5 has C(5,3) = 10 triangles
  result
  |> list.length
  |> should.equal(10)
}
