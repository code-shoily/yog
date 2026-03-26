import gleam/dict
import gleam/float
import gleam/list
import gleeunit/should
import pbt/qcheck_generators
import qcheck
import yog/centrality

/// Star Graph Invariant: The center node must have strictly higher centrality than any leaf.
pub fn star_graph_invariant_test() {
  use #(graph, center, leaves) <- qcheck.given(
    qcheck_generators.star_graph_generator(),
  )

  let degree = centrality.degree(graph, centrality.TotalDegree)
  let closeness = centrality.closeness_int(graph)
  let betweenness = centrality.betweenness_int(graph)
  let pagerank =
    centrality.pagerank(graph, centrality.default_pagerank_options())
  let eigenvector = centrality.eigenvector(graph, 100, 0.0001)

  // Scores for center
  let center_degree = dict.get(degree, center) |> should.be_ok()
  let center_closeness = dict.get(closeness, center) |> should.be_ok()
  let center_betweenness = dict.get(betweenness, center) |> should.be_ok()
  let center_pagerank = dict.get(pagerank, center) |> should.be_ok()
  let center_eigenvector = dict.get(eigenvector, center) |> should.be_ok()

  list.each(leaves, fn(leaf) {
    let leaf_degree = dict.get(degree, leaf) |> should.be_ok()
    let leaf_closeness = dict.get(closeness, leaf) |> should.be_ok()
    let leaf_betweenness = dict.get(betweenness, leaf) |> should.be_ok()
    let leaf_pagerank = dict.get(pagerank, leaf) |> should.be_ok()
    let leaf_eigenvector = dict.get(eigenvector, leaf) |> should.be_ok()

    // Center should be strictly greater
    { center_degree >. leaf_degree } |> should.be_true()
    { center_closeness >. leaf_closeness } |> should.be_true()
    // Betweenness for leaves in a star is always 0.0, center is (n-1)(n-2)/2 or similar
    { center_betweenness >. leaf_betweenness } |> should.be_true()
    { center_pagerank >. leaf_pagerank } |> should.be_true()
    { center_eigenvector >. leaf_eigenvector } |> should.be_true()
  })
}

/// PageRank Unity Law: PageRank scores must sum to 1.0 (approximately).
pub fn pagerank_unity_law_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  let scores = centrality.pagerank(graph, centrality.default_pagerank_options())
  let sum =
    dict.values(scores)
    |> list.fold(0.0, float.add)

  case dict.size(scores) {
    0 -> sum |> should.equal(0.0)
    _ -> {
      // Allow for small floating point error
      let diff = float.absolute_value(sum -. 1.0)
      { diff <. 0.001 } |> should.be_true()
    }
  }
}

/// Closeness/Betweenness/Eigenvector should return non-negative values for all nodes.
pub fn centrality_non_negative_test() {
  use graph <- qcheck.given(qcheck_generators.graph_generator())

  let degree = centrality.degree(graph, centrality.TotalDegree)
  let closeness = centrality.closeness_int(graph)
  let betweenness = centrality.betweenness_int(graph)
  let pagerank =
    centrality.pagerank(graph, centrality.default_pagerank_options())
  let eigenvector = centrality.eigenvector(graph, 100, 0.0001)

  let all_non_negative = fn(scores) {
    dict.values(scores)
    |> list.all(fn(s) { s >=. 0.0 })
  }

  all_non_negative(degree) |> should.be_true()
  all_non_negative(closeness) |> should.be_true()
  all_non_negative(betweenness) |> should.be_true()
  all_non_negative(pagerank) |> should.be_true()
  all_non_negative(eigenvector) |> should.be_true()
}
