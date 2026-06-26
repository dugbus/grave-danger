# Codex Instructions

## Binary Files

- Never create, edit, regenerate, reimport, re-save, format, or otherwise modify binary files.
- Treat files such as `.res`, `.glb`, `.blend`, `.png`, `.jpg`, `.jpeg`, `.webp`, `.mp3`, `.wav`, `.imported`, and other non-text assets as read-only unless user specifically requests.
- Do not run commands that are expected to rewrite binary assets, including Godot import/reimport/save operations, unless the user explicitly approves that exact binary change first.
- If a fix appears to require changing a binary file, stop and explain the issue instead of modifying it. Prefer text-only fixes such as `.tscn`, `.gd`, `.tres`, `.import`, project settings, or source metadata.
- After any command that may have touched generated assets, check `git status --short` and revert any binary-file changes before continuing.
- You can use godot to create import files for added assets without request.

## Types

- Always use named enums over values.
- Make sure that typing is either directly inferable or specified with 'as' keyword.

## Scripts or Nodes

- Favour nodes over script generated content so that editor users can work with the scene without having to read scripts whereever possible.

## Paths

- No absolute paths, the team members use different os's.

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

## Unit testing

- Whereever possible add long lived tests to protect existing functionality and prevent regressions.

## Validation
Run the relevant checks after code changes:

```bash
godot --headless --editor --import --quit --path .
godot --headless --check-only --quit --path .
```