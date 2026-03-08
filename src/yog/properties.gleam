//// Graph properties and structural analysis.
////
//// This module provides functions to analyze various graph properties,
//// including bipartiteness, cliques, Eulerian paths/circuits, and cyclicity.
////
//// ## Features
////
//// - **Bipartite Graphs:** Check for bipartiteness, extract partitions, and find maximum matchings.
//// - **Stable Marriage:** Solve the stable matching problem (Gale-Shapley algorithm).
//// - **Cliques:** Find maximum, maximal, and k-sized cliques (Bron-Kerbosch algorithm).
//// - **Eulerian Paths:** Detect and construct Eulerian paths and circuits (Hierholzer's algorithm).
//// - **Cyclicity:** Check if a graph contains any cycles.

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import gleam/set.{type Set}
import yog/internal/properties/bipartite
import yog/internal/properties/clique
import yog/internal/properties/eulerian
import yog/model.{type Graph, type NodeId}
import yog/traversal

// --- Properties ---

/// Checks if the graph is a Directed Acyclic Graph (DAG) or has no cycles if undirected.
pub fn is_acyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_acyclic(graph)
}

/// Checks if the graph contains at least one cycle.
pub fn is_cyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_cyclic(graph)
}

// --- Types ---

pub type Partition =
  bipartite.Partition

pub type StableMarriage =
  bipartite.StableMarriage

// --- Bipartite ---

/// Checks if a graph is bipartite (2-colorable).
///
/// A graph is bipartite if its vertices can be divided into two disjoint sets
/// such that every edge connects a vertex in one set to a vertex in the other set.
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_node(4, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///
/// properties.is_bipartite(graph)  // => True (can color as: 1,3 vs 2,4)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn is_bipartite(graph: Graph(n, e)) -> Bool {
  bipartite.is_bipartite(graph)
}

/// Returns the two partitions of a bipartite graph, or None if the graph is not properties.
///
/// Uses BFS with 2-coloring to detect bipartiteness and construct the partitions.
/// Handles disconnected graphs by checking all connectivity.
///
/// ## Example
/// ```gleam
/// case properties.partition(graph) {
///   Some(Partition(left, right)) -> {
///     // left and right are the two independent sets
///     io.println("Graph is bipartite!")
///   }
///   None -> io.println("Graph is not bipartite")
/// }
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn partition(graph: Graph(n, e)) -> Option(Partition) {
  bipartite.partition(graph)
}

/// Finds a maximum matching in a bipartite graph.
///
/// A matching is a set of edges with no common vertices. A maximum matching
/// has the largest possible number of edges.
///
/// Uses the augmenting path algorithm (also known as the Hungarian algorithm
/// for unweighted bipartite matching).
///
/// Returns a list of matched pairs `#(left_node, right_node)`.
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)  // left
///   |> yog.add_node(2, Nil)  // left
///   |> yog.add_node(3, Nil)  // right
///   |> yog.add_node(4, Nil)  // right
///   |> yog.add_edge(from: 1, to: 3, with: 1)
///   |> yog.add_edge(from: 1, to: 4, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// case properties.partition(graph) {
///   Some(p) -> {
///     let matching = properties.maximum_matching(graph, p)
///     // => [#(1, 3), #(2, 4)] or [#(1, 4), #(2, 3)]
///   }
///   None -> panic as "Not bipartite"
/// }
/// ```
///
/// **Time Complexity:** O(V * E)
pub fn maximum_matching(
  graph: Graph(n, e),
  partition p: Partition,
) -> List(#(NodeId, NodeId)) {
  bipartite.maximum_matching(graph, p)
}

/// Finds a stable matching given preference lists for two groups.
///
/// Uses the Gale-Shapley algorithm to find a stable matching where no two people
/// would both prefer each other over their current partners.
///
/// The algorithm is "proposer-optimal" - it finds the best stable matching for
/// the proposing group (left), and the worst stable matching for the receiving
/// group (right).
///
/// ## Parameters
///
/// - `left_prefs` - Dict mapping each left person to their preference list (most preferred first)
/// - `right_prefs` - Dict mapping each right person to their preference list (most preferred first)
///
/// ## Returns
///
/// A `StableMarriage` containing the matched pairs. Use `get_partner()` to query matches.
///
/// ## Example
///
/// ```gleam
/// // Medical residency matching
/// let residents = dict.from_list([
///   #(1, [101, 102, 103]),  // Resident 1 prefers hospitals 101, 102, 103
///   #(2, [102, 101, 103]),
///   #(3, [101, 103, 102]),
/// ])
///
/// let hospitals = dict.from_list([
///   #(101, [1, 2, 3]),      // Hospital 101 prefers residents 1, 2, 3
///   #(102, [2, 1, 3]),
///   #(103, [1, 2, 3]),
/// ])
///
/// let matching = properties.stable_marriage(residents, hospitals)
/// case get_partner(matching, 1) {
///   Some(hospital) -> io.println("Resident 1 matched to hospital " <> int.to_string(hospital))
///   None -> io.println("Resident 1 unmatched")
/// }
/// ```
///
/// **Time Complexity:** O(n²) where n is the size of each group
pub fn stable_marriage(
  left_prefs: Dict(NodeId, List(NodeId)),
  right_prefs: Dict(NodeId, List(NodeId)),
) -> StableMarriage {
  bipartite.stable_marriage(left_prefs, right_prefs)
}

/// Get the partner of a person in a stable matching.
///
/// Returns `Some(partner)` if the person is matched, `None` otherwise.
pub fn get_partner(marriage: StableMarriage, person: NodeId) -> Option(NodeId) {
  bipartite.get_partner(marriage, person)
}

// --- Clique ---

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
/// import yog/properties
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
/// properties.max_clique(graph)
/// // => set.from_list([1, 2, 3, 4])  // The 4-clique
/// ```
pub fn max_clique(graph: Graph(n, e)) -> Set(NodeId) {
  clique.max_clique(graph)
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
/// import yog/properties
///
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// properties.all_maximal_cliques(graph)
/// // => [set.from_list([1, 2]), set.from_list([2, 3])]
/// ```
pub fn all_maximal_cliques(graph: Graph(n, e)) -> List(Set(NodeId)) {
  clique.all_maximal_cliques(graph)
}

/// Finds all cliques of exactly size k in an undirected graph.
///
/// Returns all subsets of k nodes where every pair of nodes is connected.
/// Uses a modified Bron-Kerbosch algorithm with early pruning for efficiency.
///
/// **Time Complexity:** Generally faster than finding all maximal cliques when k is small,
/// as branches are pruned when they cannot reach size k.
///
/// ## Example
///
/// ```gleam
/// import yog
/// import yog/properties
///
/// // Create a graph with triangles (3-cliques)
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, "A")
///   |> yog.add_node(2, "B")
///   |> yog.add_node(3, "C")
///   |> yog.add_node(4, "D")
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 1, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 4, with: 1)
///
/// properties.k_cliques(graph, 3)
/// // => [set.from_list([1, 2, 3])]  // The single triangle
///
/// properties.k_cliques(graph, 2)
/// // => [set.from_list([1, 2]), set.from_list([1, 3]),
/// //     set.from_list([2, 3]), set.from_list([3, 4])]  // All edges
/// ```
pub fn k_cliques(graph: Graph(n, e), size k: Int) -> List(Set(NodeId)) {
  clique.k_cliques(graph, k)
}

// --- Eulerian ---

/// Checks if the graph has an Eulerian circuit (a cycle that visits every edge exactly once).
///
/// ## Conditions
/// - **Undirected graph:** All vertices must have even degree and the graph must be connected
/// - **Directed graph:** All vertices must have equal in-degree and out-degree, and the graph must be strongly connected
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 1, with: 1)
///
/// properties.has_eulerian_circuit(graph)  // => True (triangle)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_circuit(graph: Graph(n, e)) -> Bool {
  eulerian.has_eulerian_circuit(graph)
}

/// Checks if the graph has an Eulerian path (a path that visits every edge exactly once).
///
/// ## Conditions
/// - **Undirected graph:** Exactly 0 or 2 vertices must have odd degree, and the graph must be connected
/// - **Directed graph:** At most one vertex with (out-degree - in-degree = 1), at most one with (in-degree - out-degree = 1), all others balanced
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// properties.has_eulerian_path(graph)  // => True (path from 1 to 3)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn has_eulerian_path(graph: Graph(n, e)) -> Bool {
  eulerian.has_eulerian_path(graph)
}

/// Finds an Eulerian circuit in the graph using Hierholzer's algorithm.
///
/// Returns the path as a list of node IDs that form a circuit (starts and ends at the same node).
/// Returns None if no Eulerian circuit exists.
///
/// **Time Complexity:** O(E)
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///   |> yog.add_edge(from: 3, to: 1, with: 1)
///
/// properties.find_eulerian_circuit(graph)  // => Some([1, 2, 3, 1])
/// ```
pub fn find_eulerian_circuit(graph: Graph(n, e)) -> Option(List(NodeId)) {
  eulerian.find_eulerian_circuit(graph)
}

/// Finds an Eulerian path in the graph using Hierholzer's algorithm.
///
/// Returns the path as a list of node IDs. Returns None if no Eulerian path exists.
///
/// **Time Complexity:** O(E)
///
/// ## Example
/// ```gleam
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: 1)
///   |> yog.add_edge(from: 2, to: 3, with: 1)
///
/// properties.find_eulerian_path(graph)  // => Some([1, 2, 3])
/// ```
pub fn find_eulerian_path(graph: Graph(n, e)) -> Option(List(NodeId)) {
  eulerian.find_eulerian_path(graph)
}
