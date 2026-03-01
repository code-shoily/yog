import gleam/dict
import gleam/list
import gleam/order.{type Order}
import gleam/set.{type Set}
import gleamy/priority_queue
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
    dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
      let inner_edges =
        dict.fold(targets, [], fn(inner_acc, to_id, weight) {
          // For Undirected, only keep edges where from < to to avoid duplicates
          case graph.kind == Undirected && from_id > to_id {
            True -> inner_acc
            False -> [
              Edge(from: from_id, to: to_id, weight: weight),
              ..inner_acc
            ]
          }
        })
      list.flatten([inner_edges, acc])
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

/// Finds the Minimum Spanning Tree (MST) using Prim's algorithm.
///
/// Returns a list of edges that form the MST. Unlike Kruskal's which processes
/// all edges globally, Prim's grows the MST from a starting node by repeatedly
/// adding the minimum-weight edge that connects a visited node to an unvisited node.
///
/// **Time Complexity:** O(E log V) where E is the number of edges and V is the number of vertices
///
/// ## Example
///
/// ```gleam
/// let mst_edges = mst.prim(in: graph, with_compare: int.compare)
/// // => [Edge(1, 2, 5), Edge(2, 3, 3), ...]
/// ```
pub fn prim(
  in graph: Graph(n, e),
  with_compare compare: fn(e, e) -> Order,
) -> List(Edge(e)) {
  let node_ids = dict.keys(graph.nodes)

  case node_ids {
    [] -> []
    [start, ..] -> {
      // Create priority queue with edge comparison
      let edge_compare = fn(a: Edge(e), b: Edge(e)) {
        compare(a.weight, b.weight)
      }

      let initial_pq = priority_queue.new(edge_compare)
      let initial_visited = set.from_list([start])

      // Add all edges from the start node to the priority queue
      let initial_edges = get_edges_from_node(graph, start)
      let pq_with_initial_edges =
        list.fold(initial_edges, initial_pq, fn(pq, edge) {
          priority_queue.push(pq, edge)
        })

      do_prim(graph, pq_with_initial_edges, initial_visited, [])
    }
  }
}

fn do_prim(
  graph: Graph(n, e),
  pq: priority_queue.Queue(Edge(e)),
  visited: Set(NodeId),
  acc: List(Edge(e)),
) -> List(Edge(e)) {
  case priority_queue.pop(pq) {
    Error(Nil) -> list.reverse(acc)
    Ok(#(edge, rest_pq)) -> {
      // Skip if the target node is already visited
      case set.contains(visited, edge.to) {
        True -> do_prim(graph, rest_pq, visited, acc)
        False -> {
          // Add the edge to MST and mark node as visited
          let new_visited = set.insert(visited, edge.to)
          let new_acc = [edge, ..acc]

          // Add all edges from the newly visited node to unvisited nodes
          let new_edges = get_edges_from_node(graph, edge.to)
          let filtered_edges =
            list.filter(new_edges, fn(e) { !set.contains(new_visited, e.to) })

          let new_pq =
            list.fold(filtered_edges, rest_pq, fn(pq, e) {
              priority_queue.push(pq, e)
            })

          do_prim(graph, new_pq, new_visited, new_acc)
        }
      }
    }
  }
}

// Helper function to get all edges from a node
fn get_edges_from_node(graph: Graph(n, e), from: NodeId) -> List(Edge(e)) {
  case dict.get(graph.out_edges, from) {
    Ok(targets) ->
      dict.fold(targets, [], fn(acc, to_id, weight) {
        // For undirected graphs, avoid creating duplicate edges
        case graph.kind == Undirected && from > to_id {
          True -> acc
          False -> [Edge(from: from, to: to_id, weight: weight), ..acc]
        }
      })
    Error(Nil) -> []
  }
}
