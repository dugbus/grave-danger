#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
godot_binary="${GODOT_BIN:-godot}"

show_usage() {
	cat <<'USAGE'
Usage: ./resolution-test.sh [options]

Captures the main UI scenes at a representative set of display resolutions.
Screenshots are written to screenshots/<width>x<height>/<scene>.png.

Options:
  --resolutions=LIST  Comma-separated resolutions, for example 1280x720,2560x1080
  --scenes=LIST       Comma-separated res:// scene paths
  --output=PATH       Output directory under res:// or user:// (default: res://screenshots)
  --help              Show this help

Set GODOT_BIN when the Godot executable is not available as "godot" on PATH.
USAGE
}

for argument in "$@"; do
	if [[ "$argument" == "--help" ]]; then
		show_usage
		exit 0
	fi
done

if ! command -v "$godot_binary" >/dev/null 2>&1; then
	printf 'Godot executable not found: %s\n' "$godot_binary" >&2
	printf 'Set GODOT_BIN to the Godot 4 executable and try again.\n' >&2
	exit 1
fi

"$godot_binary" \
	--path "$script_dir" \
	--windowed \
	--resolution 960x540 \
	--audio-driver Dummy \
	--script res://tests/resolution_screenshot_runner.gd \
	-- \
	"$@"
