#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/.." && pwd)"
docs_dir="$project_dir/docs"

mkdir -p "$docs_dir"
find "$project_dir/Assets" -type f \( -iname "*.glb" -o -iname "*.gltf" \) | while IFS= read -r file; do
    filename=$(basename "$file")
    outfile="$docs_dir/${filename}.md"

    echo "Processing: $file"
    gltf-transform inspect "$file" --format=md > "$outfile" 2>&1
done
