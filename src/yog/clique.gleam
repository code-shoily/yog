//// Maximum clique finding using the Bron-Kerbosch algorithm.
////
//// A clique is a subset of vertices where every two vertices are adjacent
//// (i.e., a complete subgraph). Finding the maximum clique is NP-complete,
//// but the Bron-Kerbosch algorithm with pivoting is efficient in practice.
////
//// ## Use Cases
////
//// - Social network analysis: Finding tightly-knit friend groups
//// - Computational biology: Identifying protein complexes
//// - Code analysis: Detecting mutually dependent modules
//// - Graph coloring: Chromatic number lower bounds
//// - AoC 2024 Day 23: Finding largest sets of interconnected computers

import gleam/list
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}

/// Finds the maximum clique in an undirected graph.
///
/// A clique is a subset of nodes where every pair of nodes is connected.
/// This function returns the largest such subset found using the Bron-Kerbosch
/// algorithm with pivoting.
///
/// **Time Complexity:** O(3^(n/3)) worst case, but much faster in practice due to pivoting
///
/// **Note:** This algorithm works on undirected graphs. For directed graphs,
/// consider using the underlying undirected structure.
///
/// ## Example
///
/// ```gleam
/// import yog
/// import yog/clique
///
/// // Create a graph with a 4-clique
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_node(4, "D")
///   |> yog.add_node(5, "E")
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 1, to: 3, with: 1)
///   |> yog.add_edge(from: 1, to: 4, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 2, to: 4, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///   |> yog.add_edge(from: 4, to: 5, with: 1)
///
/// clique.max_clique(graph)
/// // => set.from_list([1, 2, 3, 4])  // The 4-clique
/// ```
pub fn max_clique(graph: Graph(n, e)) -> Set(NodeId) {
  let all_nodes = model.all_nodes(graph)
  let p = set.from_list(all_nodes)
  let r = set.new()
  let x = set.new()

  bron_kerbosch_pivot(graph, r, p, x)
}

/// Finds all maximal cliques in an undirected graph.
///
/// A maximal clique is a clique that cannot be extended by adding another node.
/// Note that there can be many maximal cliques, and they may have different sizes.
///
/// **Time Complexity:** O(3^(n/3)) worst case
///
/// ## Example
///
/// ```gleam
/// import yog
/// import yog/clique
///
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// clique.all_maximal_cliques(graph)
/// // => [set.from_list([1, 2]), set.from_list([2, 3])]
/// ```
pub fn all_maximal_cliques(graph: Graph(n, e)) -> List(Set(NodeId)) {
  let all_nodes = model.all_nodes(graph)
  let p = set.from_list(all_nodes)
  let r = set.new()
  let x = set.new()

  bron_kerbosch_all(graph, r, p, x, [])
}

// Bron-Kerbosch algorithm with pivoting (finds maximum clique)
fn bron_kerbosch_pivot(
  graph: Graph(n, e),
  r: Set(NodeId),
  p: Set(NodeId),
  x: Set(NodeId),
) -> Set(NodeId) {
  case set.is_empty(p) && set.is_empty(x) {
    True -> r
    False -> {
      // Choose pivot from P ∪ X to maximize |P ∩ N(pivot)|
      let pivot = choose_pivot(p, x)
      let pivot_neighbors = get_neighbor_ids_set(graph, pivot)
      let candidates = set.drop(p, set.to_list(pivot_neighbors))

      // Process candidates not connected to pivot
      set.to_list(candidates)
      |> list.fold(#(p, x, set.new()), fn(acc, v) {
        let #(curr_p, curr_x, best_r) = acc
        let v_neighbors = get_neighbor_ids_set(graph, v)

        let recursive_r =
          bron_kerbosch_pivot(
            graph,
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
  graph: Graph(n, e),
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
        let v_neighbors = get_neighbor_ids_set(graph, v)

        let new_acc =
          bron_kerbosch_all(
            graph,
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

// Get neighbor IDs as a set for faster intersection operations
fn get_neighbor_ids_set(graph: Graph(n, e), id: NodeId) -> Set(NodeId) {
  model.neighbors(graph, id)
  |> list.map(fn(neighbor) { neighbor.0 })
  |> set.from_list
}

// Choose a pivot to minimize the number of recursive calls
fn choose_pivot(p: Set(NodeId), x: Set(NodeId)) -> NodeId {
  set.union(p, x)
  |> set.to_list
  |> list.first
  |> result.unwrap(-1)
}
