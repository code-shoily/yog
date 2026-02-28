import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/set.{type Set}
import gleamy/priority_queue
import yog/model.{type Graph, type NodeId}
import yog/transform

pub type MinCut {
  MinCut(weight: Int, group_a_size: Int, group_b_size: Int)
}

/// Finds the global minimum cut of an undirected weighted graph using the
/// Stoer-Wagner algorithm.
///
/// Returns the minimum cut weight and the sizes of the two partitions.
/// Perfect for AoC 2023 Day 25, where you need to find the cut of weight 3
/// and compute the product of partition sizes.
///
/// **Time Complexity:** O(V³) or O(VE + V² log V) with a good priority queue
///
/// ## Example
///
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_node(4, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///   |> yog.add_edge(from: 1, to: 4, with: 1)
///
/// let result = min_cut.global_min_cut(in: graph)
/// // result.weight == 2 (minimum cut)
/// // result.group_a_size * result.group_b_size == product of partition sizes
/// ```
pub fn global_min_cut(in graph: Graph(n, Int)) -> MinCut {
  // Start every node with a weight of 1 (representing itself)
  // This tracks how many original nodes have been merged together
  let graph = transform.map_nodes(graph, fn(_) { 1 })
  do_min_cut(
    graph,
    MinCut(weight: 999_999_999, group_a_size: 0, group_b_size: 0),
  )
}

fn do_min_cut(graph: Graph(Int, Int), best: MinCut) -> MinCut {
  case model.order(graph) <= 1 {
    True -> best
    False -> {
      let #(s, t, cut_weight) = maximum_adjacency_search(graph)

      let assert Ok(t_size) = dict.get(graph.nodes, t)
      let assert Ok(s_size) = dict.get(graph.nodes, s)
      let total_nodes = list.fold(dict.values(graph.nodes), 0, int.add)

      let current_cut =
        MinCut(
          weight: cut_weight,
          group_a_size: t_size,
          group_b_size: total_nodes - t_size,
        )

      let best = case current_cut.weight < best.weight {
        True -> current_cut
        False -> best
      }

      let next_graph =
        transform.contract(
          in: graph,
          merge: s,
          with: t,
          combine_weights: int.add,
        )

      let next_graph = model.add_node(next_graph, s, s_size + t_size)

      do_min_cut(next_graph, best)
    }
  }
}

/// Maximum Adjacency Search (MAS): finds the two most tightly connected nodes.
///
/// Returns #(s, t, cut_weight) where:
/// - s: second-to-last node added
/// - t: last node added
/// - cut_weight: sum of edge weights connecting t to the rest of the graph
///
/// This is similar to Prim's algorithm but picks nodes by maximum total
/// connection weight to the current set, not minimum edge weight.
fn maximum_adjacency_search(graph: Graph(Int, Int)) -> #(NodeId, NodeId, Int) {
  let all_nodes = model.all_nodes(graph)

  let assert Ok(start) = list.first(all_nodes)
  let initial_order = [start]
  let remaining = set.from_list(all_nodes) |> set.delete(start)

  let #(initial_weights, initial_queue) =
    model.neighbors(graph, start)
    |> list.fold(#(dict.new(), priority_queue.new(compare_max)), fn(acc, edge) {
      let #(weights_acc, queue_acc) = acc
      let #(neighbor, weight) = edge
      case set.contains(remaining, neighbor) {
        True -> #(
          dict.insert(weights_acc, neighbor, weight),
          priority_queue.push(queue_acc, #(weight, neighbor)),
        )
        False -> acc
      }
    })

  let final_order =
    build_mas_order(
      graph,
      initial_order,
      remaining,
      initial_weights,
      initial_queue,
    )

  // Fix: Don't reverse! The list is built with newest at head
  let assert [t, s, ..] = final_order

  let cut_weight =
    model.neighbors(graph, t)
    |> list.fold(0, fn(sum, edge) {
      let #(_, weight) = edge
      sum + weight
    })

  #(s, t, cut_weight)
}

/// Builds the MAS ordering by greedily adding the most tightly connected node.
fn build_mas_order(
  graph: Graph(Int, Int),
  current_order: List(NodeId),
  remaining: Set(NodeId),
  weights: dict.Dict(NodeId, Int),
  queue: priority_queue.Queue(#(Int, NodeId)),
) -> List(NodeId) {
  case set.size(remaining) {
    0 -> current_order
    _ -> {
      let #(node, new_queue) = get_next_mas_node(queue, remaining, weights)
      let new_remaining = set.delete(remaining, node)

      let #(new_weights, updated_queue) =
        model.neighbors(graph, node)
        |> list.fold(#(weights, new_queue), fn(acc, edge) {
          let #(weights_acc, queue_acc) = acc
          let #(neighbor, weight) = edge
          case set.contains(new_remaining, neighbor) {
            True -> {
              let existing_w = case dict.get(weights_acc, neighbor) {
                Ok(v) -> v
                Error(_) -> 0
              }
              let new_w = existing_w + weight
              #(
                dict.insert(weights_acc, neighbor, new_w),
                priority_queue.push(queue_acc, #(new_w, neighbor)),
              )
            }
            False -> acc
          }
        })

      build_mas_order(
        graph,
        [node, ..current_order],
        new_remaining,
        new_weights,
        updated_queue,
      )
    }
  }
}

fn get_next_mas_node(
  queue: priority_queue.Queue(#(Int, NodeId)),
  remaining: Set(NodeId),
  weights: dict.Dict(NodeId, Int),
) -> #(NodeId, priority_queue.Queue(#(Int, NodeId))) {
  case priority_queue.pop(queue) {
    Ok(#(#(w, node), q_rest)) -> {
      case set.contains(remaining, node) {
        True -> {
          // Verify this is the current weight, not a stale entry
          let current_weight = case dict.get(weights, node) {
            Ok(v) -> v
            Error(_) -> 0
          }
          case w == current_weight {
            True -> #(node, q_rest)
            False -> get_next_mas_node(q_rest, remaining, weights)
          }
        }
        False -> get_next_mas_node(q_rest, remaining, weights)
      }
    }
    Error(_) -> {
      // If queue is empty, pick the node with minimum ID from remaining
      let assert Ok(node) = set.to_list(remaining) |> list.first()
      #(node, queue)
    }
  }
}

fn compare_max(a: #(Int, NodeId), b: #(Int, NodeId)) -> order.Order {
  // Compare by weight (descending), then by node ID (ascending) for deterministic tie-breaking
  case int.compare(b.0, a.0) {
    order.Eq -> int.compare(a.1, b.1)
    other -> other
  }
}
