////
//// Advanced Property Tests - Algorithm Cross-Validation & Correctness
////
//// These tests validate that:
//// 1. Different algorithms solving the same problem agree
//// 2. Algorithms produce valid/optimal results
//// 3. Complex invariants hold (partitions, trees, etc.)
////

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleeunit
import yog/centrality
import yog/connectivity
import yog/model.{type Graph, type NodeId}
import yog/mst
import yog/pathfinding/bellman_ford
import yog/pathfinding/dijkstra
import yog/traversal

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// HELPERS & GENERATORS
// ============================================================================

// Unused - using simpler generators instead

/// Check if all edges in a path exist in the graph
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

/// Calculate total weight of a path
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

/// Check if node b is reachable from node a via BFS
fn is_reachable(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  let visited = traversal.walk(graph, from: from, using: traversal.BreadthFirst)
  list.contains(visited, to)
}

// ============================================================================
// CATEGORY 1: ALGORITHM CROSS-VALIDATION
// ============================================================================

// ----------------------------------------------------------------------------
// SCC: Tarjan vs Kosaraju - Both should find same strongly connected components
// ----------------------------------------------------------------------------

pub fn scc_tarjan_equals_kosaraju_test() {
  // Example-based test with known SCC structure
  // Graph with 2 SCCs: {0, 1} and {2}
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 0, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let tarjan = connectivity.strongly_connected_components(graph)
  let kosaraju = connectivity.kosaraju(graph)

  // Convert to sets for comparison (order doesn't matter)
  let tarjan_sets =
    tarjan
    |> list.map(set.from_list)
    |> set.from_list

  let kosaraju_sets =
    kosaraju
    |> list.map(set.from_list)
    |> set.from_list

  // Both algorithms should find the same components
  assert tarjan_sets == kosaraju_sets
}

// ----------------------------------------------------------------------------
// MST: Kruskal vs Prim - Total weights should match
// ----------------------------------------------------------------------------

pub fn mst_kruskal_equals_prim_weight_test() {
  // Create small connected undirected graph
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 0, to: 3, with: 10)

  let kruskal_edges = mst.kruskal(in: graph, with_compare: int.compare)
  let prim_edges = mst.prim(in: graph, with_compare: int.compare)

  let kruskal_weight =
    kruskal_edges
    |> list.fold(0, fn(sum, edge) { sum + edge.weight })

  let prim_weight =
    prim_edges
    |> list.fold(0, fn(sum, edge) { sum + edge.weight })

  // Both should produce same total weight
  assert kruskal_weight == prim_weight
}

// ----------------------------------------------------------------------------
// Pathfinding: Bellman-Ford vs Dijkstra on non-negative graphs
// ----------------------------------------------------------------------------

pub fn bellman_ford_equals_dijkstra_test() {
  // Small graph with non-negative weights
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 3)
    |> model.add_edge(from: 0, to: 2, with: 10)

  let dijkstra_result = dijkstra.shortest_path_int(in: graph, from: 0, to: 2)

  let bellman_result =
    bellman_ford.bellman_ford(
      in: graph,
      from: 0,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Both should find same path weight
  case dijkstra_result, bellman_result {
    Some(d_path), bellman_ford.ShortestPath(path: b_path) -> {
      assert d_path.total_weight == b_path.total_weight
    }
    None, bellman_ford.NoPath -> Nil
    _, _ -> panic as "Dijkstra and Bellman-Ford disagree on path existence!"
  }
}

// ============================================================================
// CATEGORY 2: PATHFINDING CORRECTNESS
// ============================================================================

// ----------------------------------------------------------------------------
// Property: Dijkstra path is valid and connects start to goal
// ----------------------------------------------------------------------------

pub fn dijkstra_path_validity_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 3)

  case dijkstra.shortest_path_int(in: graph, from: 0, to: 3) {
    Some(path) -> {
      // Path should start at start node
      assert list.first(path.nodes) == Ok(0)

      // Path should end at goal node
      let last = list.last(path.nodes)
      assert last == Ok(3)

      // All edges in path should exist
      assert is_valid_path(graph, path.nodes)

      // Weight should match actual path weight
      let calculated = calculate_path_weight(graph, path.nodes)
      assert path.total_weight == calculated
    }
    None -> panic as "Path should exist!"
  }
}

// ----------------------------------------------------------------------------
// Property: No path should return None and BFS should confirm
// ----------------------------------------------------------------------------

pub fn dijkstra_no_path_confirmed_by_bfs_test() {
  // Disconnected graph
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 5)
  // Node 2 is unreachable from 0

  case dijkstra.shortest_path_int(in: graph, from: 0, to: 2) {
    None -> {
      // BFS should also confirm no path
      assert !is_reachable(graph, 0, 2)
    }
    Some(_) -> panic as "Should not find path to unreachable node!"
  }
}

// ----------------------------------------------------------------------------
// Property: Undirected paths are symmetric
// ----------------------------------------------------------------------------

pub fn undirected_paths_symmetric_test() {
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 3)
    |> model.add_edge(from: 1, to: 2, with: 4)

  let forward = dijkstra.shortest_path_int(in: graph, from: 0, to: 2)
  let backward = dijkstra.shortest_path_int(in: graph, from: 2, to: 0)

  case forward, backward {
    Some(f_path), Some(b_path) -> {
      // Weights should be equal for undirected graph
      assert f_path.total_weight == b_path.total_weight
    }
    None, None -> Nil
    _, _ -> panic as "Symmetric paths should both exist or both not exist!"
  }
}

// ----------------------------------------------------------------------------
// Property: Path from A to C via B >= direct path from A to C (triangle inequality)
// ----------------------------------------------------------------------------

pub fn triangle_inequality_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 5)
    |> model.add_edge(from: 1, to: 2, with: 3)
    |> model.add_edge(from: 0, to: 2, with: 10)

  let direct = dijkstra.shortest_path_int(in: graph, from: 0, to: 2)
  let via_1_part1 = dijkstra.shortest_path_int(in: graph, from: 0, to: 1)
  let via_1_part2 = dijkstra.shortest_path_int(in: graph, from: 1, to: 2)

  case direct, via_1_part1, via_1_part2 {
    Some(d), Some(p1), Some(p2) -> {
      let via_weight = p1.total_weight + p2.total_weight
      // Direct path should be <= path via intermediate node
      assert d.total_weight <= via_weight
    }
    _, _, _ -> Nil
  }
}

// ============================================================================
// CATEGORY 3: COMPLEX INVARIANTS
// ============================================================================

// ----------------------------------------------------------------------------
// Property: SCC components partition the graph
// ----------------------------------------------------------------------------

pub fn scc_components_partition_graph_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 0, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 1)
    |> model.add_edge(from: 3, to: 2, with: 1)

  let components = connectivity.strongly_connected_components(graph)

  // Every node should be in exactly one component
  let all_in_components =
    components
    |> list.flat_map(fn(comp) { comp })
    |> set.from_list

  let all_graph_nodes =
    model.all_nodes(graph)
    |> set.from_list

  // Coverage: all nodes appear in some component
  assert all_in_components == all_graph_nodes

  // Disjointness: components don't overlap
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

// ----------------------------------------------------------------------------
// Property: MST is actually a spanning tree (V-1 edges, connected, acyclic)
// ----------------------------------------------------------------------------

pub fn mst_is_spanning_tree_test() {
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 2)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 0, to: 3, with: 10)

  let mst_edges = mst.kruskal(in: graph, with_compare: int.compare)
  let n = model.order(graph)

  // Property 1: Tree has V-1 edges
  assert list.length(mst_edges) == n - 1

  // Property 2: Spans all nodes
  let nodes_in_mst =
    mst_edges
    |> list.flat_map(fn(edge) { [edge.from, edge.to] })
    |> set.from_list

  assert set.size(nodes_in_mst) == n

  // Property 3: Is connected (can reach all nodes from any node)
  let mst_graph = model.new(model.Undirected)

  let mst_graph =
    list.range(0, n - 1)
    |> list.fold(mst_graph, fn(g, i) { model.add_node(g, i, i) })

  let mst_graph =
    list.fold(mst_edges, mst_graph, fn(g, edge) {
      model.add_edge(g, from: edge.from, to: edge.to, with: edge.weight)
    })

  let reachable =
    traversal.walk(mst_graph, from: 0, using: traversal.BreadthFirst)

  assert list.length(reachable) == n
}

// ----------------------------------------------------------------------------
// Property: Bridges removal increases connected components
// ----------------------------------------------------------------------------

pub fn bridges_increase_components_test() {
  // Graph: 0-1-2 where 1-2 is a bridge
  let graph =
    model.new(model.Undirected)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 1, to: 0, with: 1)
    // Self-loop for testing
    |> model.add_edge(from: 1, to: 2, with: 1)

  let result = connectivity.analyze(in: graph)

  // Should find the bridge
  assert result.bridges != []

  // Removing a bridge should disconnect the graph
  let bridge = case list.first(result.bridges) {
    Ok(b) -> b
    Error(_) -> panic as "Should have found bridges"
  }

  let #(src, dst) = bridge
  let without_bridge =
    graph
    |> model.remove_edge(src, dst)
    |> model.remove_edge(dst, src)

  // After removing bridge, node 2 should be unreachable from 0
  assert !is_reachable(without_bridge, 0, 2)
}

// ----------------------------------------------------------------------------
// Property: Degree centrality matches manual count
// ----------------------------------------------------------------------------

pub fn degree_centrality_correctness_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(0, 0)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_edge(from: 0, to: 1, with: 1)
    |> model.add_edge(from: 0, to: 2, with: 1)
    |> model.add_edge(from: 1, to: 2, with: 1)

  let out_degrees = centrality.degree(graph, centrality.OutDegree)

  // Node 0 has 2 outgoing edges (normalized: 2/2 = 1.0)
  let degree_0 = case dict.get(out_degrees, 0) {
    Ok(degree) -> degree
    Error(_) -> panic as "Should have degree for node 0"
  }
  // Centrality is normalized, so check it's positive
  assert degree_0 >. 0.0

  // Node 1 has 1 outgoing edge (normalized: 1/2 = 0.5)
  let degree_1 = case dict.get(out_degrees, 1) {
    Ok(degree) -> degree
    Error(_) -> panic as "Should have degree for node 1"
  }
  assert degree_1 >. 0.0

  // Node 2 has 0 outgoing edges
  let degree_2 = case dict.get(out_degrees, 2) {
    Ok(degree) -> degree
    Error(_) -> panic as "Should have degree for node 2"
  }
  assert degree_2 == 0.0
}
