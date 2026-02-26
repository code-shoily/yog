import gleeunit/should
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import yog/model.{Directed, Undirected}
import yog/render
import yog/pathfinding

// ============= Basic Mermaid Generation Tests =============

pub fn empty_directed_graph_test() {
  let graph = model.new(Directed)
  let output = render.to_mermaid(graph, render.default_options())

  output
  |> string.starts_with("graph TD\n")
  |> should.be_true()
}

pub fn empty_undirected_graph_test() {
  let graph = model.new(Undirected)
  let output = render.to_mermaid(graph, render.default_options())

  output
  |> string.starts_with("graph LR\n")
  |> should.be_true()
}

pub fn single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")

  let output = render.to_mermaid(graph, render.default_options())

  output
  |> string.contains("1[\"1\"]")
  |> should.be_true()
}

pub fn multiple_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_node(3, "Node C")

  let output = render.to_mermaid(graph, render.default_options())

  output
  |> string.contains("1[\"1\"]")
  |> should.be_true()

  output
  |> string.contains("2[\"2\"]")
  |> should.be_true()

  output
  |> string.contains("3[\"3\"]")
  |> should.be_true()
}

pub fn single_directed_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = render.to_mermaid(graph, render.default_options())

  // Should use --> for directed edge
  output
  |> string.contains("1 -->|10| 2")
  |> should.be_true()
}

pub fn single_undirected_edge_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = render.to_mermaid(graph, render.default_options())

  // Should use --- for undirected edge
  output
  |> string.contains("1 ---|10| 2")
  |> should.be_true()

  // Should NOT show the reverse edge (2 ---|10| 1)
  output
  |> string.contains("2 ---|10| 1")
  |> should.be_false()
}

pub fn undirected_no_duplicate_edges_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: "5")
    |> model.add_edge(from: 2, to: 3, with: "3")
    |> model.add_edge(from: 1, to: 3, with: "1")

  let output = render.to_mermaid(graph, render.default_options())

  // Should have exactly 3 edges (not 6)
  // Count occurrences of "---" (edge marker)
  let edge_count =
    output
    |> string.split("---")
    |> list.length()
    |> fn(n) { n - 1 }

  edge_count
  |> should.equal(3)

  // Verify each edge appears once
  output
  |> string.contains("1 ---|5| 2")
  |> should.be_true()

  output
  |> string.contains("2 ---|3| 3")
  |> should.be_true()

  output
  |> string.contains("1 ---|1| 3")
  |> should.be_true()

  // Verify reverse edges DON'T appear
  output
  |> string.contains("2 ---|5| 1")
  |> should.be_false()

  output
  |> string.contains("3 ---|3| 2")
  |> should.be_false()

  output
  |> string.contains("3 ---|1| 1")
  |> should.be_false()
}

pub fn multiple_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: "5")
    |> model.add_edge(from: 2, to: 3, with: "10")
    |> model.add_edge(from: 1, to: 3, with: "15")

  let output = render.to_mermaid(graph, render.default_options())

  output
  |> string.contains("1 -->|5| 2")
  |> should.be_true()

  output
  |> string.contains("2 -->|10| 3")
  |> should.be_true()

  output
  |> string.contains("1 -->|15| 3")
  |> should.be_true()
}

// ============= Custom Label Tests =============

pub fn custom_node_label_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "End")

  let options =
    render.MermaidOptions(
      node_label: fn(id, data) { data <> " (ID:" <> string.inspect(id) <> ")" },
      edge_label: fn(weight) { weight },
      highlighted_nodes: None,
      highlighted_edges: None,
    )

  let output = render.to_mermaid(graph, options)

  output
  |> string.contains("1[\"Start (ID:1)\"]")
  |> should.be_true()

  output
  |> string.contains("2[\"End (ID:2)\"]")
  |> should.be_true()
}

pub fn custom_edge_label_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "100")

  let options =
    render.MermaidOptions(
      node_label: fn(id, _data) { string.inspect(id) },
      edge_label: fn(weight) { weight <> " km" },
      highlighted_nodes: None,
      highlighted_edges: None,
    )

  let output = render.to_mermaid(graph, options)

  output
  |> string.contains("1 -->|100 km| 2")
  |> should.be_true()
}

// ============= Highlighting Tests =============

pub fn highlight_single_node_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let options =
    render.MermaidOptions(
      ..render.default_options(),
      highlighted_nodes: Some([2]),
    )

  let output = render.to_mermaid(graph, options)

  // Should have style definitions
  output
  |> string.contains("classDef highlight")
  |> should.be_true()

  // Node 2 should be highlighted
  output
  |> string.contains("2[\"2\"]:::highlight")
  |> should.be_true()

  // Node 1 should not be highlighted
  output
  |> string.contains("1[\"1\"]")
  |> should.be_true()

  // Should not contain Node 1 with highlight
  output
  |> string.contains("1[\"1\"]:::highlight")
  |> should.be_false()
}

pub fn highlight_multiple_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let options =
    render.MermaidOptions(
      ..render.default_options(),
      highlighted_nodes: Some([1, 3]),
    )

  let output = render.to_mermaid(graph, options)

  output
  |> string.contains("1[\"1\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("3[\"3\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("2[\"2\"]:::highlight")
  |> should.be_false()
}

pub fn highlight_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: "5")
    |> model.add_edge(from: 2, to: 3, with: "10")

  let options =
    render.MermaidOptions(
      ..render.default_options(),
      highlighted_edges: Some([#(1, 2)]),
    )

  let output = render.to_mermaid(graph, options)

  output
  |> string.contains("classDef highlightEdge")
  |> should.be_true()

  output
  |> string.contains("1 -->|5| 2:::highlightEdge")
  |> should.be_true()

  output
  |> string.contains("2 -->|10| 3:::highlightEdge")
  |> should.be_false()
}

pub fn highlight_path_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: "5")
    |> model.add_edge(from: 2, to: 3, with: "10")

  let options =
    render.MermaidOptions(
      ..render.default_options(),
      highlighted_nodes: Some([1, 2, 3]),
      highlighted_edges: Some([#(1, 2), #(2, 3)]),
    )

  let output = render.to_mermaid(graph, options)

  // All nodes should be highlighted
  output
  |> string.contains("1[\"1\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("2[\"2\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("3[\"3\"]:::highlight")
  |> should.be_true()

  // Both edges should be highlighted
  output
  |> string.contains("1 -->|5| 2:::highlightEdge")
  |> should.be_true()

  output
  |> string.contains("2 -->|10| 3:::highlightEdge")
  |> should.be_true()
}

// ============= Path Conversion Tests =============

pub fn path_to_options_single_node_test() {
  let path = pathfinding.Path(nodes: [1], total_weight: "0")
  let options = render.path_to_options(path, render.default_options())

  options.highlighted_nodes
  |> should.equal(Some([1]))

  options.highlighted_edges
  |> should.equal(Some([]))
}

pub fn path_to_options_two_nodes_test() {
  let path = pathfinding.Path(nodes: [1, 2], total_weight: "5")
  let options = render.path_to_options(path, render.default_options())

  options.highlighted_nodes
  |> should.equal(Some([1, 2]))

  options.highlighted_edges
  |> should.equal(Some([#(1, 2)]))
}

pub fn path_to_options_three_nodes_test() {
  let path = pathfinding.Path(nodes: [1, 2, 3], total_weight: "15")
  let options = render.path_to_options(path, render.default_options())

  options.highlighted_nodes
  |> should.equal(Some([1, 2, 3]))

  options.highlighted_edges
  |> should.equal(Some([#(1, 2), #(2, 3)]))
}

pub fn path_to_options_preserves_base_labels_test() {
  let path = pathfinding.Path(nodes: [1, 2], total_weight: "10")

  let base =
    render.MermaidOptions(
      node_label: fn(_id, data) { "Custom " <> data },
      edge_label: fn(weight) { weight <> " units" },
      highlighted_nodes: None,
      highlighted_edges: None,
    )

  let options = render.path_to_options(path, base)

  // Should preserve the custom label functions
  let node_label = options.node_label(1, "Test")
  node_label
  |> should.equal("Custom Test")

  let edge_label = options.edge_label("5")
  edge_label
  |> should.equal("5 units")
}

// ============= Integration Tests =============

pub fn render_with_pathfinding_result_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")
    |> model.add_edge(from: 1, to: 2, with: "5")
    |> model.add_edge(from: 2, to: 3, with: "3")

  // This would be the result from pathfinding
  let path = pathfinding.Path(nodes: [1, 2, 3], total_weight: "8")

  let options = render.path_to_options(path, render.default_options())
  let output = render.to_mermaid(graph, options)

  // Verify path is highlighted
  output
  |> string.contains("1[\"1\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("2[\"2\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("3[\"3\"]:::highlight")
  |> should.be_true()

  output
  |> string.contains("1 -->|5| 2:::highlightEdge")
  |> should.be_true()

  output
  |> string.contains("2 -->|3| 3:::highlightEdge")
  |> should.be_true()
}

pub fn complex_graph_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 1, to: 2, with: "1")
    |> model.add_edge(from: 1, to: 3, with: "4")
    |> model.add_edge(from: 2, to: 3, with: "2")
    |> model.add_edge(from: 2, to: 4, with: "5")
    |> model.add_edge(from: 3, to: 4, with: "1")

  let output = render.to_mermaid(graph, render.default_options())

  // Verify all nodes are present
  output
  |> string.contains("1[\"1\"]")
  |> should.be_true()

  output
  |> string.contains("4[\"4\"]")
  |> should.be_true()

  // Verify all edges are present
  output
  |> string.contains("1 -->|1| 2")
  |> should.be_true()

  output
  |> string.contains("3 -->|1| 4")
  |> should.be_true()
}
