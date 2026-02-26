import gleam/dict
import gleam/list
import gleam/order.{type Order}
import yog/internal/dsu
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
  // 1. Get all nodes from your model.nodes Dict
  let node_ids = dict.keys(graph.nodes)

  // 2. Derive all unique edges from out_edges
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

  // 3. Setup DSU
  let initial_dsu = list.fold(node_ids, dsu.new(), dsu.add)

  do_kruskal(edges, initial_dsu, [])
}

fn do_kruskal(
  edges: List(Edge(e)),
  dsu_state: dsu.DisjointSet(NodeId),
  acc: List(Edge(e)),
) {
  case edges {
    [] -> list.reverse(acc)
    [edge, ..rest] -> {
      let #(dsu1, root_from) = dsu.find(dsu_state, edge.from)
      let #(dsu2, root_to) = dsu.find(dsu1, edge.to)

      case root_from == root_to {
        True -> do_kruskal(rest, dsu2, acc)
        False -> {
          let next_dsu = dsu.union(dsu2, edge.from, edge.to)
          do_kruskal(rest, next_dsu, [edge, ..acc])
        }
      }
    }
  }
}
