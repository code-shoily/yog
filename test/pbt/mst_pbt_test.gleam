import gleam/int
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
          let kruskal_edges = mst.kruskal(in: graph, with_compare: int.compare)
          let prim_edges = mst.prim(in: graph, with_compare: int.compare)

          let kruskal_weight =
            kruskal_edges
            |> list.fold(0, fn(sum, edge) { sum + edge.weight })

          let prim_weight =
            prim_edges
            |> list.fold(0, fn(sum, edge) { sum + edge.weight })

          assert kruskal_weight == prim_weight
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
      let mst_edges = mst.kruskal(in: graph, with_compare: int.compare)
      let num_components =
        list.length(connectivity.strongly_connected_components(graph))
      let n = model.order(graph)

      // Forest has V-C edges
      assert list.length(mst_edges) == n - num_components
    }
  }
}
