import gleam/int
import gleam/io
import gleam/list
import yog/model.{Undirected}
import yog/mst

pub fn main() {
  // Model buildings and cable costs
  let buildings =
    model.new(Undirected)
    |> model.add_node(1, "Building A")
    |> model.add_node(2, "Building B")
    |> model.add_node(3, "Building C")
    |> model.add_node(4, "Building D")
    |> model.add_edge(from: 1, to: 2, with: 100)
    // $100 to connect
    |> model.add_edge(from: 1, to: 3, with: 150)
    |> model.add_edge(from: 2, to: 3, with: 50)
    |> model.add_edge(from: 2, to: 4, with: 200)
    |> model.add_edge(from: 3, to: 4, with: 100)

  // Find minimum cost to connect all buildings
  let cables = mst.kruskal(in: buildings, with_compare: int.compare)
  let total_cost = list.fold(cables, 0, fn(sum, edge) { sum + edge.weight })
  // => 250 (connects all buildings with minimum cable cost)
  // Prints: Minimum cable cost is 250
  io.println("Minimum cable cost is " <> int.to_string(total_cost))
}
