#!/usr/bin/env bash

# Usage:
# ./consolidateDisks.sh /path/to/search
set -euo pipefail

ROOT_DIR="${1:-.}"
for file in "$ROOT_DIR"*.chd; do
    dir_name=$(echo "$file" | sed -r 's/(( \(Disc [1-9]+\))?\.chd)//')
    if [[ ! -d "$dir_name" ]]; then
        echo "Created: $dir_name"
        mkdir "$dir_name"
    fi

    echo "Moving: $file -> $dir_name"
    mv "$file" "$dir_name"
done