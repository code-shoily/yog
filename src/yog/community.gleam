//// Community detection and clustering algorithms.
////
//// Provides types and utility functions for working with community structures
//// in graphs. Community detection algorithms identify groups of nodes that
//// are more densely connected internally than with the rest of the graph.
////
//// ## Algorithms
////
//// | Algorithm | Module | Best For |
//// |-----------|--------|----------|
//// | [Louvain](https://en.wikipedia.org/wiki/Louvain_method) | `yog/community/louvain` | Large graphs, modularity optimization |
//// | [Leiden](https://en.wikipedia.org/wiki/Leiden_algorithm) | `yog/community/leiden` | Quality guarantee, well-connected communities |
//// | [Label Propagation](https://en.wikipedia.org/wiki/Label_propagation_algorithm) | `yog/community/label_propagation` | Speed, near-linear time |
//// | [Girvan-Newman](https://en.wikipedia.org/wiki/Girvan%E2%80%93Newman_algorithm) | `yog/community/girvan_newman` | Hierarchical structure, edge betweenness |
//// | [Infomap](https://www.mapequation.org/) | `yog/community/infomap` | Information-theoretic, flow-based |
//// | [Clique Percolation](https://en.wikipedia.org/wiki/Clique_percolation_method) | `yog/community/clique_percolation` | Overlapping communities |
//// | [Walktrap](https://doi.org/10.1080/15427951.2007.10129237) | `yog/community/walktrap` | Random walk-based distances |
//// | [Local Community](https://en.wikipedia.org/wiki/Community_structure#Local_communities) | `yog/community/local_community` | Massive graphs, seed expansion |
//// | [Fluid Communities](https://arxiv.org/abs/1703.09307) | `yog/community/fluid_communities` | Exact `k` partitions, fast |
////
//// ## Core Types
////
//// - **`Communities`** - Community assignment mapping nodes to community IDs
//// - **`Dendrogram`** - Hierarchical community structure with multiple levels
//// - **`CommunityId`** - Integer identifier for a community
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community
//// import yog/community/louvain
////
//// let graph = // ... build your graph
////
//// // Detect communities
//// let communities = louvain.detect(graph)
//// io.debug(communities.num_communities)  // => 4
////
//// // Get nodes in each community
//// let communities_dict = community.communities_to_dict(communities)
//// // => dict.from_list([#(0, set.from_list([1, 2, 3])), #(1, set.from_list([4, 5]))])
////
//// // Find largest community
//// case community.largest_community(communities) {
////   Some(community_id) -> io.debug(community_id)
////   None -> io.println("No communities found")
//// }
//// ```
////
//// ## Choosing an Algorithm
////
//// - **Louvain**: Fast and widely used, good for most cases
//// - **Leiden**: Better quality than Louvain, guarantees well-connected communities
//// - **Label Propagation**: Fastest option for very large graphs
//// - **Girvan-Newman**: When you need hierarchical structure
//// - **Infomap**: When flow/random walk structure matters
//// - **Clique Percolation**: When nodes may belong to multiple communities
//// - **Walktrap**: Good for capturing local structure via random walks
//// - **Local Community**: When the graph is massive/infinite and you only care about the immediate community around specific seeds
//// - **Fluid Communities**: Fast and allows finding exactly `k` communities

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/set.{type Set}
import yog/model.{type NodeId}

/// Community assignment for nodes
pub type CommunityId =
  Int

/// Represents a community partition of a graph.
///
/// ## Fields
///
/// - `assignments`: Dictionary mapping each node ID to its community ID
/// - `num_communities`: Total number of distinct communities
///
/// ## Example
///
/// ```gleam
/// Communities(
///   assignments: dict.from_list([#(1, 0), #(2, 0), #(3, 1)]),
///   num_communities: 2
/// )
/// // Node 1 and 2 are in community 0, node 3 is in community 1
/// ```
pub type Communities {
  Communities(assignments: Dict(NodeId, CommunityId), num_communities: Int)
}

/// Hierarchical community structure with multiple levels of granularity.
///
/// ## Fields
///
/// - `levels`: List of community partitions from finest to coarsest
/// - `merge_order`: Order in which communities were merged (for dendrogram reconstruction)
///
/// ## Example
///
/// A dendrogram might have 3 levels:
/// - Level 0: Each node in its own community (finest)
/// - Level 1: Communities merged based on similarity
/// - Level 2: All nodes in one community (coarsest)
pub type Dendrogram {
  Dendrogram(
    levels: List(Communities),
    merge_order: List(#(CommunityId, CommunityId)),
  )
}

/// Converts community assignments to a dictionary mapping community IDs to sets of node IDs.
///
/// This is useful when you need to iterate over all nodes in each community
/// rather than looking up the community for each node.
///
/// ## Example
///
/// ```gleam
/// let communities = Communities(
///   assignments: dict.from_list([#(1, 0), #(2, 0), #(3, 1)]),
///   num_communities: 2
/// )
///
/// community.communities_to_dict(communities)
/// // => dict.from_list([
/// //      #(0, set.from_list([1, 2])),
/// //      #(1, set.from_list([3]))
/// //    ])
/// ```
pub fn communities_to_dict(
  communities: Communities,
) -> Dict(CommunityId, Set(NodeId)) {
  dict.fold(
    over: communities.assignments,
    from: dict.new(),
    with: fn(acc, node, community) {
      let current_set =
        dict.get(acc, community)
        |> option.from_result
        |> option.unwrap(set.new())
      dict.insert(acc, community, set.insert(current_set, node))
    },
  )
}

/// Returns the community ID with the largest number of nodes.
///
/// Returns `None` if there are no communities (empty graph or no assignments).
///
/// ## Example
///
/// ```gleam
/// let communities = Communities(
///   assignments: dict.from_list([#(1, 0), #(2, 0), #(3, 0), #(4, 1)]),
///   num_communities: 2
/// )
///
/// community.largest_community(communities)
/// // => Some(0)  // Community 0 has 3 nodes vs 1 for community 1
/// ```
pub fn largest_community(communities: Communities) -> Option(CommunityId) {
  community_sizes(communities)
  |> dict.to_list
  |> list.sort(fn(a, b) { int.compare(b.1, a.1) })
  |> list.first
  |> option.from_result
  |> option.map(fn(pair) { pair.0 })
}

/// Returns a dictionary mapping community IDs to their sizes (number of nodes).
///
/// ## Example
///
/// ```gleam
/// let communities = Communities(
///   assignments: dict.from_list([#(1, 0), #(2, 0), #(3, 1), #(4, 1), #(5, 1)]),
///   num_communities: 2
/// )
///
/// community.community_sizes(communities)
/// // => dict.from_list([#(0, 2), #(1, 3)])
/// ```
pub fn community_sizes(communities: Communities) -> Dict(CommunityId, Int) {
  dict.fold(
    over: communities.assignments,
    from: dict.new(),
    with: fn(acc, _node, community) {
      let current_size =
        dict.get(acc, community)
        |> option.from_result
        |> option.unwrap(0)
      dict.insert(acc, community, current_size + 1)
    },
  )
}

/// Merges two communities into one.
///
/// All nodes from the source community are reassigned to the target community.
/// The source community ID is effectively removed.
///
/// ## Parameters
///
/// - `communities`: The current community partition
/// - `source`: The community ID to merge from (will be removed)
/// - `target`: The community ID to merge into (will be kept)
///
/// ## Example
///
/// ```gleam
/// let communities = Communities(
///   assignments: dict.from_list([#(1, 0), #(2, 0), #(3, 1), #(4, 1)]),
///   num_communities: 2
/// )
///
/// // Merge community 1 into community 0
/// let merged = community.merge_communities(communities, source: 1, target: 0)
/// // merged.assignments => dict.from_list([#(1, 0), #(2, 0), #(3, 0), #(4, 0)])
/// // merged.num_communities => 1
/// ```
pub fn merge_communities(
  communities: Communities,
  source: CommunityId,
  target: CommunityId,
) -> Communities {
  let new_assignments =
    dict.fold(
      over: communities.assignments,
      from: communities.assignments,
      with: fn(acc, node, community) {
        case community == source {
          True -> dict.insert(acc, node, target)
          False -> acc
        }
      },
    )

  let num_communities = case source == target {
    True -> communities.num_communities
    False -> communities.num_communities - 1
  }

  Communities(assignments: new_assignments, num_communities: num_communities)
}
