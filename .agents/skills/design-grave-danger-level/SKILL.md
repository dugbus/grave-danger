---
name: design-grave-danger-level
description: Design and refine authored Grave Danger levels using deliberate progression, staged boundary pressure, varied encounters, editable visual dressing, and replay-backed validation. Use for new levels or substantial layout, encounter, or aesthetic changes in this repository.
---

# Design Grave Danger Level

Build a level around an observable player journey, not an inventory of available placeables.
Use existing scenes and resources as vocabulary, while keeping the route and encounter structure
original.

Before changing a level, read [references/level-design-lessons.md](references/level-design-lessons.md).
That file contains playtest- and editor-backed project lessons and is intended to evolve as new evidence arrives.

## Establish the route

State the level's route in one sentence before placing content. Identify:

- where the player starts and exits;
- which objectives must be completed in order;
- where pressure changes the player's direction or priorities;
- which optional branches reward risk without blocking completion.

Prefer authored GridMap structure when room shape, sight lines, or chokepoints carry the design.
Procedural connectivity is not evidence of a compelling route.

Embed every locked door or gate in a continuous collision barrier. Verify the neighboring GridMap
cells close every bypass, and test progression with each later lock treated as blocked. A complete
route must make each required key reachable only at its intended stage and leave every counted
treasure item and deposit point reachable before the exit.

## Author pressure as a sequence

Treat a moving kill boundary as level choreography. Author poses around the current objective:

- a contraction creates a readable deadline;
- if an expansion opens the next district, it must accommodate early arrivals rather than
  forcing them to wait for a fixed schedule;
- the following contraction removes the previous district and leads forward;
- the final phase drives the player toward the exit.

Do not rely on one slow whole-map pulse. Check that each phase actually contains its intended key,
treasure, doorway, and safe approach. Use enough perimeter segments and rounding for the authored
scale, and test transition times and pose coverage rather than only matching scene text.
When expansion gates cause waiting, consider keeping forward ground safe and using authored
trailing contractions, accelerated by progression events. Keep that orchestration local to the
level, smooth, deterministic, and compatible with pause effects. Test fast escape and slower
full-collection routes; a single safe timeline does not establish good pacing.

## Compose encounters

Give adjacent districts different gameplay verbs. Combine patrols, pursuit enemies, ambushes,
timed floor hazards, movable obstacles, destructible shortcuts, and resource decisions according to
the route. Avoid repeating the same paired trap beside every doorway.

Configure open skeleton paths to reverse at their endpoints. For physics hazards, require visible
speed and travel-direction alignment before they kill; side contacts and tiny settling motion must
remain safe.

Use ordinary coins for routine rewards. Place gems or gold bars only as intentional rare rewards
whose difficulty and presentation justify their value. Avoid introductory text that explains a
route the environment can teach through walls, locks, light, and pressure.

## Dress the level for play and editing

Use the reference's floor, road and grass vocabulary without copying its composition. Follow the
floor construction and painted-grass guidance in the lessons: make floor tiles directly editable
from the main scene, compose paving and foliage selectively, and leave hazards and rewards readable.
Preserve a validated route during an art pass. Check editor ownership and actual navigation-grid
discovery as well as rendering; a second GridMap can change enemy routing without moving any walls.

## Validate and learn

Add a sibling level test that checks the actual scene and GridMap. Cover staged reachability,
sealed chokepoints, objective placement, enemy route cells, boundary phase timing and coverage,
and level-specific economy rules. Run focused suites before `./check.sh` and distinguish new
failures from existing repository failures.

When human play evidence is useful, use the repository's `replay-player-session` skill. Compare
player feedback with the smallest relevant replay channels, clearly separate observation from
inference, and fix the underlying rule when the behavior can recur outside one placement.

After playtesting or editor feedback reveals a reusable lesson, update the reference with the decision-changing rule
and its evidence. Keep one-off coordinates and temporary tuning values in the level, not the skill.
