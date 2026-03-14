//// DOT (Graphviz) format export for visualizing graphs.
////
//// This module exports graphs to the [DOT language](https://graphviz.org/doc/info/lang.html),
//// which is the native format for [Graphviz](https://graphviz.org/) - a powerful open-source
//// graph visualization tool. The exported files can be rendered to PNG, SVG, PDF, and other
//// formats using the `dot`, `neato`, `circo`, or other Graphviz layout engines.
////
//// ## Quick Start
////
//// ```gleam
//// import yog/io/dot
////
//// // Export with default styling
//// let dot_string = dot.to_string(my_graph)
////
//// // Write to file and render with Graphviz CLI
//// // $ dot -Tpng output.dot -o graph.png
//// ```
////
//// ## Customization
////
//// Use `DotOptions` to customize:
//// - Node labels and shapes
//// - Edge labels and styles
//// - Highlight specific nodes or paths
//// - Graph direction (LR, TB, etc.)
////
//// ## Rendering Options
////
//// | Engine | Best For |
//// |--------|----------|
//// | `dot` | Hierarchical layouts (DAGs, trees) |
//// | `neato` | Spring-based layouts (undirected) |
//// | `circo` | Circular layouts |
//// | `fdp` | Force-directed layouts |
//// | `sfdp` | Large graphs |
////
//// ## References
////
//// - [Graphviz Documentation](https://graphviz.org/documentation/)
//// - [DOT Language Guide](https://graphviz.org/doc/info/lang.html)
//// - [Node Shapes](https://graphviz.org/doc/info/shapes.html)
//// - [Arrow Styles](https://graphviz.org/doc/info/arrows.html)

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding/utils.{type Path}

/// Options for customizing DOT (Graphviz) diagram rendering.
pub type DotOptions {
  DotOptions(
    /// Function to convert node ID and data to a display label
    node_label: fn(NodeId, String) -> String,
    /// Function to convert edge weight to a display label
    edge_label: fn(String) -> String,
    /// Optional list of node IDs to highlight
    highlighted_nodes: option.Option(List(NodeId)),
    /// Optional list of edges to highlight as (from, to) pairs
    highlighted_edges: option.Option(List(#(NodeId, NodeId))),
    /// Node shape (e.g., "circle", "box", "ellipse")
    node_shape: String,
    /// Highlight color for nodes/edges
    highlight_color: String,
  )
}

/// Creates default DOT options with simple labeling.
pub fn default_dot_options() -> DotOptions {
  DotOptions(
    node_label: fn(id, _data) { int.to_string(id) },
    edge_label: fn(weight) { weight },
    highlighted_nodes: None,
    highlighted_edges: None,
    node_shape: "ellipse",
    highlight_color: "red",
  )
}

/// Converts a graph to DOT (Graphviz) syntax.
///
/// The graph's node data and edge data must be convertible to strings.
/// Use the options to customize labels and highlighting.
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
///   |> model.add_edge(from: 1, to: 2, with: "5")
///
/// let diagram = dot.to_dot(graph, default_dot_options())
/// // io.println(diagram)
/// ```
///
/// This output can be processed by Graphviz tools (e.g., `dot -Tpng -o graph.png`):
/// ````dot
/// digraph G {
///   node [shape=ellipse];
///   1 [label="Start"];
///   2 [label="Process"];
///   1 -> 2 [label="5"];
/// }
/// ````
pub fn to_dot(graph: Graph(String, String), options: DotOptions) -> String {
  let graph_type = case graph.kind {
    Directed -> "digraph G {\n"
    Undirected -> "graph G {\n"
  }

  let base_node_style = "  node [shape=" <> options.node_shape <> "];\n"
  let base_edge_style = "  edge [fontname=\"Helvetica\", fontsize=10];\n"

  let nodes =
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      let label = options.node_label(id, data)
      let id_str = int.to_string(id)

      let mut_attrs = case options.highlighted_nodes {
        Some(highlighted) -> {
          case list.contains(highlighted, id) {
            True ->
              " fillcolor=\"" <> options.highlight_color <> "\", style=filled"
            False -> ""
          }
        }
        None -> ""
      }
      [
        "  " <> id_str <> " [label=\"" <> label <> "\"" <> mut_attrs <> "];",
        ..acc
      ]
    })
    |> string.join("\n")

  let edges =
    dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
      let inner_edges =
        dict.fold(targets, [], fn(inner_acc, to_id, weight) {
          // Handle undirected deduplication
          let is_valid = case graph.kind {
            Undirected -> from_id <= to_id
            Directed -> True
          }

          case is_valid {
            False -> inner_acc
            True -> {
              let connector = case graph.kind {
                Directed -> " -> "
                Undirected -> " -- "
              }

              let is_highlighted = case options.highlighted_edges {
                Some(highlighted) ->
                  list.contains(highlighted, #(from_id, to_id))
                  || list.contains(highlighted, #(to_id, from_id))
                None -> False
              }

              let mut_attrs = case is_highlighted {
                True ->
                  " color=\"" <> options.highlight_color <> "\", penwidth=2"
                False -> ""
              }

              let edge_def =
                "  "
                <> int.to_string(from_id)
                <> connector
                <> int.to_string(to_id)
                <> " [label=\""
                <> options.edge_label(weight)
                <> "\""
                <> mut_attrs
                <> "];"
              [edge_def, ..inner_acc]
            }
          }
        })
      list.flatten([inner_edges, acc])
    })
    |> string.join("\n")

  graph_type
  <> base_node_style
  <> base_edge_style
  <> nodes
  <> "\n"
  <> edges
  <> "\n}"
}

/// Converts a shortest path result to highlighted DOT options.
///
/// ## Example
///
/// ```gleam
/// let path = pathfinding.shortest_path(
///   in: graph,
///   from: 1,
///   to: 5,
///   with_zero: "0",
///   with_add: string_add, // Assume these exist or map to int/float
///   with_compare: string_compare,
/// )
///
/// case path {
///   Some(p) -> {
///     let options = dot.path_to_dot_options(p, default_dot_options())
///     let diagram = dot.to_dot(graph, options)
///     io.println(diagram)
///   }
///   None -> io.println("No path found")
/// }
/// ```
pub fn path_to_dot_options(
  path: Path(e),
  base_options: DotOptions,
) -> DotOptions {
  let nodes = path.nodes
  let edges = path_to_edges(nodes)

  DotOptions(
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
