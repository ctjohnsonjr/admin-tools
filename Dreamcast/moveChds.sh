#!/usr/bin/env bash

# Usage:
# ./moveChds /path/to/search /destination/path

set -euo pipefail

ROOT_DIR="${1:-.}"
DESTINATION="$2"
for file in "$ROOT_DIR"**/*.chd; do
    echo "Moving: $file -> $DESTINATION"
    mv "$file" "$DESTINATION"
done