import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/path.{Path}
import yog/render/dot

// =============================================================================
// DOT (Graphviz) Rendering Tests
// =============================================================================

pub fn empty_directed_dot_test() {
  let graph = model.new(Directed)
  let output = dot.to_dot(graph, dot.default_dot_options())

  output
  |> string.starts_with("digraph G {\n")
  |> should.be_true()

  output
  |> string.ends_with("\n}")
  |> should.be_true()
}

pub fn empty_undirected_dot_test() {
  let graph = model.new(Undirected)
  let output = dot.to_dot(graph, dot.default_dot_options())

  output
  |> string.starts_with("graph G {\n")
  |> should.be_true()
}

pub fn single_node_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")

  let output = dot.to_dot(graph, dot.default_dot_options())

  output
  |> string.contains("1 [label=\"1\"]")
  |> should.be_true()
}

pub fn multiple_nodes_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")

  let output = dot.to_dot(graph, dot.default_dot_options())

  output
  |> string.contains("1 [label=\"1\"]")
  |> should.be_true()

  output
  |> string.contains("2 [label=\"2\"]")
  |> should.be_true()

  output
  |> string.contains("3 [label=\"3\"]")
  |> should.be_true()
}

pub fn single_directed_edge_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = dot.to_dot(graph, dot.default_dot_options())

  // Should use -> for directed edge
  output
  |> string.contains("1 -> 2 [label=\"10\"]")
  |> should.be_true()
}

pub fn single_undirected_edge_dot_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = dot.to_dot(graph, dot.default_dot_options())

  // Should use -- for undirected edge
  output
  |> string.contains("1 -- 2 [label=\"10\"]")
  |> should.be_true()

  // Should NOT show the reverse edge (2 -- 1)
  output
  |> string.contains("2 -- 1 [label=\"10\"]")
  |> should.be_false()
}

pub fn undirected_no_duplicate_edges_dot_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "3"), #(1, 3, "1")])

  let output = dot.to_dot(graph, dot.default_dot_options())

  // Verify each edge appears once
  output
  |> string.contains("1 -- 2 [label=\"5\"]")
  |> should.be_true()

  output
  |> string.contains("2 -- 3 [label=\"3\"]")
  |> should.be_true()

  output
  |> string.contains("1 -- 3 [label=\"1\"]")
  |> should.be_true()

  // Verify reverse edges DON'T appear
  output
  |> string.contains("2 -- 1")
  |> should.be_false()

  output
  |> string.contains("3 -- 2")
  |> should.be_false()
}

pub fn multiple_edges_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "10"), #(1, 3, "15")])

  let output = dot.to_dot(graph, dot.default_dot_options())

  output
  |> string.contains("1 -> 2 [label=\"5\"]")
  |> should.be_true()

  output
  |> string.contains("2 -> 3 [label=\"10\"]")
  |> should.be_true()

  output
  |> string.contains("1 -> 3 [label=\"15\"]")
  |> should.be_true()
}

pub fn custom_node_label_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "End")

  let options =
    dot.DotOptions(..dot.default_dot_options(), node_label: fn(id, data) {
      data <> " (" <> string.inspect(id) <> ")"
    })

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 [label=\"Start (1)\"]")
  |> should.be_true()

  output
  |> string.contains("2 [label=\"End (2)\"]")
  |> should.be_true()
}

pub fn custom_edge_label_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "100")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      node_label: fn(id, _data) { string.inspect(id) },
      edge_label: fn(weight) { weight <> " km" },
      node_shape: dot.Box,
      highlight_color: "blue",
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 -> 2")
  |> should.be_true()

  output
  |> string.contains("label=\"100 km\"")
  |> should.be_true()

  output
  |> string.contains("shape=box")
  |> should.be_true()
}

pub fn highlight_single_node_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let options =
    dot.DotOptions(..dot.default_dot_options(), highlighted_nodes: Some([2]))

  let output = dot.to_dot(graph, options)

  // Node 2 should be highlighted with red fillcolor
  output
  |> string.contains("2 [label=\"2\", fillcolor=\"red\"]")
  |> should.be_true()

  // Node 1 should not have highlight override (uses base style lightblue)
  output
  |> string.contains("1 [label=\"1\"];")
  |> should.be_true()
}

pub fn highlight_multiple_nodes_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let options =
    dot.DotOptions(..dot.default_dot_options(), highlighted_nodes: Some([1, 3]))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 [label=\"1\", fillcolor=\"red\"]")
  |> should.be_true()

  output
  |> string.contains("3 [label=\"3\", fillcolor=\"red\"]")
  |> should.be_true()

  // Node 2 should not have highlight override (uses base style)
  output
  |> string.contains("2 [label=\"2\"];")
  |> should.be_true()
}

pub fn highlight_edges_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "10")])

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      highlighted_edges: Some([#(1, 2)]),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 -> 2 [label=\"5\", color=\"red\", penwidth=\"2.0\"]")
  |> should.be_true()

  // Edge 2->3 should not be highlighted
  output
  |> string.contains("2 -> 3 [label=\"10\"]")
  |> should.be_true()
}

pub fn path_to_dot_options_single_node_test() {
  let path = Path(nodes: [1], total_weight: "0")
  let options = dot.path_to_dot_options(path, dot.default_dot_options())

  options.highlighted_nodes
  |> should.equal(Some([1]))

  options.highlighted_edges
  |> should.equal(Some([]))
}

pub fn path_to_dot_options_two_nodes_test() {
  let path = Path(nodes: [1, 2], total_weight: "5")
  let options = dot.path_to_dot_options(path, dot.default_dot_options())

  options.highlighted_nodes
  |> should.equal(Some([1, 2]))

  options.highlighted_edges
  |> should.equal(Some([#(1, 2)]))
}

pub fn path_to_dot_options_three_nodes_test() {
  let path = Path(nodes: [1, 2, 3], total_weight: "15")
  let options = dot.path_to_dot_options(path, dot.default_dot_options())

  options.highlighted_nodes
  |> should.equal(Some([1, 2, 3]))

  options.highlighted_edges
  |> should.equal(Some([#(1, 2), #(2, 3)]))
}

pub fn render_dot_with_pathfinding_result_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "3")])

  let path = Path(nodes: [1, 2, 3], total_weight: "8")

  let options = dot.path_to_dot_options(path, dot.default_dot_options())
  let output = dot.to_dot(graph, options)

  // Verify path is highlighted
  output
  |> string.contains("1 [label=\"1\", fillcolor=\"red\"]")
  |> should.be_true()

  output
  |> string.contains("2 [label=\"2\", fillcolor=\"red\"]")
  |> should.be_true()

  output
  |> string.contains("3 [label=\"3\", fillcolor=\"red\"]")
  |> should.be_true()

  output
  |> string.contains("1 -> 2 [label=\"5\", color=\"red\", penwidth=\"2.0\"]")
  |> should.be_true()

  output
  |> string.contains("2 -> 3 [label=\"3\", color=\"red\", penwidth=\"2.0\"]")
  |> should.be_true()
}

// =============================================================================
// Subgraph Tests
// =============================================================================

pub fn single_subgraph_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let subgraph =
    dot.Subgraph(
      name: "cluster_0",
      label: Some("Group A"),
      node_ids: [1, 2],
      style: Some(dot.Filled),
      fillcolor: Some("lightgrey"),
      color: Some("blue"),
    )

  let options =
    dot.DotOptions(..dot.default_dot_options(), subgraphs: Some([subgraph]))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("subgraph cluster_0 {")
  |> should.be_true()

  output
  |> string.contains("label=\"Group A\";")
  |> should.be_true()

  output
  |> string.contains("style=filled;")
  |> should.be_true()

  output
  |> string.contains("fillcolor=\"lightgrey\";")
  |> should.be_true()

  output
  |> string.contains("color=\"blue\";")
  |> should.be_true()

  output
  |> string.contains("    1;")
  |> should.be_true()

  output
  |> string.contains("    2;")
  |> should.be_true()
}

pub fn multiple_subgraphs_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")

  let subgraph1 =
    dot.Subgraph(
      name: "cluster_0",
      label: Some("Group A"),
      node_ids: [1, 2],
      style: None,
      fillcolor: None,
      color: None,
    )

  let subgraph2 =
    dot.Subgraph(
      name: "cluster_1",
      label: Some("Group B"),
      node_ids: [3, 4],
      style: Some(dot.Dashed),
      fillcolor: Some("lightblue"),
      color: None,
    )

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      subgraphs: Some([subgraph1, subgraph2]),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("subgraph cluster_0 {")
  |> should.be_true()

  output
  |> string.contains("subgraph cluster_1 {")
  |> should.be_true()

  output
  |> string.contains("label=\"Group A\";")
  |> should.be_true()

  output
  |> string.contains("label=\"Group B\";")
  |> should.be_true()
}

pub fn empty_subgraph_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let subgraph =
    dot.Subgraph(
      name: "cluster_empty",
      label: None,
      node_ids: [],
      style: None,
      fillcolor: None,
      color: None,
    )

  let options =
    dot.DotOptions(..dot.default_dot_options(), subgraphs: Some([subgraph]))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("subgraph cluster_empty {")
  |> should.be_true()

  // Should not have label, style, fillcolor, or color lines
  output
  |> string.contains("cluster_empty {\n  }")
  |> should.be_true()
}

// =============================================================================
// Per-Element Attribute Tests
// =============================================================================

pub fn custom_node_attributes_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")

  let options =
    dot.DotOptions(..dot.default_dot_options(), node_attributes: fn(id, _data) {
      case id {
        1 -> [#("fillcolor", "green"), #("shape", "diamond")]
        2 -> [#("fillcolor", "yellow"), #("penwidth", "2")]
        _ -> []
      }
    })

  let output = dot.to_dot(graph, options)

  // Node 1 should have custom attributes
  output
  |> string.contains("1 [label=\"1\", fillcolor=\"green\", shape=\"diamond\"]")
  |> should.be_true()

  // Node 2 should have custom attributes
  output
  |> string.contains("2 [label=\"2\", fillcolor=\"yellow\", penwidth=\"2\"]")
  |> should.be_true()

  // Node 3 should have default styling
  output
  |> string.contains("3 [label=\"3\"];")
  |> should.be_true()
}

pub fn custom_edge_attributes_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "10")])

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      edge_attributes: fn(from, to, _weight) {
        case from, to {
          1, 2 -> [#("color", "red"), #("penwidth", "3")]
          _, _ -> []
        }
      },
    )

  let output = dot.to_dot(graph, options)

  // Edge 1->2 should have custom attributes
  output
  |> string.contains("1 -> 2 [label=\"5\", color=\"red\", penwidth=\"3\"]")
  |> should.be_true()

  // Edge 2->3 should have default styling
  output
  |> string.contains("2 -> 3 [label=\"10\"]")
  |> should.be_true()
}

pub fn node_attributes_override_highlighting_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      highlighted_nodes: Some([1]),
      node_attributes: fn(id, _data) {
        case id {
          1 -> [#("fillcolor", "purple")]
          _ -> []
        }
      },
    )

  let output = dot.to_dot(graph, options)

  // Node 1 custom attribute should override highlight color
  output
  |> string.contains("1 [label=\"1\", fillcolor=\"purple\"]")
  |> should.be_true()
}

// =============================================================================
// Graph-Level Options Tests
// =============================================================================

pub fn graph_layout_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), layout: Some(dot.Neato))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("layout=neato")
  |> should.be_true()
}

pub fn graph_rankdir_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), rankdir: Some(dot.LeftToRight))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("rankdir=LR")
  |> should.be_true()
}

pub fn graph_bgcolor_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), bgcolor: Some("lightgray"))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("bgcolor=\"lightgray\"")
  |> should.be_true()
}

pub fn graph_splines_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), splines: Some(dot.Ortho))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("splines=ortho")
  |> should.be_true()
}

pub fn graph_overlap_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), overlap: Some(dot.Scale))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("overlap=scale")
  |> should.be_true()
}

pub fn graph_nodesep_ranksep_option_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      nodesep: Some(0.5),
      ranksep: Some(1.0),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("nodesep=0.5")
  |> should.be_true()

  output
  |> string.contains("ranksep=1.0")
  |> should.be_true()
}

pub fn multiple_graph_options_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      layout: Some(dot.Fdp),
      rankdir: Some(dot.BottomToTop),
      bgcolor: Some("white"),
      splines: Some(dot.Curved),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains(
    "graph [layout=fdp, rankdir=BT, bgcolor=\"white\", splines=curved]",
  )
  |> should.be_true()
}

// =============================================================================
// Non-String Edge Type Tests
// =============================================================================

pub fn int_edge_formatter_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 42)

  let options =
    dot.default_dot_options_with_edge_formatter(fn(weight) {
      string.inspect(weight)
    })

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 -> 2 [label=\"42\"]")
  |> should.be_true()
}

pub fn float_edge_formatter_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 3.14)

  let options =
    dot.default_dot_options_with_edge_formatter(fn(weight) {
      string.inspect(weight) <> " km"
    })

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("1 -> 2 [label=\"3.14 km\"]")
  |> should.be_true()
}

// =============================================================================
// Arrow Style Tests
// =============================================================================

pub fn arrowhead_style_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "5")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      arrowhead: Some(dot.ArrowDiamond),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("arrowhead=diamond")
  |> should.be_true()
}

pub fn arrowtail_style_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "5")

  let options =
    dot.DotOptions(..dot.default_dot_options(), arrowtail: Some(dot.Vee))

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("arrowtail=vee")
  |> should.be_true()
}

pub fn both_arrow_styles_dot_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "5")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      arrowhead: Some(dot.Normal),
      arrowtail: Some(dot.ArrowDot),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("arrowhead=normal")
  |> should.be_true()

  output
  |> string.contains("arrowtail=dot")
  |> should.be_true()
}

// =============================================================================
// Custom Shape Tests
// =============================================================================

pub fn custom_node_shape_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), node_shape: dot.Hexagon)

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("node [shape=hexagon")
  |> should.be_true()
}

pub fn diamond_node_shape_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(..dot.default_dot_options(), node_shape: dot.Diamond)

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("node [shape=diamond")
  |> should.be_true()
}

pub fn custom_shape_string_dot_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")

  let options =
    dot.DotOptions(
      ..dot.default_dot_options(),
      node_shape: dot.CustomShape("star"),
    )

  let output = dot.to_dot(graph, options)

  output
  |> string.contains("node [shape=star")
  |> should.be_true()
}
