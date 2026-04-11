//// Minimum Spanning Tree (MST) algorithms for finding optimal network connections.
////
//// A [Minimum Spanning Tree](https://en.wikipedia.org/wiki/Minimum_spanning_tree) connects all nodes
//// in a weighted undirected graph with the minimum possible total edge weight. MSTs have
//// applications in network design, clustering, and optimization problems.
////
//// ## Available Algorithms
////
//// | Algorithm | Function | Best For |
//// |-----------|----------|----------|
//// | [Kruskal's](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm) | `kruskal/4` | Sparse graphs, edge lists |
//// | [Prim's](https://en.wikipedia.org/wiki/Prim%27s_algorithm) | `prim/4` | Dense graphs, adjacency-based |
//// | [Borůvka's](https://en.wikipedia.org/wiki/Bor%C5%AFvka%27s_algorithm) | `boruvka/4` | Parallel/distributed MST |
//// | [Chu-Liu/Edmonds](https://en.wikipedia.org/wiki/Edmonds%27_algorithm) | `edmonds/6` | Directed MSA (arborescence) |
//// | Wilson's | `wilson/2` | Uniform random spanning tree |
////
//// ## Properties of MSTs
////
//// - Connects all nodes with exactly `V - 1` edges (for a graph with V nodes)
//// - Contains no cycles
//// - Minimizes the sum of edge weights
//// - May not be unique if multiple edges have the same weight
////
//// ## Maximum Spanning Trees
////
//// While these functions are named for Minimum Spanning Trees, they are fully
//// generic. To find a **Maximum Spanning Tree**, simply provide a comparator
//// that reverses the natural order of your weights (e.g., using `order.reverse(int.compare)`).
//// This will cause the algorithms to prioritize the largest weights first,
//// yielding the maximum possible total weight.
////
//// > [!TIP]
//// > **Widest Path Problem**: In an undirected graph, the unique path between two nodes
//// > in a Maximum Spanning Tree is also a **widest path** (or maximum capacity path).
//// > If you need to find a path that maximizes the bottleneck capacity between two
//// > nodes, you can calculate the MaxST and then find the path in that tree.
////
//// ## Example Use Cases
////
//// - **Network Design**: Minimizing cable length to connect buildings
//// - **Cluster Analysis**: Hierarchical clustering via MST
//// - **Approximation**: Traveling Salesman Problem approximations
//// - **Image Segmentation**: Computer vision applications
////
//// ## References
////
//// - [Wikipedia: Minimum Spanning Tree](https://en.wikipedia.org/wiki/Minimum_spanning_tree)
//// - [CP-Algorithms: MST](https://cp-algorithms.com/graph/mst_kruskal.html)

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import gleam/set.{type Set}
import yog/disjoint_set
import yog/internal/priority_queue
import yog/internal/random
import yog/internal/util
import yog/model.{type Graph, type NodeId, Directed, Undirected}

/// Algorithm used to compute the spanning tree result.
pub type Algorithm {
  Kruskal
  Prim
  Boruvka
  ChuLiuEdmonds
  Wilson
}

/// Represents an edge in the minimum spanning tree.
pub type Edge(e) {
  Edge(from: NodeId, to: NodeId, weight: e)
}

/// Result of a Minimum Spanning Tree computation.
pub type MstResult(e) {
  MstResult(
    edges: List(Edge(e)),
    total_weight: e,
    node_count: Int,
    edge_count: Int,
    algorithm: Algorithm,
    root: Option(NodeId),
  )
}

// =============================================================================
// KRUSKAL'S ALGORITHM
// =============================================================================

/// Finds the Minimum Spanning Tree (MST) using Kruskal's algorithm.
///
/// **Time Complexity:** O(E log E)
pub fn kruskal(
  in graph: Graph(n, e),
  with_compare compare: fn(e, e) -> Order,
  with_add add: fn(e, e) -> e,
  with_zero zero: e,
) -> MstResult(e) {
  let edges =
    extract_undirected_edges(graph)
    |> list.sort(fn(a, b) { compare(a.weight, b.weight) })
  let mst_edges = do_kruskal(edges, disjoint_set.new(), [])
  make_result(mst_edges, Kruskal, dict.size(graph.nodes), None, add, zero)
}

fn do_kruskal(
  edges: List(Edge(e)),
  disjoint_set_state: disjoint_set.DisjointSet(NodeId),
  acc: List(Edge(e)),
) -> List(Edge(e)) {
  case edges {
    [] -> list.reverse(acc)
    [edge, ..rest] -> {
      let #(disjoint_set1, root_from) =
        disjoint_set_state
        |> disjoint_set.find(edge.from)
      let #(disjoint_set2, root_to) =
        disjoint_set1
        |> disjoint_set.find(edge.to)
      case root_from == root_to {
        True -> do_kruskal(rest, disjoint_set2, acc)
        False -> {
          disjoint_set2
          |> disjoint_set.union(edge.from, edge.to)
          |> do_kruskal(rest, _, [edge, ..acc])
        }
      }
    }
  }
}

// =============================================================================
// PRIM'S ALGORITHM
// =============================================================================

/// Finds the Minimum Spanning Tree (MST) using Prim's algorithm.
///
/// **Time Complexity:** O(E log V)
///
/// **Disconnected Graphs:** For disconnected graphs, Prim's only returns edges
/// for the connected component containing the starting node.
pub fn prim(
  in graph: Graph(n, e),
  with_compare compare: fn(e, e) -> Order,
  with_add add: fn(e, e) -> e,
  with_zero zero: e,
) -> MstResult(e) {
  let mst_edges = case dict.keys(graph.nodes) {
    [] -> []
    [start, ..] -> {
      let initial_pq =
        priority_queue.new(fn(a: Edge(e), b: Edge(e)) {
          compare(a.weight, b.weight)
        })
      graph
      |> get_all_edges_from_node(start)
      |> list.fold(initial_pq, fn(pq, edge) { priority_queue.push(pq, edge) })
      |> do_prim(graph, _, set.from_list([start]), [])
    }
  }
  make_result(mst_edges, Prim, dict.size(graph.nodes), None, add, zero)
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
      case set.contains(visited, edge.to) {
        True -> do_prim(graph, rest_pq, visited, acc)
        False -> {
          let new_visited = set.insert(visited, edge.to)
          graph
          |> get_all_edges_from_node(edge.to)
          |> list.filter(fn(e) { !set.contains(new_visited, e.to) })
          |> list.fold(rest_pq, fn(pq, e) { priority_queue.push(pq, e) })
          |> do_prim(graph, _, new_visited, [edge, ..acc])
        }
      }
    }
  }
}

// =============================================================================
// BORUVKA'S ALGORITHM
// =============================================================================

/// Finds the Minimum Spanning Tree (MST) using Borůvka's algorithm.
///
/// **Time Complexity:** O(E log V)
pub fn boruvka(
  in graph: Graph(n, e),
  with_compare compare: fn(e, e) -> Order,
  with_add add: fn(e, e) -> e,
  with_zero zero: e,
) -> MstResult(e) {
  let nodes = dict.keys(graph.nodes)
  let dsu =
    list.fold(nodes, disjoint_set.new(), fn(acc, node) {
      disjoint_set.add(acc, node)
    })
  let all_edges = extract_undirected_edges(graph)
  let mst_edges = do_boruvka(all_edges, dsu, [], compare)
  make_result(mst_edges, Boruvka, list.length(nodes), None, add, zero)
}

fn do_boruvka(
  all_edges: List(Edge(e)),
  dsu: disjoint_set.DisjointSet(NodeId),
  mst_edges: List(Edge(e)),
  compare: fn(e, e) -> Order,
) -> List(Edge(e)) {
  case disjoint_set.count_sets(dsu) <= 1 {
    True -> list.reverse(mst_edges)
    False -> {
      let cheapest = find_best_edges_for_components(all_edges, dsu, compare)
      case dict.size(cheapest) == 0 {
        True -> list.reverse(mst_edges)
        False -> {
          let edges_to_add = deduplicate_cheapest(dict.values(cheapest))
          let #(new_dsu, new_mst) =
            list.fold(edges_to_add, #(dsu, mst_edges), fn(acc, edge) {
              #(disjoint_set.union(acc.0, edge.from, edge.to), [edge, ..acc.1])
            })
          let old_count = disjoint_set.count_sets(dsu)
          let new_count = disjoint_set.count_sets(new_dsu)
          case new_count == old_count {
            True -> list.reverse(mst_edges)
            False -> do_boruvka(all_edges, new_dsu, new_mst, compare)
          }
        }
      }
    }
  }
}

fn find_best_edges_for_components(
  edges: List(Edge(e)),
  dsu: disjoint_set.DisjointSet(NodeId),
  compare: fn(e, e) -> Order,
) -> Dict(NodeId, Edge(e)) {
  list.fold(edges, dict.new(), fn(acc, edge) {
    let #(_, root_u) = disjoint_set.find(dsu, edge.from)
    let #(_, root_v) = disjoint_set.find(dsu, edge.to)
    case root_u == root_v {
      True -> acc
      False -> {
        acc
        |> update_best(root_u, edge, compare)
        |> update_best(root_v, edge, compare)
      }
    }
  })
}

fn update_best(
  best_map: Dict(NodeId, Edge(e)),
  root: NodeId,
  edge: Edge(e),
  compare: fn(e, e) -> Order,
) -> Dict(NodeId, Edge(e)) {
  case dict.get(best_map, root) {
    Error(_) -> dict.insert(best_map, root, edge)
    Ok(existing) -> {
      case compare(edge.weight, existing.weight) {
        order.Lt -> dict.insert(best_map, root, edge)
        _ -> best_map
      }
    }
  }
}

fn deduplicate_cheapest(edges: List(Edge(e))) -> List(Edge(e)) {
  let #(result, _) =
    list.fold(edges, #([], set.new()), fn(acc, edge) {
      let key = case edge.from > edge.to {
        True -> #(edge.to, edge.from)
        False -> #(edge.from, edge.to)
      }
      case set.contains(acc.1, key) {
        True -> acc
        False -> #([edge, ..acc.0], set.insert(acc.1, key))
      }
    })
  list.reverse(result)
}

// =============================================================================
// CHU-LIU/EDMONDS ALGORITHM (DIRECTED MSA)
// =============================================================================

/// Finds the Minimum Spanning Arborescence (MSA) of a directed graph.
///
/// An arborescence is a directed spanning tree rooted at `root`. This algorithm
/// finds the minimum-weight set of edges that connects all reachable nodes to
/// the root.
///
/// **Time Complexity:** O(VE)
pub fn edmonds(
  in graph: Graph(n, e),
  root root: NodeId,
  with_compare compare: fn(e, e) -> Order,
  with_add add: fn(e, e) -> e,
  with_subtract subtract: fn(e, e) -> e,
  with_zero zero: e,
) -> Result(MstResult(e), String) {
  case graph.kind {
    Directed -> {
      let nodes = dict.keys(graph.nodes)
      let edges = extract_all_edges(graph)
      let min_id = list.fold(nodes, 0, int.min)
      case
        do_edmonds(
          EdmondsGraph(nodes, edges),
          root,
          compare,
          subtract,
          min_id - 1,
        )
      {
        Ok(mst_edges) ->
          Ok(make_result(
            mst_edges,
            ChuLiuEdmonds,
            list.length(nodes),
            Some(root),
            add,
            zero,
          ))
        Error(msg) -> Error(msg)
      }
    }
    Undirected -> Error("Edmonds algorithm requires a directed graph")
  }
}

type EdmondsGraph(e) {
  EdmondsGraph(nodes: List(NodeId), edges: List(Edge(e)))
}

type CycleInfo(e) {
  CycleInfo(
    super_node: NodeId,
    cycle: List(NodeId),
    mapping: Dict(#(NodeId, NodeId), Edge(e)),
  )
}

fn do_edmonds(
  graph: EdmondsGraph(e),
  root: NodeId,
  compare: fn(e, e) -> Order,
  subtract: fn(e, e) -> e,
  super_counter: Int,
) -> Result(List(Edge(e)), String) {
  let nodes = graph.nodes
  let best_in = find_best_in_edges(graph, root, compare)
  let unreachable =
    list.any(nodes, fn(v) { v != root && !dict.has_key(best_in, v) })
  case unreachable {
    True -> Error("No arborescence exists")
    False -> {
      let cycle = find_cycle_in_best_in(best_in, nodes)
      case cycle {
        [] -> Ok(dict.values(best_in))
        cycle_nodes -> {
          let super_node = super_counter
          let next_counter = super_counter - 1
          let #(contracted, cycle_info) =
            contract_cycle(
              graph,
              cycle_nodes,
              best_in,
              subtract,
              super_node,
              compare,
            )
          case do_edmonds(contracted, root, compare, subtract, next_counter) {
            Ok(contracted_edges) ->
              Ok(expand_cycle(contracted_edges, cycle_info, best_in))
            Error(msg) -> Error(msg)
          }
        }
      }
    }
  }
}

fn find_best_in_edges(
  graph: EdmondsGraph(e),
  root: NodeId,
  compare: fn(e, e) -> Order,
) -> Dict(NodeId, Edge(e)) {
  use acc, node_id <- list.fold(graph.nodes, dict.new())
  case node_id == root {
    True -> acc
    False -> {
      let incoming = list.filter(graph.edges, fn(e) { e.to == node_id })
      case incoming {
        [] -> acc
        [first, ..rest] -> {
          let best =
            list.fold(rest, first, fn(best, e) {
              case compare(e.weight, best.weight) {
                order.Lt -> e
                _ -> best
              }
            })
          dict.insert(acc, node_id, best)
        }
      }
    }
  }
}

fn find_cycle_in_best_in(
  best_in: Dict(NodeId, Edge(e)),
  nodes: List(NodeId),
) -> List(NodeId) {
  list.find_map(nodes, fn(start_node) {
    find_cycle_dfs(start_node, best_in, dict.new(), [])
  })
  |> result.unwrap([])
}

fn find_cycle_dfs(
  node: NodeId,
  best_in: Dict(NodeId, Edge(e)),
  visited: Dict(NodeId, String),
  path: List(NodeId),
) -> Result(List(NodeId), Nil) {
  case dict.get(visited, node) {
    Ok("visiting") -> {
      let cycle = [node, ..list.take_while(path, fn(x) { x != node })]
      Ok(list.reverse(cycle))
    }
    Ok(_) -> Error(Nil)
    Error(_) -> {
      case dict.get(best_in, node) {
        Error(_) -> Error(Nil)
        Ok(edge) -> {
          find_cycle_dfs(
            edge.from,
            best_in,
            dict.insert(visited, node, "visiting"),
            [node, ..path],
          )
        }
      }
    }
  }
}

fn contract_cycle(
  graph: EdmondsGraph(e),
  cycle: List(NodeId),
  best_in: Dict(NodeId, Edge(e)),
  subtract: fn(e, e) -> e,
  super_node: Int,
  compare: fn(e, e) -> Order,
) -> #(EdmondsGraph(e), CycleInfo(e)) {
  let cycle_set = set.from_list(cycle)
  let new_nodes =
    list.filter(graph.nodes, fn(n) { !set.contains(cycle_set, n) })
  let new_nodes = [super_node, ..new_nodes]

  let candidates =
    list.filter_map(graph.edges, fn(edge) {
      let u_in = set.contains(cycle_set, edge.from)
      let v_in = set.contains(cycle_set, edge.to)
      case u_in, v_in {
        True, True -> Error(Nil)
        True, False -> Ok(#(Edge(super_node, edge.to, edge.weight), edge))
        False, True -> {
          let assert Ok(best_in_v) = dict.get(best_in, edge.to)
          let new_weight = subtract(edge.weight, best_in_v.weight)
          Ok(#(Edge(edge.from, super_node, new_weight), edge))
        }
        False, False -> Ok(#(edge, edge))
      }
    })

  let deduped =
    list.fold(
      candidates,
      dict.new(),
      fn(acc: Dict(#(NodeId, NodeId), #(Edge(e), Edge(e))), pair) {
        let #(c_edge, orig_edge) = pair
        let key = #(c_edge.from, c_edge.to)
        case dict.get(acc, key) {
          Ok(#(existing, _)) -> {
            case compare(c_edge.weight, existing.weight) {
              order.Lt -> dict.insert(acc, key, #(c_edge, orig_edge))
              _ -> acc
            }
          }
          Error(_) -> dict.insert(acc, key, #(c_edge, orig_edge))
        }
      },
    )

  let new_edges = dict.values(deduped) |> list.map(fn(p) { p.0 })
  let mapping = dict.map_values(deduped, fn(_, pair) { pair.1 })

  #(EdmondsGraph(new_nodes, new_edges), CycleInfo(super_node, cycle, mapping))
}

fn expand_cycle(
  contracted_edges: List(Edge(e)),
  cycle_info: CycleInfo(e),
  best_in: Dict(NodeId, Edge(e)),
) -> List(Edge(e)) {
  let CycleInfo(super_node, cycle, mapping) = cycle_info

  let entry_edge_contracted =
    list.find(contracted_edges, fn(e) { e.to == super_node })
  let entry_orig = case entry_edge_contracted {
    Ok(e) -> dict.get(mapping, #(e.from, super_node))
    Error(_) -> Error(Nil)
  }

  let node_to_bypass = case entry_orig {
    Ok(orig) -> orig.to
    Error(_) -> -1
  }

  let final_edges =
    list.flat_map(contracted_edges, fn(e) {
      case e.to == super_node, e.from == super_node {
        True, _ -> {
          case entry_orig {
            Ok(orig) -> [orig]
            Error(_) -> []
          }
        }
        _, True -> {
          case dict.get(mapping, #(super_node, e.to)) {
            Ok(orig) -> [orig]
            Error(_) -> []
          }
        }
        _, _ -> [e]
      }
    })

  let cycle_edges =
    list.filter_map(cycle, fn(node) {
      case dict.get(best_in, node) {
        Ok(edge) if edge.to != node_to_bypass -> Ok(edge)
        _ -> Error(Nil)
      }
    })

  list.append(final_edges, cycle_edges)
}

// =============================================================================
// WILSON'S ALGORITHM (UNIFORM SPANNING TREE)
// =============================================================================

/// Generates a Uniform Spanning Tree (UST) using Wilson's algorithm.
///
/// Uses a random seed for non-deterministic sampling.
pub fn wilson(
  in graph: Graph(n, e),
  with_add add: fn(e, e) -> e,
  with_zero zero: e,
) -> MstResult(e) {
  do_wilson_generic(graph, random.new(None), add, zero)
}

/// Generates a Uniform Spanning Tree with a fixed seed for reproducibility.
pub fn wilson_with_seed(
  in graph: Graph(n, e),
  seed seed: Int,
  with_add add: fn(e, e) -> e,
  with_zero zero: e,
) -> MstResult(e) {
  do_wilson_generic(graph, random.new(Some(seed)), add, zero)
}

fn do_wilson_generic(
  graph: Graph(n, e),
  rng: random.Rng,
  add: fn(e, e) -> e,
  zero: e,
) -> MstResult(e) {
  let nodes = dict.keys(graph.nodes)
  case nodes {
    [] -> make_result([], Wilson, 0, None, add, zero)
    [first, ..] -> {
      let tree = set.from_list([first])
      let unvisited = set.difference(set.from_list(nodes), tree)
      let #(edges, _) = do_wilson_loop(graph, unvisited, tree, [], rng)
      make_result(edges, Wilson, list.length(nodes), None, add, zero)
    }
  }
}

fn do_wilson_loop(
  graph: Graph(n, e),
  unvisited: Set(NodeId),
  tree: Set(NodeId),
  acc_edges: List(Edge(e)),
  rng: random.Rng,
) -> #(List(Edge(e)), random.Rng) {
  case set.size(unvisited) {
    0 -> #(list.reverse(acc_edges), rng)
    _ -> {
      let unvisited_list = set.to_list(unvisited)
      let #(idx, next_rng) = random.next_int(rng, list.length(unvisited_list))
      let assert Ok(start_node) = util.list_at(unvisited_list, idx)

      let #(path_map, next_rng2) =
        perform_lerw(graph, start_node, tree, dict.new(), next_rng)
      let #(new_tree, new_unvisited, path_edges) =
        add_path_to_tree(graph, start_node, path_map, tree, unvisited)

      do_wilson_loop(
        graph,
        new_unvisited,
        new_tree,
        list.append(acc_edges, path_edges),
        next_rng2,
      )
    }
  }
}

fn perform_lerw(
  graph: Graph(n, e),
  current: NodeId,
  tree: Set(NodeId),
  path_map: Dict(NodeId, NodeId),
  rng: random.Rng,
) -> #(Dict(NodeId, NodeId), random.Rng) {
  case set.contains(tree, current) {
    True -> #(path_map, rng)
    False -> {
      let neighbors = model.successor_ids(graph, current)
      case neighbors {
        [] -> #(path_map, rng)
        _ -> {
          let #(idx, next_rng) = random.next_int(rng, list.length(neighbors))
          let assert Ok(next_node) = util.list_at(neighbors, idx)
          perform_lerw(
            graph,
            next_node,
            tree,
            dict.insert(path_map, current, next_node),
            next_rng,
          )
        }
      }
    }
  }
}

fn add_path_to_tree(
  graph: Graph(n, e),
  current: NodeId,
  path_map: Dict(NodeId, NodeId),
  tree: Set(NodeId),
  unvisited: Set(NodeId),
) -> #(Set(NodeId), Set(NodeId), List(Edge(e))) {
  case set.contains(tree, current) {
    True -> #(tree, unvisited, [])
    False -> {
      let assert Ok(next_node) = dict.get(path_map, current)
      let assert Ok(weight) = model.edge_data(graph, current, next_node)
      let edge = Edge(current, next_node, weight)

      let new_tree = set.insert(tree, current)
      let new_unvisited = set.delete(unvisited, current)

      let #(final_tree, final_unvisited, rest_edges) =
        add_path_to_tree(graph, next_node, path_map, new_tree, new_unvisited)
      #(final_tree, final_unvisited, [edge, ..rest_edges])
    }
  }
}

// =============================================================================
// CONVENIENCE WRAPPERS
// =============================================================================

/// Kruskal for `Int` weights.
pub fn kruskal_int(in graph: Graph(n, Int)) -> MstResult(Int) {
  kruskal(graph, with_compare: int.compare, with_add: int.add, with_zero: 0)
}

/// Kruskal for `Float` weights.
pub fn kruskal_float(in graph: Graph(n, Float)) -> MstResult(Float) {
  kruskal(
    graph,
    with_compare: float.compare,
    with_add: float.add,
    with_zero: 0.0,
  )
}

/// Prim for `Int` weights.
pub fn prim_int(in graph: Graph(n, Int)) -> MstResult(Int) {
  prim(graph, with_compare: int.compare, with_add: int.add, with_zero: 0)
}

/// Prim for `Float` weights.
pub fn prim_float(in graph: Graph(n, Float)) -> MstResult(Float) {
  prim(graph, with_compare: float.compare, with_add: float.add, with_zero: 0.0)
}

/// Borůvka for `Int` weights.
pub fn boruvka_int(in graph: Graph(n, Int)) -> MstResult(Int) {
  boruvka(graph, with_compare: int.compare, with_add: int.add, with_zero: 0)
}

/// Borůvka for `Float` weights.
pub fn boruvka_float(in graph: Graph(n, Float)) -> MstResult(Float) {
  boruvka(
    graph,
    with_compare: float.compare,
    with_add: float.add,
    with_zero: 0.0,
  )
}

/// Edmonds for `Int` weights.
pub fn edmonds_int(
  in graph: Graph(n, Int),
  root root: NodeId,
) -> Result(MstResult(Int), String) {
  edmonds(
    graph,
    root: root,
    with_compare: int.compare,
    with_add: int.add,
    with_subtract: int.subtract,
    with_zero: 0,
  )
}

/// Edmonds for `Float` weights.
pub fn edmonds_float(
  in graph: Graph(n, Float),
  root root: NodeId,
) -> Result(MstResult(Float), String) {
  edmonds(
    graph,
    root: root,
    with_compare: float.compare,
    with_add: float.add,
    with_subtract: float.subtract,
    with_zero: 0.0,
  )
}

/// Wilson for `Int` weights.
pub fn wilson_int(in graph: Graph(n, Int)) -> MstResult(Int) {
  wilson(graph, with_add: int.add, with_zero: 0)
}

/// Wilson for `Float` weights.
pub fn wilson_float(in graph: Graph(n, Float)) -> MstResult(Float) {
  wilson(graph, with_add: float.add, with_zero: 0.0)
}

/// Wilson with fixed seed for `Int` weights.
pub fn wilson_int_with_seed(
  in graph: Graph(n, Int),
  seed seed: Int,
) -> MstResult(Int) {
  wilson_with_seed(graph, seed: seed, with_add: int.add, with_zero: 0)
}

/// Wilson with fixed seed for `Float` weights.
pub fn wilson_float_with_seed(
  in graph: Graph(n, Float),
  seed seed: Int,
) -> MstResult(Float) {
  wilson_with_seed(graph, seed: seed, with_add: float.add, with_zero: 0.0)
}

// =============================================================================
// HELPERS
// =============================================================================

fn make_result(
  edges: List(Edge(e)),
  algorithm: Algorithm,
  node_count: Int,
  root: Option(NodeId),
  add: fn(e, e) -> e,
  zero: e,
) -> MstResult(e) {
  let total_weight =
    list.fold(edges, zero, fn(acc, edge) { add(acc, edge.weight) })
  MstResult(
    edges: edges,
    total_weight: total_weight,
    node_count: node_count,
    edge_count: list.length(edges),
    algorithm: algorithm,
    root: root,
  )
}

fn extract_undirected_edges(graph: Graph(n, e)) -> List(Edge(e)) {
  dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
    dict.fold(targets, acc, fn(inner_acc, to_id, weight) {
      case graph.kind == Undirected && from_id > to_id {
        True -> inner_acc
        False -> [Edge(from: from_id, to: to_id, weight: weight), ..inner_acc]
      }
    })
  })
}

fn extract_all_edges(graph: Graph(n, e)) -> List(Edge(e)) {
  dict.fold(graph.out_edges, [], fn(acc, from_id, targets) {
    dict.fold(targets, acc, fn(inner_acc, to_id, weight) {
      [Edge(from: from_id, to: to_id, weight: weight), ..inner_acc]
    })
  })
}

fn get_all_edges_from_node(graph: Graph(n, e), from: NodeId) -> List(Edge(e)) {
  case dict.get(graph.out_edges, from) {
    Ok(targets) -> {
      use acc, to_id, weight <- dict.fold(targets, [])
      [Edge(from: from, to: to_id, weight: weight), ..acc]
    }
    Error(Nil) -> []
  }
}
