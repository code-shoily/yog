import gleam/dict
import gleam/list
import gleam/set
import gleeunit
import pbt/qcheck_generators as gen
import qcheck
import yog/dag/algorithm
import yog/dag/model as dag_model
import yog/model
import yog/property/cyclicity

pub fn main() {
  gleeunit.main()
}

// ============================================================
// Properties
// ============================================================

/// Property: Any graph successfully converted to a Dag must be acyclic.
pub fn dag_validity_invariant_test() {
  use graph <- qcheck.given(gen.directed_graph_generator())

  case dag_model.from_graph(graph) {
    Ok(_) -> {
      let assert True = cyclicity.is_acyclic(graph)
      Nil
    }
    Error(dag_model.CycleDetected) -> {
      let assert False = cyclicity.is_acyclic(graph)
      Nil
    }
    Error(_) -> Nil
  }
}

/// Property: For every edge u -> v in a DAG, u must appear before v in the topological sort.
pub fn topological_sort_invariant_test() {
  use graph <- qcheck.given(gen.dag_generator())
  let assert Ok(dag) = dag_model.from_graph(graph)
  let sorted = algorithm.topological_sort(dag)

  // Create a map of NodeId -> Index
  let index_map =
    sorted
    |> list.index_map(fn(node, idx) { #(node, idx) })
    |> dict.from_list()

  // Check all edges
  let all_valid =
    dict.fold(graph.out_edges, True, fn(acc, u, targets) {
      dict.fold(targets, acc, fn(inner_acc, v, _) {
        let assert Ok(u_idx) = dict.get(index_map, u)
        let assert Ok(v_idx) = dict.get(index_map, v)
        inner_acc && u_idx < v_idx
      })
    })

  let assert True = all_valid
  Nil
}

/// Property: Adding an edge to a DAG must either preserve acyclicity or correctly report a cycle.
pub fn add_edge_safety_test() {
  use graph <- qcheck.given(gen.dag_generator())
  let assert Ok(dag) = dag_model.from_graph(graph)

  let num_nodes = model.order(graph)
  case num_nodes < 2 {
    True -> Nil
    False -> {
      let nodes = model.all_nodes(graph)
      let test_pairs = list.take(list.combination_pairs(nodes), 20)

      list.each(test_pairs, fn(pair) {
        let #(u, v) = pair
        case dag_model.add_edge(dag, from: u, to: v, with: 1) {
          Ok(new_dag) -> {
            let new_graph = dag_model.to_graph(new_dag)
            let assert True = cyclicity.is_acyclic(new_graph)
            Nil
          }
          Error(dag_model.CycleDetected) -> {
            let assert Ok(cyclic_graph) =
              model.add_edge(graph, from: u, to: v, with: 1)
            let assert False = cyclicity.is_acyclic(cyclic_graph)
            Nil
          }
          Error(_) -> Nil
        }
      })
    }
  }
}

/// Property: count_reachability(Descendants) for a node u should equal the number of nodes
/// reachable from u (excluding u itself).
pub fn reachability_consistency_test() {
  use graph <- qcheck.given(gen.dag_generator())
  let assert Ok(dag) = dag_model.from_graph(graph)

  let counts = algorithm.count_reachability(dag, algorithm.Descendants)

  let all_consistent =
    dict.fold(counts, True, fn(acc, node, count) {
      let visited = bfs_reachability(graph, [node], set.new())
      // visited includes 'node' itself, so count should be size - 1
      acc && count == { set.size(visited) - 1 }
    })

  let assert True = all_consistent
  Nil
}

// Simple BFS to find all reachable nodes
fn bfs_reachability(
  graph: model.Graph(n, e),
  queue: List(model.NodeId),
  visited: set.Set(model.NodeId),
) {
  case queue {
    [] -> visited
    [current, ..rest] -> {
      case set.contains(visited, current) {
        True -> bfs_reachability(graph, rest, visited)
        False -> {
          let neighbors =
            model.successors(graph, current)
            |> list.map(fn(e) { e.0 })
          bfs_reachability(
            graph,
            list.append(rest, neighbors),
            set.insert(visited, current),
          )
        }
      }
    }
  }
}
