import gleam/dict
import gleam/option.{Some}
import gleeunit/should
import yog/community/walktrap
import yog/model.{Undirected}

pub fn walktrap_simple_test() {
  // Two triangles connected by a bridge
  // {0,1,2} - {3,4,5}
  // Bridge (1,4)
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

  let comms =
    walktrap.detect_with_options(
      g,
      walktrap.WalktrapOptions(walk_length: 4, target_communities: Some(2)),
    )

  comms.num_communities |> should.equal(2)

  let label0 = dict.get(comms.assignments, 0) |> should.be_ok
  let label2 = dict.get(comms.assignments, 2) |> should.be_ok
  let label3 = dict.get(comms.assignments, 3) |> should.be_ok
  let label5 = dict.get(comms.assignments, 5) |> should.be_ok

  label0 |> should.equal(label2)
  label3 |> should.equal(label5)
  label0 |> should.not_equal(label3)
}
