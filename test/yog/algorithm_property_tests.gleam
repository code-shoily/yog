////
//// Advanced Property Tests - Algorithm Cross-Validation & Correctness
////

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleeunit
import qcheck
import yog/centrality
import yog/connectivity
import yog/model.{type Graph, type NodeId}
import yog/mst
import yog/pathfinding/bellman_ford
import yog/pathfinding/dijkstra
import yog/qcheck_generators
import yog/traversal

pub fn main() {
  gleeunit.main()
}

// Helpers
fn is_valid_path(graph: Graph(n, Int), path: List(NodeId)) -> Bool {
  case path {
    [] | [_] -> True
    [first, second, ..rest] -> {
      let edge_exists =
        model.successors(graph, first)
        |> list.any(fn(pair) { pair.0 == second })
      edge_exists && is_valid_path(graph, [second, ..rest])
    }
  }
}

fn calculate_path_weight(graph: Graph(n, Int), path: List(NodeId)) -> Int {
  case path {
    [] | [_] -> 0
    [first, second, ..rest] -> {
      let edge_weight =
        model.successors(graph, first)
        |> list.find(fn(pair) { pair.0 == second })
        |> result.map(fn(pair) { pair.1 })
        |> result.unwrap(0)

      edge_weight + calculate_path_weight(graph, [second, ..rest])
    }
  }
}

fn is_reachable(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  let visited = traversal.walk(graph, from: from, using: traversal.BreadthFirst)
  list.contains(visited, to)
}

// ============================================================================
// CATEGORY 1: ALGORITHM CROSS-VALIDATION
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

pub fn bellman_ford_equals_dijkstra_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let dijkstra_result =
        dijkstra.shortest_path_int(in: graph, from: src, to: dst)
      let bellman_result =
        bellman_ford.bellman_ford(
          in: graph,
          from: src,
          to: dst,
          with_zero: 0,
          with_add: int.add,
          with_compare: int.compare,
        )

      case dijkstra_result, bellman_result {
        Some(d_path), bellman_ford.ShortestPath(path: b_path) -> {
          assert d_path.total_weight == b_path.total_weight
        }
        None, bellman_ford.NoPath -> Nil
        _, _ -> panic as "Dijkstra and Bellman-Ford disagree on path existence!"
      }
    }
  }
}

// ============================================================================
// CATEGORY 2: PATHFINDING CORRECTNESS
// ============================================================================

pub fn dijkstra_path_validity_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case dijkstra.shortest_path_int(in: graph, from: src, to: dst) {
        Some(path) -> {
          assert list.first(path.nodes) == Ok(src)
          assert list.last(path.nodes) == Ok(dst)
          assert is_valid_path(graph, path.nodes)

          let calculated = calculate_path_weight(graph, path.nodes)
          assert path.total_weight == calculated
        }
        None -> Nil
      }
    }
  }
}

pub fn dijkstra_no_path_confirmed_by_bfs_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case dijkstra.shortest_path_int(in: graph, from: src, to: dst) {
        None -> {
          assert !is_reachable(graph, src, dst)
        }
        Some(_) -> Nil
      }
    }
  }
}

pub fn undirected_paths_symmetric_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let forward = dijkstra.shortest_path_int(in: graph, from: src, to: dst)
      let backward = dijkstra.shortest_path_int(in: graph, from: dst, to: src)

      case forward, backward {
        Some(f_path), Some(b_path) -> {
          assert f_path.total_weight == b_path.total_weight
        }
        None, None -> Nil
        _, _ -> panic as "Symmetric paths should both exist or both not exist!"
      }
    }
  }
}

pub fn triangle_inequality_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let n = model.order(graph)
      let via_node = { src + dst } % n

      let direct = dijkstra.shortest_path_int(in: graph, from: src, to: dst)
      let via_1_part1 =
        dijkstra.shortest_path_int(in: graph, from: src, to: via_node)
      let via_1_part2 =
        dijkstra.shortest_path_int(in: graph, from: via_node, to: dst)

      case direct, via_1_part1, via_1_part2 {
        Some(d), Some(p1), Some(p2) -> {
          let via_weight = p1.total_weight + p2.total_weight
          assert d.total_weight <= via_weight
        }
        _, _, _ -> Nil
      }
    }
  }
}

// ============================================================================
// CATEGORY 3: COMPLEX INVARIANTS
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

pub fn bridges_increase_components_test() {
  use #(graph, #(src, dst, weight)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 | 1 -> Nil
    _ -> {
      // Force edge insertion so we might create a bridge
      let graph = model.add_edge(graph, from: src, to: dst, with: weight)

      let result = connectivity.analyze(in: graph)

      let base_comp =
        list.length(connectivity.strongly_connected_components(graph))

      case result.bridges {
        [] -> Nil
        [bridge, ..] -> {
          let #(b_src, b_dst) = bridge

          let without_bridge =
            graph
            |> model.remove_edge(b_src, b_dst)
            |> model.remove_edge(b_dst, b_src)

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

pub fn degree_centrality_correctness_test() {
  use graph <- qcheck.given(qcheck_generators.directed_graph_generator())

  let out_degrees = centrality.degree(graph, centrality.OutDegree)

  case model.order(graph) {
    0 | 1 -> Nil
    _ -> {
      let max_possible = model.order(graph) - 1

      // Centrality score must be between 0.0 and infinity (normalized against order-1, could be >1.0 with loops/parallel edges)
      let valid_range =
        dict.values(out_degrees)
        |> list.all(fn(score) { score >=. 0.0 })

      assert valid_range

      // Compare scores
      let all_match =
        list.all(model.all_nodes(graph), fn(node) {
          let expected_degree = list.length(model.successors(graph, node))
          let expected_score =
            int.to_float(expected_degree) /. int.to_float(max_possible)

          case dict.get(out_degrees, node) {
            Ok(score) -> score == expected_score
            Error(_) -> False
          }
        })

      assert all_match
    }
  }
}
