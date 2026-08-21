#!/usr/bin/env bash
set -euo pipefail

readonly teardown_diagnostic_pattern='ObjectDB instances were leaked at exit|resources still in use at exit|RID allocations .* were leaked at exit|Pages in use exist at exit'
readonly dummy_shader_diagnostic_pattern='RID allocations of type .*RendererDummy.*DummyShader.* were leaked at exit'

run_godot_check() {
	local allowed_dummy_shader_count="$1"
	shift
	local command_output
	local command_status
	if command_output="$("$@" 2>&1)"; then
		command_status=0
	else
		command_status=$?
	fi

	if ((command_status != 0)); then
		printf '%s\n' "$command_output" | sed '/^Godot Engine /d'
		return "$command_status"
	fi

	# Godot 4.7's headless dummy renderer reports internal shader allocations
	# after scenes containing shader-backed materials are instantiated. Keep a
	# strict per-command ceiling so engine noise is hidden without masking growth
	# or any other teardown leak.
	local dummy_shader_count=0
	local dummy_shader_line
	dummy_shader_line="$(rg "$dummy_shader_diagnostic_pattern" <<< "$command_output" || true)"
	if [[ -n "$dummy_shader_line" ]]; then
		dummy_shader_count="$(sed -E 's/^ERROR: ([0-9]+) RID allocations.*/\1/' <<< "$dummy_shader_line")"
	fi
	if ((dummy_shader_count > allowed_dummy_shader_count)); then
		printf '%s\n' "$command_output" | sed '/^Godot Engine /d'
		printf 'Dummy-renderer shader allocations exceeded the allowed baseline (%s > %s).\n' \
			"$dummy_shader_count" "$allowed_dummy_shader_count" >&2
		return 1
	fi

	command_output="$(printf '%s\n' "$command_output" \
		| sed '/^Godot Engine /d' \
		| sed "/$dummy_shader_diagnostic_pattern/d")"
	printf '%s\n' "$command_output"
	if rg -q "$teardown_diagnostic_pattern" <<< "$command_output"; then
		printf 'Godot reported leaked teardown state; failing validation.\n' >&2
		return 1
	fi
}

run_godot_check 0 godot --headless --check-only --quit --path . --log-file scene_scan.log
run_godot_check 2 godot --headless --path . --script res://tools/check_all_scenes.gd --debug --log-file scene_scan.log
run_godot_check 0 godot --headless --path . --script res://tests/check_test_pairs.gd --log-file scene_scan.log
run_godot_check 2 godot --headless --path . --script res://tests/test_runner.gd --log-file scene_scan.log
run_godot_check 4 godot --headless --path . --script res://tests/run_tests.gd --log-file scene_scan.log

if ! lint_output="$(gdlint . 2>&1)"; then
	printf '%s\n' "$lint_output" | tee -a scene_scan.log
	exit 1
fi

printf '%s\n' "$lint_output" >> scene_scan.log

script_count="$(rg --files -g '*.gd' -g '!addons/**' -g '!tests/**' | wc -l | tr -d ' ')"
printf 'Linted %s/%s .gd scripts.\n' "$script_count" "$script_count"
