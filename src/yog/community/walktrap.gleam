//// Walktrap community detection algorithm.
////
//// Identifies communities using random walks to define distances between nodes.
//// Nodes in the same community tend to have similar transition probabilities
//// to other nodes (they "see" the network similarly).
////
//// ## Algorithm
////
//// 1. **Compute** transition probabilities P^t (t-step random walk)
//// 2. **Define** distance between nodes based on transition probability differences
//// 3. **Merge** closest communities iteratively (hierarchical agglomerative)
//// 4. **Return** hierarchy of community partitions
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Hierarchical structure | ✓ Good |
//// | Local structure matters | ✓ Captures neighborhood via walks |
//// | Large graphs | Consider faster alternatives |
//// | Quality priority | Good balance of speed and quality |
////
//// ## Complexity
////
//// - **Time**: O(V² × log V) for hierarchical clustering
//// - **Space**: O(V²) for distance matrix
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/walktrap
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])
////
//// // Basic usage (walk_length=4 is default)
//// let communities = walktrap.detect(graph)
////
//// // With options
//// let options = walktrap.WalktrapOptions(
////   walk_length: 4,
////   target_communities: Some(2),
//// )
//// let communities = walktrap.detect_with_options(graph, options)
////
//// // Full hierarchical detection
//// let dendrogram = walktrap.detect_hierarchical(graph, walk_length: 4)
//// ```
////
//// ## References
////
//// - [Pons & Latapy 2006 - Computing communities with random walks](https://doi.org/10.1080/15427951.2007.10129237)
//// - [Wikipedia: Walktrap Algorithm](https://en.wikipedia.org/wiki/Walktrap_community)

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import yog/community.{type Communities, type Dendrogram, Communities, Dendrogram}
import yog/model.{type Graph, type NodeId}

/// Options for Walktrap algorithm.
pub type WalktrapOptions {
  WalktrapOptions(
    /// Number of steps in the random walk (typically 3-5).
    walk_length: Int,
    /// Target number of communities. If None, returns the full dendrogram.
    target_communities: Option(Int),
  )
}

/// Default options for Walktrap.
pub fn default_options() -> WalktrapOptions {
  WalktrapOptions(walk_length: 4, target_communities: None)
}

/// Detects communities using the Walktrap algorithm with default options.
pub fn detect(graph: Graph(n, e)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using Walktrap with custom options.
pub fn detect_with_options(
  graph: Graph(n, e),
  options: WalktrapOptions,
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
      let dendrogram = detect_hierarchical(graph, options.walk_length)

      case options.target_communities {
        None ->
          list.last(dendrogram.levels)
          |> result.unwrap(Communities(dict.new(), 0))
        Some(target) -> {
          list.find(dendrogram.levels, fn(c) { c.num_communities <= target })
          |> result.or(list.last(dendrogram.levels))
          |> result.unwrap(Communities(dict.new(), 0))
        }
      }
    }
  }
}

/// Full hierarchical Walktrap detection.
pub fn detect_hierarchical(graph: Graph(n, e), walk_length: Int) -> Dendrogram {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)

  // 1. Compute transition probabilities P^t
  let p_t = compute_pt(graph, nodes, walk_length)

  // 2. Compute degrees for normalization
  let degrees =
    list.map(nodes, fn(u) {
      #(u, int.to_float(list.length(model.successors(graph, u))))
    })
    |> dict.from_list

  // 3. Initial communities: each node in its own community
  let initial_assignments =
    list.map(nodes, fn(u) { #(u, u) })
    |> dict.from_list

  let initial_communities = Communities(initial_assignments, n)

  // 4. Hierarchical merging (simplified version for basic implementation)
  // For a full implementation, we'd use a priority queue and ward's method.
  // Here we'll do a greedy merge based on distance.
  do_walktrap_merge([initial_communities], p_t, degrees, n)
}

fn compute_pt(
  graph: Graph(n, e),
  nodes: List(NodeId),
  t: Int,
) -> Dict(NodeId, Dict(NodeId, Float)) {
  // Initial P^1
  let p1 =
    list.map(nodes, fn(u) {
      let neighbors = model.successors(graph, u)
      let d = int.to_float(list.length(neighbors))
      let row =
        list.map(neighbors, fn(v) { #(v.0, 1.0 /. d) })
        |> dict.from_list
      #(u, row)
    })
    |> dict.from_list

  // Compute P^t via repeated multiplication
  int.range(from: 1, to: t, with: p1, run: fn(p_acc, _) {
    multiply_matrices(p_acc, p1, nodes)
  })
}

fn multiply_matrices(
  a: Dict(NodeId, Dict(NodeId, Float)),
  b: Dict(NodeId, Dict(NodeId, Float)),
  nodes: List(NodeId),
) -> Dict(NodeId, Dict(NodeId, Float)) {
  list.map(nodes, fn(i) {
    let row_a = dict.get(a, i) |> result.unwrap(dict.new())
    let new_row =
      list.map(nodes, fn(j) {
        let val =
          dict.fold(over: row_a, from: 0.0, with: fn(sum, k, aik) {
            let row_b_k = dict.get(b, k) |> result.unwrap(dict.new())
            let bkj = dict.get(row_b_k, j) |> result.unwrap(0.0)
            sum +. aik *. bkj
          })
        #(j, val)
      })
      |> list.filter(fn(p) { p.1 >. 0.0 })
      |> dict.from_list
    #(i, new_row)
  })
  |> dict.from_list
}

fn do_walktrap_merge(
  levels: List(Communities),
  p_t: Dict(NodeId, Dict(NodeId, Float)),
  degrees: Dict(NodeId, Float),
  n: Int,
) -> Dendrogram {
  let current_level =
    list.first(levels) |> result.unwrap(Communities(dict.new(), 0))

  case current_level.num_communities <= 1 {
    True -> Dendrogram(levels: list.reverse(levels), merge_order: [])
    False -> {
      // Find best pair to merge
      // For Walktrap, we merge communities C, D that minimize:
      // Delta(C, D) = 1/n * sum_k (1/d_k * (P_Ck^t - P_Dk^t)^2)
      // where P_Ck^t = sum_{i in C} P_ik^t / |C|

      let best_pair = find_best_merge(current_level, p_t, degrees, n)
      case best_pair {
        None -> Dendrogram(levels: list.reverse(levels), merge_order: [])
        Some(#(c1, c2)) -> {
          let next_level = community.merge_communities(current_level, c1, c2)
          do_walktrap_merge([next_level, ..levels], p_t, degrees, n)
        }
      }
    }
  }
}

fn find_best_merge(
  communities: Communities,
  p_t: Dict(NodeId, Dict(NodeId, Float)),
  degrees: Dict(NodeId, Float),
  n: Int,
) -> Option(#(Int, Int)) {
  let community_map = community.communities_to_dict(communities)
  let ids = dict.keys(community_map)

  // O(C^2 * N) - slow but correct for starters
  list.fold(
    over: ids,
    from: #(None, 1_000_000_000_000_000.0),
    with: fn(best_acc, c1) {
      list.fold(over: ids, from: best_acc, with: fn(inner_acc, c2) {
        case c1 < c2 {
          False -> inner_acc
          True -> {
            let dist =
              calculate_community_distance(
                c1,
                c2,
                community_map,
                p_t,
                degrees,
                n,
              )
            case dist <. inner_acc.1 {
              True -> #(Some(#(c1, c2)), dist)
              False -> inner_acc
            }
          }
        }
      })
    },
  ).0
}

fn calculate_community_distance(
  c1: Int,
  c2: Int,
  community_map: Dict(Int, set.Set(NodeId)),
  p_t: Dict(NodeId, Dict(NodeId, Float)),
  degrees: Dict(NodeId, Float),
  _n: Int,
) -> Float {
  let nodes1 =
    dict.get(community_map, c1)
    |> result.unwrap(set.new())
    |> set.to_list
  let nodes2 =
    dict.get(community_map, c2)
    |> result.unwrap(set.new())
    |> set.to_list

  let p_c1 = compute_community_pt(nodes1, p_t)
  let p_c2 = compute_community_pt(nodes2, p_t)

  let node_ids = dict.keys(p_t)
  list.fold(over: node_ids, from: 0.0, with: fn(sum, k) {
    let d_k = dict.get(degrees, k) |> result.unwrap(1.0)
    let pk1 = dict.get(p_c1, k) |> result.unwrap(0.0)
    let pk2 = dict.get(p_c2, k) |> result.unwrap(0.0)
    let diff = pk1 -. pk2
    sum +. { diff *. diff /. d_k }
  })
}

fn compute_community_pt(
  nodes: List(NodeId),
  p_t: Dict(NodeId, Dict(NodeId, Float)),
) -> Dict(NodeId, Float) {
  let count = int.to_float(list.length(nodes))
  list.fold(over: nodes, from: dict.new(), with: fn(acc, u) {
    let row = dict.get(p_t, u) |> result.unwrap(dict.new())
    dict.fold(over: row, from: acc, with: fn(inner_acc, k, prob) {
      let current = dict.get(inner_acc, k) |> result.unwrap(0.0)
      dict.insert(inner_acc, k, current +. { prob /. count })
    })
  })
}
