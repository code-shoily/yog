# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - Unreleased

### Added
- **Visualization module (`yog/render`)** - Generate diagrams from graphs in multiple formats
  - `to_mermaid()` - Convert graphs to Mermaid syntax for GitHub/GitLab markdown
  - `to_dot()` - Convert graphs to DOT (Graphviz) format for publication-quality graphics
  - `to_json()` - Export graphs as JSON for web-based visualization libraries (D3.js, Cytoscape, etc.)
  - `path_to_options()` - Helper to highlight pathfinding results in Mermaid diagrams
  - `path_to_dot_options()` - Helper to highlight pathfinding results in DOT diagrams
  - Support for custom node and edge labels across all formats
  - Path highlighting with CSS classes (Mermaid) and color attributes (DOT)
  - Customizable JSON structure via mapper functions
  - Complete test coverage (47 tests)
- City navigation example demonstrating pathfinding with visualization

### Fixed
- Undirected graphs now render each edge only once in all formats (previously showed duplicates)

## [1.0.0] - 2025-02-26

### Added
- **Core graph data structures** (`yog/model`)
  - Directed and undirected graph support
  - Generic node and edge types
  - Add/remove nodes and edges
  - Query successors, predecessors, neighbors

- **Pathfinding algorithms** (`yog/pathfinding`)
  - Dijkstra's algorithm for non-negative weights
  - A* search with heuristic support
  - Bellman-Ford for negative weights and cycle detection

- **Graph traversal** (`yog/traversal`)
  - Breadth-First Search (BFS)
  - Depth-First Search (DFS)
  - Early termination support

- **Minimum Spanning Tree** (`yog/mst`)
  - Kruskal's algorithm with Union-Find

- **Topological sorting** (`yog/topological_sort`)
  - Kahn's algorithm
  - Lexicographical variant with heap-based implementation

- **Connected components** (`yog/components`)
  - Tarjan's algorithm for Strongly Connected Components (SCC)

- **Graph transformations** (`yog/transform`)
  - Transpose (O(1) edge reversal)
  - Map nodes and edges (functor operations)
  - Filter nodes with automatic edge pruning
  - Merge graphs

- Comprehensive test suite (276 tests)
- Complete documentation with examples
- Published to Hex package manager

[1.1.0]: https://github.com/yourusername/yog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yourusername/yog/releases/tag/v1.0.0
