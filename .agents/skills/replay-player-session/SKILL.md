---
name: replay-player-session
description: Ask a user to perform a focused in-game test, inspect committed or local player feedback reports, archive corrected reports into the changelog, launch the requested level only after explicit readiness confirmation, and replay recorded player sessions with selectable command-line JSONL logging. Use when Codex needs human gameplay evidence, wants a player to reproduce or verify behavior, is told there is new feedback, needs to resolve or archive a feedback report, needs to inspect the last run, or needs feedback, position, input, camera, button, metadata, or drift logs from an existing replay.
---

# Replay Player Session

Use the bundled script from the repository root.

## Directed playtest handshake

Form one short, observable instruction and name the level when known. Ask the user whether
they are ready to begin, then stop and wait for their response. Never launch the game in
the same turn as the readiness question; the user may be away from their computer.

After the user explicitly says they are ready, launch with the required confirmation flag:

```bash
python3 .agents/skills/replay-player-session/scripts/player_session.py \
  request-test \
  --confirmed \
  --level vampire_boss \
  --instruction "Walk through the exit gate, then return and report whether the boundary hurts you."
```

The launcher refuses to start without `--confirmed`. The game opens the requested level,
shows the instruction in a persistent HUD panel, records the run normally, and stores the
instruction in its replay metadata. Tell the user to complete the request and finish the
run or close the game.

## Inspect recordings

List saved recordings newest first:

```bash
python3 .agents/skills/replay-player-session/scripts/player_session.py recordings
```

Replay the newest session headlessly and emit selected JSONL channels:

```bash
python3 .agents/skills/replay-player-session/scripts/player_session.py replay \
  --level latest \
  --logs summary,metadata,position,input,buttons \
  --sample-seconds 0.25
```

Available channels are `summary`, `metadata`, `position`, `input`, `camera`, `buttons`,
and `drift`; use `all` or `none` when appropriate. Prefer the smallest useful set. Use
`--output <path>` for a persistent JSONL artifact. Before using `--visual`, perform the
same ask-and-wait handshake and then pass `--confirmed`; this plays the recorded poses and
camera in a game window. `--speed` controls visual playback speed only.

## Player feedback markers

The feedback control exists in every ordinary and Codex-directed gameplay run. By default,
Square/left-face immediately marks the current moment, pauses through the gameplay pause
screen, and opens a centered optional multiline note area. Proceed attaches the note and
Cancel dismisses it; both buttons support joypad focus and resume a run that was not
already paused. Escape or pressing Square again also cancels the form. The press is
release-gated and debounced.
A directed test may configure these with
`request-test --report-button BUTTON --text-button BUTTON`, using `triangle`, `cross`,
`square`, `circle`, or `disabled`.

Each marker creates `feedback/reports/<report-id>.json`, a text `.tscn` snapshot of the
played level, and, after its short follow-up window, a matching Git LFS-backed `.gdr`
playback. These files are intended to be committed and pushed together by the level
designer. The report records the exact marker time, level, optional note, diagnostic
snapshot, level snapshot status, and playback status.

When the user returns to Codex and says `new feedback`, inspect only the newest marker and
its nearby input and position window:

```bash
python3 .agents/skills/replay-player-session/scripts/player_session.py reports

python3 .agents/skills/replay-player-session/scripts/player_session.py feedback \
  --report latest \
  --logs summary,metadata,feedback,position,input,buttons \
  --before 2 \
  --after 3 \
  --sample-seconds 0.25
```

Pass `--report <report-id>` when several committed reports exist. The command prefers the
repository report, includes its focused runtime snapshot, and avoids emitting the full
recording. A small live sidecar makes a just-created marker and nearby samples available
while the game is still running, so the player may return to Codex immediately. Add
`camera` or `drift` only when the reported behavior needs it. If no marker is found, ask
the player to press the configured report button during a run.

Before using `feedback --visual`, perform the same ask-and-wait handshake and then pass
`--confirmed`; visual feedback playback prefers the report's level snapshot so later
local level edits do not change the recorded context.

## Resolve and archive feedback

After implementing and verifying a fix, archive the report with one concise, observable
fix sentence:

```bash
python3 .agents/skills/replay-player-session/scripts/player_session.py \
  archive-feedback \
  --report 20260726T150000Z-vampire_boss \
  --fix "The Vampire now rebuilds its route after colliding with a coffin."
```

This changes the report status to resolved, stores the fix in its JSON, moves the JSON,
level snapshot, and playback to `feedback/archive/<date>/`, and calls the repository
changelog script with the report ID, marker time, level, fix, and archived playback path.
Inspect the resulting changelog entry and include the archive move in the fix commit.

The working repository retains at most 20 active and archived reports using 25 MiB of
playback data, with a 5 MiB ceiling per playback. Resolved reports are pruned oldest-first;
open reports are never silently removed. Playback files are tracked by Git LFS to avoid
growing ordinary Git objects.

Use `--dry-run` to inspect either Godot command without launching it. Summarize evidence
from the replay logs for the user, separating directly observed facts from inference.
