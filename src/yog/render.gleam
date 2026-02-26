import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding

/// Options for customizing Mermaid diagram rendering.
pub type MermaidOptions {
  MermaidOptions(
    /// Function to convert node ID and data to a display label
    node_label: fn(NodeId, String) -> String,
    /// Function to convert edge weight to a display label
    edge_label: fn(String) -> String,
    /// Optional list of node IDs to highlight (e.g., a path)
    highlighted_nodes: option.Option(List(NodeId)),
    /// Optional list of edges to highlight as (from, to) pairs
    highlighted_edges: option.Option(List(#(NodeId, NodeId))),
  )
}

/// Creates default Mermaid options with simple labeling.
///
/// Uses node ID as label and edge weight as-is.
pub fn default_options() -> MermaidOptions {
  MermaidOptions(
    node_label: fn(id, _data) { int.to_string(id) },
    edge_label: fn(weight) { weight },
    highlighted_nodes: None,
    highlighted_edges: None,
  )
}

/// Converts a graph to Mermaid diagram syntax.
///
/// The graph's node data and edge data must be convertible to strings.
/// Use the options to customize labels and highlight specific paths.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// let graph =
///   model.new(Directed)
///   |> model.add_node(1, "Start")
///   |> model.add_node(2, "Process")
///   |> model.add_node(3, "End")
///   |> model.add_edge(from: 1, to: 2, with: "5")
///   |> model.add_edge(from: 2, to: 3, with: "3")
///
/// // Basic rendering
/// let diagram = render.to_mermaid(graph, default_options())
///
/// // Highlight a path
/// let options = MermaidOptions(
///   ..default_options(),
///   highlighted_nodes: Some([1, 2, 3]),
///   highlighted_edges: Some([#(1, 2), #(2, 3)]),
/// )
/// let highlighted = render.to_mermaid(graph, options)
/// ```
///
/// The output can be embedded in markdown:
/// ````markdown
/// ```mermaid
/// graph TD
///   1["Start"]
///   2["Process"]
///   3["End"]
///   1 -->|5| 2
///   2 -->|3| 3
/// ```
/// ````
pub fn to_mermaid(
  graph: Graph(String, String),
  options: MermaidOptions,
) -> String {
  // Graph type and direction
  let graph_type = case graph.kind {
    Directed -> "graph TD\n"
    Undirected -> "graph LR\n"
  }

  // Style definitions for highlighting
  let styles = case options.highlighted_nodes, options.highlighted_edges {
    Some(_), _ | _, Some(_) ->
      "  classDef highlight fill:#ffeb3b,stroke:#f57c00,stroke-width:3px\n"
      <> "  classDef highlightEdge stroke:#f57c00,stroke-width:3px\n"
    None, None -> ""
  }

  // Generate node declarations
  let nodes =
    dict.to_list(graph.nodes)
    |> list.map(fn(pair) {
      let #(id, data) = pair
      let label = options.node_label(id, data)
      let node_def = "  " <> int.to_string(id) <> "[\"" <> label <> "\"]"

      // Add highlight class if this node is in the highlighted list
      case options.highlighted_nodes {
        Some(highlighted) ->
          case list.contains(highlighted, id) {
            True -> node_def <> ":::highlight"
            False -> node_def
          }
        None -> node_def
      }
    })
    |> string.join("\n")

  // Generate edge declarations
  let edges =
    dict.to_list(graph.out_edges)
    |> list.flat_map(fn(pair) {
      let #(from_id, targets) = pair
      dict.to_list(targets)
      |> list.filter_map(fn(target) {
        let #(to_id, weight) = target

        // For undirected graphs, only render each edge once (when from_id <= to_id)
        // This prevents showing the same edge twice (once from each direction)
        case graph.kind {
          Undirected if from_id > to_id -> Error(Nil)
          _ -> {
            // Choose arrow style based on graph type
            let arrow = case graph.kind {
              Directed -> "-->"
              Undirected -> "---"
            }

            // Check if this edge should be highlighted
            let is_highlighted = case options.highlighted_edges {
              Some(edges) ->
                list.contains(edges, #(from_id, to_id))
                || list.contains(edges, #(to_id, from_id))
              None -> False
            }

            let edge_def =
              "  "
              <> int.to_string(from_id)
              <> " "
              <> arrow
              <> "|"
              <> options.edge_label(weight)
              <> "| "
              <> int.to_string(to_id)

            case is_highlighted {
              True -> Ok(edge_def <> ":::highlightEdge")
              False -> Ok(edge_def)
            }
          }
        }
      })
    })
    |> string.join("\n")

  graph_type <> styles <> nodes <> "\n" <> edges
}

/// Converts a shortest path result to highlighted Mermaid options.
///
/// Useful for visualizing pathfinding algorithm results.
///
/// ## Example
///
/// ```gleam
/// let path = pathfinding.shortest_path(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: "0",
///   with_add: string_add,
///   with_compare: string_compare,
/// )
///
/// case path {
///   Some(p) -> {
///     let options = render.path_to_options(p, default_options())
///     let diagram = render.to_mermaid(graph, options)
///     io.println(diagram)
///   }
///   None -> io.println("No path found")
/// }
/// ```
pub fn path_to_options(
  path: pathfinding.Path(e),
  base_options: MermaidOptions,
) -> MermaidOptions {
  let nodes = path.nodes
  let edges = path_to_edges(nodes)

  MermaidOptions(
    ..base_options,
    highlighted_nodes: Some(nodes),
    highlighted_edges: Some(edges),
  )
}

// Helper to convert a list of nodes to a list of edges
fn path_to_edges(nodes: List(NodeId)) -> List(#(NodeId, NodeId)) {
  case nodes {
    [] | [_] -> []
    [first, second, ..rest] -> [
      #(first, second),
      ..path_to_edges([second, ..rest])
    ]
  }
}
