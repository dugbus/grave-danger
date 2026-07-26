#!/usr/bin/env python3
"""Add one timestamped, player-facing entry to CHANGELOG.md."""

from __future__ import annotations

import argparse
import re
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


DATE_HEADING_PATTERN = re.compile(r"^## (\d{4}-\d{2}-\d{2})$")
HOUR_HEADING_PATTERN = re.compile(r"^### ([01]\d|2[0-3])00$")
TITLE = "# Changelog"
UNDATED_HEADING = "## Undated entries"


def _normalize_text(value: str, field_name: str) -> str:
    normalized = " ".join(value.split())
    if normalized.startswith("- ") or normalized.startswith("* "):
        normalized = normalized[2:].strip()
    if not normalized:
        raise ValueError(f"{field_name} cannot be empty.")
    return normalized


def _ensure_document(lines: list[str]) -> list[str]:
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()

    if not lines:
        return [TITLE]
    if lines[0].strip() == TITLE:
        return lines
    return [TITLE, "", UNDATED_HEADING, "", *lines]


def _insert_block(lines: list[str], index: int, block: list[str]) -> None:
    prefix_needs_blank = index > 0 and bool(lines[index - 1].strip())
    suffix_needs_blank = index < len(lines) and bool(lines[index].strip())
    insertion: list[str] = []
    if prefix_needs_blank:
        insertion.append("")
    insertion.extend(block)
    if suffix_needs_blank and (not insertion or insertion[-1].strip()):
        insertion.append("")
    lines[index:index] = insertion


def _date_heading_indexes(lines: list[str]) -> list[tuple[int, str]]:
    headings: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        match = DATE_HEADING_PATTERN.fullmatch(line.strip())
        if match:
            headings.append((index, match.group(1)))
    return headings


def _find_date_insert_index(lines: list[str], date_text: str) -> int:
    for index, existing_date in _date_heading_indexes(lines):
        if date_text > existing_date:
            return index

    for index, line in enumerate(lines):
        if index > 0 and line.startswith("## ") \
                and DATE_HEADING_PATTERN.fullmatch(line.strip()) is None:
            return index
    return len(lines)


def _find_section_end(lines: list[str], heading_index: int, prefix: str) -> int:
    for index in range(heading_index + 1, len(lines)):
        if lines[index].startswith(prefix):
            return index
    return len(lines)


def _find_hour_insert_index(
    lines: list[str],
    date_index: int,
    date_end: int,
    hour_text: str,
) -> int:
    for index in range(date_index + 1, date_end):
        match = HOUR_HEADING_PATTERN.fullmatch(lines[index].strip())
        if match and hour_text > match.group(1) + "00":
            return index
    return date_end


def format_changelog(
    existing_text: str,
    entry: str,
    prompt_summary: str,
    moment: datetime,
) -> tuple[str, bool]:
    """Return updated changelog text and whether a new entry was added."""
    normalized_entry = _normalize_text(entry, "Changelog entry")
    normalized_prompt = _normalize_text(prompt_summary, "Prompt summary")
    bullet = f"- {normalized_entry}"
    prompt_line = f"  - Prompt: {normalized_prompt}"
    date_text = moment.strftime("%Y-%m-%d")
    hour_text = moment.strftime("%H00")
    lines = _ensure_document(existing_text.splitlines())

    date_index = next(
        (
            index
            for index, existing_date in _date_heading_indexes(lines)
            if existing_date == date_text
        ),
        -1,
    )
    if date_index < 0:
        insert_index = _find_date_insert_index(lines, date_text)
        _insert_block(
            lines,
            insert_index,
            [
                f"## {date_text}",
                "",
                f"### {hour_text}",
                "",
                bullet,
                prompt_line,
                "",
            ],
        )
        return "\n".join(lines).rstrip() + "\n", True

    date_end = _find_section_end(lines, date_index, "## ")
    hour_index = next(
        (
            index
            for index in range(date_index + 1, date_end)
            if lines[index].strip() == f"### {hour_text}"
        ),
        -1,
    )
    if hour_index < 0:
        insert_index = _find_hour_insert_index(
            lines,
            date_index,
            date_end,
            hour_text,
        )
        _insert_block(
            lines,
            insert_index,
            [f"### {hour_text}", "", bullet, prompt_line, ""],
        )
        return "\n".join(lines).rstrip() + "\n", True

    hour_end = _find_section_end(lines, hour_index, "### ")
    hour_end = min(hour_end, date_end)
    entry_index = next(
        (
            index
            for index in range(hour_index + 1, hour_end)
            if lines[index].strip() == bullet
        ),
        -1,
    )
    if entry_index >= 0:
        existing_prompt_index = entry_index + 1
        has_existing_prompt = existing_prompt_index < hour_end \
            and lines[existing_prompt_index].strip().startswith("- Prompt:")
        if has_existing_prompt:
            if lines[existing_prompt_index].strip() == prompt_line.strip():
                return "\n".join(lines).rstrip() + "\n", False
            lines[existing_prompt_index] = prompt_line
        else:
            lines.insert(existing_prompt_index, prompt_line)
        return "\n".join(lines).rstrip() + "\n", True

    insert_index = hour_index + 1
    while insert_index < hour_end and not lines[insert_index].strip():
        insert_index += 1
    lines[insert_index:insert_index] = [bullet, prompt_line]
    if insert_index == hour_index + 1:
        lines.insert(insert_index, "")
    return "\n".join(lines).rstrip() + "\n", True


def _resolve_moment(at_text: str | None, timezone_name: str | None) -> datetime:
    selected_timezone = None
    if timezone_name:
        try:
            selected_timezone = ZoneInfo(timezone_name)
        except ZoneInfoNotFoundError as error:
            raise ValueError(f"Unknown timezone: {timezone_name}") from error

    if at_text:
        try:
            moment = datetime.fromisoformat(at_text)
        except ValueError as error:
            raise ValueError("--at must be an ISO-8601 date and time.") from error
        if moment.tzinfo is None:
            moment = moment.replace(
                tzinfo=selected_timezone or datetime.now().astimezone().tzinfo
            )
        elif selected_timezone is not None:
            moment = moment.astimezone(selected_timezone)
        return moment

    if selected_timezone is not None:
        return datetime.now(selected_timezone)
    return datetime.now().astimezone()


def _parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Add one timestamped entry to CHANGELOG.md.",
    )
    parser.add_argument("entry", help="Player-facing or level-editor-facing change.")
    parser.add_argument(
        "--prompt",
        required=True,
        help="Concise paraphrase of the originating user request.",
    )
    parser.add_argument(
        "--file",
        type=Path,
        default=Path("CHANGELOG.md"),
        help="Changelog path relative to the current directory.",
    )
    parser.add_argument(
        "--at",
        help="ISO-8601 timestamp override for tests or backdated entries.",
    )
    parser.add_argument(
        "--timezone",
        help="IANA timezone used for the current time or to convert --at.",
    )
    return parser.parse_args()


def main() -> int:
    arguments = _parse_arguments()
    try:
        moment = _resolve_moment(arguments.at, arguments.timezone)
        existing_text = arguments.file.read_text(encoding="utf-8") \
            if arguments.file.exists() else ""
        updated_text, added = format_changelog(
            existing_text,
            arguments.entry,
            arguments.prompt,
            moment,
        )
    except (OSError, ValueError) as error:
        print(f"Error: {error}")
        return 1

    if added:
        arguments.file.write_text(updated_text, encoding="utf-8")
        print(
            f"Added CHANGELOG entry under "
            f"{moment.strftime('%Y-%m-%d')} / {moment.strftime('%H00')}."
        )
    else:
        print("Identical CHANGELOG entry and prompt already exist in this hour.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
