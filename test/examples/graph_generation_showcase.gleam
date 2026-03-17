import gleam/int
import gleam/io
import yog/generator/classic as generators
import yog/model

pub fn main() {
  io.println("=== Yog Graph Generation Showcase ===\n")

  // 1. Complete Graphs (Kn)
  let k5 = generators.complete(5)
  io.println("Complete Graph K5:")
  io.println("Nodes: " <> int.to_string(model.node_count(k5)))
  io.println("Edges: " <> int.to_string(model.edge_count(k5)))
  io.println("")

  // 2. Cycle Graphs (Cn)
  let c6 = generators.cycle(6)
  io.println("Cycle Graph C6:")
  io.println("Nodes: " <> int.to_string(model.node_count(c6)))
  io.println("Edges: " <> int.to_string(model.edge_count(c6)))
  io.println("")

  // 3. Path Graphs (Pn)
  let p5 = generators.path(5)
  io.println("Path Graph P5:")
  io.println("Nodes: " <> int.to_string(model.node_count(p5)))
  io.println("Edges: " <> int.to_string(model.edge_count(p5)))
  io.println("")

  // 4. Star Graphs (Sn)
  let s6 = generators.star(6)
  io.println("Star Graph S6:")
  io.println("Nodes: " <> int.to_string(model.node_count(s6)))
  io.println("Edges: " <> int.to_string(model.edge_count(s6)))
  io.println("")

  // 5. Wheel Graphs (Wn)
  let w6 = generators.wheel(6)
  io.println("Wheel Graph W6:")
  io.println("Nodes: " <> int.to_string(model.node_count(w6)))
  io.println("Edges: " <> int.to_string(model.edge_count(w6)))
  io.println("")

  // 6. Complete Bipartite (Km,n)
  let k33 = generators.complete_bipartite(3, 3)
  io.println("Complete Bipartite K3,3:")
  io.println("Nodes: " <> int.to_string(model.node_count(k33)))
  io.println("Edges: " <> int.to_string(model.edge_count(k33)))
  io.println("")

  // 7. Binary Trees
  let tree = generators.binary_tree(3)
  // Height 3
  io.println("Binary Tree (height 3):")
  io.println("Nodes: " <> int.to_string(model.node_count(tree)))
  io.println("Edges: " <> int.to_string(model.edge_count(tree)))
  io.println("")

  // 8. 2D Grids
  let grid = generators.grid_2d(3, 4)
  io.println("2D Grid (3x4):")
  io.println("Nodes: " <> int.to_string(model.node_count(grid)))
  io.println("Edges: " <> int.to_string(model.edge_count(grid)))
  io.println("")

  // 9. Petersen Graph
  let petersen = generators.petersen()
  io.println("Petersen Graph:")
  io.println("Nodes: " <> int.to_string(model.node_count(petersen)))
  io.println("Edges: " <> int.to_string(model.edge_count(petersen)))
  io.println("")

  // 10. Directed vs Undirected
  io.println("Generators respect graph type:")
  let directed_k4 = generators.complete_with_type(4, model.Directed)
  let undirected_k4 = generators.complete_with_type(4, model.Undirected)

  io.println(
    "Directed K4 Edges: "
    <> int.to_string(model.edge_count(directed_k4))
    <> " (all bi-directional)",
  )
  io.println(
    "Undirected K4 Edges: " <> int.to_string(model.edge_count(undirected_k4)),
  )
}
