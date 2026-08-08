#!/usr/bin/env python3
"""Safely duplicate a repository level or instantiate the generated-level template."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import struct
import sys
import tempfile
import zlib
from dataclasses import asdict, dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Iterable, Sequence


LEVEL_SCENE_FILE = "level.tscn"
LEVEL_PNG_FILE = "level.png"
MAPPING_RELATIVE_PATH = Path("levels/level_mapping.tres")
TEMPLATE_KEY = "generated-template"
TEMPLATE_FOLDER = "generated-level-template"
TEXT_SUFFIXES = {
    ".cfg",
    ".gd",
    ".gdshader",
    ".ini",
    ".json",
    ".material",
    ".md",
    ".shader",
    ".tres",
    ".tscn",
    ".txt",
    ".xml",
    ".yaml",
    ".yml",
}
IGNORED_FILE_NAMES = {".DS_Store"}
IGNORED_SUFFIXES = {".import", ".uid"}
IGNORED_SCAN_PARTS = {".agents", ".git", ".godot"}
MAX_PNG_DIMENSION = 4096
MAX_GENERATED_DIMENSION = 257
MIN_GENERATED_DIMENSION = 7


class SourceKind(str, Enum):
    """Kinds of base level understood by the duplicator."""

    LEVEL = "level"
    TEMPLATE = "template"


class MappingFormat(str, Enum):
    """Supported level-mapping serialization formats."""

    DICTIONARY = "dictionary"
    LEVEL_DEFINITION = "level_definition"


@dataclass(frozen=True)
class MappingEntry:
    """One entry parsed from levels/level_mapping.tres."""

    level_id: str
    name: str
    folder: str
    values: dict[str, Any]


@dataclass(frozen=True)
class LevelOption:
    """One unique scene folder exposed by --list."""

    key: str
    name: str
    folder: str
    source_kind: str
    aliases: tuple[str, ...] = ()
    description: str = ""


@dataclass(frozen=True)
class ResolvedBase:
    """Resolved source directory and optional mapping metadata."""

    key: str
    name: str
    folder: str
    source_kind: SourceKind
    source_directory: Path
    mapping_entry: MappingEntry | None = None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "List repository level bases or duplicate one with rewritten local references."
        )
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--list",
        action="store_true",
        help="List level names, IDs, folders, aliases, and bundled templates.",
    )
    mode.add_argument(
        "--base",
        metavar="NAME_OR_ID",
        help="Base level name, ID, folder, or generated-template.",
    )
    parser.add_argument("--name", help="Display name for the new level.")
    parser.add_argument("--folder", help="New folder below levels/; inferred when omitted.")
    parser.add_argument("--id", dest="level_id", help="Stable level ID; inferred when omitted.")
    parser.add_argument(
        "--legacy-result-key",
        help="Optional unique legacy result key for old save/result compatibility.",
    )
    parser.add_argument(
        "--png-size",
        metavar="WIDTHxHEIGHT",
        help="Create a transparent level.png at the exact dimensions.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=1,
        help="Maze seed used by generated-template (default: 1).",
    )
    parser.add_argument(
        "--skip-mapping",
        action="store_true",
        help="Create the level without adding it to levels/level_mapping.tres.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and report the planned operation without writing.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON.",
    )
    parser.add_argument(
        "--repo",
        type=Path,
        help="Repository root; defaults to the nearest project.godot above the current directory.",
    )
    return parser


def find_repository_root(explicit_root: Path | None, start: Path | None = None) -> Path:
    if explicit_root is not None:
        candidate = explicit_root.expanduser().resolve()
        _validate_repository_root(candidate)
        return candidate

    current = (start or Path.cwd()).resolve()
    for candidate in (current, *current.parents):
        if (candidate / "project.godot").is_file() and (candidate / "levels").is_dir():
            return candidate
    raise ValueError("Could not find a Godot repository containing project.godot and levels/.")


def _validate_repository_root(root: Path) -> None:
    if not (root / "project.godot").is_file():
        raise ValueError(f"Repository root has no project.godot: {root}")
    if not (root / "levels").is_dir():
        raise ValueError(f"Repository root has no levels directory: {root}")


def parse_mapping_entries(mapping_path: Path) -> list[MappingEntry]:
    if not mapping_path.is_file():
        return []
    content = mapping_path.read_text(encoding="utf-8")
    mapping_format = _detect_mapping_format(content, mapping_path)
    if mapping_format is MappingFormat.LEVEL_DEFINITION:
        return _parse_level_definition_entries(content)

    marker = "level_entries = Array[Dictionary](["
    marker_index = content.find(marker)

    entries: list[MappingEntry] = []
    body_start = marker_index + len(marker)
    body_end = content.find("}])", body_start)
    if body_end < 0:
        raise ValueError(f"Could not find the end of level_entries in {mapping_path}")
    body = content[body_start : body_end + 1]
    for match in re.finditer(r"\{(.*?)\}", body, flags=re.DOTALL):
        values = _parse_dictionary(match.group(1))
        folder = str(values.get("folder_name", ""))
        if not folder:
            continue
        name = str(values.get("name", folder))
        level_id = str(values.get("id", _to_snake_case(name)))
        entries.append(MappingEntry(level_id, name, folder, values))
    return entries


def _detect_mapping_format(content: str, mapping_path: Path) -> MappingFormat:
    if "level_entries = Array[Dictionary]([" in content:
        return MappingFormat.DICTIONARY
    if re.search(r"(?m)^level_entries = Array\[ExtResource\([^\]]+\)\]\(\[", content):
        return MappingFormat.LEVEL_DEFINITION
    raise ValueError(f"Could not find level_entries in {mapping_path}")


def _parse_level_definition_entries(content: str) -> list[MappingEntry]:
    entries: list[MappingEntry] = []
    block_pattern = re.compile(
        r'(?ms)^\[sub_resource type="Resource" id="[^"]+"\]\n(.*?)(?=^\[|\Z)'
    )
    for match in block_pattern.finditer(content):
        values = _parse_resource_properties(match.group(1))
        folder = str(values.get("folder_name", ""))
        if not folder:
            continue
        name = str(values.get("display_name", folder))
        level_id = str(values.get("id", _to_snake_case(name)))
        entries.append(MappingEntry(level_id, name, folder, values))
    return entries


def _parse_resource_properties(body: str) -> dict[str, Any]:
    values: dict[str, Any] = {}
    for key, raw_value in re.findall(
        r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)$",
        body,
        re.MULTILINE,
    ):
        value = raw_value.strip()
        if value.startswith('"') and value.endswith('"'):
            values[key] = value[1:-1]
        elif value == "true":
            values[key] = True
        elif value == "false":
            values[key] = False
        elif re.fullmatch(r"-?\d+", value):
            values[key] = int(value)
    return values


def _parse_dictionary(body: str) -> dict[str, Any]:
    values: dict[str, Any] = {}
    for key, raw_value in re.findall(r'^"([^"]+)":\s*(.+?)(?:,)?$', body, re.MULTILINE):
        value = raw_value.strip().rstrip(",")
        if value.startswith('"') and value.endswith('"'):
            values[key] = value[1:-1]
        elif value == "true":
            values[key] = True
        elif value == "false":
            values[key] = False
        elif re.fullmatch(r"-?\d+", value):
            values[key] = int(value)
    return values


def discover_level_options(repository_root: Path) -> list[LevelOption]:
    entries = parse_mapping_entries(repository_root / MAPPING_RELATIVE_PATH)
    entries_by_folder: dict[str, list[MappingEntry]] = {}
    for entry in entries:
        entries_by_folder.setdefault(entry.folder, []).append(entry)

    options: list[LevelOption] = []
    level_directories = sorted(
        (
            directory
            for directory in (repository_root / "levels").iterdir()
            if directory.is_dir() and (directory / LEVEL_SCENE_FILE).is_file()
        ),
        key=lambda path: _natural_sort_key(path.name),
    )
    for directory in level_directories:
        mapped_entries = entries_by_folder.get(directory.name, [])
        if mapped_entries:
            primary = mapped_entries[0]
            aliases = tuple(
                f"{entry.name} ({entry.level_id})" for entry in mapped_entries[1:]
            )
            options.append(
                LevelOption(
                    key=primary.level_id,
                    name=primary.name,
                    folder=directory.name,
                    source_kind=SourceKind.LEVEL.value,
                    aliases=aliases,
                )
            )
        else:
            options.append(
                LevelOption(
                    key=directory.name,
                    name=_humanize(directory.name),
                    folder=directory.name,
                    source_kind=SourceKind.LEVEL.value,
                    description="Unmapped level scene",
                )
            )

    options.append(
        LevelOption(
            key=TEMPLATE_KEY,
            name="Generated Level Template",
            folder=TEMPLATE_FOLDER,
            source_kind=SourceKind.TEMPLATE.value,
            description="Procedural maze scene with configurable PNG dimensions",
        )
    )
    return options


def resolve_base(repository_root: Path, query: str) -> ResolvedBase:
    normalized_query = query.strip().casefold()
    if normalized_query in {
        TEMPLATE_KEY,
        TEMPLATE_FOLDER,
        "generated level template",
    }:
        template_directory = Path(__file__).resolve().parents[1] / "assets" / TEMPLATE_FOLDER
        if not (template_directory / LEVEL_SCENE_FILE).is_file():
            raise ValueError(f"Generated-level template is incomplete: {template_directory}")
        return ResolvedBase(
            key=TEMPLATE_KEY,
            name="Generated Level Template",
            folder=TEMPLATE_FOLDER,
            source_kind=SourceKind.TEMPLATE,
            source_directory=template_directory,
        )

    entries = parse_mapping_entries(repository_root / MAPPING_RELATIVE_PATH)
    exact_entries = [
        entry
        for entry in entries
        if normalized_query
        in {entry.level_id.casefold(), entry.name.casefold(), entry.folder.casefold()}
        and (repository_root / "levels" / entry.folder / LEVEL_SCENE_FILE).is_file()
    ]
    matched_folders = {entry.folder for entry in exact_entries}
    if len(matched_folders) == 1:
        selected = exact_entries[0]
        return ResolvedBase(
            key=selected.level_id,
            name=selected.name,
            folder=selected.folder,
            source_kind=SourceKind.LEVEL,
            source_directory=repository_root / "levels" / selected.folder,
            mapping_entry=selected,
        )
    if len(matched_folders) > 1:
        choices = ", ".join(f"{entry.name} ({entry.level_id})" for entry in exact_entries)
        raise ValueError(f"Base query is ambiguous; use one of: {choices}")

    direct_directory = repository_root / "levels" / query
    if direct_directory.is_dir() and (direct_directory / LEVEL_SCENE_FILE).is_file():
        return ResolvedBase(
            key=query,
            name=_humanize(query),
            folder=query,
            source_kind=SourceKind.LEVEL,
            source_directory=direct_directory,
        )
    raise ValueError(f"Unknown base level: {query}. Run with --list to see valid choices.")


def infer_level_identifiers(name: str) -> tuple[str, str, str | None]:
    cleaned_name = " ".join(name.split())
    numbered_match = re.fullmatch(r"Level\s+(\d+)", cleaned_name, flags=re.IGNORECASE)
    if numbered_match:
        number = int(numbered_match.group(1))
        width = max(2, len(numbered_match.group(1)))
        legacy_key = str(number).zfill(width)
        return str(number), f"level_{legacy_key}", legacy_key

    folder = _to_kebab_case(cleaned_name)
    return folder, _to_snake_case(cleaned_name), None


def parse_png_size(raw_size: str | None) -> tuple[int, int] | None:
    if raw_size is None:
        return None
    match = re.fullmatch(r"\s*(\d+)\s*[xX]\s*(\d+)\s*", raw_size)
    if match is None:
        raise ValueError("PNG size must use WIDTHxHEIGHT, for example 64x48.")
    width, height = int(match.group(1)), int(match.group(2))
    if not 1 <= width <= MAX_PNG_DIMENSION or not 1 <= height <= MAX_PNG_DIMENSION:
        raise ValueError(
            f"PNG dimensions must be between 1 and {MAX_PNG_DIMENSION} pixels."
        )
    return width, height


def duplicate_level(
    repository_root: Path,
    base_query: str,
    name: str,
    *,
    folder: str | None = None,
    level_id: str | None = None,
    legacy_result_key: str | None = None,
    png_size: tuple[int, int] | None = None,
    seed: int = 1,
    skip_mapping: bool = False,
    dry_run: bool = False,
) -> dict[str, Any]:
    base = resolve_base(repository_root, base_query)
    display_name = " ".join(name.split())
    if not display_name:
        raise ValueError("--name must contain visible text.")

    inferred_folder, inferred_id, inferred_legacy_key = infer_level_identifiers(display_name)
    target_folder = folder or inferred_folder
    target_id = level_id or inferred_id
    target_legacy_key = (
        legacy_result_key if legacy_result_key is not None else inferred_legacy_key
    )
    _validate_folder(target_folder)
    _validate_level_id(target_id)
    if not skip_mapping:
        _validate_mapping_uniqueness(
            repository_root,
            target_folder,
            target_id,
            display_name,
            target_legacy_key,
        )

    target_directory = repository_root / "levels" / target_folder
    if target_directory.exists():
        raise ValueError(f"Target level folder already exists: levels/{target_folder}")

    effective_png_size = png_size
    if base.source_kind is SourceKind.TEMPLATE and effective_png_size is None:
        effective_png_size = (31, 31)
    if base.source_kind is SourceKind.TEMPLATE and effective_png_size is not None:
        width, height = effective_png_size
        if not (
            MIN_GENERATED_DIMENSION <= width <= MAX_GENERATED_DIMENSION
            and MIN_GENERATED_DIMENSION <= height <= MAX_GENERATED_DIMENSION
        ):
            raise ValueError(
                "Generated template dimensions must be between "
                f"{MIN_GENERATED_DIMENSION} and {MAX_GENERATED_DIMENSION}."
            )

    copied_files = list(_source_files(base.source_directory))
    external_references = (
        _find_external_references(repository_root, base.folder, base.source_directory)
        if base.source_kind is SourceKind.LEVEL
        else []
    )
    result: dict[str, Any] = {
        "base": base.key,
        "base_folder": base.folder,
        "created": not dry_run,
        "dry_run": dry_run,
        "level_id": target_id,
        "level_name": display_name,
        "target": f"levels/{target_folder}",
        "mapping_updated": not skip_mapping and not dry_run,
        "png_size": list(effective_png_size) if effective_png_size else None,
        "seed": seed,
        "copied_files": [
            str(path.relative_to(base.source_directory)) for path in copied_files
        ],
        "external_references": external_references,
    }
    if dry_run:
        return result

    levels_directory = repository_root / "levels"
    temporary_directory = Path(
        tempfile.mkdtemp(prefix=f".duplicate-{target_folder}-", dir=levels_directory)
    )
    try:
        _copy_level_files(
            base,
            temporary_directory,
            target_folder,
            display_name,
            effective_png_size,
            seed,
        )
        temporary_directory.rename(target_directory)
        if not skip_mapping:
            try:
                _append_mapping_entry(
                    repository_root / MAPPING_RELATIVE_PATH,
                    target_folder,
                    target_id,
                    display_name,
                    target_legacy_key,
                    base.mapping_entry,
                )
            except Exception:
                shutil.rmtree(target_directory)
                raise
    except Exception:
        if temporary_directory.exists():
            shutil.rmtree(temporary_directory)
        raise
    return result


def _source_files(source_directory: Path) -> Iterable[Path]:
    for path in sorted(source_directory.rglob("*")):
        if not path.is_file() or path.is_symlink():
            continue
        if path.name in IGNORED_FILE_NAMES or path.suffix in IGNORED_SUFFIXES:
            continue
        yield path


def _copy_level_files(
    base: ResolvedBase,
    target_directory: Path,
    target_folder: str,
    display_name: str,
    png_size: tuple[int, int] | None,
    seed: int,
) -> None:
    old_prefix = f"res://levels/{base.folder}/"
    new_prefix = f"res://levels/{target_folder}/"
    class_name_rewrites = _collect_class_name_rewrites(
        base.source_directory,
        _to_pascal_case(display_name),
    )
    for source_path in _source_files(base.source_directory):
        relative_path = source_path.relative_to(base.source_directory)
        if png_size is not None and relative_path == Path(LEVEL_PNG_FILE):
            continue
        target_path = target_directory / relative_path
        target_path.parent.mkdir(parents=True, exist_ok=True)
        if source_path.suffix.lower() in TEXT_SUFFIXES:
            content = source_path.read_text(encoding="utf-8")
            content = _rewrite_text(
                content,
                old_prefix,
                new_prefix,
                relative_path,
                display_name,
                png_size,
                seed,
                base.source_kind,
                class_name_rewrites,
            )
            target_path.write_text(content, encoding="utf-8")
        else:
            shutil.copyfile(source_path, target_path)

    if png_size is not None:
        write_transparent_png(target_directory / LEVEL_PNG_FILE, *png_size)


def _rewrite_text(
    content: str,
    old_prefix: str,
    new_prefix: str,
    relative_path: Path,
    display_name: str,
    png_size: tuple[int, int] | None,
    seed: int,
    source_kind: SourceKind,
    class_name_rewrites: dict[str, str],
) -> str:
    rewritten = content.replace(old_prefix, new_prefix)
    rewritten = re.sub(r'\s+uid="uid://[^"]+"', "", rewritten)
    for old_class_name, new_class_name in class_name_rewrites.items():
        rewritten = re.sub(
            rf"\b{re.escape(old_class_name)}\b",
            new_class_name,
            rewritten,
        )

    if relative_path == Path(LEVEL_SCENE_FILE):
        root_name = _to_pascal_case(display_name) or "Level"
        rewritten = re.sub(
            r'(?m)^(\[node name=")[^"]+(" type="[^"]+"(?: [^\]]+)?\])$',
            rf"\g<1>{root_name}\g<2>",
            rewritten,
            count=1,
        )
        if source_kind is SourceKind.TEMPLATE:
            rewritten = re.sub(
                r"(?m)^maze_seed = -?\d+$",
                f"maze_seed = {seed}",
                rewritten,
            )

    if png_size is not None:
        width, height = png_size
        if relative_path.name == "png_to_gridmap_settings.tres":
            rewritten = re.sub(
                r"(?m)^export_size = Vector2i\(\d+,\s*\d+\)$",
                f"export_size = Vector2i({width}, {height})",
                rewritten,
            )
        if (
            relative_path.name == "generated_maze_config.tres"
            or 'script_class="GDGeneratedMazeConfig"' in rewritten
        ):
            rewritten = re.sub(r"(?m)^width = \d+$", f"width = {width}", rewritten)
            rewritten = re.sub(r"(?m)^height = \d+$", f"height = {height}", rewritten)
    return rewritten


def _collect_class_name_rewrites(
    source_directory: Path,
    target_pascal_name: str,
) -> dict[str, str]:
    rewrites: dict[str, str] = {}
    for path in _source_files(source_directory):
        if path.suffix.lower() != ".gd":
            continue
        content = path.read_text(encoding="utf-8")
        match = re.search(r"(?m)^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", content)
        if match is None:
            continue
        old_class_name = match.group(1)
        rewrites[old_class_name] = f"{old_class_name}{target_pascal_name}"
    return rewrites


def write_transparent_png(path: Path, width: int, height: int) -> None:
    """Write a standards-compliant transparent RGBA PNG using only the standard library."""

    signature = b"\x89PNG\r\n\x1a\n"
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    scanline = b"\x00" + (b"\x00\x00\x00\x00" * width)
    pixels = zlib.compress(scanline * height, level=9)
    png = signature + _png_chunk(b"IHDR", header) + _png_chunk(b"IDAT", pixels)
    png += _png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(kind)
    checksum = zlib.crc32(data, checksum)
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


def _append_mapping_entry(
    mapping_path: Path,
    folder: str,
    level_id: str,
    name: str,
    legacy_result_key: str | None,
    source_entry: MappingEntry | None,
) -> None:
    if not mapping_path.is_file():
        raise ValueError(f"Cannot update missing mapping file: {mapping_path}")
    content = mapping_path.read_text(encoding="utf-8")
    mapping_format = _detect_mapping_format(content, mapping_path)
    if mapping_format is MappingFormat.LEVEL_DEFINITION:
        _append_level_definition_entry(
            mapping_path,
            content,
            folder,
            level_id,
            name,
            legacy_result_key,
            source_entry,
        )
        return

    closing_index = content.rfind("}])")
    if closing_index < 0:
        raise ValueError(f"Could not find the end of level_entries in {mapping_path}")

    values: list[tuple[str, str]] = [
        ("available", "true"),
        ("folder_name", _godot_string(folder)),
        ("id", _godot_string(level_id)),
    ]
    if legacy_result_key:
        values.append(("legacy_result_key", _godot_string(legacy_result_key)))
    values.append(("name", _godot_string(name)))
    if source_entry is not None and bool(
        source_entry.values.get("run_playback_enabled", False)
    ):
        values.append(("run_playback_enabled", "true"))
    values.append(
        (
            "tutorial",
            "true"
            if source_entry is not None and bool(source_entry.values.get("tutorial", False))
            else "false",
        )
    )
    body = ",\n".join(f'"{key}": {value}' for key, value in values)
    addition = f", {{\n{body}\n}}"
    updated = content[: closing_index + 1] + addition + content[closing_index + 1 :]
    mapping_path.write_text(updated, encoding="utf-8")


def _append_level_definition_entry(
    mapping_path: Path,
    content: str,
    folder: str,
    level_id: str,
    name: str,
    legacy_result_key: str | None,
    source_entry: MappingEntry | None,
) -> None:
    script_match = re.search(
        r'^\[ext_resource type="Script"[^\]]*path="res://levels/level_definition\.gd"'
        r'[^\]]*id="([^"]+)"\]$',
        content,
        re.MULTILINE,
    )
    if script_match is None:
        raise ValueError(f"Could not find the level-definition script in {mapping_path}")

    resource_marker = "\n[resource]\n"
    resource_index = content.find(resource_marker)
    if resource_index < 0:
        raise ValueError(f"Could not find the resource section in {mapping_path}")

    subresource_id = _unique_subresource_id(content, level_id)
    properties = [
        f'script = ExtResource("{script_match.group(1)}")',
        f"id = {_godot_string(level_id)}",
        f"display_name = {_godot_string(name)}",
        f"folder_name = {_godot_string(folder)}",
    ]
    if legacy_result_key:
        properties.append(f"legacy_result_key = {_godot_string(legacy_result_key)}")
    properties.append("available = true")
    if source_entry is not None and bool(source_entry.values.get("tutorial", False)):
        properties.append("tutorial = true")
    if source_entry is not None and not bool(
        source_entry.values.get("run_playback_enabled", True)
    ):
        properties.append("run_playback_enabled = false")

    block = (
        f'\n[sub_resource type="Resource" id="{subresource_id}"]\n'
        + "\n".join(properties)
        + "\n"
    )
    updated = content[:resource_index] + block + content[resource_index:]
    array_pattern = re.compile(
        r'(?m)^(level_entries = Array\[ExtResource\([^\]]+\)\]\(\[)(.*)(\]\))$'
    )
    array_match = array_pattern.search(updated)
    if array_match is None:
        raise ValueError(f"Could not find the typed level_entries array in {mapping_path}")
    separator = ", " if array_match.group(2).strip() else ""
    replacement = (
        array_match.group(1)
        + array_match.group(2)
        + separator
        + f'SubResource("{subresource_id}")'
        + array_match.group(3)
    )
    updated = updated[: array_match.start()] + replacement + updated[array_match.end() :]
    mapping_path.write_text(updated, encoding="utf-8")


def _unique_subresource_id(content: str, level_id: str) -> str:
    base = "Level_" + re.sub(r"[^A-Za-z0-9_]", "_", level_id)
    candidate = base
    suffix = 2
    while f'id="{candidate}"' in content:
        candidate = f"{base}_{suffix}"
        suffix += 1
    return candidate


def _validate_mapping_uniqueness(
    repository_root: Path,
    folder: str,
    level_id: str,
    name: str,
    legacy_result_key: str | None,
) -> None:
    entries = parse_mapping_entries(repository_root / MAPPING_RELATIVE_PATH)
    for entry in entries:
        if entry.folder.casefold() == folder.casefold():
            raise ValueError(f"Level folder is already mapped: {folder}")
        if entry.level_id.casefold() == level_id.casefold():
            raise ValueError(f"Level ID is already mapped: {level_id}")
        if entry.name.casefold() == name.casefold():
            raise ValueError(f"Level name is already mapped: {name}")
        if (
            legacy_result_key
            and str(entry.values.get("legacy_result_key", "")) == legacy_result_key
        ):
            raise ValueError(f"Legacy result key is already mapped: {legacy_result_key}")


def _find_external_references(
    repository_root: Path,
    source_folder: str,
    source_directory: Path,
) -> list[str]:
    needle = f"res://levels/{source_folder}/"
    references: list[str] = []
    for path in repository_root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        relative_parts = path.relative_to(repository_root).parts
        if any(part in IGNORED_SCAN_PARTS for part in relative_parts):
            continue
        if path == repository_root / MAPPING_RELATIVE_PATH:
            continue
        if path == source_directory or source_directory in path.parents:
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(content.splitlines(), start=1):
            if needle in line:
                references.append(f"{path.relative_to(repository_root)}:{line_number}")
    return sorted(references)


def _validate_folder(folder: str) -> None:
    if re.fullmatch(r"[a-z0-9][a-z0-9-]*", folder) is None:
        raise ValueError("--folder must contain lowercase letters, digits, and hyphens only.")


def _validate_level_id(level_id: str) -> None:
    if re.fullmatch(r"[a-z][a-z0-9_]*", level_id) is None:
        raise ValueError("--id must be snake_case and begin with a lowercase letter.")


def _godot_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _to_kebab_case(value: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", value)
    result = "-".join(word.casefold() for word in words)
    if not result:
        raise ValueError("Could not infer a folder from --name; pass --folder explicitly.")
    return result


def _to_snake_case(value: str) -> str:
    result = _to_kebab_case(value).replace("-", "_")
    return f"level_{result}" if result[0].isdigit() else result


def _to_pascal_case(value: str) -> str:
    return "".join(word[:1].upper() + word[1:] for word in re.findall(r"[A-Za-z0-9]+", value))


def _humanize(value: str) -> str:
    return " ".join(word.capitalize() for word in re.split(r"[-_]+", value) if word)


def _natural_sort_key(value: str) -> tuple[Any, ...]:
    return tuple(
        int(part) if part.isdigit() else part.casefold()
        for part in re.split(r"(\d+)", value)
    )


def _print_options(options: Sequence[LevelOption], as_json: bool) -> None:
    if as_json:
        print(json.dumps({"bases": [asdict(option) for option in options]}, indent=2))
        return
    for option in options:
        aliases = f" | aliases: {', '.join(option.aliases)}" if option.aliases else ""
        description = f" | {option.description}" if option.description else ""
        print(
            f"{option.key} | {option.name} | levels/{option.folder}"
            f"{aliases}{description}"
        )


def _print_result(result: dict[str, Any], as_json: bool) -> None:
    if as_json:
        print(json.dumps(result, indent=2))
        return
    verb = "Would create" if result["dry_run"] else "Created"
    print(f"{verb} {result['target']} as {result['level_name']} ({result['level_id']}).")
    if result["png_size"]:
        width, height = result["png_size"]
        print(f"level.png: {width}x{height}")
    if result["external_references"]:
        print("External source references to review:")
        for reference in result["external_references"]:
            print(f"  - {reference}")


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)
    try:
        repository_root = find_repository_root(arguments.repo)
        if arguments.list:
            _print_options(discover_level_options(repository_root), arguments.json)
            return 0
        if not arguments.name:
            parser.error("--name is required when --base is used.")
        png_size = parse_png_size(arguments.png_size)
        result = duplicate_level(
            repository_root,
            arguments.base,
            arguments.name,
            folder=arguments.folder,
            level_id=arguments.level_id,
            legacy_result_key=arguments.legacy_result_key,
            png_size=png_size,
            seed=arguments.seed,
            skip_mapping=arguments.skip_mapping,
            dry_run=arguments.dry_run,
        )
        _print_result(result, arguments.json)
        return 0
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
