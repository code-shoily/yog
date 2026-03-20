import gleam/dict
import gleam/option.{Some}
import gleeunit/should
import yog
import yog/community/fluid_communities.{FluidOptions}

pub fn fluid_communities_disjoint_test() {
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_edges([
      #(1, 2, 1),
      #(2, 3, 1),
      #(3, 1, 1),
      #(4, 5, 1),
      #(5, 6, 1),
      #(6, 4, 1),
    ])

  let ops =
    FluidOptions(target_communities: 2, max_iterations: 20, seed: Some(42))
  let communities = fluid_communities.detect_with_options(graph, ops)

  communities.num_communities |> should.equal(2)

  let assert Ok(c1) = dict.get(communities.assignments, 1)
  let assert Ok(c2) = dict.get(communities.assignments, 2)
  let assert Ok(c3) = dict.get(communities.assignments, 3)
  c1 |> should.equal(c2)
  c2 |> should.equal(c3)

  let assert Ok(c4) = dict.get(communities.assignments, 4)
  let assert Ok(c5) = dict.get(communities.assignments, 5)
  c4 |> should.equal(c5)

  c1 |> should.not_equal(c4)
}

pub fn fluid_communities_limits_k_test() {
  let graph =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)

  // Requesting 10 nodes on a 2 node graph should cap k at 2
  let ops =
    FluidOptions(target_communities: 10, max_iterations: 1, seed: Some(1))
  let communities = fluid_communities.detect_with_options(graph, ops)

  communities.num_communities |> should.equal(2)
}
