import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Lt}
import gleam/set
import gleamy/priority_queue
import yog/model.{type Graph, type NodeId}

/// Represents a path through the graph with its total weight.
pub type Path(e) {
  Path(nodes: List(NodeId), total_weight: e)
}

/// Finds the shortest path between two nodes using Dijkstra's algorithm.
///
/// Works with non-negative edge weights only. For negative weights, use `bellman_ford`.
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
/// pathfinding.shortest_path(
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
}

fn do_dijkstra(
  graph: Graph(n, e),
  goal: NodeId,
  frontier: priority_queue.Queue(#(e, List(NodeId))),
  visited: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Option(Path(e)) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(dist, [current, ..] as path), rest_frontier)) -> {
      case current == goal {
        True -> Some(Path(nodes: list.reverse(path), total_weight: dist))
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

fn compare_frontier(
  a: #(e, List(NodeId)),
  b: #(e, List(NodeId)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

fn compare_distance_frontier(
  a: #(e, NodeId),
  b: #(e, NodeId),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

fn compare_a_star_frontier(
  a: #(e, e, List(NodeId)),
  b: #(e, e, List(NodeId)),
  cmp: fn(e, e) -> Order,
) -> Order {
  cmp(a.0, b.0)
}

/// Helper to determine if a node should be explored based on distance comparison.
/// Returns True if the node hasn't been visited or if the new distance is shorter.
fn should_explore_node(
  visited: Dict(NodeId, e),
  node: NodeId,
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

/// Computes shortest distances from a source node to all reachable nodes.
///
/// Returns a dictionary mapping each reachable node to its shortest distance
/// from the source. Unreachable nodes are not included in the result.
///
/// This is useful when you need distances to multiple destinations, or want
/// to find the closest target among many options. More efficient than running
/// `shortest_path` multiple times.
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
/// // Find distances from node 1 to all reachable nodes
/// let distances = pathfinding.single_source_distances(
///   in: graph,
///   from: 1,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => dict.from_list([#(1, 0), #(2, 5), #(3, 8), #(4, 15)])
///
/// // Find closest target among many options
/// let targets = [10, 20, 30]
/// let closest = targets
///   |> list.filter_map(fn(t) { dict.get(distances, t) })
///   |> list.sort(int.compare)
///   |> list.first
/// ```
///
/// ## Use Cases
///
/// - Finding nearest target among multiple options
/// - Computing distance maps for game AI
/// - Network routing table generation
/// - Graph analysis (centrality measures)
/// - Reverse pathfinding (with `transform.transpose`)
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
      // Check if we've already found a better path to this node
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

// ======================== A* SEARCH ========================

/// Finds the shortest path using A* search with a heuristic function.
///
/// A* is more efficient than Dijkstra when you have a good heuristic estimate
/// of the remaining distance to the goal. The heuristic must be admissible
/// (never overestimate the actual distance) to guarantee finding the shortest path.
///
/// **Time Complexity:** O((V + E) log V), but often faster than Dijkstra in practice
///
/// ## Parameters
///
/// - `heuristic`: A function that estimates distance from any node to the goal.
///   Must be admissible (h(n) ≤ actual distance) to guarantee shortest path.
///
/// ## Example
///
/// ```gleam
/// // Manhattan distance heuristic for grid
/// let h = fn(node, goal) {
///   int.absolute_value(node.x - goal.x) + int.absolute_value(node.y - goal.y)
/// }
///
/// pathfinding.a_star(
///   in: graph,
///   from: start,
///   to: goal,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare,
///   heuristic: h
/// )
/// ```
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
  // Queue stores #(F_Score, Actual_Dist, Path)
  let frontier =
    priority_queue.new(fn(a, b) { compare_a_star_frontier(a, b, compare) })
    |> priority_queue.push(#(initial_f, zero, [start]))

  do_a_star(graph, goal, frontier, dict.new(), add, compare, h)
}

fn do_a_star(graph, goal, frontier, visited, add, compare, h) {
  case priority_queue.pop(frontier) {
    Error(Nil) -> None
    Ok(#(#(_, dist, [current, ..] as path), rest_frontier)) -> {
      case current == goal {
        True -> Some(Path(nodes: list.reverse(path), total_weight: dist))
        False -> {
          // G-SAFE BRANCHING (No guards)
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

// ======================== BELLMAN-FORD ========================

/// Result type for Bellman-Ford algorithm.
pub type BellmanFordResult(e) {
  /// A shortest path was found successfully
  ShortestPath(path: Path(e))
  /// A negative cycle was detected (reachable from source)
  NegativeCycle
  /// No path exists from start to goal
  NoPath
}

/// Finds shortest path with support for negative edge weights using Bellman-Ford.
///
/// Unlike Dijkstra and A*, this algorithm can handle negative edge weights.
/// It also detects negative cycles reachable from the source node.
///
/// **Time Complexity:** O(VE) where V is vertices and E is edges
///
/// ## Returns
///
/// - `ShortestPath(path)`: If a valid shortest path exists
/// - `NegativeCycle`: If a negative cycle is reachable from the start node
/// - `NoPath`: If no path exists from start to goal
///
/// ## Example
///
/// ```gleam
/// pathfinding.bellman_ford(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// )
/// // => ShortestPath(Path([1, 3, 5], -2))  // Can have negative total weight
/// // or NegativeCycle                       // If cycle detected
/// // or NoPath                              // If unreachable
/// ```
pub fn bellman_ford(
  in graph: Graph(n, e),
  from start: NodeId,
  to goal: NodeId,
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> BellmanFordResult(e) {
  // Get all nodes
  let all_nodes = model.all_nodes(graph)

  // Initialize distances: start=0, others=infinity (represented as None)
  let initial_distances = dict.from_list([#(start, zero)])
  let initial_predecessors = dict.new()

  // Run V-1 iterations of edge relaxation
  let node_count = list.length(all_nodes)
  let #(distances, predecessors) =
    relaxation_passes(
      graph,
      all_nodes,
      initial_distances,
      initial_predecessors,
      node_count - 1,
      add,
      compare,
    )

  // Check for negative cycles
  case has_negative_cycle(graph, all_nodes, distances, add, compare) {
    True -> NegativeCycle
    False -> {
      // Reconstruct path
      case dict.get(distances, goal) {
        Error(Nil) -> NoPath
        Ok(dist) -> {
          case reconstruct_path(predecessors, start, goal, [goal]) {
            Ok(path) -> ShortestPath(Path(nodes: path, total_weight: dist))
            Error(Nil) -> NoPath
          }
        }
      }
    }
  }
}

fn relaxation_passes(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  predecessors: Dict(NodeId, NodeId),
  remaining: Int,
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> #(Dict(NodeId, e), Dict(NodeId, NodeId)) {
  case remaining <= 0 {
    True -> #(distances, predecessors)
    False -> {
      // Relax all edges
      let #(new_distances, new_predecessors) =
        list.fold(nodes, #(distances, predecessors), fn(acc, u) {
          let #(dists, preds) = acc

          case dict.get(dists, u) {
            Error(Nil) -> acc
            Ok(u_dist) -> {
              // Get all outgoing edges from u
              let neighbors = model.successors(graph, u)

              list.fold(neighbors, #(dists, preds), fn(inner_acc, edge) {
                let #(v, weight) = edge
                let #(curr_dists, curr_preds) = inner_acc
                let new_dist = add(u_dist, weight)

                case dict.get(curr_dists, v) {
                  Error(Nil) ->
                    // v not reached yet, update it
                    #(
                      dict.insert(curr_dists, v, new_dist),
                      dict.insert(curr_preds, v, u),
                    )
                  Ok(v_dist) ->
                    case compare(new_dist, v_dist) {
                      Lt ->
                        // Found shorter path
                        #(
                          dict.insert(curr_dists, v, new_dist),
                          dict.insert(curr_preds, v, u),
                        )
                      _ -> inner_acc
                    }
                }
              })
            }
          }
        })

      relaxation_passes(
        graph,
        nodes,
        new_distances,
        new_predecessors,
        remaining - 1,
        add,
        compare,
      )
    }
  }
}

fn has_negative_cycle(
  graph: Graph(n, e),
  nodes: List(NodeId),
  distances: Dict(NodeId, e),
  add: fn(e, e) -> e,
  compare: fn(e, e) -> Order,
) -> Bool {
  // Try to relax edges one more time
  // If any edge can still be relaxed, there's a negative cycle
  list.any(nodes, fn(u) {
    case dict.get(distances, u) {
      Error(Nil) -> False
      Ok(u_dist) -> {
        model.successors(graph, u)
        |> list.any(fn(edge) {
          let #(v, weight) = edge
          let new_dist = add(u_dist, weight)

          case dict.get(distances, v) {
            Error(Nil) -> False
            Ok(v_dist) ->
              case compare(new_dist, v_dist) {
                Lt -> True
                _ -> False
              }
          }
        })
      }
    }
  })
}

fn reconstruct_path(
  predecessors: Dict(NodeId, NodeId),
  start: NodeId,
  current: NodeId,
  acc: List(NodeId),
) -> Result(List(NodeId), Nil) {
  case current == start {
    True -> Ok(acc)
    False -> {
      case dict.get(predecessors, current) {
        Error(Nil) -> Error(Nil)
        Ok(pred) -> reconstruct_path(predecessors, start, pred, [pred, ..acc])
      }
    }
  }
}

// ======================== FLOYD-WARSHALL ========================

/// Computes shortest paths between all pairs of nodes using the Floyd-Warshall algorithm.
///
/// Returns a nested dictionary where `distances[i][j]` gives the shortest distance from node `i` to node `j`.
/// If no path exists between two nodes, the pair will not be present in the dictionary.
///
/// Returns `Error(Nil)` if a negative cycle is detected in the graph.
///
/// **Time Complexity:** O(V³)
/// **Space Complexity:** O(V²)
///
/// ## Parameters
///
/// - `zero`: The identity element for addition (e.g., `0` for integers, `0.0` for floats)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import gleam/int
/// import gleam/io
/// import yog
/// import yog/pathfinding
///
/// pub fn main() {
///   let graph =
///     yog.directed()
///     |> yog.add_node(1, "A")
///     |> yog.add_node(2, "B")
///     |> yog.add_node(3, "C")
///     |> yog.add_edge(from: 1, to: 2, with: 4)
///     |> yog.add_edge(from: 2, to: 3, with: 3)
///     |> yog.add_edge(from: 1, to: 3, with: 10)
///
///   case pathfinding.floyd_warshall(
///     in: graph,
///     with_zero: 0,
///     with_add: int.add,
///     with_compare: int.compare
///   ) {
///     Ok(distances) -> {
///       // Query distance from node 1 to node 3
///       let assert Ok(row) = dict.get(distances, 1)
///       let assert Ok(dist) = dict.get(row, 3)
///       // dist = 7 (via node 2: 4 + 3)
///       io.println("Distance from 1 to 3: " <> int.to_string(dist))
///     }
///     Error(Nil) -> io.println("Negative cycle detected!")
///   }
/// }
/// ```
///
/// ## Handling Negative Weights
///
/// Floyd-Warshall can handle negative edge weights and will detect negative cycles:
///
/// ```gleam
/// let graph_with_negative_cycle =
///   yog.directed()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_edge(from: 1, to: 2, with: 5)
///   |> yog.add_edge(from: 2, to: 1, with: -10)
///
/// case pathfinding.floyd_warshall(
///   in: graph_with_negative_cycle,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(_) -> io.println("No negative cycle")
///   Error(Nil) -> io.println("Negative cycle detected!")  // This will execute
/// }
/// ```
///
/// ## Use Cases
///
/// - Computing distance matrices for all node pairs
/// - Finding transitive closure of a graph
/// - Detecting negative cycles
/// - Preprocessing for queries about arbitrary node pairs
/// - Graph metrics (diameter, centrality)
///
pub fn floyd_warshall(
  in graph: Graph(n, e),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let nodes = dict.keys(graph.nodes)

  // Initialize distances: direct edges + zero distance to self
  // Using flat dictionary with composite keys for better performance
  let initial_distances =
    nodes
    |> list.fold(dict.new(), fn(distances, i) {
      nodes
      |> list.fold(distances, fn(distances, j) {
        case i == j {
          True -> {
            // Self-distance: check for self-loop edge
            case dict.get(graph.out_edges, i) {
              Ok(neighbors) ->
                case dict.get(neighbors, j) {
                  Ok(weight) -> {
                    // Self-loop exists: use min(zero, weight)
                    // If weight < 0, use it (will be detected as negative cycle)
                    // If weight > 0, use zero (staying put is shorter)
                    case compare(weight, zero) {
                      Lt -> dict.insert(distances, #(i, j), weight)
                      _ -> dict.insert(distances, #(i, j), zero)
                    }
                  }
                  Error(Nil) -> dict.insert(distances, #(i, j), zero)
                }
              Error(Nil) -> dict.insert(distances, #(i, j), zero)
            }
          }
          False -> {
            // Different nodes: check if there's a direct edge from i to j
            case dict.get(graph.out_edges, i) {
              Ok(neighbors) ->
                case dict.get(neighbors, j) {
                  Ok(weight) -> dict.insert(distances, #(i, j), weight)
                  Error(Nil) -> distances
                }
              Error(Nil) -> distances
            }
          }
        }
      })
    })

  // Floyd-Warshall: for each intermediate node k, try routing through k
  let final_distances =
    nodes
    |> list.fold(initial_distances, fn(distances, k) {
      nodes
      |> list.fold(distances, fn(distances, i) {
        nodes
        |> list.fold(distances, fn(distances, j) {
          // Try path i -> k -> j
          case dict.get(distances, #(i, k)) {
            Error(Nil) -> distances
            Ok(dist_ik) -> {
              case dict.get(distances, #(k, j)) {
                Error(Nil) -> distances
                Ok(dist_kj) -> {
                  let new_dist = add(dist_ik, dist_kj)
                  case dict.get(distances, #(i, j)) {
                    Error(Nil) ->
                      // No existing path, use new path
                      dict.insert(distances, #(i, j), new_dist)
                    Ok(current_dist) -> {
                      // Compare and keep shorter path
                      case compare(new_dist, current_dist) {
                        Lt -> dict.insert(distances, #(i, j), new_dist)
                        _ -> distances
                      }
                    }
                  }
                }
              }
            }
          }
        })
      })
    })

  // Check for negative cycles: if distance[i][i] < 0 for any i
  case detect_negative_cycle(final_distances, nodes, zero, compare) {
    True -> Error(Nil)
    False -> Ok(final_distances)
  }
}

/// Detects if there's a negative cycle by checking if any node has negative distance to itself
fn detect_negative_cycle(
  distances: Dict(#(NodeId, NodeId), e),
  nodes: List(NodeId),
  zero: e,
  compare: fn(e, e) -> Order,
) -> Bool {
  nodes
  |> list.any(fn(i) {
    case dict.get(distances, #(i, i)) {
      Ok(dist) ->
        case compare(dist, zero) {
          Lt -> True
          _ -> False
        }
      Error(Nil) -> False
    }
  })
}

// ======================== DISTANCE MATRIX ========================

/// Computes shortest distances between all pairs of points of interest.
///
/// Automatically chooses the most efficient algorithm based on the density
/// of points of interest relative to the total graph size:
/// - When POIs are dense (> 1/3 of nodes): Uses Floyd-Warshall O(V³)
/// - When POIs are sparse (≤ 1/3 of nodes): Uses multiple single-source Dijkstra O(P × (V+E) log V)
///
/// Returns only distances between the specified points of interest, not all node pairs.
///
/// **Time Complexity:** Automatically optimized based on POI density
///
/// ## Parameters
///
/// - `between`: List of points of interest (POI) nodes
/// - `zero`: The identity element for addition (e.g., `0` for integers)
/// - `add`: Function to add two weights
/// - `compare`: Function to compare two weights
///
/// ## Returns
///
/// - `Ok(distances)`: Dictionary mapping POI pairs to their shortest distances
/// - `Error(Nil)`: If a negative cycle is detected (only when using Floyd-Warshall)
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import yog
/// import yog/pathfinding
///
/// // Graph with many nodes, but only care about distances between a few POIs
/// let graph = build_large_graph()  // 1000 nodes
/// let pois = [1, 5, 10, 42]       // 4 points of interest
///
/// // Efficiently computes only POI-to-POI distances
/// case pathfinding.distance_matrix(
///   in: graph,
///   between: pois,
///   with_zero: 0,
///   with_add: int.add,
///   with_compare: int.compare
/// ) {
///   Ok(distances) -> {
///     // Get distance from POI 1 to POI 42
///     dict.get(distances, #(1, 42))
///   }
///   Error(Nil) -> panic as "Negative cycle detected"
/// }
/// ```
///
/// ## Use Cases
///
/// - AoC 2016 Day 24: Computing distances between numbered locations
/// - TSP-like problems: Finding optimal tour through specific landmarks
/// - Network analysis: Distances between server hubs
/// - Game pathfinding: Distances between quest objectives
///
/// ## Algorithm Selection
///
/// The function automatically chooses the optimal algorithm:
/// - **Floyd-Warshall** when POIs are dense: Computes all-pairs shortest paths once,
///   then filters to POIs. Efficient when you need distances for most nodes.
/// - **Multiple Dijkstra** when POIs are sparse: Runs single-source shortest paths
///   from each POI. Efficient when POIs are much fewer than total nodes.
///
pub fn distance_matrix(
  in graph: Graph(n, e),
  between points_of_interest: List(NodeId),
  with_zero zero: e,
  with_add add: fn(e, e) -> e,
  with_compare compare: fn(e, e) -> Order,
) -> Result(Dict(#(NodeId, NodeId), e), Nil) {
  let num_nodes = dict.size(graph.nodes)
  let num_pois = list.length(points_of_interest)
  let poi_set = set.from_list(points_of_interest)

  // Choose algorithm based on POI density
  // Floyd-Warshall: O(V³)
  // Multiple Dijkstra: O(P × (V + E) log V) where P = num_pois
  // Crossover heuristic: P > V/3
  case num_pois * 3 > num_nodes {
    True -> {
      // Dense POIs: Use Floyd-Warshall and filter to POI pairs
      case
        floyd_warshall(
          in: graph,
          with_zero: zero,
          with_add: add,
          with_compare: compare,
        )
      {
        Error(Nil) -> Error(Nil)
        Ok(all_distances) -> {
          // Filter to only POI-to-POI distances
          let poi_distances =
            dict.filter(all_distances, fn(key, _value) {
              let #(from_node, to_node) = key
              set.contains(poi_set, from_node) && set.contains(poi_set, to_node)
            })
          Ok(poi_distances)
        }
      }
    }
    False -> {
      // Sparse POIs: Run single_source_distances from each POI
      let result =
        list.fold(points_of_interest, dict.new(), fn(acc, source) {
          let distances =
            single_source_distances(
              in: graph,
              from: source,
              with_zero: zero,
              with_add: add,
              with_compare: compare,
            )

          // Add only POI-to-POI distances
          list.fold(points_of_interest, acc, fn(acc2, target) {
            case dict.get(distances, target) {
              Ok(dist) -> dict.insert(acc2, #(source, target), dist)
              Error(Nil) -> acc2
            }
          })
        })

      Ok(result)
    }
  }
}
