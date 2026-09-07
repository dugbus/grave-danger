# Floor Surface Implementation Plan

Based on [FLOOR SURFACE DESIGN.md](FLOOR%20SURFACE%20DESIGN.md). This plan covers the **standalone prototype only**. M1, M2 and M3 are accepted; M4 is being revised after its first human trial, and later milestones remain unimplemented.

The aim is to deliver small, usable increments that a human can edit and play before the next dependent part is built. Existing Grave Danger levels and floor implementations remain outside this work. Integration requires a separate plan after prototype acceptance.

## How to use this checklist

- Tick individual tasks when their work or verification is complete. Tick a milestone below only after its automated checks and human trial pass and any requested changes have been resolved and retried.
- At each checkpoint, record the tested revision, settings, observations and decision in the review log. A working build awaiting a human trial remains incomplete.
- Treat each milestone as a review boundary. Continue independent preparation if useful, but settle feedback before building work that depends on the disputed behaviour.
- Keep tuning in shared text `.tres` resources. Change settings and repeat the same trial before changing architecture. Reopen affected checklist items when a later change invalidates earlier evidence.
- Keep the playground's named test areas and reset positions stable so trials are repeatable. Add cases as functionality arrives; do not rebuild the whole playground each milestone.
- Before requesting an in-game trial or launching a scene, follow the repository's `replay-player-session` skill, including its readiness requirement. Use manual observations where standalone replay support is unavailable; adding production replay dependencies is not a prerequisite.

## Progress

- [x] M1 — Isolated playground and controllable test player.
- [x] M2 — Authoritative map, flat floor generation and sampling.
- [x] M3 — Viewport shape painting and reliable undo.
- [ ] M4 — Absolute elevation, ledges and traversal tuning.
- [ ] M5 — Styles, exposed depth and pits.
- [ ] M6 — Explicit ramps and transition authoring.
- [ ] M7 — Early player visibility experiment and rendering decision.
- [ ] M8 — Grounded objects and conform operation.
- [ ] M9 — Complete authoring workflow, validation and rebuild behaviour.
- [ ] M10 — Stepped-pyramid and final 2.5D visibility acceptance.

Sequence: M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → M10. M8 can be prepared after M6 independently of the visibility experiment. If raised geometry already hides the player at M4, bring the M7 experiment forward using that fixture.

## Implementation boundaries and proposed architecture

The project currently targets Godot 4.7 with Forward Plus. Reuse the existing `move_left`, `move_right`, `move_up`, `move_down` and `jump` actions for the standalone controller. Inspect existing code for conventions without depending on the production floor builder or player controller.

Use `addons/floor_surface/` as the owner of this reusable toolset, with runtime scenes/scripts/resources together, `editor/` for the plugin and dock scene, `shaders/` for text shaders, and `test/` for the playground, test player and placement fixtures. This adapts the design's suggested folder to the repository's plugin ownership rule. Proposed playground path: `res://addons/floor_surface/test/floor_surface_playground.tscn`.

Every new production script, including editor and playground behaviour, must have a sibling `<script_name>_test.gd`. Avoid naming a production playground controller with the `_test.gd` suffix. Tests extend `res://tests/test_case.gd`, implement its `run()` contract and omit `class_name`. Production content must never load these suites.

| Component | Responsibility |
| --- | --- |
| `FloorMap` resource | Finite X/Z bounds, cell occupancy, integer absolute elevation, stable palette index and named transition/orientation data; deterministic text serialization. |
| `FloorElevationProfile` resource | Shared elevation unit and local delta classifications, with validation against the standalone controller's supported step, jump and slope limits. |
| `FloorStyle` resource | Independent top, edge and pit-bottom materials and pit depth; missing resources produce actionable validation. |
| `FloorSurface` scene | Owns the map and palette, exposes the surface API, coordinates rebuilds and emits typed change notifications. No new autoload. |
| Geometry builder | Derives batched top/edge/ramp/pit meshes and static collision from a shared surface description. Start with a full deterministic rebuild; introduce chunk invalidation when measured or needed. |
| Surface sampler | Returns a typed result containing validity, world height, normal, cell, style and transition; shares ramp mathematics with generation. |
| Editor plugin | Selects a FloorSurface, paints in the 3D viewport and provides a dock, overlays, validation and stroke-level undo/redo. |
| Grounding component/scene | Holds a typed surface reference, grounding mode and explicit placement offset; works on visible, editable scene objects. |
| Visibility controller and shaders | Consume derived elevation/occupancy data and camera/player inputs; fade obstructing fragments while preserving the surrounding structure. |
| Playground scene | Own camera, light, CharacterBody3D player, debug UI, reset points and editable sample objects. |

Generated mesh and collision nodes are derived output; authoring lives in map/style resources and ordinary placement nodes. Do not create a node for every face. Keep helper scripts small, typed and composable, and document exported settings in human terms. Use named PascalCase enums rather than numeric mode values.

Only text assets are planned: `.gd`, `.tscn`, `.tres`, `.gdshader` and plugin configuration. Use primitive meshes and procedural grid/checker shaders for initial samples. Read existing binary art only if useful; do not create or rewrite binary assets or bake generated geometry/textures to disk. The elevation texture is transient GPU data regenerated from the map. Any later binary asset change needs the specific authorization required by `AGENTS.md`.

The only anticipated shared configuration edit is registering the new editor plugin, when needed. Keep the main scene, production input bindings, existing floor tools and existing levels unchanged.

## M1 — Isolated playground and test player

**Deliverable:** A small scene that can be run directly, with enough movement and camera control to evaluate later floor changes.

- [x] Create the toolset skeleton and an editor-authored playground with its own camera, lighting, primitive player, temporary flat collision pad and labelled reset point.
- [x] Add deterministic movement, jump, fall/reset and visible control instructions. Put movement, jump, step and slope tuning in a shared test-controller resource.
- [x] Match the broad fixed 2.5D camera arrangement using independent settings. Provide named alternate views for later occlusion trials without changing production cameras.
- [x] Add lightweight debug UI with unavailable floor fields clearly marked until M2; show controller settings and test revision/fixture identity where practical.
- [x] Automated checks: controller reset and movement state, safe scene construction/teardown and script pairing; run the relevant suite and repository checks. M1's focused checks pass; unrelated repository failures are recorded below for later resolution.
- [x] Human trial: run the scene, move in every direction, jump, fall off the pad and reset. Confirm the camera and controls are comfortable enough to judge later geometry.
- [x] Review: record camera, speed and jump changes; rerun the trial and accept the harness.

## M2 — Authoritative map, flat geometry and surface API

**Deliverable:** A small saved floor map with a hole; visible geometry, collision and queries agree.

- [x] Implement map/profile/style resources and typed sample results. Store integer absolute elevations, never free-form per-cell heights.
- [x] Set the coordinate contract: grid aligned to world X/Z, configurable cell size and X/Z origin, and absolute `world_y = elevation * elevation_unit`. Initially warn on root Y offsets, rotation or scale that would violate that contract.
- [x] Define deterministic boundary ownership, negative-coordinate handling, out-of-bounds sampling and palette-index validation. Keep style assignment available on absent in-bounds cells for later pit appearance; outside bounds has no implicit pit bottom.
- [x] Generate batched flat tops and matching static collision from the map, replacing the temporary pad. Repeated rebuilds replace derived output without duplication.
- [x] Expose `has_floor`, `get_cell_elevation`, `get_world_height_at_cell` and `sample_surface`; document invalid-cell results and route consumers through this API.
- [x] Populate debug UI with cell, sampled height, absolute unit, normal and transition. Show no valid surface over holes rather than assuming Y=0.
- [x] Automated checks: text save/reload, absent and out-of-bounds cells, grid boundaries, negative cells, origin/cell-size changes, repeated rebuilds and flat query/collision agreement. M2's focused checks pass; unrelated repository failures remain recorded below.
- [x] Human trial: walk across several cell seams and into the hole, reset, then reload the scene. Confirm no invisible bridge remains over the hole and the saved layout and debug samples agree.
- [x] Retry acceptance: confirm the unshaded high-contrast checker floor is clearly visible in the runtime and editor after the first trial rendered its surface black.
- [x] Review: settle cell size and coordinate expectations before painting tools depend on them.

## M3 — Viewport shape painting and undo

**Deliverable:** Floor occupancy can be authored without editing individual cell properties.

- [x] Add a dedicated Floor Surface mode and dock, with target selection, hover preview, floor paint, erase, brush size and rectangle fill.
- [x] Support painting onto empty space using a grid/working-plane fallback; picking must not depend exclusively on existing floor collision.
- [x] Use one undo/redo action per complete stroke or rectangle, including a stroke crossing itself. Cancellation leaves the map unchanged.
- [x] Save authored resources reliably; make it clear whether a map is shared and provide an explicit unique-copy workflow before independent edits.
- [x] Automated checks: brush and rectangle footprints, automatic storage expansion/compaction, stroke aggregation, cancellation, undo/redo round trips and independence of unique map copies. M3's focused suites, editor startup, scene/UID scan, test pairing and lint pass; the full repository check still stops on the pre-existing Tutorial 3 kill-boundary test mismatch recorded below.
- [x] Human trial: paint a room, erase a central hole, widen a passage, undo and redo each action, then save/reopen. Confirm one undo reverses one gesture and viewport navigation still works.
- [x] Retry acceptance: paint beyond the previous edge, find the explicit Rectangle control, verify the independent-copy explanation, and confirm the transform gizmo hides during painting and returns afterward.
- [x] Review: adjust brush feedback and controls before extending the same gestures to elevation and style.

## M4 — Absolute elevation, ledges and traversal

**Deliverable:** Quickly authored raised regions with consistent local step/jump behaviour.

- [x] Add absolute elevation entry, raise/lower by one unit, cursor sampling, brush and rectangle operations. Display both units and metres, including `24 — 6.00m` with the provisional 0.25m unit.
- [x] Add a temporary muted elevation overlay and hovered-cell height labels independent of material and lighting. Keep the overlay low-luminance and translucent so it does not replace the authored floor detail.
- [x] Generate tops and exposed vertical ledges from neighbour height differences, holes and outer boundaries, omitting internal faces at matching heights. Define consistent edge ownership to avoid duplicates.
- [x] Implement profile classifications for flat, walkable step, normal jump, unencumbered-only jump and blocked ledge. Keep upward traversal and downward/drop behaviour explicit; do not classify using absolute height alone.
- [x] Build matching comparison lanes near Y=0 and at a higher absolute elevation. Tune physical step/jump behaviour against their local deltas; labels alone do not enforce traversal.
- [x] Provide a simple normal/unencumbered test mode to exercise the reserved threshold without importing inventory mechanics. Keep all initial thresholds provisional.
- [x] Automated checks: quantisation, negative and tall elevations, identical local classifications at different absolute heights, threshold boundaries, ledge collision and undo of elevation changes. Fifteen focused suites pass 300 assertions, including physical traversal on both comparison bands, hole and perimeter walls, and low-glare overlay limits; editor startup, scene/UID scanning, test pairing and focused lint pass. The full repository check retains the pre-existing Tutorial 3 kill-boundary mismatch recorded below.
- [ ] Human trial: directly set a platform to 24 units, then traverse both comparison lanes. Walk the small step, jump the normal ledge, compare the two movement modes and attempt the blocked ledge.
- [ ] Review: record the elevation unit, thresholds and controller settings together; retest both lanes after tuning.

## M5 — Styles, exposed depth and pits

**Deliverable:** Geometry can look like different surfaces, and holes have readable sides and configurable visible bottoms.

- [ ] Supply at least two reusable text-material styles with independently configurable top, edge and pit-bottom appearance and depth.
- [ ] Add style brush, rectangle and sample tools using M3's undo model. Preserve topology and collision when changing material alone.
- [ ] Implement continuous world X/Z projection on tops and world/triplanar projection on exposed sides. Define how the supported materials receive shared projection settings without modifying source materials silently.
- [ ] Define pit depth relative to a documented rim datum for each connected hole region, including mixed rim elevations and style depths. Agree the rule in this checkpoint; ensure generated sides meet bottoms without cracks.
- [ ] Generate optional pit bottoms only within authored bounds. Treat them as visual-only in the prototype: surface queries remain invalid in holes and the player falls/resets. Keep this choice explicit for later review.
- [ ] Automated checks: edge ownership at holes and lower neighbours, material grouping, depth changes, missing-style warnings, no walkable collision over holes and style undo.
- [ ] Human trial: paint stone next to dirt, inspect a projected checker across cell boundaries, change pit depth and edge material, and walk/fall around the pit. Check texture scale on tall walls and seams at mixed-height rims.
- [ ] Review: accept the pit datum and appearance controls; resolve visible cracks or inconsistent depth before ramps add more edge shapes.

## M6 — Explicit ramps and transition authoring

**Deliverable:** Paintable ramps connect local elevation bands, with matching rendering, collision and samples.

- [ ] Implement named flat/ramp transition and low-edge orientation data; reserve extensibility without implementing stairs, ladders or special drops.
- [ ] Infer low/high endpoints from neighbouring cells. Define the permitted band delta in shared settings and reject ambiguous or unsupported connections visibly rather than guessing silently.
- [ ] Generate ramp tops, collision and triangular/trapezoidal exposed sides from one shared surface description. Sample interpolated height and normal across the full ramp.
- [ ] Add a boundary-drag transition tool with inferred orientation, clear preview and a correction control for ambiguous intent. Ramp deletion restores the authored ledge/top behaviour through undoable edits.
- [ ] Support a sequence of simple ramps and landings across several terraces. Automatic multi-terrace route dragging is optional; individually painting connected ramps must work.
- [ ] Build a simple ramp and a short multi-terrace route with untouched blocked edges alongside them. Check slope limits using both rise and cell run.
- [ ] Automated checks: all four orientations, endpoint/midpoint samples, normals, side geometry, hole neighbours, invalid endpoints, adjacent seams and physics/query agreement.
- [ ] Human trial: paint a connection, walk up/down and across its edges, jump onto it and try neighbouring unpainted ledges. Edit a neighbour to invalidate it, inspect the warning, repair it, then undo/redo.
- [ ] Review: tune transition gestures and slope limits; retain a reliable short ramp route for later regression trials.

## M7 — Early player visibility experiment

**Deliverable:** Evidence for a rendering approach before applying the final fade across all floor styles.

- [ ] Derive world-aligned GPU-readable elevation and occupancy data from FloorMap, with ramp orientation/endpoints or equivalent data sufficient to represent slopes. Refresh on relevant edits, not every frame for static terrain.
- [ ] Add a 1m platform, taller terrace and ramp obstruction fixture, plus debug player position, sample data, fade reason and an elevation-data preview.
- [ ] Compare a fragment-depth/screen-space soft-mask approach with an elevation-guided obstruction mask or equivalent ray-based approach. Evaluate the actual Forward Plus output; do not commit to a shader technique solely from the specification.
- [ ] Evaluate false fades, ramp accuracy, transparency sorting, shadow behaviour, overlapping top/edge materials and frame cost. Reject whole-object hiding as the final solution.
- [ ] Implement the selected experiment with configurable radius, soft edge, fade amount and smooth restoration, using camera/player depth to distinguish obstruction from geometry behind the player.
- [ ] Automated checks: elevation/occupancy encoding, edit invalidation, no static per-frame rebuild and CPU-side obstruction math where applicable. Shader appearance remains a rendered human check.
- [ ] Human trial: repeatedly walk behind and in front of the platform, pause under overlap, ascend the ramp, switch named camera views and disable the effect for comparison. Confirm nearby non-obstructing terrain stays opaque.
- [ ] Review: record the chosen method, rejected alternatives, material requirements, measured cost and remaining visual defects. Rework the approach if it cannot preserve player readability and structure shape.

## M8 — Grounded test objects

**Deliverable:** Editable sample objects follow changed floor heights without losing deliberate offsets.

- [ ] Create a reusable grounding scene/component with named upright, align-normal and absolute modes and a typed surface dependency; no production GridMap integration.
- [ ] Define offset space and preserve authored heading/offset during initial grounding and repeated conform operations. Guard off-tree transform access in editor tooling.
- [ ] Add upright scenery and slope-aligned rubble/decal substitutes as ordinary editable playground nodes, plus an absolute-height control object.
- [ ] Add explicit **Conform Grounded Objects** with one undoable operation. Mark affected objects stale after floor changes and warn on absent floor; never silently move invalid placements to Y=0.
- [ ] Automated checks: flat/ramp placement, orientation, offset preservation, repeated-conform stability, absolute-mode preservation, missing floor and undo.
- [ ] Human trial: move samples onto a ramp, raise the supporting floor and run Conform. Check upright versus aligned orientation, explicit offsets and the unchanged absolute object; erase supporting floor and inspect the warning.
- [ ] Review: settle whether explicit conform plus a stale-placement warning is sufficient or automatic updates are desired; implement and retry any agreed adjustment.

## M9 — Complete authoring workflow and rebuild validation

**Deliverable:** A designer can author and revise a substantial surface efficiently and recover from invalid edits.

- [ ] Add bounded flood fill for shape, elevation and style. Document each fill's matching rule and preview the affected region; ensure absent-cell fills cannot escape map bounds.
- [ ] Complete shared brush/rectangle/fill/sample behaviour, elevation overlay, selection readouts and direct absolute-height entry. One full gesture remains one undo action.
- [ ] Add visible diagnostics and safe repair actions for invalid ramps, unsupported slopes, grounded objects over holes, stale grounding, missing styles/materials and unsupported transforms.
- [ ] Rebuild all affected neighbours when topology changes, including ramp sides, pit regions, sampling data and visibility data. Undo/redo must restore derived behaviour as well as the authored map.
- [ ] Measure the agreed playground and pyramid map sizes. Batch by material and chunk where useful; invalidate affected chunks and borders correctly if chunking is introduced. Record map size, timings and agreed responsiveness target before declaring performance acceptable.
- [ ] Confirm save/reopen, plugin disable/enable and multiple surface instances do not duplicate derived output or accidentally share mutable per-surface state.
- [ ] Automated checks: bounded fill, validation/repair round trips, dirty-neighbour coverage, multi-instance isolation, serialization and complete edit/undo/redo/rebuild sequences.
- [ ] Human trial: build nested terraces with rectangles and direct elevation entry, paint a path, fill a style region, erase a pit and repair an invalid ramp. Undo/redo the sequence and reopen the scene.
- [ ] Review: fix workflow friction before acceptance. A dedicated terrace/inset tool is optional only if rectangle/fill authoring proves too slow; it is not required to finish the prototype.

## M10 — Stepped-pyramid and final visibility acceptance

**Deliverable:** The full standalone playground passes the required design cases after human iteration.

- [ ] Author an approximately 6m pyramid using quantised absolute terrace elevations, with a one-cell-wide ramp route on each of four sides. Choose terrace rise, cell run and controller thresholds together so ramps are walkable and unpainted terrace boundaries are blocked.
- [ ] Verify every route reaches the summit continuously through locally valid ramps/landings. Compare equal local deltas near the base and summit; absolute height must not change their classification.
- [ ] Complete the selected visibility effect across raised tops, vertical faces, ramp tops and ramp sides for both sample styles; restore full opacity when obstruction ends.
- [ ] Retain every playground case: flat ground, styled pit, walkable step, normal jump, reserved unencumbered jump, blocked ledge, simple ramp, grounded objects and pyramid.
- [ ] Automated checks: pyramid connectivity and permitted route transitions, non-route ledge classification, high-elevation samples, ramp collision continuity, rebuild determinism and all prior regression suites.
- [ ] Human trial A — Authoring: recreate or substantially reshape nested terraces using viewport tools, directly enter the summit height, adjust routes/styles and exercise undo/redo without per-cell Inspector editing.
- [ ] Human trial B — Movement: ascend/descend all four routes, attempt unpainted terrace shortcuts, jump near ramp joins, fall into the pit and reset. Repeat the step/jump lanes in both controller modes.
- [ ] Human trial C — Visibility: walk behind the 1m platform, progressively taller terraces and the 6m pyramid from several sides; walk up overlapping ramps and repeatedly enter/leave obstruction. Check flicker, popping, sorting, shadows and unwanted fading of unobstructing geometry.
- [ ] Human trial D — Placement and persistence: change a terrace, conform offset objects, save/reopen and repeat the affected route and visibility case.
- [ ] Review: record the tested renderer, camera views, settings, map revision and measured edit/runtime performance. Resolve acceptance defects and repeat affected earlier checkpoints.

## Final acceptance gate

Tick only with recorded evidence; implementation alone does not satisfy a human acceptance item.

- [ ] Floor and holes are fast to author without per-cell Inspector editing.
- [ ] Tall structures use quantised absolute elevations, including the approximately 6m pyramid.
- [ ] Step/jump/block interpretation is consistent for equal local deltas at different heights.
- [ ] Explicit ramps provide the continuous routes across otherwise blocked terrace boundaries.
- [ ] All four pyramid routes work without unintended shortcuts or collision seams.
- [ ] Top, exposed-edge and pit-bottom materials and depth are configurable.
- [ ] World-projected textures remain continuous across cells and readable on tall sides.
- [ ] Collision matches visible tops, ledges and ramps; holes have no walkable top.
- [ ] Surface queries return correct flat and interpolated ramp heights/normals.
- [ ] Grounded objects conform after edits while preserving modes and offsets.
- [ ] Player visibility works behind platforms, terraces, pyramid and ramps, with smooth local fading and restoration.
- [ ] Undo/redo, validation, repair, save/reopen and rebuild behaviour are reliable.
- [ ] Relevant automated suites and `./check.sh` pass; outstanding human defects are resolved.
- [ ] No existing Grave Danger level or floor implementation was changed for the prototype.

## Validation for each implementation milestone

Use the existing co-located test runner, replacing the example with each affected sibling suite:

```bash
godot --headless --path . --script res://tests/test_runner.gd --log-file scene_scan.log -- --test-file=res://addons/floor_surface/floor_map_test.gd
./check.sh
```

Run checks after code changes. Inspect `git status --short` after commands that may affect generated assets, and resolve stale or duplicate UIDs in text declarations. Do not use import/re-save operations to repair binary assets. Visual and movement acceptance also requires the rendered playground: headless success cannot prove transparency, readability or comfortable traversal.

At each completed implementation update, inspect the diff and use the `write-changelog` skill to record the observable player/editor improvement. This planning task itself only requires documentation review; it does not launch the playground or implement these milestones.

## Review log

Copy one entry for each trial, including retries. Refer to milestone IDs above and add concrete requested changes as new unchecked items under the affected milestone.

```text
Milestone / trial:
Date / tester / revision:
Fixture and camera view:
Settings changed (before → after):
Automated results:
Human observations (expected / actual):
Decision: Awaiting trial / Changes requested / Accepted
Follow-up checklist items:
Earlier checkpoints to repeat:
Evidence or feedback report path:
```

```text
Milestone / trial: M1 implementation and acceptance
Date / tester / revision: 2026-09-06 / Codex automated checks and user human trial / 582b6a6 + working tree
Fixture and camera view: M1 / isolated-playground-v1 / all three named camera arrangements
Settings changed (before → after): New standalone defaults retained: 5.0m/s movement, 0.80m jump, 0.25m step, 45° floor angle
Automated results: Four focused suites passed (47 assertions); scene/UID scan, test pairing and focused lint passed. ./check.sh remains blocked by pre-existing stale kill-boundary expectations in Tutorial 3 and further unrelated legacy-suite failures.
Human observations (expected / actual): Expected movement in four directions, jump, manual and fall reset, readable HUD and comfortable fixed cameras / tester reported the fixture was perfect with no requested changes
Decision: Accepted
Follow-up checklist items: Begin M2 only as a separate implementation update
Earlier checkpoints to repeat: None
Evidence or feedback report path: Not created yet
```

```text
Milestone / trial: M2 human trial 1
Date / tester / revision: 2026-09-06 / user / 5484f1b + working tree
Fixture and camera view: M2 / saved-flat-map-v1 / runtime view
Settings changed (before → after): Initial lit dark teal checker → unshaded high-contrast teal checker for retry
Automated results: Geometry, collision and query checks passed before the trial
Human observations (expected / actual): Expected a readable grid and hole / floor rendered black; player and hole debug text remained visible; player fell through the hole and off outer sides as intended
Decision: Changes requested
Follow-up checklist items: Verify the brighter unshaded grid in both runtime and editor, then repeat the M2 trial
Earlier checkpoints to repeat: M2 visual readability and HUD-to-surface agreement
Evidence or feedback report path: User report in conversation; standalone replay unavailable
```

```text
Milestone / trial: M2 human trial 2
Date / tester / revision: 2026-09-06 / user / 5484f1b + working tree
Fixture and camera view: M2 / saved-flat-map-v1 / independently launched runtime and refreshed editor preview
Settings changed (before → after): Retained 1.00m cells, origin (0, 0), 0.25m elevation unit and the brighter unshaded checker
Automated results: Focused material and assembled-playground suites passed after the visibility correction; prior M2 geometry, collision, serialization and query checks remain passing
Human observations (expected / actual): Expected visible floor, usable hole and matching runtime behavior / tester confirmed it worked correctly after launching independently
Decision: Accepted
Follow-up checklist items: Begin M3 only as a separate implementation update
Earlier checkpoints to repeat: None
Evidence or feedback report path: User report in conversation; standalone replay unavailable
```

```text
Milestone / trial: M2 implementation check; human trial pending
Date / tester / revision: 2026-09-06 / Codex automated checks / 5484f1b + working tree
Fixture and camera view: M2 / saved-flat-map-v1 / all three named camera arrangements constructed
Settings changed (before → after): Temporary 12m × 10m pad → saved 12 × 10 map at 1.00m cells, origin (0, 0), 0.25m elevation unit, central 2 × 2 hole
Automated results: Seven focused suites passed (110 assertions); scene/UID scan, test pairing, focused lint and diff checks passed. ./check.sh remains blocked by the existing Tutorial 3 GDKillBoundary3D expectation and its resulting unrelated teardown failure.
Human observations (expected / actual): Expected stable movement across visible cell seams, live matching samples and a fall/reset through the hole with no invisible bridge / awaiting trial
Decision: Awaiting trial
Follow-up checklist items: Run the directed M2 trial, reopen the scene, and settle the cell-size/origin contract
Earlier checkpoints to repeat: Confirm M1 movement and camera comfort remain intact
Evidence or feedback report path: Not created yet
```

```text
Milestone / trial: M3 implementation checkpoint
Date / tester / revision: 2026-09-06 / Codex automated checks / 18b7573 + working tree
Fixture and camera view: M2 saved-flat-map-v1 / Godot 3D editor viewport
Settings changed (before → after): Added explicit viewport-paint toggle; paint/erase; 1, 3, 5, 7 and 9-cell square brushes; rectangle fill; green/red footprint preview
Automated results: FloorMap, shape painter, dock, editor plugin and runtime FloorSurface focused suites pass. Headless editor startup, all-scene/UID scan, test pairing and focused lint pass. ./check.sh reaches the known unrelated Tutorial 3 failure where the legacy kill-boundary test requests GDKillBoundary3D; its aborted suite then exceeds teardown baselines.
Human observations (expected / actual): Expected room painting, a central erased hole, a widened passage, one undo per gesture, redo, save/reopen and uninterrupted middle/right-mouse navigation / awaiting trial
Decision: Awaiting trial
Follow-up checklist items: Complete the M3 human trial and adjust brush feedback or controls from observed use
Earlier checkpoints to repeat: Confirm the M2 checker remains visible after save/reopen
Evidence or feedback report path: Not created yet
```

```text
Milestone / trial: M3 human trial 1
Date / tester / revision: 2026-09-06 / user / 18b7573 + working tree
Fixture and camera view: M2 saved-flat-map-v1 / Godot 3D editor viewport
Settings changed (before → after): Shared playground map → independently copied scene-local map; authored holes and a passage; saved and reopened the scene
Automated results: Pre-trial M3 focused suites, editor startup, scene/UID scan, test pairing and lint passed
Human observations (expected / actual): Escape restored the gesture, middle/right navigation worked, and scene-local saving survived closure. Fixed map bounds felt unnecessary; Rectangle existed but was not discoverable; Make Unique did not explain why it was needed; the selected FloorSurface transform gizmo obstructed painting.
Decision: Changes requested
Follow-up checklist items: Auto-expand bounds during paint with full undo/cancel; expose Brush and Rectangle buttons; explain shared versus independent maps in consequence-first language; hide and restore the selection gizmo with paint mode
Earlier checkpoints to repeat: M3 undo/redo and save/reopen; M2 visual readability after the authored trial layout
Evidence or feedback report path: User report in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M3 human retry 2
Date / tester / revision: 2026-09-06 / user / 18b7573 + working tree
Fixture and camera view: Saved-flat-map-v1 / Godot 3D editor viewport
Settings changed (before → after): Fixed storage edge → automatic expansion and trimming; hidden shape selector → direct Brush/Rectangle buttons; ambiguous Make Unique wording → consequence-first independent-copy explanation; selected-node gizmo → hidden only while painting
Automated results: Six focused M3 suites passed 141 assertions after the retry refinement; complete repository validation retains the pre-existing Tutorial 3 kill-boundary blocker recorded above
Human observations (expected / actual): Expected out-of-bounds painting, obvious shape controls, complete undo/redo and unobstructed editing / tester reported that out-of-bounds painting and undo/redo worked and that the buttons were clear, accepting the revised workflow as great
Decision: Accepted
Follow-up checklist items: Begin M4 only as a separate implementation update
Earlier checkpoints to repeat: Retain M3 gesture and persistence checks when elevation editing begins
Evidence or feedback report path: User report in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M4 implementation checkpoint
Date / tester / revision: 2026-09-06 / Codex automated checks / 4d99236 + working tree
Fixture and camera view: M4 absolute-elevation-comparison-v1 / three focus-preserving camera arrangements
Settings changed (before → after): Flat-only floor → integer absolute heights at 0.25m per unit; one jump tune → Normal 0.65m and Unencumbered 0.90m; added 1-unit walk, 2-unit normal jump, 3-unit unencumbered-only and 4-unit blocked thresholds
Automated results: Fourteen focused suites passed 284 assertions, including editor gestures, elevated picking/overlay, owned ledge mesh/collision and real low/high lane traversal. Editor startup, 119-scene/UID scan, 232-script test pairing and focused lint pass. ./check.sh reaches 2,397 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown baseline failure.
Human observations (expected / actual): Expected direct elevation-24 authoring, readable false colours and equivalent physical traversal in the low and high lanes / awaiting trial
Decision: Awaiting human trial
Follow-up checklist items: Run the directed M4 editor and traversal trial; tune provisional thresholds only from observed use
Earlier checkpoints to repeat: Confirm M3 rectangle, undo/redo, save/reopen and viewport navigation while authoring elevation
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M4 human trial 1
Date / tester / revision: 2026-09-06 / user / 4d99236 + working tree
Fixture and camera view: M4 absolute-elevation-comparison-v1 / Godot 3D editor viewport
Settings changed (before → after): Flat-only floor → integer absolute elevation painting with full-tile false-colour feedback
Automated results: Pre-trial M4 focused suites passed 284 assertions; complete repository validation retained the pre-existing Tutorial 3 kill-boundary blocker
Human observations (expected / actual): Elevation painting was easy to use and undo/redo worked well. Hole walls, the exposed back of the raised comparison structure and outer boundary walls were missing. The full-value elevation overlay was too bright and obscured checker contrast for a tester with diabetic retinopathy.
Decision: Changes requested
Follow-up checklist items: Generate owned walls for every floor-to-empty boundary; reduce overlay luminance and opacity while retaining exact text labels; visually retry holes, outer edges and checker readability
Earlier checkpoints to repeat: Retain the accepted elevation painting and undo/redo interaction
Evidence or feedback report path: User report in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M4 human-trial revision 1
Date / tester / revision: 2026-09-06 / Codex automated checks / 4d99236 + working tree
Fixture and camera view: M4 absolute-elevation-comparison-v1 / Godot 3D editor viewport
Settings changed (before → after): Floor-to-empty boundaries omitted → one owned wall to the style's provisional 2m depth; full-value overlay at 0.72 alpha → muted 0.38-value overlay at 0.26 alpha
Automated results: Fifteen focused suites passed 300 assertions, including explicit hole, outer-boundary, raised ledge and overlay luminance/opacity cases. Scene/UID scanning, test pairing and focused lint pass. ./check.sh reaches 2,402 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown baseline failure.
Human observations (expected / actual): Expected complete exposed sides and a readable checker beneath low-glare elevation feedback / awaiting visual retry
Decision: Awaiting human retry
Follow-up checklist items: Visually inspect the hole, outer perimeter and raised comparison structure, then confirm elevation mode is comfortable and the checker remains legible
Earlier checkpoints to repeat: Retain the accepted elevation painting and undo/redo interaction
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

## Deferred until a separate integration plan

After every final acceptance item passes, the prototype is ready for integration planning. That future plan must cover the PNG-generated floor path; existing floor-plane/GridMap migration; main scenery/GridMap grounding; navigation, enemies and gameplay consumers of the API; real-player and encumbrance tuning; the production camera/rendering setup; one representative converted level; and a rollback path before bulk conversion. Passing this plan does not itself authorize or start those changes.
