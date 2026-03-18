#!/bin/bash

# Script to run all example files in test/examples/
# Usage: ./run_examples.sh

set -e

EXAMPLES_DIR="test/examples"

echo "Running all examples from $EXAMPLES_DIR..."
echo ""

for file in "$EXAMPLES_DIR"/*.gleam; do
    # Extract filename without extension
    filename=$(basename "$file" .gleam)
    module="examples/$filename"
    
    echo "=================================="
    echo "Running: $module"
    echo "=================================="
    gleam run -m "$module"
    echo ""
done

echo "=================================="
echo "All examples completed!"
echo "=================================="
