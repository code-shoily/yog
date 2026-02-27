import gleam/list
import gleeunit/should
import yog/generators
import yog/model

// Complete graph tests
pub fn complete_graph_nodes_test() {
  let k5 = generators.complete(5)
  model.all_nodes(k5)
  |> list.length()
  |> should.equal(5)
}

pub fn complete_graph_edges_test() {
  // K_5 should have 5*4/2 = 10 edges (undirected)
  let k5 = generators.complete(5)

  // Count edges by checking all successors
  let edge_count =
    model.all_nodes(k5)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(k5, node)
      count + list.length(successors)
    })

  // Each edge counted twice (undirected), so divide by 2
  edge_count / 2
  |> should.equal(10)
}

pub fn complete_graph_connectivity_test() {
  // In K_4, node 0 should be connected to nodes 1, 2, 3
  let k4 = generators.complete(4)
  let neighbors = model.successors(k4, 0) |> list.map(fn(edge) { edge.0 })

  list.contains(neighbors, 1)
  |> should.be_true()

  list.contains(neighbors, 2)
  |> should.be_true()

  list.contains(neighbors, 3)
  |> should.be_true()

  list.length(neighbors)
  |> should.equal(3)
}

pub fn complete_graph_single_node_test() {
  let k1 = generators.complete(1)
  model.all_nodes(k1)
  |> list.length()
  |> should.equal(1)

  // No edges
  model.successors(k1, 0)
  |> list.length()
  |> should.equal(0)
}

// Cycle graph tests
pub fn cycle_graph_nodes_test() {
  let c6 = generators.cycle(6)
  model.all_nodes(c6)
  |> list.length()
  |> should.equal(6)
}

pub fn cycle_graph_edges_test() {
  // C_6 should have exactly 6 edges
  let c6 = generators.cycle(6)

  let edge_count =
    model.all_nodes(c6)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(c6, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(6)
}

pub fn cycle_graph_structure_test() {
  // Each node in a cycle should have exactly 2 neighbors
  let c5 = generators.cycle(5)

  model.all_nodes(c5)
  |> list.all(fn(node) {
    let neighbors = model.successors(c5, node)
    list.length(neighbors) == 2
  })
  |> should.be_true()
}

pub fn cycle_graph_small_test() {
  // Cycle requires at least 3 nodes
  let c2 = generators.cycle(2)
  model.all_nodes(c2)
  |> list.length()
  |> should.equal(0)
}

// Path graph tests
pub fn path_graph_nodes_test() {
  let p5 = generators.path(5)
  model.all_nodes(p5)
  |> list.length()
  |> should.equal(5)
}

pub fn path_graph_edges_test() {
  // P_5 should have 4 edges (n-1)
  let p5 = generators.path(5)

  let edge_count =
    model.all_nodes(p5)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(p5, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(4)
}

pub fn path_graph_endpoints_test() {
  // In a path, the first and last nodes have degree 1
  let p4 = generators.path(4)

  model.successors(p4, 0)
  |> list.length()
  |> should.equal(1)

  model.successors(p4, 3)
  |> list.length()
  |> should.equal(1)
}

pub fn path_graph_middle_nodes_test() {
  // Middle nodes in a path have degree 2
  let p5 = generators.path(5)

  model.successors(p5, 2)
  |> list.length()
  |> should.equal(2)
}

// Star graph tests
pub fn star_graph_nodes_test() {
  let s6 = generators.star(6)
  model.all_nodes(s6)
  |> list.length()
  |> should.equal(6)
}

pub fn star_graph_edges_test() {
  // S_6 should have 5 edges (n-1)
  let s6 = generators.star(6)

  let edge_count =
    model.all_nodes(s6)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(s6, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(5)
}

pub fn star_graph_center_test() {
  // Center node (0) should be connected to all others
  let s5 = generators.star(5)

  model.successors(s5, 0)
  |> list.length()
  |> should.equal(4)
}

pub fn star_graph_leaf_test() {
  // Leaf nodes should only connect to center
  let s5 = generators.star(5)

  model.successors(s5, 1)
  |> list.length()
  |> should.equal(1)

  let neighbors = model.successors(s5, 1) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors, 0)
  |> should.be_true()
}

// Wheel graph tests
pub fn wheel_graph_nodes_test() {
  let w6 = generators.wheel(6)
  model.all_nodes(w6)
  |> list.length()
  |> should.equal(6)
}

pub fn wheel_graph_center_degree_test() {
  // Center node should be connected to all rim nodes
  let w6 = generators.wheel(6)

  model.successors(w6, 0)
  |> list.length()
  |> should.equal(5)
}

pub fn wheel_graph_rim_degree_test() {
  // Rim nodes should have degree 3 (center + 2 neighbors on rim)
  let w5 = generators.wheel(5)

  model.successors(w5, 1)
  |> list.length()
  |> should.equal(3)
}

// Complete bipartite tests
pub fn complete_bipartite_nodes_test() {
  let k33 = generators.complete_bipartite(3, 3)
  model.all_nodes(k33)
  |> list.length()
  |> should.equal(6)
}

pub fn complete_bipartite_edges_test() {
  // K_3,3 should have 3*3 = 9 edges
  let k33 = generators.complete_bipartite(3, 3)

  let edge_count =
    model.all_nodes(k33)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(k33, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(9)
}

pub fn complete_bipartite_left_connections_test() {
  // Node 0 (left partition) should connect to all right partition nodes
  let k23 = generators.complete_bipartite(2, 3)

  model.successors(k23, 0)
  |> list.length()
  |> should.equal(3)

  let neighbors = model.successors(k23, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors, 2)
  |> should.be_true()
  list.contains(neighbors, 3)
  |> should.be_true()
  list.contains(neighbors, 4)
  |> should.be_true()
}

pub fn complete_bipartite_no_within_partition_test() {
  // Nodes in same partition shouldn't be connected
  let k22 = generators.complete_bipartite(2, 2)

  let neighbors_0 = model.successors(k22, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors_0, 1)
  |> should.be_false()
}

// Empty graph tests
pub fn empty_graph_test() {
  let empty = generators.empty(5)

  model.all_nodes(empty)
  |> list.length()
  |> should.equal(5)

  // No edges
  model.all_nodes(empty)
  |> list.all(fn(node) {
    let edges = model.successors(empty, node)
    edges == []
  })
  |> should.be_true()
}

// Binary tree tests
pub fn binary_tree_nodes_test() {
  // Binary tree of depth 3 should have 2^4 - 1 = 15 nodes
  let tree = generators.binary_tree(3)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(15)
}

pub fn binary_tree_root_children_test() {
  // Root (0) should have children 1 and 2
  let tree = generators.binary_tree(2)

  let children = model.successors(tree, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(children, 1)
  |> should.be_true()
  list.contains(children, 2)
  |> should.be_true()

  list.length(children)
  |> should.equal(2)
}

pub fn binary_tree_leaf_nodes_test() {
  // In a complete binary tree of depth 2, nodes 3,4,5,6 are leaves
  // But since it's undirected, they still have an edge back to parent
  // So they have degree 1, not 0
  let tree = generators.binary_tree(2)

  model.successors(tree, 3)
  |> list.length()
  |> should.equal(1)

  model.successors(tree, 6)
  |> list.length()
  |> should.equal(1)
}

// Grid 2D tests
pub fn grid_2d_nodes_test() {
  let grid = generators.grid_2d(3, 4)
  model.all_nodes(grid)
  |> list.length()
  |> should.equal(12)
}

pub fn grid_2d_corner_degree_test() {
  // Corner nodes have degree 2
  let grid = generators.grid_2d(3, 3)

  model.successors(grid, 0)
  |> list.length()
  |> should.equal(2)

  model.successors(grid, 8)
  |> list.length()
  |> should.equal(2)
}

pub fn grid_2d_edge_degree_test() {
  // Edge nodes (not corners) have degree 3
  let grid = generators.grid_2d(3, 3)

  model.successors(grid, 1)
  // Top edge
  |> list.length()
  |> should.equal(3)
}

pub fn grid_2d_internal_degree_test() {
  // Internal nodes have degree 4
  let grid = generators.grid_2d(3, 3)

  model.successors(grid, 4)
  // Center node
  |> list.length()
  |> should.equal(4)
}

pub fn grid_2d_connections_test() {
  // Node 0 should connect to 1 (right) and 3 (down) in a 3x3 grid
  let grid = generators.grid_2d(3, 3)

  let neighbors = model.successors(grid, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors, 1)
  |> should.be_true()
  list.contains(neighbors, 3)
  |> should.be_true()
}

// Petersen graph tests
pub fn petersen_graph_nodes_test() {
  let petersen = generators.petersen()
  model.all_nodes(petersen)
  |> list.length()
  |> should.equal(10)
}

pub fn petersen_graph_edges_test() {
  // Petersen graph has 15 edges
  let petersen = generators.petersen()

  let edge_count =
    model.all_nodes(petersen)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(petersen, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(15)
}

pub fn petersen_graph_regularity_test() {
  // Petersen graph is 3-regular (every node has degree 3)
  let petersen = generators.petersen()

  model.all_nodes(petersen)
  |> list.all(fn(node) {
    let degree = model.successors(petersen, node) |> list.length()
    degree == 3
  })
  |> should.be_true()
}

pub fn petersen_graph_outer_pentagon_test() {
  // Verify outer pentagon exists: 0-1-2-3-4-0
  let petersen = generators.petersen()

  let neighbors_0 =
    model.successors(petersen, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors_0, 1)
  |> should.be_true()
  list.contains(neighbors_0, 4)
  |> should.be_true()
}

// Directed vs undirected tests
pub fn complete_directed_test() {
  let directed = generators.complete_with_type(4, model.Directed)

  // In directed K_4, should have 4*3 = 12 edges
  let edge_count =
    model.all_nodes(directed)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(directed, node)
      count + list.length(successors)
    })

  edge_count
  |> should.equal(12)
}

pub fn cycle_directed_test() {
  let directed = generators.cycle_with_type(5, model.Directed)

  // In directed cycle, each node has out-degree 1
  model.all_nodes(directed)
  |> list.all(fn(node) {
    let successors = model.successors(directed, node)
    list.length(successors) == 1
  })
  |> should.be_true()
}

// Edge weight tests
pub fn generated_graphs_have_unit_weights_test() {
  let k3 = generators.complete(3)

  let edges = model.successors(k3, 0)

  list.all(edges, fn(edge) {
    let #(_, weight) = edge
    weight == 1
  })
  |> should.be_true()
}
