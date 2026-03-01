import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import yog/model
import yog/topological_sort

pub fn main() {
  // Model task dependencies where we want alphabetically earliest valid order
  // Task B requires A to be completed first, etc.
  let dependencies = [
    #("C", "A"),
    // C must be done before A
    #("C", "F"),
    // C must be done before F
    #("A", "B"),
    // A must be done before B
    #("A", "D"),
    // A must be done before D
    #("B", "E"),
    // B must be done before E
    #("D", "E"),
    // D must be done before E
    #("F", "E"),
    // F must be done before E
  ]

  // Use ASCII codes as node IDs so int.compare gives alphabetical order
  let graph =
    dependencies
    |> list.fold(model.new(model.Directed), fn(g, dep) {
      let #(prereq, step) = dep
      let prereq_id = char_to_ascii(prereq)
      let step_id = char_to_ascii(step)

      g
      |> model.add_node(prereq_id, prereq)
      |> model.add_node(step_id, step)
      |> model.add_edge(from: prereq_id, to: step_id, with: Nil)
    })

  case
    topological_sort.lexicographical_topological_sort(graph, string.compare)
  {
    Ok(order) -> {
      let task_order =
        order
        |> list.map(fn(id) {
          let assert Ok(task) = dict.get(graph.nodes, id)
          task
        })
        |> string.join("")

      // Prints: Task execution order: CABDFE
      io.println("Task execution order: " <> task_order)
    }
    Error(Nil) -> io.println("Circular dependency detected!")
  }
}

fn char_to_ascii(s: String) -> Int {
  let assert Ok(codepoint) = string.to_utf_codepoints(s) |> list.first
  string.utf_codepoint_to_int(codepoint)
}
