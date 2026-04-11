//// Graph connectivity analysis - finding connected components, bridges, articulation points,
//// and strongly connected components.
////
//// This module provides algorithms for analyzing the connectivity structure of graphs,
//// identifying components, and finding critical elements whose removal would disconnect the graph.
////
//// ## Component Types
////
//// | Component Type | Function | Graph Type | Description |
//// |----------------|----------|------------|-------------|
//// | **Connected Components** | `connected_components/1` | Undirected | Maximal connected subgraphs |
//// | **Weakly Connected Components** | `weakly_connected_components/1` | Directed | Connected when ignoring direction |
//// | **Strongly Connected Components** | `strongly_connected_components/1` | Directed | Connected following edge directions |
////
//// ## Bridges vs Articulation Points
////
//// - **Bridge** (cut edge): An edge whose removal increases the number of connected components.
////   In a network, this represents a single point of failure.
//// - **Articulation Point** (cut vertex): A node whose removal increases the number of connected
////   components. These are critical nodes in the network.
////
//// ## Algorithms
////
//// | Algorithm | Function | Use Case | Complexity |
//// |-----------|----------|----------|------------|
//// | DFS-based CC | `connected_components/1` | Undirected graph components | O(V + E) |
//// | DFS-based WCC | `weakly_connected_components/1` | Directed graph, ignore direction | O(V + E) |
//// | [Tarjan's SCC](https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm) | `strongly_connected_components/1` | Find SCCs in one pass | O(V + E) |
//// | [Kosaraju's Algorithm](https://en.wikipedia.org/wiki/Kosaraju%27s_algorithm) | `kosaraju/1` | Find SCCs using two DFS passes | O(V + E) |
//// | [Tarjan's Bridge-Finding](https://en.wikipedia.org/wiki/Bridge_(graph_theory)) | `analyze/1` | Find bridges and articulation points | O(V + E) |
////
//// All algorithms run in **O(V + E)** linear time.
////
//// ## References
////
//// - [Wikipedia: Connected Component](https://en.wikipedia.org/wiki/Component_(graph_theory))
//// - [Wikipedia: Strongly Connected Components](https://en.wikipedia.org/wiki/Strongly_connected_component)
//// - [Wikipedia: Biconnected Component](https://en.wikipedia.org/wiki/Biconnected_component)
//// - [CP-Algorithms: Finding Bridges](https://cp-algorithms.com/graph/bridge-searching.html)

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}
import yog/transform

/// Represents a bridge (critical edge) in an undirected graph.
/// Bridges are stored as ordered pairs where the first node ID is smaller.
pub type Bridge =
  #(NodeId, NodeId)

/// Type alias for a connected component - a list of node IDs.
pub type Component =
  List(NodeId)

/// Results from connectivity analysis containing bridges and articulation points.
pub type ConnectivityResults {
  ConnectivityResults(bridges: List(Bridge), articulation_points: List(NodeId))
}

// =============================================================================
// Bridge & Articulation Point Analysis
// =============================================================================

/// Analyzes an **undirected graph** to find all bridges and articulation points
/// using Tarjan's algorithm in a single DFS pass.
///
/// **Important:** This algorithm is designed for undirected graphs. For directed
/// graphs, use strongly connected components analysis instead.
///
/// **Bridges** are edges whose removal increases the number of connected components.
/// **Articulation points** (cut vertices) are nodes whose removal increases the number
/// of connected components.
///
/// **Bridge ordering:** Bridges are returned as `#(lower_id, higher_id)` for consistency.
///
/// ## Example
///
/// ```gleam
/// import yog
/// import yog/connectivity
///
/// let graph =
///   yog.undirected()
///   |> yog.add_node(1, Nil)
///   |> yog.add_node(2, Nil)
///   |> yog.add_node(3, Nil)
///   |> yog.add_edge(from: 1, to: 2, with: Nil)
///   |> yog.add_edge(from: 2, to: 3, with: Nil)
///
/// let results = connectivity.analyze(in: graph)
/// // results.bridges == [#(1, 2), #(2, 3)]
/// // results.articulation_points == [2]
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn analyze(in graph: Graph(n, e)) -> ConnectivityResults {
  let nodes = dict.keys(graph.nodes)
  let initial_state =
    InternalState(
      tin: dict.new(),
      low: dict.new(),
      timer: 0,
      bridges: [],
      points: set.new(),
      visited: set.new(),
    )

  let final_state =
    list.fold(nodes, initial_state, fn(state, node) {
      case set.contains(state.visited, node) {
        True -> state
        False -> do_analyze(graph, node, None, state)
      }
    })

  ConnectivityResults(
    bridges: final_state.bridges,
    articulation_points: set.to_list(final_state.points),
  )
}

type InternalState {
  InternalState(
    tin: Dict(NodeId, Int),
    low: Dict(NodeId, Int),
    timer: Int,
    bridges: List(Bridge),
    points: Set(NodeId),
    visited: Set(NodeId),
  )
}

fn do_analyze(
  graph: Graph(n, e),
  v: NodeId,
  parent: Option(NodeId),
  state: InternalState,
) -> InternalState {
  let tin = dict.insert(state.tin, v, state.timer)
  let low = dict.insert(state.low, v, state.timer)
  let visited = set.insert(state.visited, v)
  let timer = state.timer + 1

  let state = InternalState(..state, tin:, low:, visited:, timer:)
  let neighbors = model.successor_ids(graph, v)

  let #(final_state, children) = {
    use #(acc_state, children_count), to <- list.fold(neighbors, #(state, 0))
    case parent, set.contains(acc_state.visited, to) {
      Some(parent_id), _ if to == parent_id -> #(acc_state, children_count)
      _, True -> {
        let assert Ok(v_low) = dict.get(acc_state.low, v)
        let assert Ok(to_tin) = dict.get(acc_state.tin, to)
        let new_low = int.min(v_low, to_tin)
        #(
          InternalState(
            ..acc_state,
            low: dict.insert(acc_state.low, v, new_low),
          ),
          children_count,
        )
      }
      _, False -> {
        let post_dfs_state = do_analyze(graph, to, Some(v), acc_state)
        let assert Ok(v_low) = dict.get(post_dfs_state.low, v)
        let assert Ok(to_low) = dict.get(post_dfs_state.low, to)
        let new_v_low = int.min(v_low, to_low)
        let assert Ok(v_tin) = dict.get(post_dfs_state.tin, v)

        let new_bridges = case to_low > v_tin {
          True -> {
            let bridge = case v < to {
              True -> #(v, to)
              False -> #(to, v)
            }
            [bridge, ..post_dfs_state.bridges]
          }
          False -> post_dfs_state.bridges
        }

        let new_points = case parent, to_low >= v_tin {
          Some(_), True -> set.insert(post_dfs_state.points, v)
          _, _ -> post_dfs_state.points
        }

        #(
          InternalState(
            ..post_dfs_state,
            low: dict.insert(post_dfs_state.low, v, new_v_low),
            bridges: new_bridges,
            points: new_points,
          ),
          children_count + 1,
        )
      }
    }
  }

  // Special case: Root of DFS tree is an articulation point if it has > 1 child
  case parent, children > 1 {
    None, True ->
      InternalState(..final_state, points: set.insert(final_state.points, v))
    _, _ -> final_state
  }
}

// =============================================================================
// Tarjan's Strongly Connected Components
// =============================================================================

pub type TarjanState {
  TarjanState(
    index: Int,
    stack: List(NodeId),
    on_stack: Dict(NodeId, Bool),
    indices: Dict(NodeId, Int),
    low_links: Dict(NodeId, Int),
    components: List(List(NodeId)),
  )
}

/// Finds Strongly Connected Components (SCC) using Tarjan's Algorithm.
/// Returns a list of components, where each component is a list of NodeIds.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// import yog/connectivity
/// import yog/model.{Directed}
///
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///   |> model.add_edge(from: 2, to: 3, with: 1)
///   |> model.add_edge(from: 3, to: 1, with: 1)
///
/// let sccs = connectivity.strongly_connected_components(graph)
/// // => [[1, 2, 3]]  // All nodes form one SCC (cycle)
/// ```
pub fn strongly_connected_components(graph: Graph(n, e)) -> List(List(NodeId)) {
  let nodes = model.all_nodes(graph)

  let initial_state =
    TarjanState(
      index: 0,
      stack: [],
      on_stack: dict.new(),
      indices: dict.new(),
      low_links: dict.new(),
      components: [],
    )

  let final_state =
    list.fold(nodes, initial_state, fn(state, node) {
      case dict.has_key(state.indices, node) {
        True -> state
        False -> strong_connect(graph, node, state)
      }
    })

  final_state.components
}

fn strong_connect(
  graph: Graph(n, e),
  u: NodeId,
  state: TarjanState,
) -> TarjanState {
  let state =
    TarjanState(
      ..state,
      indices: dict.insert(state.indices, u, state.index),
      low_links: dict.insert(state.low_links, u, state.index),
      index: state.index + 1,
      stack: [u, ..state.stack],
      on_stack: dict.insert(state.on_stack, u, True),
    )

  let successors = model.successor_ids(graph, u)

  let state = {
    use st, v <- list.fold(successors, state)
    case
      dict.has_key(st.indices, v),
      dict.get(st.on_stack, v) |> result.unwrap(False)
    {
      False, _ -> {
        let st = strong_connect(graph, v, st)
        let u_low = dict.get(st.low_links, u) |> result.unwrap(0)
        let v_low = dict.get(st.low_links, v) |> result.unwrap(0)
        TarjanState(
          ..st,
          low_links: dict.insert(st.low_links, u, int.min(u_low, v_low)),
        )
      }
      True, True -> {
        let u_low = dict.get(st.low_links, u) |> result.unwrap(0)
        let v_index = dict.get(st.indices, v) |> result.unwrap(0)
        TarjanState(
          ..st,
          low_links: dict.insert(st.low_links, u, int.min(u_low, v_index)),
        )
      }
      True, False -> st
    }
  }

  let u_index = dict.get(state.indices, u) |> result.unwrap(0)
  let u_low = dict.get(state.low_links, u) |> result.unwrap(0)

  case u_low == u_index {
    True -> pop_stack_until(u, state, [])
    False -> state
  }
}

fn pop_stack_until(
  u: NodeId,
  state: TarjanState,
  component: List(NodeId),
) -> TarjanState {
  case state.stack {
    [] -> state
    [head, ..tail] -> {
      let new_component = [head, ..component]
      let new_on_stack = dict.insert(state.on_stack, head, False)
      let next_state = TarjanState(..state, stack: tail, on_stack: new_on_stack)

      case head == u {
        True ->
          TarjanState(..next_state, components: [
            new_component,
            ..state.components
          ])
        False -> pop_stack_until(u, next_state, new_component)
      }
    }
  }
}

// =============================================================================
// Kosaraju's Algorithm
// =============================================================================

/// Finds Strongly Connected Components (SCC) using Kosaraju's Algorithm.
///
/// Returns a list of components, where each component is a list of NodeIds.
/// Kosaraju's algorithm uses two DFS passes and graph transposition:
///
/// 1. First DFS: Compute finishing times (nodes added to stack when DFS completes)
/// 2. Transpose the graph (reverse all edges) - O(1) operation!
/// 3. Second DFS: Process nodes in reverse finishing time order on transposed graph
///
/// **Time Complexity:** O(V + E) where V is vertices and E is edges
/// **Space Complexity:** O(V) for the visited set and finish stack
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///   |> model.add_edge(from: 2, to: 3, with: 1)
///   |> model.add_edge(from: 3, to: 1, with: 1)
///
/// let sccs = connectivity.kosaraju(graph)
/// // => [[1, 2, 3]]  // All nodes form one SCC (cycle)
/// ```
///
/// ## Comparison with Tarjan's Algorithm
///
/// - **Kosaraju:** Two DFS passes, requires graph transposition, simpler to understand
/// - **Tarjan:** Single DFS pass, no transposition needed, uses low-link values
///
/// Both have the same O(V + E) time complexity, but Kosaraju may be preferred when:
/// - The graph is already stored in a format supporting fast transposition
/// - Simplicity and clarity are prioritized over single-pass execution
pub fn kosaraju(graph: Graph(n, e)) -> List(List(NodeId)) {
  let nodes = model.all_nodes(graph)

  let #(finish_stack, _) = {
    use #(stack, visited), node <- list.fold(nodes, #([], set.new()))
    first_dfs(graph, node, visited, stack)
  }

  let transposed = transform.transpose(graph)

  let #(components, _) = {
    use #(components, visited), node <- list.fold(finish_stack, #([], set.new()))
    case set.contains(visited, node) {
      True -> #(components, visited)
      False -> {
        let #(component, new_visited) =
          second_dfs(transposed, node, visited, [])
        #([component, ..components], new_visited)
      }
    }
  }

  components
}

fn first_dfs(
  graph: Graph(n, e),
  node: NodeId,
  visited: Set(NodeId),
  stack: List(NodeId),
) -> #(List(NodeId), Set(NodeId)) {
  case set.contains(visited, node) {
    True -> #(stack, visited)
    False -> {
      let new_visited = set.insert(visited, node)
      let successors = model.successor_ids(graph, node)

      let #(new_stack, final_visited) = {
        use #(s, v), succ <- list.fold(successors, #(stack, new_visited))
        first_dfs(graph, succ, v, s)
      }

      #([node, ..new_stack], final_visited)
    }
  }
}

fn second_dfs(
  transposed: Graph(n, e),
  node: NodeId,
  visited: Set(NodeId),
  component: List(NodeId),
) -> #(List(NodeId), Set(NodeId)) {
  case set.contains(visited, node) {
    True -> #(component, visited)
    False -> {
      let new_visited = set.insert(visited, node)
      let new_component = [node, ..component]
      let successors = model.successor_ids(transposed, node)

      use #(comp, vis), succ <- list.fold(successors, #(
        new_component,
        new_visited,
      ))
      second_dfs(transposed, succ, vis, comp)
    }
  }
}

// =============================================================================
// Connected Components (Undirected)
// =============================================================================

/// Finds Connected Components in an **undirected graph**.
///
/// A connected component is a maximal subgraph where every node is reachable
/// from every other node via undirected edges. This uses simple DFS and runs
/// in linear time.
///
/// **Important:** This algorithm is designed for undirected graphs. For directed
/// graphs, use `weakly_connected_components/1` instead.
///
/// **Time Complexity:** O(V + E) where V is vertices and E is edges
/// **Space Complexity:** O(V) for the visited set
///
/// ## Example
///
/// ```gleam
/// import yog/connectivity
/// import yog/model.{Undirected}
///
/// let graph =
///   model.new(Undirected)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_node(4, "D")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///   |> model.add_edge(from: 3, to: 4, with: 1)
///
/// let components = connectivity.connected_components(graph)
/// // => [[1, 2], [3, 4]]  // Two separate components
/// ```
pub fn connected_components(graph: Graph(n, e)) -> List(Component) {
  let nodes = model.all_nodes(graph)
  do_connected_components(graph, nodes, set.new(), [])
}

fn do_connected_components(
  graph: Graph(n, e),
  nodes: List(NodeId),
  visited: Set(NodeId),
  components: List(Component),
) -> List(Component) {
  case nodes {
    [] -> components
    [node, ..rest] ->
      case set.contains(visited, node) {
        True -> do_connected_components(graph, rest, visited, components)
        False -> {
          let #(component, new_visited) = dfs_collect(graph, node, visited, [])
          do_connected_components(graph, rest, new_visited, [
            component,
            ..components
          ])
        }
      }
  }
}

fn dfs_collect(
  graph: Graph(n, e),
  node: NodeId,
  visited: Set(NodeId),
  component: List(NodeId),
) -> #(List(NodeId), Set(NodeId)) {
  case set.contains(visited, node) {
    True -> #(component, visited)
    False -> {
      let new_visited = set.insert(visited, node)
      let neighbors = model.successor_ids(graph, node)

      use #(comp, vis), neighbor <- list.fold(neighbors, #(
        [node, ..component],
        new_visited,
      ))
      dfs_collect(graph, neighbor, vis, comp)
    }
  }
}

// =============================================================================
// Weakly Connected Components (Directed)
// =============================================================================

/// Finds Weakly Connected Components in a **directed graph**.
///
/// A weakly connected component is a maximal subgraph where, if you ignore
/// edge directions, all nodes are reachable from each other. This is equivalent
/// to finding connected components on the underlying undirected graph.
///
/// For directed graphs, you have two component concepts:
/// - **Weakly Connected Components** (WCC): Treat edges as undirected
/// - **Strongly Connected Components** (SCC): Follow edge directions
///
/// **Time Complexity:** O(V + E) where V is vertices and E is edges
/// **Space Complexity:** O(V) for the visited set
///
/// ## Example
///
/// ```gleam
/// import yog/connectivity
/// import yog/model.{Directed}
///
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "A")
///   |> model.add_node(2, "B")
///   |> model.add_node(3, "C")
///   |> model.add_edge(from: 1, to: 2, with: 1)
///   |> model.add_edge(from: 3, to: 2, with: 1)  // 1->2<-3
///
/// // SCCs: [[1], [2], [3]]  (no cycles)
/// let sccs = connectivity.strongly_connected_components(graph)
///
/// // WCCs: [[1, 2, 3]]  (weakly connected as undirected)
/// let wccs = connectivity.weakly_connected_components(graph)
/// ```
pub fn weakly_connected_components(graph: Graph(n, e)) -> List(Component) {
  let nodes = model.all_nodes(graph)
  do_weakly_connected_components(graph, nodes, set.new(), [])
}

fn do_weakly_connected_components(
  graph: Graph(n, e),
  nodes: List(NodeId),
  visited: Set(NodeId),
  components: List(Component),
) -> List(Component) {
  case nodes {
    [] -> components
    [node, ..rest] ->
      case set.contains(visited, node) {
        True -> do_weakly_connected_components(graph, rest, visited, components)
        False -> {
          let #(component, new_visited) =
            wcc_dfs_collect(graph, node, visited, [])
          do_weakly_connected_components(graph, rest, new_visited, [
            component,
            ..components
          ])
        }
      }
  }
}

fn wcc_dfs_collect(
  graph: Graph(n, e),
  node: NodeId,
  visited: Set(NodeId),
  component: List(NodeId),
) -> #(List(NodeId), Set(NodeId)) {
  case set.contains(visited, node) {
    True -> #(component, visited)
    False -> {
      let new_visited = set.insert(visited, node)
      let neighbors = model.neighbor_ids(graph, node)

      use #(comp, vis), neighbor <- list.fold(neighbors, #(
        [node, ..component],
        new_visited,
      ))
      wcc_dfs_collect(graph, neighbor, vis, comp)
    }
  }
}

// =============================================================================
// K-CORE DECOMPOSITION
// =============================================================================

/// Returns the maximal subgraph where every node has at least degree `k`.
///
/// A [k-core](https://en.wikipedia.org/wiki/Degeneracy_(graph_theory)) is obtained
/// by repeatedly removing all nodes with degree less than `k` until no such nodes
/// remain. It is useful for identifying the most resilient/connected part of a
/// network and for pruning peripheral nodes before expensive analysis.
///
/// ## Example
///
/// ```gleam
/// // A square (cycle of 4) has a 2-core containing all nodes, but no 3-core.
/// let core_2 = connectivity.k_core(graph, 2)
/// let core_3 = connectivity.k_core(graph, 3)
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn k_core(graph: Graph(n, e), k: Int) -> Graph(n, e) {
  let nodes = model.all_nodes(graph)
  let degrees = initial_degrees(graph, nodes)
  let to_prune =
    list.filter(nodes, fn(u) {
      case dict.get(degrees, u) {
        Ok(deg) -> deg < k
        Error(_) -> False
      }
    })
  let queue_set = set.from_list(to_prune)
  let pruned =
    do_prune_k_core(graph.out_edges, to_prune, queue_set, degrees, k, set.new())
  let remaining = set.difference(set.from_list(nodes), pruned) |> set.to_list
  transform.subgraph(graph, remaining)
}

fn initial_degrees(graph: Graph(n, e), nodes: List(NodeId)) -> Dict(NodeId, Int) {
  use acc, u <- list.fold(nodes, dict.new())
  let deg = case dict.get(graph.out_edges, u) {
    Ok(neighbors) -> dict.size(neighbors)
    Error(_) -> 0
  }
  dict.insert(acc, u, deg)
}

fn do_prune_k_core(
  out_edges: Dict(NodeId, Dict(NodeId, e)),
  queue: List(NodeId),
  queue_set: Set(NodeId),
  degrees: Dict(NodeId, Int),
  k: Int,
  pruned: Set(NodeId),
) -> Set(NodeId) {
  case queue {
    [] -> pruned
    [u, ..rest] -> {
      let queue_set = set.delete(queue_set, u)
      case set.contains(pruned, u) {
        True -> do_prune_k_core(out_edges, rest, queue_set, degrees, k, pruned)
        False -> {
          let new_pruned = set.insert(pruned, u)
          let neighbors = case dict.get(out_edges, u) {
            Ok(nbrs) -> dict.keys(nbrs)
            Error(_) -> []
          }
          let #(new_rest, new_queue_set, new_degrees) =
            list.fold(neighbors, #(rest, queue_set, degrees), fn(acc, v) {
              let #(acc_rest, acc_qs, acc_deg) = acc
              case set.contains(new_pruned, v) {
                True -> acc
                False -> {
                  let assert Ok(old_deg) = dict.get(acc_deg, v)
                  let new_deg = old_deg - 1
                  let acc_deg = dict.insert(acc_deg, v, new_deg)
                  case new_deg < k && !set.contains(acc_qs, v) {
                    True -> #([v, ..acc_rest], set.insert(acc_qs, v), acc_deg)
                    False -> #(acc_rest, acc_qs, acc_deg)
                  }
                }
              }
            })
          do_prune_k_core(
            out_edges,
            new_rest,
            new_queue_set,
            new_degrees,
            k,
            new_pruned,
          )
        }
      }
    }
  }
}

/// Returns the core number of every node.
///
/// The core number of a node is the largest `k` such that the node belongs to a
/// k-core. This is computed using the Batagelj–Zaversnik O(V + E) bucket
/// elimination algorithm.
///
/// ## Example
///
/// ```gleam
/// // In a triangle, every node has core number 2.
/// let cores = connectivity.core_numbers(triangle_graph)
/// // cores == dict.from_list([#(1, 2), #(2, 2), #(3, 2)])
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn core_numbers(graph: Graph(n, e)) -> Dict(NodeId, Int) {
  let nodes = model.all_nodes(graph)
  let degrees = initial_degrees(graph, nodes)
  let max_deg = case dict.values(degrees) {
    [] -> 0
    vals -> list.fold(vals, 0, int.max)
  }
  do_calculate_core_numbers(graph.out_edges, nodes, degrees, max_deg)
}

fn do_calculate_core_numbers(
  out_edges: Dict(NodeId, Dict(NodeId, e)),
  nodes: List(NodeId),
  degrees: Dict(NodeId, Int),
  max_deg: Int,
) -> Dict(NodeId, Int) {
  let buckets =
    list.fold(nodes, dict.new(), fn(acc, u) {
      let assert Ok(deg) = dict.get(degrees, u)
      let existing = case dict.get(acc, deg) {
        Ok(b) -> b
        Error(_) -> []
      }
      dict.insert(acc, deg, [u, ..existing])
    })

  let initial_state = #(degrees, dict.new(), buckets, set.new())

  let #(_, cores, _, _) =
    int.range(from: 0, to: max_deg + 1, with: initial_state, run: fn(state, i) {
      process_bucket(out_edges, i, state)
    })

  cores
}

fn process_bucket(
  out_edges: Dict(NodeId, Dict(NodeId, e)),
  i: Int,
  state: #(
    Dict(NodeId, Int),
    Dict(NodeId, Int),
    Dict(Int, List(NodeId)),
    Set(NodeId),
  ),
) -> #(
  Dict(NodeId, Int),
  Dict(NodeId, Int),
  Dict(Int, List(NodeId)),
  Set(NodeId),
) {
  let #(degs, cores, buckets, processed) = state
  case dict.get(buckets, i) {
    Error(_) -> state
    Ok([]) -> state
    Ok([u, ..rest]) -> {
      case set.contains(processed, u) {
        True ->
          process_bucket(out_edges, i, #(
            degs,
            cores,
            dict.insert(buckets, i, rest),
            processed,
          ))
        False -> {
          let cores = dict.insert(cores, u, i)
          let processed = set.insert(processed, u)
          let neighbors = case dict.get(out_edges, u) {
            Ok(nbrs) -> dict.keys(nbrs)
            Error(_) -> []
          }
          let #(new_degs, new_buckets) =
            list.fold(
              neighbors,
              #(degs, dict.insert(buckets, i, rest)),
              fn(acc, v) {
                let #(d_acc, b_acc) = acc
                case set.contains(processed, v) {
                  True -> acc
                  False -> {
                    let assert Ok(old_v_deg) = dict.get(d_acc, v)
                    let new_v_deg = old_v_deg - 1
                    let d_acc = dict.insert(d_acc, v, new_v_deg)
                    let target_bucket = int.max(new_v_deg, i)
                    let existing = case dict.get(b_acc, target_bucket) {
                      Ok(b) -> b
                      Error(_) -> []
                    }
                    let b_acc =
                      dict.insert(b_acc, target_bucket, [v, ..existing])
                    #(d_acc, b_acc)
                  }
                }
              },
            )
          process_bucket(out_edges, i, #(
            new_degs,
            cores,
            new_buckets,
            processed,
          ))
        }
      }
    }
  }
}

/// Returns the [degeneracy](https://en.wikipedia.org/wiki/Degeneracy_(graph_theory))
/// of the graph.
///
/// Degeneracy is the maximum core number found in the graph. It measures how
/// sparse or dense the graph is and provides an upper bound on many graph
/// parameters such as chromatic number.
///
/// **Time Complexity:** O(V + E)
pub fn degeneracy(graph: Graph(n, e)) -> Int {
  let cores = core_numbers(graph)
  case dict.values(cores) {
    [] -> 0
    vals -> list.fold(vals, 0, int.max)
  }
}

/// Groups nodes by their core number (k-shell decomposition).
///
/// A k-shell contains all nodes that have a core number of exactly `k`. This
/// decomposition is useful for visualising the layered structure of a network
/// and for identifying core-periphery patterns.
///
/// ## Example
///
/// ```gleam
/// // A star graph with 4 leaves has a 1-shell (the leaves) and no higher shells.
/// let shells = connectivity.shell_decomposition(star_graph)
/// // shells == dict.from_list([#(1, [2, 3, 4, 5])])
/// ```
///
/// **Time Complexity:** O(V + E)
pub fn shell_decomposition(graph: Graph(n, e)) -> Dict(Int, List(NodeId)) {
  use acc, node, core <- dict.fold(core_numbers(graph), dict.new())
  let existing = case dict.get(acc, core) {
    Ok(nodes) -> nodes
    Error(_) -> []
  }
  dict.insert(acc, core, [node, ..existing])
}
