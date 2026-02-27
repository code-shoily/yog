import gleam/dict
import gleam/int
import gleam/list
import gleeunit/should
import yog/disjoint_set
import yog/internal/utils

// ============= Creation Tests =============

pub fn new_disjoint_set_test() {
  let d = disjoint_set.new()

  // New should be empty
  d.parents
  |> should.equal(dict.new())

  d.ranks
  |> should.equal(dict.new())
}

// ============= Add Tests =============

pub fn add_single_element_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)

  // Element should be its own parent
  let #(_, root) = disjoint_set.find(d, 1)
  root
  |> should.equal(1)
}

pub fn add_multiple_elements_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)

  // Each should be in its own set
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(_d3, root3) = disjoint_set.find(d2, 3)

  root1
  |> should.equal(1)

  root2
  |> should.equal(2)

  root3
  |> should.equal(3)
}

pub fn add_duplicate_element_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(1)
    |> disjoint_set.add(1)

  // Should still just be one element
  let #(_, root) = disjoint_set.find(d, 1)
  root
  |> should.equal(1)
}

// ============= Find Tests =============

pub fn find_self_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)

  let #(_, root) = disjoint_set.find(d, 1)

  root
  |> should.equal(1)
}

pub fn find_nonexistent_auto_adds_test() {
  let d = disjoint_set.new()

  // Finding non-existent element should auto-add it
  let #(d1, root) = disjoint_set.find(d, 42)

  root
  |> should.equal(42)

  // Should now exist in the disjoint set
  let #(_, root2) = disjoint_set.find(d1, 42)
  root2
  |> should.equal(42)
}

pub fn find_after_union_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.union(1, 2)

  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(_d2, root2) = disjoint_set.find(d1, 2)

  // Both should have same root
  root1
  |> should.equal(root2)
}

// ============= Union Tests =============

pub fn union_two_elements_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.union(1, 2)

  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(_d2, root2) = disjoint_set.find(d1, 2)

  root1
  |> should.equal(root2)
}

pub fn union_multiple_pairs_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(3, 4)

  // 1 and 2 should be in same set
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)

  root1
  |> should.equal(root2)

  // 3 and 4 should be in same set
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(_d4, root4) = disjoint_set.find(d3, 4)

  root3
  |> should.equal(root4)

  // But 1 and 3 should be in different sets
  root1
  |> should.not_equal(root3)
}

pub fn union_chains_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(2, 3)

  // All three should be in same set
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(_d3, root3) = disjoint_set.find(d2, 3)

  root1
  |> should.equal(root2)

  root2
  |> should.equal(root3)
}

pub fn union_already_connected_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(2, 1)

  // Should still be connected
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(_d2, root2) = disjoint_set.find(d1, 2)

  root1
  |> should.equal(root2)
}

pub fn union_without_add_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.union(1, 2)

  // Should auto-add both elements
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(_d2, root2) = disjoint_set.find(d1, 2)

  root1
  |> should.equal(root2)
}

// ============= Path Compression Tests =============

pub fn path_compression_flattens_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    // Create a chain: 1->2->3->4
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(2, 3)
    |> disjoint_set.union(3, 4)

  // Find 1 should trigger path compression
  let #(d1, root1) = disjoint_set.find(d, 1)

  // All elements should now point directly to root
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(_d4, root4) = disjoint_set.find(d3, 4)

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
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    |> disjoint_set.add(5)
    // Create two trees of different sizes
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(1, 3)
    // Tree 1 has rank 1, contains {1,2,3}
    |> disjoint_set.union(4, 5)
    // Tree 2 has rank 1, contains {4,5}
    |> disjoint_set.union(1, 4)

  // All should be in same set
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(d4, root4) = disjoint_set.find(d3, 4)
  let #(_d5, root5) = disjoint_set.find(d4, 5)

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
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    |> disjoint_set.add(5)
    |> disjoint_set.add(6)
    // Component 1: {1, 2}
    |> disjoint_set.union(1, 2)
    // Component 2: {3, 4}
    |> disjoint_set.union(3, 4)
    // Component 3: {5, 6}
    |> disjoint_set.union(5, 6)

  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(d4, root4) = disjoint_set.find(d3, 4)
  let #(d5, root5) = disjoint_set.find(d4, 5)
  let #(_d6, root6) = disjoint_set.find(d5, 6)

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
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    // Create two components
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(3, 4)

  // Verify they're separate
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root3) = disjoint_set.find(d1, 3)

  root1
  |> should.not_equal(root3)

  // Now merge the components
  let d3 = disjoint_set.union(d2, 2, 3)

  // Now all should be in same component
  let #(d4, new_root1) = disjoint_set.find(d3, 1)
  let #(_d5, new_root3) = disjoint_set.find(d4, 3)

  new_root1
  |> should.equal(new_root3)
}

// ============= Stress Tests =============

pub fn large_disjoint_set_test() {
  // Create a disjoint_set with 100 elements
  let numbers = utils.range(1, 100)

  let d =
    list.fold(numbers, disjoint_set.new(), fn(acc, n) {
      disjoint_set.add(acc, n)
    })

  // Union them into 10 components of 10 elements each
  let d2 =
    utils.range(0, 9)
    |> list.fold(d, fn(acc, group) {
      utils.range(1, 9)
      |> list.fold(acc, fn(acc2, i) {
        disjoint_set.union(acc2, group * 10 + 1, group * 10 + i + 1)
      })
    })

  // Verify first component
  let #(d3, root1) = disjoint_set.find(d2, 1)
  let #(_d4, root10) = disjoint_set.find(d3, 10)

  root1
  |> should.equal(root10)

  // Verify different components are separate
  let #(d5, root_comp1) = disjoint_set.find(d2, 5)
  let #(_d6, root_comp2) = disjoint_set.find(d5, 15)

  root_comp1
  |> should.not_equal(root_comp2)
}

pub fn union_all_test() {
  // Create disjoint_set and union all elements into one set
  let numbers = utils.range(1, 50)

  let d =
    list.fold(numbers, disjoint_set.new(), fn(acc, n) {
      disjoint_set.add(acc, n)
    })

  // Union all to element 1
  let d2 =
    utils.range(2, 50)
    |> list.fold(d, fn(acc, n) { disjoint_set.union(acc, 1, n) })

  // All should have same root
  let #(d3, root1) = disjoint_set.find(d2, 1)
  let #(d4, root25) = disjoint_set.find(d3, 25)
  let #(_d5, root50) = disjoint_set.find(d4, 50)

  root1
  |> should.equal(root25)

  root25
  |> should.equal(root50)
}

// ============= String/Generic Type Tests =============

pub fn disjoint_set_with_strings_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add("alice")
    |> disjoint_set.add("bob")
    |> disjoint_set.add("charlie")
    |> disjoint_set.union("alice", "bob")

  let #(d1, root_alice) = disjoint_set.find(d, "alice")
  let #(d2, root_bob) = disjoint_set.find(d1, "bob")
  let #(_d3, root_charlie) = disjoint_set.find(d2, "charlie")

  root_alice
  |> should.equal(root_bob)

  root_alice
  |> should.not_equal(root_charlie)
}

// ============= Convenience Function Tests =============

pub fn from_pairs_empty_test() {
  let d = disjoint_set.from_pairs([])

  disjoint_set.size(d)
  |> should.equal(0)
}

pub fn from_pairs_single_pair_test() {
  let d = disjoint_set.from_pairs([#(1, 2)])

  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(_d2, root2) = disjoint_set.find(d1, 2)

  root1
  |> should.equal(root2)
}

pub fn from_pairs_multiple_pairs_test() {
  let d = disjoint_set.from_pairs([#(1, 2), #(3, 4), #(2, 3)])

  // All should be in one set
  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(_d4, root4) = disjoint_set.find(d3, 4)

  root1
  |> should.equal(root2)

  root2
  |> should.equal(root3)

  root3
  |> should.equal(root4)
}

pub fn from_pairs_separate_components_test() {
  let d = disjoint_set.from_pairs([#(1, 2), #(3, 4), #(5, 6)])

  let #(d1, root1) = disjoint_set.find(d, 1)
  let #(d2, root2) = disjoint_set.find(d1, 2)
  let #(d3, root3) = disjoint_set.find(d2, 3)
  let #(_d4, root5) = disjoint_set.find(d3, 5)

  // 1 and 2 connected
  root1
  |> should.equal(root2)

  // 1 and 3 not connected
  root1
  |> should.not_equal(root3)

  // 1 and 5 not connected
  root1
  |> should.not_equal(root5)
}

pub fn connected_same_set_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.union(1, 2)

  let #(_d1, result) = disjoint_set.connected(d, 1, 2)

  result
  |> should.be_true()
}

pub fn connected_different_sets_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.union(1, 2)

  let #(_d1, result) = disjoint_set.connected(d, 1, 3)

  result
  |> should.be_false()
}

pub fn connected_auto_adds_test() {
  let d = disjoint_set.new()

  // Should auto-add both elements
  let #(d1, result) = disjoint_set.connected(d, 1, 2)

  result
  |> should.be_false()

  // Both should now exist
  disjoint_set.size(d1)
  |> should.equal(2)
}

pub fn size_empty_test() {
  let d = disjoint_set.new()

  disjoint_set.size(d)
  |> should.equal(0)
}

pub fn size_after_adds_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)

  disjoint_set.size(d)
  |> should.equal(3)
}

pub fn size_after_union_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.union(1, 2)

  // Union doesn't change size, just connectivity
  disjoint_set.size(d)
  |> should.equal(2)
}

pub fn count_sets_empty_test() {
  let d = disjoint_set.new()

  disjoint_set.count_sets(d)
  |> should.equal(0)
}

pub fn count_sets_all_separate_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)

  disjoint_set.count_sets(d)
  |> should.equal(3)
}

pub fn count_sets_after_unions_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.add(4)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(3, 4)

  // Should have 2 sets: {1,2} and {3,4}
  disjoint_set.count_sets(d)
  |> should.equal(2)
}

pub fn count_sets_all_connected_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)
    |> disjoint_set.union(1, 2)
    |> disjoint_set.union(2, 3)

  disjoint_set.count_sets(d)
  |> should.equal(1)
}

pub fn to_lists_empty_test() {
  let d = disjoint_set.new()

  disjoint_set.to_lists(d)
  |> should.equal([])
}

pub fn to_lists_single_elements_test() {
  let d =
    disjoint_set.new()
    |> disjoint_set.add(1)
    |> disjoint_set.add(2)
    |> disjoint_set.add(3)

  let result = disjoint_set.to_lists(d)

  // Should have 3 singleton sets
  list.length(result)
  |> should.equal(3)

  // Each set should have 1 element
  list.all(result, fn(set) { list.length(set) == 1 })
  |> should.be_true()
}

pub fn to_lists_multiple_sets_test() {
  let d = disjoint_set.from_pairs([#(1, 2), #(3, 4), #(5, 6)])

  let result = disjoint_set.to_lists(d)

  // Should have 3 sets
  list.length(result)
  |> should.equal(3)

  // Each set should have 2 elements
  list.all(result, fn(set) { list.length(set) == 2 })
  |> should.be_true()
}

pub fn to_lists_one_large_set_test() {
  let d = disjoint_set.from_pairs([#(1, 2), #(2, 3), #(3, 4)])

  let result = disjoint_set.to_lists(d)

  // Should have 1 set
  list.length(result)
  |> should.equal(1)

  // That set should have 4 elements
  case result {
    [set] -> {
      list.length(set)
      |> should.equal(4)
    }
    _ -> {
      should.fail()
    }
  }
}

pub fn to_lists_preserves_elements_test() {
  let d = disjoint_set.from_pairs([#(1, 2), #(3, 4)])

  let result = disjoint_set.to_lists(d)

  // Flatten to get all elements
  let all_elements =
    result
    |> list.flatten()
    |> list.sort(int.compare)

  all_elements
  |> should.equal([1, 2, 3, 4])
}
