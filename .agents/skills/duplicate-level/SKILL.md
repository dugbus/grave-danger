---
name: duplicate-level
description: Discover, duplicate, and scaffold this Godot repository's level scenes with deterministic reference rewriting, level mapping updates, and optional PNG sizing. Use when Codex needs to list available base levels, copy an existing level into a new levels/ folder, create a procedural generated-level starting point, or repair the setup of a newly duplicated level.
---

# Duplicate Level

Run the bundled script from the repository root. Start by listing bases unless the user
already named an unambiguous level:

```bash
python3 .agents/skills/duplicate-level/scripts/duplicate_level.py --list
```

Use `--json` when the result will be consumed programmatically. The list includes mapped
level names and IDs, unmapped folders containing `level.tscn`, aliases that share a scene,
and the bundled `generated-template`.

Preview the operation before writing:

```bash
python3 .agents/skills/duplicate-level/scripts/duplicate_level.py \
  --base "Vampire Boss" \
  --name "Moonlit Crypt" \
  --dry-run
```

Then repeat without `--dry-run`. Folder and ID values are inferred from the new display
name; override them with `--folder` and `--id` only when repository conventions require
it. Use `--skip-mapping` only when the level must remain unavailable from level selection.

For a fresh procedural level, use the bundled scene template and set the exact PNG size:

```bash
python3 .agents/skills/duplicate-level/scripts/duplicate_level.py \
  --base generated-template \
  --name "Moonlit Crypt" \
  --png-size 64x48 \
  --seed 23
```

The script:

- copies source-owned files recursively while omitting generated `.import`, `.uid`, and
  editor metadata;
- removes stale resource UIDs and rewrites `res://levels/<source>/` paths in copied text;
- renames copied global GDScript `class_name` declarations and their local uses to avoid
  collisions with the source level;
- gives the copied root scene a human-friendly node name;
- creates or replaces `level.png` when `--png-size WIDTHxHEIGHT` is supplied;
- keeps generated-template maze dimensions and PNG-to-GridMap export dimensions aligned;
- appends a unique entry to `levels/level_mapping.tres`;
- reports external files that still mention the source level without redirecting them.

After creation, inspect the reported files and the new scene. Run `./check.sh`; if invoking
Godot changes imported or binary assets, follow the repository's binary-file policy.
