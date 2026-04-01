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

for (( i=$start; i < $end; i++ )); do
    dir=${dirs[i]}
    echo "[$i] Found: '$dir'"
    readarray -t files < <(find "$dir" -type f -regex '.*.\(iso\|cue\|gdi\)$')
    for (( j=0; j<${#files[@]}; j++ )); do
        file=${files[j]}
        name=${file%.*} # Remove extension from file name
        out_file="$name.chd"
        if [[ ! -e "$out_file" ]]
        then
            chdman createdvd -i "$file" -o "$out_file" --force || {
                if [[ -e "$out_file" ]]
                then
                    rm "$out_file"
                fi
                echo "$dir" >> "$root_dir/errors.log"
            }
        else
            echo "Found: '$out_file', skipping..."
        fi
    done
done

echo "Operation Complete"