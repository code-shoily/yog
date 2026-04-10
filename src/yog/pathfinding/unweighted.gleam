//// Unweighted pathfinding algorithms for graphs where all edges have equal weight.
////
//// These algorithms use [Breadth-First Search (BFS)](https://en.wikipedia.org/wiki/Breadth-first_search)
//// to find paths and distances based on the number of hops between nodes.
////
//// | Algorithm | Function | Complexity | Best For |
//// |-----------|----------|------------|----------|
//// | BFS Path | `shortest_path/3` | O(V + E) | Single-pair unweighted paths |
//// | SSAD | `single_source_distances/2` | O(V + E) | Distances from one node to all others |
//// | Unweighted APSP | `all_pairs_shortest_paths/1` | O(V(V + E)) | All-pairs distances in sparse graphs |
////
//// ## Why Use Unweighted Algorithms?
////
//// If your graph doesn't have custom edge weights (or if all weights are identical),
//// Dijkstra and Floyd-Warshall are unnecessarily slow due to their use of priority 
//// queues or O(V³) matrices. BFS-based algorithms are the most efficient way to
//// calculate hop-counts.
////
//// ## Comparison with Weighted Algorithms
////
//// | Feature | Unweighted (BFS) | Weighted (Dijkstra) |
//// |---------|------------------|---------------------|
//// | point-to-point | O(V + E) | O((V+E) log V) |
//// | SS/APSP | O(V(V + E)) | O(V² log V + VE) |
//// | Overhead | Low (simple queue) | Higher (priority queue) |
////

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import yog/internal/queue
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/path.{type Path, Path}

/// Finds the shortest path (minimum hops) between two nodes in an unweighted graph.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// unweighted.shortest_path(graph, from: 1, to: 5)
/// // => Some(Path([1, 2, 5], 2))
/// ```
pub fn shortest_path(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  case start == goal {
    True -> Some(Path([start], 0))
    False -> {
      let q = queue.new() |> queue.push(#(start, [start]))
      let visited = dict.new() |> dict.insert(start, 0)
      do_shortest_path(graph, goal, q, visited)
    }
  }
}

fn do_shortest_path(
  graph: Graph(n, e),
  goal: NodeId,
  q: queue.Queue(#(NodeId, List(NodeId))),
  visited: Dict(NodeId, Int),
) -> Option(Path(Int)) {
  case queue.pop(q) {
    Error(Nil) -> None
    Ok(#(#(current, path), rest_q)) -> {
      case current == goal {
        True ->
          Some(Path(
            nodes: list.reverse(path),
            total_weight: list.length(path) - 1,
          ))
        False -> {
          let neighbors = model.successor_ids(graph, current)
          let #(next_q, next_visited) =
            list.fold(neighbors, #(rest_q, visited), fn(acc, neighbor) {
              let #(q_acc, v_acc) = acc
              case dict.has_key(v_acc, neighbor) {
                True -> acc
                False -> {
                  let dist =
                    dict.get(v_acc, current)
                    |> option.from_result
                    |> option.unwrap(0)
                  #(
                    queue.push(q_acc, #(neighbor, [neighbor, ..path])),
                    dict.insert(v_acc, neighbor, dist + 1),
                  )
                }
              }
            })
          do_shortest_path(graph, goal, next_q, next_visited)
        }
      }
    }
  }
}

/// Computes the shortest distance (in hops) from a source node to all reachable nodes.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// unweighted.single_source_distances(graph, source: 1)
/// // => Dict([#(1, 0), #(2, 1), #(5, 2)])
/// ```
pub fn single_source_distances(
  in graph: Graph(n, e),
  source start: NodeId,
) -> Dict(NodeId, Int) {
  let q = queue.new() |> queue.push(start)
  let visited = dict.from_list([#(start, 0)])
  do_single_source(graph, q, visited)
}

fn do_single_source(
  graph: Graph(n, e),
  q: queue.Queue(NodeId),
  distances: Dict(NodeId, Int),
) -> Dict(NodeId, Int) {
  case queue.pop(q) {
    Error(Nil) -> distances
    Ok(#(current, rest_q)) -> {
      let current_dist =
        dict.get(distances, current) |> option.from_result |> option.unwrap(0)
      let neighbors = model.successor_ids(graph, current)

      let #(next_q, next_distances) =
        list.fold(neighbors, #(rest_q, distances), fn(acc, neighbor) {
          let #(q_acc, d_acc) = acc
          case dict.has_key(d_acc, neighbor) {
            True -> acc
            False -> #(
              queue.push(q_acc, neighbor),
              dict.insert(d_acc, neighbor, current_dist + 1),
            )
          }
        })

      do_single_source(graph, next_q, next_distances)
    }
  }
}

/// Computes hop-count distances between all pairs of nodes in an unweighted graph.
///
/// This implementation runs a BFS from every node, which is much more efficient than
/// Floyd-Warshall for sparse unweighted graphs.
///
/// **Time Complexity:** O(V(V + E))
pub fn all_pairs_shortest_paths(
  in graph: Graph(n, e),
) -> Dict(#(NodeId, NodeId), Int) {
  let nodes = dict.keys(graph.nodes)

  list.fold(nodes, dict.new(), fn(acc, source) {
    let distances = single_source_distances(graph, source)

    dict.fold(distances, acc, fn(apsp_acc, target, dist) {
      dict.insert(apsp_acc, #(source, target), dist)
    })
  })
}
