//// Local community detection using fitness maximization.
////
//// This module implements a local community detection algorithm that starts
//// from a set of seed nodes and iteratively expands (or shrinks) the community
//// to maximize a local fitness function. It is particularly useful for extracting
//// the community surrounding a specific node without calculating the global
//// community structure of the entire graph, making it efficient for massive or
//// infinite (implicit) graphs.
////
//// The fitness function used is based on Lancichinetti et al. (2009):
//// `f(S) = k_in / (k_in + k_out)^alpha`
//// where `k_in` is the sum of internal degrees (twice the internal edge weights),
//// `k_out` is the sum of external degrees (edges to outside S),
//// and `alpha` is a resolution parameter controlling community size.
////
//// ## Example
////
//// ```gleam
//// import yog/community/local_community
////
//// // Find the local community around node 5
//// let community = local_community.detect(graph, seeds: [5], alpha: 1.0)
//// // Returns a Set(NodeId) containing the local community
//// ```
////
//// ## References
////
//// - Lancichinetti et al. (2009). Detecting the overlapping and hierarchical community structure in complex networks.
//// - Clauset, A. (2005). Finding local community structure in networks.

import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}

/// Options for local community detection.
pub type LocalCommunityOptions {
  LocalCommunityOptions(
    /// Resolution parameter controlling the size of the community.
    /// Default is 1.0. Larger values yield smaller communities.
    alpha: Float,
    /// Maximum number of adjustment iterations to perform.
    max_iterations: Int,
  )
}

/// Default options for local community detection.
/// alpha = 1.0, max_iterations = 1000
pub fn default_options() -> LocalCommunityOptions {
  LocalCommunityOptions(alpha: 1.0, max_iterations: 1000)
}

/// Detects a local community starting from a list of seed nodes using default options.
///
/// Assumes unweighted edges (weight = 1.0) if the graph weights are not Floats.
/// Use `detect_float` or `detect_int` or custom weight functions if needed.
/// But for simplicity, we map uniform weights to 1.0 if not specified.
pub fn detect(graph: Graph(n, e), seeds: List(NodeId)) -> Set(NodeId) {
  detect_with(graph, seeds, default_options(), fn(_) { 1.0 })
}

/// Detects a local community from seeds using a specific weight function.
pub fn detect_with(
  graph: Graph(n, e),
  seeds: List(NodeId),
  options: LocalCommunityOptions,
  weight_fn: fn(e) -> Float,
) -> Set(NodeId) {
  let initial_s = set.from_list(seeds)
  // Compute initial degrees
  let #(k_in, k_out) = compute_k_out_in(graph, initial_s, weight_fn)

  // Cache the total degrees of all nodes we visit
  let degrees_cache = dict.new()

  do_detect(graph, initial_s, k_in, k_out, degrees_cache, options, 0, weight_fn)
}

fn compute_k_out_in(
  graph: Graph(n, e),
  s: Set(NodeId),
  weight_fn: fn(e) -> Float,
) -> #(Float, Float) {
  set.fold(s, #(0.0, 0.0), fn(acc, node) {
    let #(k_in_acc, k_out_acc) = acc
    list.fold(
      model.successors(graph, node),
      #(k_in_acc, k_out_acc),
      fn(acc2, neighbor_rel) {
        let #(neighbor_id, w) = neighbor_rel
        let w_float = weight_fn(w)
        case set.contains(s, neighbor_id) {
          True -> #(acc2.0 +. w_float, acc2.1)
          False -> #(acc2.0, acc2.1 +. w_float)
        }
      },
    )
  })
}

// Compute the boundary of S
fn boundary_of(graph: Graph(n, e), s: Set(NodeId)) -> Set(NodeId) {
  set.fold(s, set.new(), fn(acc, node) {
    list.fold(model.successors(graph, node), acc, fn(acc2, neighbor_rel) {
      let #(neighbor_id, _) = neighbor_rel
      case set.contains(s, neighbor_id) {
        True -> acc2
        False -> set.insert(acc2, neighbor_id)
      }
    })
  })
}

fn total_degree(
  graph: Graph(n, e),
  node: NodeId,
  cache: Dict(NodeId, Float),
  weight_fn: fn(e) -> Float,
) -> #(Float, Dict(NodeId, Float)) {
  case dict.get(cache, node) {
    Ok(d) -> #(d, cache)
    Error(Nil) -> {
      let d =
        list.fold(model.successors(graph, node), 0.0, fn(acc, n) {
          acc +. weight_fn(n.1)
        })
      #(d, dict.insert(cache, node, d))
    }
  }
}

pub type Operation {
  Add(node: NodeId, new_k_in: Float, new_k_out: Float)
  Remove(node: NodeId, new_k_in: Float, new_k_out: Float)
}

fn w_in_s(
  graph: Graph(n, e),
  node: NodeId,
  s: Set(NodeId),
  weight_fn: fn(e) -> Float,
) -> Float {
  list.fold(model.successors(graph, node), 0.0, fn(acc, n) {
    case set.contains(s, n.0) {
      True -> acc +. weight_fn(n.1)
      False -> acc
    }
  })
}

fn fitness(k_in: Float, k_out: Float, alpha: Float) -> Float {
  let vol = k_in +. k_out
  case vol <=. 0.0 {
    True -> 0.0
    False -> {
      let denom =
        float.power(vol, alpha)
        |> result.unwrap(1.0)
      k_in /. denom
    }
  }
}

fn do_detect(
  graph: Graph(n, e),
  s: Set(NodeId),
  k_in: Float,
  k_out: Float,
  cache: Dict(NodeId, Float),
  opts: LocalCommunityOptions,
  iters: Int,
  weight_fn: fn(e) -> Float,
) -> Set(NodeId) {
  let bound = boundary_of(graph, s)
  let current_f = fitness(k_in, k_out, opts.alpha)

  // Find the operation that yields the highest fitness gain
  let best_add =
    set.fold(bound, #(None, current_f, cache), fn(acc, node) {
      let #(best_op, best_f, current_cache) = acc
      let #(d, next_cache) = total_degree(graph, node, current_cache, weight_fn)
      let w_in = w_in_s(graph, node, s, weight_fn)

      let new_k_in = k_in +. 2.0 *. w_in
      let new_k_out = k_out +. d -. 2.0 *. w_in
      let f = fitness(new_k_in, new_k_out, opts.alpha)

      case f >. best_f {
        True -> #(Some(Add(node, new_k_in, new_k_out)), f, next_cache)
        False -> #(best_op, best_f, next_cache)
      }
    })

  let best_op_f_cache =
    set.fold(s, best_add, fn(acc, node) {
      // Don't remove if it's the last node!
      case set.size(s) <= 1 {
        True -> acc
        False -> {
          let #(best_op, best_f, current_cache) = acc
          let #(d, next_cache) =
            total_degree(graph, node, current_cache, weight_fn)
          let w_in = w_in_s(graph, node, set.delete(s, node), weight_fn)

          let new_k_in = k_in -. 2.0 *. w_in
          let new_k_out = k_out -. d +. 2.0 *. w_in
          let f = fitness(new_k_in, new_k_out, opts.alpha)

          case f >. best_f {
            True -> #(Some(Remove(node, new_k_in, new_k_out)), f, next_cache)
            False -> #(best_op, best_f, next_cache)
          }
        }
      }
    })

  let #(best_op, _best_f, final_cache) = best_op_f_cache

  case best_op {
    None -> s
    // Local maximum reached
    Some(Add(node, nk_in, nk_out)) -> {
      let new_s = set.insert(s, node)
      case iters >= opts.max_iterations {
        True -> new_s
        False ->
          do_detect(
            graph,
            new_s,
            nk_in,
            nk_out,
            final_cache,
            opts,
            iters + 1,
            weight_fn,
          )
      }
    }
    Some(Remove(node, nk_in, nk_out)) -> {
      let new_s = set.delete(s, node)
      case iters >= opts.max_iterations {
        True -> new_s
        False ->
          do_detect(
            graph,
            new_s,
            nk_in,
            nk_out,
            final_cache,
            opts,
            iters + 1,
            weight_fn,
          )
      }
    }
  }
}
