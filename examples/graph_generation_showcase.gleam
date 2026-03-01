import gleam/int
import gleam/io
import yog/generators
import yog/model

pub fn main() {
  io.println("=== Graph Generation Showcase ===\n")

  // Complete graphs
  io.println("1. Complete Graph K_5")
  let k5 = generators.complete(5)
  print_graph_stats("K_5", k5)
  io.println("  Every node connected to every other node")
  io.println("  Perfect for studying maximum connectivity\n")

  // Cycle graphs
  io.println("2. Cycle Graph C_6")
  let c6 = generators.cycle(6)
  print_graph_stats("C_6", c6)
  io.println("  Nodes form a ring: 0-1-2-3-4-5-0")
  io.println("  Perfect for studying circular structures\n")

  // Path graphs
  io.println("3. Path Graph P_5")
  let p5 = generators.path(5)
  print_graph_stats("P_5", p5)
  io.println("  Linear chain: 0-1-2-3-4")
  io.println("  Perfect for studying sequential processes\n")

  // Star graphs
  io.println("4. Star Graph S_6")
  let s6 = generators.star(6)
  print_graph_stats("S_6", s6)
  io.println("  Central node (0) connected to all others")
  io.println("  Perfect for studying hub-and-spoke networks\n")

  // Wheel graphs
  io.println("5. Wheel Graph W_6")
  let w6 = generators.wheel(6)
  print_graph_stats("W_6", w6)
  io.println("  Cycle with central hub")
  io.println("  Perfect for studying hybrid topologies\n")

  // Complete bipartite
  io.println("6. Complete Bipartite K_{3,3}")
  let k33 = generators.complete_bipartite(3, 3)
  print_graph_stats("K_3,3", k33)
  io.println("  Two groups: nodes 0-2 and 3-5")
  io.println("  Every node in one group connected to all in other")
  io.println("  Perfect for studying matching problems\n")

  // Binary tree
  io.println("7. Binary Tree (depth 3)")
  let tree = generators.binary_tree(3)
  print_graph_stats("Binary Tree", tree)
  io.println("  Complete binary tree with 15 nodes")
  io.println("  Root at 0, children at 2i+1 and 2i+2")
  io.println("  Perfect for studying hierarchical structures\n")

  // Grid 2D
  io.println("8. 2D Grid (3x4)")
  let grid = generators.grid_2d(3, 4)
  print_graph_stats("3x4 Grid", grid)
  io.println("  Rectangular lattice with 12 nodes")
  io.println("  Perfect for studying spatial problems\n")

  // Petersen graph
  io.println("9. Petersen Graph")
  let petersen = generators.petersen()
  print_graph_stats("Petersen", petersen)
  io.println("  Famous 3-regular graph with 10 nodes")
  io.println("  Perfect for counterexamples in graph theory\n")

  io.println("=== Use Cases ===")
  io.println("• Testing: Graphs with known properties")
  io.println("• Benchmarking: Graphs of various sizes")
  io.println("• Education: Classic structures for learning")
  io.println("• Prototyping: Quick graph creation\n")

  io.println("=== Directed vs Undirected ===")
  let directed_k4 = generators.complete_with_type(4, model.Directed)
  let undirected_k4 = generators.complete_with_type(4, model.Undirected)

  io.println("Directed K_4 edges: " <> int.to_string(count_edges(directed_k4)))
  io.println(
    "Undirected K_4 edges: " <> int.to_string(count_edges(undirected_k4) / 2),
  )
  io.println("(Directed has edges in both directions)")
}

fn print_graph_stats(_name: String, graph: model.Graph(Nil, Int)) -> Nil {
  let node_count = model.all_nodes(graph) |> list_length()
  let edge_count = count_edges(graph)

  // For undirected graphs, each edge is counted twice
  let display_edges = case graph.kind {
    model.Undirected -> edge_count / 2
    model.Directed -> edge_count
  }

  io.println("  Nodes: " <> int.to_string(node_count))
  io.println("  Edges: " <> int.to_string(display_edges))
}

fn count_edges(graph: model.Graph(Nil, Int)) -> Int {
  model.all_nodes(graph)
  |> list_fold(0, fn(count, node) {
    let successors = model.successors(graph, node)
    count + list_length(successors)
  })
}

fn list_length(list: List(a)) -> Int {
  case list {
    [] -> 0
    [_, ..rest] -> 1 + list_length(rest)
  }
}

fn list_fold(list: List(a), initial: b, fun: fn(b, a) -> b) -> b {
  case list {
    [] -> initial
    [x, ..rest] -> list_fold(rest, fun(initial, x), fun)
  }
}
