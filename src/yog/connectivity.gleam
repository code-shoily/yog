import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}

/// Represents a bridge (critical edge) in an undirected graph.
/// Bridges are stored as ordered pairs where the first node ID is smaller.
pub type Bridge =
  #(NodeId, NodeId)

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
