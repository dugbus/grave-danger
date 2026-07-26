#!/usr/bin/env python3
"""Launch directed Grave Danger playtests and inspect recorded player sessions."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Sequence


REPLAY_RUNNER = "res://tools/codex_replay_runner.gd"
GAME_SCENE = "res://game/graveyard.tscn"
OUTPUT_PREFIX = "CODEX_REPLAY "
LOG_CHANNELS = {
    "summary",
    "metadata",
    "feedback",
    "position",
    "input",
    "camera",
    "buttons",
    "drift",
}
ACTIVE_REPORT_DIRECTORY = Path("feedback/reports")
ARCHIVE_REPORT_DIRECTORY = Path("feedback/archive")
CHANGELOG_SCRIPT = Path(".agents/skills/write-changelog/scripts/add_changelog_entry.py")
MAXIMUM_REPORT_COUNT = 20
MAXIMUM_REPORT_BYTES = 25 * 1024 * 1024


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Coordinate directed player tests and inspect the game's saved replays."
    )
    parser.add_argument(
        "--repo",
        type=Path,
        help="Repository root; defaults to the nearest project.godot.",
    )
    parser.add_argument(
        "--godot",
        help="Godot executable; defaults to GODOT_BIN or the godot command on PATH.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    request_test = subparsers.add_parser(
        "request-test",
        help="Launch a level with a player-facing Codex test instruction.",
    )
    request_test.add_argument("--instruction", required=True)
    request_test.add_argument("--level")
    request_test.add_argument(
        "--report-button",
        default="square",
        choices=("triangle", "cross", "square", "circle", "disabled"),
    )
    request_test.add_argument(
        "--text-button",
        default="disabled",
        choices=("triangle", "cross", "square", "circle", "disabled"),
    )
    request_test.add_argument(
        "--confirmed",
        action="store_true",
        help="Assert that the user explicitly said they are ready.",
    )
    request_test.add_argument("--dry-run", action="store_true")

    recordings = subparsers.add_parser(
        "recordings",
        help="List saved recordings newest first.",
    )
    recordings.add_argument("--dry-run", action="store_true")

    replay = subparsers.add_parser(
        "replay",
        help="Replay a saved session with selected JSONL logging.",
    )
    replay.add_argument("--level", default="latest")
    replay.add_argument(
        "--logs",
        default="summary,metadata,position,input,buttons",
        help="Comma-separated channels, all, or none.",
    )
    replay.add_argument("--sample-seconds", type=float, default=0.5)
    replay.add_argument("--speed", type=float, default=1.0)
    replay.add_argument("--output", type=Path)
    replay.add_argument("--visual", action="store_true")
    replay.add_argument(
        "--confirmed",
        action="store_true",
        help="Assert user readiness before opening visual replay.",
    )
    replay.add_argument("--dry-run", action="store_true")

    feedback = subparsers.add_parser(
        "feedback",
        aliases=["new-feedback"],
        help="Inspect only the newest player-marked moment and its nearby samples.",
    )
    feedback.add_argument(
        "--logs",
        default="summary,metadata,feedback,position,input,buttons",
        help="Comma-separated channels, all, or none.",
    )
    feedback.add_argument("--sample-seconds", type=float, default=0.25)
    feedback.add_argument(
        "--report",
        default="latest",
        help="Committed report ID or latest.",
    )
    feedback.add_argument("--before", type=float, default=2.0)
    feedback.add_argument("--after", type=float, default=3.0)
    feedback.add_argument("--speed", type=float, default=1.0)
    feedback.add_argument("--output", type=Path)
    feedback.add_argument("--visual", action="store_true")
    feedback.add_argument(
        "--confirmed",
        action="store_true",
        help="Assert user readiness before opening visual feedback playback.",
    )
    feedback.add_argument("--dry-run", action="store_true")

    subparsers.add_parser(
        "reports",
        help="List repository-backed open feedback reports newest first.",
    )

    archive = subparsers.add_parser(
        "archive-feedback",
        help="Archive a corrected report and record the fix in CHANGELOG.md.",
    )
    archive.add_argument("--report", required=True)
    archive.add_argument("--fix", required=True)
    return parser


def find_repository_root(explicit_root: Path | None, start: Path | None = None) -> Path:
    if explicit_root is not None:
        root = explicit_root.expanduser().resolve()
        _validate_repository(root)
        return root
    current = (start or Path.cwd()).resolve()
    for candidate in (current, *current.parents):
        if (candidate / "project.godot").is_file():
            _validate_repository(candidate)
            return candidate
    raise ValueError("Could not find a repository containing project.godot.")


def find_godot(explicit_executable: str | None) -> str:
    requested = explicit_executable or os.environ.get("GODOT_BIN") or "godot"
    resolved = shutil.which(requested)
    if resolved is None:
        raise ValueError(
            "Could not find Godot. Pass --godot or set GODOT_BIN to a Godot 4.7 executable."
        )
    return resolved


def build_request_test_command(
    godot: str,
    repository: Path,
    instruction: str,
    level: str | None,
    report_button: str = "square",
    text_button: str = "disabled",
) -> list[str]:
    command = [
        godot,
        "--path",
        str(repository),
        "--log-file",
        str(repository / ".godot" / "codex_player_session.log"),
        GAME_SCENE,
        "--",
        "--codex-test",
        instruction,
        "--codex-report-button",
        report_button,
        "--codex-text-button",
        text_button,
    ]
    if level:
        command.extend(["--codex-level", level])
    command.append("--codex-confirmed")
    return command


def build_feedback_command(
    godot: str,
    repository: Path,
    *,
    logs: str,
    sample_seconds: float,
    before: float,
    after: float,
    speed: float,
    output: Path | None,
    visual: bool,
    report: str = "latest",
) -> list[str]:
    command = [godot]
    if not visual:
        command.append("--headless")
    command.extend(
        [
            "--path",
            str(repository),
            "--log-file",
            str(repository / ".godot" / "codex_player_session.log"),
            "--script",
            REPLAY_RUNNER,
            "--",
            "--codex-new-feedback",
            "--codex-feedback-report",
            report,
            "--codex-logs",
            logs,
            "--codex-sample-seconds",
            str(sample_seconds),
            "--codex-feedback-before",
            str(before),
            "--codex-feedback-after",
            str(after),
            "--codex-speed",
            str(speed),
        ]
    )
    if visual:
        command.extend(["--codex-visual", "--codex-confirmed"])
    if output is not None:
        command.extend(["--codex-log-file", str(output.expanduser().resolve())])
    return command


def list_repository_reports(repository: Path) -> list[dict[str, object]]:
    report_directory = repository / ACTIVE_REPORT_DIRECTORY
    reports: list[dict[str, object]] = []
    if not report_directory.is_dir():
        return reports
    for report_path in report_directory.glob("*.json"):
        try:
            report = json.loads(report_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(report, dict):
            continue
        report["_path"] = str(report_path.relative_to(repository))
        reports.append(report)
    reports.sort(
        key=lambda report: (
            int(report.get("created_unix_time", 0)),
            str(report.get("report_id", "")),
        ),
        reverse=True,
    )
    return reports


def archive_feedback_report(repository: Path, report_id: str, fix: str) -> dict[str, str]:
    active_directory = repository / ACTIVE_REPORT_DIRECTORY
    report_path = active_directory / f"{report_id}.json"
    if not report_path.is_file():
        raise ValueError(f"Open feedback report not found: {report_id}")
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(f"Feedback report is not valid JSON: {report_id}") from error
    if not isinstance(report, dict):
        raise ValueError(f"Feedback report is not an object: {report_id}")

    concise_fix = " ".join(fix.split())
    if not concise_fix:
        raise ValueError("--fix must contain visible text.")
    resolved_at = datetime.now().astimezone()
    archive_directory = (
        repository / ARCHIVE_REPORT_DIRECTORY / resolved_at.date().isoformat()
    )
    archive_directory.mkdir(parents=True, exist_ok=True)
    archived_report_path = archive_directory / report_path.name
    playback_name = str(report.get("playback_file", f"{report_id}.gdr"))
    playback_path = active_directory / playback_name
    archived_playback_path = archive_directory / playback_name
    level_scene_name = str(report.get("level_scene_file", f"{report_id}.tscn"))
    level_scene_path = active_directory / level_scene_name
    archived_level_scene_path = archive_directory / level_scene_name

    report["status"] = "resolved"
    report["fix"] = concise_fix
    report["resolved_at"] = resolved_at.isoformat(timespec="seconds")
    archived_report_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if playback_path.is_file():
        shutil.move(str(playback_path), str(archived_playback_path))
    if level_scene_path.is_file():
        shutil.move(str(level_scene_path), str(archived_level_scene_path))
    report_path.unlink()

    marker = report.get("marker", {})
    marker_time = float(marker.get("time", 0.0)) if isinstance(marker, dict) else 0.0
    level_id = str(report.get("level_id", "unknown"))
    playback_reference = (
        str(archived_playback_path.relative_to(repository))
        if archived_playback_path.is_file()
        else "playback unavailable"
    )
    outcome = (
        f"{concise_fix} Feedback report {report_id} marked at {marker_time:.2f}s "
        f"in {level_id} is archived with {playback_reference}."
    )
    note = str(marker.get("note", "")).strip() if isinstance(marker, dict) else ""
    prompt = f"Resolve feedback report {report_id}"
    if note:
        prompt += f": {note}"
    changelog_script = repository / CHANGELOG_SCRIPT
    completed = subprocess.run(
        [
            sys.executable,
            str(changelog_script),
            "--prompt",
            prompt,
            outcome,
        ],
        cwd=repository,
        check=False,
    )
    if completed.returncode != 0:
        raise OSError("Could not record the resolved feedback in CHANGELOG.md.")
    pruned = enforce_report_retention(repository)
    return {
        "report_id": report_id,
        "archive": str(archived_report_path.relative_to(repository)),
        "playback": playback_reference,
        "level_scene": (
            str(archived_level_scene_path.relative_to(repository))
            if archived_level_scene_path.is_file()
            else "level snapshot unavailable"
        ),
        "pruned": ",".join(pruned),
    }


def enforce_report_retention(repository: Path) -> list[str]:
    active_reports = list((repository / ACTIVE_REPORT_DIRECTORY).glob("*.json"))
    archived_reports = sorted(
        (repository / ARCHIVE_REPORT_DIRECTORY).glob("*/*.json"),
        key=lambda path: (path.stat().st_mtime, path.name),
    )

    def playback_bytes() -> int:
        paths = [
            *(repository / ACTIVE_REPORT_DIRECTORY).glob("*.gdr"),
            *(repository / ARCHIVE_REPORT_DIRECTORY).glob("*/*.gdr"),
        ]
        return sum(path.stat().st_size for path in paths if path.is_file())

    pruned: list[str] = []
    while archived_reports and (
        len(active_reports) + len(archived_reports) > MAXIMUM_REPORT_COUNT
        or playback_bytes() > MAXIMUM_REPORT_BYTES
    ):
        archived_report = archived_reports.pop(0)
        try:
            report = json.loads(archived_report.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            report = {}
        report_id = str(report.get("report_id", archived_report.stem))
        playback_name = str(report.get("playback_file", f"{report_id}.gdr"))
        archived_playback = archived_report.parent / playback_name
        level_scene_name = str(
            report.get("level_scene_file", f"{report_id}.tscn")
        )
        archived_level_scene = archived_report.parent / level_scene_name
        if archived_playback.is_file():
            archived_playback.unlink()
        if archived_level_scene.is_file():
            archived_level_scene.unlink()
        archived_report.unlink()
        pruned.append(report_id)
    return pruned


def build_recordings_command(godot: str, repository: Path) -> list[str]:
    return [
        godot,
        "--headless",
        "--path",
        str(repository),
        "--log-file",
        str(repository / ".godot" / "codex_player_session.log"),
        "--script",
        REPLAY_RUNNER,
        "--",
        "--codex-list-recordings",
    ]


def build_replay_command(
    godot: str,
    repository: Path,
    *,
    level: str,
    logs: str,
    sample_seconds: float,
    speed: float,
    output: Path | None,
    visual: bool,
) -> list[str]:
    command = [godot]
    if not visual:
        command.append("--headless")
    command.extend(
        [
            "--path",
            str(repository),
            "--log-file",
            str(repository / ".godot" / "codex_player_session.log"),
            "--script",
            REPLAY_RUNNER,
            "--",
            "--codex-replay",
            "--codex-level",
            level,
            "--codex-logs",
            logs,
            "--codex-sample-seconds",
            str(sample_seconds),
            "--codex-speed",
            str(speed),
        ]
    )
    if visual:
        command.extend(["--codex-visual", "--codex-confirmed"])
    if output is not None:
        command.extend(["--codex-log-file", str(output.expanduser().resolve())])
    return command


def validate_logs(raw_logs: str) -> None:
    normalized = raw_logs.strip().lower()
    if normalized in {"all", "none"}:
        return
    requested = {item.strip() for item in normalized.split(",") if item.strip()}
    unknown = requested - LOG_CHANNELS
    if unknown:
        raise ValueError(f"Unknown log channels: {', '.join(sorted(unknown))}")


def run_filtered(command: Sequence[str]) -> int:
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    replay_lines = [
        line.removeprefix(OUTPUT_PREFIX)
        for line in completed.stdout.splitlines()
        if line.startswith(OUTPUT_PREFIX)
    ]
    for line in replay_lines:
        print(line)
    if completed.returncode != 0:
        diagnostics = [
            line
            for line in (completed.stdout + "\n" + completed.stderr).splitlines()
            if line and not line.startswith(OUTPUT_PREFIX)
        ]
        if diagnostics:
            print("\n".join(diagnostics[-30:]), file=sys.stderr)
    return completed.returncode


def _validate_repository(repository: Path) -> None:
    required_paths = [
        repository / "project.godot",
        repository / "game" / "graveyard.tscn",
        repository / "tools" / "codex_replay_runner.gd",
    ]
    missing = [str(path.relative_to(repository)) for path in required_paths if not path.exists()]
    if missing:
        raise ValueError(f"Repository is missing: {', '.join(missing)}")


def _print_command(command: Sequence[str]) -> None:
    print(shlex.join(command))


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)
    try:
        repository = find_repository_root(arguments.repo)
        (repository / ".godot").mkdir(exist_ok=True)
        if arguments.command == "reports":
            for report in list_repository_reports(repository):
                print(json.dumps({
                    key: value
                    for key, value in report.items()
                    if key in {
                        "report_id",
                        "level_id",
                        "created_unix_time",
                        "status",
                        "playback_status",
                        "level_scene_status",
                        "_path",
                    }
                }))
            return 0

        if arguments.command == "archive-feedback":
            result = archive_feedback_report(
                repository,
                arguments.report,
                arguments.fix,
            )
            print(json.dumps(result))
            return 0

        godot = find_godot(arguments.godot)
        if arguments.command == "request-test":
            instruction = " ".join(arguments.instruction.split())
            if not instruction:
                raise ValueError("--instruction must contain visible text.")
            if not arguments.confirmed:
                print(
                    json.dumps(
                        {
                            "status": "user_confirmation_required",
                            "question": (
                                "Are you ready to start the playtest now? "
                                f"Requested action: {instruction}"
                            ),
                        }
                    )
                )
                return 4
            command = build_request_test_command(
                godot,
                repository,
                instruction,
                arguments.level,
                arguments.report_button,
                arguments.text_button,
            )
            if arguments.dry_run:
                _print_command(command)
                return 0
            return subprocess.run(command, check=False).returncode

        if arguments.command == "recordings":
            command = build_recordings_command(godot, repository)
            if arguments.dry_run:
                _print_command(command)
                return 0
            return run_filtered(command)

        if arguments.command in {"feedback", "new-feedback"}:
            validate_logs(arguments.logs)
            if arguments.sample_seconds <= 0.0:
                raise ValueError("--sample-seconds must be greater than zero.")
            if arguments.before < 0.0 or arguments.after < 0.0:
                raise ValueError("--before and --after must be zero or greater.")
            if arguments.speed <= 0.0:
                raise ValueError("--speed must be greater than zero.")
            if arguments.visual and not arguments.confirmed:
                print(
                    json.dumps(
                        {
                            "status": "user_confirmation_required",
                            "question": (
                                "Are you ready to open the visual feedback playback?"
                            ),
                        }
                    )
                )
                return 4
            command = build_feedback_command(
                godot,
                repository,
                logs=arguments.logs,
                sample_seconds=arguments.sample_seconds,
                before=arguments.before,
                after=arguments.after,
                speed=arguments.speed,
                output=arguments.output,
                visual=arguments.visual,
                report=arguments.report,
            )
            if arguments.dry_run:
                _print_command(command)
                return 0
            exit_code = run_filtered(command)
            if exit_code == 0 and arguments.output is not None:
                print(f"Feedback log written to {arguments.output.expanduser().resolve()}")
            return exit_code

        validate_logs(arguments.logs)
        if arguments.sample_seconds <= 0.0:
            raise ValueError("--sample-seconds must be greater than zero.")
        if arguments.speed <= 0.0:
            raise ValueError("--speed must be greater than zero.")
        if arguments.visual and not arguments.confirmed:
            print(
                json.dumps(
                    {
                        "status": "user_confirmation_required",
                        "question": "Are you ready for the visual replay window to open now?",
                    }
                )
            )
            return 4
        command = build_replay_command(
            godot,
            repository,
            level=arguments.level,
            logs=arguments.logs,
            sample_seconds=arguments.sample_seconds,
            speed=arguments.speed,
            output=arguments.output,
            visual=arguments.visual,
        )
        if arguments.dry_run:
            _print_command(command)
            return 0
        if arguments.visual:
            return subprocess.run(command, check=False).returncode
        exit_code = run_filtered(command)
        if exit_code == 0 and arguments.output is not None:
            print(f"Replay log written to {arguments.output.expanduser().resolve()}")
        return exit_code
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
