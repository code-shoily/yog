//// Mermaid diagram export for Markdown-compatible graph visualization.
////
//// This module exports graphs to [Mermaid](https://mermaid.js.org/) syntax,
//// allowing you to embed graphs directly in Markdown documents, GitHub READMEs,
//// Notion pages, and other platforms that support Mermaid rendering.
////
//// ## Quick Start
////
//// ```gleam
//// import yog/io/mermaid
////
//// let diagram = mermaid.to_string(my_graph)
//// // Paste into Markdown:
//// // ```mermaid
//// // graph TD
//// //   1 --> 2
//// // ```
//// ```
////
//// ## Customization
////
//// Use `MermaidOptions` to:
//// - Add custom node labels
//// - Display edge weights
//// - Highlight specific nodes or paths
//// - Style important elements
////
//// ## References
////
//// - [Mermaid Syntax](https://mermaid.js.org/syntax/flowchart.html)
//// - [GitHub Mermaid Docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams)

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding/utils.{type Path}

// =============================================================================
// TYPES
// =============================================================================

/// Direction for graph layout
pub type Direction {
  /// Top-Down (vertical, top to bottom) - Mermaid "TD" or "TB"
  TD
  /// Left-Right (horizontal)
  LR
  /// Bottom-Top (vertical, bottom to top)
  BT
  /// Right-Left (horizontal, right to left)
  RL
}

/// Node shape options for Mermaid diagrams.
pub type NodeShape {
  /// Rectangle with rounded corners: [label]
  RoundedRect
  /// Stadium shape (pill): ([label])
  Stadium
  /// Subroutine shape (rectangle with side lines): [[label]]
  Subroutine
  /// Cylindrical shape (database): [(label)]
  Cylinder
  /// Circle: ((label))
  Circle
  /// Asymmetric shape (flag): >label]
  Asymmetric
  /// Rhombus (decision): {label}
  Rhombus
  /// Hexagon: {{label}}
  Hexagon
  /// Parallelogram: [/label/]
  Parallelogram
  /// Parallelogram alt: [\label\]
  ParallelogramAlt
  /// Trapezoid: [/label\]
  Trapezoid
  /// Trapezoid alt: [\label/]
  TrapezoidAlt
}

/// CSS length unit for styling
pub type CssLength {
  /// Pixels (most common)
  Px(Int)
  /// Ems (relative to font size)
  Em(Float)
  /// Rems (relative to root font size)
  Rem(Float)
  /// Percentage
  Percent(Float)
  /// Custom CSS value (for advanced users)
  CustomCss(String)
}

// =============================================================================
// OPTIONS
// =============================================================================

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
    // Graph-level attributes
    /// Graph direction (default: TD)
    direction: Direction,
    // Node styling
    /// Node shape (default: RoundedRect)
    node_shape: NodeShape,
    /// Highlight fill color (CSS color, default: #ffeb3b)
    highlight_fill: String,
    /// Highlight stroke color (CSS color, default: #f57c00)
    highlight_stroke: String,
    /// Highlight stroke width (default: Px(3))
    highlight_stroke_width: CssLength,
    // Edge styling
    /// Default link thickness (default: Px(2))
    link_thickness: CssLength,
    /// Highlighted link stroke color (default: #f57c00)
    highlight_link_stroke: String,
    /// Highlighted link stroke width (default: Px(3))
    highlight_link_stroke_width: CssLength,
  )
}

/// Creates default Mermaid options with simple labeling.
///
/// Uses node ID as label and edge weight as-is.
/// Default configuration:
/// - Direction: Top-to-bottom (TD)
/// - Node shape: Rounded rectangle
/// - Highlight: Yellow fill with orange stroke
pub fn default_options() -> MermaidOptions {
  MermaidOptions(
    node_label: fn(id, _data) { int.to_string(id) },
    edge_label: fn(weight) { weight },
    highlighted_nodes: None,
    highlighted_edges: None,
    // Graph-level
    direction: TD,
    // Node styling
    node_shape: RoundedRect,
    highlight_fill: "#ffeb3b",
    highlight_stroke: "#f57c00",
    highlight_stroke_width: Px(3),
    // Edge styling
    link_thickness: Px(2),
    highlight_link_stroke: "#f57c00",
    highlight_link_stroke_width: Px(3),
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
  let graph_type = "graph " <> direction_to_string(options.direction) <> "\n"

  // Style definitions for highlighting
  let styles = case options.highlighted_nodes, options.highlighted_edges {
    Some(_), _ | _, Some(_) -> {
      let node_highlight =
        "  classDef highlight fill:"
        <> options.highlight_fill
        <> ",stroke:"
        <> options.highlight_stroke
        <> ",stroke-width:"
        <> css_length_to_string(options.highlight_stroke_width)
        <> "\n"
      let edge_highlight =
        "  classDef highlightEdge stroke:"
        <> options.highlight_link_stroke
        <> ",stroke-width:"
        <> css_length_to_string(options.highlight_link_stroke_width)
        <> "\n"
      node_highlight <> edge_highlight
    }
    None, None -> ""
  }

  // Generate node declarations
  let nodes =
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      let label = options.node_label(id, data)
      let node_def =
        "  "
        <> int.to_string(id)
        <> node_shape_brackets(options.node_shape, label)

      // Add highlight class if this node is in the highlighted list
      let node_with_highlight = case options.highlighted_nodes {
        Some(highlighted) ->
          case list.contains(highlighted, id) {
            True -> node_def <> ":::highlight"
            False -> node_def
          }
        None -> node_def
      }
      [node_with_highlight, ..acc]
    })
    |> string.join("\n")

  // Generate edge declarations
  let edges =
    dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
      let inner_edges =
        dict.fold(targets, [], fn(inner_acc, to_id, weight) {
          // For undirected graphs, only render each edge once (when from_id <= to_id)
          // This prevents showing the same edge twice (once from each direction)
          case graph.kind {
            Undirected if from_id > to_id -> inner_acc
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

              let edge_with_highlight = case is_highlighted {
                True -> edge_def <> ":::highlightEdge"
                False -> edge_def
              }
              [edge_with_highlight, ..inner_acc]
            }
          }
        })
      list.flatten([inner_edges, acc])
    })
    |> string.join("\n")

  graph_type <> styles <> nodes <> "\n" <> edges
}

/// Converts a shortest path result to highlighted Mermaid options.
pub fn path_to_options(
  path: Path(e),
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

// =============================================================================
// HELPERS
// =============================================================================

/// Convert Direction to Mermaid string
fn direction_to_string(dir: Direction) -> String {
  case dir {
    TD -> "TD"
    LR -> "LR"
    BT -> "BT"
    RL -> "RL"
  }
}

/// Convert CssLength to CSS string
fn css_length_to_string(length: CssLength) -> String {
  case length {
    Px(n) -> int.to_string(n) <> "px"
    Em(f) -> float.to_string(f) <> "em"
    Rem(f) -> float.to_string(f) <> "rem"
    Percent(f) -> float.to_string(f) <> "%"
    CustomCss(s) -> s
  }
}

/// Helper to convert NodeShape to Mermaid bracket syntax
fn node_shape_brackets(shape: NodeShape, label: String) -> String {
  case shape {
    RoundedRect -> "[\"" <> label <> "\"]"
    Stadium -> "([\"" <> label <> "\"])"
    Subroutine -> "[[\"" <> label <> "\"]]"
    Cylinder -> "[(\"" <> label <> "\")]"
    Circle -> "((\"" <> label <> "\"))"
    Asymmetric -> ">\"" <> label <> "\"]"
    Rhombus -> "{\"" <> label <> "\"}"
    Hexagon -> "{{\"" <> label <> "\"}}"
    Parallelogram -> "[/\"" <> label <> "\"/]"
    ParallelogramAlt -> "[\\\"" <> label <> "\"\\]"
    Trapezoid -> "[/\"" <> label <> "\"\\]"
    TrapezoidAlt -> "[\\\"" <> label <> "\"/]"
  }
}
