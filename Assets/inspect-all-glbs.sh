#!/usr/bin/env bash

set -euo pipefail

find . -type f \( -iname "*.glb" -o -iname "*.gltf" \) | while read -r file; do
    outfile="../docs/${file}.md"

    echo "Processing: $file"
    gltf-transform inspect "$file" --format=md > "$outfile" 2>&1
done