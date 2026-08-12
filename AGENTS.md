# Codex Instructions

## Coding starndard.

- Always use named enums over values.
- Make sure that typing is either directly inferable or specified with 'as' keyword.
- Any exported variable has a human friendly comment to explain the intent of the setting.
- If settings are aiming to be contant for the whole game and not per instance then they should live in their own .tres file.
- Preserve and update comments, don't remove as a tidy up operation unless they are incorrect in which case update them. Comments can show important intent.
- Use PascalCase for Project Enumerations.


## Binary Files

- Never create, edit, regenerate, reimport, re-save, format, or otherwise modify binary files.
- Treat files such as `.res`, `.glb`, `.blend`, `.png`, `.jpg`, `.jpeg`, `.webp`, `.mp3`, `.wav`, `.imported`, and other non-text assets as read-only unless user specifically requests.
- Do not run commands that are expected to rewrite binary assets, including Godot import/reimport/save operations, unless the user explicitly approves that exact binary change first.
- If a fix appears to require changing a binary file, stop and explain the issue instead of modifying it. Prefer text-only fixes such as `.tscn`, `.gd`, `.tres`, `.import`, project settings, or source metadata.
- After any command that may have touched generated assets, check `git status --short` and revert any binary-file changes before continuing.
- You can use godot to create import files for added assets without request.

## Scripts or Nodes

- Favour nodes over script generated content so that editor users can work with the scene without having to read scripts whereever possible.
- When a model has attached behaviour always create a scene for that object so it can placed fully populated and working.

## Paths

- No absolute paths, the team members use different os's.

## Folder ownership

- `placeables/`: reusable, non-grid-aligned level objects without a dedicated root; group distinct behaviours such as treasure, collectibles, pushables, traps, and triggers in subfolders.
- `levels/`: level-specific scenes and data only; put theme-specific content in its level folder, such as `levels/graveyard/`.
- `lighting/`: reusable indoor and outdoor lighting rigs.
- `enemies/`: enemy scenes, behaviour, and enemy-specific resources.
- `player/`: player scenes, behaviour, and player-only settings.
- `ui/`: screens and HUD features; keep each substantial HUD feature in its own `ui/hud/` subfolder.
- `inventory/`: carried-item data, inventory systems, and key scenes and resources.
- `game/` and `autoload/`: runtime orchestration and truly global services respectively, not feature implementation.
- `Assets/`: art and audio grouped by implementation owner; mirror `placeables/` for runtime art, while preserving artist source workspaces and third-party packs.
- `addons/` and `tests/`: plugins and long-lived tests respectively.
- Keep a feature's scene, script, and resources together. Choose folders by what owns a file, not what consumes it.

## Project target
- Target Godot 4.7+ unless project.godot or CI says otherwise.
- Prefer current Godot 4.x APIs. Do not use Godot 3.x APIs.

## GDScript style
- Godot 4.7 only.
- Use statically typed GDScript.
- Use tabs for GDScript indentation, displayed at four columns.
- Prefer composition over deep inheritance.
- Keep scripts below 500 lines where practical.
- Keep functions small and single-purpose.
- Avoid string-based method and signal names.
- Use Resources for shared configuration.
- Do not duplicate tunable defaults across scene instances.
- Avoid autoloads unless state genuinely needs global lifetime.
- Do not use get_node() repeatedly inside process loops.
- Cache required node references with @onready.
- Avoid allocations in _process() and _physics_process().
- In tool scripts and property setters, guard `global_position` and `global_transform` access with `is_inside_tree()`; use local transforms while a node is off-tree.
- Use signals for loose communication, direct calls for ownership relationships.
- Make enemy state transitions explicit and testable.
- Keep gameplay logic deterministic where replays depend upon it.
- Never silently modify imported assets or generated scenes.
- Preserve editor usability for non-programmers.
- Explain any architecture change before applying it across the repository.

## GODOT Best Practices

Godot guidance is stored in docs/godot-best-practices.

Consult it only when relevant to the current task. Read the smallest number of
topic files needed. Treat the documentation as general guidance rather than
project-specific requirements. Prefer existing project conventions when they
deliberately differ.

## Code generation rules
- Preserve existing scene/resource paths.
- Do not hand-edit `.tscn`, `.tres`, `.import`, or `project.godot` unless the task requires it.
- When copying a text scene or resource to a new path, remove its root `uid` so the copy cannot share the source identity.
- Never invent or copy an `ext_resource` UID. Keep the stable `res://` path and omit a stale UID when the referenced resource has been regenerated.
- Prefer small, composable scenes and scripts over large inheritance trees.
- Use signals or typed dependencies for decoupling; avoid global singletons unless already established.
- Do not invent nodes, autoloads, input actions, groups, or resources without checking existing files first.
- Moving a file should use git mv to ensure that history is preserved.

## CHANGELOG.md 
- On every task update the changelog with the updates as bullet points describing the changes in terms of a player or as a level editor.

## Unit testing

- Whereever possible add long lived tests to protect existing functionality and prevent regressions.
- Place each production script's tests in a sibling `<script_name>_test.gd` file.
- Co-located tests must extend `res://tests/test_case.gd`, implement `run()`, and avoid `class_name`.
- Never reference, preload, or load `_test.gd` files from production scripts, scenes, resources, or autoloads.
- Keep shared test infrastructure in `tests/`; keep feature-specific test doubles in the owning sibling test.
- Every first-party production script requires a sibling test; the pairing check does not allow exemptions.
- Run one co-located suite with `godot --headless --path . --script res://tests/test_runner.gd --log-file scene_scan.log -- --test-file=<res://path_to_test.gd>`.

## Validation
Run the relevant checks after code changes:

```bash
./check.sh
```

The scene scan rejects duplicate root UIDs and stale `ext_resource` UIDs. Resolve those
failures in the text scene or resource that declares them; do not re-save or modify a
binary asset merely to make its old UID valid again.
