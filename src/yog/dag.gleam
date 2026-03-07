import yog/dag/algorithms
import yog/dag/models.{type Dag}

// Re-export models
pub fn from_graph(graph) {
  models.from_graph(graph)
}

pub fn to_graph(dag: Dag(n, e)) {
  models.to_graph(dag)
}

// Re-export algorithms
pub fn topological_sort(dag: Dag(n, e)) {
  algorithms.topological_sort(dag)
}

pub fn longest_path(dag: Dag(n, Int)) {
  algorithms.longest_path(dag)
}

pub fn transitive_closure(dag: Dag(n, e), with merge_fn: fn(e, e) -> e) {
  algorithms.transitive_closure(dag, merge_fn)
}

pub fn transitive_reduction(dag: Dag(n, e), with merge_fn: fn(e, e) -> e) {
  algorithms.transitive_reduction(dag, merge_fn)
}

pub fn count_reachability(dag: Dag(n, e), direction: algorithms.Direction) {
  algorithms.count_reachability(dag, direction)
}

pub fn lowest_common_ancestors(dag: Dag(n, e), node_a, node_b) {
  algorithms.lowest_common_ancestors(dag, node_a, node_b)
}
