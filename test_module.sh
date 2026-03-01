#!/usr/bin/env bash
# Run tests for a single module without running the full test suite.
#
# Usage:
#   ./test_module.sh <gleam_module_path>
#
# Examples:
#   ./test_module.sh yog/pathfinding_test
#   ./test_module.sh yog/model_test
#   ./test_module.sh yog_test
#
# The argument is the path under test/ without the .gleam extension.
# Slashes are converted to @ to match Erlang module naming.

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <module_path>"
  echo ""
  echo "Examples:"
  echo "  $0 yog/pathfinding_test"
  echo "  $0 yog/model_test"
  echo "  $0 yog_test"
  echo ""
  echo "Available test modules:"
  find test -name "*_test.gleam" | sed 's|test/||; s|\.gleam||' | sort
  exit 1
fi

MODULE_PATH="$1"
# Convert path separators to @ (Gleam -> Erlang module naming)
ERLANG_MODULE="${MODULE_PATH//\//@}"

echo "Building project..."
gleam build --target erlang

echo ""
echo "Running tests for: $ERLANG_MODULE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Expand the glob and build -pa flags for each ebin directory
PA_FLAGS=()
for dir in build/dev/erlang/*/ebin; do
  PA_FLAGS+=(-pa "$dir")
done

erl "${PA_FLAGS[@]}" \
    -eval "eunit:test('${ERLANG_MODULE}', [verbose]), init:stop()" \
    -noshell
