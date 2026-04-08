import gleam/list
import gleam/set
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/model
import yog/traversal

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TRAVERSAL: INVARIANTS
// ============================================================================

pub fn traversal_no_duplicates_bfs_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let visited =
        traversal.walk(graph, from: 0, using: traversal.BreadthFirst)

      let unique_count = set.size(set.from_list(visited))
      let total_count = list.length(visited)

      assert unique_count == total_count
    }
  }
}

pub fn traversal_no_duplicates_dfs_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let visited = traversal.walk(graph, from: 0, using: traversal.DepthFirst)

      let unique_count = set.size(set.from_list(visited))
      let total_count = list.length(visited)

      // Should visit each node exactly once despite cycles
      assert unique_count == total_count
    }
  }
}
