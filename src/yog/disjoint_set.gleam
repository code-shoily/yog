import gleam/dict.{type Dict}
import gleam/result

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
