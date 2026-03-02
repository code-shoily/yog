# Yog Benchmarking Guide

Comprehensive guide to benchmarking Yog graph algorithms.

## Quick Start

### Run the Example

```bash
gleam run -m internal/bench/simple_pathfinding
```

### Create Your Own

```bash
cp src/internal/bench/simple_pathfinding.gleam src/internal/bench/my_benchmark.gleam
# Edit my_benchmark.gleam
gleam run -m internal/bench/my_benchmark
```

### Basic Template

```gleam
import gleam/int
import gleamy/bench
import internal/bench/bench_utils
import yog/pathfinding

pub fn main() {
  // 1. Create test graphs
  let graph = bench_utils.random_graph(
    bench_utils.Medium,  // 1K nodes
    bench_utils.Sparse,  // ~1% edges
    42
  )

  // 2. Define inputs and functions
  let inputs = [bench.Input("Test", #(graph, 0, 999))]
  let functions = [bench.Function("Dijkstra", run_dijkstra)]

  // 3. Run and display results
  bench.run(inputs, functions, [bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println
}

fn run_dijkstra(input: #(Graph(Nil, Int), Int, Int)) -> Nil {
  let #(graph, from, to) = input
  let _ = pathfinding.shortest_path(
    in: graph, from: from, to: to,
    with_zero: 0, with_add: int.add, with_compare: int.compare
  )
  Nil
}
```

## What to Benchmark

### High Priority (Most Expensive)

- **Pathfinding**: Dijkstra, A*, Bellman-Ford, Floyd-Warshall
- **Max Flow**: Edmonds-Karp (O(VE²))
- **Min Cut**: Stoer-Wagner (O(V³))

### Medium Priority

- **Traversal**: BFS vs DFS vs fold_walk
- **SCC**: Tarjan vs Kosaraju
- **MST**: Kruskal vs Prim

### Algorithm Comparison Ideas

- Dijkstra vs A* (with good/bad heuristic)
- Kruskal vs Prim (sparse vs dense graphs)
- Algorithm scaling with graph size
- Sparse vs dense graph performance

## Graph Generators

### Sizes

```gleam
bench_utils.Small      // 100 nodes
bench_utils.Medium     // 1,000 nodes
bench_utils.Large      // 10,000 nodes
bench_utils.XLarge     // 100,000 nodes
```

### Densities

```gleam
bench_utils.Sparse         // ~1% edges
bench_utils.MediumDensity  // ~5% edges
bench_utils.Dense          // ~20% edges
```

### Graph Types

```gleam
// Random graph
bench_utils.random_graph(size, density, seed)

// Grid (great for pathfinding)
bench_utils.grid_graph(50, 50)

// Complete graph (worst case)
bench_utils.complete_graph(100)

// DAG (topological sort)
bench_utils.random_dag(100, seed)

// Bipartite (matching)
bench_utils.bipartite_graph(50, 50)
```

## Configuration

### Duration & Warmup

```gleam
bench.run(inputs, functions, [
  bench.Duration(2000),  // Run for 2 seconds
  bench.Warmup(500),     // Warm up for 500ms
])
```

Use longer duration (5000ms) for very fast operations (<1ms).

### Multiple Algorithms

```gleam
let inputs = [bench.Input("Same graph", graph)]

let functions = [
  bench.Function("Algorithm A", algo_a),
  bench.Function("Algorithm B", algo_b),
]

bench.run(inputs, functions, [bench.Duration(2000)])
|> bench.table([bench.IPS, bench.Min, bench.P(99)])
|> io.println
```

## Understanding Results

### Output

Benchmarks display a table with these metrics:

```
Input               Function       IPS           Min           Max           P99
Small: 100 nodes    Dijkstra    3906736.16     0.0001       56.02          0.001
Medium: 1K nodes    Dijkstra        557.99     1.4301        5.42          4.20
```

### Metrics

- **IPS**: Iterations Per Second (higher is better)
- **Min**: Minimum execution time in milliseconds
- **Max**: Maximum execution time (shows outliers)
- **P99**: 99th percentile - 99% of runs were this fast or faster

### Scalability Patterns

- **O(V)**: 10× nodes → 10× time
- **O(V log V)**: 10× nodes → ~13× time
- **O(V²)**: 10× nodes → 100× time
- **O(V³)**: 10× nodes → 1000× time

### Expected Performance

| Algorithm | Complexity | 100 nodes | 1K nodes | 10K nodes |
|-----------|-----------|-----------|----------|-----------|
| BFS/DFS | O(V+E) | ~100μs | ~1ms | ~10ms |
| Dijkstra | O((V+E) log V) | ~200μs | ~2-3ms | ~30-40ms |
| Bellman-Ford | O(VE) | ~500μs | ~50ms | ~5s |
| Floyd-Warshall | O(V³) | ~10ms | ~10s | Too slow |

*Rough estimates for sparse graphs*

## Best Practices

### 1. Choose Appropriate Sizes

Match graph size to algorithm complexity:

- **O(V³)**: Max 100 nodes (Small)
- **O(V²) or O(VE)**: Max 1K nodes (Medium)
- **O(E log V)**: Max 10K nodes (Large)
- **O(V+E)**: Up to 100K nodes (XLarge)

### 2. Test What Matters

Only benchmark the algorithm, not setup:

```gleam
// ❌ Bad: includes graph construction
fn bad(_input: Nil) -> Nil {
  let g = build_graph()  // This gets measured!
  let _ = algorithm(g)
  Nil
}

// ✅ Good: only algorithm measured
fn good(input: Graph(Nil, Int)) -> Nil {
  let _ = algorithm(input)
  Nil
}
```

### 3. Fair Comparisons

Use identical inputs when comparing algorithms:

```gleam
let graph = bench_utils.random_graph(...)  // Generate once

let inputs = [bench.Input("Same for all", graph)]

let functions = [
  bench.Function("Algo A", algo_a),
  bench.Function("Algo B", algo_b),  // Fair comparison
]
```

### 4. Start Small

Test with small graphs first, then scale up:

```gleam
let inputs = [
  bench.Input("10 nodes", tiny_graph),
  bench.Input("100 nodes", small_graph),
  // Add larger only if fast:
  // bench.Input("1K nodes", medium_graph),
]
```

### 5. Document Expectations

```gleam
io.println("Benchmarking: Dijkstra vs Bellman-Ford")
io.println("Expected: Dijkstra ~10-100x faster")
io.println("Complexity: O(E log V) vs O(VE)\n")
```

## Algorithm Complexity Reference

| Algorithm | Time | Space | Max Practical Size |
|-----------|------|-------|--------------------|
| BFS/DFS | O(V+E) | O(V) | 100K+ nodes |
| Dijkstra | O((V+E) log V) | O(V) | 100K+ nodes |
| A* | O((V+E) log V) | O(V) | 100K+ nodes |
| Bellman-Ford | O(VE) | O(V) | 10K nodes |
| Floyd-Warshall | O(V³) | O(V²) | 1K nodes |
| Kruskal MST | O(E log E) | O(V) | 100K+ nodes |
| Prim MST | O(E log V) | O(V) | 100K+ nodes |
| Edmonds-Karp | O(VE²) | O(V) | 1K nodes |
| Stoer-Wagner | O(V³) | O(V²) | 100 nodes |
| Tarjan SCC | O(V+E) | O(V) | 100K+ nodes |
| Kosaraju SCC | O(V+E) | O(V) | 100K+ nodes |

## Troubleshooting

### Benchmark takes forever
- Reduce graph size
- Lower `Duration` parameter
- Check algorithm complexity vs graph size

### Out of memory
- Use smaller graphs
- Avoid `Dense` with `Large` or `XLarge`
- Check algorithm space complexity

### Inconsistent results
- Increase `Duration` and `Warmup`
- Close other applications
- Run multiple times

### Module not found
- File must be in `src/internal/bench/`
- Run: `gleam run -m internal/bench/filename`

## Why `internal/bench`?

Benchmarks are in `src/internal/bench/` to:
- Keep them out of Yog's public API
- Prevent pollution of user imports/autocomplete
- Still allow individual execution: `gleam run -m internal/bench/...`

This follows Gleam best practices for internal tooling.

## Further Reading

- [gleamy_bench documentation](https://hexdocs.pm/gleamy_bench/)
- [Yog documentation](https://hexdocs.pm/yog/)
- Example: `src/internal/bench/simple_pathfinding.gleam`

---

**Happy Benchmarking! 📊**
