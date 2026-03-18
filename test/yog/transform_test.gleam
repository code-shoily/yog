import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import gleeunit/should
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20), #(1, 3, 30)])

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2), #(3, 1, 3)])

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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let mapped =
    transform.map_nodes(graph, fn(s) {
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20), #(1, 3, 30)])

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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "keep")
    |> model.add_node(2, "remove")
    |> model.add_node(3, "keep")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20), #(1, 3, 30)])

  let filtered = transform.filter_nodes(graph, fn(s) { s == "keep" })

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
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, 1)
    |> model.add_node(2, 2)
    |> model.add_node(3, 3)
    |> model.add_node(4, 4)
    |> model.add_edges([
      #(1, 2, "a"),
      #(2, 3, "b"),
      #(3, 4, "c"),
      #(1, 4, "d"),
    ])

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
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let g2 = model.new(Directed)

  let merged = transform.merge(g1, g2)

  dict.get(merged.nodes, 1)
  |> should.equal(Ok("A"))
}

pub fn merge_disjoint_graphs_test() {
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let assert Ok(g2) =
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
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let assert Ok(g2) =
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
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let assert Ok(g2) =
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

pub fn merge_combines_edges_from_same_node_test() {
  // Test that merge does a deep merge of inner edge dictionaries
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(1, 3, 15)])

  let assert Ok(g2) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([#(1, 4, 20), #(1, 5, 25)])

  let merged = transform.merge(g1, g2)

  // Should have ALL edges from node 1 (not just from g2)
  let edges = model.successors(merged, 1)
  list.length(edges)
  |> should.equal(4)

  edges
  |> list.contains(#(2, 10))
  |> should.be_true()

  edges
  |> list.contains(#(3, 15))
  |> should.be_true()

  edges
  |> list.contains(#(4, 20))
  |> should.be_true()

  edges
  |> list.contains(#(5, 25))
  |> should.be_true()
}

// ============= Combined Operations Tests =============

pub fn map_then_filter_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, 5)
    |> model.add_node(2, 10)
    |> model.add_node(3, 15)
    |> model.add_edges([#(1, 2, 1), #(2, 3, 2)])

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
  let assert Ok(graph) =
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
  let assert Ok(g1) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let assert Ok(g2) =
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

// ============= Subgraph Tests =============

pub fn subgraph_empty_list_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let sub = transform.subgraph(graph, keeping: [])

  dict.size(sub.nodes)
  |> should.equal(0)

  dict.size(sub.out_edges)
  |> should.equal(0)
}

pub fn subgraph_single_node_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let sub = transform.subgraph(graph, keeping: [2])

  dict.size(sub.nodes)
  |> should.equal(1)

  dict.get(sub.nodes, 2)
  |> should.equal(Ok("B"))

  // No edges (isolated node)
  model.successors(sub, 2)
  |> should.equal([])
}

pub fn subgraph_two_connected_nodes_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let sub = transform.subgraph(graph, keeping: [2, 3])

  dict.size(sub.nodes)
  |> should.equal(2)

  // Edge 2->3 is preserved
  model.successors(sub, 2)
  |> should.equal([#(3, 20)])

  // Edge 1->2 is removed (node 1 not in subgraph)
  model.predecessors(sub, 2)
  |> should.equal([])
}

pub fn subgraph_all_nodes_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let sub = transform.subgraph(graph, keeping: [1, 2, 3])

  // Should be identical to original
  dict.size(sub.nodes)
  |> should.equal(3)

  model.successors(sub, 1)
  |> should.equal([#(2, 10)])

  model.successors(sub, 2)
  |> should.equal([#(3, 20)])
}

pub fn subgraph_removes_edges_outside_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20), #(3, 4, 30)])

  let sub = transform.subgraph(graph, keeping: [2, 3])

  dict.size(sub.nodes)
  |> should.equal(2)

  // Edge 2->3 preserved
  model.successors(sub, 2)
  |> should.equal([#(3, 20)])

  // Edge 3->4 removed (4 not in subgraph)
  model.successors(sub, 3)
  |> should.equal([])

  // Edge 1->2 removed (1 not in subgraph)
  model.predecessors(sub, 2)
  |> should.equal([])
}

pub fn subgraph_with_cycle_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20), #(3, 2, 25), #(3, 4, 30)])

  let sub = transform.subgraph(graph, keeping: [2, 3])

  // Cycle 2<->3 should be preserved
  model.successors(sub, 2)
  |> should.equal([#(3, 20)])

  model.successors(sub, 3)
  |> should.equal([#(2, 25)])
}

pub fn subgraph_undirected_graph_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let sub = transform.subgraph(graph, keeping: [1, 2])

  dict.size(sub.nodes)
  |> should.equal(2)

  // Undirected edge 1-2 preserved
  model.neighbors(sub, 1)
  |> list.contains(#(2, 10))
  |> should.be_true()

  model.neighbors(sub, 2)
  |> list.contains(#(1, 10))
  |> should.be_true()

  // Edge 2-3 removed (3 not in subgraph)
  model.neighbors(sub, 2)
  |> list.length()
  |> should.equal(1)
}

pub fn subgraph_nonexistent_ids_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  // Request nodes that don't exist
  let sub = transform.subgraph(graph, keeping: [2, 99, 100])

  // Should only have node 2
  dict.size(sub.nodes)
  |> should.equal(1)

  dict.get(sub.nodes, 2)
  |> should.equal(Ok("B"))
}

pub fn subgraph_preserves_graph_type_test() {
  let graph = model.new(Undirected)

  let sub = transform.subgraph(graph, keeping: [])

  sub.kind
  |> should.equal(Undirected)
}

pub fn subgraph_complex_graph_test() {
  // More complex graph to test comprehensive filtering
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 2, 12),
      #(1, 3, 13),
      #(2, 4, 24),
      #(3, 4, 34),
      #(4, 5, 45),
    ])

  let sub = transform.subgraph(graph, keeping: [1, 2, 3, 4])

  dict.size(sub.nodes)
  |> should.equal(4)

  // Edges within subgraph preserved
  model.successors(sub, 1)
  |> list.length()
  |> should.equal(2)

  model.successors(sub, 2)
  |> should.equal([#(4, 24)])

  model.successors(sub, 3)
  |> should.equal([#(4, 34)])

  // Edge 4->5 removed (5 not in subgraph)
  model.successors(sub, 4)
  |> should.equal([])
}

// ============= Contract Tests =============

pub fn contract_simple_directed_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 10), #(2, 3, 20)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  // Node 2 should be removed
  dict.size(contracted.nodes)
  |> should.equal(2)

  dict.get(contracted.nodes, 2)
  |> should.equal(Error(Nil))

  // Edge 2->3 should become 1->3
  model.successors(contracted, 1)
  |> should.equal([#(3, 20)])
}

pub fn contract_simple_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(2, 3, 10)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  // Node 2 removed, edge 2-3 becomes 1-3
  dict.size(contracted.nodes)
  |> should.equal(2)

  // In undirected graphs, we only process out_edges now (not in_edges too)
  // so the weight is correctly 10
  let neighbors = model.neighbors(contracted, 1)
  list.length(neighbors)
  |> should.equal(1)

  neighbors
  |> list.first()
  |> should.equal(Ok(#(3, 10)))
}

pub fn contract_combining_weights_test() {
  // Both a and b have edges to the same neighbor
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 3, 5), #(2, 3, 10)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  // Edges to 3 should be combined: 5 + 10 = 15
  model.successors(contracted, 1)
  |> should.equal([#(3, 15)])
}

pub fn contract_both_incoming_and_outgoing_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_edges([
      #(3, 1, 30),
      #(3, 2, 32),
      #(1, 4, 14),
      #(2, 4, 24),
    ])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  dict.size(contracted.nodes)
  |> should.equal(3)

  // Incoming edges to both 1 and 2 from 3 should combine
  model.predecessors(contracted, 1)
  |> should.equal([#(3, 62)])

  // Outgoing edges from both 1 and 2 to 4 should combine
  model.successors(contracted, 1)
  |> should.equal([#(4, 38)])
}

pub fn contract_removes_self_loops_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 12), #(2, 3, 23)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  // Edge 1->2 would become 1->1 (self-loop), should be removed
  model.successors(contracted, 1)
  |> should.equal([#(3, 23)])

  // No self-loop
  model.successors(contracted, 1)
  |> list.any(fn(edge) { edge.0 == 1 })
  |> should.be_false()
}

pub fn contract_isolated_nodes_test() {
  let graph =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  dict.size(contracted.nodes)
  |> should.equal(2)

  dict.get(contracted.nodes, 1)
  |> should.equal(Ok("A"))

  dict.get(contracted.nodes, 2)
  |> should.equal(Error(Nil))
}

pub fn contract_triangle_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 12), #(1, 3, 13), #(2, 3, 23)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  dict.size(contracted.nodes)
  |> should.equal(2)

  // Edge 1-3 (weight 13) exists
  // Edge 2-3 has weight 23
  // When contracting: we only process out_edges, so 2-3 becomes 1-3
  // This combines with existing: 13 + 23 = 36
  model.neighbors(contracted, 1)
  |> list.filter(fn(edge) { edge.0 == 3 })
  |> list.first()
  |> should.equal(Ok(#(3, 36)))
}

pub fn contract_max_combine_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 3, 5), #(2, 3, 10)])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.max)

  // Should use max instead of add
  model.successors(contracted, 1)
  |> should.equal([#(3, 10)])
}

pub fn contract_complex_graph_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_node(4, "D")
    |> model.add_node(5, "E")
    |> model.add_edges([
      #(1, 3, 13),
      #(2, 3, 23),
      #(2, 4, 24),
      #(3, 5, 35),
      #(4, 5, 45),
    ])

  let contracted =
    transform.contract(in: graph, merge: 1, with: 2, combine_weights: int.add)

  dict.size(contracted.nodes)
  |> should.equal(4)

  // Edges from 1 and 2 to 3 combine
  model.successors(contracted, 1)
  |> list.contains(#(3, 36))
  |> should.be_true()

  // Edge 2->4 becomes 1->4
  model.successors(contracted, 1)
  |> list.contains(#(4, 24))
  |> should.be_true()

  // Other edges remain unchanged
  model.successors(contracted, 3)
  |> should.equal([#(5, 35)])
}

// ============= Filter Edges Tests =============

pub fn filter_edges_by_weight_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(1, 3, 15), #(2, 3, 3)])

  let heavy = transform.filter_edges(graph, fn(_src, _dst, w) { w >= 10 })

  // Only 1->3 (15) should remain
  model.successors(heavy, 1)
  |> should.equal([#(3, 15)])

  model.successors(heavy, 2)
  |> should.equal([])

  // All nodes preserved
  dict.size(heavy.nodes)
  |> should.equal(3)
}

pub fn filter_edges_remove_self_loops_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 1, 5), #(1, 2, 10)])

  let no_loops = transform.filter_edges(graph, fn(src, dst, _w) { src != dst })

  model.successors(no_loops, 1)
  |> should.equal([#(2, 10)])
}

pub fn filter_edges_empty_graph_test() {
  let graph = model.new(Directed)
  let filtered = transform.filter_edges(graph, fn(_s, _d, _w) { True })

  dict.size(filtered.out_edges)
  |> should.equal(0)
}

pub fn filter_edges_keep_all_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let same = transform.filter_edges(graph, fn(_s, _d, _w) { True })

  model.successors(same, 1)
  |> should.equal([#(2, 10)])
}

pub fn filter_edges_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 5), #(1, 3, 15)])

  let heavy = transform.filter_edges(graph, fn(_s, _d, w) { w >= 10 })

  // Only 1-3 edge remains (both directions)
  model.successors(heavy, 1) |> should.equal([#(3, 15)])
  model.successors(heavy, 3) |> should.equal([#(1, 15)])
  model.successors(heavy, 2) |> should.equal([])
}

// ============= Complement Tests =============

pub fn complement_triangle_test() {
  // Triangle: 1-2, 2-3, 1-3
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1), #(1, 3, 1)])

  let comp = transform.complement(graph, default_weight: 1)

  // Complete graph → complement has no edges
  model.successors(comp, 1) |> should.equal([])
  model.successors(comp, 2) |> should.equal([])
  model.successors(comp, 3) |> should.equal([])
}

pub fn complement_path_graph_test() {
  // Path: 1-2-3 (undirected)
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edges([#(1, 2, 1), #(2, 3, 1)])

  let comp = transform.complement(graph, default_weight: 99)

  // Missing edge: 1-3 → appears in complement
  model.successors(comp, 1) |> list.length |> should.equal(1)
  model.successors(comp, 1)
  |> list.contains(#(3, 99))
  |> should.be_true

  // 1-2 and 2-3 existed → gone in complement
  model.successors(comp, 2) |> should.equal([])
}

pub fn complement_directed_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let comp = transform.complement(graph, default_weight: 1)

  // 1→2 existed, so gone. 2→1 didn't exist, so present
  model.successors(comp, 1) |> should.equal([])
  model.successors(comp, 2) |> should.equal([#(1, 1)])
}

pub fn complement_preserves_nodes_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 1)

  let comp = transform.complement(graph, default_weight: 0)

  // All nodes preserved
  dict.size(comp.nodes) |> should.equal(3)
  dict.get(comp.nodes, 1) |> should.equal(Ok("A"))
}

// ============= to_directed Tests =============

pub fn to_directed_changes_kind_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let directed = transform.to_directed(graph)

  directed.kind |> should.equal(Directed)

  // Both directions from undirected are preserved
  model.successors(directed, 1) |> should.equal([#(2, 10)])
  model.successors(directed, 2) |> should.equal([#(1, 10)])
}

pub fn to_directed_already_directed_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let result = transform.to_directed(graph)
  result.kind |> should.equal(Directed)

  model.successors(result, 1) |> should.equal([#(2, 5)])
}

// ============= to_undirected Tests =============

pub fn to_undirected_mirrors_edges_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 10)

  let undirected = transform.to_undirected(graph, resolve: int.min)

  undirected.kind |> should.equal(Undirected)

  // Edge now in both directions
  model.successors(undirected, 1) |> should.equal([#(2, 10)])
  model.successors(undirected, 2) |> should.equal([#(1, 10)])
}

pub fn to_undirected_resolves_conflicts_test() {
  let assert Ok(graph) =
    model.new(Directed)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edges([#(1, 2, 10), #(2, 1, 20)])

  let min_undirected = transform.to_undirected(graph, resolve: int.min)

  // Both directions should have min(10, 20) = 10
  model.successors(min_undirected, 1) |> should.equal([#(2, 10)])
  model.successors(min_undirected, 2) |> should.equal([#(1, 10)])

  let max_undirected = transform.to_undirected(graph, resolve: int.max)

  // Both directions should have max(10, 20) = 20
  model.successors(max_undirected, 1) |> should.equal([#(2, 20)])
  model.successors(max_undirected, 2) |> should.equal([#(1, 20)])
}

pub fn to_undirected_already_undirected_test() {
  let assert Ok(graph) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_edge(from: 1, to: 2, with: 5)

  let result = transform.to_undirected(graph, resolve: int.min)
  result.kind |> should.equal(Undirected)
}

pub fn to_directed_then_to_undirected_roundtrip_test() {
  let assert Ok(original) =
    model.new(Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: 10)
  let assert Ok(original) = model.add_edge(original, from: 2, to: 3, with: 20)

  let roundtripped =
    original
    |> transform.to_directed
    |> transform.to_undirected(resolve: int.min)

  roundtripped.kind |> should.equal(Undirected)

  // Same edges as original
  model.successors(roundtripped, 1) |> should.equal([#(2, 10)])
  model.successors(roundtripped, 2)
  |> list.length
  |> should.equal(2)
}
