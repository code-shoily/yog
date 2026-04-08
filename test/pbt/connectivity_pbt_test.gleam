import gleam/list
import gleam/set
import gleeunit
import pbt/qcheck_generators
import qcheck
import yog/connectivity
import yog/model

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// SCC: ALGORITHM CROSS-VALIDATION
// ============================================================================

pub fn scc_tarjan_equals_kosaraju_test() {
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

  let tarjan = connectivity.strongly_connected_components(graph)
  let kosaraju = connectivity.kosaraju(graph)

  let tarjan_sets =
    tarjan
    |> list.map(set.from_list)
    |> set.from_list

  let kosaraju_sets =
    kosaraju
    |> list.map(set.from_list)
    |> set.from_list

  assert tarjan_sets == kosaraju_sets
}

// ============================================================================
// SCC: STRUCTURAL INVARIANTS
// ============================================================================

pub fn scc_components_partition_graph_test() {
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

  let components = connectivity.strongly_connected_components(graph)

  let all_in_components =
    components
    |> list.flat_map(fn(comp) { comp })
    |> set.from_list

  let all_graph_nodes =
    model.all_nodes(graph)
    |> set.from_list

  assert all_in_components == all_graph_nodes

  let pairs = list.combination_pairs(components)

  let are_disjoint =
    list.all(pairs, fn(pair) {
      let #(c1, c2) = pair
      let s1 = set.from_list(c1)
      let s2 = set.from_list(c2)
      set.is_disjoint(s1, s2)
    })

  assert are_disjoint
}

// ============================================================================
// CONNECTIVITY ANALYSIS: BRIDGES
// ============================================================================

pub fn bridges_increase_components_test() {
  use #(graph, #(src, dst, weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 | 1 -> Nil
    _ -> {
      // Force edge insertion so we might create a bridge
      let assert Ok(graph) =
        model.add_edge(graph, from: src, to: dst, with: weight)

      let result = connectivity.analyze(in: graph)

      let base_comp =
        list.length(connectivity.strongly_connected_components(graph))

      case result.bridges {
        [] -> Nil
        [bridge, ..] -> {
          let #(b_src, b_dst) = bridge

          let without_bridge = model.remove_edge(graph, b_src, b_dst)

          let split_comp =
            list.length(connectivity.strongly_connected_components(
              without_bridge,
            ))
          assert split_comp > base_comp
        }
      }
    }
  }
}
