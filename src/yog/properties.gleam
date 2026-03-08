import gleam/dict.{type Dict}
import gleam/option.{type Option}
import gleam/set.{type Set}
import yog/internal/properties/bipartite
import yog/internal/properties/clique
import yog/internal/properties/eulerian
import yog/model.{type Graph, type NodeId}
import yog/traversal

// --- Properties ---

pub fn is_acyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_acyclic(graph)
}

pub fn is_cyclic(graph: Graph(n, e)) -> Bool {
  traversal.is_cyclic(graph)
}

// --- Types ---

pub type Partition =
  bipartite.Partition

pub type StableMarriage =
  bipartite.StableMarriage

// --- Bipartite ---

pub fn is_bipartite(graph: Graph(n, e)) -> Bool {
  bipartite.is_bipartite(graph)
}

pub fn partition(graph: Graph(n, e)) -> Option(Partition) {
  bipartite.partition(graph)
}

pub fn maximum_matching(
  graph: Graph(n, e),
  partition p: Partition,
) -> List(#(NodeId, NodeId)) {
  bipartite.maximum_matching(graph, p)
}

pub fn stable_marriage(
  left_prefs: Dict(NodeId, List(NodeId)),
  right_prefs: Dict(NodeId, List(NodeId)),
) -> StableMarriage {
  bipartite.stable_marriage(left_prefs, right_prefs)
}

pub fn get_partner(marriage: StableMarriage, person: NodeId) -> Option(NodeId) {
  bipartite.get_partner(marriage, person)
}

// --- Clique ---

pub fn max_clique(graph: Graph(n, e)) -> Set(NodeId) {
  clique.max_clique(graph)
}

pub fn all_maximal_cliques(graph: Graph(n, e)) -> List(Set(NodeId)) {
  clique.all_maximal_cliques(graph)
}

pub fn k_cliques(graph: Graph(n, e), size k: Int) -> List(Set(NodeId)) {
  clique.k_cliques(graph, k)
}

// --- Eulerian ---

pub fn has_eulerian_circuit(graph: Graph(n, e)) -> Bool {
  eulerian.has_eulerian_circuit(graph)
}

pub fn has_eulerian_path(graph: Graph(n, e)) -> Bool {
  eulerian.has_eulerian_path(graph)
}

pub fn find_eulerian_circuit(graph: Graph(n, e)) -> Option(List(NodeId)) {
  eulerian.find_eulerian_circuit(graph)
}

pub fn find_eulerian_path(graph: Graph(n, e)) -> Option(List(NodeId)) {
  eulerian.find_eulerian_path(graph)
}
