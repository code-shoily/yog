import gleam/dict
import gleam/list
import gleeunit/should
import yog/internal/utils

// Basic range
pub fn range_basic_test() {
  utils.range(1, 5)
  |> should.equal([1, 2, 3, 4, 5])
}

// Range starting from 0
pub fn range_from_zero_test() {
  utils.range(0, 3)
  |> should.equal([0, 1, 2, 3])
}

// Single element range
pub fn range_single_element_test() {
  utils.range(5, 5)
  |> should.equal([5])
}

// Empty range (start > end)
pub fn range_empty_test() {
  utils.range(5, 3)
  |> should.equal([])
}

// Large range
pub fn range_large_test() {
  let result = utils.range(1, 100)

  // Check length
  list.length(result)
  |> should.equal(100)

  // Check first and last elements
  result
  |> should.equal([
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78,
    79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
    98, 99, 100,
  ])
}

// Negative numbers
pub fn range_negative_test() {
  utils.range(-3, 2)
  |> should.equal([-3, -2, -1, 0, 1, 2])
}

// Range with negative start and end
pub fn range_all_negative_test() {
  utils.range(-5, -2)
  |> should.equal([-5, -4, -3, -2])
}

// --- dict_update_inner tests ---

// Update an existing inner key
pub fn dict_update_inner_existing_key_test() {
  let inner = dict.from_list([#("b", 1), #("c", 2)])
  let outer = dict.from_list([#("a", inner)])

  let result =
    utils.dict_update_inner(outer, "a", "b", fn(inner_dict, key) {
      dict.insert(inner_dict, key, 10)
    })

  // Check the updated value
  let assert Ok(updated_inner) = dict.get(result, "a")
  dict.get(updated_inner, "b")
  |> should.equal(Ok(10))

  // Other keys should remain unchanged
  dict.get(updated_inner, "c")
  |> should.equal(Ok(2))
}

// Add a new inner key to existing outer key
pub fn dict_update_inner_new_inner_key_test() {
  let inner = dict.from_list([#("b", 1)])
  let outer = dict.from_list([#("a", inner)])

  let result =
    utils.dict_update_inner(outer, "a", "c", fn(inner_dict, key) {
      dict.insert(inner_dict, key, 20)
    })

  let assert Ok(updated_inner) = dict.get(result, "a")
  dict.get(updated_inner, "c")
  |> should.equal(Ok(20))

  // Original key should still exist
  dict.get(updated_inner, "b")
  |> should.equal(Ok(1))
}

// Outer key not found - should return unchanged
pub fn dict_update_inner_outer_key_missing_test() {
  let inner = dict.from_list([#("b", 1)])
  let outer = dict.from_list([#("a", inner)])

  let result =
    utils.dict_update_inner(outer, "z", "b", fn(inner_dict, key) {
      dict.insert(inner_dict, key, 10)
    })

  // Should be unchanged
  result
  |> should.equal(outer)
}

// Empty inner dictionary
pub fn dict_update_inner_empty_inner_test() {
  let inner = dict.new()
  let outer = dict.from_list([#("a", inner)])

  let result =
    utils.dict_update_inner(outer, "a", "b", fn(inner_dict, key) {
      dict.insert(inner_dict, key, 5)
    })

  let assert Ok(updated_inner) = dict.get(result, "a")
  dict.get(updated_inner, "b")
  |> should.equal(Ok(5))

  dict.size(updated_inner)
  |> should.equal(1)
}

// Multiple outer keys - only target is updated
pub fn dict_update_inner_multiple_outer_keys_test() {
  let inner1 = dict.from_list([#("x", 1)])
  let inner2 = dict.from_list([#("y", 2)])
  let outer = dict.from_list([#("a", inner1), #("b", inner2)])

  let result =
    utils.dict_update_inner(outer, "a", "x", fn(inner_dict, key) {
      dict.insert(inner_dict, key, 100)
    })

  // First outer key should be updated
  let assert Ok(updated_inner1) = dict.get(result, "a")
  dict.get(updated_inner1, "x")
  |> should.equal(Ok(100))

  // Second outer key should be unchanged
  let assert Ok(updated_inner2) = dict.get(result, "b")
  dict.get(updated_inner2, "y")
  |> should.equal(Ok(2))
}
