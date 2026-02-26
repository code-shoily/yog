import gleam/dict
import gleam/list
import gleam/order.{type Order}
import gleam/result
import yog/internal/heap
import yog/model.{type Graph, type NodeId}

/// Performs a topological sort on a directed graph using Kahn's algorithm.
///
/// Returns a linear ordering of nodes such that for every directed edge (u, v),
/// node u comes before node v in the ordering.
///
/// Returns `Error(Nil)` if the graph contains a cycle.
///
/// **Time Complexity:** O(V + E) where V is vertices and E is edges
///
/// ## Example
///
/// ```gleam
/// topological_sort.topological_sort(graph)
/// // => Ok([1, 2, 3, 4])  // Valid ordering
/// // or Error(Nil)         // Cycle detected
/// ```
pub fn topological_sort(graph: Graph(n, e)) -> Result(List(NodeId), Nil) {
  // 1. Get all unique NodeIds from both out_edges and in_edges
  let all_nodes = model.all_nodes(graph)

  // 2. Calculate initial in-degrees
  let in_degrees =
    all_nodes
    |> list.map(fn(id) {
      let degree =
        dict.get(graph.in_edges, id)
        |> result.map(dict.size)
        |> result.unwrap(0)
      #(id, degree)
    })
    |> dict.from_list()

  // 3. Find starting nodes (in-degree 0)
  let queue =
    dict.to_list(in_degrees)
    |> list.filter(fn(pair) { pair.1 == 0 })
    |> list.map(fn(pair) { pair.0 })

  do_kahn(graph, queue, in_degrees, [], list.length(all_nodes))
}

/// Performs a topological sort that returns the lexicographically smallest sequence.
///
/// Uses a heap-based version of Kahn's algorithm to ensure that when multiple
/// nodes have in-degree 0, the smallest one (according to `compare_ids`) is chosen first.
///
/// Returns `Error(Nil)` if the graph contains a cycle.
///
/// **Time Complexity:** O(V log V + E) due to heap operations
///
/// ## Example
///
/// ```gleam
/// // Get smallest numeric ordering
/// topological_sort.lexicographical_topological_sort(graph, int.compare)
/// // => Ok([1, 2, 3, 4])  // Always picks smallest available node
/// ```
pub fn lexicographical_topological_sort(
  graph: Graph(n, e),
  compare_ids: fn(NodeId, NodeId) -> Order,
) -> Result(List(NodeId), Nil) {
  // 1. Get all nodes from the edge maps
  let all_nodes = model.all_nodes(graph)

  // 2. Initial in-degrees
  let in_degrees =
    all_nodes
    |> list.map(fn(id) {
      let degree =
        dict.get(graph.in_edges, id)
        |> result.map(dict.size)
        |> result.unwrap(0)
      #(id, degree)
    })
    |> dict.from_list()

  // 3. Find initial nodes with 0 in-degree and put them in your HEAP
  let initial_heap =
    dict.to_list(in_degrees)
    |> list.filter(fn(pair) { pair.1 == 0 })
    |> list.map(fn(pair) { pair.0 })
    |> list.fold(heap.new(), fn(h, id) { heap.insert(h, id, compare_ids) })

  do_lexical_kahn(
    graph,
    initial_heap,
    in_degrees,
    [],
    list.length(all_nodes),
    compare_ids,
  )
}

fn do_lexical_kahn(graph, h, in_degrees, acc, total_count, compare_ids) {
  case heap.find_min(h) {
    Error(Nil) -> {
      case list.length(acc) == total_count {
        True -> Ok(list.reverse(acc))
        False -> Error(Nil)
      }
    }
    Ok(head) -> {
      let assert Ok(rest_h) = heap.delete_min(h, compare_ids)
      let neighbors = model.successor_ids(graph, head)

      let #(next_h, next_in_degrees) =
        list.fold(neighbors, #(rest_h, in_degrees), fn(state, neighbor) {
          let #(current_h, degrees) = state
          let current_degree = dict.get(degrees, neighbor) |> result.unwrap(0)
          let new_degree = current_degree - 1

          let new_degrees = dict.insert(degrees, neighbor, new_degree)
          let updated_h = case new_degree == 0 {
            True -> heap.insert(current_h, neighbor, compare_ids)
            False -> current_h
          }
          #(updated_h, new_degrees)
        })

      do_lexical_kahn(
        graph,
        next_h,
        next_in_degrees,
        [head, ..acc],
        total_count,
        compare_ids,
      )
    }
  }
}

fn do_kahn(graph, queue, in_degrees, acc, total_node_count) {
  case queue {
    [] -> {
      case list.length(acc) == total_node_count {
        True -> Ok(list.reverse(acc))
        False -> Error(Nil)
        // Cycle detected!
      }
    }
    [head, ..tail] -> {
      let neighbors = model.successor_ids(graph, head)

      let #(next_queue, next_in_degrees) =
        list.fold(neighbors, #(tail, in_degrees), fn(state, neighbor) {
          let #(q, degrees) = state
          let current_degree = dict.get(degrees, neighbor) |> result.unwrap(0)
          let new_degree = current_degree - 1

          let new_degrees = dict.insert(degrees, neighbor, new_degree)
          let new_q = case new_degree == 0 {
            True -> [neighbor, ..q]
            False -> q
          }
          #(new_q, new_degrees)
        })

      do_kahn(
        graph,
        next_queue,
        next_in_degrees,
        [head, ..acc],
        total_node_count,
      )
    }
  }
}
