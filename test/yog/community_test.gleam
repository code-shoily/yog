import gleam/dict
import gleam/option.{Some}
import gleeunit/should
import yog/community.{Communities}

pub fn community_to_dict_test() {
  let assignments = dict.from_list([#(0, 1), #(1, 1), #(2, 2)])
  let comms = Communities(assignments, 2)

  let result = community.communities_to_dict(comms)
  dict.size(result) |> should.equal(2)
  dict.get(result, 1) |> should.be_ok
  dict.get(result, 2) |> should.be_ok
}

pub fn largest_community_test() {
  let assignments = dict.from_list([#(0, 1), #(1, 1), #(2, 2)])
  let comms = Communities(assignments, 2)

  community.largest_community(comms) |> should.equal(Some(1))
}

pub fn community_sizes_test() {
  let assignments = dict.from_list([#(0, 1), #(1, 1), #(2, 2)])
  let comms = Communities(assignments, 2)

  let sizes = community.community_sizes(comms)
  dict.get(sizes, 1) |> should.equal(Ok(2))
  dict.get(sizes, 2) |> should.equal(Ok(1))
}
