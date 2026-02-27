import gleam/io
import gleam/option.{None, Some}
import gleam/string
import yog/eulerian
import yog/model

pub fn main() {
  // The Seven Bridges of Königsberg problem
  // Nodes represent the four land masses (A, B, C, D)
  // Edges represent the seven bridges
  let graph =
    model.new(model.Undirected)
    |> model.add_node(1, "Island A")
    |> model.add_node(2, "Bank B")
    |> model.add_node(3, "Bank C")
    |> model.add_node(4, "Island D")
    // Bridges
    |> model.add_edge(from: 1, to: 2, with: "b1")
    |> model.add_edge(from: 1, to: 2, with: "b2")
    |> model.add_edge(from: 1, to: 3, with: "b3")
    |> model.add_edge(from: 1, to: 3, with: "b4")
    |> model.add_edge(from: 1, to: 4, with: "b5")
    |> model.add_edge(from: 2, to: 4, with: "b6")
    |> model.add_edge(from: 3, to: 4, with: "b7")

  io.println("--- Seven Bridges of Königsberg ---")

  // Check if an Eulerian circuit exists (all even degrees)
  case eulerian.has_eulerian_circuit(graph) {
    True -> io.println("Eulerian circuit exists!")
    False -> io.println("No Eulerian circuit exists.")
  }

  // Check if an Eulerian path exists (0 or 2 odd degrees)
  case eulerian.has_eulerian_path(graph) {
    True -> {
      io.println("Eulerian path exists!")
      case eulerian.find_eulerian_path(graph) {
        Some(path) -> io.println("Path: " <> string.inspect(path))
        None -> Nil
      }
    }
    False -> io.println("No Eulerian path exists either.")
  }

  // Example of a graph that DOES have a circuit
  let circuit_graph =
    model.new(model.Undirected)
    |> model.add_node(1, "A")
    |> model.add_node(2, "B")
    |> model.add_node(3, "C")
    |> model.add_edge(from: 1, to: 2, with: Nil)
    |> model.add_edge(from: 2, to: 3, with: Nil)
    |> model.add_edge(from: 3, to: 1, with: Nil)

  io.println("\n--- Simple Triangle ---")
  case eulerian.find_eulerian_circuit(circuit_graph) {
    Some(circuit) -> io.println("Circuit found: " <> string.inspect(circuit))
    None -> io.println("No circuit found")
  }
}
