#!/bin/bash

# Yog Graph Library Benchmark Runner
# This script runs the comprehensive benchmark suite for Yog

set -e

echo "=========================================="
echo "  Yog Graph Library Benchmark Suite"
echo "=========================================="
echo ""

# Check if gleam is installed
if ! command -v gleam &> /dev/null; then
    echo "Error: Gleam is not installed. Please install it first."
    echo "Visit: https://gleam.run/getting-started/installing/"
    exit 1
fi

# Build the project
echo "Building project..."
gleam build

# Run benchmarks
echo ""
echo "Running benchmarks..."
echo "This will take several minutes..."
echo ""

gleam run -m bench/runner

echo ""
echo "=========================================="
echo "  Benchmark suite completed successfully"
echo "=========================================="
