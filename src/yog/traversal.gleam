import gleam/list
import gleam/set.{type Set}
import yog/internal/queue
import yog/model.{type Graph, type NodeId}

/// Traversal order for graph walking algorithms.
pub type Order {
  /// Breadth-First Search: visit all neighbors before going deeper.
  BreadthFirst
  /// Depth-First Search: visit as deep as possible before backtracking.
  DepthFirst
}

/// Walks the graph starting from the given node, visiting all reachable nodes.
///
/// Returns a list of NodeIds in the order they were visited.
/// Uses successors to follow directed paths.
///
/// ## Example
///
/// ```gleam
/// // BFS traversal
/// traversal.walk(from: 1, in: graph, using: BreadthFirst)
/// // => [1, 2, 3, 4, 5]
///
/// // DFS traversal
/// traversal.walk(from: 1, in: graph, using: DepthFirst)
/// // => [1, 2, 4, 5, 3]
/// ```
pub fn walk(
  from start_id: NodeId,
  in graph: Graph(n, e),
  using order: Order,
) -> List(NodeId) {
  case order {
    BreadthFirst ->
      do_walk_bfs(graph, queue.new() |> queue.push(start_id), set.new(), [])
    DepthFirst -> do_walk_dfs(graph, [start_id], set.new(), [])
  }
}

/// Walks the graph but stops early when a condition is met.
///
/// Traverses the graph until `should_stop` returns True for a node.
/// Returns all nodes visited including the one that stopped traversal.
///
/// ## Example
///
/// ```gleam
/// // Stop when we find node 5
/// traversal.walk_until(
///   from: 1,
///   in: graph,
///   using: BreadthFirst,
///   until: fn(node) { node == 5 }
/// )
/// ```
pub fn walk_until(
  from start_id: NodeId,
  in graph: Graph(n, e),
  using order: Order,
  until should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  case order {
    BreadthFirst ->
      do_walk_until_bfs(
        graph,
        queue.new() |> queue.push(start_id),
        set.new(),
        [],
        should_stop,
      )
    DepthFirst ->
      do_walk_until_dfs(graph, [start_id], set.new(), [], should_stop)
  }
}

// BFS with efficient O(1) amortized queue operations
fn do_walk_bfs(
  graph: Graph(n, e),
  q: queue.Queue(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
) -> List(NodeId) {
  case queue.pop(q) {
    Error(Nil) -> list.reverse(acc)
    Ok(#(head, rest)) -> {
      case set.contains(visited, head) {
        True -> do_walk_bfs(graph, rest, visited, acc)
        False -> {
          let next_nodes = model.successor_ids(graph, head)
          let next_queue = queue.push_list(rest, next_nodes)

          do_walk_bfs(graph, next_queue, set.insert(visited, head), [
            head,
            ..acc
          ])
        }
      }
    }
  }
}

// DFS with list-based stack (prepend is O(1))
fn do_walk_dfs(
  graph: Graph(n, e),
  stack: List(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
) -> List(NodeId) {
  case stack {
    [] -> list.reverse(acc)
    [head, ..tail] -> {
      case set.contains(visited, head) {
        True -> do_walk_dfs(graph, tail, visited, acc)
        False -> {
          let next_nodes = model.successor_ids(graph, head)
          let next_stack = list.append(next_nodes, tail)

          do_walk_dfs(graph, next_stack, set.insert(visited, head), [
            head,
            ..acc
          ])
        }
      }
    }
  }
}

// BFS with early termination
fn do_walk_until_bfs(
  graph: Graph(n, e),
  q: queue.Queue(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
  should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  case queue.pop(q) {
    Error(Nil) -> list.reverse(acc)
    Ok(#(head, rest)) -> {
      case set.contains(visited, head) {
        True -> do_walk_until_bfs(graph, rest, visited, acc, should_stop)
        False -> {
          let current_acc = [head, ..acc]

          case should_stop(head) {
            True -> list.reverse(current_acc)
            False -> {
              let next_nodes = model.successor_ids(graph, head)
              let next_queue = queue.push_list(rest, next_nodes)

              do_walk_until_bfs(
                graph,
                next_queue,
                set.insert(visited, head),
                current_acc,
                should_stop,
              )
            }
          }
        }
      }
    }
  }
}

// DFS with early termination
fn do_walk_until_dfs(
  graph: Graph(n, e),
  stack: List(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
  should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  case stack {
    [] -> list.reverse(acc)
    [head, ..tail] -> {
      case set.contains(visited, head) {
        True -> do_walk_until_dfs(graph, tail, visited, acc, should_stop)
        False -> {
          let current_acc = [head, ..acc]

          case should_stop(head) {
            True -> list.reverse(current_acc)
            False -> {
              let next_nodes = model.successor_ids(graph, head)
              let next_stack = list.append(next_nodes, tail)

              do_walk_until_dfs(
                graph,
                next_stack,
                set.insert(visited, head),
                current_acc,
                should_stop,
              )
            }
          }
        }
      }
    }
  }
}
