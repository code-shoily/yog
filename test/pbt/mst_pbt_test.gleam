import gleam/list
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/connectivity
import yog/model
import yog/mst

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// MST: ALGORITHM CROSS-VALIDATION
// ============================================================================

pub fn mst_kruskal_equals_prim_weight_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case list.length(connectivity.strongly_connected_components(graph)) {
        1 -> {
          let kruskal_result = mst.kruskal_int(graph)
          let prim_result = mst.prim_int(graph)

          assert kruskal_result.total_weight == prim_result.total_weight
        }
        _ -> Nil
      }
    }
  }
}

// ============================================================================
// MST: STRUCTURAL INVARIANTS
// ============================================================================

pub fn mst_is_spanning_forest_test() {
  use graph <- qcheck.given(qcheck_generators.undirected_graph_generator())

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let mst_result = mst.kruskal_int(graph)
      let num_components =
        list.length(connectivity.strongly_connected_components(graph))
      let n = model.order(graph)

      // Forest has V-C edges
      assert mst_result.edge_count == n - num_components
    }
  }
}
