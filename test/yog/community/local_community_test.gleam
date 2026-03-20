import gleam/set
import gleeunit/should
import yog
import yog/community/local_community

pub fn local_community_disjoint_cliques_test() {
  // 1-2-3 (clique) connected to 4-5-6 (clique) by edge (3,4)
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_node(4, Nil)
    |> yog.add_node(5, Nil)
    |> yog.add_node(6, Nil)
    |> yog.add_edges([
      #(1, 2, 1.0),
      #(2, 3, 1.0),
      #(3, 1, 1.0),
      #(4, 5, 1.0),
      #(5, 6, 1.0),
      #(6, 4, 1.0),
      #(3, 4, 0.1),
    ])

  // detect_with uses the float weights
  let c1 =
    local_community.detect_with(
      graph,
      [1],
      local_community.default_options(),
      fn(e) { e },
    )

  set.contains(c1, 1) |> should.be_true
  set.contains(c1, 2) |> should.be_true
  set.contains(c1, 3) |> should.be_true
  set.contains(c1, 4) |> should.be_false
  set.contains(c1, 5) |> should.be_false
  set.contains(c1, 6) |> should.be_false
}

pub fn default_detect_ignores_weights_test() {
  let assert Ok(graph) =
    yog.undirected()
    |> yog.add_node(1, Nil)
    |> yog.add_node(2, Nil)
    |> yog.add_node(3, Nil)
    |> yog.add_edges([#(1, 2, 100), #(2, 3, 100), #(3, 1, 100)])

  let c1 = local_community.detect(graph, [1])
  set.size(c1) |> should.equal(3)
}
