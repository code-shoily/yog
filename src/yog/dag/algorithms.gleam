import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import yog/dag/models.{type Dag}
import yog/model.{type NodeId}
import yog/pathfinding/utils.{type Path, Path}
import yog/traversal

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
  let graph = models.to_graph(dag)
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
  let graph = models.to_graph(dag)
  let sorted_nodes = topological_sort(dag)

  // Initialize DP tables.
  // distance: tracks the longest distance to a node.
  // predecessor: tracks the node that came before it on the longest path.
  let #(distances, predecessors) =
    list.fold(sorted_nodes, #(dict.new(), dict.new()), fn(acc, node) {
      let #(dist_acc, pred_acc) = acc
      let node_dist = case dict.get(dist_acc, node) {
        Ok(d) -> d
        Error(_) -> 0
      }

      // Relax outgoing edges
      case dict.get(graph.out_edges, node) {
        Ok(edges) -> {
          dict.fold(edges, #(dist_acc, pred_acc), fn(inner_acc, target, weight) {
            let #(d_acc, p_acc) = inner_acc

            // Re-fetch current_target_dist using Option
            let current_target_dist = dict.get(d_acc, target)
            let new_dist = node_dist + weight

            let should_update = case current_target_dist {
              Ok(d) -> new_dist > d
              // If we've never reached this node, any path is the longest so far
              Error(_) -> True
            }

            case should_update {
              True -> #(
                dict.insert(d_acc, target, new_dist),
                dict.insert(p_acc, target, node),
              )
              False -> inner_acc
            }
          })
        }
        Error(_) -> acc
      }
    })

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
    Some(#(end_node, _)) -> reconstruct_path(end_node, predecessors, [])
  }
}

fn reconstruct_path(
  current: NodeId,
  predecessors: dict.Dict(NodeId, NodeId),
  path: List(NodeId),
) -> List(NodeId) {
  let new_path = [current, ..path]
  case dict.get(predecessors, current) {
    Ok(prev) -> reconstruct_path(prev, predecessors, new_path)
    Error(_) -> new_path
  }
}

/// Computes the transitive closure of a DAG.
///
/// The transitive closure adds edges between all pairs of nodes where a path
/// exists in the original graph. If `u` can reach `v` through any path, the
/// closure will have a direct edge `u -> v`.
///
/// The `merge_fn` is used to combine edge weights when multiple paths exist
/// between the same pair of nodes.
///
/// **Use cases:**
/// - Reachability queries (is A reachable from B?)
/// - Precomputing path relationships
/// - Dependency analysis (what indirectly depends on what?)
///
/// **Time Complexity:** O(V × E) in the worst case
///
/// ## Example
///
/// ```gleam
/// // Original edges: A->B (weight 2), B->C (weight 3)
/// // Closure adds: A->C (weight 5 = 2+3)
/// let closure = dag.algorithms.transitive_closure(dag, int.add)
/// ```
pub fn transitive_closure(
  dag: Dag(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Dag(n, e) {
  let graph = models.to_graph(dag)

  // We need to track the weights along with reachability. A simple dictionary approach 
  // where reachability_map is Dict(NodeId, Dict(NodeId, e)).
  // For each node u, and each child v, if v reaches w with weight W_vw, 
  // then u reaches w with weight merge_fn(W_uv, W_vw).
  // If u already reached w directly with W_uw, we merge W_uw and the new path.

  let sorted_nodes = topological_sort(dag) |> list.reverse()

  let reachability_map =
    list.fold(sorted_nodes, dict.new(), fn(acc, node) {
      case dict.get(graph.out_edges, node) {
        Ok(edges) -> {
          // edges is Dict(NodeId, e) maps direct_child -> W_node_child
          let reachable_from_node =
            dict.fold(edges, edges, fn(reachable_acc, child, w_node_child) {
              // Get the child's reachable set
              case dict.get(acc, child) {
                Ok(child_reachable) -> {
                  // Merge the child's rechable nodes into the current node's set
                  dict.fold(
                    child_reachable,
                    reachable_acc,
                    fn(inner_acc, target, w_child_target) {
                      let combined_weight =
                        merge_fn(w_node_child, w_child_target)

                      // If we already have a path to this target, merge them again
                      case dict.get(inner_acc, target) {
                        Ok(existing_weight) ->
                          dict.insert(
                            inner_acc,
                            target,
                            merge_fn(existing_weight, combined_weight),
                          )
                        Error(_) ->
                          dict.insert(inner_acc, target, combined_weight)
                      }
                    },
                  )
                }
                Error(_) -> reachable_acc
              }
            })
          dict.insert(acc, node, reachable_from_node)
        }
        Error(_) -> dict.insert(acc, node, dict.new())
      }
    })

  // Build the new graph
  let new_graph =
    dict.fold(reachability_map, graph, fn(g_acc, source_node, targets) {
      dict.fold(targets, g_acc, fn(g_inner, target_node, weight) {
        // Nodes are guaranteed to exist since we started with the original graph
        let assert Ok(g) =
          model.add_edge(
            g_inner,
            from: source_node,
            to: target_node,
            with: weight,
          )
        g
      })
    })

  let assert Ok(new_dag) = models.from_graph(new_graph)
  new_dag
}

/// Computes the transitive reduction of a DAG.
///
/// The transitive reduction removes all edges that are redundant - i.e., edges
/// `u -> v` where there exists an indirect path from `u` to `v` through other
/// nodes. The result has the minimum number of edges while preserving all
/// reachability relationships.
///
/// This is the inverse of transitive closure. It's useful for:
/// - Simplifying dependency graphs
/// - Removing implied dependencies
/// - Creating minimal representations
///
/// **Time Complexity:** O(V × E)
///
/// ## Example
///
/// ```gleam
/// // Original: A->B, B->C, A->C (A->C is implied by A->B->C)
/// // Reduction removes: A->C
/// // Result: A->B, B->C
/// let minimal = dag.algorithms.transitive_reduction(dag, int.add)
/// ```
pub fn transitive_reduction(
  dag: Dag(n, e),
  with merge_fn: fn(e, e) -> e,
) -> Dag(n, e) {
  let graph = models.to_graph(dag)
  let reach_dag = transitive_closure(dag, merge_fn)
  let reach_graph = models.to_graph(reach_dag)

  // An edge u->v is redundant if there exists some w such that u->w and w->v.
  let reduced_graph =
    dict.fold(graph.out_edges, graph, fn(g_acc, u, targets) {
      dict.fold(targets, g_acc, fn(g_inner, v, _w) {
        // Is there an indirect path from u to v?
        // u has an edge to w, and reach_graph says w reaches v.
        let is_redundant =
          dict.fold(targets, False, fn(found_redundant, w, _) {
            case found_redundant, w == v {
              True, _ -> True
              False, True -> False
              False, False -> {
                // Check if w reaches v
                case dict.get(reach_graph.out_edges, w) {
                  Ok(w_targets) -> dict.has_key(w_targets, v)
                  Error(_) -> False
                }
              }
            }
          })

        case is_redundant {
          True -> model.remove_edge(g_inner, u, v)
          False -> g_inner
        }
      })
    })

  let assert Ok(new_dag) = models.from_graph(reduced_graph)
  new_dag
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
  let graph = models.to_graph(dag)
  let sorted_nodes = topological_sort(dag)

  // Initialize distance and predecessor tables
  let #(distances, predecessors) =
    list.fold(sorted_nodes, #(dict.new(), dict.new()), fn(acc, node) {
      let #(dist_acc, pred_acc) = acc

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
          dict.fold(edges, #(dist_acc, pred_acc), fn(inner_acc, target, weight) {
            let #(d_acc, p_acc) = inner_acc
            let current_target_dist = dict.get(d_acc, target)
            let new_dist = node_dist + weight

            let should_update = case current_target_dist {
              Ok(d) -> new_dist < d
              // If we've never reached this node, any path is the shortest so far
              Error(_) -> True
            }

            case should_update {
              True -> #(
                dict.insert(d_acc, target, new_dist),
                dict.insert(p_acc, target, node),
              )
              False -> inner_acc
            }
          })
        }
        Error(_) -> acc
      }
    })

  // Check if we can reach the goal
  case dict.get(distances, goal) {
    Error(_) -> None
    Ok(total_dist) -> {
      // Reconstruct path by backtracking from goal to start
      let path = reconstruct_path_backward(goal, start, predecessors, [])
      Some(Path(nodes: path, total_weight: total_dist))
    }
  }
}

fn reconstruct_path_backward(
  current: NodeId,
  start: NodeId,
  predecessors: dict.Dict(NodeId, NodeId),
  path: List(NodeId),
) -> List(NodeId) {
  let new_path = [current, ..path]
  case current == start {
    True -> new_path
    False -> {
      case dict.get(predecessors, current) {
        Ok(prev) ->
          reconstruct_path_backward(prev, start, predecessors, new_path)
        Error(_) -> new_path
        // Should not happen if path exists
      }
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
  let graph = models.to_graph(dag)

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
      let related_set = set.from_list(related)
      let all_reachable: Set(NodeId) =
        list.fold(related, related_set, fn(set_acc: Set(NodeId), child) {
          case dict.get(acc, child) {
            Ok(child_set) -> set.union(set_acc, child_set)
            Error(_) -> set_acc
          }
        })
      dict.insert(acc, node, all_reachable)
    })

  // Convert sets to counts
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

  // Find intersection
  let common_ancestors =
    list.filter(ancestors_counts_a, fn(a) {
      list.contains(ancestors_counts_b, a)
    })

  // To find "lowest" common ancestors, we need to remove any common ancestor
  // that is an ancestor of another common ancestor.
  list.filter(common_ancestors, fn(candidate) {
    // A candidate is "lowest" if no other common ancestor is reachable from it.
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
  let graph = models.to_graph(dag)

  // Ancestors of X are all nodes Y where X is reachable from Y
  let all_nodes = dict.keys(graph.nodes)
  list.filter(all_nodes, fn(n) { has_path(dag, n, node) })
}

/// Checks if a path exists from `start` to `target` in the DAG.
///
/// Performs a simple DFS traversal. Since the graph is a DAG, no cycle
/// detection is needed.
///
/// **Time Complexity:** O(V + E) in the worst case
fn has_path(dag: Dag(n, e), start: NodeId, target: NodeId) -> Bool {
  let graph = models.to_graph(dag)

  // Simple DFS. Since it's a DAG, no cycle detection needed.
  // Using prepend for O(1) stack operations.
  do_has_path(graph, [start], target, set.new())
}

fn do_has_path(
  graph: model.Graph(n, e),
  stack: List(NodeId),
  target: NodeId,
  visited: Set(NodeId),
) -> Bool {
  case stack {
    [] -> False
    [current, ..rest] -> {
      case current == target {
        True -> True
        False -> {
          case set.contains(visited, current) {
            True -> do_has_path(graph, rest, target, visited)
            False -> {
              let new_visited = set.insert(visited, current)
              let children = case dict.get(graph.out_edges, current) {
                Ok(edges) -> dict.keys(edges)
                Error(_) -> []
              }
              // Prepend children to stack for DFS (O(1) per child)
              let new_stack =
                list.fold(children, rest, fn(acc, child) { [child, ..acc] })
              do_has_path(graph, new_stack, target, new_visited)
            }
          }
        }
      }
    }
  }
}
