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

/// Analyzes an **undirected graph** to find all bridges and articulation points
/// using Tarjan's algorithm in a single DFS pass.
///
/// **Important:** This algorithm is designed for undirected graphs. For directed
/// graphs, use strongly connected components analysis instead.
///
/// **Bridges** are edges whose removal increases the number of connected connectivity.
/// **Articulation points** (cut vertices) are nodes whose removal increases the number
/// of connected connectivity.
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

  let #(final_state, children) =
    list.fold(neighbors, #(state, 0), fn(acc, to) {
      let #(acc_state, children_count) = acc
      case parent {
        Some(parent_id) if to == parent_id -> acc
        _ -> {
          case set.contains(acc_state.visited, to) {
            True -> {
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
            False -> {
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
      }
    })

  // Special case: Root of DFS tree is an articulation point if it has > 1 child
  case parent, children > 1 {
    None, True ->
      InternalState(..final_state, points: set.insert(final_state.points, v))
    _, _ -> final_state
  }
}

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
  // Set the discovery index and low-link to the current index
  let state =
    TarjanState(
      ..state,
      indices: dict.insert(state.indices, u, state.index),
      low_links: dict.insert(state.low_links, u, state.index),
      index: state.index + 1,
      stack: [u, ..state.stack],
      on_stack: dict.insert(state.on_stack, u, True),
    )

  // Consider successors of u
  let successors = model.successor_ids(graph, u)

  let state =
    list.fold(successors, state, fn(st, v) {
      case dict.has_key(st.indices, v) {
        False -> {
          // Successor v has not yet been visited; recurse on it
          let st = strong_connect(graph, v, st)
          let u_low = dict.get(st.low_links, u) |> result.unwrap(0)
          let v_low = dict.get(st.low_links, v) |> result.unwrap(0)
          TarjanState(
            ..st,
            low_links: dict.insert(st.low_links, u, int.min(u_low, v_low)),
          )
        }
        True -> {
          case dict.get(st.on_stack, v) |> result.unwrap(False) {
            True -> {
              // Successor v is in stack and hence in the current SCC
              let u_low = dict.get(st.low_links, u) |> result.unwrap(0)
              let v_index = dict.get(st.indices, v) |> result.unwrap(0)
              TarjanState(
                ..st,
                low_links: dict.insert(st.low_links, u, int.min(u_low, v_index)),
              )
            }
            False -> st
          }
        }
      }
    })

  // If u is a root node, pop the stack and generate an SCC
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

  // First DFS: Compute finishing times
  let #(finish_stack, _) =
    list.fold(nodes, #([], set.new()), fn(acc, node) {
      let #(stack, visited) = acc
      first_dfs(graph, node, visited, stack)
    })

  // Transpose the graph (O(1) operation!)
  let transposed = transform.transpose(graph)

  // Second DFS: Process in reverse finishing time order on transposed graph
  let #(components, _) =
    list.fold(finish_stack, #([], set.new()), fn(acc, node) {
      let #(components, visited) = acc
      case set.contains(visited, node) {
        True -> acc
        False -> {
          let #(component, new_visited) =
            second_dfs(transposed, node, visited, [])
          #([component, ..components], new_visited)
        }
      }
    })

  components
}

// First DFS: Accumulate nodes in finishing time order
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

      // Visit all successors first
      let #(new_stack, final_visited) =
        list.fold(successors, #(stack, new_visited), fn(acc, succ) {
          let #(s, v) = acc
          first_dfs(graph, succ, v, s)
        })

      // Add current node to stack AFTER visiting all descendants (finishing time)
      #([node, ..new_stack], final_visited)
    }
  }
}

// Second DFS: Explore SCC on transposed graph
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

      // Visit all successors in the transposed graph
      list.fold(successors, #(new_component, new_visited), fn(acc, succ) {
        let #(comp, vis) = acc
        second_dfs(transposed, succ, vis, comp)
      })
    }
  }
}

// ============= Connected Components (Undirected Graphs) =============

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
///
/// ## Comparison with Other Component Types
///
/// | Function | Graph Type | Direction | Use Case |
/// |----------|------------|-----------|----------|
/// | `connected_components/1` | Undirected | N/A | Standard undirected connectivity |
/// | `weakly_connected_components/1` | Directed | Ignored | Directed graphs treated as undirected |
/// | `strongly_connected_components/1` | Directed | Followed | Maximum reachability following arrows |
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
    [node, ..rest] -> {
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

      list.fold(
        neighbors,
        #([node, ..component], new_visited),
        fn(acc, neighbor) {
          let #(comp, vis) = acc
          dfs_collect(graph, neighbor, vis, comp)
        },
      )
    }
  }
}

// ============= Weakly Connected Components (Directed Graphs) =============

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
///
/// ## Comparison with Other Component Types
///
/// | Function | Graph Type | Direction | Use Case |
/// |----------|------------|-----------|----------|
/// | `connected_components/1` | Undirected | N/A | Standard undirected connectivity |
/// | `weakly_connected_components/1` | Directed | Ignored | Directed graphs treated as undirected |
/// | `strongly_connected_components/1` | Directed | Followed | Maximum reachability following arrows |
///
/// ## Implementation Notes
///
/// This function uses `model.neighbors/2` which treats edges as undirected
/// by combining successors and predecessors for directed graphs. This is
/// more efficient than actually converting the graph to undirected form.
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
    [node, ..rest] -> {
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
      // Use neighbors() to treat edges as undirected
      let neighbors =
        model.neighbors(graph, node)
        |> list.map(fn(n) { n.0 })

      list.fold(
        neighbors,
        #([node, ..component], new_visited),
        fn(acc, neighbor) {
          let #(comp, vis) = acc
          wcc_dfs_collect(graph, neighbor, vis, comp)
        },
      )
    }
  }
}
