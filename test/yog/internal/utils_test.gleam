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
