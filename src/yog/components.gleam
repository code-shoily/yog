import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import yog/model.{type Graph, type NodeId}

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
