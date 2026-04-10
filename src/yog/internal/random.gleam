import gleam/int
import gleam/option.{type Option, None, Some}
import prng/random

/// Opaque type for the random number generator state.
pub opaque type Rng {
  Rng(seed: random.Seed)
}

/// Creates a new random number generator.
/// If a seed is provided, it will be deterministic.
pub fn new(seed: Option(Int)) -> Rng {
  let s = case seed {
    Some(s) -> s
    None -> int.random(2_147_483_647)
  }
  Rng(random.new_seed(s))
}

/// Generates a random integer in the range [0, limit).
pub fn next_int(rng: Rng, limit: Int) -> #(Int, Rng) {
  case limit <= 0 {
    True -> #(0, rng)
    False -> {
      let #(val, next_seed) = random.step(random.int(0, limit - 1), rng.seed)
      #(val, Rng(next_seed))
    }
  }
}

/// Generates a random float in the range [0.0, 1.0).
pub fn next_float(rng: Rng) -> #(Float, Rng) {
  let #(val, next_seed) = random.step(random.float(0.0, 1.0), rng.seed)
  #(val, Rng(next_seed))
}

/// Shuffles a list randomly.
pub fn shuffle(list: List(a), rng: Rng) -> #(List(a), Rng) {
  let #(shuffled, next_seed) = random.step(random.shuffle(list), rng.seed)
  #(shuffled, Rng(next_seed))
}
