import gleam/dict
import gleam/function
import gleam/int
import gleam/json
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
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      let label = options.node_label(id, data)
      let node_def = "  " <> int.to_string(id) <> "[\"" <> label <> "\"]"

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

// =============================================================================
// DOT (Graphviz) Rendering
// =============================================================================

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
/// let diagram = render.to_dot(graph, default_dot_options())
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
/// Converts a graph to DOT (Graphviz) syntax.
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
///     let options = render.path_to_dot_options(p, default_dot_options())
///     let diagram = render.to_dot(graph, options)
///     io.println(diagram)
///   }
///   None -> io.println("No path found")
/// }
/// ```
pub fn path_to_dot_options(
  path: pathfinding.Path(e),
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

// =============================================================================
// JSON Rendering (for D3.js, Cytoscape, etc.)
// =============================================================================

/// Options for customizing JSON output.
pub type JsonOptions {
  JsonOptions(
    /// Function to convert node ID and data to JSON for the 'nodes' array.
    node_mapper: fn(NodeId, String) -> json.Json,
    /// Function to convert source, target, and edge weight to JSON for the 'edges' array.
    edge_mapper: fn(NodeId, NodeId, String) -> json.Json,
  )
}

/// Creates default JSON options.
///
/// Nodes are `{ "id": 1, "label": "Node A" }`.
/// Edges are `{ "source": 1, "target": 2, "weight": "5" }`.
pub fn default_json_options() -> JsonOptions {
  JsonOptions(
    node_mapper: fn(id, data) {
      json.object([
        #("id", json.int(id)),
        #("label", json.string(data)),
      ])
    },
    edge_mapper: fn(from, to, weight) {
      json.object([
        #("source", json.int(from)),
        #("target", json.int(to)),
        #("weight", json.string(weight)),
      ])
    },
  )
}

/// Converts a graph to a JSON string compatible with many visualization libraries (e.g., D3.js).
///
/// The graph's node data and edge data must be convertible to strings.
///
/// **Time Complexity:** O(V + E)
///
/// ## Example
///
/// ```gleam
/// import gleam/io
/// import gleam/json
/// import yog/model
///
/// pub fn main() {
///   let graph =
///     model.new(model.Directed)
///     |> model.add_node(1, "Alice")
///     |> model.add_node(2, "Bob")
///     |> model.add_edge(from: 1, to: 2, with: "follows")
///
///   let json_string = render.to_json(graph, render.default_json_options())
///   io.println(json_string)
/// }
/// ```
///
/// This outputs:
/// ````json
/// {
///   "nodes": [
///     {"id": 1, "label": "Alice"},
///     {"id": 2, "label": "Bob"}
///   ],
///   "edges": [
///     {"source": 1, "target": 2, "weight": "follows"}
///   ]
/// }
/// ````
pub fn to_json(graph: Graph(String, String), options: JsonOptions) -> String {
  let nodes_json =
    dict.fold(graph.nodes, [], fn(acc, id, data) {
      [options.node_mapper(id, data), ..acc]
    })

  let edges_json =
    dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
      let inner_edges =
        dict.fold(targets, [], fn(inner_acc, to_id, weight) {
          case graph.kind {
            Undirected if from_id > to_id -> inner_acc
            _ -> [options.edge_mapper(from_id, to_id, weight), ..inner_acc]
          }
        })
      list.flatten([inner_edges, acc])
    })

  json.to_string(
    json.object([
      #("nodes", json.array(nodes_json, of: function.identity)),
      #("edges", json.array(edges_json, of: function.identity)),
    ]),
  )
}
