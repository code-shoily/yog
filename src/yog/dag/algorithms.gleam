import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import yog/dag/models.{type Dag}
import yog/model.{type NodeId}
import yog/traversal

/// topological_sort(Dag(n, e)) -> List(NodeId)
/// Unlike the general version, this version is total (cannot return an Error)
/// because the DAG type guarantees acyclicity.
pub fn topological_sort(dag: Dag(n, e)) -> List(NodeId) {
  let graph = models.to_graph(dag)
  // We can safely unwrap because the graph is proven to be acyclic.
  let assert Ok(sorted) = traversal.topological_sort(graph)
  sorted
}

/// longest_path(Dag(n, Int)) -> List(NodeId)
/// Goal: Find the Critical Path in O(V+E).
/// Returns the list of node IDs forming the longest path in the DAG.
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

/// transitive_closure(Dag(n, e), fn(e, e) -> e) -> Dag(n, e)
/// Goal: Create a "Reachability Map" where an edge (u, v) exists if v is reachable from u.
/// Returns a new Dag representing the transitive closure. The `merge_fn` combines edge weights
/// when an indirect path dominates.
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
        model.add_edge(g_inner, source_node, target_node, weight)
      })
    })

  let assert Ok(new_dag) = models.from_graph(new_graph)
  new_dag
}

/// transitive_reduction(Dag(n, e), fn(e, e) -> e) -> Dag(n, e)
/// Goal: Remove redundant edges while preserving reachability.
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

pub type Direction {
  Ancestors
  Descendants
}

/// count_reachability(Dag(n, e), Direction) -> Dict(NodeId, Int)
/// Goal: Efficiently count total descendants/ancestors for every node.
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

  // Pre-compute reversing relationships for Ancestors
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
  // We use sets to avoid double counting from diamond patterns
  let reachability_sets =
    list.fold(nodes_to_process, dict.new(), fn(acc, node) {
      let related = get_related(node)
      let all_reachable =
        list.fold(related, related, fn(set_acc, child) {
          case dict.get(acc, child) {
            Ok(child_set) -> list.append(set_acc, child_set) |> list.unique()
            Error(_) -> set_acc
          }
        })
      dict.insert(acc, node, all_reachable)
    })

  // Convert sets to counts
  dict.map_values(reachability_sets, fn(_, reachable) { list.length(reachable) })
}

/// lowest_common_ancestors(Dag(n, e), NodeId, NodeId) -> List(NodeId)
/// Goal: Find the immediate common dependencies of two nodes.
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

/// Helper: does a path exist from `start` to `target`?
fn has_path(dag: Dag(n, e), start: NodeId, target: NodeId) -> Bool {
  let graph = models.to_graph(dag)

  // Simple DFS or BFS. Since it's a DAG, DFS is fine and fast.
  do_has_path(graph, [start], target, dict.new())
}

fn do_has_path(
  graph: model.Graph(n, e),
  stack: List(NodeId),
  target: NodeId,
  visited: dict.Dict(NodeId, Bool),
) -> Bool {
  case stack {
    [] -> False
    [current, ..rest] -> {
      case current == target {
        True -> True
        False -> {
          case dict.has_key(visited, current) {
            True -> do_has_path(graph, rest, target, visited)
            False -> {
              let new_visited = dict.insert(visited, current, True)
              let children = case dict.get(graph.out_edges, current) {
                Ok(edges) -> dict.keys(edges)
                Error(_) -> []
              }
              do_has_path(
                graph,
                list.append(children, rest),
                target,
                new_visited,
              )
            }
          }
        }
      }
    }
  }
}
