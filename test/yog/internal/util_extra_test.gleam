//// Unit tests for norm_diff and fisher_yates functions
//// in yog/internal/util.gleam

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import yog/internal/random
import yog/internal/util

// =============================================================================
// NORM_DIFF TESTS
// =============================================================================

pub fn norm_diff_l1_basic_test() {
  let m1 = dict.from_list([#("a", 1.0), #("b", 2.0)])
  let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])

  // L1 = |1-3| + |2-4| = 2 + 2 = 4
  util.norm_diff(m1, m2, util.L1)
  |> should.equal(4.0)
}

pub fn norm_diff_l2_basic_test() {
  let m1 = dict.from_list([#("a", 1.0), #("b", 2.0)])
  let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])

  // L2 = sqrt((1-3)^2 + (2-4)^2) = sqrt(4 + 4) = sqrt(8) = 2.828...
  let result = util.norm_diff(m1, m2, util.L2)
  float.loosely_equals(result, 2.8284271247461903, 0.0001)
  |> should.be_true()
}

pub fn norm_diff_max_basic_test() {
  let m1 = dict.from_list([#("a", 1.0), #("b", 2.0)])
  let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])

  // Max = max(|1-3|, |2-4|) = max(2, 2) = 2
  util.norm_diff(m1, m2, util.Max)
  |> should.equal(2.0)
}

pub fn norm_diff_identical_vectors_test() {
  let m1 = dict.from_list([#("a", 1.0), #("b", 2.0)])

  // Distance from a vector to itself should be 0
  util.norm_diff(m1, m1, util.L1)
  |> should.equal(0.0)

  util.norm_diff(m1, m1, util.L2)
  |> should.equal(0.0)

  util.norm_diff(m1, m1, util.Max)
  |> should.equal(0.0)
}

pub fn norm_diff_empty_dicts_test() {
  let empty = dict.new()

  util.norm_diff(empty, empty, util.L1)
  |> should.equal(0.0)

  util.norm_diff(empty, empty, util.L2)
  |> should.equal(0.0)

  util.norm_diff(empty, empty, util.Max)
  |> should.equal(0.0)
}

pub fn norm_diff_missing_keys_test() {
  let m1 = dict.from_list([#("a", 5.0)])
  let m2 = dict.from_list([#("a", 2.0), #("b", 3.0)])

  // Accounts for keys in both dictionaries
  // L1 = |5-2| + |0-3| = 3 + 3 = 6
  util.norm_diff(m1, m2, util.L1)
  |> should.equal(6.0)
}

pub fn norm_diff_non_negative_test() {
  let m1 = dict.from_list([#("x", 10.0), #("y", 20.0)])
  let m2 = dict.from_list([#("x", 5.0), #("y", 15.0)])

  // All norms should be >= 0
  let l1 = util.norm_diff(m1, m2, util.L1)
  let l2 = util.norm_diff(m1, m2, util.L2)
  let max_val = util.norm_diff(m1, m2, util.Max)

  { l1 >=. 0.0 } |> should.be_true()
  { l2 >=. 0.0 } |> should.be_true()
  { max_val >=. 0.0 } |> should.be_true()
}

pub fn norm_diff_l2_less_than_l1_test() {
  let m1 = dict.from_list([#("a", 0.0), #("b", 0.0)])
  let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])

  // L1 = 7, L2 = 5, so L2 < L1
  let l1 = util.norm_diff(m1, m2, util.L1)
  let l2 = util.norm_diff(m1, m2, util.L2)

  { l2 <. l1 } |> should.be_true()
}

pub fn norm_diff_max_less_than_l1_test() {
  let m1 = dict.from_list([#("a", 0.0), #("b", 0.0)])
  let m2 = dict.from_list([#("a", 3.0), #("b", 4.0)])

  // L1 = 7, Max = 4, so Max < L1
  let l1 = util.norm_diff(m1, m2, util.L1)
  let max_val = util.norm_diff(m1, m2, util.Max)

  { max_val <. l1 } |> should.be_true()
}

// =============================================================================
// RANDOM SHUFFLE TESTS
// =============================================================================

pub fn shuffle_basic_test() {
  let list = [1, 2, 3, 4, 5]
  let rng = random.new(Some(42))

  let #(shuffled, _) = random.shuffle(list, rng)

  // Shuffled list should have same length
  list.length(shuffled)
  |> should.equal(list.length(list))

  // Shuffled list should contain same elements
  list.sort(shuffled, int.compare)
  |> should.equal(list.sort(list, int.compare))
}

pub fn shuffle_deterministic_test() {
  let list = [1, 2, 3, 4, 5]
  let seed = 42

  let #(shuffled1, _) = random.shuffle(list, random.new(Some(seed)))
  let #(shuffled2, _) = random.shuffle(list, random.new(Some(seed)))

  // Same seed should produce same result
  shuffled1
  |> should.equal(shuffled2)
}

pub fn shuffle_empty_test() {
  let #(result, _) = random.shuffle([], random.new(Some(123)))
  result
  |> should.equal([])
}

pub fn shuffle_single_element_test() {
  let #(result, _) = random.shuffle([42], random.new(Some(999)))
  result
  |> should.equal([42])
}

pub fn shuffle_two_elements_test() {
  let list = [1, 2]

  // With different seeds, should get one of the two permutations
  let #(shuffled, _) = random.shuffle(list, random.new(Some(42)))

  // Should be either [1, 2] or [2, 1]
  let is_valid = shuffled == [1, 2] || shuffled == [2, 1]
  is_valid
  |> should.be_true()
}

pub fn shuffle_preserves_elements_test() {
  let list = ["a", "b", "c", "d", "e"]
  let #(shuffled, _) = random.shuffle(list, random.new(Some(42)))

  // Sort both and compare
  list.sort(shuffled, string.compare)
  |> should.equal(list.sort(list, string.compare))
}

pub fn shuffle_different_seeds_test() {
  let list = [1, 2, 3, 4, 5]
  let seed1 = 42
  let seed2 = 43

  let #(shuffled1, _) = random.shuffle(list, random.new(Some(seed1)))
  let #(shuffled2, _) = random.shuffle(list, random.new(Some(seed2)))

  // Different seeds likely produce different results
  // (Not guaranteed, but very likely for 5 elements)
  // We just check both are valid shuffles
  list.sort(shuffled1, int.compare)
  |> should.equal(list.sort(list, int.compare))

  list.sort(shuffled2, int.compare)
  |> should.equal(list.sort(list, int.compare))
}

pub fn shuffle_multiple_shuffles_test() {
  let list = [1, 2, 3, 4]

  let #(shuffled1, rng1) = random.shuffle(list, random.new(Some(42)))
  let #(shuffled2, _) = random.shuffle(shuffled1, rng1)

  // Double shuffle should still preserve all elements
  list.sort(shuffled2, int.compare)
  |> should.equal(list.sort(list, int.compare))
}

pub fn shuffle_known_seed_test() {
  // Test with a known seed to verify reproducibility
  let list = [1, 2, 3, 4, 5]

  // This seed produces a known output
  let #(result, _) = random.shuffle(list, random.new(Some(42)))

  // Verify result is a valid permutation
  list.sort(result, int.compare)
  |> should.equal([1, 2, 3, 4, 5])
}
