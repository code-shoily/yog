import gleam/float
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import yog/internal/util
import yog/model
import yog/pathfinding/path as p_path
import yog/render/dot
import yog/render/mermaid

pub fn dot_quote_escaping_test() {
  let graph =
    model.new(model.Directed) |> model.add_node(1, "Node \"With\" Quotes")
  let options =
    dot.default_dot_options_with(
      node_label: fn(_, data) { data },
      edge_label: fn(w) { w },
    )
  let result = dot.to_dot(graph, options)

  // Should contain escaped quotes: \"
  string.contains(result, "label=\"Node \\\"With\\\" Quotes\"")
  |> should.be_true()
}

pub fn mermaid_quote_escaping_test() {
  let graph =
    model.new(model.Directed)
    |> model.add_node(1, "Node \"With\" Quotes")
    |> model.add_node(2, "Ok")

  let options =
    mermaid.MermaidOptions(..mermaid.default_options(), node_label: fn(_, data) {
      data
    })
  let result = mermaid.to_mermaid(graph, options)

  // Our implementation uses #quot;
  string.contains(result, "Node #quot;With#quot; Quotes")
  |> should.be_true()
}

pub fn dot_path_to_edges_large_test() {
  // Generate a long path to check tail recursion 
  let nodes = util.range(0, 1000)
  let edges =
    dot.path_to_dot_options(
      p_path.Path(nodes: nodes, total_weight: 0.0),
      dot.default_dot_options_with_edge_formatter(float.to_string),
    ).highlighted_edges

  case edges {
    Some(e) -> list.length(e) |> should.equal(1000)
    _ -> panic
  }
}
