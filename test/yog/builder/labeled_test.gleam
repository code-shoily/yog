import gleam/int
import gleam/list
import gleam/option.{Some}
import gleeunit/should
import yog
import yog/builder/labeled
import yog/model.{Directed, Undirected}
import yog/pathfinding

pub fn new_creates_empty_builder_test() {
  let builder = labeled.new(Directed)
  let graph = labeled.to_graph(builder)

  model.all_nodes(graph)
  |> should.equal([])
}

pub fn add_node_creates_node_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_node("A")

  labeled.all_labels(builder)
  |> should.equal(["A"])
}

pub fn add_edge_creates_nodes_automatically_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "A", to: "B", with: 5)

  let labels = labeled.all_labels(builder)
  list.contains(labels, "A")
  |> should.be_true()
  list.contains(labels, "B")
  |> should.be_true()
}

pub fn add_edge_creates_edge_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "A", to: "B", with: 10)

  let assert Ok(successors) = labeled.successors(builder, "A")
  successors
  |> should.equal([#("B", 10)])
}

pub fn add_multiple_edges_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "A", to: "B", with: 5)
    |> labeled.add_edge(from: "A", to: "C", with: 3)
    |> labeled.add_edge(from: "B", to: "C", with: 2)

  let assert Ok(a_successors) = labeled.successors(builder, "A")
  list.length(a_successors)
  |> should.equal(2)

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("C", 2)])
}

pub fn get_id_returns_id_for_existing_label_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_node("A")
    |> labeled.add_node("B")

  let assert Ok(id_a) = labeled.get_id(builder, "A")
  let assert Ok(id_b) = labeled.get_id(builder, "B")

  // IDs should be different
  id_a
  |> should.not_equal(id_b)
}

pub fn get_id_returns_error_for_missing_label_test() {
  let builder = labeled.new(Directed)

  labeled.get_id(builder, "NonExistent")
  |> should.be_error()
}

pub fn ensure_node_creates_new_node_test() {
  let builder = labeled.new(Directed)
  let #(builder, id1) = labeled.ensure_node(builder, "A")
  let #(_builder, id2) = labeled.ensure_node(builder, "B")

  id1
  |> should.not_equal(id2)
}

pub fn ensure_node_returns_existing_id_test() {
  let builder = labeled.new(Directed)
  let #(builder, id1) = labeled.ensure_node(builder, "A")
  let #(_builder, id2) = labeled.ensure_node(builder, "A")

  id1
  |> should.equal(id2)
}

pub fn successors_returns_labeled_successors_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "home", to: "work", with: 10)
    |> labeled.add_edge(from: "home", to: "gym", with: 5)

  let assert Ok(successors) = labeled.successors(builder, "home")
  list.length(successors)
  |> should.equal(2)
}

pub fn successors_returns_error_for_missing_label_test() {
  let builder = labeled.new(Directed)

  labeled.successors(builder, "NonExistent")
  |> should.be_error()
}

pub fn predecessors_returns_labeled_predecessors_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "A", to: "C", with: 1)
    |> labeled.add_edge(from: "B", to: "C", with: 2)

  let assert Ok(predecessors) = labeled.predecessors(builder, "C")
  list.length(predecessors)
  |> should.equal(2)
}

pub fn undirected_graph_creates_bidirectional_edges_test() {
  let builder =
    labeled.new(Undirected)
    |> labeled.add_edge(from: "A", to: "B", with: 5)

  let assert Ok(a_successors) = labeled.successors(builder, "A")
  a_successors
  |> should.equal([#("B", 5)])

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("A", 5)])
}

pub fn to_graph_conversion_preserves_structure_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "A", to: "B", with: 5)
    |> labeled.add_edge(from: "B", to: "C", with: 3)

  let graph = labeled.to_graph(builder)

  // Graph should have 3 nodes
  model.all_nodes(graph)
  |> list.length()
  |> should.equal(3)
}

pub fn pathfinding_works_with_labeled_builder_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "home", to: "work", with: 10)
    |> labeled.add_edge(from: "work", to: "gym", with: 5)
    |> labeled.add_edge(from: "home", to: "gym", with: 20)

  let graph = labeled.to_graph(builder)

  let assert Ok(home_id) = labeled.get_id(builder, "home")
  let assert Ok(gym_id) = labeled.get_id(builder, "gym")

  let assert Some(path) =
    pathfinding.shortest_path(
      in: graph,
      from: home_id,
      to: gym_id,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take the path home -> work -> gym (15) not home -> gym (20)
  path.total_weight
  |> should.equal(15)

  path.nodes
  |> list.length()
  |> should.equal(3)
}

pub fn string_labels_work_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: "red bag", to: "blue bag", with: 2)
    |> labeled.add_edge(from: "blue bag", to: "green bag", with: 3)

  let assert Ok(successors) = labeled.successors(builder, "red bag")
  successors
  |> should.equal([#("blue bag", 2)])
}

pub fn integer_labels_work_too_test() {
  // Even though the internal NodeId is Int, you can use Int as labels
  let builder =
    labeled.new(Directed)
    |> labeled.add_edge(from: 100, to: 200, with: 5)

  let assert Ok(id_100) = labeled.get_id(builder, 100)
  let assert Ok(id_200) = labeled.get_id(builder, 200)

  // The internal IDs are different from the label values
  id_100
  |> should.not_equal(100)
  id_200
  |> should.not_equal(200)
}

pub fn all_labels_returns_all_added_labels_test() {
  let builder =
    labeled.new(Directed)
    |> labeled.add_node("A")
    |> labeled.add_node("B")
    |> labeled.add_edge(from: "C", to: "D", with: 1)

  let labels = labeled.all_labels(builder)
  list.length(labels)
  |> should.equal(4)

  list.contains(labels, "A")
  |> should.be_true()
  list.contains(labels, "D")
  |> should.be_true()
}

pub fn labeled_directed_convenience_function_test() {
  let builder =
    labeled.directed()
    |> labeled.add_edge(from: "A", to: "B", with: 10)

  let assert Ok(successors) = labeled.successors(builder, "A")
  successors
  |> should.equal([#("B", 10)])

  // Should be directed (not bidirectional)
  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([])
}

pub fn labeled_undirected_convenience_function_test() {
  let builder =
    labeled.undirected()
    |> labeled.add_edge(from: "A", to: "B", with: 5)

  let assert Ok(a_successors) = labeled.successors(builder, "A")
  a_successors
  |> should.equal([#("B", 5)])

  // Should be undirected (bidirectional)
  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("A", 5)])
}

pub fn labeled_directed_equivalent_to_new_test() {
  let builder1 =
    labeled.directed()
    |> labeled.add_edge(from: "X", to: "Y", with: 1)

  let builder2 =
    labeled.new(Directed)
    |> labeled.add_edge(from: "X", to: "Y", with: 1)

  // Both should produce same structure
  labeled.all_labels(builder1)
  |> list.length()
  |> should.equal(list.length(labeled.all_labels(builder2)))

  let assert Ok(succ1) = labeled.successors(builder1, "X")
  let assert Ok(succ2) = labeled.successors(builder2, "X")
  succ1
  |> should.equal(succ2)
}

pub fn add_unweighted_edge_labeled_test() {
  let builder: labeled.Builder(String, Nil) =
    labeled.directed()
    |> labeled.add_unweighted_edge("A", "B")
    |> labeled.add_unweighted_edge("B", "C")

  let assert Ok(a_successors) = labeled.successors(builder, "A")
  a_successors
  |> should.equal([#("B", Nil)])

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("C", Nil)])
}

pub fn add_simple_edge_labeled_test() {
  let builder =
    labeled.directed()
    |> labeled.add_simple_edge("home", "work")
    |> labeled.add_simple_edge("work", "gym")

  let assert Ok(home_successors) = labeled.successors(builder, "home")
  home_successors
  |> should.equal([#("work", 1)])

  let assert Ok(work_successors) = labeled.successors(builder, "work")
  work_successors
  |> should.equal([#("gym", 1)])
}

pub fn add_simple_edge_undirected_labeled_test() {
  let builder =
    labeled.undirected()
    |> labeled.add_simple_edge("A", "B")

  // Should be bidirectional
  let assert Ok(a_successors) = labeled.successors(builder, "A")
  a_successors
  |> should.equal([#("B", 1)])

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("A", 1)])
}

pub fn add_simple_edge_aoc_example_test() {
  // Real-world AoC usage pattern
  let builder =
    labeled.undirected()
    |> labeled.add_simple_edge("COM", "B")
    |> labeled.add_simple_edge("B", "C")
    |> labeled.add_simple_edge("C", "D")

  // Verify the tree structure
  let assert Ok(com_successors) = labeled.successors(builder, "COM")
  list.length(com_successors)
  |> should.equal(1)

  let graph = labeled.to_graph(builder)
  yog.all_nodes(graph)
  |> list.length()
  |> should.equal(4)
}

pub fn from_list_directed_test() {
  let builder =
    labeled.from_list(Directed, [
      #("A", "B", 10),
      #("B", "C", 5),
      #("A", "C", 20),
    ])

  // Should have all labels
  let labels = labeled.all_labels(builder)
  list.length(labels)
  |> should.equal(3)

  list.contains(labels, "A")
  |> should.be_true()
  list.contains(labels, "B")
  |> should.be_true()
  list.contains(labels, "C")
  |> should.be_true()

  // Should have correct edges
  let assert Ok(a_successors) = labeled.successors(builder, "A")
  list.length(a_successors)
  |> should.equal(2)

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("C", 5)])
}

pub fn from_list_undirected_test() {
  let builder = labeled.from_list(Undirected, [#("A", "B", 5)])

  // Should be bidirectional
  let assert Ok(a_successors) = labeled.successors(builder, "A")
  a_successors
  |> should.equal([#("B", 5)])

  let assert Ok(b_successors) = labeled.successors(builder, "B")
  b_successors
  |> should.equal([#("A", 5)])
}

pub fn from_list_empty_test() {
  let builder = labeled.from_list(Directed, [])

  labeled.all_labels(builder)
  |> should.equal([])
}

pub fn from_list_integer_labels_test() {
  let builder = labeled.from_list(Directed, [#(100, 200, 42), #(200, 300, 99)])

  let assert Ok(successors) = labeled.successors(builder, 100)
  successors
  |> should.equal([#(200, 42)])
}

pub fn from_unweighted_list_test() {
  let builder =
    labeled.from_unweighted_list(Directed, [
      #("A", "B"),
      #("B", "C"),
      #("A", "C"),
    ])

  // Should have all labels
  let labels = labeled.all_labels(builder)
  list.length(labels)
  |> should.equal(3)

  // Should have Nil weight edges
  let assert Ok(a_successors) = labeled.successors(builder, "A")
  list.length(a_successors)
  |> should.equal(2)

  // Check that the edge data is Nil
  let assert Ok([#(_, edge_data), ..]) = labeled.successors(builder, "A")
  edge_data
  |> should.equal(Nil)
}

pub fn from_unweighted_list_undirected_test() {
  let builder = labeled.from_unweighted_list(Undirected, [#("X", "Y")])

  // Should be bidirectional
  let assert Ok(x_successors) = labeled.successors(builder, "X")
  x_successors
  |> should.equal([#("Y", Nil)])

  let assert Ok(y_successors) = labeled.successors(builder, "Y")
  y_successors
  |> should.equal([#("X", Nil)])
}

pub fn from_unweighted_list_empty_test() {
  let builder = labeled.from_unweighted_list(Directed, [])

  labeled.all_labels(builder)
  |> should.equal([])
}

pub fn from_list_pathfinding_integration_test() {
  // Build a graph using from_list and verify pathfinding works
  let builder =
    labeled.from_list(Directed, [
      #("home", "work", 10),
      #("work", "gym", 5),
      #("home", "gym", 20),
    ])

  let graph = labeled.to_graph(builder)
  let assert Ok(home_id) = labeled.get_id(builder, "home")
  let assert Ok(gym_id) = labeled.get_id(builder, "gym")

  let assert Some(path) =
    pathfinding.shortest_path(
      in: graph,
      from: home_id,
      to: gym_id,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
    )

  // Should take the shorter path through work
  path.total_weight
  |> should.equal(15)
}
