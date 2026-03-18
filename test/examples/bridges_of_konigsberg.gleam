import gleam/io
import gleam/option.{None, Some}
import gleam/string
import yog
import yog/model
import yog/property/eulerian as properties

pub fn main() {
  io.println("=== The Seven Bridges of Königsberg ===\n")

  // The historical problem:
  // Four land masses (nodes) connected by seven bridges (edges)
  // Can we walk through the city crossing every bridge exactly once?
  let graph =
    yog.from_unweighted_edges(model.Undirected, [
      #(1, 2),
      // Island A <-> Land B (bridge 1)
      #(1, 2),
      // Island A <-> Land B (bridge 2)
      #(1, 3),
      // Island A <-> Land C (bridge 3)
      #(1, 3),
      // Island A <-> Land C (bridge 4)
      #(1, 4),
      // Island A <-> Land D (bridge 5)
      #(2, 4),
      // Land B <-> Land D (bridge 6)
      #(3, 4),
      // Land C <-> Land D (bridge 7)
    ])

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
  let circuit_graph =
    yog.from_unweighted_edges(model.Undirected, [#(1, 2), #(2, 3), #(3, 1)])

  case properties.find_eulerian_circuit(circuit_graph) {
    Some(circuit) -> {
      io.println("\nSuccessfully found path for a triangle:")
      io.println(string.inspect(circuit))
    }
    None -> io.println("Error calculating path")
  }
}
