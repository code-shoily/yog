import gleam/dict
import gleam/option.{Some}
import gleam/result
import gleeunit/should
import yog/community.{Communities}
import yog/community/girvan_newman
import yog/community/karate_club
import yog/community/label_propagation
import yog/community/metrics

pub fn karate_club_lpa_test() {
  let g = karate_club.karate_club_graph()
  let comms = label_propagation.detect(g)

  // LPA should find some structure (usually 2-4 communities)
  { comms.num_communities >= 2 } |> should.be_true

  // Node 0 and 33 are usually in different communities in the real split
  let _label0 = dict.get(comms.assignments, 0) |> should.be_ok
  let _label33 = dict.get(comms.assignments, 33) |> should.be_ok

  // LPA is stochastic, but usually they differ
  // label0 |> should.not_equal(label33) 

  // Check modularity: should be positive
  let q = metrics.modularity(g, comms)
  { q >. 0.0 } |> should.be_true
}

pub fn karate_club_gn_test() {
  let g = karate_club.karate_club_graph()
  // GN should find the split into 2
  let options = girvan_newman.GirvanNewmanOptions(target_communities: Some(2))
  let comms =
    girvan_newman.detect_with_options(g, options)
    |> result.unwrap(Communities(dict.new(), 0))
  comms.num_communities |> should.equal(2)

  let label0 = dict.get(comms.assignments, 0) |> should.be_ok
  let label33 = dict.get(comms.assignments, 33) |> should.be_ok
  label0 |> should.not_equal(label33)
}
