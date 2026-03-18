import gleam/io
import gleam/option.{None, Some}
import gleam/string
import yog
import yog/property/eulerian as properties

pub fn main() {
  io.println("=== The Seven Bridges of Königsberg ===\n")

  // The historical problem:
  // Four land masses (nodes) connected by seven bridges (edges)
  // Can we walk through the city crossing every bridge exactly once?
  let graph =
    yog.undirected()
    |> yog.add_node(1, "Island A")
    |> yog.add_node(2, "Land B")
    |> yog.add_node(3, "Land C")
    |> yog.add_node(4, "Land D")
  // Bridges
  let assert Ok(graph) = yog.add_edge(graph, 1, 2, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 1, 2, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 1, 3, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 1, 3, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 1, 4, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 2, 4, Nil)
  let assert Ok(graph) = yog.add_edge(graph, 3, 4, Nil)

  io.println("Graph analysis:")
  case properties.has_eulerian_circuit(graph) {
    True -> io.println("✓ Eulerian circuit exists")
    False -> io.println("✗ No Eulerian circuit (too many odd-degree nodes)")
  }

  case properties.has_eulerian_path(graph) {
    True -> {
      io.println("✓ Eulerian path exists!")
      case properties.find_eulerian_path(graph) {
        Some(path) -> io.println(string.inspect(path))
        None -> Nil
      }
    }
    False -> io.println("✗ No Eulerian path (more than two odd-degree nodes)")
  }

  io.println("\nEuler concluded in 1736 that no such walk is possible.")

  // Example where it works (a simple path)
  let circuit_graph = yog.undirected()
  let assert Ok(circuit_graph) = yog.add_edge(circuit_graph, 1, 2, Nil)
  let assert Ok(circuit_graph) = yog.add_edge(circuit_graph, 2, 3, Nil)
  let assert Ok(circuit_graph) = yog.add_edge(circuit_graph, 3, 1, Nil)

  case properties.find_eulerian_circuit(circuit_graph) {
    Some(circuit) -> {
      io.println("\nSuccessfully found path for a triangle:")
      io.println(string.inspect(circuit))
    }
    None -> io.println("Error calculating path")
  }
}
