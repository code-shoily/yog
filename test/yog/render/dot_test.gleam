import gleam/option.{Some}
import gleam/string
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/pathfinding/utils.{Path}
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
  |> string.contains("1 -> 2 [label=\"5\" color=\"red\", penwidth=2.0]")
  |> should.be_true()

  // Edge 2->3 should not be highlighted
  output
  |> string.contains("2 -> 3 [label=\"10\"];")
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
  |> string.contains("1 -> 2 [label=\"5\" color=\"red\", penwidth=2.0]")
  |> should.be_true()

  output
  |> string.contains("2 -> 3 [label=\"3\" color=\"red\", penwidth=2.0]")
  |> should.be_true()
}
