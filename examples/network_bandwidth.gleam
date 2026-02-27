import gleam/int
import gleam/io
import gleam/set
import yog
import yog/max_flow

pub fn main() {
  io.println("=== Network Bandwidth Allocation ===\n")

  // Model a network with routers and bandwidth constraints
  // Nodes: 0=Source, 1=RouterA, 2=RouterB, 3=RouterC, 4=RouterD, 5=Destination
  // Edge weights represent bandwidth capacity in Mbps

  let network =
    yog.directed()
    // From source
    |> yog.add_edge(from: 0, to: 1, with: 20)
    // Source -> Router A (20 Mbps)
    |> yog.add_edge(from: 0, to: 2, with: 30)
    // Source -> Router B (30 Mbps)
    // Intermediate connections
    |> yog.add_edge(from: 1, to: 2, with: 10)
    // Router A -> Router B (10 Mbps)
    |> yog.add_edge(from: 1, to: 3, with: 15)
    // Router A -> Router C (15 Mbps)
    |> yog.add_edge(from: 2, to: 3, with: 25)
    // Router B -> Router C (25 Mbps)
    |> yog.add_edge(from: 2, to: 4, with: 20)
    // Router B -> Router D (20 Mbps)
    // To destination
    |> yog.add_edge(from: 3, to: 5, with: 30)
    // Router C -> Destination (30 Mbps)
    |> yog.add_edge(from: 4, to: 5, with: 15)
  // Router D -> Destination (15 Mbps)

  io.println("Network topology:")
  io.println("  Source (0) -> RouterA (1): 20 Mbps")
  io.println("  Source (0) -> RouterB (2): 30 Mbps")
  io.println("  RouterA (1) -> RouterC (3): 15 Mbps")
  io.println("  RouterB (2) -> RouterC (3): 25 Mbps")
  io.println("  RouterB (2) -> RouterD (4): 20 Mbps")
  io.println("  RouterC (3) -> Dest (5): 30 Mbps")
  io.println("  RouterD (4) -> Dest (5): 15 Mbps\n")

  // Find maximum bandwidth from source to destination
  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 5,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  io.println(
    "Maximum bandwidth from source to destination: "
    <> int.to_string(result.max_flow)
    <> " Mbps",
  )

  // Find the minimum cut (bottleneck in the network)
  let cut = max_flow.min_cut(result, with_zero: 0, with_compare: int.compare)

  io.println("\n=== Minimum Cut Analysis ===")
  io.println("This identifies the bottleneck that limits network capacity.\n")

  io.println("Source side nodes:")
  set.to_list(cut.source_side)
  |> print_node_list()

  io.println("\nSink side nodes:")
  set.to_list(cut.sink_side)
  |> print_node_list()

  io.println(
    "\nThe edges crossing from source side to sink side form the bottleneck.",
  )
  io.println(
    "Their total capacity ("
    <> int.to_string(result.max_flow)
    <> " Mbps) equals the maximum flow.",
  )
  io.println(
    "\nThis tells us which links to upgrade to increase network capacity.",
  )
}

fn print_node_list(nodes: List(Int)) -> Nil {
  case nodes {
    [] -> io.println("  (none)")
    _ -> {
      nodes
      |> list_to_string()
      |> io.println()
      Nil
    }
  }
}

fn list_to_string(nodes: List(Int)) -> String {
  case nodes {
    [] -> ""
    [node] -> "  Node " <> int.to_string(node)
    [first, ..rest] ->
      "  Node " <> int.to_string(first) <> "\n" <> list_to_string(rest)
  }
}
