import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import yog/bipartite

pub fn main() {
  io.println("--- Medical Residency Matching (NRMP Style) ---")
  io.println("")

  // Real-world scenario: 5 medical residents applying to 5 hospitals
  // Using the Gale-Shapley algorithm for stable matching

  // Residents and their hospital preferences (most preferred first)
  let residents =
    dict.from_list([
      #(1, [101, 102, 103, 104, 105]),
      // Dr. Anderson prefers City General most
      #(2, [102, 105, 101, 103, 104]),
      // Dr. Brown prefers Metro Hospital
      #(3, [103, 101, 104, 102, 105]),
      // Dr. Chen prefers University Med
      #(4, [104, 103, 105, 102, 101]),
      // Dr. Davis prefers Regional Care
      #(5, [105, 104, 103, 102, 101]),
      // Dr. Evans prefers Coastal Medical
    ])

  // Hospitals and their resident preferences (most preferred first)
  let hospitals =
    dict.from_list([
      #(101, [3, 1, 2, 4, 5]),
      // City General prefers Dr. Chen
      #(102, [1, 2, 5, 3, 4]),
      // Metro Hospital prefers Dr. Anderson
      #(103, [3, 4, 1, 2, 5]),
      // University Med prefers Dr. Chen
      #(104, [4, 5, 3, 2, 1]),
      // Regional Care prefers Dr. Davis
      #(105, [5, 2, 4, 3, 1]),
      // Coastal Medical prefers Dr. Evans
    ])

  io.println("Resident Preferences:")
  io.println(
    "  Dr. Anderson (1): City General, Metro, University, Regional, Coastal",
  )
  io.println(
    "  Dr. Brown (2):    Metro, Coastal, City General, University, Regional",
  )
  io.println(
    "  Dr. Chen (3):     University, City General, Regional, Metro, Coastal",
  )
  io.println(
    "  Dr. Davis (4):    Regional, University, Coastal, Metro, City General",
  )
  io.println(
    "  Dr. Evans (5):    Coastal, Regional, University, Metro, City General",
  )
  io.println("")

  io.println("Hospital Preferences:")
  io.println("  City General (101):  Chen, Anderson, Brown, Davis, Evans")
  io.println("  Metro Hospital (102): Anderson, Brown, Evans, Chen, Davis")
  io.println("  University Med (103): Chen, Davis, Anderson, Brown, Evans")
  io.println("  Regional Care (104):  Davis, Evans, Chen, Brown, Anderson")
  io.println("  Coastal Medical (105): Evans, Brown, Davis, Chen, Anderson")
  io.println("")

  // Run the Gale-Shapley algorithm
  let matching = bipartite.stable_marriage(residents, hospitals)

  io.println("=== Stable Matching Results ===")
  io.println("")

  // Display matches for each resident
  let resident_names = ["Anderson", "Brown", "Chen", "Davis", "Evans"]
  let hospital_names = [
    "City General", "Metro Hospital", "University Med", "Regional Care",
    "Coastal Medical",
  ]

  list_range(1, 5)
  |> list.each(fn(resident_id) {
    case bipartite.get_partner(matching, resident_id) {
      option.Some(hospital_id) -> {
        let resident_name = get_name(resident_names, resident_id - 1)
        let hospital_name = get_name(hospital_names, hospital_id - 101)
        let resident_rank = get_rank(residents, resident_id, hospital_id)
        let hospital_rank = get_rank(hospitals, hospital_id, resident_id)

        io.println(
          "Dr. "
          <> resident_name
          <> " (#"
          <> int.to_string(resident_id)
          <> ") matched to "
          <> hospital_name
          <> " (#"
          <> int.to_string(hospital_id)
          <> ")",
        )
        io.println(
          "  - Resident's rank for this hospital: "
          <> int.to_string(resident_rank)
          <> " of 5",
        )
        io.println(
          "  - Hospital's rank for this resident: "
          <> int.to_string(hospital_rank)
          <> " of 5",
        )
      }
      option.None -> {
        let resident_name = get_name(resident_names, resident_id - 1)
        io.println("Dr. " <> resident_name <> " was not matched")
      }
    }
  })

  io.println("")
  io.println("--- Properties of This Matching ---")
  io.println("✓ Stable: No resident-hospital pair would both prefer each other")
  io.println("✓ Complete: All participants are matched (groups are equal size)")
  io.println("✓ Resident-optimal: Residents get best stable outcome possible")
  io.println("✓ Hospital-pessimal: Hospitals get worst stable outcome possible")
  io.println("")
  io.println("This is the same algorithm used by the real NRMP!")
}

// Helper: Get name from list
fn get_name(names: List(String), index: Int) -> String {
  case list_at(names, index) {
    option.Some(name) -> name
    option.None -> "Unknown"
  }
}

// Helper: Get preference rank (1-indexed)
fn get_rank(prefs: dict.Dict(Int, List(Int)), person: Int, target: Int) -> Int {
  case dict.get(prefs, person) {
    Ok(pref_list) -> {
      case list_index_of(pref_list, target) {
        option.Some(idx) -> idx + 1
        option.None -> 999
      }
    }
    Error(_) -> 999
  }
}

// Helper: Get element at index
fn list_at(lst: List(a), index: Int) -> option.Option(a) {
  case index, lst {
    0, [first, ..] -> option.Some(first)
    n, [_, ..rest] if n > 0 -> list_at(rest, n - 1)
    _, _ -> option.None
  }
}

// Helper: Find index of element in list
fn list_index_of(lst: List(a), target: a) -> option.Option(Int) {
  do_index_of(lst, target, 0)
}

fn do_index_of(lst: List(a), target: a, current: Int) -> option.Option(Int) {
  case lst {
    [] -> option.None
    [first, ..rest] ->
      case first == target {
        True -> option.Some(current)
        False -> do_index_of(rest, target, current + 1)
      }
  }
}

// Helper: Generate range [start..end] inclusive
fn list_range(start: Int, end: Int) -> List(Int) {
  case start > end {
    True -> []
    False -> [start, ..list_range(start + 1, end)]
  }
}
