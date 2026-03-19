//// Clique Percolation Method (CPM) for detecting overlapping communities.
////
//// Identifies communities by finding "chains" of adjacent k-cliques.
//// Two k-cliques are adjacent if they share k-1 nodes. Unlike other
//// algorithms, CPM can identify nodes that belong to multiple communities.
////
//// ## Algorithm
////
//// 1. **Find** all maximal cliques (using Bron-Kerbosch)
//// 2. **Extract** all k-cliques from maximal cliques
//// 3. **Build** adjacency between k-cliques (share k-1 nodes)
//// 4. **Find** connected components of k-cliques
//// 5. **Merge** cliques in each component to form communities
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Overlapping communities | ✓ Only algorithm in this module |
//// | Dense networks with cliques | ✓ Excellent |
//// | Sparse graphs | ✗ May find no communities |
//// | Non-overlapping needed | Convert with `to_communities/1` |
////
//// ## Complexity
////
//// - **Time**: O(3^(V/3)) for maximal clique enumeration (worst case)
//// - **Space**: O(V + E)
////
//// **Note**: Clique enumeration can be expensive on large or dense graphs.
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/clique_percolation as cpm
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1), #(3, 1, 1)])  // Triangle
////
//// // Detect overlapping communities (k=3 finds triangles)
//// let overlapping = cpm.detect_overlapping(graph)
//// // overlapping.communities contains sets of nodes
////
//// // Convert to non-overlapping (assigns node to first community)
//// let communities = cpm.to_communities(overlapping)
////
//// // With custom k
//// let options = cpm.CPMOptions(k: 4)
//// let overlapping = cpm.detect_overlapping_with_options(graph, options)
//// ```
////
//// ## References
////
//// - [Palla et al. 2005 - Uncovering overlapping community structure](https://doi.org/10.1038/nature03607)
//// - [Wikipedia: Clique Percolation Method](https://en.wikipedia.org/wiki/Clique_percolation_method)

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import yog/community.{type Communities, Communities}
import yog/model.{type Graph, type NodeId}

/// Result of overlapping community detection.
pub type OverlappingCommunities {
  OverlappingCommunities(
    /// List of communities, where each community is a set of node IDs.
    communities: List(Set(NodeId)),
  )
}

/// Options for Clique Percolation Method.
pub type CPMOptions {
  CPMOptions(
    /// Size of the clique (k). Typically 3 or 4.
    k: Int,
  )
}

/// Default options for CPM.
pub fn default_options() -> CPMOptions {
  CPMOptions(k: 3)
}

/// Detects overlapping communities using CPM with default options.
pub fn detect_overlapping(graph: Graph(n, e)) -> OverlappingCommunities {
  detect_overlapping_with_options(graph, default_options())
}

/// Detects overlapping communities using CPM with custom options.
pub fn detect_overlapping_with_options(
  graph: Graph(n, e),
  options: CPMOptions,
) -> OverlappingCommunities {
  let k = options.k
  let nodes = model.all_nodes(graph)

  // 1. Find all maximal cliques (Bron-Kerbosch)
  let maximal_cliques = find_maximal_cliques(graph, nodes)

  // 2. Extract all k-cliques from maximal cliques
  let k_cliques =
    list.flat_map(maximal_cliques, fn(clique) {
      let clique_list = set.to_list(clique)
      case list.length(clique_list) < k {
        True -> []
        False -> combinations(clique_list, k) |> list.map(set.from_list)
      }
    })
    |> list.unique

  // 3. Build adjacency between k-cliques
  // Two k-cliques are adjacent if they share k-1 nodes
  let clique_adj =
    list.index_map(k_cliques, fn(c1, i) {
      let neighbors =
        list.index_fold(over: k_cliques, from: [], with: fn(acc, c2, j) {
          case i < j && set.size(set.intersection(c1, c2)) == { k - 1 } {
            True -> [j, ..acc]
            False -> acc
          }
        })
      #(i, neighbors)
    })
    |> dict.from_list

  // 4. Find connected components of cliques
  let clique_components =
    find_clique_components(clique_adj, list.length(k_cliques))

  // 5. Build node sets from clique components
  let communities =
    list.map(clique_components, fn(component) {
      list.fold(over: component, from: set.new(), with: fn(acc, clique_idx) {
        let clique =
          list.drop(k_cliques, clique_idx)
          |> list.first
          |> result.unwrap(set.new())
        set.union(acc, clique)
      })
    })

  OverlappingCommunities(communities)
}

/// Converts overlapping communities to hard assignments by picking 
/// the first community for each node.
pub fn to_communities(overlapping: OverlappingCommunities) -> Communities {
  let assignments =
    list.index_fold(
      over: overlapping.communities,
      from: dict.new(),
      with: fn(acc, community, idx) {
        list.fold(
          over: set.to_list(community),
          from: acc,
          with: fn(inner_acc, node) {
            case dict.has_key(inner_acc, node) {
              True -> inner_acc
              False -> dict.insert(inner_acc, node, idx)
            }
          },
        )
      },
    )

  Communities(assignments, list.length(overlapping.communities))
}

// --- Internal Implementation ---

fn find_maximal_cliques(
  graph: Graph(n, e),
  nodes: List(NodeId),
) -> List(Set(NodeId)) {
  let neighbors_dict =
    list.map(nodes, fn(u) {
      #(
        u,
        model.successors(graph, u) |> list.map(fn(v) { v.0 }) |> set.from_list,
      )
    })
    |> dict.from_list

  bron_kerbosch(set.new(), set.from_list(nodes), set.new(), neighbors_dict)
}

fn bron_kerbosch(
  r: Set(NodeId),
  p: Set(NodeId),
  x: Set(NodeId),
  neighbors: Dict(NodeId, Set(NodeId)),
) -> List(Set(NodeId)) {
  case set.is_empty(p) && set.is_empty(x) {
    True -> [r]
    False -> {
      // Simplified Bron-Kerbosch without pivoting for now
      let p_list = set.to_list(p)
      let #(_, cliques) =
        list.fold(over: p_list, from: #(p, []), with: fn(acc, v) {
          let current_p = acc.0
          let current_cliques = acc.1

          let v_neighbors = dict.get(neighbors, v) |> result.unwrap(set.new())

          let new_r = set.insert(r, v)
          let new_p = set.intersection(current_p, v_neighbors)
          let new_x = set.intersection(x, v_neighbors)

          let results = bron_kerbosch(new_r, new_p, new_x, neighbors)

          #(set.delete(current_p, v), list.append(results, current_cliques))
        })
      cliques
    }
  }
}

fn combinations(items: List(a), k: Int) -> List(List(a)) {
  case k {
    0 -> [[]]
    _ -> {
      case items {
        [] -> []
        [first, ..rest] -> {
          let with_first =
            combinations(rest, k - 1)
            |> list.map(fn(c) { [first, ..c] })
          let without_first = combinations(rest, k)
          list.append(with_first, without_first)
        }
      }
    }
  }
}

fn find_clique_components(adj: Dict(Int, List(Int)), n: Int) -> List(List(Int)) {
  // DFS to find connected components
  let visited = set.new()
  let #(_, components) =
    int.range(from: 0, to: n, with: #(visited, []), run: fn(acc, i) {
      case set.contains(acc.0, i) {
        True -> acc
        False -> {
          let #(new_visited, component) = dfs_component(i, adj, acc.0, [])
          #(new_visited, [component, ..acc.1])
        }
      }
    })
  components
}

fn dfs_component(
  u: Int,
  adj: Dict(Int, List(Int)),
  visited: Set(Int),
  component: List(Int),
) -> #(Set(Int), List(Int)) {
  let visited = set.insert(visited, u)
  let component = [u, ..component]
  let neighbors = dict.get(adj, u) |> result.unwrap([])

  list.fold(over: neighbors, from: #(visited, component), with: fn(acc, v) {
    case set.contains(acc.0, v) {
      True -> acc
      False -> dfs_component(v, adj, acc.0, acc.1)
    }
  })
}
