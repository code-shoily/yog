//// Shared types and utilities for pathfinding algorithms.

import gleam/dict.{type Dict}
import gleam/order.{type Order, Lt}
import yog/model.{type NodeId}

/// Represents a path through the graph with its total weight.
pub type Path(e) {
  Path(nodes: List(NodeId), total_weight: e)
}

pub fn compare_frontier(
  a: #(e, List(NodeId)),
  b: #(e, List(NodeId)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

pub fn compare_distance_frontier(
  a: #(e, NodeId),
  b: #(e, NodeId),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

pub fn compare_a_star_frontier(
  a: #(e, e, List(NodeId)),
  b: #(e, e, List(NodeId)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Helper to determine if a node should be explored based on distance comparison.
/// Returns True if the node hasn't been visited or if the new distance is shorter.
pub fn should_explore_node(
  visited: Dict(k, e),
  node: k,
  new_dist: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  case dict.get(visited, node) {
    Ok(prev_dist) ->
      case compare(new_dist, prev_dist) {
        Lt -> True
        _ -> False
      }
    Error(Nil) -> True
  }
}
