import gleam/int
import gleam/list
import gleam/order
import gleam/set
import gleeunit/should
import yog
import yog/max_flow
import yog/model

// Debug test: check if residual graph construction works
pub fn residual_graph_construction_test() {
  let _network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)

  // Manually build residual graph to test
  let residual =
    model.new(model.Directed)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_edge(from: 0, to: 1, with: 10)
    |> model.add_edge(from: 1, to: 0, with: 0)

  let successors_0 = model.successors(residual, 0)
  let successors_1 = model.successors(residual, 1)

  list.length(successors_0)
  |> should.equal(1)

  list.length(successors_1)
  |> should.equal(1)
}

// Basic test: simple network with one bottleneck
pub fn simple_flow_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 1, to: 2, with: 5)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(5)
}

// Two parallel paths with different capacities
pub fn parallel_paths_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 10)
    |> yog.add_edge(from: 1, to: 3, with: 4)
    |> yog.add_edge(from: 2, to: 3, with: 9)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Flow limited by smaller path capacities: 4 + 9 = 13
  result.max_flow
  |> should.equal(13)
}

// Network with multiple paths and intermediate connections
pub fn complex_network_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 10)
    |> yog.add_edge(from: 1, to: 2, with: 2)
    |> yog.add_edge(from: 1, to: 3, with: 4)
    |> yog.add_edge(from: 1, to: 4, with: 8)
    |> yog.add_edge(from: 2, to: 4, with: 9)
    |> yog.add_edge(from: 3, to: 5, with: 10)
    |> yog.add_edge(from: 4, to: 3, with: 6)
    |> yog.add_edge(from: 4, to: 5, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(19)
}

// Classic textbook example
pub fn textbook_example_test() {
  // From Cormen et al. "Introduction to Algorithms"
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 16)
    |> yog.add_edge(from: 0, to: 2, with: 13)
    |> yog.add_edge(from: 1, to: 2, with: 10)
    |> yog.add_edge(from: 1, to: 3, with: 12)
    |> yog.add_edge(from: 2, to: 1, with: 4)
    |> yog.add_edge(from: 2, to: 4, with: 14)
    |> yog.add_edge(from: 3, to: 2, with: 9)
    |> yog.add_edge(from: 3, to: 5, with: 20)
    |> yog.add_edge(from: 4, to: 3, with: 7)
    |> yog.add_edge(from: 4, to: 5, with: 4)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(23)
}

// No path from source to sink
pub fn no_path_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 2, to: 3, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(0)
}

// Single edge network
pub fn single_edge_test() {
  let network = yog.directed() |> yog.add_edge(from: 0, to: 1, with: 42)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(42)
}

// Source equals sink (should be 0)
pub fn source_equals_sink_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 1, to: 2, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 1,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(0)
}

// Zero capacity edges should be ignored
pub fn zero_capacity_edges_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 0)
    |> yog.add_edge(from: 0, to: 2, with: 10)
    |> yog.add_edge(from: 2, to: 1, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 1,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(10)
}

// Bipartite matching as max flow
pub fn bipartite_matching_test() {
  // Model bipartite matching as max flow:
  // Source (0) -> left partition (1,2) -> right partition (3,4) -> sink (5)
  // All edges have capacity 1
  let network =
    yog.directed()
    // Source to left partition
    |> yog.add_edge(from: 0, to: 1, with: 1)
    |> yog.add_edge(from: 0, to: 2, with: 1)
    // Left to right edges (potential matches)
    |> yog.add_edge(from: 1, to: 3, with: 1)
    |> yog.add_edge(from: 1, to: 4, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 1)
    // Right partition to sink
    |> yog.add_edge(from: 3, to: 5, with: 1)
    |> yog.add_edge(from: 4, to: 5, with: 1)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Maximum matching is 2
  result.max_flow
  |> should.equal(2)
}

// Min-cut extraction - simple case
pub fn min_cut_simple_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 10)
    |> yog.add_edge(from: 1, to: 3, with: 4)
    |> yog.add_edge(from: 2, to: 3, with: 9)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  let cut = max_flow.min_cut(result, with_zero: 0, with_compare: int.compare)

  // Source side should contain source
  set.contains(cut.source_side, 0)
  |> should.be_true()

  // Sink side should contain sink
  set.contains(cut.sink_side, 3)
  |> should.be_true()

  // All nodes should be in one side or the other
  let total_size = set.size(cut.source_side) + set.size(cut.sink_side)
  total_size
  |> should.equal(4)
}

// Min-cut extraction - verify partitioning
pub fn min_cut_partitioning_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 1, to: 2, with: 5)
    |> yog.add_edge(from: 2, to: 3, with: 15)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  let cut = max_flow.min_cut(result, with_zero: 0, with_compare: int.compare)

  // Source and sink should be in different partitions
  let source_in_source_side = set.contains(cut.source_side, 0)
  let sink_in_sink_side = set.contains(cut.sink_side, 3)

  source_in_source_side
  |> should.be_true()

  sink_in_sink_side
  |> should.be_true()

  // Partitions should not overlap
  let intersection = set.intersection(cut.source_side, cut.sink_side)
  set.size(intersection)
  |> should.equal(0)
}

// Triangle network with cycle
pub fn triangle_with_cycle_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 1, to: 2, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 5)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 2,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Direct path has capacity 5, path through 1 has capacity 10
  // Total flow should be 15
  result.max_flow
  |> should.equal(15)
}

// Multiple bottlenecks
pub fn multiple_bottlenecks_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 100)
    |> yog.add_edge(from: 1, to: 2, with: 1)
    |> yog.add_edge(from: 2, to: 3, with: 100)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Bottleneck is the edge 1->2 with capacity 1
  result.max_flow
  |> should.equal(1)
}

// Diamond network
pub fn diamond_network_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 10)
    |> yog.add_edge(from: 1, to: 3, with: 10)
    |> yog.add_edge(from: 2, to: 3, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  result.max_flow
  |> should.equal(20)
}

// Network with intermediate node having limited outgoing capacity
pub fn limited_intermediate_capacity_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 100)
    |> yog.add_edge(from: 0, to: 2, with: 100)
    |> yog.add_edge(from: 1, to: 3, with: 5)
    |> yog.add_edge(from: 2, to: 3, with: 7)
    |> yog.add_edge(from: 3, to: 4, with: 8)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 4,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Node 3 can receive 5+7=12 but can only send 8
  result.max_flow
  |> should.equal(8)
}

// Flow with float capacities
pub fn float_capacities_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10.5)
    |> yog.add_edge(from: 1, to: 2, with: 5.5)
    |> yog.add_edge(from: 0, to: 2, with: 3.0)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 2,
      with_zero: 0.0,
      with_add: fn(a, b) { a +. b },
      with_subtract: fn(a, b) { a -. b },
      with_compare: fn(a, b) {
        case a <. b {
          True -> order.Lt
          False ->
            case a >. b {
              True -> order.Gt
              False -> order.Eq
            }
        }
      },
      with_min: fn(a, b) {
        case a <. b {
          True -> a
          False -> b
        }
      },
    )

  // 5.5 through path 0->1->2, plus 3.0 direct = 8.5
  result.max_flow
  |> should.equal(8.5)
}

// Verify max flow = min cut (theorem verification)
pub fn max_flow_min_cut_theorem_test() {
  let network =
    yog.directed()
    |> yog.add_edge(from: 0, to: 1, with: 10)
    |> yog.add_edge(from: 0, to: 2, with: 5)
    |> yog.add_edge(from: 1, to: 3, with: 15)
    |> yog.add_edge(from: 2, to: 3, with: 10)

  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  // Max flow should equal the capacity of minimum cut
  // In this case, max flow = 15
  result.max_flow
  |> should.equal(15)

  let cut = max_flow.min_cut(result, with_zero: 0, with_compare: int.compare)

  // Verify cut partitions the graph
  set.contains(cut.source_side, 0)
  |> should.be_true()

  set.contains(cut.sink_side, 3)
  |> should.be_true()
}
