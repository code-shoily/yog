import gleeunit/should
import gleam/dict
import gleam/int
import gleam/string
import yog/model.{Directed, Undirected}
import yog/transform

// ============= Transpose Tests =============

pub fn transpose_empty_graph_test() {
  let graph = model.new(Directed)
  let transposed = transform.transpose(graph)

  transposed.out_edges
  |> should.equal(dict.new())

  transposed.in_edges
  |> should.equal(dict.new())
}

pub fn transpose_single_edge_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let transposed = transform.transpose(graph)

  // Original: 1->2
  // Transposed: 2->1
  model.successors(transposed, 2)
  |> should.equal([#(1, 10)])

  model.successors(transposed, 1)
  |> should.equal([])

  model.predecessors(transposed, 1)
  |> should.equal([#(2, 10)])
}

pub fn transpose_multiple_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)
    |> model.add_edge(from: 1, to: 3, with: 30)

  let transposed = transform.transpose(graph)

  // Original: 1->2, 2->3, 1->3
  // Transposed: 2->1, 3->2, 3->1
  model.successors(transposed, 2)
  |> should.equal([#(1, 10)])

  model.successors(transposed, 3)
  |> dict.from_list()
  |> dict.size()
  |> should.equal(2)
}

pub fn transpose_cycle_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)
    |> model.add_edge(from: 3, to: 1, with: 3)

  let transposed = transform.transpose(graph)

  // Cycle reverses: 1->2->3->1 becomes 1->3->2->1
  model.successors(transposed, 1)
  |> should.equal([#(3, 3)])

  model.successors(transposed, 3)
  |> should.equal([#(2, 2)])

  model.successors(transposed, 2)
  |> should.equal([#(1, 1)])
}

pub fn transpose_twice_is_identity_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let double_transposed =
    graph
    |> transform.transpose()
    |> transform.transpose()

  // Should be back to original
  model.successors(double_transposed, 1)
  |> should.equal(model.successors(graph, 1))

  model.successors(double_transposed, 2)
  |> should.equal(model.successors(graph, 2))
}

pub fn transpose_preserves_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Node A")
    |> model.add_node(2, "Node B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let transposed = transform.transpose(graph)

  transposed.nodes
  |> should.equal(graph.nodes)
}

// ============= Map Nodes Tests =============

pub fn map_nodes_empty_graph_test() {
  let graph = model.new(Directed)
  let mapped = transform.map_nodes(graph, string.uppercase)

  mapped.nodes
  |> should.equal(dict.new())
}

pub fn map_nodes_transforms_all_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "alice")
    |> model.add_node(2, "bob")
    |> model.add_node(3, "carol")

  let mapped = transform.map_nodes(graph, string.uppercase)

  dict.get(mapped.nodes, 1)
  |> should.equal(Ok("ALICE"))

  dict.get(mapped.nodes, 2)
  |> should.equal(Ok("BOB"))

  dict.get(mapped.nodes, 3)
  |> should.equal(Ok("CAROL"))
}

pub fn map_nodes_preserves_structure_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let mapped = transform.map_nodes(graph, fn(s) { s <> "!" })

  // Edges should be unchanged
  model.successors(mapped, 1)
  |> should.equal([#(2, 10)])

  // Graph type should be preserved
  mapped.kind
  |> should.equal(Directed)
}

pub fn map_nodes_with_type_change_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "5")
    |> model.add_node(2, "10")
    |> model.add_node(3, "15")

  // Parse strings to integers
  let mapped = transform.map_nodes(graph, fn(s) {
    case int.parse(s) {
      Ok(n) -> n
      Error(_) -> 0
    }
  })

  dict.get(mapped.nodes, 1)
  |> should.equal(Ok(5))

  dict.get(mapped.nodes, 2)
  |> should.equal(Ok(10))
}

pub fn map_nodes_functor_composition_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)

  // map(f . g) == map(f) . map(g)
  let composed =
    graph
    |> transform.map_nodes(fn(x) { x * 2 })
    |> transform.map_nodes(fn(x) { x + 1 })

  let direct =
    graph
    |> transform.map_nodes(fn(x) { x * 2 + 1 })

  composed.nodes
  |> should.equal(direct.nodes)
}

// ============= Map Edges Tests =============

pub fn map_edges_empty_graph_test() {
  let graph = model.new(Directed)
  let mapped = transform.map_edges(graph, fn(x) { x * 2 })

  mapped.out_edges
  |> should.equal(dict.new())

  mapped.in_edges
  |> should.equal(dict.new())
}

pub fn map_edges_transforms_all_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)
    |> model.add_edge(from: 1, to: 3, with: 30)

  let mapped = transform.map_edges(graph, fn(w) { w * 2 })

  model.successors(mapped, 1)
  |> dict.from_list()
  |> dict.get(2)
  |> should.equal(Ok(20))

  model.successors(mapped, 2)
  |> should.equal([#(3, 40)])

  model.successors(mapped, 1)
  |> dict.from_list()
  |> dict.get(3)
  |> should.equal(Ok(60))
}

pub fn map_edges_preserves_structure_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let mapped = transform.map_edges(graph, fn(w) { w + 5 })

  // Nodes should be unchanged
  mapped.nodes
  |> should.equal(graph.nodes)

  // Graph type should be preserved
  mapped.kind
  |> should.equal(Directed)

  // Edge structure preserved, just weights changed
  model.successors(mapped, 1)
  |> should.equal([#(2, 15)])
}

pub fn map_edges_with_type_change_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  // Convert int weights to float
  let mapped = transform.map_edges(graph, int.to_float)

  model.successors(mapped, 1)
  |> should.equal([#(2, 10.0)])
}

pub fn map_edges_undirected_graph_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let mapped = transform.map_edges(graph, fn(w) { w * 3 })

  // Both directions should be transformed
  model.successors(mapped, 1)
  |> should.equal([#(2, 15)])

  model.successors(mapped, 2)
  |> should.equal([#(1, 15)])
}

pub fn map_edges_functor_composition_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  // map(f . g) == map(f) . map(g)
  let composed =
    graph
    |> transform.map_edges(fn(x) { x * 2 })
    |> transform.map_edges(fn(x) { x + 5 })

  let direct =
    graph
    |> transform.map_edges(fn(x) { x * 2 + 5 })

  model.successors(composed, 1)
  |> should.equal(model.successors(direct, 1))
}

// ============= Filter Nodes Tests =============

pub fn filter_nodes_empty_graph_test() {
  let graph = model.new(Directed)
  let filtered = transform.filter_nodes(graph, fn(_) { True })

  filtered.nodes
  |> should.equal(dict.new())
}

pub fn filter_nodes_keep_all_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let filtered = transform.filter_nodes(graph, fn(_) { True })

  filtered.nodes
  |> dict.size()
  |> should.equal(2)

  model.successors(filtered, 1)
  |> should.equal([#(2, 10)])
}

pub fn filter_nodes_remove_all_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let filtered = transform.filter_nodes(graph, fn(_) { False })

  filtered.nodes
  |> dict.size()
  |> should.equal(0)

  filtered.out_edges
  |> dict.size()
  |> should.equal(0)
}

pub fn filter_nodes_by_predicate_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "apple")
    |> model.add_node(2, "banana")
    |> model.add_node(3, "apricot")
    |> model.add_node(4, "cherry")

  // Keep only nodes starting with 'a'
  let filtered =
    transform.filter_nodes(graph, fn(s) { string.starts_with(s, "a") })

  dict.size(filtered.nodes)
  |> should.equal(2)

  dict.has_key(filtered.nodes, 1)
  |> should.be_true()

  dict.has_key(filtered.nodes, 3)
  |> should.be_true()

  dict.has_key(filtered.nodes, 2)
  |> should.be_false()
}

pub fn filter_nodes_prunes_edges_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "keep")
    |> model.add_node(2, "remove")
    |> model.add_node(3, "keep")
    |> model.add_edge(from: 1, to: 2, with: 10)
    |> model.add_edge(from: 2, to: 3, with: 20)
    |> model.add_edge(from: 1, to: 3, with: 30)

  let filtered =
    transform.filter_nodes(graph, fn(s) { s == "keep" })

  // Nodes 1 and 3 remain
  dict.size(filtered.nodes)
  |> should.equal(2)

  // Edge 1->2 should be gone (node 2 removed)
  // Edge 2->3 should be gone (node 2 removed)
  // Edge 1->3 should remain
  model.successors(filtered, 1)
  |> should.equal([#(3, 30)])

  model.successors(filtered, 3)
  |> should.equal([])
}

pub fn filter_nodes_complex_pruning_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_node(4, 4)
    |> model.add_edge(from: 1, to: 2, with: "a")
    |> model.add_edge(from: 2, to: 3, with: "b")
    |> model.add_edge(from: 3, to: 4, with: "c")
    |> model.add_edge(from: 1, to: 4, with: "d")

  // Keep only even-numbered nodes
  let filtered = transform.filter_nodes(graph, fn(n) { n % 2 == 0 })

  dict.size(filtered.nodes)
  |> should.equal(2)

  // Only edge 2->4 could remain, but node 4 has no incoming edge from 2 in original
  // Edge 1->2 gone (node 1 removed)
  // Edge 2->3 gone (node 3 removed)
  // Edge 3->4 gone (node 3 removed)
  // Edge 1->4 gone (node 1 removed)
  model.successors(filtered, 2)
  |> should.equal([])

  model.successors(filtered, 4)
  |> should.equal([])
}

pub fn filter_nodes_preserves_graph_type_test() {
  let graph =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")

  let filtered = transform.filter_nodes(graph, fn(_) { True })

  filtered.kind
  |> should.equal(Undirected)
}

// ============= Merge Tests =============

pub fn merge_empty_graphs_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let merged = transform.merge(g1, g2)

  merged.nodes
  |> dict.size()
  |> should.equal(0)
}

pub fn merge_with_empty_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 = model.new(Directed)

  let merged = transform.merge(g1, g2)

  dict.get(merged.nodes, 1)
  |> should.equal(Ok("A"))
}

pub fn merge_disjoint_graphs_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 =
    model.new(Directed)
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edge(from: 3, to: 4, with: 20)

  let merged = transform.merge(g1, g2)

  dict.size(merged.nodes)
  |> should.equal(4)

  model.successors(merged, 1)
  |> should.equal([#(2, 10)])

  model.successors(merged, 3)
  |> should.equal([#(4, 20)])
}

pub fn merge_overlapping_nodes_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "Original")
    |> model.add_node(2, "B")

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "Updated")
    |> model.add_node(3, "C")

  let merged = transform.merge(g1, g2)

  // Node 1 should have data from g2 (other takes precedence)
  dict.get(merged.nodes, 1)
  |> should.equal(Ok("Updated"))

  dict.size(merged.nodes)
  |> should.equal(3)
}

pub fn merge_overlapping_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 20)

  let merged = transform.merge(g1, g2)

  // Edge weight from g2 should take precedence
  model.successors(merged, 1)
  |> should.equal([#(2, 20)])
}

pub fn merge_combines_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 =
    model.new(Directed)
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 2, to: 3, with: 20)

  let merged = transform.merge(g1, g2)

  // Should have both edges
  model.successors(merged, 1)
  |> should.equal([#(2, 10)])

  model.successors(merged, 2)
  |> should.equal([#(3, 20)])
}

pub fn merge_preserves_base_graph_type_test() {
  let g1 = model.new(Directed)
  let g2 = model.new(Directed)

  let merged = transform.merge(g1, g2)

  merged.kind
  |> should.equal(Directed)
}

// ============= Combined Operations Tests =============

pub fn map_then_filter_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, 5)
    |> model.add_node(2, 10)
    |> model.add_node(3, 15)
    |> model.add_edge(from: 1, to: 2, with: 1)
    |> model.add_edge(from: 2, to: 3, with: 2)

  let result =
    graph
    |> transform.map_nodes(fn(x) { x * 2 })
    |> transform.filter_nodes(fn(x) { x > 20 })

  // Only node 3 (15 * 2 = 30) remains
  dict.size(result.nodes)
  |> should.equal(1)

  dict.get(result.nodes, 3)
  |> should.equal(Ok(30))
}

pub fn transpose_preserves_edge_weights_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 42)

  let transposed = transform.transpose(graph)

  // Edge 2->1 should have same weight
  model.successors(transposed, 2)
  |> should.equal([#(1, 42)])
}

pub fn merge_then_map_edges_test() {
  let g1 =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 =
    model.new(Directed)
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 2, to: 3, with: 20)

  let result =
    transform.merge(g1, g2)
    |> transform.map_edges(fn(w) { w / 10 })

  model.successors(result, 1)
  |> should.equal([#(2, 1)])

  model.successors(result, 2)
  |> should.equal([#(3, 2)])
}
