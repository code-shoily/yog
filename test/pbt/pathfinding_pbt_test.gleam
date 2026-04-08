import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import pbt/qcheck_generators
import qcheck
import yog/model.{type Graph, type NodeId}
import yog/pathfinding/a_star
import yog/pathfinding/bellman_ford
import yog/pathfinding/bidirectional
import yog/pathfinding/dijkstra
import yog/pathfinding/floyd_warshall
import yog/traversal

fn bfs_path_unweighted(
  graph: model.Graph(n, e),
  src: model.NodeId,
  dst: model.NodeId,
) {
  let parents =
    traversal.fold_walk(
      over: graph,
      from: src,
      using: traversal.BreadthFirst,
      initial: dict.new(),
      with: fn(acc, node_id, meta) {
        let new_acc = case meta.parent {
          Some(p) -> dict.insert(acc, node_id, p)
          None -> acc
        }
        case node_id == dst {
          True -> #(traversal.Halt, new_acc)
          False -> #(traversal.Continue, new_acc)
        }
      },
    )

  case dict.has_key(parents, dst) || src == dst {
    False -> None
    True -> Some(reconstruct_path_helper(parents, src, dst, [dst]))
  }
}

fn reconstruct_path_helper(parents, src, current, acc) {
  case current == src {
    True -> acc
    False -> {
      case dict.get(parents, current) {
        Ok(parent) ->
          reconstruct_path_helper(parents, src, parent, [parent, ..acc])
        Error(Nil) -> acc
      }
    }
  }
}

// Helpers from algorithm_property_test
fn is_valid_path(graph: Graph(n, Int), path: List(NodeId)) -> Bool {
  case path {
    [] | [_] -> True
    [first, second, ..rest] -> {
      let edge_exists =
        model.successors(graph, first)
        |> list.any(fn(pair) { pair.0 == second })
      edge_exists && is_valid_path(graph, [second, ..rest])
    }
  }
}

fn calculate_path_weight(graph: Graph(n, Int), path: List(NodeId)) -> Int {
  case path {
    [] | [_] -> 0
    [first, second, ..rest] -> {
      let edge_weight =
        model.successors(graph, first)
        |> list.find(fn(pair) { pair.0 == second })
        |> result.map(fn(pair) { pair.1 })
        |> result.unwrap(0)

      edge_weight + calculate_path_weight(graph, [second, ..rest])
    }
  }
}

fn is_reachable(graph: Graph(n, e), from: NodeId, to: NodeId) -> Bool {
  let visited = traversal.walk(graph, from: from, using: traversal.BreadthFirst)
  list.contains(visited, to)
}

/// Dijkstra vs BFS: On unweighted graphs, Dijkstra weight should be (path_length - 1).
pub fn dijkstra_vs_bfs_unweighted_test() {
  let generator = {
    use graph <- qcheck.bind(qcheck_generators.unweighted_graph_generator(
      model.Directed,
    ))
    let n = model.order(graph)
    case n {
      0 -> qcheck.return(#(graph, 0, 0))
      _ -> {
        use src <- qcheck.bind(qcheck.bounded_int(0, n - 1))
        use dst <- qcheck.map(qcheck.bounded_int(0, n - 1))
        #(graph, src, dst)
      }
    }
  }

  use #(graph, src, dst) <- qcheck.given(generator)

  let bfs_p = bfs_path_unweighted(graph, src, dst)
  let dijkstra_res = dijkstra.shortest_path_int(graph, src, dst)

  case bfs_p, dijkstra_res {
    Some(p1), Some(p2) -> {
      list.length(p1) |> should.equal(list.length(p2.nodes))
      p2.total_weight |> should.equal(list.length(p2.nodes) - 1)
    }
    None, None -> should.be_true(True)
    _, _ -> should.fail()
  }
}

/// A* vs Dijkstra: A* with zero heuristic should be identical to Dijkstra.
pub fn a_star_vs_dijkstra_test() {
  let generator = {
    use graph <- qcheck.bind(qcheck_generators.directed_graph_generator())
    let n = model.order(graph)
    case n {
      0 -> qcheck.return(#(graph, 0, 0))
      _ -> {
        use src <- qcheck.bind(qcheck.bounded_int(0, n - 1))
        use dst <- qcheck.map(qcheck.bounded_int(0, n - 1))
        #(graph, src, dst)
      }
    }
  }

  use #(graph, src, dst) <- qcheck.given(generator)

  let d_res = dijkstra.shortest_path_int(graph, src, dst)
  let a_res = a_star.a_star_int(graph, src, dst, fn(_, _) { 0 })

  case d_res, a_res {
    Some(p1), Some(p2) -> {
      p1.total_weight |> should.equal(p2.total_weight)
    }
    None, None -> should.be_true(True)
    _, _ -> should.fail()
  }
}

/// Bidirectional vs Dijkstra: Correctness for bidirectional search on undirected graphs.
pub fn bidirectional_vs_dijkstra_test() {
  let generator = {
    use graph <- qcheck.bind(qcheck_generators.undirected_graph_generator())
    let n = model.order(graph)
    case n {
      0 -> qcheck.return(#(graph, 0, 0))
      _ -> {
        use src <- qcheck.bind(qcheck.bounded_int(0, n - 1))
        use dst <- qcheck.map(qcheck.bounded_int(0, n - 1))
        #(graph, src, dst)
      }
    }
  }

  use #(graph, src, dst) <- qcheck.given(generator)

  let d_res = dijkstra.shortest_path_int(graph, src, dst)
  let bi_res = bidirectional.shortest_path_int(graph, src, dst)

  case d_res, bi_res {
    Some(p1), Some(p2) -> {
      p1.total_weight |> should.equal(p2.total_weight)
    }
    None, None -> should.be_true(True)
    _, _ -> should.fail()
  }
}

/// Bellman-Ford vs Dijkstra: Consistency on non-negative weights.
pub fn bellman_ford_vs_dijkstra_test() {
  let generator = {
    use graph <- qcheck.bind(qcheck_generators.directed_graph_generator())
    let n = model.order(graph)
    case n {
      0 -> qcheck.return(#(graph, 0, 0))
      _ -> {
        use src <- qcheck.bind(qcheck.bounded_int(0, n - 1))
        use dst <- qcheck.map(qcheck.bounded_int(0, n - 1))
        #(graph, src, dst)
      }
    }
  }

  use #(graph, src, dst) <- qcheck.given(generator)

  let d_res = dijkstra.shortest_path_int(graph, src, dst)
  let bf_res = bellman_ford.bellman_ford_int(graph, src, dst)

  case d_res, bf_res {
    Some(p1), bellman_ford.ShortestPath(p2) -> {
      p1.total_weight |> should.equal(p2.total_weight)
    }
    None, bellman_ford.NoPath -> should.be_true(True)
    _, _ -> should.fail()
  }
}

/// Bellman-Ford vs Floyd-Warshall consistency with potentially negative weights.
pub fn bellman_ford_vs_floyd_warshall_test() {
  let generator = {
    use graph <- qcheck.bind(qcheck_generators.graph_generator_negative_weights(
      model.Directed,
    ))
    let n = model.order(graph)
    case n {
      0 -> qcheck.return(#(graph, 0, 0))
      _ -> {
        use src <- qcheck.bind(qcheck.bounded_int(0, n - 1))
        use dst <- qcheck.map(qcheck.bounded_int(0, n - 1))
        #(graph, src, dst)
      }
    }
  }

  use #(graph, src, dst) <- qcheck.given(generator)

  let bf_res = bellman_ford.bellman_ford_int(graph, src, dst)
  let fw_res = floyd_warshall.floyd_warshall_int(graph)

  case bf_res, fw_res {
    bellman_ford.ShortestPath(p), Ok(dists) -> {
      dict.get(dists, #(src, dst))
      |> should.be_ok()
      |> should.equal(p.total_weight)
    }
    bellman_ford.NoPath, Ok(dists) -> {
      dict.has_key(dists, #(src, dst)) |> should.be_false()
    }
    bellman_ford.NegativeCycle, Error(Nil) -> should.be_true(True)
    _, Ok(_) -> {
      case bf_res {
        bellman_ford.NegativeCycle -> should.fail()
        _ -> should.be_true(True)
      }
    }
    _, Error(Nil) -> should.be_true(True)
  }
}

// ============================================================================
// DIJKSTRA: VALIDITY & INVARIANTS
// ============================================================================

pub fn dijkstra_path_validity_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case dijkstra.shortest_path_int(in: graph, from: src, to: dst) {
        Some(path) -> {
          assert list.first(path.nodes) == Ok(src)
          assert list.last(path.nodes) == Ok(dst)
          assert is_valid_path(graph, path.nodes)

          let calculated = calculate_path_weight(graph, path.nodes)
          assert path.total_weight == calculated
        }
        None -> Nil
      }
    }
  }
}

pub fn dijkstra_no_path_confirmed_by_bfs_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      case dijkstra.shortest_path_int(in: graph, from: src, to: dst) {
        None -> {
          assert !is_reachable(graph, src, dst)
        }
        Some(_) -> Nil
      }
    }
  }
}

pub fn undirected_paths_symmetric_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Undirected),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let forward = dijkstra.shortest_path_int(in: graph, from: src, to: dst)
      let backward = dijkstra.shortest_path_int(in: graph, from: dst, to: src)

      case forward, backward {
        Some(f_path), Some(b_path) -> {
          assert f_path.total_weight == b_path.total_weight
        }
        None, None -> Nil
        _, _ -> panic as "Symmetric paths should both exist or both not exist!"
      }
    }
  }
}

pub fn triangle_inequality_test() {
  use #(graph, #(src, dst, _w)) <- qcheck.given(
    qcheck_generators.graph_and_edge_generator(model.Directed),
  )

  case model.order(graph) {
    0 -> Nil
    _ -> {
      let n = model.order(graph)
      let via_node = { src + dst } % n

      let direct = dijkstra.shortest_path_int(in: graph, from: src, to: dst)
      let via_1_part1 =
        dijkstra.shortest_path_int(in: graph, from: src, to: via_node)
      let via_1_part2 =
        dijkstra.shortest_path_int(in: graph, from: via_node, to: dst)

      case direct, via_1_part1, via_1_part2 {
        Some(d), Some(p1), Some(p2) -> {
          let via_weight = p1.total_weight + p2.total_weight
          assert d.total_weight <= via_weight
        }
        _, _, _ -> Nil
      }
    }
  }
}
