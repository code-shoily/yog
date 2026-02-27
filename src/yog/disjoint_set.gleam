import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set

/// Disjoint Set Union (Union-Find) data structure.
///
/// Efficiently tracks a partition of elements into disjoint sets.
/// Uses path compression and union by rank for near-constant time operations.
///
/// **Time Complexity:** O(α(n)) amortized per operation, where α is the inverse Ackermann function
pub type DisjointSet(a) {
  DisjointSet(parents: Dict(a, a), ranks: Dict(a, Int))
}

/// Creates a new empty disjoint set structure.
pub fn new() -> DisjointSet(a) {
  DisjointSet(parents: dict.new(), ranks: dict.new())
}

/// Adds a new element to the disjoint set.
///
/// The element starts in its own singleton set.
/// If the element already exists, the structure is returned unchanged.
pub fn add(disjoint_set: DisjointSet(a), element: a) -> DisjointSet(a) {
  case dict.has_key(disjoint_set.parents, element) {
    True -> disjoint_set
    False ->
      DisjointSet(
        parents: dict.insert(disjoint_set.parents, element, element),
        ranks: dict.insert(disjoint_set.ranks, element, 0),
      )
  }
}

/// Finds the representative (root) of the set containing the element.
///
/// Uses path compression to flatten the tree structure for future queries.
/// If the element doesn't exist, it's automatically added first.
///
/// Returns a tuple of `#(updated_disjoint_set, root)`.
pub fn find(disjoint_set: DisjointSet(a), element: a) -> #(DisjointSet(a), a) {
  case dict.get(disjoint_set.parents, element) {
    // If not found, add it and return as its own root
    Error(_) -> #(add(disjoint_set, element), element)
    Ok(parent) if parent == element -> #(disjoint_set, element)
    Ok(parent) -> {
      let #(updated_disjoint_set, root) = find(disjoint_set, parent)
      let new_parents = dict.insert(updated_disjoint_set.parents, element, root)
      #(DisjointSet(..updated_disjoint_set, parents: new_parents), root)
    }
  }
}

/// Merges the sets containing the two elements.
///
/// Uses union by rank to keep the tree balanced.
/// If the elements are already in the same set, returns unchanged.
pub fn union(disjoint_set: DisjointSet(a), x: a, y: a) -> DisjointSet(a) {
  let #(disjoint_set1, root_x) = find(disjoint_set, x)
  let #(disjoint_set2, root_y) = find(disjoint_set1, y)

  case root_x == root_y {
    True -> disjoint_set2
    False -> {
      let rank_x = dict.get(disjoint_set2.ranks, root_x) |> result.unwrap(0)
      let rank_y = dict.get(disjoint_set2.ranks, root_y) |> result.unwrap(0)

      case rank_x < rank_y {
        True ->
          DisjointSet(
            ..disjoint_set2,
            parents: dict.insert(disjoint_set2.parents, root_x, root_y),
          )
        False -> {
          let disjoint_set3 =
            DisjointSet(
              ..disjoint_set2,
              parents: dict.insert(disjoint_set2.parents, root_y, root_x),
            )
          case rank_x == rank_y {
            True ->
              DisjointSet(
                ..disjoint_set3,
                ranks: dict.insert(disjoint_set3.ranks, root_x, rank_x + 1),
              )
            False -> disjoint_set3
          }
        }
      }
    }
  }
}

/// Creates a disjoint set from a list of pairs to union.
///
/// This is a convenience function for building a disjoint set from edge lists
/// or connection pairs. Perfect for graph problems, AoC, and competitive programming.
///
/// ## Example
/// ```gleam
/// let dsu = disjoint_set.from_pairs([#(1, 2), #(3, 4), #(2, 3)])
/// // Results in: {1,2,3,4} as one set
/// ```
pub fn from_pairs(pairs: List(#(a, a))) -> DisjointSet(a) {
  list.fold(pairs, new(), fn(dsu, pair) { union(dsu, pair.0, pair.1) })
}

/// Checks if two elements are in the same set (connected).
///
/// Returns the updated disjoint set (due to path compression) and a boolean result.
///
/// ## Example
/// ```gleam
/// let dsu = from_pairs([#(1, 2), #(3, 4)])
/// let #(dsu2, result) = connected(dsu, 1, 2)  // => True
/// let #(dsu3, result) = connected(dsu2, 1, 3) // => False
/// ```
pub fn connected(dsu: DisjointSet(a), x: a, y: a) -> #(DisjointSet(a), Bool) {
  let #(dsu1, root_x) = find(dsu, x)
  let #(dsu2, root_y) = find(dsu1, y)
  #(dsu2, root_x == root_y)
}

/// Returns the total number of elements in the structure.
pub fn size(dsu: DisjointSet(a)) -> Int {
  dict.size(dsu.parents)
}

/// Returns the number of disjoint sets.
///
/// Counts the distinct sets by finding the unique roots.
///
/// ## Example
/// ```gleam
/// let dsu = from_pairs([#(1, 2), #(3, 4)])
/// count_sets(dsu)  // => 2 (sets: {1,2} and {3,4})
/// ```
pub fn count_sets(dsu: DisjointSet(a)) -> Int {
  dict.keys(dsu.parents)
  |> list.map(fn(element) { find_root_readonly(dsu, element) })
  |> set.from_list()
  |> set.size()
}

/// Returns all disjoint sets as a list of lists.
///
/// Each inner list contains all members of one set. The order of sets and
/// elements within sets is unspecified.
///
/// Note: This operation doesn't perform path compression, so the structure
/// is not modified.
///
/// ## Example
/// ```gleam
/// let dsu = from_pairs([#(1, 2), #(3, 4), #(5, 6)])
/// to_lists(dsu)  // => [[1, 2], [3, 4], [5, 6]] (order may vary)
/// ```
pub fn to_lists(dsu: DisjointSet(a)) -> List(List(a)) {
  dict.keys(dsu.parents)
  |> list.fold(dict.new(), fn(acc, element) {
    let root = find_root_readonly(dsu, element)
    dict.upsert(acc, root, fn(existing) {
      case existing {
        Some(members) -> [element, ..members]
        None -> [element]
      }
    })
  })
  |> dict.values()
}

// Private helper that finds root without path compression (read-only operation)
fn find_root_readonly(dsu: DisjointSet(a), element: a) -> a {
  case dict.get(dsu.parents, element) {
    Error(_) -> element
    Ok(parent) if parent == element -> element
    Ok(parent) -> find_root_readonly(dsu, parent)
  }
}
