//// Internal utilities shared by Louvain and Leiden algorithms.
////
//// This module contains helper functions for modularity-based community detection.
//// These are implementation details used by the Louvain and Leiden modules.
////
//// ## Internal Types
////
//// - **`CommunityState`**: Tracks assignments, weights, and totals during optimization
////
//// ## Functions
////
//// These functions are primarily for internal use:
////
//// - `shuffle/2` - Deterministic shuffle using LCG
//// - `calculate_modularity_gain/6` - Delta Q for moving a node
//// - `move_node/5` - Update state after moving a node
//// - `phase2_aggregate/2` - Aggregate communities into super-nodes
////
//// **Note**: This module is exposed for advanced users who want to implement
//// custom variants of modularity-based algorithms. Most users should use the
//// `louvain` or `leiden` modules directly.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/set.{type Set}
import yog/community.{type CommunityId}
import yog/model.{type Graph, type NodeId}

/// Internal state for modularity-based algorithms.
pub type CommunityState {
  CommunityState(
    assignments: Dict(NodeId, CommunityId),
    node_weights: Dict(NodeId, Float),
    community_totals: Dict(CommunityId, Float),
    community_internals: Dict(CommunityId, Float),
    total_weight: Float,
  )
}

/// Deterministic shuffle using Linear Congruential Generator.
pub fn shuffle(items: List(a), seed: Int) -> List(a) {
  // Use LCG parameters (same as glibc)
  let a = 1_103_515_245
  let c = 12_345
  let m = 2_147_483_648

  items
  |> list.index_map(fn(item, i) {
    // Generate deterministic random number
    let rand = { a * { seed + i } + c } % m
    #(int.to_float(rand), item)
  })
  |> list.sort(fn(a, b) { float.compare(a.0, b.0) })
  |> list.map(fn(pair) { pair.1 })
}

/// Get communities that are neighbors of a node.
pub fn get_neighbor_communities(
  graph: Graph(n, Int),
  state: CommunityState,
  node: NodeId,
) -> List(CommunityId) {
  let neighbors = model.successors(graph, node)

  list.fold(neighbors, set.new(), fn(acc, neighbor_edge) {
    let #(neighbor_id, _) = neighbor_edge
    let comm =
      dict.get(state.assignments, neighbor_id) |> result.unwrap(neighbor_id)
    set.insert(acc, comm)
  })
  |> set.to_list
}

/// Calculate modularity gain from moving a node between communities.
pub fn calculate_modularity_gain(
  graph: Graph(n, Int),
  node: NodeId,
  current_comm: CommunityId,
  target_comm: CommunityId,
  node_weight: Float,
  state: CommunityState,
) -> Float {
  case current_comm == target_comm {
    True -> 0.0
    False -> {
      let ki = node_weight
      let m = state.total_weight
      let two_m_sq = 2.0 *. m *. m

      case m == 0.0 {
        True -> 0.0
        False -> {
          // 1. Gain of adding to target community
          let ki_in_target = calculate_ki_in(graph, state, node, target_comm)
          let sigma_tot_target =
            dict.get(state.community_totals, target_comm) |> result.unwrap(0.0)

          let delta_q_add =
            { ki_in_target /. m } -. { sigma_tot_target *. ki /. two_m_sq }

          // 2. Gain of leaving current community
          let ki_in_current = calculate_ki_in(graph, state, node, current_comm)
          let sigma_tot_current =
            dict.get(state.community_totals, current_comm) |> result.unwrap(0.0)
          let sigma_tot_c_minus_i = sigma_tot_current -. ki
          let delta_q_remove =
            { ki_in_current /. m } -. { sigma_tot_c_minus_i *. ki /. two_m_sq }

          delta_q_add -. delta_q_remove
        }
      }
    }
  }
}

/// Calculate sum of edge weights from node to target community.
/// Calculate sum of edge weights from node to target community.
pub fn calculate_ki_in(
  graph: Graph(n, Int),
  state: CommunityState,
  node: NodeId,
  target_comm: CommunityId,
) -> Float {
  let successors = model.successors(graph, node)
  list.fold(successors, 0.0, fn(acc, edge) {
    let #(neighbor, weight) = edge
    let neighbor_comm =
      dict.get(state.assignments, neighbor) |> result.unwrap(neighbor)
    case neighbor_comm == target_comm {
      True -> acc +. int.to_float(weight)
      False -> acc
    }
  })
}

/// Move a node from one community to another.
pub fn move_node(
  state: CommunityState,
  node: NodeId,
  from_comm: CommunityId,
  to_comm: CommunityId,
  node_weight: Float,
) -> CommunityState {
  let new_assignments = dict.insert(state.assignments, node, to_comm)

  let new_totals =
    state.community_totals
    |> dict.upsert(from_comm, fn(v) { option.unwrap(v, 0.0) -. node_weight })
    |> dict.upsert(to_comm, fn(v) { option.unwrap(v, 0.0) +. node_weight })

  CommunityState(
    ..state,
    assignments: new_assignments,
    community_totals: new_totals,
  )
}

/// Calculate total edge weight in graph.
/// Calculate total edge weight in graph.
pub fn calculate_total_weight(graph: Graph(n, Int)) -> Float {
  let nodes = model.all_nodes(graph)
  list.fold(nodes, 0.0, fn(acc, node) {
    let weight_sum =
      model.successors(graph, node)
      |> list.fold(0, fn(sum, edge) { sum + edge.1 })
    acc +. int.to_float(weight_sum)
  })
  /. 2.0
}

/// Calculate degree (weight) for each node.
/// Calculate degree (weight) for each node.
pub fn calculate_node_weights(graph: Graph(n, Int)) -> Dict(NodeId, Float) {
  let nodes = model.all_nodes(graph)
  list.map(nodes, fn(node) {
    let weight_sum =
      model.successors(graph, node)
      |> list.fold(0, fn(sum, edge) { sum + edge.1 })
    #(node, int.to_float(weight_sum))
  })
  |> dict.from_list
}

/// Calculate total weight incident to each community.
pub fn calculate_community_totals(
  assignments: Dict(NodeId, CommunityId),
  node_weights: Dict(NodeId, Float),
) -> Dict(CommunityId, Float) {
  dict.fold(assignments, dict.new(), fn(acc, node, comm) {
    let weight = dict.get(node_weights, node) |> result.unwrap(0.0)
    dict.upsert(acc, comm, fn(v) { option.unwrap(v, 0.0) +. weight })
  })
}

/// Count unique communities in assignments.
pub fn count_unique_communities(assignments: Dict(NodeId, CommunityId)) -> Int {
  assignments
  |> dict.values
  |> set.from_list
  |> set.size
}

/// Convert assignments to community -> nodes mapping.
pub fn get_community_nodes(
  assignments: Dict(NodeId, CommunityId),
) -> Dict(CommunityId, Set(NodeId)) {
  dict.fold(assignments, dict.new(), fn(acc, node, comm) {
    dict.upsert(acc, comm, fn(maybe_set) {
      case maybe_set {
        option.None -> set.from_list([node])
        option.Some(s) -> set.insert(s, node)
      }
    })
  })
}

/// Aggregate graph by merging communities into super-nodes.
pub fn phase2_aggregate(
  graph: Graph(n, Int),
  assignments: Dict(NodeId, CommunityId),
) -> Graph(Nil, Int) {
  let communities = get_community_nodes(assignments)
  let new_graph = model.new(model.Undirected)

  // Add super-nodes
  let new_graph_with_nodes =
    dict.fold(communities, new_graph, fn(g, comm_id, _nodes) {
      model.add_node(g, comm_id, Nil)
    })

  // Aggregate edges
  aggregate_edges(graph, new_graph_with_nodes, assignments)
}

fn aggregate_edges(
  original_graph: Graph(n, Int),
  new_graph: Graph(Nil, Int),
  assignments: Dict(NodeId, CommunityId),
) -> Graph(Nil, Int) {
  let nodes = model.all_nodes(original_graph)

  list.fold(nodes, new_graph, fn(g, u) {
    let comm_u = dict.get(assignments, u) |> result.unwrap(u)
    let successors = model.successors(original_graph, u)

    list.fold(successors, g, fn(g2, edge) {
      let #(v, weight) = edge
      let comm_v = dict.get(assignments, v) |> result.unwrap(v)

      // For undirected graphs, only process each edge once (u < v)
      // For self-loops (comm_u == comm_v), always add
      case comm_u == comm_v || comm_u < comm_v {
        True -> add_or_update_edge(g2, comm_u, comm_v, weight)
        False -> g2
      }
    })
  })
}

fn add_or_update_edge(
  graph: Graph(Nil, Int),
  u: NodeId,
  v: NodeId,
  weight: Int,
) -> Graph(Nil, Int) {
  let current =
    model.successors(graph, u)
    |> list.find(fn(edge) { edge.0 == v })

  case current {
    Ok(#(_, existing_weight)) -> {
      let new_weight = existing_weight + weight
      model.add_edge_ensure(graph, u, v, new_weight, default: Nil)
    }
    Error(Nil) -> {
      model.add_edge_ensure(graph, u, v, weight, default: Nil)
    }
  }
}

/// Rebuild state for aggregated graph.
pub fn rebuild_state(aggregated_graph: Graph(Nil, Int)) -> CommunityState {
  let nodes = model.all_nodes(aggregated_graph)
  let total_weight = calculate_total_weight(aggregated_graph)

  let new_assignments =
    list.index_map(nodes, fn(i, node) { #(node, i) })
    |> dict.from_list

  let node_weights = calculate_node_weights(aggregated_graph)

  CommunityState(
    assignments: new_assignments,
    node_weights: node_weights,
    community_totals: calculate_community_totals(new_assignments, node_weights),
    community_internals: dict.new(),
    total_weight: total_weight,
  )
}
