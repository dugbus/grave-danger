#!/usr/bin/env python3
"""Require an immediately preceding, non-empty ## comment for @export* annotations."""

import argparse
import re
from pathlib import Path

# Match strings before comments so annotation-like text in either is ignored.
NON_CODE = re.compile(
    r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|#[^\n]*'
)
EXPORT = re.compile(r"@export(?:_[A-Za-z0-9_]+)?\b")
EXCLUDED_DIRECTORIES = {"addons", "tests"}


def undocumented_exports(source: str) -> list[tuple[int, str]]:
    """Return annotation lines and names whose preceding line lacks documentation."""
    documentation_lines: set[int] = set()
    for match in NON_CODE.finditer(source):
        if match.group().startswith("##") and match.group()[2:].strip():
            line_start = source.rfind("\n", 0, match.start()) + 1
            if not source[line_start:match.start()].strip():
                documentation_lines.add(source.count("\n", 0, match.start()) + 1)
    code = NON_CODE.sub(lambda match: re.sub(r"[^\n]", " ", match.group()), source)
    violations = []
    for match in EXPORT.finditer(code):
        line = code.count("\n", 0, match.start()) + 1
        if line - 1 not in documentation_lines:
            violations.append((line, match.group()))
    return violations


def script_paths(root: Path):
    """Scan first-party scripts using the same exclusions as gdlint."""
    for path in sorted(root.rglob("*.gd")):
        if not any(
            part.startswith(".") or part in EXCLUDED_DIRECTORIES
            for part in path.relative_to(root).parts[:-1]
        ):
            yield path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=Path("."))
    args = parser.parse_args()
    count = 0
    violations = 0
    for path in script_paths(args.root):
        count += 1
        for line, annotation in undocumented_exports(path.read_text(encoding="utf-8")):
            print(
                f"{path.relative_to(args.root)}:{line}: {annotation} requires an "
                "immediately preceding, non-empty ## documentation comment."
            )
            violations += 1
    print(f"Checked export documentation in {count} scripts; {violations} violations.")
    return 1 if violations else 0


if __name__ == "__main__":
    raise SystemExit(main())
