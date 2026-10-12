---
name: format-gdscript
description: Format first-party Grave Danger GDScript after script edits, or check and normalize its formatting baseline using gdformat and the repository's tab-based style.
---

# Format GDScript

Run from the repository root. Development tools are pinned in `requirements-dev.txt`;
install them with `python3 -m pip install -r requirements-dev.txt` when missing.

After editing scripts, format only the `.gd` files changed by the current task,
including their tests:

```bash
./format.sh player/player_movement.gd player/player_movement_test.gd
./format.sh --check player/player_movement.gd player/player_movement_test.gd
```

`gdformatrc` uses tabs and the project's 120-character line limit. `.editorconfig`
displays tabs at four columns. Keep the formatter's default safety checks enabled;
they verify comment preservation, syntax-tree equivalence, and stable formatting.

Use `--diff` with the same paths to preview changes. A full baseline check is
`./format.sh --check --all` and also runs at the start of `./check.sh`.
Use `./format.sh --all` only when the task authorizes a repository-wide formatting
pass. The wrapper excludes generated directories and third-party addons, accepts
only `.gd` files, and never formats scenes, resources, shaders, or binary assets.

Inspect the diff and run `./check.sh` after formatting. Keep gameplay fixes separate
from formatting-only changes when practical. If formatting exposes a test that
matches source whitespace, replace that fragile assertion with a behavior assertion
or a whitespace-independent check while preserving what it protects.
