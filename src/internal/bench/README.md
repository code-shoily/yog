# Yog Benchmarks

Internal benchmarking suite for Yog graph algorithms.

## Quick Start

```bash
# Run the example
gleam run -m internal/bench/simple_pathfinding

# Create your own
cp src/internal/bench/simple_pathfinding.gleam src/internal/bench/my_benchmark.gleam
gleam run -m internal/bench/my_benchmark
```

## Files

- **`simple_pathfinding.gleam`** - Working example (use as template)
- **`bench_utils.gleam`** - Graph generators and utilities

## Documentation

See **`BENCHMARKING_GUIDE.md`** in the project root for:
- Complete templates
- Graph generator API
- Best practices
- Algorithm complexity guide
- Troubleshooting

## Quick Reference

### Graph Sizes
- `bench_utils.Small` = 100 nodes
- `bench_utils.Medium` = 1,000 nodes
- `bench_utils.Large` = 10,000 nodes
- `bench_utils.XLarge` = 100,000 nodes

### Graph Densities
- `bench_utils.Sparse` = ~1% edges
- `bench_utils.MediumDensity` = ~5% edges
- `bench_utils.Dense` = ~20% edges

### Graph Generators
```gleam
import internal/bench/bench_utils

// Random
bench_utils.random_graph(size, density, seed)

// Structured
bench_utils.grid_graph(width, height)
bench_utils.complete_graph(nodes)
bench_utils.random_dag(nodes, seed)
bench_utils.bipartite_graph(left, right)
```

### Basic Template
```gleam
import gleam/int
import gleamy/bench
import internal/bench/bench_utils
import yog/pathfinding

pub fn main() {
  let graph = bench_utils.random_graph(
    bench_utils.Medium,
    bench_utils.Sparse,
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
