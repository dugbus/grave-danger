#!/usr/bin/env bash

set -euo pipefail

readonly MACOS_PRESET="macOS Apple Silicon"
readonly MACOS_ARTIFACT="GraveDanger-macOS.zip"
readonly WINDOWS_PRESET="Windows x86_64"
readonly WINDOWS_ARTIFACT="GraveDanger-Windows-x86_64.exe"
readonly IOS_PRESET="iOS ARM64"
readonly IOS_ARTIFACT="GraveDanger-iOS.zip"
readonly IOS_OPTIONS_SECTION="preset.3.options"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly script_dir
readonly godot_binary="${GODOT_BIN:-godot}"

build_output_dir="${BUILD_OUTPUT_DIR:-builds}"
if [[ "$build_output_dir" != /* ]]; then
	build_output_dir="$script_dir/$build_output_dir"
fi
readonly build_output_dir

dry_run=false
declare -a requested_targets=()
declare -a artifacts=()


usage() {
	cat <<'USAGE'
Usage: ./build-production.sh [--dry-run] [all|macos|windows|ios ...]

Packages release builds using the export presets in export_presets.cfg.
With no targets, all production targets are built.

Environment:
  GODOT_BIN         Godot executable or path (default: godot)
  BUILD_OUTPUT_DIR  Output directory, relative to the repository by default
  GODOT_TEMPLATE_DIR
                    Godot version's export-template directory, when nonstandard

Examples:
  ./build-production.sh
  ./build-production.sh macos windows
  ./build-production.sh --dry-run all

iOS production packaging requires a 10-character Apple Team ID in the
"iOS ARM64" export preset and a working Xcode command-line installation.
USAGE
}


fail() {
	printf 'Build error: %s\n' "$1" >&2
	exit 1
}


add_all_targets() {
	requested_targets=(macos windows ios)
}


read_export_option() {
	local section="$1"
	local option_name="$2"
	awk -v section="[$section]" -v option_name="$option_name" '
		$0 == section {
			in_section = 1
			next
		}
		in_section && /^\[/ {
			exit
		}
		in_section && index($0, option_name "=") == 1 {
			value = substr($0, length(option_name) + 2)
			gsub(/^"|"$/, "", value)
			print value
			exit
		}
	' "$script_dir/export_presets.cfg"
}


preflight_ios() {
	[[ "$(uname -s)" == Darwin ]] \
		|| fail "iOS packages require macOS with Xcode installed."
	command -v xcodebuild >/dev/null 2>&1 \
		|| fail "xcodebuild was not found. Install Xcode and its command-line tools."

	local team_id
	team_id="$(read_export_option "$IOS_OPTIONS_SECTION" "application/app_store_team_id")"
	[[ "$team_id" =~ ^[[:alnum:]]{10}$ ]] || fail \
		"Set the 10-character Apple Team ID in the '$IOS_PRESET' export preset."
}


resolve_template_directory() {
	if [[ -n "${GODOT_TEMPLATE_DIR:-}" ]]; then
		printf '%s\n' "$GODOT_TEMPLATE_DIR"
		return
	fi

	local godot_version
	local template_version
	godot_version="$("$godot_binary" --version)"
	template_version="$(awk -F. '{ print $1 "." $2 "." $3; exit }' <<< "$godot_version")"
	case "$(uname -s)" in
		Darwin)
			printf '%s/Library/Application Support/Godot/export_templates/%s\n' \
				"${HOME:?HOME is required}" "$template_version"
			;;
		Linux)
			local data_directory="${XDG_DATA_HOME:-${HOME:?HOME is required}/.local/share}"
			printf '%s/godot/export_templates/%s\n' "$data_directory" "$template_version"
			;;
		MINGW*|MSYS*|CYGWIN*)
			printf '%s/Godot/export_templates/%s\n' \
				"${APPDATA:?APPDATA is required}" "$template_version"
			;;
		*)
			fail "Cannot locate Godot export templates on $(uname -s). Set GODOT_TEMPLATE_DIR."
			;;
	esac
}


preflight_export_template() {
	local target="$1"
	local template_directory="$2"
	local platform_name
	local template_name
	case "$target" in
		macos)
			platform_name="macOS"
			template_name="macos.zip"
			;;
		windows)
			platform_name="Windows x86_64"
			template_name="windows_release_x86_64.exe"
			;;
		ios)
			platform_name="iOS"
			template_name="ios.zip"
			;;
	esac

	[[ -f "$template_directory/$template_name" ]] || fail \
		"Missing $platform_name export template: $template_directory/$template_name. Install it from Godot's Editor > Manage Export Templates."
}


parse_arguments() {
	while (($# > 0)); do
		case "$1" in
			--dry-run)
				dry_run=true
				;;
			-h|--help)
				usage
				exit 0
				;;
			all|macos|windows|ios)
				requested_targets+=("$1")
				;;
			*)
				fail "Unknown target '$1'. Run with --help for supported targets."
				;;
		esac
		shift
	done

	if ((${#requested_targets[@]} == 0)); then
		add_all_targets
		return
	fi
	if [[ " ${requested_targets[*]} " == *" all "* ]]; then
		if ((${#requested_targets[@]} > 1)); then
			fail "Use 'all' by itself, or list individual targets without 'all'."
		fi
		add_all_targets
	fi
}


preflight() {
	[[ -f "$script_dir/project.godot" ]] \
		|| fail "project.godot was not found beside this script."
	[[ -f "$script_dir/export_presets.cfg" ]] \
		|| fail "export_presets.cfg is missing."

	if [[ "$dry_run" == true ]]; then
		return
	fi
	command -v "$godot_binary" >/dev/null 2>&1 \
		|| fail "Godot executable '$godot_binary' was not found. Set GODOT_BIN if needed."

	local template_directory
	template_directory="$(resolve_template_directory)"
	for target in "${requested_targets[@]}"; do
		preflight_export_template "$target" "$template_directory"
		if [[ "$target" == ios ]]; then
			preflight_ios
		fi
	done
	mkdir -p -- "$build_output_dir"
}


package_target() {
	local preset="$1"
	local artifact_name="$2"
	local artifact_path="$build_output_dir/$artifact_name"

	printf '\nPackaging %s\n' "$preset"
	printf 'Output: %s\n' "$artifact_path"
	if [[ "$dry_run" == true ]]; then
		printf 'Dry run:'
		printf ' %q' \
			"$godot_binary" \
			--headless \
			--path "$script_dir" \
			--export-release "$preset" \
			"$artifact_path"
		printf '\n'
		return
	fi

	"$godot_binary" \
		--headless \
		--path "$script_dir" \
		--export-release "$preset" \
		"$artifact_path"
	[[ -e "$artifact_path" ]] \
		|| fail "Godot completed without creating $artifact_name."
	artifacts+=("$artifact_path")
}


package_requested_targets() {
	for target in "${requested_targets[@]}"; do
		case "$target" in
			macos)
				package_target "$MACOS_PRESET" "$MACOS_ARTIFACT"
				;;
			windows)
				package_target "$WINDOWS_PRESET" "$WINDOWS_ARTIFACT"
				;;
			ios)
				package_target "$IOS_PRESET" "$IOS_ARTIFACT"
				;;
		esac
	done
}


report_success() {
	if [[ "$dry_run" == true ]]; then
		printf '\nDry run complete; no packages were written.\n'
		return
	fi

	printf '\nProduction packages created:\n'
	for artifact in "${artifacts[@]}"; do
		printf '  %s\n' "$artifact"
	done
}


parse_arguments "$@"
preflight
package_requested_targets
report_success
