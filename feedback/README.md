# Player Feedback Reports

Press Triangle during gameplay to create a report in `feedback/reports/`. Each open report
contains readable JSON metadata and a matching `.gdr` playback captured through the marked
moment and its short follow-up window.

Commit both files so another developer or Codex thread can inspect the same evidence.
Playback files use Git LFS. The game and archive command retain at most 20 reports using
25 MiB in total, with a 5 MiB limit for one playback. Open reports are never silently
pruned; resolved archive entries are removed oldest-first when space is needed.

After correcting a report, use the replay-player-session skill's `archive-feedback`
command. It records the fix and report identity in `CHANGELOG.md`, moves the evidence to
`feedback/archive/<date>/`, and reapplies the retention limit.
