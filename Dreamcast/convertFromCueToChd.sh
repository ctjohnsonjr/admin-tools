#!/usr/bin/env bash

# Usage:
# ./convertFromCueToChd.sh /path/to/search countperpage,page
set -euo pipefail

root_dir="${1:-.}"
if [[ -v 2 ]]; then
    paging_params=(${2//,/ })
    count=${paging_params[0]}
    page=${paging_params[1]}
fi

echo "Converting: $root_dir"
readarray -t dirs < <(find "$root_dir" -maxdepth 1 -type d ! -path "$root_dir")

length=${#dirs[@]}

start=0
end=$length
if [[ -v count ]]; then
    start=$(($count * ($page - 1)))
    page_end=$(($count * $page))
    end=$(( ($length<=$page_end) ? $length : $page_end ))
fi

if [[ $start -ge $length ]]; then
    echo "Page is outside the range of entries"
    exit 1
fi

for ((i=$start ; i < $end; i++)); do
    dir=${dirs[i]}
    echo "[$i] Found: '$dir'"
    for cue_file in "$dir"/*.cue; do
        name=${cue_file%.cue} # Remove '.cue' from file name
        chd_file="$name.chd"
        if [[ ! -e "$chd_file" ]]
        then
            chdman createcd -i "$cue_file" -o "$chd_file" --force
        else
            echo "Found: '$chd_file', skipping..."
        fi
    done
done

echo "Operation Complete"