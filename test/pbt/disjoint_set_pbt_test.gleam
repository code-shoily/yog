import gleam/int
import gleam/list
import gleeunit
import qcheck
import yog/disjoint_set

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// GENERATORS
// ============================================================================

fn pairs_generator() {
  use num_nodes <- qcheck.bind(qcheck.bounded_int(1, 50))
  use num_pairs <- qcheck.bind(qcheck.bounded_int(0, 100))
  qcheck.fixed_length_list_from(
    qcheck.tuple2(
      qcheck.bounded_int(0, num_nodes - 1),
      qcheck.bounded_int(0, num_nodes - 1),
    ),
    num_pairs,
  )
}

// ============================================================================
// PROPERTIES: EQUIVALENCE RELATION
// ============================================================================

/// Property: Every element is connected to itself.
pub fn connected_reflexivity_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let all_connected_to_self =
    disjoint_set.to_lists(dsu)
    |> list.flatten()
    |> list.all(fn(element) {
      let #(_, is_connected) = disjoint_set.connected(dsu, element, element)
      is_connected
    })

  assert all_connected_to_self
}

/// Property: If x is connected to y, then y is connected to x.
pub fn connected_symmetry_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let all_elements =
    disjoint_set.to_lists(dsu)
    |> list.flatten()

  let is_symmetric =
    list.combination_pairs(all_elements)
    |> list.all(fn(pair) {
      let #(x, y) = pair
      let #(_, c1) = disjoint_set.connected(dsu, x, y)
      let #(_, c2) = disjoint_set.connected(dsu, y, x)
      c1 == c2
    })

  assert is_symmetric
}

/// Property: If x is connected to y and y is connected to z, then x is connected to z.
pub fn connected_transitivity_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let all_elements =
    disjoint_set.to_lists(dsu)
    |> list.flatten()

  // We test a subset of triples to avoid O(n^3) explosion if elements are many
  let triples = list.take(list.combination_pairs(all_elements), 50)

  let is_transitive =
    list.all(triples, fn(pair) {
      let #(x, y) = pair
      let #(_, xy) = disjoint_set.connected(dsu, x, y)
      case xy {
        False -> True
        True -> {
          // If x is connected to y, then for any z it is connected to, x must also be connected to it
          list.all(all_elements, fn(z) {
            let #(_, yz) = disjoint_set.connected(dsu, y, z)
            let #(_, xz) = disjoint_set.connected(dsu, x, z)
            !yz || xz
          })
        }
      }
    })

  assert is_transitive
}

// ============================================================================
// PROPERTIES: STRUCTURAL INVARIANTS
// ============================================================================

/// Property: count_sets must match the number of lists in to_lists.
pub fn count_sets_consistent_with_to_lists_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let count = disjoint_set.count_sets(dsu)
  let lists = disjoint_set.to_lists(dsu)

  assert count == list.length(lists)
}

/// Property: size must match the sum of lengths of lists in to_lists.
pub fn size_consistent_with_to_lists_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let total_size = disjoint_set.size(dsu)
  let list_size =
    disjoint_set.to_lists(dsu)
    |> list.map(list.length)
    |> list.fold(0, int.add)

  assert total_size == list_size
}

/// Property: find returns the same root if and only if elements are connected.
pub fn find_root_consistency_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  let all_elements =
    disjoint_set.to_lists(dsu)
    |> list.flatten()

  let is_consistent =
    list.combination_pairs(all_elements)
    |> list.all(fn(pair) {
      let #(x, y) = pair
      let #(dsu1, root_x) = disjoint_set.find(dsu, x)
      let #(_, root_y) = disjoint_set.find(dsu1, y)
      let #(_, is_connected) = disjoint_set.connected(dsu, x, y)

      { root_x == root_y } == is_connected
    })

  assert is_consistent
}

// ============================================================================
// PROPERTIES: MERGE INVARIANTS
// ============================================================================

/// Property: union(x, y) followed by connected(x, y) should be true.
pub fn union_guarantees_connectivity_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  // Pick two random elements from the range
  use #(x, y) <- qcheck.given(qcheck.tuple2(
    qcheck.bounded_int(0, 100),
    qcheck.bounded_int(0, 100),
  ))

  let dsu_after = disjoint_set.union(dsu, x, y)
  let #(_, is_connected) = disjoint_set.connected(dsu_after, x, y)

  assert is_connected
}

/// Property: union is idempotent (functionally).
pub fn union_idempotence_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)

  use #(x, y) <- qcheck.given(qcheck.tuple2(
    qcheck.bounded_int(0, 100),
    qcheck.bounded_int(0, 100),
  ))

  let dsu1 = disjoint_set.union(dsu, x, y)
  let dsu2 = disjoint_set.union(dsu1, x, y)

  // Functional equivalence check
  // Any element's root should be same in dsu1 and dsu2
  // We check a few relevant points
  let #(dsu1a, root1x) = disjoint_set.find(dsu1, x)
  let #(dsu2a, root2x) = disjoint_set.find(dsu2, x)
  let #(_, root1y) = disjoint_set.find(dsu1a, y)
  let #(_, root2y) = disjoint_set.find(dsu2a, y)

  assert root1x == root2x
  assert root1y == root2y
  assert root2x == root2y
}

/// Property: size non-decreasing.
pub fn size_non_decreasing_test() {
  use pairs <- qcheck.given(pairs_generator())
  let dsu = disjoint_set.from_pairs(pairs)
  let initial_size = disjoint_set.size(dsu)

  use #(x, y) <- qcheck.given(qcheck.tuple2(
    qcheck.bounded_int(0, 100),
    qcheck.bounded_int(0, 100),
  ))

  let dsu_after = disjoint_set.union(dsu, x, y)
  let after_size = disjoint_set.size(dsu_after)

  assert after_size >= initial_size
}
