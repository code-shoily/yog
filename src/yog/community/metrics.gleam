//// Metrics for evaluating community structure and topological properties.
////
//// Provides various metrics to measure the quality of detected communities
//// and analyze graph topology including modularity, clustering coefficients,
//// and triangle counts.
////
//// ## Metrics
////
//// | Metric | Function | Use Case |
//// |--------|----------|----------|
//// | Modularity | `modularity/2` | Quality of community partition |
//// | Triangle Count | `count_triangles/1` | Global clustering measure |
//// | Local Clustering | `clustering_coefficient/2` | Node-level clustering |
//// | Global Clustering | `average_clustering_coefficient/1` | Graph-wide clustering |
//// | Density | `density/1` | Edge density of graph |
//// | Community Density | `community_density/2` | Internal edge density |
////
//// ## Modularity
////
//// Modularity Q measures the density of edges inside communities compared to
//// what would be expected by chance. Ranges from -1 to 1, with positive values
//// indicating community structure better than random.
////
//// ## Example
////
//// ```gleam
//// import yog
//// import yog/community/louvain
//// import yog/community/metrics
////
//// let graph = // ... build graph
////
//// // Detect communities and evaluate
//// let communities = louvain.detect(graph)
//// let q = metrics.modularity(graph, communities)
//// // q > 0.3 generally indicates good community structure
////
//// // Graph topology metrics
//// let triangles = metrics.count_triangles(graph)
//// let avg_clustering = metrics.average_clustering_coefficient(graph)
//// let graph_density = metrics.density(graph)
////
//// // Community-specific metrics
//// let community_dict = community.communities_to_dict(communities)
//// let first_comm = case dict.get(community_dict, 0) {
////   Ok(nodes) -> metrics.community_density(graph, nodes)
////   Error(Nil) -> 0.0
//// }
//// ```

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/set
import yog
import yog/community.{type Communities}
import yog/model.{type Graph, type NodeId}

/// Calculates Newman's modularity Q for an undirected graph.
///
/// Q measures the density of edges inside communities compared to
/// what would be expected by chance.
///
/// Time Complexity: O(E)
pub fn modularity(graph: Graph(n, Int), communities: Communities) -> Float {
  let m =
    {
      list.fold(model.all_nodes(graph), 0.0, fn(acc, u) {
        let weight_sum =
          yog.successors(graph, u)
          |> list.fold(0, fn(sum, edge) { sum + edge.1 })
        acc +. int.to_float(weight_sum)
      })
    }
    /. 2.0
  case m == 0.0 {
    True -> 0.0
    False -> {
      let two_m = 2.0 *. m
      let degree_map =
        list.map(model.all_nodes(graph), fn(u) {
          let weight_sum =
            yog.successors(graph, u)
            |> list.fold(0, fn(sum, edge) { sum + edge.1 })
          #(u, int.to_float(weight_sum))
        })
        |> dict.from_list

      let communities_dict = community.communities_to_dict(communities)

      dict.fold(over: communities_dict, from: 0.0, with: fn(acc, _id, nodes) {
        let node_list = set.to_list(nodes)
        let sum_in = {
          use inner_acc, u <- list.fold(over: node_list, from: 0.0)
          let sucs = yog.successors(graph, u)
          use innermost_acc, #(v, weight) <- list.fold(
            over: sucs,
            from: inner_acc,
          )
          case set.contains(nodes, v) {
            True -> innermost_acc +. int.to_float(weight)
            False -> innermost_acc
          }
        }

        let sum_deg = {
          use inner_acc, u <- list.fold(over: node_list, from: 0.0)
          let k_u =
            dict.get(degree_map, u) |> option.from_result |> option.unwrap(0.0)
          inner_acc +. k_u
        }

        acc
        +. { sum_in /. two_m }
        -. { { sum_deg *. sum_deg } /. { two_m *. two_m } }
      })
    }
  }
}

/// Count total triangles in the graph.
/// A triangle is a set of three nodes where all are connected.
/// 
/// Time Complexity: O(V * k^2) where k is average degree.
pub fn count_triangles(graph: Graph(n, e)) -> Int {
  triangles_per_node(graph)
  |> dict.values
  |> int.sum
  |> int.divide(3)
  |> option.from_result
  |> option.unwrap(0)
}

/// Returns a dictionary mapping each node to the number of triangles it participates in.
pub fn triangles_per_node(graph: Graph(n, e)) -> Dict(NodeId, Int) {
  let nodes = model.all_nodes(graph)
  list.fold(over: nodes, from: dict.new(), with: fn(acc, u) {
    let neighbors =
      yog.successors(graph, u)
      |> list.map(fn(pair) { pair.0 })
      |> set.from_list

    let count = {
      use inner_acc, v <- list.fold(over: set.to_list(neighbors), from: 0)
      let v_neighbors =
        yog.successors(graph, v)
        |> list.map(fn(pair) { pair.0 })
        |> set.from_list

      // Intersection size
      inner_acc + set.size(set.intersection(neighbors, v_neighbors))
    }
    // Each triangle u-v-w is counted twice for u (once as v-w, once as w-v)
    dict.insert(acc, u, count / 2)
  })
}

/// Calculates the local clustering coefficient for a node.
pub fn clustering_coefficient(graph: Graph(n, e), node: NodeId) -> Float {
  let neighbors = yog.successors(graph, node)
  let k = list.length(neighbors)
  case k < 2 {
    True -> 0.0
    False -> {
      let t =
        dict.get(triangles_per_node(graph), node)
        |> option.from_result
        |> option.unwrap(0)
      2.0 *. int.to_float(t) /. int.to_float({ k * { k - 1 } })
    }
  }
}

/// Calculates the average clustering coefficient for the entire graph.
pub fn average_clustering_coefficient(graph: Graph(n, e)) -> Float {
  let nodes = model.all_nodes(graph)
  let n = list.length(nodes)
  case n == 0 {
    True -> 0.0
    False -> {
      let sum =
        list.fold(over: nodes, from: 0.0, with: fn(acc, u) {
          acc +. clustering_coefficient(graph, u)
        })
      sum /. int.to_float(n)
    }
  }
}

/// Graph density: ratio of actual edges to maximum possible edges.
pub fn density(graph: Graph(n, e)) -> Float {
  let n = int.to_float(model.order(graph))
  let e = int.to_float(model.edge_count(graph))
  case n <. 2.0 {
    True -> 0.0
    False -> e /. { n *. { n -. 1.0 } }
  }
}

/// Density within a community (ratio of internal edges to possible edges).
pub fn community_density(
  graph: Graph(n, e),
  community: set.Set(model.NodeId),
) -> Float {
  let nodes = set.to_list(community)
  let num_nodes = int.to_float(list.length(nodes))

  case num_nodes <. 2.0 {
    True -> 0.0
    False -> {
      let internal_edges =
        list.fold(over: nodes, from: 0, with: fn(acc, u) {
          let sucs = yog.successors(graph, u)
          list.fold(over: sucs, from: acc, with: fn(inner_acc, pair) {
            let #(v, _weight) = pair
            case set.contains(community, v) && u < v {
              True -> inner_acc + 1
              False -> inner_acc
            }
          })
        })

      let max_edges = num_nodes *. { num_nodes -. 1.0 } /. 2.0
      int.to_float(internal_edges) /. max_edges
    }
  }
}

/// Average density across all communities.
pub fn average_community_density(
  graph: Graph(n, e),
  communities: Communities,
) -> Float {
  let community_dict = community.communities_to_dict(communities)
  let num_communities = dict.size(community_dict)

  case num_communities == 0 {
    True -> 0.0
    False -> {
      let total_density =
        dict.fold(over: community_dict, from: 0.0, with: fn(acc, _id, nodes) {
          acc +. community_density(graph, nodes)
        })

      total_density /. int.to_float(num_communities)
    }
  }
}
