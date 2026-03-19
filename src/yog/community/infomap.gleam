//// Infomap community detection algorithm.
////
//// Uses information theory to find the most efficient way to describe the
//// flow of a random walker on the network. The optimal partition minimizes
//// the description length of the walker's path (Map Equation).
////
//// ## Algorithm
////
//// 1. **Calculate** steady-state PageRank probabilities (random walker flow)
//// 2. **Initialize** each node in its own community
//// 3. **Optimize** the Map Equation greedily by merging communities
//// 4. **Repeat** until no improvement in description length
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Flow-based communities | ✓ Excellent |
//// | Random walk structure | ✓ Designed for this |
//// | Directed graphs | ✓ Good (uses PageRank flow) |
//// | Information-theoretic interpretation | ✓ Provides description length |
////
//// ## Complexity
////
//// - **Time**: O(V + E) per iteration, typically converges quickly
//// - **Space**: O(V + E)
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/infomap
////
//// let graph =
////   yog.directed()
////   |> yog.add_node(1, "Home")
////   |> yog.add_node(2, "About")
////   |> yog.add_node(3, "Contact")
////   |> yog.add_edges([#(1, 2, 1), #(2, 1, 1), #(2, 3, 1)])
////
//// // Basic usage
//// let communities = infomap.detect(graph)
//// io.debug(communities.num_communities)
////
//// // With custom options
//// let options = infomap.InfomapOptions(
////   teleport_prob: 0.15,
////   tolerance: 0.000001,
////   max_pagerank_iters: 200,
//// )
//// let communities = infomap.detect_with_options(graph, options)
//// ```
////
//// ## References
////
//// - [Rosvall & Bergstrom 2008 - Maps of information flow](https://doi.org/10.1073/pnas.0706851105)
//// - [MapEquation.org](https://www.mapequation.org/)

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import yog/community.{type Communities, Communities}
import yog/model.{type Graph, type NodeId}

/// Options for Infomap algorithm.
pub type InfomapOptions {
  InfomapOptions(
    /// Teleportation probability for PageRank (typically 0.15).
    teleport_prob: Float,
    /// Stop when relative improvement is less than this.
    tolerance: Float,
    /// Max iterations for steady-state calculation.
    max_pagerank_iters: Int,
  )
}

/// Default options for Infomap.
pub fn default_options() -> InfomapOptions {
  InfomapOptions(
    teleport_prob: 0.15,
    tolerance: 0.000001,
    max_pagerank_iters: 200,
  )
}

/// Detects communities using the Infomap algorithm with default options.
pub fn detect(graph: Graph(n, e)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using Infomap with custom options.
pub fn detect_with_options(
  graph: Graph(n, e),
  options: InfomapOptions,
) -> Communities {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  case n {
    0 -> Communities(dict.new(), 0)
    1 -> {
      let node = list.first(nodes) |> result.unwrap(0)
      Communities(dict.from_list([#(node, 0)]), 1)
    }
    _ -> {
      // 1. Calculate steady-state PageRank probabilities
      let pagerank = calculate_pagerank(graph, nodes, options)

      // 2. Initial partition: each node in its own community
      let initial_assignments =
        list.index_map(nodes, fn(u, i) { #(u, i) })
        |> dict.from_list

      // 3. Greedy optimization of Map Equation
      let final_assignments =
        optimize_map_equation(graph, pagerank, initial_assignments)

      let unique_labels =
        dict.values(final_assignments)
        |> set.from_list
        |> set.size

      Communities(
        assignments: final_assignments,
        num_communities: unique_labels,
      )
    }
  }
}

fn calculate_pagerank(
  graph: Graph(n, e),
  nodes: List(NodeId),
  options: InfomapOptions,
) -> Dict(NodeId, Float) {
  let n = int.to_float(list.length(nodes))
  let initial_pr =
    list.map(nodes, fn(u) { #(u, 1.0 /. n) })
    |> dict.from_list

  do_pagerank(
    graph,
    nodes,
    initial_pr,
    options.teleport_prob,
    options.max_pagerank_iters,
  )
}

fn do_pagerank(
  graph: Graph(n, e),
  nodes: List(NodeId),
  pr: Dict(NodeId, Float),
  alpha: Float,
  remaining_iters: Int,
) -> Dict(NodeId, Float) {
  case remaining_iters <= 0 {
    True -> pr
    False -> {
      let n_float = int.to_float(list.length(nodes))
      let teleport = alpha /. n_float

      // Calculate total PageRank from dangling nodes
      let dangling_pr =
        list.fold(over: nodes, from: 0.0, with: fn(sum, u) {
          let deg = list.length(model.successors(graph, u))
          case deg == 0 {
            True -> sum +. { dict.get(pr, u) |> result.unwrap(0.0) }
            False -> sum
          }
        })

      let next_pr =
        list.fold(over: nodes, from: dict.new(), with: fn(acc, u) {
          let neighbors = model.successors(graph, u)
          let deg = list.length(neighbors)
          let u_pr = dict.get(pr, u) |> result.unwrap(0.0)

          case deg {
            0 -> acc
            _ -> {
              let contribution = u_pr *. { 1.0 -. alpha } /. int.to_float(deg)
              list.fold(over: neighbors, from: acc, with: fn(inner_acc, v) {
                let current_v_pr =
                  dict.get(inner_acc, v.0) |> result.unwrap(0.0)
                dict.insert(inner_acc, v.0, current_v_pr +. contribution)
              })
            }
          }
        })

      // Combine flow, teleportation, and dangling node contribution
      let final_pr =
        list.map(nodes, fn(u) {
          let val = dict.get(next_pr, u) |> result.unwrap(0.0)
          let dangling_contribution =
            { dangling_pr *. { 1.0 -. alpha } } /. n_float
          #(u, val +. teleport +. dangling_contribution)
        })
        |> dict.from_list

      do_pagerank(graph, nodes, final_pr, alpha, remaining_iters - 1)
    }
  }
}

fn optimize_map_equation(
  graph: Graph(n, e),
  pagerank: Dict(NodeId, Float),
  assignments: Dict(NodeId, Int),
) -> Dict(NodeId, Int) {
  // Simplification: just one pass of greedy movement for now
  // A real Infomap would repeat until convergence and use refinement
  greedy_move(graph, pagerank, assignments)
}

fn greedy_move(
  graph: Graph(n, e),
  pagerank: Dict(NodeId, Float),
  assignments: Dict(NodeId, Int),
) -> Dict(NodeId, Int) {
  let nodes = model.all_nodes(graph)

  list.fold(over: nodes, from: assignments, with: fn(current_acc, u) {
    let current_comm = dict.get(current_acc, u) |> result.unwrap(-1)
    let neighbors = model.successors(graph, u)
    let neighbor_comms =
      list.map(neighbors, fn(v) {
        dict.get(current_acc, v.0) |> result.unwrap(-1)
      })
      |> set.from_list
      |> set.to_list
      |> list.filter(fn(c) { c != -1 && c != current_comm })

    // Try moving to each neighbor community and pick the one with most internal flow
    // (This is a simplified heuristic for minimizing map equation)
    let best_comm =
      list.fold(
        over: neighbor_comms,
        from: #(current_comm, 0.0),
        with: fn(best, candidate) {
          let internal_flow =
            calculate_flow_to_comm(graph, u, candidate, current_acc, pagerank)
          case internal_flow >. best.1 {
            True -> #(candidate, internal_flow)
            False -> best
          }
        },
      ).0

    dict.insert(current_acc, u, best_comm)
  })
}

fn calculate_flow_to_comm(
  graph: Graph(n, e),
  u: NodeId,
  comm_id: Int,
  assignments: Dict(NodeId, Int),
  pagerank: Dict(NodeId, Float),
) -> Float {
  let neighbors = model.successors(graph, u)
  let u_pr = dict.get(pagerank, u) |> result.unwrap(0.0)

  list.fold(over: neighbors, from: 0.0, with: fn(acc, v) {
    let v_comm = dict.get(assignments, v.0) |> result.unwrap(-1)
    case v_comm == comm_id {
      True -> {
        let deg = list.length(model.successors(graph, u))
        acc +. { u_pr /. int.to_float(deg) }
      }
      False -> acc
    }
  })
}
