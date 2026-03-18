import gleam/io
import gleam/string
import yog/model.{Directed}
import yog/traversal

pub fn main() {
  // Model tasks with dependencies
  let tasks =
    model.new(Directed)
    |> model.add_node(1, "Design")
    |> model.add_node(2, "Implement")
    |> model.add_node(3, "Test")
    |> model.add_node(4, "Deploy")
  // Design before Implement
  let assert Ok(tasks) = model.add_edge(tasks, from: 1, to: 2, with: Nil)
  // Implement before Test
  let assert Ok(tasks) = model.add_edge(tasks, from: 2, to: 3, with: Nil)
  // Test before Deploy
  let assert Ok(tasks) = model.add_edge(tasks, from: 3, to: 4, with: Nil)

  case traversal.topological_sort(tasks) {
    Ok(order) -> {
      // order = [1, 2, 3, 4] - valid execution order
      io.println("Execute tasks in order: " <> string.inspect(order))
    }
    Error(Nil) -> io.println("Circular dependency detected!")
  }
}
