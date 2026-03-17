# Erlang-Only Benchmarks

This directory contains benchmarks that compare Yog algorithms with Erlang's `:digraph` module.

## Why are these separate?

These benchmarks use Erlang's `:digraph` module via FFI, which is only available on the Erlang target. To keep the main codebase compatible with both Erlang and JavaScript targets, these benchmarks are stored outside the `src/` directory.

## Available Benchmarks

- `compare_digraph.gleam` - General digraph operations
- `compare_digraph_acyclic.gleam` - Acyclic graph checks
- `compare_digraph_condensation.gleam` - Strongly connected components
- `compare_digraph_cycle.gleam` - Cycle detection
- `compare_digraph_path.gleam` - Pathfinding
- `compare_digraph_reachability.gleam` - Reachability queries
- `compare_digraph_topsort.gleam` - Topological sorting

## Running a Benchmark

1. Copy the benchmark to `test/bench/`:

   ```bash
   cp bench_erlang/compare_digraph_acyclic.gleam test/bench/
   ```

2. Run it:

   ```bash
   gleam run -m test/compare_digraph_acyclic
   ```

3. Clean up when done:

   ```bash
   rm test/bench/compare_digraph_acyclic.gleam
   ```

## Note

These files remain in the repository with the `.gleam` extension to maintain IDE support, syntax highlighting, and LSP features. Gleam only compiles files in the `src/` directory, so keeping them here doesn't affect the main build.
