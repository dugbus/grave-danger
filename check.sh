#!/usr/bin/env bash
set -euo pipefail

godot --headless --check-only --quit --path . --log-file scene_scan.log 2>&1 | sed '/^Godot Engine /d'
godot --headless --path . --script res://tools/check_all_scenes.gd --debug --log-file scene_scan.log 2>&1 | sed '/^Godot Engine /d'
godot --headless --path . --script res://tests/run_tests.gd --log-file scene_scan.log 2>&1 | sed '/^Godot Engine /d'

if ! lint_output="$(gdlint . 2>&1)"; then
	printf '%s\n' "$lint_output" | tee -a scene_scan.log
	exit 1
fi

printf '%s\n' "$lint_output" >> scene_scan.log

script_count="$(rg --files -g '*.gd' -g '!addons/**' -g '!tests/**' | wc -l | tr -d ' ')"
printf 'Linted %s/%s .gd scripts.\n' "$script_count" "$script_count"
