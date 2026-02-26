import gleam/list
import gleam/set.{type Set}
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
  do_walk(graph, [start_id], set.new(), [], order)
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
  do_walk_until(graph, [start_id], set.new(), [], order, should_stop)
}

fn do_walk(
  graph: Graph(n, e),
  queue: List(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
  order: Order,
) -> List(NodeId) {
  case queue {
    [] -> list.reverse(acc)
    [head, ..tail] -> {
      case set.contains(visited, head) {
        True -> do_walk(graph, tail, visited, acc, order)
        False -> {
          // We use successors here because walking a graph 
          // usually implies following the direction of the edges.
          let next_nodes = model.successor_ids(graph, head)

          let next_queue = case order {
            BreadthFirst -> list.append(tail, next_nodes)
            DepthFirst -> list.append(next_nodes, tail)
          }

          do_walk(
            graph,
            next_queue,
            set.insert(visited, head),
            [head, ..acc],
            order,
          )
        }
      }
    }
  }
}

fn do_walk_until(
  graph: Graph(n, e),
  queue: List(NodeId),
  visited: Set(NodeId),
  acc: List(NodeId),
  order: Order,
  should_stop: fn(NodeId) -> Bool,
) -> List(NodeId) {
  case queue {
    [] -> list.reverse(acc)
    [head, ..tail] -> {
      case set.contains(visited, head) {
        True -> do_walk_until(graph, tail, visited, acc, order, should_stop)
        False -> {
          let current_acc = [head, ..acc]

          // --- THE BREAKOUT CASE ---
          case should_stop(head) {
            True -> list.reverse(current_acc)
            False -> {
              let next_nodes = model.successor_ids(graph, head)

              let next_queue = case order {
                BreadthFirst -> list.append(tail, next_nodes)
                DepthFirst -> list.append(next_nodes, tail)
              }

              do_walk_until(
                graph,
                next_queue,
                set.insert(visited, head),
                current_acc,
                order,
                should_stop,
              )
            }
          }
        }
      }
    }
  }
}
