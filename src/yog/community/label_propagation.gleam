//// Label Propagation Algorithm (LPA) for community detection.
////
//// A near-linear time algorithm that detects community structure by propagating
//// labels through the network. Each node adopts the most frequent label among
//// its neighbors until convergence.
////
//// ## Algorithm
////
//// 1. **Initialize**: Each node gets a unique label
//// 2. **Iterate**: Nodes update their label to the most common among neighbors
//// 3. **Converge**: Stop when no changes occur or max iterations reached
////
//// ## When to Use
////
//// | Use Case | Recommendation |
//// |----------|----------------|
//// | Very large graphs | ✓ Excellent (near-linear time) |
//// | Speed critical | ✓ Fastest option |
//// | Quality priority | Consider Louvain/Leiden |
//// | Overlapping communities | Use Clique Percolation |
////
//// ## Complexity
////
//// - **Time**: O(E × iterations), typically near-linear in practice
//// - **Space**: O(V + E)
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/label_propagation as lpa
////
//// let graph =
////   yog.undirected()
////   |> yog.add_node(1, "A")
////   |> yog.add_node(2, "B")
////   |> yog.add_node(3, "C")
////   |> yog.add_edges([#(1, 2, 1), #(2, 3, 1)])
////
//// // Basic usage
//// let communities = lpa.detect(graph)
//// io.debug(communities.num_communities)
////
//// // With custom options
//// let options = lpa.LabelPropagationOptions(max_iterations: 100, seed: 42)
//// let communities = lpa.detect_with_options(graph, options)
//// ```
////
//// ## References
////
//// - [Raghavan et al. 2007 - Near linear time algorithm](https://doi.org/10.1103/PhysRevE.76.036106)
//// - [Wikipedia: Label Propagation Algorithm](https://en.wikipedia.org/wiki/Label_propagation_algorithm)

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/set
import yog
import yog/community.{type Communities, Communities}
import yog/internal/random
import yog/internal/utils
import yog/model.{type Graph, type NodeId}

/// Options for Label Propagation Algorithm.
pub type LabelPropagationOptions {
  LabelPropagationOptions(max_iterations: Int, seed: Int)
}

/// Default options for LPA.
pub fn default_options() -> LabelPropagationOptions {
  LabelPropagationOptions(max_iterations: 100, seed: 42)
}

/// Detects communities using the Label Propagation Algorithm.
pub fn detect(graph: Graph(n, e)) -> Communities {
  detect_with_options(graph, default_options())
}

/// Detects communities using LPA with custom options.
pub fn detect_with_options(
  graph: Graph(n, e),
  options: LabelPropagationOptions,
) -> Communities {
  let nodes = model.all_nodes(graph)
  // 1. Initialize each node with its own ID as its label
  let initial_labels =
    list.map(nodes, fn(u) { #(u, u) })
    |> dict.from_list

  let rng = random.new(Some(options.seed))
  let final_labels =
    run_lpa(graph, nodes, initial_labels, options.max_iterations, rng)

  let unique_labels =
    dict.values(final_labels)
    |> set.from_list
    |> set.size

  Communities(assignments: final_labels, num_communities: unique_labels)
}

fn run_lpa(
  graph: Graph(n, e),
  nodes: List(NodeId),
  labels: Dict(NodeId, Int),
  remaining_iters: Int,
  rng: random.Rng,
) -> Dict(NodeId, Int) {
  case remaining_iters <= 0 {
    True -> labels
    False -> {
      // 2. Randomize node order using Fisher-Yates shuffle
      let #(shuffled_nodes, next_rng) = utils.shuffle(nodes, rng)

      // 3. Update labels
      let #(new_labels, changed, final_rng) =
        list.fold(
          over: shuffled_nodes,
          from: #(labels, False, next_rng),
          with: fn(acc, u) {
            let #(current_labels, was_changed, curr_rng) = acc
            let neighbors = yog.neighbors(graph, u)

            case neighbors {
              [] -> acc
              _ -> {
                let neighbor_labels =
                  list.map(neighbors, fn(pair) {
                    dict.get(current_labels, pair.0) |> result.unwrap(pair.0)
                  })

                let #(best_label, new_rng) =
                  most_frequent(neighbor_labels, curr_rng)
                let old_label = dict.get(current_labels, u) |> result.unwrap(u)

                case best_label == old_label {
                  True -> #(current_labels, was_changed, new_rng)
                  False -> #(
                    dict.insert(current_labels, u, best_label),
                    True,
                    new_rng,
                  )
                }
              }
            }
          },
        )

      case changed {
        False -> new_labels
        True ->
          run_lpa(graph, nodes, new_labels, remaining_iters - 1, final_rng)
      }
    }
  }
}

fn most_frequent(labels: List(Int), rng: random.Rng) -> #(Int, random.Rng) {
  let counts =
    list.fold(over: labels, from: dict.new(), with: fn(acc, label) {
      let count = dict.get(acc, label) |> result.unwrap(0)
      dict.insert(acc, label, count + 1)
    })

  let max_count =
    dict.values(counts)
    |> list.fold(0, int.max)

  let candidates =
    dict.to_list(counts)
    |> list.filter(fn(pair) { pair.1 == max_count })
    |> list.map(fn(pair) { pair.0 })

  // Tie-break: choose randomly from candidates
  let n = list.length(candidates)
  case n {
    0 -> #(0, rng)
    // Should not happen
    1 -> #(result.unwrap(list.first(candidates), 0), rng)
    _ -> {
      let #(idx, new_rng) = random.next_int(rng, n)
      let chosen =
        candidates
        |> list.drop(idx)
        |> list.first
        |> result.unwrap(0)
      #(chosen, new_rng)
    }
  }
}
