import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import pbt/qcheck_generators
import qcheck
import yog/model
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
