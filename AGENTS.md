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
- Follow the Godot 4.6 GDScript style guide.
- Use spaces, not tabs.
- Use snake_case for files, functions, variables, and signals.
- Use PascalCase for class_name and node names.
- Prefer `:=` when the type is clear from the right side; write explicit types when inference is ambiguous, especially `get_node()` results.
- Order scripts as: @tool/@icon, class_name, extends, doc comment, signals, enums, constants, exports, vars, @onready vars, lifecycle callbacks, public methods, private methods.

## Code generation rules
- Preserve existing scene/resource paths.
- Do not hand-edit `.tscn`, `.tres`, `.import`, or `project.godot` unless the task requires it.
- Prefer small, composable scenes and scripts over large inheritance trees.
- Use signals or typed dependencies for decoupling; avoid global singletons unless already established.
- Do not invent nodes, autoloads, input actions, groups, or resources without checking existing files first.
- Moving a file should use git mv to ensure that history is preserved.

## CHANGELOG.md 
- On every task update the changelog with the updates as bullet points describing the changes in terms of a player or as a level editor.

## Unit testing

- Whereever possible add long lived tests to protect existing functionality and prevent regressions.

## Validation
Run the relevant checks after code changes:

```bash
./check.sh
```
