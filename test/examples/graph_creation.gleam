import gleam/int
import gleam/io
import yog
import yog/builder/labeled
import yog/model

pub fn main() {
  io.println("=== Graph Creation Methods ===\n")

  // Method 1: Builder pattern with add_node and add_edge
  io.println("1. Builder Pattern (most flexible)")
  let graph1 =
    yog.directed()
    |> yog.add_node(1, "Node A")
    |> yog.add_node(2, "Node B")
    |> yog.add_node(3, "Node C")
    |> yog.add_edge(from: 1, to: 2, with: 10)
    |> yog.add_edge(from: 2, to: 3, with: 5)

  io.println(
    "  Built graph with "
    <> int.to_string(count_nodes(graph1))
    <> " nodes using builder pattern",
  )

  // Method 2: From edge list
  io.println("\n2. From Edge List (quick and concise)")
  let graph2 =
    yog.from_edges(model.Directed, [#(1, 2, 10), #(2, 3, 5), #(1, 3, 15)])

  io.println(
    "  Created graph with "
    <> int.to_string(count_nodes(graph2))
    <> " nodes from edge list",
  )

  // Method 3: From unweighted edges
  io.println("\n3. From Unweighted Edges (no weights needed)")
  let graph3 =
    yog.from_unweighted_edges(model.Directed, [#(1, 2), #(2, 3), #(3, 4)])

  io.println(
    "  Created unweighted graph with "
    <> int.to_string(count_nodes(graph3))
    <> " nodes",
  )

  // Method 4: From adjacency list
  io.println("\n4. From Adjacency List (natural representation)")
  let graph4 =
    yog.from_adjacency_list(model.Directed, [
      #(1, [#(2, 10), #(3, 5)]),
      #(2, [#(3, 3)]),
    ])

  io.println(
    "  Created graph with "
    <> int.to_string(count_nodes(graph4))
    <> " nodes from adjacency list",
  )

  // Method 5: Simple edges (weight = 1)
  io.println("\n5. Simple Edges (default weight 1)")
  let graph5 =
    yog.directed()
    |> yog.add_simple_edge(from: 1, to: 2)
    |> yog.add_simple_edge(from: 2, to: 3)

  io.println(
    "  Created graph with "
    <> int.to_string(count_nodes(graph5))
    <> " nodes using simple edges",
  )

  // Method 6: Labeled builder (string labels)
  io.println("\n6. Labeled Builder (use strings as node IDs)")
  let builder =
    labeled.directed()
    |> labeled.add_edge(from: "home", to: "work", with: 10)
    |> labeled.add_edge(from: "work", to: "gym", with: 5)
    |> labeled.add_edge(from: "home", to: "gym", with: 15)

  let graph6 = labeled.to_graph(builder)
  io.println(
    "  Created labeled graph with "
    <> int.to_string(count_nodes(graph6))
    <> " nodes",
  )

  // Method 7: Labeled from list
  io.println("\n7. Labeled From List (bulk creation with labels)")
  let builder2 =
    labeled.from_list(model.Directed, [
      #("A", "B", 10),
      #("B", "C", 5),
      #("C", "D", 3),
    ])

  let graph7 = labeled.to_graph(builder2)
  io.println(
    "  Created labeled graph with "
    <> int.to_string(count_nodes(graph7))
    <> " nodes from list",
  )

  // Method 8: Labeled unweighted from list
  io.println("\n8. Labeled Unweighted From List")
  let builder3 =
    labeled.from_unweighted_list(model.Directed, [
      #("start", "middle"),
      #("middle", "end"),
    ])

  let graph8 = labeled.to_graph(builder3)
  io.println(
    "  Created unweighted labeled graph with "
    <> int.to_string(count_nodes(graph8))
    <> " nodes",
  )

  // Method 9: Labeled simple edges
  io.println("\n9. Labeled Simple Edges (labels + weight 1)")
  let builder4 =
    labeled.directed()
    |> labeled.add_simple_edge("Alice", "Bob")
    |> labeled.add_simple_edge("Bob", "Carol")
    |> labeled.add_simple_edge("Carol", "Dave")

  let graph9 = labeled.to_graph(builder4)
  io.println(
    "  Created simple labeled graph with "
    <> int.to_string(count_nodes(graph9))
    <> " nodes",
  )

  // Method 10: Undirected graphs
  io.println("\n10. Undirected Graphs (all methods work)")
  let graph10 =
    yog.undirected()
    |> yog.add_edge(from: 1, to: 2, with: 5)

  io.println(
    "  Created undirected graph (edges work both ways) with "
    <> int.to_string(count_nodes(graph10))
    <> " nodes",
  )

  io.println("\n=== Summary ===")
  io.println("• Builder pattern: Most flexible, good for complex graphs")
  io.println("• from_edges: Quick creation from edge list")
  io.println("• from_adjacency_list: Natural for adjacency list data")
  io.println("• Labeled builder: Use strings/any type as node identifiers")
  io.println("• from_list variants: Bulk creation with labels")
  io.println("• Simple/unweighted: Convenient for unit weights or no weights")
}

fn count_nodes(graph: yog.Graph(n, e)) -> Int {
  yog.all_nodes(graph)
  |> fn(nodes) { nodes }
  |> fn(nodes) { count_list(nodes) }
}

fn count_list(list: List(a)) -> Int {
  case list {
    [] -> 0
    [_, ..rest] -> 1 + count_list(rest)
  }
}
