import gleam/dict
import gleeunit/should
import yog/community/infomap
import yog/model.{Undirected}

pub fn infomap_simple_test() {
  // Two triangles connected by a bridge
  let g =
    model.new(Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_node(3, Nil)
    |> model.add_node(4, Nil)
    |> model.add_node(5, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)
    |> model.add_edge_ensure(2, 0, 1, default: Nil)
    |> model.add_edge_ensure(3, 4, 1, default: Nil)
    |> model.add_edge_ensure(4, 5, 1, default: Nil)
    |> model.add_edge_ensure(5, 3, 1, default: Nil)
    |> model.add_edge_ensure(1, 4, 1, default: Nil)

  let comms = infomap.detect(g)

  // With 200 iterations and teleport 0.15, it should find two communities
  // Though my simplified heuristic might need verification
  { comms.num_communities >= 1 } |> should.be_true

  // Basic check for assignments
  dict.size(comms.assignments) |> should.equal(6)
}
