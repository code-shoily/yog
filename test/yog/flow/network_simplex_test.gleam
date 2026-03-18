import gleam/list
import gleam/result
import gleeunit/should
import yog
import yog/flow/network_simplex

pub fn simple_network_simplex_test() {
  let assert Ok(graph) =
    yog.directed()
    |> yog.add_node(1, 10)
    // Supply (positive)
    |> yog.add_node(2, 0)
    |> yog.add_node(3, -10)
    // Demand (negative)
    |> yog.add_edge(from: 1, to: 2, with: #(5, 2))
  // #(capacity, cost)
  let assert Ok(graph) = yog.add_edge(graph, from: 1, to: 3, with: #(10, 5))
  let assert Ok(graph) = yog.add_edge(graph, from: 2, to: 3, with: #(5, 1))

  let get_demand = fn(d: Int) { d }
  let get_capacity = fn(e: #(Int, Int)) { e.0 }
  let get_cost = fn(e: #(Int, Int)) { e.1 }

  let result =
    network_simplex.min_cost_flow(graph, get_demand, get_capacity, get_cost)
  let assert Ok(res) = result

  // Best path: 5 units through 1 -> 2 -> 3 (cost = 5 * (2+1) = 15)
  //            5 units through 1 -> 3 (cost = 5 * 5 = 25)
  // Total cost = 40
  res.cost |> should.equal(40)
}

pub type NodeData {
  NodeData(demand: Int)
}

pub type EdgeData {
  EdgeData(capacity: Int, cost: Int)
}

pub fn transport_problem_test() {
  // 1 = Factory 1 (+50)
  // 2 = Factory 2 (+50)
  // 3 = Store 1 (-30)
  // 4 = Store 2 (-40)
  // 5 = Store 3 (-30)

  let g =
    yog.directed()
    |> yog.add_node(1, NodeData(50))
    |> yog.add_node(2, NodeData(50))
    |> yog.add_node(3, NodeData(-30))
    |> yog.add_node(4, NodeData(-40))
    |> yog.add_node(5, NodeData(-30))
    // Factory 1 Routes
    |> yog.add_edge_ensure(1, 3, EdgeData(100, 10), NodeData(0))
    // Cheap to S1
    |> yog.add_edge_ensure(1, 4, EdgeData(100, 20), NodeData(0))
    // Okay to S2
    |> yog.add_edge_ensure(1, 5, EdgeData(100, 50), NodeData(0))
    // Very expensive to S3
    // Factory 2 Routes
    |> yog.add_edge_ensure(2, 3, EdgeData(100, 60), NodeData(0))
    // Very expensive to S1
    |> yog.add_edge_ensure(2, 4, EdgeData(100, 15), NodeData(0))
    // Cheap to S2
    |> yog.add_edge_ensure(2, 5, EdgeData(100, 10), NodeData(0))
  // Cheap to S3

  let demand_of = fn(n: NodeData) { n.demand }
  let capacity_of = fn(e: EdgeData) { e.capacity }
  let cost_of = fn(e: EdgeData) { e.cost }

  let result = network_simplex.min_cost_flow(g, demand_of, capacity_of, cost_of)
  let assert Ok(res) = result

  // THE MATH:
  // F1 sends 30 to S1 (Cost: 30 * 10 = 300)
  // F1 sends 20 to S2 (Cost: 20 * 20 = 400) -> F1 exhausted (50)
  // F2 sends 20 to S2 (Cost: 20 * 15 = 300) -> S2 satisfied (40)
  // F2 sends 30 to S3 (Cost: 30 * 10 = 300) -> F2 exhausted (50)
  // Total Minimum Cost = 300 + 400 + 300 + 300 = 1300

  res.cost |> should.equal(1300)

  // Verify the exact optimal routing
  let get_flow = fn(src, tgt) {
    list.find(res.flow, fn(route) { route.0 == src && route.1 == tgt })
    |> result.map(fn(route) { route.2 })
    |> result.unwrap(0)
  }

  get_flow(1, 3) |> should.equal(30)
  get_flow(1, 4) |> should.equal(20)
  get_flow(1, 5) |> should.equal(0)

  get_flow(2, 3) |> should.equal(0)
  get_flow(2, 4) |> should.equal(20)
  get_flow(2, 5) |> should.equal(30)
}
