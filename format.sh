#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/.agents/skills/format-gdscript/scripts/format_gdscript.py" "$@"
