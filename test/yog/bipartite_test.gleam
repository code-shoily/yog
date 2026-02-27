import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleeunit/should
import yog
import yog/bipartite

// ============= Bipartite Detection Tests =============

pub fn is_bipartite_empty_test() {
  let graph = yog.undirected()

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_single_node_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_path_test() {
  // Path: 1 - 2 - 3 - 4 (always bipartite)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_even_cycle_test() {
  // Square: 1 - 2 - 3 - 4 - 1 (even cycle is bipartite)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 1, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_odd_cycle_test() {
  // Triangle: 1 - 2 - 3 - 1 (odd cycle is NOT bipartite)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_false()
}

pub fn is_bipartite_complete_bipartite_test() {
  // K_2,3: Complete bipartite with left={1,2}, right={3,4,5}
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 1, to: 5, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 5, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_tree_test() {
  // Tree (always bipartite)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 5, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_disconnected_components_test() {
  // Two disconnected even cycles (both bipartite)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 1, with: 1)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_node(7, Nil)
    |> yog.add_node(8, Nil)
    |> yog.add_edge(from: 5, to: 6, with: 1)
    |> yog.add_edge(from: 6, to: 7, with: 1)
    |> yog.add_edge(from: 7, to: 8, with: 1)
    |> yog.add_edge(from: 8, to: 5, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_true()
}

pub fn is_bipartite_disconnected_with_odd_cycle_test() {
  // One even cycle + one odd cycle (not bipartite because of odd cycle)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)
    |> yog.add_edge(from: 4, to: 1, with: 1)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_node(7, Nil)
    |> yog.add_edge(from: 5, to: 6, with: 1)
    |> yog.add_edge(from: 6, to: 7, with: 1)
    |> yog.add_edge(from: 7, to: 5, with: 1)

  bipartite.is_bipartite(graph)
  |> should.be_false()
}

// ============= Partition Tests =============

pub fn partition_path_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(bipartite.Partition(left, right)) -> {
      // Should partition as {1, 3} and {2, 4}
      let left_size = set.size(left)
      let right_size = set.size(right)

      left_size
      |> should.equal(2)

      right_size
      |> should.equal(2)

      // Verify alternating pattern
      case set.contains(left, 1) {
        True -> {
          set.contains(left, 3)
          |> should.be_true()

          set.contains(right, 2)
          |> should.be_true()

          set.contains(right, 4)
          |> should.be_true()
        }
        False -> {
          set.contains(right, 1)
          |> should.be_true()

          set.contains(right, 3)
          |> should.be_true()

          set.contains(left, 2)
          |> should.be_true()

          set.contains(left, 4)
          |> should.be_true()
        }
      }
    }
  }
}

pub fn partition_returns_none_for_odd_cycle_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 1, with: 1)

  case bipartite.partition(graph) {
    None -> should.equal(1, 1)
    Some(_) -> should.fail()
  }
}

// ============= Maximum Matching Tests =============

pub fn maximum_matching_perfect_test() {
  // K_2,2: Complete bipartite graph with 2 vertices on each side
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      // Perfect matching: all 4 vertices matched (2 edges)
      list.length(matching)
      |> should.equal(2)

      // Verify all vertices are matched
      let matched_left =
        list.map(matching, fn(pair) { pair.0 })
        |> set.from_list()

      let matched_right =
        list.map(matching, fn(pair) { pair.1 })
        |> set.from_list()

      set.size(matched_left)
      |> should.equal(2)

      set.size(matched_right)
      |> should.equal(2)
    }
  }
}

pub fn maximum_matching_path_test() {
  // Path: 1 - 2 - 3 - 4
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 3, to: 4, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      // Maximum matching size is 2 (either 1-2, 3-4 or just one edge depending on partition)
      // Actually, the maximum matching in a path is floor(n/2) = 2
      list.length(matching)
      |> should.equal(2)
    }
  }
}

pub fn maximum_matching_unbalanced_test() {
  // K_2,3: 2 vertices on left, 3 on right
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 1, to: 5, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 5, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      // Maximum matching: min(2, 3) = 2
      list.length(matching)
      |> should.equal(2)
    }
  }
}

pub fn maximum_matching_empty_graph_test() {
  let graph = yog.undirected()

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      list.length(matching)
      |> should.equal(0)
    }
  }
}

pub fn maximum_matching_no_edges_test() {
  // Bipartite but no edges
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      list.length(matching)
      |> should.equal(0)
    }
  }
}

pub fn maximum_matching_augmenting_path_test() {
  // Test case where augmenting path algorithm needs to rematch
  // Graph: 1-3, 1-4, 2-4
  // First greedy match: 1-3
  // Then for 2: 2-4 is available
  // Result: {1-3, 2-4} or {1-4, 2-?} - wait, 2 only connects to 4
  // So we need: 1-3, 2-4 (both matched)
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      // Maximum matching: 2 edges
      list.length(matching)
      |> should.equal(2)
    }
  }
}

pub fn maximum_matching_directed_graph_test() {
  // Test with directed graph (should treat as undirected for bipartite purposes)
  let graph =
    yog.directed()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    |> yog.add_edge(from: 2, to: 4, with: 1)

  case bipartite.partition(graph) {
    None -> should.fail()
    Some(p) -> {
      let matching = bipartite.maximum_matching(graph, p)

      // Should still find a matching of size 2
      list.length(matching)
      |> should.equal(2)
    }
  }
}
