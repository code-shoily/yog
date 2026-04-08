import gleam/list
import gleeunit/should
import yog/generator/classic as generators
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

pub fn complete_graph_empty_test() {
  let k0 = generators.complete(0)
  model.all_nodes(k0)
  |> list.length()
  |> should.equal(0)

  let k_neg = generators.complete(-5)
  model.all_nodes(k_neg)
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

  let c1 = generators.cycle(1)
  model.all_nodes(c1)
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

pub fn path_graph_empty_test() {
  let p0 = generators.path(0)
  model.all_nodes(p0)
  |> list.length()
  |> should.equal(0)

  let p_neg = generators.path(-3)
  model.all_nodes(p_neg)
  |> list.length()
  |> should.equal(0)
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

pub fn star_graph_small_test() {
  // Star with 1 node has no edges
  let s1 = generators.star(1)
  model.all_nodes(s1)
  |> list.length()
  |> should.equal(1)
  model.successors(s1, 0)
  |> list.length()
  |> should.equal(0)

  // Star with 0 or negative nodes is empty
  let s0 = generators.star(0)
  model.all_nodes(s0)
  |> list.length()
  |> should.equal(0)
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

pub fn wheel_graph_small_test() {
  // Wheel requires at least 4 nodes
  let w3 = generators.wheel(3)
  model.all_nodes(w3)
  |> list.length()
  |> should.equal(0)
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

pub fn complete_bipartite_empty_test() {
  let k00 = generators.complete_bipartite(0, 0)
  model.all_nodes(k00)
  |> list.length()
  |> should.equal(0)

  let k03 = generators.complete_bipartite(0, 3)
  model.all_nodes(k03)
  |> list.length()
  |> should.equal(3)
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

pub fn empty_graph_zero_test() {
  let empty = generators.empty(0)
  model.all_nodes(empty)
  |> list.length()
  |> should.equal(0)
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

pub fn binary_tree_empty_test() {
  let tree = generators.binary_tree(-1)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(0)

  let tree0 = generators.binary_tree(0)
  model.all_nodes(tree0)
  |> list.length()
  |> should.equal(1)
}

// k-ary tree tests
pub fn kary_tree_binary_equivalent_test() {
  // k-ary tree with arity 2 should be equivalent to binary tree
  let kary = generators.kary_tree(3, arity: 2)
  let binary = generators.binary_tree(3)

  model.all_nodes(kary)
  |> list.length()
  |> should.equal(model.all_nodes(binary) |> list.length())
}

pub fn kary_tree_ternary_test() {
  // Ternary tree of depth 2: (3^3 - 1) / (3 - 1) = 26 / 2 = 13 nodes
  let tree = generators.kary_tree(2, arity: 3)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(13)
}

pub fn kary_tree_star_test() {
  // k-ary tree with depth 1 is a star
  let kary = generators.kary_tree(1, arity: 5)
  let star = generators.star(6)

  model.all_nodes(kary)
  |> list.length()
  |> should.equal(model.all_nodes(star) |> list.length())
}

pub fn kary_tree_path_test() {
  // k-ary tree with arity 1 is a path
  let kary = generators.kary_tree(4, arity: 1)
  let path = generators.path(5)

  model.all_nodes(kary)
  |> list.length()
  |> should.equal(model.all_nodes(path) |> list.length())
}

pub fn kary_tree_invalid_test() {
  let tree = generators.kary_tree(3, arity: 0)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(0)

  let tree_neg = generators.kary_tree(-1, arity: 2)
  model.all_nodes(tree_neg)
  |> list.length()
  |> should.equal(0)
}

// Complete k-ary tree tests
pub fn complete_kary_nodes_test() {
  let tree = generators.complete_kary(20, arity: 3)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(20)
}

pub fn complete_kary_edges_test() {
  // Tree with n nodes has n-1 edges
  let tree = generators.complete_kary(7, arity: 2)
  model.edge_count(tree)
  |> should.equal(6)
}

pub fn complete_kary_single_node_test() {
  let tree = generators.complete_kary(1, arity: 3)
  model.all_nodes(tree)
  |> list.length()
  |> should.equal(1)
  model.edge_count(tree)
  |> should.equal(0)
}

// Caterpillar tree tests
pub fn caterpillar_nodes_test() {
  let cat = generators.caterpillar(20, spine_length: 5)
  model.all_nodes(cat)
  |> list.length()
  |> should.equal(20)
}

pub fn caterpillar_edges_test() {
  // Tree with n nodes has n-1 edges
  let cat = generators.caterpillar(15, spine_length: 5)
  model.edge_count(cat)
  |> should.equal(14)
}

pub fn caterpillar_spine_only_test() {
  // When spine_length = n, it's a path
  let cat = generators.caterpillar(5, spine_length: 5)
  let path = generators.path(5)

  model.edge_count(cat)
  |> should.equal(model.edge_count(path))
}

pub fn caterpillar_star_test() {
  // When spine_length = 1, it's a star
  let cat = generators.caterpillar(5, spine_length: 1)
  let star = generators.star(5)

  model.edge_count(cat)
  |> should.equal(model.edge_count(star))
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

pub fn grid_2d_invalid_test() {
  let grid = generators.grid_2d(0, 5)
  model.all_nodes(grid)
  |> list.length()
  |> should.equal(0)

  let grid2 = generators.grid_2d(3, 0)
  model.all_nodes(grid2)
  |> list.length()
  |> should.equal(0)
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

// Hypercube tests
pub fn hypercube_nodes_test() {
  // 3-cube has 8 nodes
  let cube = generators.hypercube(3)
  model.all_nodes(cube)
  |> list.length()
  |> should.equal(8)
}

pub fn hypercube_edges_test() {
  // 3-cube has 12 edges (n * 2^(n-1) = 3 * 4 = 12)
  let cube = generators.hypercube(3)

  let edge_count =
    model.all_nodes(cube)
    |> list.fold(0, fn(count, node) {
      let successors = model.successors(cube, node)
      count + list.length(successors)
    })

  edge_count / 2
  |> should.equal(12)
}

pub fn hypercube_degree_test() {
  // n-cube is n-regular
  let cube = generators.hypercube(4)

  model.all_nodes(cube)
  |> list.all(fn(node) {
    let degree = model.successors(cube, node) |> list.length()
    degree == 4
  })
  |> should.be_true()
}

pub fn hypercube_cube_equivalence_test() {
  // hypercube(3) should be equivalent to cube()
  let h3 = generators.hypercube(3)
  let c = generators.cube()

  model.all_nodes(h3)
  |> list.length()
  |> should.equal(model.all_nodes(c) |> list.length())
}

pub fn hypercube_invalid_test() {
  let h = generators.hypercube(-1)
  model.all_nodes(h)
  |> list.length()
  |> should.equal(0)

  let h0 = generators.hypercube(0)
  model.all_nodes(h0)
  |> list.length()
  |> should.equal(1)
}

// Ladder graph tests
pub fn ladder_nodes_test() {
  // 4-rung ladder has 8 nodes
  let ladder = generators.ladder(4)
  model.all_nodes(ladder)
  |> list.length()
  |> should.equal(8)
}

pub fn ladder_edges_test() {
  // 4-rung ladder has 10 edges (3n - 2 = 12 - 2 = 10)
  let ladder = generators.ladder(4)
  model.edge_count(ladder)
  |> should.equal(10)
}

pub fn ladder_degree_test() {
  // End nodes have degree 2, interior have degree 3
  let ladder = generators.ladder(4)

  // Node 0 (end of bottom rail) has degree 2
  model.successors(ladder, 0)
  |> list.length()
  |> should.equal(2)

  // Node 2 (interior of bottom rail) has degree 3
  model.successors(ladder, 2)
  |> list.length()
  |> should.equal(3)
}

pub fn ladder_invalid_test() {
  let l = generators.ladder(0)
  model.all_nodes(l)
  |> list.length()
  |> should.equal(0)

  let l_neg = generators.ladder(-3)
  model.all_nodes(l_neg)
  |> list.length()
  |> should.equal(0)
}

// Circular ladder (prism) tests
pub fn circular_ladder_nodes_test() {
  // CL_5 has 10 nodes
  let cl = generators.circular_ladder(5)
  model.all_nodes(cl)
  |> list.length()
  |> should.equal(10)
}

pub fn circular_ladder_edges_test() {
  // CL_5 has 15 edges (3n = 15)
  let cl = generators.circular_ladder(5)
  model.edge_count(cl)
  |> should.equal(15)
}

pub fn circular_ladder_cube_test() {
  // CL_4 is the cube graph (isomorphic to hypercube(3))
  let cl4 = generators.circular_ladder(4)
  let cube = generators.cube()

  model.all_nodes(cl4)
  |> list.length()
  |> should.equal(model.all_nodes(cube) |> list.length())

  model.edge_count(cl4)
  |> should.equal(model.edge_count(cube))
}

pub fn circular_ladder_prism_alias_test() {
  // prism(n) should be the same as circular_ladder(n)
  let prism = generators.prism(5)
  let ladder = generators.circular_ladder(5)

  model.all_nodes(prism)
  |> list.length()
  |> should.equal(model.all_nodes(ladder) |> list.length())
}

pub fn circular_ladder_invalid_test() {
  // CL requires at least 3 rungs
  let cl = generators.circular_ladder(2)
  model.all_nodes(cl)
  |> list.length()
  |> should.equal(0)
}

// Möbius ladder tests
pub fn mobius_ladder_nodes_test() {
  // ML_6 has 12 nodes
  let ml = generators.mobius_ladder(6)
  model.all_nodes(ml)
  |> list.length()
  |> should.equal(12)
}

pub fn mobius_ladder_edges_test() {
  // ML_6 has 18 edges (3n = 18)
  let ml = generators.mobius_ladder(6)
  model.edge_count(ml)
  |> should.equal(18)
}

pub fn mobius_ladder_properties_test() {
  // ML_4 has 8 nodes (2n) and is 3-regular
  let ml4 = generators.mobius_ladder(4)

  model.all_nodes(ml4)
  |> list.length()
  |> should.equal(8)

  model.edge_count(ml4)
  |> should.equal(12)
}

pub fn mobius_ladder_invalid_test() {
  // ML requires at least 2 rungs
  let ml = generators.mobius_ladder(1)
  model.all_nodes(ml)
  |> list.length()
  |> should.equal(0)
}

// Friendship graph tests
pub fn friendship_nodes_test() {
  // F_3 has 7 nodes (1 center + 6 outer)
  let f3 = generators.friendship(3)
  model.all_nodes(f3)
  |> list.length()
  |> should.equal(7)
}

pub fn friendship_edges_test() {
  // F_3 has 9 edges (3n = 9)
  let f3 = generators.friendship(3)
  model.edge_count(f3)
  |> should.equal(9)
}

pub fn friendship_center_degree_test() {
  // Center has degree 2n
  let f4 = generators.friendship(4)

  model.successors(f4, 0)
  |> list.length()
  |> should.equal(8)
}

pub fn friendship_outer_degree_test() {
  // Outer vertices have degree 2
  let f3 = generators.friendship(3)

  model.successors(f3, 1)
  |> list.length()
  |> should.equal(2)
}

pub fn friendship_invalid_test() {
  let f = generators.friendship(0)
  model.all_nodes(f)
  |> list.length()
  |> should.equal(0)

  let f_neg = generators.friendship(-1)
  model.all_nodes(f_neg)
  |> list.length()
  |> should.equal(0)
}

// Windmill graph tests
pub fn windmill_nodes_test() {
  // Windmill of 4 triangles: 1 + 4*(3-1) = 9 nodes
  let w4 = generators.windmill(4, clique_size: 3)
  model.all_nodes(w4)
  |> list.length()
  |> should.equal(9)
}

pub fn windmill_edges_test() {
  // Windmill of 4 triangles: 4 * 3 = 12 edges
  let w4 = generators.windmill(4, clique_size: 3)
  model.edge_count(w4)
  |> should.equal(12)
}

pub fn windmill_friendship_equivalence_test() {
  // Windmill with clique_size 3 is friendship graph
  let w3 = generators.windmill(3, clique_size: 3)
  let f3 = generators.friendship(3)

  model.all_nodes(w3)
  |> list.length()
  |> should.equal(model.all_nodes(f3) |> list.length())

  model.edge_count(w3)
  |> should.equal(model.edge_count(f3))
}

pub fn windmill_invalid_test() {
  // n < 1
  let w = generators.windmill(0, clique_size: 3)
  model.all_nodes(w)
  |> list.length()
  |> should.equal(0)

  // k < 2
  let w2 = generators.windmill(3, clique_size: 1)
  model.all_nodes(w2)
  |> list.length()
  |> should.equal(0)
}

// Book graph tests
pub fn book_nodes_test() {
  // B_3 has 5 nodes (2 spine + 3 page)
  let book = generators.book(3)
  model.all_nodes(book)
  |> list.length()
  |> should.equal(5)
}

pub fn book_edges_test() {
  // B_3 has 7 edges (2n + 1 = 7)
  let book = generators.book(3)
  model.edge_count(book)
  |> should.equal(7)
}

pub fn book_spine_test() {
  // Nodes 0 and 1 form the spine and are connected
  let book = generators.book(3)

  let neighbors_0 = model.successors(book, 0) |> list.map(fn(edge) { edge.0 })
  list.contains(neighbors_0, 1)
  |> should.be_true()
}

pub fn book_invalid_test() {
  let b = generators.book(0)
  model.all_nodes(b)
  |> list.length()
  |> should.equal(0)
}

// Crown graph tests
pub fn crown_nodes_test() {
  // crown(4) has 8 nodes
  let crown = generators.crown(4)
  model.all_nodes(crown)
  |> list.length()
  |> should.equal(8)
}

pub fn crown_edges_test() {
  // crown(4) has 12 edges (n(n-1) = 4*3 = 12)
  let crown = generators.crown(4)
  model.edge_count(crown)
  |> should.equal(12)
}

pub fn crown_degree_test() {
  // crown(n) is (n-1)-regular
  let crown = generators.crown(4)

  model.all_nodes(crown)
  |> list.all(fn(node) {
    let degree = model.successors(crown, node) |> list.length()
    degree == 3
  })
  |> should.be_true()
}

pub fn crown_c4_test() {
  // crown(2) is C_4 (K_{2,2} minus perfect matching)
  let c2 = generators.crown(2)
  let c4 = generators.cycle(4)

  // Both have 4 nodes
  model.all_nodes(c2)
  |> list.length()
  |> should.equal(model.all_nodes(c4) |> list.length())

  // crown(2) has n(n-1) = 2*1 = 2 edges
  // C_4 has 4 edges
  // Note: crown(2) is not exactly C_4, it's K_{2,2} minus perfect matching
  model.edge_count(c2)
  |> should.equal(2)
}

pub fn crown_invalid_test() {
  // crown requires at least 2
  let c = generators.crown(1)
  model.all_nodes(c)
  |> list.length()
  |> should.equal(0)
}

// Turán graph tests
pub fn turan_nodes_test() {
  let turan = generators.turan(10, 3)
  model.all_nodes(turan)
  |> list.length()
  |> should.equal(10)
}

pub fn turan_bipartite_test() {
  // T(n, 2) is the complete bipartite graph
  let turan = generators.turan(6, 2)
  let k33 = generators.complete_bipartite(3, 3)

  model.all_nodes(turan)
  |> list.length()
  |> should.equal(model.all_nodes(k33) |> list.length())
}

pub fn turan_complete_test() {
  // When r >= n, T(n, r) is a complete graph
  let turan = generators.turan(5, 10)
  let k5 = generators.complete(5)

  model.edge_count(turan)
  |> should.equal(model.edge_count(k5))
}

pub fn turan_invalid_test() {
  let t = generators.turan(0, 3)
  model.all_nodes(t)
  |> list.length()
  |> should.equal(0)

  let t2 = generators.turan(5, 0)
  model.all_nodes(t2)
  |> list.length()
  |> should.equal(0)
}

// Platonic solids tests
pub fn tetrahedron_nodes_test() {
  let tetra = generators.tetrahedron()
  model.all_nodes(tetra)
  |> list.length()
  |> should.equal(4)
}

pub fn tetrahedron_edges_test() {
  let tetra = generators.tetrahedron()
  model.edge_count(tetra)
  |> should.equal(6)
}

pub fn tetrahedron_complete_equivalence_test() {
  // Tetrahedron is K_4
  let tetra = generators.tetrahedron()
  let k4 = generators.complete(4)

  model.edge_count(tetra)
  |> should.equal(model.edge_count(k4))
}

pub fn cube_nodes_test() {
  let cube = generators.cube()
  model.all_nodes(cube)
  |> list.length()
  |> should.equal(8)
}

pub fn cube_edges_test() {
  let cube = generators.cube()
  model.edge_count(cube)
  |> should.equal(12)
}

pub fn cube_hypercube_equivalence_test() {
  // Cube is 3D hypercube
  let cube = generators.cube()
  let h3 = generators.hypercube(3)

  model.all_nodes(cube)
  |> list.length()
  |> should.equal(model.all_nodes(h3) |> list.length())
}

pub fn octahedron_nodes_test() {
  let octa = generators.octahedron()
  model.all_nodes(octa)
  |> list.length()
  |> should.equal(6)
}

pub fn octahedron_edges_test() {
  let octa = generators.octahedron()
  model.edge_count(octa)
  |> should.equal(12)
}

pub fn octahedron_degree_test() {
  // Octahedron is 4-regular
  let octa = generators.octahedron()

  model.all_nodes(octa)
  |> list.all(fn(node) {
    let degree = model.successors(octa, node) |> list.length()
    degree == 4
  })
  |> should.be_true()
}

pub fn dodecahedron_nodes_test() {
  let dodec = generators.dodecahedron()
  model.all_nodes(dodec)
  |> list.length()
  |> should.equal(20)
}

pub fn dodecahedron_edges_test() {
  let dodec = generators.dodecahedron()
  model.edge_count(dodec)
  |> should.equal(30)
}

pub fn dodecahedron_degree_test() {
  // Dodecahedron is 3-regular
  let dodec = generators.dodecahedron()

  model.all_nodes(dodec)
  |> list.all(fn(node) {
    let degree = model.successors(dodec, node) |> list.length()
    degree == 3
  })
  |> should.be_true()
}

pub fn icosahedron_nodes_test() {
  let icosa = generators.icosahedron()
  model.all_nodes(icosa)
  |> list.length()
  |> should.equal(12)
}

pub fn icosahedron_edges_test() {
  let icosa = generators.icosahedron()
  model.edge_count(icosa)
  |> should.equal(30)
}

pub fn icosahedron_degree_test() {
  // Icosahedron is 5-regular
  let icosa = generators.icosahedron()

  model.all_nodes(icosa)
  |> list.all(fn(node) {
    let degree = model.successors(icosa, node) |> list.length()
    degree == 5
  })
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
