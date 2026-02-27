import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleeunit/should
import yog/bipartite

// Classic stable marriage problem - 3 men, 3 women
pub fn classic_three_couples_test() {
  // Men's preferences (1, 2, 3 are men; 101, 102, 103 are women)
  let men_prefs =
    dict.from_list([
      #(1, [101, 102, 103]),
      #(2, [102, 101, 103]),
      #(3, [101, 102, 103]),
    ])

  // Women's preferences
  let women_prefs =
    dict.from_list([
      #(101, [2, 1, 3]),
      #(102, [1, 2, 3]),
      #(103, [1, 2, 3]),
    ])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Verify everyone is matched
  bipartite.get_partner(matching, 1)
  |> should.be_some()

  bipartite.get_partner(matching, 2)
  |> should.be_some()

  bipartite.get_partner(matching, 3)
  |> should.be_some()

  // Verify symmetry (if A is matched to B, then B is matched to A)
  let partner_1 = bipartite.get_partner(matching, 1) |> should.be_some()
  bipartite.get_partner(matching, partner_1)
  |> should.equal(Some(1))
}

// Verify stability: no blocking pair exists
pub fn stability_check_test() {
  let men_prefs =
    dict.from_list([
      #(1, [101, 102]),
      #(2, [102, 101]),
    ])

  let women_prefs =
    dict.from_list([
      #(101, [2, 1]),
      #(102, [1, 2]),
    ])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Check all matches
  let p1 = bipartite.get_partner(matching, 1) |> should.be_some()
  let p2 = bipartite.get_partner(matching, 2) |> should.be_some()

  // Verify it's a valid matching (one of two possible stable matchings)
  // Either (1->102, 2->101) or (1->101, 2->102)
  case p1 {
    102 -> p2 |> should.equal(101)
    101 -> p2 |> should.equal(102)
    _ -> panic as "Invalid matching"
  }
}

// Single pair
pub fn single_pair_test() {
  let left_prefs = dict.from_list([#(1, [101])])
  let right_prefs = dict.from_list([#(101, [1])])

  let matching = bipartite.stable_marriage(left_prefs, right_prefs)

  bipartite.get_partner(matching, 1)
  |> should.equal(Some(101))

  bipartite.get_partner(matching, 101)
  |> should.equal(Some(1))
}

// Empty preferences
pub fn empty_preferences_test() {
  let left_prefs = dict.new()
  let right_prefs = dict.new()

  let matching = bipartite.stable_marriage(left_prefs, right_prefs)

  bipartite.get_partner(matching, 1)
  |> should.equal(None)
}

// Medical residency matching (realistic example)
pub fn medical_residency_test() {
  // 4 residents, 4 hospitals
  let residents =
    dict.from_list([
      #(1, [101, 102, 103, 104]),
      // Resident 1 ranks hospitals
      #(2, [102, 104, 101, 103]),
      #(3, [103, 101, 104, 102]),
      #(4, [104, 103, 102, 101]),
    ])

  let hospitals =
    dict.from_list([
      #(101, [2, 1, 3, 4]),
      // Hospital 101 ranks residents
      #(102, [1, 3, 2, 4]),
      #(103, [3, 4, 1, 2]),
      #(104, [4, 2, 3, 1]),
    ])

  let matching = bipartite.stable_marriage(residents, hospitals)

  // Everyone should be matched
  bipartite.get_partner(matching, 1)
  |> should.be_some()
  bipartite.get_partner(matching, 2)
  |> should.be_some()
  bipartite.get_partner(matching, 3)
  |> should.be_some()
  bipartite.get_partner(matching, 4)
  |> should.be_some()

  // Check bidirectionality
  let h1 = bipartite.get_partner(matching, 1) |> should.be_some()
  bipartite.get_partner(matching, h1)
  |> should.equal(Some(1))
}

// Unbalanced groups (more proposers than receivers)
pub fn unbalanced_groups_test() {
  // 3 men but only 2 women
  let men_prefs =
    dict.from_list([#(1, [101, 102]), #(2, [102, 101]), #(3, [101, 102])])

  let women_prefs = dict.from_list([#(101, [1, 2, 3]), #(102, [2, 1, 3])])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Two men should be matched, one should not
  let matched_count =
    [1, 2, 3]
    |> list.filter(fn(man) {
      case bipartite.get_partner(matching, man) {
        Some(_) -> True
        None -> False
      }
    })
    |> list.length()

  matched_count
  |> should.equal(2)
}

// Proposer optimal: men proposing ensures stable matching
pub fn proposer_optimal_test() {
  // Setup with conflicting preferences
  let men_prefs =
    dict.from_list([
      #(1, [101, 102, 103]),
      #(2, [101, 102, 103]),
      #(3, [101, 102, 103]),
    ])

  // Women prefer in opposite order
  let women_prefs =
    dict.from_list([
      #(101, [3, 2, 1]),
      #(102, [3, 2, 1]),
      #(103, [3, 2, 1]),
    ])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // The unique stable matching has women getting their top choices
  // (Since they're "choosing" among proposers)
  bipartite.get_partner(matching, 101)
  |> should.equal(Some(3))

  bipartite.get_partner(matching, 102)
  |> should.equal(Some(2))

  bipartite.get_partner(matching, 103)
  |> should.equal(Some(1))

  // Everyone should be matched
  bipartite.get_partner(matching, 1)
  |> should.be_some()
  bipartite.get_partner(matching, 2)
  |> should.be_some()
  bipartite.get_partner(matching, 3)
  |> should.be_some()
}

// All prefer same person (contention)
pub fn high_contention_test() {
  let men_prefs =
    dict.from_list([
      #(1, [101, 102, 103]),
      #(2, [101, 102, 103]),
      #(3, [101, 102, 103]),
    ])

  let women_prefs =
    dict.from_list([#(101, [1, 2, 3]), #(102, [1, 2, 3]), #(103, [1, 2, 3])])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Everyone should eventually be matched (even if not to first choice)
  bipartite.get_partner(matching, 1)
  |> should.be_some()
  bipartite.get_partner(matching, 2)
  |> should.be_some()
  bipartite.get_partner(matching, 3)
  |> should.be_some()

  // All three women should be matched
  bipartite.get_partner(matching, 101)
  |> should.be_some()
  bipartite.get_partner(matching, 102)
  |> should.be_some()
  bipartite.get_partner(matching, 103)
  |> should.be_some()
}

// Verify no duplicates in matching
pub fn no_duplicate_matches_test() {
  let men_prefs =
    dict.from_list([#(1, [101, 102]), #(2, [101, 102]), #(3, [102, 101])])

  let women_prefs = dict.from_list([#(101, [1, 2, 3]), #(102, [2, 3, 1])])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Get all men's partners
  let partners =
    [1, 2, 3]
    |> list.filter_map(fn(man) {
      bipartite.get_partner(matching, man)
      |> option.to_result(Nil)
    })

  // Should have no duplicates
  let unique_partners = set.from_list(partners) |> set.size()
  let total_partners = list.length(partners)

  unique_partners
  |> should.equal(total_partners)
}

// Incomplete preferences (not everyone ranks everyone)
pub fn incomplete_preferences_test() {
  // Man 1 only wants woman 101, won't accept 102
  let men_prefs = dict.from_list([#(1, [101]), #(2, [101, 102])])

  let women_prefs = dict.from_list([#(101, [2, 1]), #(102, [2])])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // Man 1 might not be matched if woman 101 prefers man 2
  // But man 2 should be matched
  bipartite.get_partner(matching, 2)
  |> should.be_some()
}

// Large instance (10 couples)
pub fn large_instance_test() {
  let men_prefs =
    dict.from_list([
      #(1, [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]),
      #(2, [102, 101, 103, 104, 105, 106, 107, 108, 109, 110]),
      #(3, [103, 102, 101, 104, 105, 106, 107, 108, 109, 110]),
      #(4, [104, 103, 102, 101, 105, 106, 107, 108, 109, 110]),
      #(5, [105, 104, 103, 102, 101, 106, 107, 108, 109, 110]),
      #(6, [106, 105, 104, 103, 102, 101, 107, 108, 109, 110]),
      #(7, [107, 106, 105, 104, 103, 102, 101, 108, 109, 110]),
      #(8, [108, 107, 106, 105, 104, 103, 102, 101, 109, 110]),
      #(9, [109, 108, 107, 106, 105, 104, 103, 102, 101, 110]),
      #(10, [110, 109, 108, 107, 106, 105, 104, 103, 102, 101]),
    ])

  let women_prefs =
    dict.from_list([
      #(101, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]),
      #(102, [9, 10, 8, 7, 6, 5, 4, 3, 2, 1]),
      #(103, [8, 9, 10, 7, 6, 5, 4, 3, 2, 1]),
      #(104, [7, 8, 9, 10, 6, 5, 4, 3, 2, 1]),
      #(105, [6, 7, 8, 9, 10, 5, 4, 3, 2, 1]),
      #(106, [5, 6, 7, 8, 9, 10, 4, 3, 2, 1]),
      #(107, [4, 5, 6, 7, 8, 9, 10, 3, 2, 1]),
      #(108, [3, 4, 5, 6, 7, 8, 9, 10, 2, 1]),
      #(109, [2, 3, 4, 5, 6, 7, 8, 9, 10, 1]),
      #(110, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    ])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  // All 10 men should be matched
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  |> list.each(fn(man) {
    bipartite.get_partner(matching, man)
    |> should.be_some()
  })

  // All 10 women should be matched
  [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
  |> list.each(fn(woman) {
    bipartite.get_partner(matching, woman)
    |> should.be_some()
  })
}

// Query non-existent person
pub fn query_non_existent_test() {
  let men_prefs = dict.from_list([#(1, [101])])
  let women_prefs = dict.from_list([#(101, [1])])

  let matching = bipartite.stable_marriage(men_prefs, women_prefs)

  bipartite.get_partner(matching, 999)
  |> should.equal(None)
}
