import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import yog/model.{type Graph, type NodeId}
import yog/transform

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
/// let sccs = components.kosaraju(graph)
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
