import gleam/json
import gleam/list
import gleam/string
import gleeunit/should
import yog/model.{Directed, Undirected}
import yog/render/json as yog_json

// =============================================================================
// JSON Rendering Tests
// =============================================================================

pub fn empty_directed_json_test() {
  let graph = model.new(Directed)
  let output = yog_json.to_json(graph, yog_json.default_json_options())

  output
  |> string.contains("\"nodes\":[]")
  |> should.be_true()

  output
  |> string.contains("\"edges\":[]")
  |> should.be_true()
}

pub fn single_node_json_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  output
  |> string.contains("\"id\":1")
  |> should.be_true()

  output
  |> string.contains("\"label\":\"Node A\"")
  |> should.be_true()
}

pub fn multiple_nodes_json_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Alice")
    |> model.add_node(2, "Bob")
    |> model.add_node(3, "Carol")

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  output
  |> string.contains("\"id\":1")
  |> should.be_true()

  output
  |> string.contains("\"label\":\"Alice\"")
  |> should.be_true()

  output
  |> string.contains("\"id\":2")
  |> should.be_true()

  output
  |> string.contains("\"label\":\"Bob\"")
  |> should.be_true()

  output
  |> string.contains("\"id\":3")
  |> should.be_true()

  output
  |> string.contains("\"label\":\"Carol\"")
  |> should.be_true()
}

pub fn single_directed_edge_json_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  output
  |> string.contains("\"source\":1")
  |> should.be_true()

  output
  |> string.contains("\"target\":2")
  |> should.be_true()

  output
  |> string.contains("\"weight\":\"10\"")
  |> should.be_true()
}

pub fn single_undirected_edge_json_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: "10")

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  // Should have the edge once
  output
  |> string.contains("\"source\":1")
  |> should.be_true()

  output
  |> string.contains("\"target\":2")
  |> should.be_true()

  // Count the occurrences of "source" field (should be 1 for undirected)
  let edge_count =
    output
    |> string.split("\"source\":")
    |> list.length()
    |> fn(n) { n - 1 }

  edge_count
  |> should.equal(1)
}

pub fn multiple_edges_json_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, "5"), #(2, 3, "10"), #(1, 3, "15")])

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  // Count the occurrences of "source" field (should be 3)
  let edge_count =
    output
    |> string.split("\"source\":")
    |> list.length()
    |> fn(n) { n - 1 }

  edge_count
  |> should.equal(3)

  // Verify all edges are present
  output
  |> string.contains("\"weight\":\"5\"")
  |> should.be_true()

  output
  |> string.contains("\"weight\":\"10\"")
  |> should.be_true()

  output
  |> string.contains("\"weight\":\"15\"")
  |> should.be_true()
}

pub fn custom_node_mapper_json_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Alice")
    |> model.add_node(2, "Bob")

  let options =
    yog_json.JsonOptions(
      node_mapper: fn(id, data) {
        json.object([
          #("node_id", json.int(id)),
          #("name", json.string(data)),
          #("type", json.string("person")),
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

  let output = yog_json.to_json(graph, options)

  output
  |> string.contains("\"node_id\":1")
  |> should.be_true()

  output
  |> string.contains("\"name\":\"Alice\"")
  |> should.be_true()

  output
  |> string.contains("\"type\":\"person\"")
  |> should.be_true()
}

pub fn custom_edge_mapper_json_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: "follows")

  let options =
    yog_json.JsonOptions(
      node_mapper: fn(id, data) {
        json.object([#("id", json.int(id)), #("label", json.string(data))])
      },
      edge_mapper: fn(from, to, weight) {
        json.object([
          #("from_node", json.int(from)),
          #("to_node", json.int(to)),
          #("relationship", json.string(weight)),
        ])
      },
    )

  let output = yog_json.to_json(graph, options)

  output
  |> string.contains("\"from_node\":1")
  |> should.be_true()

  output
  |> string.contains("\"to_node\":2")
  |> should.be_true()

  output
  |> string.contains("\"relationship\":\"follows\"")
  |> should.be_true()
}

pub fn complex_graph_json_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(1, 2, "1"),
      #(1, 3, "4"),
      #(2, 3, "2"),
      #(2, 4, "5"),
      #(3, 4, "1"),
    ])

  let output = yog_json.to_json(graph, yog_json.default_json_options())

  // Verify all nodes are present
  output
  |> string.contains("\"id\":1")
  |> should.be_true()

  output
  |> string.contains("\"id\":4")
  |> should.be_true()

  // Count nodes (should be 4)
  let node_count =
    output
    |> string.split("\"id\":")
    |> list.length()
    |> fn(n) { n - 1 }

  node_count
  |> should.equal(4)

  // Count edges (should be 5)
  let edge_count =
    output
    |> string.split("\"source\":")
    |> list.length()
    |> fn(n) { n - 1 }

  edge_count
  |> should.equal(5)
}
