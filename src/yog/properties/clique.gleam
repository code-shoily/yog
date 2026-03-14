//// [Clique](https://en.wikipedia.org/wiki/Clique_(graph_theory)) finding algorithms using the 
//// [Bron-Kerbosch algorithm](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm).
////
//// A clique is a subset of nodes where every pair of nodes is connected by an edge.
//// Cliques represent tightly-knit communities or fully-connected subgraphs.
////
//// ## Algorithms
////
//// | Problem | Algorithm | Function | Complexity |
//// |---------|-----------|----------|------------|
//// | Maximum clique | [Bron-Kerbosch with pivot](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm#With_pivoting) | `max_clique/1` | O(3^(n/3)) |
//// | All maximal cliques | [Bron-Kerbosch](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm) | `all_maximal_cliques/1` | O(3^(n/3)) |
//// | k-Cliques | Bron-Kerbosch with pruning | `k_cliques/2` | O(3^(n/3)) |
////
//// ## Key Concepts
////
//// - **Clique**: Complete subgraph - every pair of vertices is adjacent
//// - **Maximal Clique**: Cannot be extended by adding another vertex
//// - **Maximum Clique**: Largest clique in the graph (NP-hard to find)
//// - **Clique Number**: Size of the maximum clique, denoted ω(G)
//// - **Clique Cover**: Partition of vertices into cliques
////
//// ## The Bron-Kerbosch Algorithm
////
//// A backtracking algorithm that recursively explores potential cliques using
//// three sets:
//// - **R**: Current clique being built
//// - **P**: Candidates that can extend R (connected to all in R)
//// - **X**: Excluded vertices (already processed)
////
//// **Pivoting optimization**: Choose a pivot vertex to reduce recursive calls,
//// achieving the worst-case optimal O(3^(n/3)) bound.
////
//// ## Complexity Notes
////
//// Finding the maximum clique is NP-hard. The O(3^(n/3)) bound is tight - there
//// exist graphs with exactly 3^(n/3) maximal cliques (Moon-Moser graphs).
////
//// ## Related Problems
////
//// - **Independent Set**: Clique in the complement graph
//// - **Vertex Cover**: Related via complement to independent set
//// - **Graph Coloring**: Lower bounded by clique number
////
//// ## Use Cases
////
//// - **Social network analysis**: Finding tightly-knit friend groups
//// - **Bioinformatics**: Protein interaction clusters
//// - **Finance**: Detecting collusion rings in trading
//// - **Recommendation**: Finding groups with similar preferences
//// - **Compiler optimization**: Register allocation (interference graphs)
////
//// ## References
////
//// - [Wikipedia: Clique](https://en.wikipedia.org/wiki/Clique_(graph_theory))
//// - [Wikipedia: Bron-Kerbosch Algorithm](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm)
//// - [Moon-Moser Theorem (Clique Enumeration)](https://en.wikipedia.org/wiki/Moon%E2%80%93Moser_theorem)
//// - [CP-Algorithms: Finding Cliques](https://cp-algorithms.com/graph/search_for_connected_components.html)

import gleam/dict.{type Dict}
import gleam/list
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}

/// Finds the maximum clique in an undirected graph.
///
/// Returns the largest subset of nodes where every pair is connected.
///
/// **Time Complexity:** O(3^(n/3)) worst case
///
/// ## Example
///
/// ```gleam
/// clique.max_clique(graph)
/// // => set.from_list([1, 2, 3, 4])
/// ```
pub fn max_clique(graph: Graph(n, e)) -> Set(NodeId) {
  let adj = build_adjacency(graph)
  let all_nodes = model.all_nodes(graph)
  let p = set.from_list(all_nodes)
  let r = set.new()
  let x = set.new()

  bron_kerbosch_pivot(adj, r, p, x)
}

/// Finds all maximal cliques in an undirected graph.
///
/// A maximal clique is a clique that cannot be extended by adding another node.
///
/// **Time Complexity:** O(3^(n/3)) worst case
///
/// ## Example
///
/// ```gleam
/// clique.all_maximal_cliques(graph)
/// // => [set.from_list([1, 2]), set.from_list([2, 3])]
/// ```
pub fn all_maximal_cliques(graph: Graph(n, e)) -> List(Set(NodeId)) {
  let adj = build_adjacency(graph)
  let all_nodes = model.all_nodes(graph)
  let p = set.from_list(all_nodes)
  let r = set.new()
  let x = set.new()

  bron_kerbosch_all(adj, r, p, x, [])
}

/// Finds all cliques of exactly size k in an undirected graph.
///
/// Uses a modified Bron-Kerbosch algorithm with early pruning.
///
/// **Time Complexity:** O(3^(n/3)) worst case
///
/// ## Example
///
/// ```gleam
/// clique.k_cliques(graph, 3)
/// // => [set.from_list([1, 2, 3])]
/// ```
pub fn k_cliques(graph: Graph(n, e), k: Int) -> List(Set(NodeId)) {
  case k <= 0 {
    True -> []
    False -> {
      let adj = build_adjacency(graph)
      let all_nodes = model.all_nodes(graph)
      let p = set.from_list(all_nodes)
      let r = set.new()

      bron_kerbosch_k(adj, r, p, k, [])
    }
  }
}

// Precompute adjacency sets for O(1) neighbor lookups during recursion.
// Built once per public entry point, avoids repeated list->set conversions.
fn build_adjacency(graph: Graph(n, e)) -> Dict(NodeId, Set(NodeId)) {
  model.all_nodes(graph)
  |> list.fold(dict.new(), fn(acc, node_id) {
    let neighbor_set =
      model.neighbors(graph, node_id)
      |> list.map(fn(neighbor) { neighbor.0 })
      |> set.from_list
    dict.insert(acc, node_id, neighbor_set)
  })
}

// Look up precomputed neighbor set; returns empty set for unknown nodes.
fn get_neighbors(adj: Dict(NodeId, Set(NodeId)), id: NodeId) -> Set(NodeId) {
  case dict.get(adj, id) {
    Ok(s) -> s
    Error(_) -> set.new()
  }
}

// Choose pivot from P ∪ X that maximizes |P ∩ N(u)|.
// This greedy strategy aggressively prunes the candidate set,
// skipping vertices that are neighbors of the pivot (they will be
// explored in a later recursive branch anyway).
fn choose_pivot(
  adj: Dict(NodeId, Set(NodeId)),
  p: Set(NodeId),
  x: Set(NodeId),
) -> NodeId {
  let union = set.union(p, x)
  let assert Ok(#(best_node, _)) =
    set.fold(union, Error(Nil), fn(best, u) {
      let neighbors_u = get_neighbors(adj, u)
      let overlap = set.size(set.intersection(p, neighbors_u))
      case best {
        Error(_) -> Ok(#(u, overlap))
        Ok(#(_, best_overlap)) ->
          case overlap > best_overlap {
            True -> Ok(#(u, overlap))
            False -> best
          }
      }
    })
  best_node
}

// Bron-Kerbosch algorithm with pivoting (finds maximum clique)
fn bron_kerbosch_pivot(
  adj: Dict(NodeId, Set(NodeId)),
  r: Set(NodeId),
  p: Set(NodeId),
  x: Set(NodeId),
) -> Set(NodeId) {
  case set.is_empty(p) && set.is_empty(x) {
    True -> r
    False -> {
      let pivot = choose_pivot(adj, p, x)
      let pivot_neighbors = get_neighbors(adj, pivot)
      let candidates = set.drop(p, set.to_list(pivot_neighbors))

      // Process candidates not connected to pivot
      set.to_list(candidates)
      |> list.fold(#(p, x, set.new()), fn(acc, v) {
        let #(curr_p, curr_x, best_r) = acc
        let v_neighbors = get_neighbors(adj, v)

        let recursive_r =
          bron_kerbosch_pivot(
            adj,
            set.insert(r, v),
            set.intersection(curr_p, v_neighbors),
            set.intersection(curr_x, v_neighbors),
          )

        let new_best = case set.size(recursive_r) > set.size(best_r) {
          True -> recursive_r
          False -> best_r
        }

        #(set.delete(curr_p, v), set.insert(curr_x, v), new_best)
      })
      |> fn(res) { res.2 }
    }
  }
}

// Bron-Kerbosch algorithm (finds all maximal cliques)
fn bron_kerbosch_all(
  adj: Dict(NodeId, Set(NodeId)),
  r: Set(NodeId),
  p: Set(NodeId),
  x: Set(NodeId),
  acc: List(Set(NodeId)),
) -> List(Set(NodeId)) {
  case set.is_empty(p) && set.is_empty(x) {
    True -> [r, ..acc]
    False -> {
      set.to_list(p)
      |> list.fold(#(p, x, acc), fn(state, v) {
        let #(curr_p, curr_x, curr_acc) = state
        let v_neighbors = get_neighbors(adj, v)

        let new_acc =
          bron_kerbosch_all(
            adj,
            set.insert(r, v),
            set.intersection(curr_p, v_neighbors),
            set.intersection(curr_x, v_neighbors),
            curr_acc,
          )

        #(set.delete(curr_p, v), set.insert(curr_x, v), new_acc)
      })
      |> fn(res) { res.2 }
    }
  }
}

// Modified Bron-Kerbosch for finding cliques of exact size k
fn bron_kerbosch_k(
  adj: Dict(NodeId, Set(NodeId)),
  r: Set(NodeId),
  p: Set(NodeId),
  k: Int,
  acc: List(Set(NodeId)),
) -> List(Set(NodeId)) {
  let r_size = set.size(r)

  case r_size == k {
    // Found a k-clique!
    True -> [r, ..acc]
    False -> {
      // Prune: can't reach size k even if we add all remaining candidates
      case r_size + set.size(p) < k {
        True -> acc
        False -> {
          // Continue exploring
          set.to_list(p)
          |> list.fold(#(p, acc), fn(state, v) {
            let #(curr_p, curr_acc) = state
            let v_neighbors = get_neighbors(adj, v)

            let new_acc =
              bron_kerbosch_k(
                adj,
                set.insert(r, v),
                set.intersection(curr_p, v_neighbors),
                k,
                curr_acc,
              )

            #(set.delete(curr_p, v), new_acc)
          })
          |> fn(res) { res.1 }
        }
      }
    }
  }
}
