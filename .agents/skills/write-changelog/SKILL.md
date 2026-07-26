---
name: write-changelog
description: Write timestamped entries to this repository's CHANGELOG.md through the bundled deterministic script. Use whenever Codex completes or materially updates a task, when a user asks to add or revise changelog text, or when repository changes need a concise player-facing or level-editor-facing release note.
---

# Write Changelog

Inspect the relevant diff before writing an entry. Describe the observable outcome for a
player or level editor, not filenames, implementation steps, tests, or internal refactors.
Use one concise sentence per independently useful outcome.

Also summarize the user's originating request in one short clause. Paraphrase the request
instead of copying it verbatim, omit conversational detail, and never include secrets or
personal information.

Run the bundled script from the repository root for every entry:

```bash
python3 .agents/skills/write-changelog/scripts/add_changelog_entry.py \
  --prompt "Keep generated characters aligned after resizing the maze." \
  "The Vampire now returns to its rebuilt gate when the generated maze size changes."
```

The script owns all changelog structure and timestamps. Do not hand-edit date or hour
headings. It:

- Uses the caller's local time by default.
- Creates ISO date headings such as `## 2026-07-26`.
- Creates 24-hour bucket headings such as `### 1100`.
- Reuses an existing date/hour section and keeps newest sections first.
- Preserves a pre-existing unstructured changelog under `## Undated entries`.
- Stores the concise request beneath its outcome as an indented `Prompt` field.
- Updates a missing or changed prompt on an identical same-hour entry without duplicating it.

Use `--timezone Europe/London` only when the task requires a timezone other than the
machine's configured local timezone. Use `--at` only for deterministic tests or an
explicitly backdated entry:

```bash
python3 .agents/skills/write-changelog/scripts/add_changelog_entry.py \
  --at 2026-07-26T11:30:00+01:00 \
  --prompt "Make generated layouts editable after choosing one." \
  "Level editors can freeze generated maze content into repositionable scene nodes."
```

After running the script, inspect the top of `CHANGELOG.md` and include it in the task's
normal validation and diff review.
