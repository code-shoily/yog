//// Dijkstra's algorithm for finding shortest paths in graphs with non-negative edge weights.

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleamy/priority_queue
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/utils.{
  type Path, Path, compare_distance_frontier, compare_frontier,
  should_explore_node,
}

/// Finds the shortest path between two nodes using Dijkstra's algorithm.
///
/// Works with non-negative edge weights only.
///
/// **Time Complexity:** O((V + E) log V) with heap
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// dijkstra.shortest_path(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => Some(Path([1, 2, 5], 15))
/// ```
pub fn shortest_path(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Option(Path(e)) {
  let frontier =
    priority_queue.new(fn(a, b) { compare_frontier(a, b, compare) })
    |> priority_queue.push(#(zero, [start]))

  do_dijkstra(graph, goal, frontier, dict.new(), add, compare)
  |> option.map(fn(res) {
    let #(dist, path) = res
    Path(nodes: list.reverse(path), total_weight: dist)
  })
}

pub fn do_dijkstra(
  graph: Graph(n, e),
  goal: NodeId,
  frontier: priority_queue.Queue(#(e, List(NodeId))),
  visited: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(#(e, List(NodeId))) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(dist, [current, ..] as path), rest_frontier)) -> {
      case current == goal {
        True -> Some(#(dist, path))
        False -> {
          let should_explore =
            should_explore_node(visited, current, dist, compare)

          case should_explore {
            False ->
              do_dijkstra(graph, goal, rest_frontier, visited, add, compare)
            True -> {
              let new_visited = dict.insert(visited, current, dist)

              let next_frontier =
                model.successors(graph, current)
                |> list.fold(rest_frontier, fn(h, neighbor) {
                  let #(next_id, weight) = neighbor
                  priority_queue.push(
                    h,
                    #(add(dist, weight), [next_id, ..path]),
                  )
                })

              do_dijkstra(graph, goal, next_frontier, new_visited, add, compare)
            }
          }
        }
      }
    }
    Ok(_) -> None
  }
}

/// Computes shortest distances from a source node to all reachable nodes.
///
/// Returns a dictionary mapping each reachable node to its shortest distance
/// from the source. Unreachable nodes are not included in the result.
///
/// **Time Complexity:** O((V + E) log V) with heap
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
pub fn single_source_distances(
  in graph: Graph(n, e),
  from source: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Dict(NodeId, e) {
  let frontier =
    priority_queue.new(fn(a, b) { compare_distance_frontier(a, b, compare) })
    |> priority_queue.push(#(zero, source))

  do_single_source_dijkstra(graph, frontier, dict.new(), add, compare)
}

fn do_single_source_dijkstra(
  graph: Graph(n, e),
  frontier: priority_queue.Queue(#(e, NodeId)),
  distances: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Dict(NodeId, e) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> distances
    Ok(#(#(dist, current), rest_frontier)) -> {
      let should_explore =
        should_explore_node(distances, current, dist, compare)

      case should_explore {
        False ->
          do_single_source_dijkstra(
            graph,
            rest_frontier,
            distances,
            add,
            compare,
          )
        True -> {
          let new_distances = dict.insert(distances, current, dist)

          let next_frontier =
            model.successors(graph, current)
            |> list.fold(rest_frontier, fn(h, neighbor) {
              let #(next_id, weight) = neighbor
              priority_queue.push(h, #(add(dist, weight), next_id))
            })

          do_single_source_dijkstra(
            graph,
            next_frontier,
            new_distances,
            add,
            compare,
          )
        }
      }
    }
  }
}

/// Finds the shortest path in an implicit graph using Dijkstra's algorithm.
///
/// Instead of a materialized `Graph`, this uses a `successors_with_cost` function
/// to compute weighted neighbors on demand.
///
/// Returns the shortest distance to any state satisfying `is_goal`, or `None`
/// if no goal state is reachable.
///
/// **Time Complexity:** O((V + E) log V) where V is visited states and E is explored transitions
///
/// ## Parameters
///
/// - `successors_with_cost`: Function that generates weighted successors for a state
/// - `is_goal`: Predicate that identifies goal states
/// - `zero`: The identity element for addition (e.g., 0 for integers)
/// - `add`: Function to add two costs
/// - `compare`: Function to compare two costs
pub fn implicit_dijkstra(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  let frontier =
    priority_queue.new(fn(a: #(cost, state), b: #(cost, state)) {
      compare(a.0, b.0)
    })
    |> priority_queue.push(#(zero, start))

  do_implicit_dijkstra(frontier, dict.new(), successors, is_goal, add, compare)
}

fn do_implicit_dijkstra(
  frontier: priority_queue.Queue(#(cost, state)),
  distances: Dict(state, cost),
  successors: fn(state) -> List(#(state, cost)),
  is_goal: fn(state) -> Bool,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(dist, current), rest_frontier)) -> {
      case is_goal(current) {
        True -> Some(dist)
        False -> {
          let should_explore =
            should_explore_node(distances, current, dist, compare)

          case should_explore {
            False ->
              do_implicit_dijkstra(
                rest_frontier,
                distances,
                successors,
                is_goal,
                add,
                compare,
              )
            True -> {
              let new_distances = dict.insert(distances, current, dist)

              let next_frontier =
                successors(current)
                |> list.fold(rest_frontier, fn(h, neighbor) {
                  let #(next_state, cost) = neighbor
                  priority_queue.push(h, #(add(dist, cost), next_state))
                })

              do_implicit_dijkstra(
                next_frontier,
                new_distances,
                successors,
                is_goal,
                add,
                compare,
              )
            }
          }
        }
      }
    }
  }
}

/// Like `implicit_dijkstra`, but deduplicates visited states by a custom key.
///
/// Essential when your state carries extra data beyond what defines identity.
/// The `visited_by` function extracts the deduplication key from each state.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
pub fn implicit_dijkstra_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  let frontier =
    priority_queue.new(fn(a: #(cost, state), b: #(cost, state)) {
      compare(a.0, b.0)
    })
    |> priority_queue.push(#(zero, start))

  do_implicit_dijkstra_by(
    frontier,
    dict.new(),
    successors,
    key_fn,
    is_goal,
    add,
    compare,
  )
}

fn do_implicit_dijkstra_by(
  frontier: priority_queue.Queue(#(cost, state)),
  distances: Dict(key, cost),
  successors: fn(state) -> List(#(state, cost)),
  key_fn: fn(state) -> key,
  is_goal: fn(state) -> Bool,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(dist, current), rest_frontier)) -> {
      case is_goal(current) {
        True -> Some(dist)
        False -> {
          let current_key = key_fn(current)
          let should_explore =
            should_explore_node(distances, current_key, dist, compare)

          case should_explore {
            False ->
              do_implicit_dijkstra_by(
                rest_frontier,
                distances,
                successors,
                key_fn,
                is_goal,
                add,
                compare,
              )
            True -> {
              let new_distances = dict.insert(distances, current_key, dist)

              let next_frontier =
                successors(current)
                |> list.fold(rest_frontier, fn(h, neighbor) {
                  let #(next_state, cost) = neighbor
                  priority_queue.push(h, #(add(dist, cost), next_state))
                })

              do_implicit_dijkstra_by(
                next_frontier,
                new_distances,
                successors,
                key_fn,
                is_goal,
                add,
                compare,
              )
            }
          }
        }
      }
    }
  }
}
