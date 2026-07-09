#!/usr/bin/env bash
set -euo pipefail

godot --headless --check-only --quit --path . --log-file scene_scan.log
godot --headless --path . --script res://tools/check_all_scenes.gd --debug --log-file scene_scan.log
gdlint . 2>&1 | tee -a scene_scan.log
