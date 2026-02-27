import gleam/dict
import gleam/list
import gleeunit/should
import yog/internal/dsu
import yog/internal/utils

// ============= Creation Tests =============

pub fn new_dsu_test() {
  let d = dsu.new()

  // New DSU should be empty
  d.parents
  |> should.equal(dict.new())

  d.ranks
  |> should.equal(dict.new())
}

// ============= Add Tests =============

pub fn add_single_element_test() {
  let d =
    dsu.new()
    |> dsu.add(1)

  // Element should be its own parent
  let #(_, root) = dsu.find(d, 1)
  root
  |> should.equal(1)
}

pub fn add_multiple_elements_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)

  // Each should be in its own set
  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root2) = dsu.find(d1, 2)
  let #(_d3, root3) = dsu.find(d2, 3)

  root1
  |> should.equal(1)

  root2
  |> should.equal(2)

  root3
  |> should.equal(3)
}

pub fn add_duplicate_element_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(1)
    |> dsu.add(1)

  // Should still just be one element
  let #(_, root) = dsu.find(d, 1)
  root
  |> should.equal(1)
}

// ============= Find Tests =============

pub fn find_self_test() {
  let d =
    dsu.new()
    |> dsu.add(1)

  let #(_, root) = dsu.find(d, 1)

  root
  |> should.equal(1)
}

pub fn find_nonexistent_auto_adds_test() {
  let d = dsu.new()

  // Finding non-existent element should auto-add it
  let #(d1, root) = dsu.find(d, 42)

  root
  |> should.equal(42)

  // Should now exist in the DSU
  let #(_, root2) = dsu.find(d1, 42)
  root2
  |> should.equal(42)
}

pub fn find_after_union_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.union(1, 2)

  let #(d1, root1) = dsu.find(d, 1)
  let #(_d2, root2) = dsu.find(d1, 2)

  // Both should have same root
  root1
  |> should.equal(root2)
}

// ============= Union Tests =============

pub fn union_two_elements_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.union(1, 2)

  let #(d1, root1) = dsu.find(d, 1)
  let #(_d2, root2) = dsu.find(d1, 2)

  root1
  |> should.equal(root2)
}

pub fn union_multiple_pairs_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.add(4)
    |> dsu.union(1, 2)
    |> dsu.union(3, 4)

  // 1 and 2 should be in same set
  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root2) = dsu.find(d1, 2)

  root1
  |> should.equal(root2)

  // 3 and 4 should be in same set
  let #(d3, root3) = dsu.find(d2, 3)
  let #(_d4, root4) = dsu.find(d3, 4)

  root3
  |> should.equal(root4)

  // But 1 and 3 should be in different sets
  root1
  |> should.not_equal(root3)
}

pub fn union_chains_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.union(1, 2)
    |> dsu.union(2, 3)

  // All three should be in same set
  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root2) = dsu.find(d1, 2)
  let #(_d3, root3) = dsu.find(d2, 3)

  root1
  |> should.equal(root2)

  root2
  |> should.equal(root3)
}

pub fn union_already_connected_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.union(1, 2)
    |> dsu.union(1, 2)
    |> dsu.union(2, 1)

  // Should still be connected
  let #(d1, root1) = dsu.find(d, 1)
  let #(_d2, root2) = dsu.find(d1, 2)

  root1
  |> should.equal(root2)
}

pub fn union_without_add_test() {
  let d =
    dsu.new()
    |> dsu.union(1, 2)

  // Should auto-add both elements
  let #(d1, root1) = dsu.find(d, 1)
  let #(_d2, root2) = dsu.find(d1, 2)

  root1
  |> should.equal(root2)
}

// ============= Path Compression Tests =============

pub fn path_compression_flattens_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.add(4)
    // Create a chain: 1->2->3->4
    |> dsu.union(1, 2)
    |> dsu.union(2, 3)
    |> dsu.union(3, 4)

  // Find 1 should trigger path compression
  let #(d1, root1) = dsu.find(d, 1)

  // All elements should now point directly to root
  let #(d2, root2) = dsu.find(d1, 2)
  let #(d3, root3) = dsu.find(d2, 3)
  let #(_d4, root4) = dsu.find(d3, 4)

  root1
  |> should.equal(root2)

  root2
  |> should.equal(root3)

  root3
  |> should.equal(root4)
}

// ============= Union by Rank Tests =============

pub fn union_by_rank_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.add(4)
    |> dsu.add(5)
    // Create two trees of different sizes
    |> dsu.union(1, 2)
    |> dsu.union(1, 3)
    // Tree 1 has rank 1, contains {1,2,3}
    |> dsu.union(4, 5)
    // Tree 2 has rank 1, contains {4,5}
    |> dsu.union(1, 4)

  // All should be in same set
  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root2) = dsu.find(d1, 2)
  let #(d3, root3) = dsu.find(d2, 3)
  let #(d4, root4) = dsu.find(d3, 4)
  let #(_d5, root5) = dsu.find(d4, 5)

  root1
  |> should.equal(root2)

  root2
  |> should.equal(root3)

  root3
  |> should.equal(root4)

  root4
  |> should.equal(root5)
}

// ============= Connected Components Tests =============

pub fn three_components_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.add(4)
    |> dsu.add(5)
    |> dsu.add(6)
    // Component 1: {1, 2}
    |> dsu.union(1, 2)
    // Component 2: {3, 4}
    |> dsu.union(3, 4)
    // Component 3: {5, 6}
    |> dsu.union(5, 6)

  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root2) = dsu.find(d1, 2)
  let #(d3, root3) = dsu.find(d2, 3)
  let #(d4, root4) = dsu.find(d3, 4)
  let #(d5, root5) = dsu.find(d4, 5)
  let #(_d6, root6) = dsu.find(d5, 6)

  // Component 1
  root1
  |> should.equal(root2)

  // Component 2
  root3
  |> should.equal(root4)

  // Component 3
  root5
  |> should.equal(root6)

  // Different components
  root1
  |> should.not_equal(root3)

  root1
  |> should.not_equal(root5)

  root3
  |> should.not_equal(root5)
}

pub fn merge_components_test() {
  let d =
    dsu.new()
    |> dsu.add(1)
    |> dsu.add(2)
    |> dsu.add(3)
    |> dsu.add(4)
    // Create two components
    |> dsu.union(1, 2)
    |> dsu.union(3, 4)

  // Verify they're separate
  let #(d1, root1) = dsu.find(d, 1)
  let #(d2, root3) = dsu.find(d1, 3)

  root1
  |> should.not_equal(root3)

  // Now merge the components
  let d3 = dsu.union(d2, 2, 3)

  // Now all should be in same component
  let #(d4, new_root1) = dsu.find(d3, 1)
  let #(_d5, new_root3) = dsu.find(d4, 3)

  new_root1
  |> should.equal(new_root3)
}

// ============= Stress Tests =============

pub fn large_dsu_test() {
  // Create a DSU with 100 elements
  let numbers = utils.range(1, 100)

  let d = list.fold(numbers, dsu.new(), fn(acc, n) { dsu.add(acc, n) })

  // Union them into 10 components of 10 elements each
  let d2 =
    utils.range(0, 9)
    |> list.fold(d, fn(acc, group) {
      utils.range(1, 9)
      |> list.fold(acc, fn(acc2, i) {
        dsu.union(acc2, group * 10 + 1, group * 10 + i + 1)
      })
    })

  // Verify first component
  let #(d3, root1) = dsu.find(d2, 1)
  let #(_d4, root10) = dsu.find(d3, 10)

  root1
  |> should.equal(root10)

  // Verify different components are separate
  let #(d5, root_comp1) = dsu.find(d2, 5)
  let #(_d6, root_comp2) = dsu.find(d5, 15)

  root_comp1
  |> should.not_equal(root_comp2)
}

pub fn union_all_test() {
  // Create DSU and union all elements into one set
  let numbers = utils.range(1, 50)

  let d = list.fold(numbers, dsu.new(), fn(acc, n) { dsu.add(acc, n) })

  // Union all to element 1
  let d2 =
    utils.range(2, 50)
    |> list.fold(d, fn(acc, n) { dsu.union(acc, 1, n) })

  // All should have same root
  let #(d3, root1) = dsu.find(d2, 1)
  let #(d4, root25) = dsu.find(d3, 25)
  let #(_d5, root50) = dsu.find(d4, 50)

  root1
  |> should.equal(root25)

  root25
  |> should.equal(root50)
}

// ============= String/Generic Type Tests =============

pub fn dsu_with_strings_test() {
  let d =
    dsu.new()
    |> dsu.add("alice")
    |> dsu.add("bob")
    |> dsu.add("charlie")
    |> dsu.union("alice", "bob")

  let #(d1, root_alice) = dsu.find(d, "alice")
  let #(d2, root_bob) = dsu.find(d1, "bob")
  let #(_d3, root_charlie) = dsu.find(d2, "charlie")

  root_alice
  |> should.equal(root_bob)

  root_alice
  |> should.not_equal(root_charlie)
}
