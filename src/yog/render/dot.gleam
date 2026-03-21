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
//// import yog/render/dot
////
//// // Export with default styling
//// let dot_string = dot.to_dot(my_graph, dot.default_dot_options())
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
//// - **Per-node and per-edge attributes** (custom colors, shapes, etc.)
//// - **Subgraphs/clusters** for visual grouping
//// - Highlight specific nodes or paths
//// - Graph direction (LR, TB, etc.)
////
//// ## Generic Data Types
////
//// The `to_dot` function works with any node and edge data types. Use 
//// `default_dot_options_with_edge_formatter()` when your edge data is not a String:
////
//// ```gleam
//// let options = dot.default_dot_options_with_edge_formatter(fn(weight) {
////   int.to_string(weight)
//// })
//// let dot_string = dot.to_dot(my_int_weighted_graph, options)
//// ```
////
//// ## Per-Element Styling
////
//// Provide custom attribute functions for fine-grained control:
////
//// ```gleam
//// let options = DotOptions(
////   ..dot.default_dot_options(),
////   node_attributes: fn(id, data) {
////     case id {
////       1 -> [("fillcolor", "green"), ("shape", "diamond")]
////       _ -> []
////     }
////   },
////   edge_attributes: fn(from, to, weight) {
////     case weight > 10 {
////       True -> [("color", "red"), ("penwidth", "2")]
////       False -> []
////     }
////   },
//// )
//// ```
////
//// ## Subgraphs and Clusters
////
//// Group nodes visually using subgraphs:
////
//// ```gleam
//// let options = DotOptions(
////   ..dot.default_dot_options(),
////   subgraphs: Some([
////     Subgraph(
////       name: "cluster_0",
////       label: Some("Cluster A"),
////       node_ids: [1, 2, 3],
////       style: Some(dot.Filled),
////       fillcolor: Some("lightgrey"),
////       color: None,
////     ),
////   ]),
//// )
//// ```
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
//// - [Cluster/Subgraph Syntax](https://graphviz.org/docs/attrs/cluster/)

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import yog/model.{type Graph, type NodeId, Directed, Undirected}
import yog/pathfinding/utils.{type Path}

// =============================================================================
// SUBGRAPH TYPE
// =============================================================================

/// A subgraph (cluster) for grouping nodes visually in the diagram.
///
/// In Graphviz, subgraphs with names starting with "cluster_" are rendered
/// as bounded rectangles around the contained nodes. This is useful for:
/// - Visualizing communities or partitions
/// - Grouping related nodes
/// - Highlighting logical components
///
/// ## Example
///
/// ```gleam
/// Subgraph(
///   name: "cluster_0",
///   label: Some("Module A"),
///   node_ids: [1, 2, 3],
///   style: Some(dot.Filled),
///   fillcolor: Some("lightblue"),
///   color: Some("blue"),
/// )
/// ```
pub type Subgraph {
  Subgraph(
    /// Subgraph name. Use "cluster_" prefix for visual clustering.
    name: String,
    /// Optional label displayed at the top of the subgraph.
    label: Option(String),
    /// List of node IDs to include in this subgraph.
    node_ids: List(NodeId),
    /// Optional style for the subgraph boundary.
    style: Option(Style),
    /// Optional fill color for the subgraph background.
    fillcolor: Option(String),
    /// Optional border color for the subgraph.
    color: Option(String),
  )
}

// =============================================================================
// TYPES
// =============================================================================

/// Graphviz layout engine
pub type Layout {
  /// Hierarchical layouts (DAGs, trees) - default for most use cases
  Dot
  /// Spring-based layouts (undirected graphs)
  Neato
  /// Circular layouts
  Circo
  /// Force-directed placement
  Fdp
  /// Scalable force-directed (for large graphs)
  Sfdp
  /// Radial layouts
  Twopi
  /// Clustered layouts (array-based)
  Osage
  /// Custom layout engine
  CustomLayout(String)
}

/// Graph direction (rank direction)
pub type RankDir {
  /// Top to Bottom (vertical, downward)
  TopToBottom
  /// Left to Right (horizontal)
  LeftToRight
  /// Bottom to Top (vertical, upward)
  BottomToTop
  /// Right to Left (horizontal, reversed)
  RightToLeft
}

/// Node shapes
pub type NodeShape {
  Box
  Circle
  Ellipse
  Diamond
  Hexagon
  Pentagon
  Octagon
  Triangle
  Rectangle
  Square
  /// Rounded rectangle
  Rect
  /// Inverted triangle
  InvTriangle
  /// House shape (pentagon with flat top)
  House
  /// Inverted house
  InvHouse
  /// Parallelogram
  Parallelogram
  /// Trapezoid
  Trapezoid
  /// Custom shape (for advanced Graphviz shapes)
  CustomShape(String)
}

/// Visual style
pub type Style {
  Solid
  Dashed
  Dotted
  Bold
  Filled
  Rounded
  Diagonals
  Striped
  Wedged
}

/// Edge routing style
pub type Splines {
  /// Straight lines
  Line
  /// Polyline (bent lines)
  Polyline
  /// Curved edges
  Curved
  /// Orthogonal (right angles only)
  Ortho
  /// Bezier splines (smooth curves) - Graphviz default
  Spline
  /// No edges
  SplinesNone
}

/// Arrow head/tail style
pub type ArrowStyle {
  /// Standard arrow
  Normal
  /// Dot circle
  ArrowDot
  /// Filled diamond
  ArrowDiamond
  /// Empty diamond
  ODiamond
  /// ArrowBox
  ArrowBox
  /// Crow's foot (database notation)
  Crow
  /// V-shaped
  Vee
  /// Inverted V
  Inv
  /// Tee (perpendicular line)
  Tee
  /// No arrow
  ArrowNone
  /// Custom arrow (e.g., "ediamond", "odot")
  CustomArrow(String)
}

/// Overlap handling
pub type Overlap {
  /// Allow overlaps (faster)
  OverlapTrue
  /// Remove all overlaps (slower)
  OverlapFalse
  /// Scale graph to remove overlaps
  Scale
  /// Scale x and y independently
  ScaleXY
  /// Prism algorithm (Voronoi-based)
  Prism
  /// Custom overlap mode
  CustomOverlap(String)
}

// =============================================================================
// OPTIONS
// =============================================================================

/// Options for customizing DOT (Graphviz) diagram rendering.
///
/// This type is generic over node data `n` and edge data `e`, allowing it to work
/// with graphs of any data types. Use `default_dot_options()` for String edge
/// data, or `default_dot_options_with_edge_formatter()` for custom edge types.
///
/// ## Per-Element Styling
///
/// Use `node_attributes` and `edge_attributes` to set custom DOT attributes
/// for individual nodes and edges. These functions receive the node/edge data
/// and should return a list of #(attribute_name, attribute_value) pairs.
///
/// Common node attributes: "fillcolor", "shape", "width", "height", "penwidth"
/// Common edge attributes: "color", "penwidth", "style", "arrowhead", "constraint"
///
pub type DotOptions(n, e) {
  DotOptions(
    /// Function to convert node ID and data to a display label
    node_label: fn(NodeId, n) -> String,
    /// Function to convert edge data to a display label
    edge_label: fn(e) -> String,
    /// Optional list of node IDs to highlight
    highlighted_nodes: Option(List(NodeId)),
    /// Optional list of edges to highlight as (from, to) pairs
    highlighted_edges: Option(List(#(NodeId, NodeId))),
    // Per-element styling (NEW)
    /// Function to provide custom DOT attributes for each node.
    /// Returns list of #(attribute_name, attribute_value) pairs.
    /// These attributes override any defaults or highlighting.
    node_attributes: fn(NodeId, n) -> List(#(String, String)),
    /// Function to provide custom DOT attributes for each edge.
    /// Returns list of #(attribute_name, attribute_value) pairs.
    /// These attributes override any defaults or highlighting.
    edge_attributes: fn(NodeId, NodeId, e) -> List(#(String, String)),
    // Subgraphs (NEW)
    /// Optional list of subgraphs/clusters for visual node grouping.
    subgraphs: Option(List(Subgraph)),
    // Graph-level attributes
    /// Graph name (default: "G")
    graph_name: String,
    /// Layout engine (default: None = auto-detect)
    layout: Option(Layout),
    /// Graph direction (default: Some(TopToBottom))
    rankdir: Option(RankDir),
    /// Background color (CSS color, default: None)
    bgcolor: Option(String),
    /// Edge routing (default: None = Graphviz default)
    splines: Option(Splines),
    /// Overlap handling (default: None)
    overlap: Option(Overlap),
    /// Minimum space between nodes in inches (default: 0.25)
    nodesep: Option(Float),
    /// Minimum space between ranks in inches (default: 0.5)
    ranksep: Option(Float),
    // Node styling
    /// Node shape (default: Ellipse)
    node_shape: NodeShape,
    /// Default node fill color (CSS color)
    node_color: String,
    /// Node style (default: Filled)
    node_style: Style,
    /// Node font name (default: "Helvetica")
    node_fontname: String,
    /// Node font size in points (default: 12)
    node_fontsize: Int,
    /// Node font color (CSS color, default: "black")
    node_fontcolor: String,
    // Edge styling
    /// Default edge color (CSS color, default: "black")
    edge_color: String,
    /// Edge style (default: Solid)
    edge_style: Style,
    /// Edge font name (default: "Helvetica")
    edge_fontname: String,
    /// Edge font size in points (default: 10)
    edge_fontsize: Int,
    /// Edge line thickness (default: 1.0)
    edge_penwidth: Float,
    /// Arrow head style (default: None = Graphviz default)
    arrowhead: Option(ArrowStyle),
    /// Arrow tail style (default: None)
    arrowtail: Option(ArrowStyle),
    // Highlighting
    /// Highlight color for nodes/edges (CSS color, default: "red")
    highlight_color: String,
    /// Highlight pen width (default: 2.0)
    highlight_penwidth: Float,
  )
}

/// Creates default DOT options with simple labeling and sensible styling.
///
/// Default configuration:
/// - Layout: Auto-detected by Graphviz
/// - Direction: Top-to-bottom
/// - Node shape: Ellipse
/// - Colors: Light blue nodes, black edges
/// - Font: Helvetica 12pt
///
/// **Note:** This function returns `DotOptions(n, String)`, meaning it works
/// with any node data type (node labels use the ID only) but requires edge
/// data to be `String`. For other edge types, use
/// `default_dot_options_with_edge_formatter()`.
///
/// ## Example
///
/// ```gleam
/// let options = dot.default_dot_options()
/// let dot_string = dot.to_dot(my_string_graph, options)
/// ```
pub fn default_dot_options() -> DotOptions(n, String) {
  create_dot_options(
    node_label: fn(id, _data) { int.to_string(id) },
    edge_label: fn(weight) { weight },
  )
}

/// Creates default DOT options with a custom edge formatter.
///
/// Use this when your graph has non-String edge data (e.g., Int, Float, custom types).
/// The provided formatter function converts edge data to strings for display.
///
/// ## Example
///
/// ```gleam
/// // For a graph with Int edge weights
/// let options = dot.default_dot_options_with_edge_formatter(fn(weight) {
///   int.to_string(weight)
/// })
///
/// // For a graph with custom edge data
/// let options = dot.default_dot_options_with_edge_formatter(fn(edge_data) {
///   edge_data.name <> ": " <> float.to_string(edge_data.weight)
/// })
/// ```
pub fn default_dot_options_with_edge_formatter(
  edge_formatter: fn(e) -> String,
) -> DotOptions(n, e) {
  create_dot_options(
    node_label: fn(id, _data) { int.to_string(id) },
    edge_label: edge_formatter,
  )
}

/// Creates default DOT options with custom label formatters for both nodes and edges.
///
/// Use this when you need full control over how both node and edge data are displayed.
///
/// ## Example
///
/// ```gleam
/// let options = dot.default_dot_options_with(
///   node_label: fn(id, data) { data.name <> " (" <> int.to_string(id) <> ")" },
///   edge_label: fn(weight) { int.to_string(weight) <> " ms" },
/// )
/// ```
pub fn default_dot_options_with(
  node_label node_label: fn(NodeId, n) -> String,
  edge_label edge_label: fn(e) -> String,
) -> DotOptions(n, e) {
  create_dot_options(node_label:, edge_label:)
}

// Private helper to create options with the common defaults
fn create_dot_options(
  node_label node_label: fn(NodeId, n) -> String,
  edge_label edge_label: fn(e) -> String,
) -> DotOptions(n, e) {
  DotOptions(
    node_label: node_label,
    edge_label: edge_label,
    highlighted_nodes: None,
    highlighted_edges: None,
    // Per-element styling defaults (no custom attributes)
    node_attributes: fn(_, _) { [] },
    edge_attributes: fn(_, _, _) { [] },
    // Subgraphs default to none
    subgraphs: None,
    // Graph-level
    graph_name: "G",
    layout: None,
    rankdir: Some(TopToBottom),
    bgcolor: None,
    splines: None,
    overlap: None,
    nodesep: None,
    ranksep: None,
    // Node styling
    node_shape: Ellipse,
    node_color: "lightblue",
    node_style: Filled,
    node_fontname: "Helvetica",
    node_fontsize: 12,
    node_fontcolor: "black",
    // Edge styling
    edge_color: "black",
    edge_style: Solid,
    edge_fontname: "Helvetica",
    edge_fontsize: 10,
    edge_penwidth: 1.0,
    arrowhead: None,
    arrowtail: None,
    // Highlighting
    highlight_color: "red",
    highlight_penwidth: 2.0,
  )
}

/// Converts a graph to DOT (Graphviz) syntax.
///
/// Works with any node data type `n` and edge data type `e`. Use the options
/// to customize labels, styling, and to define subgraphs. Use
/// `default_dot_options()` or `default_dot_options_with_edge_formatter()` to
/// create appropriate options for your graph.
///
/// **Time Complexity:** O(V + E + S) where S is the total number of nodes
/// across all subgraphs.
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
/// let diagram = dot.to_dot(graph, dot.default_dot_options())
/// // io.println(diagram)
/// ```
///
/// ## Custom Styling Example
///
/// ```gleam
/// let options = DotOptions(
///   ..dot.default_dot_options(),
///   node_attributes: fn(id, data) {
///     case id {
///       1 -> [("fillcolor", "green"), ("shape", "diamond")]
///       _ -> []
///     }
///   },
///   subgraphs: Some([
///     Subgraph(name: "cluster_0", label: Some("Group A"), node_ids: [1, 2]),
///   ]),
/// )
/// ```
///
/// This output can be processed by Graphviz tools (e.g., `dot -Tpng -o graph.png`):
/// ````dot
/// digraph G {
///   node [shape=ellipse];
///   1 [label="Start"];
///   2 [label="Process"];
///   subgraph cluster_0 {
///     label="Group A";
///     1; 2;
///   }
///   1 -> 2 [label="5"];
/// }
/// ````
pub fn to_dot(graph: Graph(n, e), options: DotOptions(n, e)) -> String {
  let graph_type = case graph.kind {
    Directed -> "digraph " <> options.graph_name <> " {\n"
    Undirected -> "graph " <> options.graph_name <> " {\n"
  }

  // Build graph-level attributes
  let graph_attrs =
    [
      option.map(options.layout, fn(v) { "layout=" <> layout_to_string(v) }),
      option.map(options.rankdir, fn(v) { "rankdir=" <> rankdir_to_string(v) }),
      option.map(options.bgcolor, fn(v) { "bgcolor=\"" <> v <> "\"" }),
      option.map(options.splines, fn(v) { "splines=" <> splines_to_string(v) }),
      option.map(options.overlap, fn(v) { "overlap=" <> overlap_to_string(v) }),
      option.map(options.nodesep, fn(v) { "nodesep=" <> float.to_string(v) }),
      option.map(options.ranksep, fn(v) { "ranksep=" <> float.to_string(v) }),
    ]
    |> list.filter_map(fn(opt) {
      case opt {
        Some(attr) -> Ok(attr)
        None -> Error(Nil)
      }
    })

  let graph_attr_line = case graph_attrs {
    [] -> ""
    attrs -> "  graph [" <> string.join(attrs, ", ") <> "];\n"
  }

  // Build node default style
  let node_attrs = [
    "shape=" <> node_shape_to_string(options.node_shape),
    "style=" <> style_to_string(options.node_style),
    "fillcolor=\"" <> options.node_color <> "\"",
    "fontname=\"" <> options.node_fontname <> "\"",
    "fontsize=" <> int.to_string(options.node_fontsize),
    "fontcolor=\"" <> options.node_fontcolor <> "\"",
  ]
  let base_node_style = "  node [" <> string.join(node_attrs, ", ") <> "];\n"

  // Build edge default style
  let edge_attrs = [
    "color=\"" <> options.edge_color <> "\"",
    "style=" <> style_to_string(options.edge_style),
    "fontname=\"" <> options.edge_fontname <> "\"",
    "fontsize=" <> int.to_string(options.edge_fontsize),
    "penwidth=" <> float.to_string(options.edge_penwidth),
  ]
  let edge_attrs_with_arrows = case options.arrowhead, options.arrowtail {
    Some(head), Some(tail) -> [
      "arrowhead=" <> arrow_style_to_string(head),
      "arrowtail=" <> arrow_style_to_string(tail),
      ..edge_attrs
    ]
    Some(head), None -> [
      "arrowhead=" <> arrow_style_to_string(head),
      ..edge_attrs
    ]
    None, Some(tail) -> [
      "arrowtail=" <> arrow_style_to_string(tail),
      ..edge_attrs
    ]
    None, None -> edge_attrs
  }
  let base_edge_style =
    "  edge [" <> string.join(edge_attrs_with_arrows, ", ") <> "];\n"

  // Generate nodes with per-element attributes
  let nodes =
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      let label = options.node_label(id, data)
      let id_str = int.to_string(id)

      // Build attribute list starting with label
      let attrs = [#("label", label)]

      // Add highlighting if applicable
      let attrs = case options.highlighted_nodes {
        Some(highlighted) -> {
          case list.contains(highlighted, id) {
            True -> [#("fillcolor", options.highlight_color), ..attrs]
            False -> attrs
          }
        }
        None -> attrs
      }

      // Merge custom attributes (these override highlighting and defaults)
      let custom_attrs = options.node_attributes(id, data)
      let attrs = merge_attributes_list(attrs, custom_attrs)

      // Format attributes
      let attr_str = format_attributes_list(attrs)

      ["  " <> id_str <> " [" <> attr_str <> "];", ..acc]
    })
    |> string.join("\n")

  // Generate subgraphs
  let subgraphs_str = case options.subgraphs {
    None -> ""
    Some(subgraph_list) -> {
      list.map(subgraph_list, fn(sub) {
        let header = "  subgraph " <> sub.name <> " {\n"

        let label = case sub.label {
          Some(l) -> "    label=\"" <> l <> "\";\n"
          None -> ""
        }

        let style = case sub.style {
          Some(s) -> "    style=" <> style_to_string(s) <> ";\n"
          None -> ""
        }

        let fillcolor = case sub.fillcolor {
          Some(f) -> "    fillcolor=\"" <> f <> "\";\n"
          None -> ""
        }

        let color = case sub.color {
          Some(c) -> "    color=\"" <> c <> "\";\n"
          None -> ""
        }

        let node_list = case sub.node_ids {
          [] -> ""
          ids ->
            ids
            |> list.map(fn(id) { "    " <> int.to_string(id) })
            |> string.join(";\n")
            <> ";\n"
        }

        header <> label <> style <> fillcolor <> color <> node_list <> "  }"
      })
      |> string.join("\n")
    }
  }

  // Generate edges with per-element attributes
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

              // Build attribute list starting with label
              let label = options.edge_label(weight)
              let attrs = [#("label", label)]

              // Add highlighting if applicable
              let is_highlighted = case options.highlighted_edges {
                Some(highlighted) ->
                  list.contains(highlighted, #(from_id, to_id))
                  || list.contains(highlighted, #(to_id, from_id))
                None -> False
              }

              let attrs = case is_highlighted {
                True -> [
                  #("penwidth", float.to_string(options.highlight_penwidth)),
                  #("color", options.highlight_color),
                  ..attrs
                ]
                False -> attrs
              }

              // Merge custom attributes (these override highlighting)
              let custom_attrs = options.edge_attributes(from_id, to_id, weight)
              let attrs = merge_attributes_list(attrs, custom_attrs)

              // Format attributes
              let attr_str = format_attributes_list(attrs)

              let edge_def =
                "  "
                <> int.to_string(from_id)
                <> connector
                <> int.to_string(to_id)
                <> " ["
                <> attr_str
                <> "];"
              [edge_def, ..inner_acc]
            }
          }
        })
      list.flatten([inner_edges, acc])
    })
    |> string.join("\n")

  // Combine all parts
  graph_type
  <> graph_attr_line
  <> base_node_style
  <> base_edge_style
  <> nodes
  <> "\n"
  <> case subgraphs_str {
    "" -> ""
    s -> s <> "\n"
  }
  <> edges
  <> "\n}"
}

// Merge two attribute lists, with override taking precedence.
// Later attributes override earlier ones with the same key.
fn merge_attributes_list(
  base: List(#(String, String)),
  override: List(#(String, String)),
) -> List(#(String, String)) {
  // Start with base, then fold override entries
  // For each override, remove any existing entry with the same key, then prepend
  list.fold(override, base, fn(acc, pair) {
    let filtered = list.filter(acc, fn(existing) { existing.0 != pair.0 })
    [pair, ..filtered]
  })
}

// Format a list of attributes as key="value", key2="value2"
// Reverses the list first so that earlier entries appear first
fn format_attributes_list(attrs: List(#(String, String))) -> String {
  attrs
  |> list.reverse()
  |> list.map(fn(pair) { pair.0 <> "=\"" <> pair.1 <> "\"" })
  |> string.join(", ")
}

/// Converts a shortest path result to highlighted DOT options.
///
/// Creates a copy of the base options with the path's nodes and edges
/// set to be highlighted. This is useful for visualizing algorithm results.
///
/// ## Example
///
/// ```gleam
/// case pathfinding.dijkstra(...) {
///   Some(path) -> {
///     let options = dot.path_to_dot_options(path, dot.default_dot_options())
///     let dot_string = dot.to_dot(graph, options)
///   }
///   None -> ""
/// }
/// ```
pub fn path_to_dot_options(
  path: Path(e),
  base_options: DotOptions(n, e),
) -> DotOptions(n, e) {
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

// =============================================================================
// HELPERS
// =============================================================================

/// Convert Layout to Graphviz string
fn layout_to_string(layout: Layout) -> String {
  case layout {
    Dot -> "dot"
    Neato -> "neato"
    Circo -> "circo"
    Fdp -> "fdp"
    Sfdp -> "sfdp"
    Twopi -> "twopi"
    Osage -> "osage"
    CustomLayout(s) -> s
  }
}

/// Convert RankDir to Graphviz string
fn rankdir_to_string(rd: RankDir) -> String {
  case rd {
    TopToBottom -> "TB"
    LeftToRight -> "LR"
    BottomToTop -> "BT"
    RightToLeft -> "RL"
  }
}

/// Convert NodeShape to Graphviz string
fn node_shape_to_string(shape: NodeShape) -> String {
  case shape {
    Box -> "box"
    Circle -> "circle"
    Ellipse -> "ellipse"
    Diamond -> "diamond"
    Hexagon -> "hexagon"
    Pentagon -> "pentagon"
    Octagon -> "octagon"
    Triangle -> "triangle"
    Rectangle -> "rectangle"
    Square -> "square"
    Rect -> "rect"
    InvTriangle -> "invtriangle"
    House -> "house"
    InvHouse -> "invhouse"
    Parallelogram -> "parallelogram"
    Trapezoid -> "trapezoid"
    CustomShape(s) -> s
  }
}

/// Convert Style to Graphviz string
fn style_to_string(style: Style) -> String {
  case style {
    Solid -> "solid"
    Dashed -> "dashed"
    Dotted -> "dotted"
    Bold -> "bold"
    Filled -> "filled"
    Rounded -> "rounded"
    Diagonals -> "diagonals"
    Striped -> "striped"
    Wedged -> "wedged"
  }
}

/// Convert Splines to Graphviz string
fn splines_to_string(splines: Splines) -> String {
  case splines {
    Line -> "line"
    Polyline -> "polyline"
    Curved -> "curved"
    Ortho -> "ortho"
    Spline -> "spline"
    SplinesNone -> "none"
  }
}

/// Convert ArrowStyle to Graphviz string
fn arrow_style_to_string(arrow: ArrowStyle) -> String {
  case arrow {
    Normal -> "normal"
    ArrowDot -> "dot"
    ArrowDiamond -> "diamond"
    ODiamond -> "odiamond"
    ArrowBox -> "box"
    Crow -> "crow"
    Vee -> "vee"
    Inv -> "inv"
    Tee -> "tee"
    ArrowNone -> "none"
    CustomArrow(s) -> s
  }
}

/// Convert Overlap to Graphviz string
fn overlap_to_string(overlap: Overlap) -> String {
  case overlap {
    OverlapTrue -> "true"
    OverlapFalse -> "false"
    Scale -> "scale"
    ScaleXY -> "scalexy"
    Prism -> "prism"
    CustomOverlap(s) -> s
  }
}
