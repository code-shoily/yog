//// Algorithms for Directed Acyclic Graphs (DAGs).
////
//// This module provides efficient algorithms that leverage the acyclicity guarantee
//// of the `Dag` type. These algorithms run in linear O(V+E) time, faster than
//// their general-graph counterparts.
////
//// ## Available Algorithms
////
//// | Algorithm | Function | Use Case |
//// |-----------|----------|----------|
//// | Topological Sort | `topological_sort/1` | Task scheduling, build systems |
//// | Longest Path | `longest_path/1` | Critical path analysis, project scheduling |
//// | Shortest Path | `shortest_path/3` | Weighted DAG shortest paths |
//// | Transitive Closure | `transitive_closure/2` | Reachability queries |
//// | Transitive Reduction | `transitive_reduction/2` | Minimal graph representation |
//// | LCA | `lowest_common_ancestors/3` | Dependency analysis, merge bases |
////
//// ## Time Complexity
////
//// Most algorithms run in **O(V + E)** linear time due to DP on topologically sorted nodes:
//// - Path algorithms: O(V + E)
//// - Transitive closure/reduction: O(V × E) worst case
//// - LCA computation: O(V × (V + E))
////
//// ## Example
////
//// ```gleam
//// import yog/dag/algorithm as dag
////
//// // Find critical path in a project schedule (weighted DAG)
//// let critical_path = dag.longest_path(project_dag)
//// ```
////
//// ## References
////
//// - [Wikipedia: Directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
//// - [Topological Sorting](https://en.wikipedia.org/wiki/Topological_sorting)
//// - [Critical Path Method](https://en.wikipedia.org/wiki/Critical_path_method)

import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import yog/dag/model as dag_model
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/path.{type Path, Path}
import yog/traversal

// Re-export type from dag_model for cleaner signatures
pub type Dag(node_data, edge_data) =
  dag_model.Dag(node_data, edge_data)

/// Returns a topological ordering of all nodes in the DAG.
///
/// Unlike `traversal.topological_sort()` which returns `Result` (since general
/// graphs may contain cycles), this version is **total** - it always returns
/// a valid ordering because the `Dag` type guarantees acyclicity.
///
/// In a topological ordering, every node appears before all nodes it has edges to.
/// This is useful for scheduling tasks with dependencies, build systems, etc.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// // Given edges: 1->2, 1->3, 2->4, 3->4
/// // Valid topological sorts include: [1, 2, 3, 4] or [1, 3, 2, 4]
/// let sorted = dag.algorithms.topological_sort(my_dag)
/// // sorted == [1, 2, 3, 4]  // or another valid ordering
/// ```
pub fn topological_sort(dag: Dag(n, e)) -> List(NodeId) {
  let graph = dag_model.to_graph(dag)
  // We can safely unwrap because the graph is proven to be acyclic.
  let assert Ok(sorted) = traversal.topological_sort(graph)
  sorted
}

/// Finds the longest path (critical path) in a weighted DAG.
///
/// The longest path is the path with maximum total edge weight from any source
/// node to any sink node. This is the dual of shortest path and is useful for:
/// - Project scheduling (finding the critical path)
/// - Dependency chains with durations
/// - Determining minimum time to complete all tasks
///
/// **Time Complexity:** O(V + E) - linear via dynamic programming on the
/// topologically sorted DAG.
///
/// **Note:** For unweighted graphs, this finds the path with most edges.
/// Weights must be non-negative for meaningful results.
///
/// ## Example
///
/// ```gleam
/// // Find the critical path in a project schedule
/// let critical_path = dag.algorithms.longest_path(project_dag)
/// // critical_path == [start, task_a, task_b, end]
/// ```
pub fn longest_path(dag: Dag(n, Int)) -> List(NodeId) {
  let graph = dag_model.to_graph(dag)
  let sorted_nodes = topological_sort(dag)

  // Initialize DP tables.
  // distance: tracks the longest distance to a node.
  // predecessor: tracks the node that came before it on the longest path.
  let #(distances, predecessors) = {
    use #(dist_acc, pred_acc) as acc, node <- list.fold(sorted_nodes, #(
      dict.new(),
      dict.new(),
    ))
    let node_dist = case dict.get(dist_acc, node) {
      Ok(d) -> d
      Error(_) -> 0
    }

    case dict.get(graph.out_edges, node) {
      Ok(edges) -> {
        use #(d_acc, p_acc) as inner_acc, target, weight <- dict.fold(edges, #(
          dist_acc,
          pred_acc,
        ))
        let current_target_dist = dict.get(d_acc, target)
        let new_dist = node_dist + weight

        let should_update = case current_target_dist {
          Ok(d) -> new_dist > d
          Error(_) -> True
        }

        case should_update {
          True -> #(
            dict.insert(d_acc, target, new_dist),
            dict.insert(p_acc, target, node),
          )
          False -> inner_acc
        }
      }
      Error(_) -> acc
    }
  }

  // Find the node with the maximum distance
  let max_node_opt =
    dict.fold(distances, None, fn(acc, node, dist) {
      case acc {
        None -> Some(#(node, dist))
        Some(#(_, max_d)) if dist > max_d -> Some(#(node, dist))
        _ -> acc
      }
    })

  // Reconstruct path
  case max_node_opt {
    None -> []
    Some(#(end_node, _)) -> do_reconstruct_path(end_node, predecessors, [])
  }
}

fn do_reconstruct_path(
  current: NodeId,
  predecessors: dict.Dict(NodeId, NodeId),
  path: List(NodeId),
) -> List(NodeId) {
  let new_path = [current, ..path]

  case dict.get(predecessors, current) {
    Ok(prev) -> do_reconstruct_path(prev, predecessors, new_path)
    Error(_) -> new_path
  }
}

/// Direction for reachability counting operations.
///
/// - `Ancestors` - Count nodes that can reach the given node (predecessors)
/// - `Descendants` - Count nodes reachable from the given node (successors)
pub type Direction {
  /// Count nodes that have paths TO the target (incoming reachability).
  Ancestors
  /// Count nodes reachable FROM the target (outgoing reachability).
  Descendants
}

/// Finds the shortest path between two specific nodes in a weighted DAG.
///
/// Uses dynamic programming on the topologically sorted DAG to find the minimum
/// weight path from `from` to `to`. Unlike Dijkstra's algorithm which works on
/// general graphs in O((V+E) log V), this leverages the DAG property for linear
/// time complexity.
///
/// Returns `None` if no path exists from `from` to `to`.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// // Find shortest path in a weighted DAG
/// case dag.algorithms.shortest_path(my_dag, from: start_node, to: end_node) {
///   Some(path) -> {
///     // path.nodes contains the node sequence
///     // path.total_weight is the path length
///   }
///   None -> // No path exists
/// }
/// ```
pub fn shortest_path(
  dag: Dag(n, Int),
  from start: NodeId,
  to goal: NodeId,
) -> Option(Path(Int)) {
  let graph = dag_model.to_graph(dag)
  let sorted_nodes = topological_sort(dag)

  // Initialize distance and predecessor tables
  let #(distances, predecessors) = {
    use #(dist_acc, pred_acc) as acc, node <- list.fold(sorted_nodes, #(
      dict.new(),
      dict.new(),
    ))

    // For the start node, initialize distance to 0
    let dist_acc = case node == start {
      True -> dict.insert(dist_acc, node, 0)
      False -> dist_acc
    }

    let node_dist = case dict.get(dist_acc, node) {
      Ok(d) -> d
      Error(_) -> 0
    }

    // Relax outgoing edges (minimize for shortest path)
    case dict.get(graph.out_edges, node) {
      Ok(edges) -> {
        use #(d_acc, p_acc) as inner_acc, target, weight <- dict.fold(edges, #(
          dist_acc,
          pred_acc,
        ))
        let current_target_dist = dict.get(d_acc, target)
        let new_dist = node_dist + weight

        let should_update = case current_target_dist {
          Ok(d) -> new_dist < d
          Error(_) -> True
        }

        case should_update {
          True -> #(
            dict.insert(d_acc, target, new_dist),
            dict.insert(p_acc, target, node),
          )
          False -> inner_acc
        }
      }
      Error(_) -> acc
    }
  }

  // Check if we can reach the goal
  case dict.get(distances, goal) {
    Error(_) -> None
    Ok(total_dist) -> {
      // Reconstruct path by backtracking from goal to start
      let path = do_reconstruct_path(goal, predecessors, [])
      Some(Path(nodes: path, total_weight: total_dist))
    }
  }
}

/// Counts the number of ancestors or descendants for every node.
///
/// For each node, returns how many other nodes are reachable from it
/// (`Descendants`) or can reach it (`Ancestors`).
///
/// Uses dynamic programming on the topologically sorted DAG for efficiency.
/// Properly handles diamond patterns where a node is reachable through multiple
/// paths - each node is only counted once.
///
/// **Time Complexity:** O(V × E) in the worst case (sparse graphs),
/// optimized with set operations for common cases.
///
/// ## Example
///
/// ```gleam
/// // Given: A->B, A->C, B->D, C->D (diamond pattern)
/// // D has 3 ancestors (A, B, C)
/// // A has 3 descendants (B, C, D) - D counted once despite 2 paths
/// let descendant_counts = dag.algorithms.count_reachability(dag, Descendants)
/// // dict.get(descendant_counts, a) == Ok(3)
/// ```
pub fn count_reachability(
  dag: Dag(n, e),
  direction: Direction,
) -> dict.Dict(NodeId, Int) {
  let graph = dag_model.to_graph(dag)

  // To count descendants, process bottom-up (reverse topo)
  // To count ancestors, process top-down (topo)
  let nodes_to_process = case direction {
    Descendants -> topological_sort(dag) |> list.reverse()
    Ancestors -> topological_sort(dag)
  }

  // Pre-compute relationship lookup based on direction
  let get_related = fn(node) {
    case direction {
      Descendants -> {
        case dict.get(graph.out_edges, node) {
          Ok(targets) -> dict.keys(targets)
          Error(_) -> []
        }
      }
      Ancestors -> {
        case dict.get(graph.in_edges, node) {
          Ok(sources) -> dict.keys(sources)
          Error(_) -> []
        }
      }
    }
  }

  // DP state: Map of node -> Set of all reachable nodes
  // Using sets for O(1) membership check and automatic deduplication
  let reachability_sets: dict.Dict(NodeId, Set(NodeId)) =
    list.fold(nodes_to_process, dict.new(), fn(acc, node) {
      let related = get_related(node)

      list.fold(related, set.from_list(related), fn(set_acc, child) {
        case dict.get(acc, child) {
          Ok(child_set) -> set.union(set_acc, child_set)
          Error(_) -> set_acc
        }
      })
      |> dict.insert(acc, node, _)
    })

  dict.map_values(reachability_sets, fn(_, reachable) { set.size(reachable) })
}

/// Finds the lowest common ancestors (LCAs) of two nodes.
///
/// A common ancestor of nodes A and B is any node that has paths to both A and B.
/// The "lowest" common ancestors are those that are not ancestors of any other
/// common ancestor - they are the "closest" shared dependencies.
///
/// This is useful for:
/// - Finding merge bases in version control
/// - Identifying shared dependencies
/// - Computing dominators in control flow graphs
///
/// **Time Complexity:** O(V × (V + E))
///
/// ## Example
///
/// ```gleam
/// // Given: X->A, X->B, Y->A, Z->B
/// // LCAs of A and B are [X] - the most specific shared ancestor
/// let lcas = dag.algorithms.lowest_common_ancestors(dag, a, b)
/// // lcas == [x]
/// ```
pub fn lowest_common_ancestors(
  dag: Dag(n, e),
  node_a: NodeId,
  node_b: NodeId,
) -> List(NodeId) {
  let ancestors_counts_a = get_ancestors_set(dag, node_a)
  let ancestors_counts_b = get_ancestors_set(dag, node_b)
  let common_ancestors =
    list.filter(ancestors_counts_a, list.contains(ancestors_counts_b, _))

  list.filter(common_ancestors, fn(candidate) {
    let is_ancestor_of_another =
      list.any(common_ancestors, fn(other) {
        case candidate == other {
          True -> False
          False -> has_path(dag, candidate, other)
        }
      })
    !is_ancestor_of_another
  })
}

fn get_ancestors_set(dag: Dag(n, e), node: NodeId) -> List(NodeId) {
  dag_model.to_graph(dag).nodes
  |> dict.keys
  |> list.filter(has_path(dag, _, node))
}

/// Checks if a path exists from `start` to `target` in the DAG.
///
/// Performs a simple DFS traversal. Since the graph is a DAG, no cycle
/// detection is needed.
///
/// **Time Complexity:** O(V + E) in the worst case
fn has_path(dag: Dag(n, e), start: NodeId, target: NodeId) -> Bool {
  let graph = dag_model.to_graph(dag)

  // Simple DFS. Since it's a DAG, no cycle detection needed.
  do_has_path(graph, [start], target, set.new())
}

fn do_has_path(
  graph: Graph(n, e),
  stack: List(NodeId),
  target: NodeId,
  visited: Set(NodeId),
) -> Bool {
  case stack {
    [] -> False
    [current, ..] if current == target -> True
    [current, ..rest] -> {
      case set.contains(visited, current) {
        True -> do_has_path(graph, rest, target, visited)
        False -> {
          case dict.get(graph.out_edges, current) {
            Ok(edges) -> dict.keys(edges)
            Error(_) -> []
          }
          |> list.fold(rest, fn(acc, child) { [child, ..acc] })
          |> do_has_path(graph, _, target, set.insert(visited, current))
        }
      }
    }
  }
}
