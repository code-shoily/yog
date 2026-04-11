import gleam/int
import gleam/io
import yog
import yog/model
import yog/mst

pub fn main() {
  // Model buildings and cable costs
  let buildings =
    yog.from_edges(model.Undirected, [
      #(1, 2, 100),
      // Building A <-> Building B: $100
      #(1, 3, 150),
      // Building A <-> Building C: $150
      #(2, 3, 50),
      // Building B <-> Building C: $50
      #(2, 4, 200),
      // Building B <-> Building D: $200
      #(3, 4, 100),
      // Building C <-> Building D: $100
    ])

  // Find minimum cost to connect all buildings
  let cables = mst.kruskal_int(buildings)
  let total_cost = cables.total_weight
  // => 250 (connects all buildings with minimum cable cost)
  // Prints: Minimum cable cost is 250
  io.println("Minimum cable cost is " <> int.to_string(total_cost))
}
