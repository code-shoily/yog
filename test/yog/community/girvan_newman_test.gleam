import gleam/dict
import gleam/int
import gleam/option.{Some}
import gleam/result
import gleeunit/should
import yog/community.{Communities}
import yog/community/girvan_newman
import yog/model

pub fn edge_betweenness_test() {
  // Path graph: 0-1-2
  let g =
    model.new(model.Undirected)
    |> model.add_node(0, Nil)
    |> model.add_node(1, Nil)
    |> model.add_node(2, Nil)
    |> model.add_edge_ensure(0, 1, 1, default: Nil)
    |> model.add_edge_ensure(1, 2, 1, default: Nil)

  let ebc = girvan_newman.edge_betweenness(g, 0, int.add, int.compare)

  // Edge (0,1) is on path 0-1 and 0-2 (2 paths)
  // Edge (1,2) is on path 1-2 and 0-2 (2 paths)
  // For undirected, paths are counted once.
  // Betweenness(0,1) = 1 (for 0-1) + 1 (for 0-2) = 2
  // Wait, Brandes counts pairs s,t once? 
  // Let's check my implementation.
  dict.get(ebc, #(0, 1)) |> should.equal(Ok(2.0))
  dict.get(ebc, #(1, 2)) |> should.equal(Ok(2.0))
}

pub fn gn_split_test() {
  // Two triangles connected by a bridge
  // {0,1,2} - 1-3 - {3,4,5}
  let g =
    model.new(model.Undirected)
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
  // Bridge

  // Level 1: whole graph (1 community)
  // Level 2: after removing (1,4), we should have two communities
  let options = girvan_newman.GirvanNewmanOptions(target_communities: Some(2))
  let comms =
    girvan_newman.detect_with_options(g, options)
    |> result.unwrap(Communities(dict.new(), 0))
  comms.num_communities |> should.equal(2)

  let label1 = dict.get(comms.assignments, 1) |> should.be_ok
  let label4 = dict.get(comms.assignments, 4) |> should.be_ok
  label1 |> should.not_equal(label4)
}
