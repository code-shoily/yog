//// A* search algorithm with heuristic guidance.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleamy/priority_queue
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/utils.{
  type Path, Path, compare_a_star_frontier, should_explore_node,
}

/// Finds the shortest path using A* search with a heuristic function.
///
/// A* is more efficient than Dijkstra when you have a good heuristic estimate
/// of the remaining distance to the goal.
///
/// **Time Complexity:** O((V + E) log V)
///
/// ## Parameters
///
/// - `heuristic`: A function that estimates distance from any node to the goal.
///   Must be admissible (h(n) ≤ actual distance).
pub fn a_star(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
  heuristic h: fn(NodeId, NodeId) -> e,
) -> Option(Path(e)) {
  let initial_f = h(start, goal)
  let frontier =
    priority_queue.new(fn(a, b) { compare_a_star_frontier(a, b, compare) })
    |> priority_queue.push(#(initial_f, zero, [start]))

  do_a_star(graph, goal, frontier, dict.new(), add, compare, h)
  |> option.map(fn(res) {
    let #(dist, path) = res
    Path(nodes: list.reverse(path), total_weight: dist)
  })
}

fn do_a_star(
  graph,
  goal,
  frontier,
  visited,
  add,
  compare,
  h,
) -> Option(#(e, List(NodeId))) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(_, dist, [current, ..] as path), rest_frontier)) -> {
      case current == goal {
        True -> Some(#(dist, path))
        False -> {
          let should_explore =
            should_explore_node(visited, current, dist, compare)

          case should_explore {
            False ->
              do_a_star(graph, goal, rest_frontier, visited, add, compare, h)
            True -> {
              let new_visited = dict.insert(visited, current, dist)
              let next_frontier =
                model.successors(graph, current)
                |> list.fold(rest_frontier, fn(acc_h, neighbor) {
                  let #(next_id, weight) = neighbor
                  let next_dist = add(dist, weight)
                  let f_score = add(next_dist, h(next_id, goal))
                  priority_queue.push(
                    acc_h,
                    #(f_score, next_dist, [next_id, ..path]),
                  )
                })
              do_a_star(
                graph,
                goal,
                next_frontier,
                new_visited,
                add,
                compare,
                h,
              )
            }
          }
        }
      }
    }
    _ -> None
  }
}

/// Finds the shortest path in an implicit graph using A* search with a heuristic.
///
/// **Time Complexity:** O((V + E) log V)
///
/// ## Parameters
///
/// - `heuristic`: Function that estimates remaining cost from any state to goal.
///   Must be admissible.
pub fn implicit_a_star(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  is_goal is_goal: fn(state) -> Bool,
  heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  let initial_f = h(start)
  let frontier =
    priority_queue.new(fn(a: #(cost, cost, state), b: #(cost, cost, state)) {
      compare(a.0, b.0)
    })
    |> priority_queue.push(#(initial_f, zero, start))

  do_implicit_a_star(frontier, dict.new(), successors, is_goal, h, add, compare)
}

fn do_implicit_a_star(
  frontier: priority_queue.Queue(#(cost, cost, state)),
  distances: Dict(state, cost),
  successors: fn(state) -> List(#(state, cost)),
  is_goal: fn(state) -> Bool,
  h: fn(state) -> cost,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(_, dist, current), rest_frontier)) -> {
      case is_goal(current) {
        True -> Some(dist)
        False -> {
          let should_explore =
            should_explore_node(distances, current, dist, compare)

          case should_explore {
            False ->
              do_implicit_a_star(
                rest_frontier,
                distances,
                successors,
                is_goal,
                h,
                add,
                compare,
              )
            True -> {
              let new_distances = dict.insert(distances, current, dist)

              let next_frontier =
                successors(current)
                |> list.fold(rest_frontier, fn(frontier_acc, neighbor) {
                  let #(next_state, edge_cost) = neighbor
                  let next_dist = add(dist, edge_cost)
                  let f_score = add(next_dist, h(next_state))
                  priority_queue.push(frontier_acc, #(
                    f_score,
                    next_dist,
                    next_state,
                  ))
                })

              do_implicit_a_star(
                next_frontier,
                new_distances,
                successors,
                is_goal,
                h,
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

/// Like `implicit_a_star`, but deduplicates visited states by a custom key.
///
/// **Time Complexity:** O((V + E) log V) where V and E are measured in unique *keys*
pub fn implicit_a_star_by(
  from start: state,
  successors_with_cost successors: fn(state) -> List(#(state, cost)),
  visited_by key_fn: fn(state) -> key,
  is_goal is_goal: fn(state) -> Bool,
  heuristic h: fn(state) -> cost,
  with_zero zero: cost,
  with_add add: fn(cost, cost) -> cost,
  with_compare compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  let initial_f = h(start)
  let frontier =
    priority_queue.new(fn(a: #(cost, cost, state), b: #(cost, cost, state)) {
      compare(a.0, b.0)
    })
    |> priority_queue.push(#(initial_f, zero, start))

  do_implicit_a_star_by(
    frontier,
    dict.new(),
    successors,
    key_fn,
    is_goal,
    h,
    add,
    compare,
  )
}

fn do_implicit_a_star_by(
  frontier: priority_queue.Queue(#(cost, cost, state)),
  distances: Dict(key, cost),
  successors: fn(state) -> List(#(state, cost)),
  key_fn: fn(state) -> key,
  is_goal: fn(state) -> Bool,
  h: fn(state) -> cost,
  add: fn(cost, cost) -> cost,
  compare: fn(cost, cost) -> Order,
) -> Option(cost) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(_, dist, current), rest_frontier)) -> {
      case is_goal(current) {
        True -> Some(dist)
        False -> {
          let current_key = key_fn(current)
          let should_explore =
            should_explore_node(distances, current_key, dist, compare)

          case should_explore {
            False ->
              do_implicit_a_star_by(
                rest_frontier,
                distances,
                successors,
                key_fn,
                is_goal,
                h,
                add,
                compare,
              )
            True -> {
              let new_distances = dict.insert(distances, current_key, dist)

              let next_frontier =
                successors(current)
                |> list.fold(rest_frontier, fn(frontier_acc, neighbor) {
                  let #(next_state, edge_cost) = neighbor
                  let next_dist = add(dist, edge_cost)
                  let f_score = add(next_dist, h(next_state))
                  priority_queue.push(frontier_acc, #(
                    f_score,
                    next_dist,
                    next_state,
                  ))
                })

              do_implicit_a_star_by(
                next_frontier,
                new_distances,
                successors,
                key_fn,
                is_goal,
                h,
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

// -----------------------------------------------------------------------------
// CONVENIENCE WRAPPERS FOR COMMON TYPES
// -----------------------------------------------------------------------------

/// Finds the shortest path using A* with **integer weights**.
///
/// This is a convenience wrapper around `a_star` that uses:
/// - `0` as the zero element
/// - `int.add` for addition
/// - `int.compare` for comparison
///
/// You still need to provide a heuristic function.
///
/// ## Example
///
/// ```gleam
/// // Grid distance heuristic (Manhattan distance)
/// let heuristic = fn(from, to) {
///   let dx = int.absolute_value(from.x - to.x)
///   let dy = int.absolute_value(from.y - to.y)
///   dx + dy
/// }
///
/// a_star.a_star_int(graph, from: start, to: goal, heuristic: heuristic)
/// ```
pub fn a_star_int(
  in graph: Graph(n, Int),
  from start: NodeId,
  to goal: NodeId,
  heuristic h: fn(NodeId, NodeId) -> Int,
) -> Option(Path(Int)) {
  a_star(
    graph,
    start,
    goal,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare,
    heuristic: h,
  )
}

/// Finds the shortest path using A* with **float weights**.
///
/// This is a convenience wrapper around `a_star` that uses:
/// - `0.0` as the zero element
/// - `float.add` for addition
/// - `float.compare` for comparison
///
/// You still need to provide a heuristic function.
pub fn a_star_float(
  in graph: Graph(n, Float),
  from start: NodeId,
  to goal: NodeId,
  heuristic h: fn(NodeId, NodeId) -> Float,
) -> Option(Path(Float)) {
  a_star(
    graph,
    start,
    goal,
    with_zero: 0.0,
    with_add: float.add,
    with_compare: float.compare,
    heuristic: h,
  )
}
