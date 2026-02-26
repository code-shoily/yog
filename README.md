# Yog 🌳

[![Package Version](https://img.shields.io/hexpm/v/yog)](https://hex.pm/packages/yog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yog/)

A graph algorithm library for Gleam, providing implementations of classic graph algorithms with a functional API.

## Features

- **Graph Data Structures**: Directed and undirected graphs with generic node and edge data
- **Pathfinding Algorithms**:
  - Dijkstra's shortest path (non-negative weights)
  - A* search with heuristics
  - Bellman-Ford (supports negative weights, detects cycles)
- **Graph Traversal**: BFS and DFS with early termination support
- **Graph Transformations**: Transpose (O(1)!), map nodes/edges, filter, merge
- **Minimum Spanning Tree**: Kruskal's algorithm with Union-Find
- **Topological Sorting**: Kahn's algorithm with lexicographical variant
- **Strongly Connected Components**: Tarjan's algorithm
- **Efficient Data Structures**: Pairing heap for priority queues, Union-Find with path compression

## Installation

Add Yog to your Gleam project:

```sh
gleam add yog
```

## Quick Start

```gleam
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/model.{Directed}
import yog/pathfinding
import gleam/int
import gleam/io

pub fn main() {
  // Create a directed graph
  let graph =
    model.new(Directed)
    |> model.add_node(1, "Start")
    |> model.add_node(2, "Middle")
    |> model.add_node(3, "End")
    |> model.add_edge(from: 1, to: 2, with: 5)
    |> model.add_edge(from: 2, to: 3, with: 3)
    |> model.add_edge(from: 1, to: 3, with: 10)

  // Find shortest path
  case pathfinding.shortest_path(
    in: graph,
    from: 1,
    to: 3,
    with_zero: 0,
    with_add: int.add,
    with_compare: int.compare
  ) {
    Some(path) -> {
      // Path(nodes: [1, 2, 3], total_weight: 8)
      // Outputs: Found path with weight: 8
      io.println("Found path with weight: " <> int.to_string(path.total_weight))
    }
    None -> io.println("No path found")
  }
}
```

## API Overview

### Core Graph Operations (`yog/model`)

```gleam
// Create graphs
let graph = model.new(Directed)  // or Undirected

// Add nodes with data
|> model.add_node(1, "Node A")
|> model.add_node(2, "Node B")

// Add edges with weights
|> model.add_edge(from: 1, to: 2, with: 10)

// Query the graph
let successors = model.successors(graph, 1)        // Outgoing edges [#(2, 10)]
let predecessors = model.predecessors(graph, 1)   // Incoming edges []
let neighbors = model.neighbors(graph, 2)         // All connected nodes [#(1, 10)]
```

### Pathfinding (`yog/pathfinding`)

#### Dijkstra's Algorithm

Best for: Graphs with non-negative edge weights

```gleam
import yog/pathfinding

pathfinding.shortest_path(
  in: graph,
  from: start_node,
  to: goal_node,
  with_zero: 0,
  with_add: int.add,
  with_compare: int.compare
)
// => Some(Path([1, 2, 5], 15)) or None
```

**Time Complexity:** O((V + E) log V)

#### A* Search

Best for: When you have a good heuristic estimate of remaining distance

```gleam
// Define an admissible heuristic (must never overestimate)
let manhattan_distance = fn(node, goal) {
  int.absolute_value(node.x - goal.x) +
  int.absolute_value(node.y - goal.y)
}

pathfinding.a_star(
  in: graph,
  from: start,
  to: goal,
  with_zero: 0,
  with_add: int.add,
  with_compare: int.compare,
  heuristic: manhattan_distance
)
```

**Time Complexity:** O((V + E) log V), often faster than Dijkstra with good heuristics

#### Bellman-Ford Algorithm

Best for: Graphs with negative edge weights, or when detecting negative cycles

```gleam
case pathfinding.bellman_ford(
  in: graph,
  from: start,
  to: goal,
  with_zero: 0,
  with_add: int.add,
  with_compare: int.compare
) {
  ShortestPath(path) -> // Found valid path (may have negative total weight)
  NegativeCycle -> // Negative cycle detected
  NoPath -> // No path exists
}
```

**Time Complexity:** O(VE)

### Graph Traversal (`yog/traversal`)

```gleam
import yog/traversal.{BreadthFirst, DepthFirst}

// Full traversal
let start_node = 1

let visited = traversal.walk(
  from: start_node,
  in: graph,
  using: BreadthFirst  // or DepthFirst
)
// => [1, 2, 3]

// Early termination
let target = 2

let path_to_target = traversal.walk_until(
  from: start_node,
  in: graph,
  using: BreadthFirst,
  until: fn(node) { node == target }
)
// => [1, 2]
```

**Time Complexity:** O(V + E)

### Minimum Spanning Tree (`yog/mst`)

Kruskal's algorithm finds the minimum spanning tree using Union-Find.

```gleam
import yog/mst

let mst_edges = mst.kruskal(
  in: graph,
  with_compare: int.compare
)
// => [Edge(2, 3, 3), Edge(1, 2, 5)]
```

**Time Complexity:** O(E log E)

### Topological Sort (`yog/topological_sort`)

Orders nodes such that for every edge (u, v), u comes before v.

```gleam
import yog/topological_sort

// Standard topological sort
case topological_sort.topological_sort(graph) {
  Ok(ordering) -> // [1, 2, 3]
  Error(Nil) -> // Cycle detected
}

// Lexicographically smallest ordering
case topological_sort.lexicographical_topological_sort(graph, int.compare) {
  Ok(ordering) -> // Always picks smallest available node
  Error(Nil) -> // Cycle detected
}
```

**Time Complexity:**

- Standard: O(V + E)
- Lexicographical: O(V log V + E)

### Strongly Connected Components (`yog/components`)

Finds maximal strongly connected subgraphs using Tarjan's algorithm.

```gleam
import yog/components

let sccs = components.strongly_connected_components(graph)
// => [[1, 2, 3], [4], [5, 6]]
```

**Time Complexity:** O(V + E)

### Graph Transformations (`yog/transform`)

Functional operations for transforming and manipulating graphs.

#### Transpose (O(1) Reverse All Edges!)

```gleam
import yog/transform

// Reverse all edges in constant time!
let reversed = transform.transpose(graph)
// Due to dual-map representation, this is just a pointer swap
```

**Time Complexity:** O(1) - dramatically faster than typical O(E) implementations

**Use for:** Kosaraju's SCC, finding nodes that can reach a target, reversing dependencies

#### Map Operations (Functor)

```gleam
// Transform node data
let uppercased = transform.map_nodes(graph, string.uppercase)

// Transform edge weights
let doubled_weights = transform.map_edges(graph, fn(w) { w * 2 })

// Can change types
let float_graph = transform.map_edges(int_graph, int.to_float)
```

**Time Complexity:**

- `map_nodes`: O(V)
- `map_edges`: O(E)

#### Filter Nodes (with Auto-Pruning)

```gleam
// Keep only nodes matching predicate
// Automatically removes edges to/from filtered nodes
let filtered = transform.filter_nodes(graph, fn(node_data) {
  string.starts_with(node_data, "active_")
})
```

**Time Complexity:** O(V + E)

#### Merge Graphs

```gleam
// Combine two graphs (second takes precedence on conflicts)
let combined = transform.merge(graph1, graph2)
```

**Time Complexity:** O(V + E)

**Use for:** Building graphs incrementally, applying patches/updates

## Working with Different Weight Types

Yog is generic over edge weights. You can use any type that supports addition and comparison:

### Integer Weights

```gleam
pathfinding.shortest_path(
  in: graph,
  from: 1, to: 5,
  with_zero: 0,
  with_add: int.add,
  with_compare: int.compare
)
```

### Float Weights

```gleam
pathfinding.shortest_path(
  in: graph,
  from: 1, to: 5,
  with_zero: 0.0,
  with_add: float.add,
  with_compare: float.compare
)
```

### Custom Weight Types

```gleam
pub type Distance {
  Distance(km: Float, time: Float)
}

let add_distances = fn(a, b) {
  Distance(km: a.km +. b.km, time: a.time +. b.time)
}

let compare_by_time = fn(a, b) {
  float.compare(a.time, b.time)
}

pathfinding.shortest_path(
  in: graph,
  from: 1, to: 5,
  with_zero: Distance(0.0, 0.0),
  with_add: add_distances,
  with_compare: compare_by_time
)
```

## Algorithm Selection Guide

| Algorithm | Use When | Time Complexity |
| ----------- | ---------- | ---------------- |
| **Dijkstra** | Non-negative weights, single shortest path | O((V+E) log V) |
| **A*** | Non-negative weights + good heuristic | O((V+E) log V)* |
| **Bellman-Ford** | Negative weights OR cycle detection needed | O(VE) |
| **BFS/DFS** | Unweighted graphs, exploring reachability | O(V+E) |
| **Kruskal's MST** | Finding minimum spanning tree | O(E log E) |
| **Tarjan's SCC** | Finding strongly connected components | O(V+E) |
| **Topological Sort** | Ordering tasks with dependencies | O(V+E) |

\* Often faster than Dijkstra in practice with good heuristics

## Examples

### Example 1: Social Network Analysis

```gleam
import yog/components
import yog/model.{Directed}

pub fn main() {
  // Model a social network where edges represent "follows" relationships
  let social_graph =
    model.new(Directed)
    |> model.add_node(1, "Alice")
    |> model.add_node(2, "Bob")
    |> model.add_node(3, "Carol")
    |> model.add_edge(from: 1, to: 2, with: Nil)
    |> model.add_edge(from: 2, to: 3, with: Nil)
    |> model.add_edge(from: 3, to: 1, with: Nil)

  // Find groups of mutually connected users
  let communities = components.strongly_connected_components(social_graph)
  echo communities
  // => [[1, 2, 3]]  // All three users form a strongly connected community
}
```

### Example 2: Task Scheduling

```gleam
import gleam/io
import gleam/string
import yog/model.{Directed}
import yog/topological_sort

pub fn main() {
  // Model tasks with dependencies
  let tasks =
    model.new(Directed)
    |> model.add_node(1, "Design")
    |> model.add_node(2, "Implement")
    |> model.add_node(3, "Test")
    |> model.add_node(4, "Deploy")
    |> model.add_edge(from: 1, to: 2, with: Nil)
    // Design before Implement
    |> model.add_edge(from: 2, to: 3, with: Nil)
    // Implement before Test
    |> model.add_edge(from: 3, to: 4, with: Nil)
  // Test before Deploy

  case topological_sort.topological_sort(tasks) {
    Ok(order) -> {
      // order = [1, 2, 3, 4] - valid execution order
      io.println("Execute tasks in order: " <> string.inspect(order))
    }
    Error(Nil) -> io.println("Circular dependency detected!")
  }
}
```

### Example 3: GPS Navigation

```gleam
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import yog/model.{Undirected}
import yog/pathfinding

pub fn main() {
  // Model road network with travel times
  let road_network =
    model.new(Undirected)
    |> model.add_node(1, "Home")
    |> model.add_node(2, "Office")
    |> model.add_node(3, "Mall")
    |> model.add_edge(from: 1, to: 2, with: 15)
    // 15 minutes
    |> model.add_edge(from: 2, to: 3, with: 10)
    |> model.add_edge(from: 1, to: 3, with: 30)

  // Use A* with straight-line distance heuristic
  let straight_line_distance = fn(from, to) {
    // Simplified: in reality would use coordinates
    case from == to {
      True -> 0
      False -> 5
      // Optimistic estimate
    }
  }

  case
    pathfinding.a_star(
      in: road_network,
      from: 1,
      to: 3,
      with_zero: 0,
      with_add: int.add,
      with_compare: int.compare,
      heuristic: straight_line_distance,
    )
  {
    Some(path) -> {
      // Path(nodes: [1, 2, 3], total_weight: 25)
      // Prints: Fastest route takes 25 minutes
      io.println(
        "Fastest route takes " <> int.to_string(path.total_weight) <> " minutes",
      )
    }
    None -> io.println("No route found")
  }
}
```

### Example 4: Network Cable Layout (Minimum Spanning Tree)

```gleam
import gleam/int
import gleam/io
import gleam/list
import yog/model.{Undirected}
import yog/mst

pub fn main() {
  // Model buildings and cable costs
  let buildings =
    model.new(Undirected)
    |> model.add_node(1, "Building A")
    |> model.add_node(2, "Building B")
    |> model.add_node(3, "Building C")
    |> model.add_node(4, "Building D")
    |> model.add_edge(from: 1, to: 2, with: 100)
    // $100 to connect
    |> model.add_edge(from: 1, to: 3, with: 150)
    |> model.add_edge(from: 2, to: 3, with: 50)
    |> model.add_edge(from: 2, to: 4, with: 200)
    |> model.add_edge(from: 3, to: 4, with: 100)

  // Find minimum cost to connect all buildings
  let cables = mst.kruskal(in: buildings, with_compare: int.compare)
  let total_cost = list.fold(cables, 0, fn(sum, edge) { sum + edge.weight })
  // => 250 (connects all buildings with minimum cable cost)
  // Prints: Minimum cable cost is 250
  io.println("Minimum cable cost is " <> int.to_string(total_cost))
}
```

## Testing

Run the test suite:

```sh
gleam test
```

Alltests pass, covering:

- Graph construction and operations
- All pathfinding algorithms
- Traversal patterns
- Graph transformations
- MST and topological sort
- Internal data structures (heap, union-find)

## Design Philosophy

Yog is designed with these principles:

1. **Functional and Immutable**: All operations return new graphs, no mutation
2. **Generic and Flexible**: Works with any weight type that supports addition and comparison
3. **Type-Safe**: Leverages Gleam's type system to prevent errors at compile time
4. **Well-Tested**: Comprehensive test suite with 256 tests
5. **Documented**: Every public function has documentation with examples
6. **Efficient**: Uses optimal algorithms and data structures (pairing heaps, union-find with path compression, O(1) transpose)

## Performance Characteristics

### Space Complexity

- Graph storage: O(V + E)
- Dijkstra/A*: O(V) for visited set and heap
- Bellman-Ford: O(V) for distances
- Union-Find: O(V)

### When to Use Each Algorithm

**Shortest Path:**

- Use **Dijkstra** for most cases with non-negative weights
- Use **A*** when you have a good heuristic (can be much faster)
- Use **Bellman-Ford** only when you have negative weights or need cycle detection

**Traversal:**

- Use **BFS** for shortest path in unweighted graphs, level-order traversal
- Use **DFS** for exhaustive search, topological properties

**MST:**

- Use **Kruskal's** for sparse graphs or when edges are already sorted

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass (`gleam test`)
2. New features include tests
3. Public functions have documentation
4. Code follows the existing style

## Acknowledgments

Yog implements classic algorithms from graph theory and computer science literature. I tried to keep the implementations optimized for Gleam's functional programming paradigm while maintaining algorithmic efficiency.

---

Further documentation can be found at <https://hexdocs.pm/yog>.

**Yog** - Graph algorithms for Gleam 🌳
