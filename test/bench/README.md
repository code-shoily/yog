# Yog Benchmarks

Internal benchmarking suite for Yog graph algorithms.

## Quick Start

```bash
# Run the example
gleam run -m bench/simple_pathfinding

# Create your own
cp test/bench/simple_pathfinding.gleam test/bench/my_benchmark.gleam
# Update as needed
gleam run -m bench/my_benchmark
```

## Files

- **`simple_pathfinding.gleam`** - Working example (use as template)
- **`bench_util.gleam`** - Graph generators and utilities

## Documentation

See **`BENCHMARKING_GUIDE.md`** in the project root for:

- Complete templates
- Graph generator API
- Best practices
- Algorithm complexity guide
- Troubleshooting

## Quick Reference

### Graph Sizes

- `bench_util.Small` = 100 nodes
- `bench_util.Medium` = 1,000 nodes
- `bench_util.Large` = 10,000 nodes
- `bench_util.XLarge` = 100,000 nodes

### Graph Densities

- `bench_util.Sparse` = ~1% edges
- `bench_util.MediumDensity` = ~5% edges
- `bench_util.Dense` = ~20% edges

### Graph Generators

```gleam
import yog/internal/bench/bench_util

// Random
bench_util.random_graph(size, density, seed)

// Structured
bench_util.grid_graph(width, height)
bench_util.complete_graph(nodes)
bench_util.random_dag(nodes, seed)
bench_util.bipartite_graph(left, right)
```

### Basic Template

```gleam
import gleam/int
import gleamy/bench
import yog/internal/bench/bench_util
import yog/pathfinding

pub fn main() {
  let graph = bench_util.random_graph(
    bench_util.Medium,
    bench_util.Sparse,
    42
  )

  let inputs = [bench.Input("Test", #(graph, 0, 999))]
  let functions = [bench.Function("Dijkstra", run_dijkstra)]

  bench.run(inputs, functions, [bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
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

---

**For detailed documentation, see `BENCHMARKING_GUIDE.md` in the project root.**
