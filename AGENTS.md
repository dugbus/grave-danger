# Codex Instructions

## Binary Files

- Never create, edit, regenerate, reimport, re-save, format, or otherwise modify binary files.
- Treat files such as `.res`, `.glb`, `.blend`, `.png`, `.jpg`, `.jpeg`, `.webp`, `.mp3`, `.wav`, `.imported`, and other non-text assets as read-only unless user specifically requests.
- Do not run commands that are expected to rewrite binary assets, including Godot import/reimport/save operations, unless the user explicitly approves that exact binary change first.
- If a fix appears to require changing a binary file, stop and explain the issue instead of modifying it. Prefer text-only fixes such as `.tscn`, `.gd`, `.tres`, `.import`, project settings, or source metadata.
- After any command that may have touched generated assets, check `git status --short` and revert any binary-file changes before continuing.

## Scripts or Nodes

- Favour nodes over script generated content so that editor users can work with the scene without having to read scripts whereever possible.

## Paths

- No absolute paths, the team members use different os's.

