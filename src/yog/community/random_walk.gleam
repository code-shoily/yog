//// Random walk primitives for graph analysis and community detection.
////
//// Provides basic random walk operations that can be used for community
//// detection, node ranking, and graph exploration.
////
//// ## Functions
////
//// | Function | Purpose |
//// |----------|---------|
//// | `random_walk/3` | Simple random walk from a start node |
//// | `random_walk_with_restart/4` | Random walk with restart probability (RWR) |
//// | `transition_probabilities/3` | Calculate transition probabilities from a node |
////
//// ## When to Use
////
//// - **Graph exploration**: Traverse graph in a stochastic manner
//// - **Similarity measure**: Random walk distances between nodes
//// - **Community detection**: Used by Walktrap and other algorithms
//// - **Personalized PageRank**: RWR is related to PPR
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/random_walk as rw
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1)])
////
//// // Simple random walk
//// let path = rw.random_walk(graph, start: 1, steps: 10)
//// // => [1, 2, 3, 2, 1, ...]  (stochastic)
////
//// // Random walk with restart (Personalized PageRank style)
//// let path = rw.random_walk_with_restart(graph, start: 1, restart_prob: 0.15, steps: 100)
////
//// // Transition probabilities from a node
//// let probs = rw.transition_probabilities(graph, node: 1, to_float: fn(x) { x })
//// // => [#(2, 1.0)]  // 100% chance to go to node 2
//// ```

import gleam/float
import gleam/int
import gleam/list
import yog/model.{type Graph, type NodeId}

/// Basic random walk from a starting node.
/// Each step chooses a neighbor uniformly at random (unweighted).
/// Returns the sequence of node IDs visited, including the start node.
/// Stops early if a sink (node with no outgoing edges) is reached.
pub fn random_walk(
  graph: Graph(n, e),
  start: NodeId,
  steps: Int,
) -> List(NodeId) {
  do_random_walk(graph, start, steps, [start])
}

fn do_random_walk(
  graph: Graph(n, e),
  current: NodeId,
  remaining_steps: Int,
  acc: List(NodeId),
) -> List(NodeId) {
  case remaining_steps <= 0 {
    True -> list.reverse(acc)
    False -> {
      let neighbors = model.successors(graph, current)
      case neighbors {
        [] -> list.reverse(acc)
        _ -> {
          let n = list.length(neighbors)
          let idx =
            float.random() *. int.to_float(n)
            |> float.floor()
            |> float.truncate()
          let assert Ok(next) =
            list.drop(neighbors, idx)
            |> list.first
          do_random_walk(graph, next.0, remaining_steps - 1, [next.0, ..acc])
        }
      }
    }
  }
}

/// Random walk with a restart probability (Personalized PageRank style).
/// At each step, there is a `restart_prob` chance of jumping back to the start node.
/// If a sink is reached, it always jumps back to the start node.
pub fn random_walk_with_restart(
  graph: Graph(n, e),
  start: NodeId,
  restart_prob: Float,
  steps: Int,
) -> List(NodeId) {
  do_walk_with_restart(graph, start, start, restart_prob, steps, [start])
}

fn do_walk_with_restart(
  graph: Graph(n, e),
  start: NodeId,
  current: NodeId,
  restart_prob: Float,
  remaining_steps: Int,
  acc: List(NodeId),
) -> List(NodeId) {
  case remaining_steps <= 0 {
    True -> list.reverse(acc)
    False -> {
      let r = float.random()
      case r <. restart_prob {
        True ->
          do_walk_with_restart(
            graph,
            start,
            start,
            restart_prob,
            remaining_steps - 1,
            [start, ..acc],
          )
        False -> {
          let neighbors = model.successors(graph, current)
          case neighbors {
            [] ->
              do_walk_with_restart(
                graph,
                start,
                start,
                restart_prob,
                remaining_steps - 1,
                [start, ..acc],
              )
            _ -> {
              let n = list.length(neighbors)
              let idx =
                float.random() *. int.to_float(n)
                |> float.floor()
                |> float.truncate()
              let assert Ok(next) =
                list.drop(neighbors, idx)
                |> list.first
              do_walk_with_restart(
                graph,
                start,
                next.0,
                restart_prob,
                remaining_steps - 1,
                [next.0, ..acc],
              )
            }
          }
        }
      }
    }
  }
}

/// Calculates transition probabilities from a node based on edge weights.
/// Assumes weights are numeric and can be converted to Float.
pub fn transition_probabilities(
  graph: Graph(n, e),
  node: NodeId,
  to_float: fn(e) -> Float,
) -> List(#(NodeId, Float)) {
  let neighbors = model.successors(graph, node)
  let total_weight =
    list.map(neighbors, fn(p) { to_float(p.1) })
    |> list.fold(0.0, float.add)

  case total_weight <=. 0.0 {
    True -> []
    False -> {
      list.map(neighbors, fn(p) { #(p.0, to_float(p.1) /. total_weight) })
    }
  }
}
