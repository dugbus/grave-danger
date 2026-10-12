#!/usr/bin/env python3
"""Format explicit GDScript files, or check the first-party repository baseline."""

import argparse
from pathlib import Path
import shutil
import subprocess


REPOSITORY_ROOT = Path(__file__).resolve().parents[4]
EXCLUDED_DIRECTORIES = {".git", ".godot", "addons"}


def script_path(value: str) -> Path:
    path = (REPOSITORY_ROOT / value).resolve()
    if not path.is_relative_to(REPOSITORY_ROOT):
        raise ValueError(f"Script must be inside the repository: {value}")
    relative = path.relative_to(REPOSITORY_ROOT)
    if any(part in EXCLUDED_DIRECTORIES for part in relative.parts):
        raise ValueError(f"Generated or third-party scripts are excluded: {value}")
    if path.suffix != ".gd" or not path.is_file():
        raise ValueError(f"Expected an existing .gd script file: {value}")
    return relative


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Check without changing files")
    mode.add_argument("--diff", action="store_true", help="Preview without changing files")
    parser.add_argument("--all", action="store_true", help="Select every first-party .gd file")
    parser.add_argument("scripts", nargs="*", help="Repository-relative .gd paths")
    args = parser.parse_args()
    if args.all == bool(args.scripts):
        parser.error("Choose explicit script paths or --all")
    try:
        if args.all:
            # git supplies tracked and untracked source files without walking generated caches.
            result = subprocess.run(
                ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                cwd=REPOSITORY_ROOT, check=True, capture_output=True,
            )
            values = sorted(set(result.stdout.decode().split("\0")) - {""})
            scripts = [
                script_path(value) for value in values
                if value.endswith(".gd")
                and not any(part in EXCLUDED_DIRECTORIES for part in Path(value).parts)
                and (REPOSITORY_ROOT / value).is_file()
            ]
        else:
            # Validate the entire selection before allowing the formatter to write anything.
            scripts = list(dict.fromkeys(script_path(value) for value in args.scripts))
    except (ValueError, subprocess.CalledProcessError) as error:
        parser.error(str(error))
    formatter = shutil.which("gdformat")
    if formatter is None:
        parser.error("Install development tools: python3 -m pip install -r requirements-dev.txt")
    if not scripts:
        print("No first-party GDScript files selected.")
        return 0
    command = [formatter]
    if args.check:
        command.append("--check")
    elif args.diff:
        command.append("--diff")
    command.extend("./" + path.as_posix() for path in scripts)
    return subprocess.run(command, cwd=REPOSITORY_ROOT, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
