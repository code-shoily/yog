//// Internal utilities for deterministic and stochastic randomness.
////
//// This module provides a simple, seeded pseudo-random number generator (PRNG)
//// based on a Linear Congruential Generator (LCG). It is used across the
//// library to ensure that stochastic algorithms (like random walks or graph
//// generators) can be made deterministic for testing and reproducibility.

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import yog/internal/utils

/// Internal state for a seeded pseudo-random number generator.
pub opaque type Rng {
  Rng(seed: Int)
}

/// Creates a new RNG state.
///
/// If a `Some(seed)` is provided, the RNG will produce a deterministic
/// sequence of values. If `None`, it is initialized with a system-level
/// random value.
pub fn new(seed: Option(Int)) -> Rng {
  case seed {
    Some(s) -> Rng(s)
    None -> Rng(float.truncate(float.random() *. 1_000_000_000.0) + 1)
  }
}

/// Generates the next random integer in the range [0, max).
///
/// Returns a tuple containing the generated integer and the next RNG state.
pub fn next_int(rng: Rng, max: Int) -> #(Int, Rng) {
  // Simple LCG (Linear Congruential Generator)
  // Parameters from Numerical Recipes
  let a = 1_664_525
  let c = 1_013_904_223
  let m = 0x7FFFFFFF
  let new_seed = int.bitwise_and(a * rng.seed + c, m)
  let result = new_seed % max
  #(result, Rng(new_seed))
}

/// Generates the next random float in the range [0.0, 1.0).
///
/// Returns a tuple containing the generated float and the next RNG state.
pub fn next_float(rng: Rng) -> #(Float, Rng) {
  let #(int_val, new_rng) = next_int(rng, 1_000_000)
  #(int.to_float(int_val) /. 1_000_000.0, new_rng)
}

/// Randomly shuffles a list using the Fisher-Yates algorithm.
///
/// This is a deterministic shuffle based on the provided RNG state.
pub fn shuffle(list: List(a), rng: Rng) -> #(List(a), Rng) {
  let n = list.length(list)
  case n <= 1 {
    True -> #(list, rng)
    False -> {
      let arr = utils.array_from_list(list)
      let #(shuffled_arr, final_rng) = do_shuffle(arr, 0, n, rng)
      #(utils.array_to_list(shuffled_arr, n), final_rng)
    }
  }
}

fn do_shuffle(arr, i, n, rng) {
  case i >= n - 1 {
    True -> #(arr, rng)
    False -> {
      let #(offset, next_rng) = next_int(rng, n - i)
      let j = i + offset

      let val_i = utils.array_get(arr, i)
      let val_j = utils.array_get(arr, j)
      let arr = utils.array_set(arr, i, val_j)
      let arr = utils.array_set(arr, j, val_i)

      do_shuffle(arr, i + 1, n, next_rng)
    }
  }
}
