import gleam/dict
import gleam/list
import gleam/order.{type Order}
import yog/disjoint_set
import yog/model.{type Graph, type NodeId, Undirected}

/// Represents an edge in the minimum spanning tree.
pub type Edge(e) {
  Edge(from: NodeId, to: NodeId, weight: e)
}

/// Finds the Minimum Spanning Tree (MST) using Kruskal's algorithm.
///
/// Returns a list of edges that form the MST. The total weight of these edges
/// is minimized while ensuring all nodes are connected.
///
/// **Time Complexity:** O(E log E) where E is the number of edges
///
/// ## Example
///
/// ```gleam
/// let mst_edges = mst.kruskal(in: graph, with_compare: int.compare)
/// // => [Edge(1, 2, 5), Edge(2, 3, 3), ...]
/// ```
pub fn kruskal(
  in graph: Graph(n, e),
  with_compare compare: fn(e, e) -> Order,
) -> List(Edge(e)) {
  let node_ids = dict.keys(graph.nodes)
  let edges =
    dict.to_list(graph.out_edges)
    |> list.flat_map(fn(entry) {
      let #(from_id, targets) = entry
      dict.to_list(targets)
      |> list.filter_map(fn(target) {
        let #(to_id, weight) = target
        // For Undirected, only keep edges where from < to to avoid duplicates
        case graph.kind == Undirected && from_id > to_id {
          True -> Error(Nil)
          False -> Ok(Edge(from: from_id, to: to_id, weight: weight))
        }
      })
    })
    |> list.sort(fn(a, b) { compare(a.weight, b.weight) })

  let initial_disjoint_set =
    list.fold(node_ids, disjoint_set.new(), disjoint_set.add)

  do_kruskal(edges, initial_disjoint_set, [])
}

fn do_kruskal(
  edges: List(Edge(e)),
  disjoint_set_state: disjoint_set.DisjointSet(NodeId),
  acc: List(Edge(e)),
) {
  case edges {
    [] -> list.reverse(acc)
    [edge, ..rest] -> {
      let #(disjoint_set1, root_from) =
        disjoint_set.find(disjoint_set_state, edge.from)
      let #(disjoint_set2, root_to) = disjoint_set.find(disjoint_set1, edge.to)

      case root_from == root_to {
        True -> do_kruskal(rest, disjoint_set2, acc)
        False -> {
          let next_disjoint_set =
            disjoint_set.union(disjoint_set2, edge.from, edge.to)
          do_kruskal(rest, next_disjoint_set, [edge, ..acc])
        }
      }
    }
  }
}
