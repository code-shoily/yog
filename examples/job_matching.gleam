import gleam/int
import gleam/io
import yog
import yog/max_flow
import yog/model

pub fn main() {
  io.println("=== Job Matching with Max Flow ===\n")

  // Model a bipartite matching problem as max flow
  // We have 4 candidates and 4 jobs
  // Each candidate is qualified for certain jobs
  //
  // Network structure:
  //   Source (0) -> Candidates (1-4) -> Jobs (5-8) -> Sink (9)
  //   All edges have capacity 1 (can only assign one candidate per job)

  io.println("Candidates and their qualifications:")
  io.println(
    "  Alice (1): Qualified for Software Engineer (5), Data Analyst (6)",
  )
  io.println(
    "  Bob (2): Qualified for Software Engineer (5), Project Manager (7)",
  )
  io.println("  Carol (3): Qualified for Data Analyst (6), Designer (8)")
  io.println("  Dave (4): Qualified for Project Manager (7), Designer (8)\n")

  let network =
    yog.directed()
    // Source to candidates (capacity 1 - each candidate can take one job)
    |> yog.add_edge(from: 0, to: 1, with: 1)
    // Source -> Alice
    |> yog.add_edge(from: 0, to: 2, with: 1)
    // Source -> Bob
    |> yog.add_edge(from: 0, to: 3, with: 1)
    // Source -> Carol
    |> yog.add_edge(from: 0, to: 4, with: 1)
    // Source -> Dave
    // Candidate qualifications (who can do which job)
    |> yog.add_edge(from: 1, to: 5, with: 1)
    // Alice -> Software Engineer
    |> yog.add_edge(from: 1, to: 6, with: 1)
    // Alice -> Data Analyst
    |> yog.add_edge(from: 2, to: 5, with: 1)
    // Bob -> Software Engineer
    |> yog.add_edge(from: 2, to: 7, with: 1)
    // Bob -> Project Manager
    |> yog.add_edge(from: 3, to: 6, with: 1)
    // Carol -> Data Analyst
    |> yog.add_edge(from: 3, to: 8, with: 1)
    // Carol -> Designer
    |> yog.add_edge(from: 4, to: 7, with: 1)
    // Dave -> Project Manager
    |> yog.add_edge(from: 4, to: 8, with: 1)
    // Dave -> Designer
    // Jobs to sink (capacity 1 - each job needs one person)
    |> yog.add_edge(from: 5, to: 9, with: 1)
    // Software Engineer -> Sink
    |> yog.add_edge(from: 6, to: 9, with: 1)
    // Data Analyst -> Sink
    |> yog.add_edge(from: 7, to: 9, with: 1)
    // Project Manager -> Sink
    |> yog.add_edge(from: 8, to: 9, with: 1)
  // Designer -> Sink

  // Find maximum matching
  let result =
    max_flow.edmonds_karp(
      in: network,
      from: 0,
      to: 9,
      with_zero: 0,
      with_add: int.add,
      with_subtract: fn(a, b) { a - b },
      with_compare: int.compare,
      with_min: int.min,
    )

  io.println(
    "Maximum matching: "
    <> int.to_string(result.max_flow)
    <> " people can be assigned to jobs",
  )

  case result.max_flow == 4 {
    True -> io.println("Perfect matching! All jobs can be filled.")
    False ->
      io.println(
        "Only "
        <> int.to_string(result.max_flow)
        <> " jobs can be filled with qualified candidates.",
      )
  }

  // Extract the actual assignments from the residual graph
  io.println("\nAssignments (by analyzing flow):")
  io.println(
    "To see actual assignments, check which edges from candidates to jobs have flow > 0",
  )

  // Check residual capacities to find assignments
  // If an edge from candidate -> job has reduced capacity, there's flow on it
  let assignments =
    extract_assignments(
      result.residual_graph,
      network,
      [
        #(1, "Alice"),
        #(2, "Bob"),
        #(3, "Carol"),
        #(4, "Dave"),
      ],
      [
        #(5, "Software Engineer"),
        #(6, "Data Analyst"),
        #(7, "Project Manager"),
        #(8, "Designer"),
      ],
    )

  print_assignments(assignments)
}

fn extract_assignments(
  residual: model.Graph(Nil, Int),
  original: model.Graph(Nil, Int),
  candidates: List(#(Int, String)),
  jobs: List(#(Int, String)),
) -> List(#(String, String)) {
  // For each candidate, check which job they were assigned to
  // By looking at edges where original capacity > residual capacity
  case candidates {
    [] -> []
    [#(candidate_id, candidate_name), ..rest_candidates] -> {
      let assignment =
        find_assignment(residual, original, candidate_id, candidate_name, jobs)
      case assignment {
        Ok(match) -> [
          match,
          ..extract_assignments(residual, original, rest_candidates, jobs)
        ]
        Error(_) ->
          extract_assignments(residual, original, rest_candidates, jobs)
      }
    }
  }
}

fn find_assignment(
  residual: model.Graph(Nil, Int),
  original: model.Graph(Nil, Int),
  candidate_id: Int,
  candidate_name: String,
  jobs: List(#(Int, String)),
) -> Result(#(String, String), Nil) {
  case jobs {
    [] -> Error(Nil)
    [#(job_id, job_name), ..rest_jobs] -> {
      // Check if there's flow on this edge
      let original_capacity =
        model.successors(original, candidate_id)
        |> find_edge_weight(job_id)

      let residual_capacity =
        model.successors(residual, candidate_id)
        |> find_edge_weight(job_id)

      case original_capacity, residual_capacity {
        1, 0 -> Ok(#(candidate_name, job_name))
        _, _ ->
          find_assignment(
            residual,
            original,
            candidate_id,
            candidate_name,
            rest_jobs,
          )
      }
    }
  }
}

fn find_edge_weight(edges: List(#(Int, Int)), target: Int) -> Int {
  case edges {
    [] -> 0
    [#(node, weight), ..rest] ->
      case node == target {
        True -> weight
        False -> find_edge_weight(rest, target)
      }
  }
}

fn print_assignments(assignments: List(#(String, String))) -> Nil {
  case assignments {
    [] -> Nil
    [#(candidate, job), ..rest] -> {
      io.println("  " <> candidate <> " -> " <> job)
      print_assignments(rest)
    }
  }
}
