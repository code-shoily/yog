import gleam/io
import gleam/string
import yog
import yog/model
import yog/traversal

pub fn main() {
  // Model tasks with dependencies
  let tasks =
    yog.from_unweighted_edges(model.Directed, [
      #(1, 2),
      // Design (1) -> Implement (2)
      #(2, 3),
      // Implement (2) -> Test (3)
      #(3, 4),
      // Test (3) -> Deploy (4)
    ])

  case traversal.topological_sort(tasks) {
    Ok(order) -> {
      // order = [1, 2, 3, 4] - valid execution order
      io.println("Execute tasks in order: " <> string.inspect(order))
    }
    Error(Nil) -> io.println("Circular dependency detected!")
  }
}
