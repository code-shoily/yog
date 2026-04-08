import gleam/int
import gleam/io
import gleam/option.{None}
import yog/generator/random as generators
import yog/model

pub fn main() {
  io.println("=== Yog Random Graph Showcase ===\n")

  // 1. Erdős-Rényi (G(n, p))
  io.println("G(n, p) Random Graph (n=100, p=0.05):")
  let er = generators.erdos_renyi_gnp(100, 0.05, seed: None)
  io.println("Nodes: " <> int.to_string(model.node_count(er)))
  io.println("Edges: " <> int.to_string(model.edge_count(er)))
  io.println("")

  // 2. Erdős-Rényi (G(n, m))
  io.println("G(n, m) Random Graph (n=100, m=250):")
  let er2 = generators.erdos_renyi_gnm(100, 250, seed: None)
  io.println("Nodes: " <> int.to_string(model.node_count(er2)))
  io.println("Edges: " <> int.to_string(model.edge_count(er2)))
  io.println("")

  // 3. Barabási-Albert (Scale-free)
  io.println("Barabási-Albert Graph (n=100, m=2):")
  let ba = generators.barabasi_albert(100, 2, seed: None)
  io.println("Nodes: " <> int.to_string(model.node_count(ba)))
  io.println("Edges: " <> int.to_string(model.edge_count(ba)))
  io.println("")

  // 4. Watts-Strogatz (Small-world)
  io.println("Watts-Strogatz Graph (n=100, k=4, p=0.1):")
  let ws = generators.watts_strogatz(100, 4, 0.1, seed: None)
  io.println("Nodes: " <> int.to_string(model.node_count(ws)))
  io.println("Edges: " <> int.to_string(model.edge_count(ws)))
  io.println("")

  // 5. Random Tree
  io.println("Random Tree (n=100):")
  let tree = generators.random_tree(100, seed: None)
  io.println("Nodes: " <> int.to_string(model.node_count(tree)))
  io.println("Edges: " <> int.to_string(model.edge_count(tree)))
  io.println("(A tree always has n-1 edges)")
}
