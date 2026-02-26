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
pub fn add(dsu: DisjointSet(a), element: a) -> DisjointSet(a) {
  case dict.has_key(dsu.parents, element) {
    True -> dsu
    False ->
      DisjointSet(
        parents: dict.insert(dsu.parents, element, element),
        ranks: dict.insert(dsu.ranks, element, 0),
      )
  }
}

/// Finds the representative (root) of the set containing the element.
///
/// Uses path compression to flatten the tree structure for future queries.
/// If the element doesn't exist, it's automatically added first.
///
/// Returns a tuple of `#(updated_dsu, root)`.
pub fn find(dsu: DisjointSet(a), element: a) -> #(DisjointSet(a), a) {
  case dict.get(dsu.parents, element) {
    // If not found, add it and return as its own root
    Error(_) -> #(add(dsu, element), element)
    Ok(parent) if parent == element -> #(dsu, element)
    Ok(parent) -> {
      let #(updated_dsu, root) = find(dsu, parent)
      let new_parents = dict.insert(updated_dsu.parents, element, root)
      #(DisjointSet(..updated_dsu, parents: new_parents), root)
    }
  }
}

/// Merges the sets containing the two elements.
///
/// Uses union by rank to keep the tree balanced.
/// If the elements are already in the same set, returns unchanged.
pub fn union(dsu: DisjointSet(a), x: a, y: a) -> DisjointSet(a) {
  let #(dsu1, root_x) = find(dsu, x)
  let #(dsu2, root_y) = find(dsu1, y)

  case root_x == root_y {
    True -> dsu2
    False -> {
      let rank_x = dict.get(dsu2.ranks, root_x) |> result.unwrap(0)
      let rank_y = dict.get(dsu2.ranks, root_y) |> result.unwrap(0)

      case rank_x < rank_y {
        True ->
          DisjointSet(
            ..dsu2,
            parents: dict.insert(dsu2.parents, root_x, root_y),
          )
        False -> {
          let dsu3 =
            DisjointSet(
              ..dsu2,
              parents: dict.insert(dsu2.parents, root_y, root_x),
            )
          case rank_x == rank_y {
            True ->
              DisjointSet(
                ..dsu3,
                ranks: dict.insert(dsu3.ranks, root_x, rank_x + 1),
              )
            False -> dsu3
          }
        }
      }
    }
  }
}
