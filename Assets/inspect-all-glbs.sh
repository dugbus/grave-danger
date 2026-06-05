#!/usr/bin/env bash

set -euo pipefail
mkdir -p ../docs
find . -type f \( -iname "*.glb" -o -iname "*.gltf" \) | while read -r file; do
    filename=$(basename "$file")
    outfile="../docs/${filename}.md"

    echo "Processing: $file"
    gltf-transform inspect "$file" --format=md > "$outfile" 2>&1
done