////
//// Property Tests for Graph Operations
////
//// These tests verify mathematical properties and invariants of graph operation.

import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleeunit
import qcheck
import yog/model.{type Graph}
import yog/operation
import yog/qcheck_generators

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// CATEGORY 1: SET-THEORETIC OPERATIONS PROPERTIES
// ============================================================================

/// Union is commutative: A ∪ B = B ∪ A (same size)
pub fn union_commutative_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let union_ab = operation.union(g1, g2)
  let union_ba = operation.union(g2, g1)

  // Check same number of nodes and edges
  assert model.order(union_ab) == model.order(union_ba)
  assert model.edge_count(union_ab) == model.edge_count(union_ba)
}

/// Intersection is commutative: A ∩ B = B ∩ A (same size)
pub fn intersection_commutative_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let inter_ab = operation.intersection(g1, g2)
  let inter_ba = operation.intersection(g2, g1)

  assert model.order(inter_ab) == model.order(inter_ba)
  assert model.edge_count(inter_ab) == model.edge_count(inter_ba)
}

/// Identity: A ∪ ∅ = A
pub fn union_empty_identity_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  let result = operation.union(g, empty)

  assert model.order(result) == model.order(g)
  assert model.edge_count(result) == model.edge_count(g)
}

/// Annihilation: A ∩ ∅ = ∅
pub fn intersection_empty_annihilation_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  let result = operation.intersection(g, empty)

  assert model.order(result) == 0
  assert model.edge_count(result) == 0
}

// ============================================================================
// CATEGORY 2: DIFFERENCE AND SYMMETRIC DIFFERENCE PROPERTIES
// ============================================================================

/// A - A = ∅
pub fn difference_self_is_empty_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let result = operation.difference(g, g)

  assert model.order(result) == 0
  assert model.edge_count(result) == 0
}

/// A - ∅ = A
pub fn difference_empty_is_identity_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  let result = operation.difference(g, empty)

  assert model.order(result) == model.order(g)
  assert model.edge_count(result) == model.edge_count(g)
}

/// Symmetric difference is commutative: A Δ B = B Δ A
pub fn symmetric_difference_commutative_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let sym_ab = operation.symmetric_difference(g1, g2)
  let sym_ba = operation.symmetric_difference(g2, g1)

  assert model.order(sym_ab) == model.order(sym_ba)
  assert model.edge_count(sym_ab) == model.edge_count(sym_ba)
}

/// A Δ A = ∅
pub fn symmetric_difference_self_is_empty_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let result = operation.symmetric_difference(g, g)

  assert model.order(result) == 0
  assert model.edge_count(result) == 0
}

/// A Δ ∅ = A
pub fn symmetric_difference_empty_is_identity_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  let result = operation.symmetric_difference(g, empty)

  assert model.order(result) == model.order(g)
  assert model.edge_count(result) == model.edge_count(g)
}

// ============================================================================
// CATEGORY 3: SUBGRAPH AND ISOMORPHISM PROPERTIES
// ============================================================================

/// Every graph is a subgraph of itself (reflexivity)
pub fn is_subgraph_reflexive_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  assert operation.is_subgraph(g, g) == True
}

/// Empty graph is a subgraph of any graph
pub fn empty_is_subgraph_of_all_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  assert operation.is_subgraph(empty, g) == True
}

/// Every graph is isomorphic to itself (reflexivity)
pub fn is_isomorphic_reflexive_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  assert operation.is_isomorphic(g, g) == True
}

/// Isomorphic graphs have same order
pub fn isomorphic_same_order_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  case operation.is_isomorphic(g1, g2) {
    True -> {
      assert model.order(g1) == model.order(g2)
      Nil
    }
    False -> Nil
  }
}

/// Isomorphic graphs have same edge count
pub fn isomorphic_same_edge_count_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  case operation.is_isomorphic(g1, g2) {
    True -> {
      assert model.edge_count(g1) == model.edge_count(g2)
      Nil
    }
    False -> Nil
  }
}

// ============================================================================
// CATEGORY 4: UNION AND INTERSECTION RELATIONSHIPS
// ============================================================================

/// A ∩ B ⊆ A (intersection is always a subgraph of both)
pub fn intersection_is_subgraph_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let inter = operation.intersection(g1, g2)

  assert operation.is_subgraph(inter, g1) == True
  assert operation.is_subgraph(inter, g2) == True
}

/// A ⊆ A ∪ B (both graphs are subgraphs of their union)
pub fn union_contains_both_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let uni = operation.union(g1, g2)

  assert operation.is_subgraph(g1, uni) == True
  assert operation.is_subgraph(g2, uni) == True
}

/// Order of union ≤ order of A + order of B
pub fn union_order_bound_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let uni = operation.union(g1, g2)

  assert model.order(uni) <= model.order(g1) + model.order(g2)
}

/// Order of intersection ≤ min(order of A, order of B)
pub fn intersection_order_bound_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let inter = operation.intersection(g1, g2)

  assert model.order(inter) <= int.min(model.order(g1), model.order(g2))
}

// ============================================================================
// CATEGORY 5: DISJOINT UNION PROPERTIES
// ============================================================================

/// Disjoint union preserves total node count
pub fn disjoint_union_preserves_node_count_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let disjoint = operation.disjoint_union(g1, g2)

  assert model.order(disjoint) == model.order(g1) + model.order(g2)
}

/// Disjoint union preserves total edge count (for directed)
pub fn disjoint_union_preserves_edge_count_directed_test() {
  use g1 <- qcheck.given(qcheck_generators.directed_graph_generator())
  use g2 <- qcheck.given(qcheck_generators.directed_graph_generator())

  let disjoint = operation.disjoint_union(g1, g2)

  assert model.edge_count(disjoint)
    == model.edge_count(g1) + model.edge_count(g2)
}

/// Disjoint union result always has nodes from both graphs distinct
pub fn disjoint_union_nodes_are_distinct_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let disjoint = operation.disjoint_union(g1, g2)
  let nodes = model.all_nodes(disjoint) |> set.from_list

  // Should have exactly the sum of nodes (no overlap)
  assert set.size(nodes) == model.order(g1) + model.order(g2)
}

// ============================================================================
// CATEGORY 6: COMPOSE PROPERTIES
// ============================================================================

/// Compose with empty graph is identity
pub fn compose_empty_identity_test() {
  use g <- qcheck.given(qcheck_generators.graph_generator())

  let empty = model.new(model.Directed)
  let result = operation.compose(g, empty)

  assert model.order(result) == model.order(g)
  assert model.edge_count(result) == model.edge_count(g)
}

// ============================================================================
// CATEGORY 7: POWER GRAPH PROPERTIES
// ============================================================================

/// G^1 = G (power of 1 is identity)
pub fn power_one_is_identity_test() {
  use g <- qcheck.given(qcheck_generators.directed_graph_generator())

  let powered = operation.power(g, 1, 1)

  assert model.order(powered) == model.order(g)
  assert model.edge_count(powered) == model.edge_count(g)
}

/// G^0 = G (power of 0 is identity)
pub fn power_zero_is_identity_test() {
  use g <- qcheck.given(qcheck_generators.directed_graph_generator())

  let powered = operation.power(g, 0, 1)

  assert model.order(powered) == model.order(g)
  assert model.edge_count(powered) == model.edge_count(g)
}

/// G^k has at least as many edges as G (for k >= 1)
pub fn power_has_at_least_as_many_edges_test() {
  use g <- qcheck.given(qcheck_generators.directed_graph_generator())

  let powered = operation.power(g, 2, 1)

  assert model.edge_count(powered) >= model.edge_count(g)
}

/// G^k preserves all nodes (no nodes are removed)
pub fn power_preserves_nodes_test() {
  use g <- qcheck.given(qcheck_generators.directed_graph_generator())

  let powered = operation.power(g, 3, 1)

  assert model.order(powered) == model.order(g)
}

// ============================================================================
// CATEGORY 8: COMPLEX RELATIONSHIPS
// ============================================================================

/// Order and edge count monotonicity for union
pub fn union_monotonic_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let uni = operation.union(g1, g2)

  assert model.order(uni) >= model.order(g1)
  assert model.order(uni) >= model.order(g2)
}

/// Order and edge count monotonicity for intersection
pub fn intersection_monotonic_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())

  let inter = operation.intersection(g1, g2)

  assert model.order(inter) <= model.order(g1)
  assert model.order(inter) <= model.order(g2)
}

/// Subgraph transitivity: if A ⊆ B and B ⊆ C then A ⊆ C
pub fn subgraph_transitive_test() {
  use g1 <- qcheck.given(qcheck_generators.graph_generator())
  use g2 <- qcheck.given(qcheck_generators.graph_generator())
  use g3 <- qcheck.given(qcheck_generators.graph_generator())

  // Use intersection to create subgraph relationships
  let inter_12 = operation.intersection(g1, g2)
  let inter_123 = operation.intersection(inter_12, g3)

  // inter_123 ⊆ inter_12 ⊆ g1
  assert operation.is_subgraph(inter_123, inter_12) == True
  assert operation.is_subgraph(inter_12, g1) == True
  assert operation.is_subgraph(inter_123, g1) == True
}
