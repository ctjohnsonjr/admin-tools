#!/usr/bin/env bash

# Usage:
# ./generateM3Us.sh /path/to/search
set -euo pipefail

ROOT_DIR="${1:-.}"

for game in $ROOT_DIR*; do
    m3u="$game/$(basename "$game").m3u"
    find "$game/" -name "*(Disc [1-9])*.chd" | while read -r disc; do
        disc_name=$(basename "$disc")
        echo "$disc_name" >> "$m3u"
    done
done