# Floor Surface Implementation Plan

Based on [FLOOR SURFACE DESIGN.md](FLOOR%20SURFACE%20DESIGN.md). This plan covers the **standalone prototype only**. M1, M2 and M3 are accepted; M4 and M5 retain open final human-review items after their implementation and feedback revisions; M6 is implemented and awaiting its directed human trial. Later milestones remain unimplemented.

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
| `FloorStyle` resource | Independent top, wall and pit-bottom materials, separate floor/wall texture scales and pit depth; missing resources produce actionable validation. |
| `FloorSurface` scene | Owns the map and palette, exposes the surface API, coordinates rebuilds and emits typed change notifications. No new autoload. |
| Geometry builder | Derives batched top/edge/ramp/pit meshes and static collision from a shared surface description. Start with a full deterministic rebuild; introduce chunk invalidation when measured or needed. |
| Surface sampler | Returns a typed result containing validity, world height, normal, cell, style and transition; shares ramp mathematics with generation. |
| Editor plugin | Selects a FloorSurface, paints in the 3D viewport and provides a dock, overlays, validation and stroke-level undo/redo. |
| Grounding component/scene | Holds a typed surface reference, grounding mode and explicit placement offset; works on visible, editable scene objects. |
| Visibility controller and shaders | Consume derived elevation/occupancy data and camera/player inputs; fade obstructing fragments while preserving the surrounding structure. |
| Playground scene | Own camera, light, CharacterBody3D player, debug UI, reset points and editable sample objects. |

Generated mesh and collision nodes are derived output; authoring lives in map/style resources and ordinary placement nodes. Do not create a node for every face. Keep helper scripts small, typed and composable, and document exported settings in human terms. Use named PascalCase enums rather than numeric mode values.

The prototype normally limits itself to text assets: `.gd`, `.tscn`, `.tres`, `.gdshader` and plugin configuration. The M5 trial specifically authorized exact copies of the existing dirt and flagstone textures in a FloorSurface-owned game-art folder; established textures and level material references remain untouched. Do not rewrite binary assets or bake generated geometry/textures to disk. The elevation texture is transient GPU data regenerated from the map. Any other binary asset change needs the specific authorization required by `AGENTS.md`.

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

- [x] Supply at least two reusable styles using FloorSurface-owned copies of existing game floor textures, with independently configurable top, wall and pit-bottom appearance and depth. The supplied flagstone style uses a separate existing stone-wall texture on vertical faces.
- [x] Add style brush, rectangle and sample tools using M3's undo model. Preserve topology and collision when changing material alone.
- [x] Implement continuous world X/Z projection on tops and world-planar projection on axis-aligned exposed sides. Each `FloorStyle` owns separate floor/pit and wall metres-per-repeat values; the builder supplies UVs and never mutates source materials.
- [x] Define pit depth relative to a documented rim datum for each connected hole region, including mixed rim elevations and style depths. The datum is the lowest `rim world Y - rim style depth` candidate, giving the region one horizontal bottom, ensuring every wall meets it, and never making a rim shallower than requested.
- [x] Generate optional pit bottoms only within authored bounds. Treat them as visual-only in the prototype: surface queries remain invalid in holes and the player falls/resets. Keep this choice explicit for later review.
- [x] Automated checks: edge ownership at holes and lower neighbours, material grouping, depth changes, missing-style warnings, no walkable collision over holes and style undo. All 20 focused FloorSurface suites pass 412 assertions, including copied texture references, the default-off grid guide, non-mutating unshaded editor previews and clockwise visible-face winding; editor startup, scene/UID scanning, test pairing and focused lint pass. The full repository check reaches 2,492 passing assertions before the pre-existing Tutorial 3 kill-boundary lookup abort and related teardown failure.
- [ ] Human trial: paint flagstones next to dirt, inspect the real texture across cell boundaries with the optional grid guide off and on, change pit depth, Wall Material and Wall UV Metres, and walk/fall around the pit. Check texture scale on tall walls and seams at mixed-height rims.
- [ ] Review: accept the pit datum and appearance controls; resolve visible cracks or inconsistent depth before ramps add more edge shapes.

## M6 — Explicit ramps and transition authoring

**Deliverable:** Paintable ramps connect arbitrary local elevations, with matching rendering, collision and samples.

- [x] Implement named flat/ramp transition and low-edge orientation data; reserve extensibility without implementing stairs, ladders or special drops.
- [x] Infer low/high flat endpoints for each contiguous ramp run. Accept any non-zero elevation difference and distribute it across the authored run length; reject missing, equal or ambiguous endpoints visibly rather than guessing silently.
- [x] Generate ramp tops, collision and triangular/trapezoidal exposed sides from one shared surface description. Sample interpolated height and normal across the full ramp.
- [x] Add a flat-landing-to-flat-landing transition tool with inferred orientation, a surface-conforming preview and a correction control for ambiguous intent. Clicking an existing valid slope begins at its high landing. Ramp deletion restores the authored ledge/top behaviour through undoable edits.
- [x] Support variable-length contiguous ramp runs plus sequences of ramps and landings across several terraces. One drag may span any number of ramp tiles between retained flat high and low endpoints.
- [x] When the optional grid guide is enabled in Ramp mode, mark every authored Ramp tile with a distinct muted tint; keep real floor materials unchanged and remove the tint immediately outside Ramp mode.
- [x] Build a three-metre, five-tile continuous ramp route with untouched blocked edges alongside it. Verify the same three-metre rise over one through five tiles without imposing an authored slope limit.
- [x] Automated checks: all four orientations, one-to-five-tile runs, endpoint/midpoint samples, normals, side geometry, hole neighbours, invalid endpoints, adjacent seams and physics/query agreement.
- [ ] Human trial: drag between flat high and low landings, then walk up/down and across the result, jump onto it and try neighbouring unpainted ledges. Start another gesture on an existing slope to confirm it snaps to the high landing. Edit a landing to invalidate it, inspect the warning, repair it, then undo/redo.
- [ ] Review: tune transition gestures and run feedback; retain the reliable five-tile ramp route for later regression trials.

## M7 — Early player visibility experiment

**Deliverable:** Evidence for a rendering approach before applying the final fade across all floor styles.

- [x] Derive world-aligned GPU-readable elevation and occupancy data from FloorMap, with ramp orientation/endpoints or equivalent data sufficient to represent slopes. Refresh on relevant edits, not every frame for static terrain.
- [x] Add a 1m platform, taller terrace and ramp obstruction fixture, plus debug player position, sample data, fade reason and an elevation-data preview. Use the actual GDPlayer and production perspective follow-camera so the visual trial reflects the game.
- [x] Compare fragment-depth/screen-space, elevation-guided and ray-gated obstruction masks in actual Forward Plus output. The transparent variants were rejected after producing false fades, hard edges, unstable shadows, depth-order artefacts and poor contrast.
- [x] Evaluate false fades, ramp accuracy, transparency sorting, shadow behaviour and overlapping top/edge materials. Reject whole-object hiding and any selected approach that modifies scenery rendering.
- [x] Implement the selected experiment as a separate component composed into the shared player scene, providing every gameplay level with the depth/stencil-tested solid silhouette without per-level edits. Keep FloorSurface and GridMap materials, shadows and camera layers untouched; use the authoritative animated player geometry without mutating authored material resources.
- [x] Automated checks: elevation/occupancy comparison data, authoritative-mesh overlay ownership, authored-resource preservation, solid depth/stencil shader contracts, comparison toggle and teardown. Shader appearance remains a rendered human check.
- [ ] Human trial: repeatedly walk behind and in front of the platform, pause while partially overlapped, ascend the ramp, switch named camera views and disable the silhouette for comparison. Confirm visible player pixels and all scenery remain unchanged while only hidden player pixels receive the solid silhouette.
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
- [ ] Top, exposed-wall and pit-bottom materials, independent texture scales and depth are configurable.
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

```text
Milestone / trial: M5 implementation checkpoint
Date / tester / revision: 2026-09-07 / Codex automated checks / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / accepted room plus retained low/high traversal views
Settings changed (before → after): One teal top material and provisional 2m sides → named teal and stone styles with independent top/edge/pit materials, 1m world UV repeat, and 2m/3m rim depths; no pit datum → lowest rim-Y-minus-style-depth datum per connected bounded hole
Automated results: Nineteen focused FloorSurface suites passed 390 assertions, covering style gestures and undo, material grouping, continuous top and side projection, mixed-rim datum changes, crack-free wall endpoints, optional visual bottoms, invalid hole samples and no pit-bottom collision. Headless editor startup, 119-scene/UID scan, 234-script pairing and lint pass. ./check.sh reaches 2,470 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown failure.
Human observations (expected / actual): Expected easy teal/stone painting, continuous checker scale, distinct edges, a readable mixed-rim bottom and falling through that visual bottom / awaiting trial
Decision: Awaiting human trial
Follow-up checklist items: Retry M4 side/overlay readability, then paint and sample both M5 styles, inspect mixed-height seams, adjust a style depth/material and fall through the central visual bottom
Earlier checkpoints to repeat: Retain M3 rectangle/undo/redo and M4 low-glare elevation mode plus complete hole/perimeter walls
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M5 human trial 1 visual-material feedback
Date / tester / revision: 2026-09-07 / user / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): M5 style and pit painting enabled with the checker shader still serving as each floor material
Automated results: Pre-trial M5 focused suites passed 390 assertions; complete repository validation retained the pre-existing Tutorial 3 kill-boundary blocker
Human observations (expected / actual): The permanent grid/checker made the underlying floor texture impossible to inspect. The tester requested a toggle and a game-owned floor-texture folder populated by copies so new FloorSurface art cannot break existing systems.
Decision: Changes requested
Follow-up checklist items: Keep the diagnostic grid as an editor-only toggle that defaults off; use independently copied dirt and flagstone textures for the current style palette; retry texture, side and pit readability
Earlier checkpoints to repeat: Retain accepted M3 painting/undo and M4 low-glare elevation feedback while inspecting unmasked M5 materials
Evidence or feedback report path: User report in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M5 human-trial revision 1
Date / tester / revision: 2026-09-07 / Codex automated checks / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): Opaque checker FloorStyle materials → lit Dirt and Flagstones materials using exact copies in the FloorSurface game-art library; permanent checker → subdued editor-only Show Grid / Checker Guide toggle, off by default
Automated results: Nineteen focused FloorSurface suites pass 401 assertions. Texture-copy hashes match their established sources; focused lint, headless editor/import startup, 119-scene/UID scan and 234-script pairing pass. ./check.sh reaches 2,481 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown baseline failure.
Human observations (expected / actual): Expected unobscured dirt and flagstone textures by default, with a low-opacity alignment guide available only when requested / awaiting visual retry
Decision: Awaiting human retry
Follow-up checklist items: In the already-open editor, compare both named styles with the guide off and on, then inspect the hole walls and bottom under the real textures
Earlier checkpoints to repeat: Retain accepted M3 painting/undo and M4 low-glare elevation feedback
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M5 human retry 2 visual-material feedback
Date / tester / revision: 2026-09-08 / user / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): Checker materials → lit texture materials with optional grid guide
Automated results: Revision 1 focused checks passed before the visual retry
Human observations (expected / actual): The generated horizontal floor preview rendered almost black while vertical flagstone faces remained readable, making the scene appear broken despite the copied textures loading.
Decision: Changes requested
Follow-up checklist items: Render transient unshaded copies only in the editor preview while preserving lit runtime materials; visually retry texture readability
Earlier checkpoints to repeat: Confirm the grid guide remains optional and defaults off
Evidence or feedback report path: User screenshot in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M5 human-retry revision 2
Date / tester / revision: 2026-09-08 / Codex automated checks / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): Generated editor mesh reused lit style materials → editor mesh uses transient unshaded duplicates; runtime style resources remain per-pixel lit
Automated results: Twenty focused FloorSurface suites pass 411 assertions, including proof that preview conversion does not mutate runtime materials. A headless editor fixture verifies all three generated playground surfaces use unshaded preview copies. Editor startup, 119-scene/UID scan, 235-script pairing and focused lint pass. ./check.sh reaches 2,491 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown baseline failure.
Human observations (expected / actual): Expected clearly readable dirt and flagstone textures on horizontal and vertical generated faces in the editor / awaiting visual retry
Decision: Awaiting human retry
Follow-up checklist items: Reload the playground scene and inspect the texture with Show Grid / Checker Guide off, then toggle the guide briefly for comparison
Earlier checkpoints to repeat: Confirm pit/outer walls, style painting and undo remain intact
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M5 human retry 3 face-culling feedback
Date / tester / revision: 2026-09-08 / user / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): Lit texture materials → readable unshaded editor-preview copies
Automated results: Revision 2 focused checks passed before the visual retry
Human observations (expected / actual): Only back faces were visible. The earlier checker shader had disabled culling and therefore concealed counter-clockwise generated triangles that Godot treated as back faces.
Decision: Changes requested
Follow-up checklist items: Reverse all generated top, pit-bottom, exposed-side and matching collision triangles to Godot's clockwise front-face order; visually retry from above and around the outer walls
Earlier checkpoints to repeat: Confirm actual textures remain readable and the grid guide remains optional
Evidence or feedback report path: User report in conversation; editor-only trial has no gameplay recording
```

```text
Milestone / trial: M5 human-retry revision 3
Date / tester / revision: 2026-09-08 / Codex automated checks / adf6c00 + working tree
Fixture and camera view: M5 styled-mixed-rim-pit-v1 / Godot 3D editor viewport
Settings changed (before → after): Counter-clockwise generated faces masked by cull-disabled checker → clockwise generated faces compatible with ordinary one-sided floor materials
Automated results: The geometry suite passes 38 assertions including every generated top and side triangle's winding. Surface collision, playground and editor-preview suites pass. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 235 script/test pairs, then reaches 2,492 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort and related teardown failure.
Human observations (expected / actual): Expected visible top faces from above, visible outward walls and unchanged collisions / awaiting visual retry
Decision: Awaiting human retry
Follow-up checklist items: Reload the playground, inspect tops from above and orbit around an outer wall and the pit
Earlier checkpoints to repeat: Confirm textures, style painting, pit walls and undo remain intact
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M6 implementation checkpoint
Date / tester / revision: 2026-09-08 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 authored-ramp-route-v1 / existing room and comparison views plus repeatable ramp-route focus
Settings changed (before → after): Reserved Flat/Ramp fields without behaviour → exact one-band ramps over a 1m cell run, limited to 45°, with inferred low edge, generated slope/side collision and interpolated samples
Automated results: Focused map, profile, resolver, painter, dock, plugin, picker, overlay, geometry, surface and playground suites pass, including all orientations, endpoints, normals, invalid bands and holes, watertight ramp/landing seams and physics/query agreement. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; all 245 co-located suites report 2,604 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D lookup abort causes the known teardown/baseline failure.
Human observations (expected / actual): Expected paintable east/west/north/south ramps, readable orientation preview, smooth walking and jumping, safe invalidation warnings and complete undo/redo / awaiting directed human trial
Decision: Awaiting human trial
Follow-up checklist items: Paint one ramp, walk up/down/across and jump onto it; invalidate and repair one landing; undo/redo; cycle to the retained two-ramp route with T
Earlier checkpoints to repeat: Confirm M3 navigation/undo, M4 ledge walls and low-glare overlay, and M5 textures with the optional grid off
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M6 human trial 1 authoring feedback
Date / tester / revision: 2026-09-08 / user / 0e25424 + working tree
Fixture and camera view: M6 authored-ramp-route-v1 / Godot 3D editor viewport
Settings changed (before → after): Initial M6 single-cell direction gesture and subtle optional grid → trial configuration
Automated results: Initial focused M6 suites passed before the editor trial
Human observations (expected / actual): Expected a visible grid and a draggable ramp line / the grid appeared to do nothing, and Ramp Paint did not expose or paint a line gesture
Decision: Changes requested
Follow-up checklist items: Make the enabled grid unmistakable without high glare; preview and paint a cardinal boundary row as one undo action; reject a broken landing without partial changes
Earlier checkpoints to repeat: Preserve viewport navigation, single-ramp painting, textures with the guide off and exact one-band validation
Evidence or feedback report path: User report in conversation; editor-only authoring has no gameplay recording
```

```text
Milestone / trial: M6 human-trial revision 1
Date / tester / revision: 2026-09-08 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 authored-ramp-route-v1 / Godot 3D editor viewport
Settings changed (before → after): Subtle 1.8%-width grid at 0.24 alpha → explicit 3.5%-width medium-luminance grid at 0.58 alpha; single-cell ramp direction cue → cardinal boundary-line preview and atomic row painting
Automated results: Four focused editor suites pass 109 assertions covering grid signal propagation and readability, typed line previews, perpendicular orientation inference, four-cell painting, undo and complete rollback. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,626 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected an obvious optional grid when enabled and a stable highlighted row that becomes ramps on release / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: Toggle the guide off/on, then drag along several raised boundary tiles and confirm the complete highlighted row becomes ramps with one undo
Earlier checkpoints to repeat: Confirm a raised boundary tile can still be dragged toward one low neighbour for a single ramp
Evidence or feedback report path: Not created yet; standalone editor authoring is not captured by gameplay replay
```

```text
Milestone / trial: M6 human trial 2 slope-model clarification
Date / tester / revision: 2026-09-08 / user / 0e25424 + working tree
Fixture and camera view: M6 authored-ramp-route-v1 / Godot 3D editor viewport
Settings changed (before → after): Cardinal multi-cell painting retained the original exact one-band-per-cell validation → requested arbitrary endpoint rise distributed over any dragged run length
Automated results: Earlier M6 revision checks passed, but they encoded the wrong fixed-band assumption
Human observations (expected / actual): Expected a ramp from 3m to 0m to work over one, two, three, four or five tiles / the fixed one-band rule rejected these intended slopes
Decision: Changes requested
Follow-up checklist items: Replace band validation with flat-endpoint interpolation; retain original authored elevations for Make Flat; verify geometry, collision, samples and traversal across every internal seam
Earlier checkpoints to repeat: Grid toggle visibility, stable line dragging, undo/redo and complete rollback for an invalid landing
Evidence or feedback report path: User report in conversation; editor-only authoring has no gameplay recording
```

```text
Milestone / trial: M6 human-trial revision 2
Date / tester / revision: 2026-09-08 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v2 / repeatable ramp-route focus
Settings changed (before → after): Exact 0.25m ramp band and 45° authoring cap → any non-zero flat-landing elevation difference distributed continuously over one or more ramp tiles; standalone controller floor angle 45° → 89° for steep-ramp trials
Automated results: Resolver tests pass 61 assertions including 3m rises over one through five tiles. Painter, geometry, surface and physical-playground suites pass 208 assertions, including retained authored heights, continuous internal seams and walking the five-tile route. Editor dock, plugin, visuals, profile and controller-settings suites pass another 102 assertions. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,687 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown and dummy-renderer baseline failure.
Human observations (expected / actual): Expected a visible straight drag whose slope is derived solely from the two landing heights and selected length / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: Select Paint Ramp; drag from a 3m high boundary tile to a 0m flat landing over one through five tiles; inspect the preview, release, walk the result and test one undo/redo
Earlier checkpoints to repeat: Toggle the grid guide, confirm texture readability with it off, and confirm an invalid/missing landing makes no partial edit
Evidence or feedback report path: Not created yet; standalone editor authoring has no gameplay recording
```

```text
Milestone / trial: M6 human trial 3 gesture and preview feedback
Date / tester / revision: 2026-09-08 / user / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v2 / Godot 3D editor viewport
Settings changed (before → after): Unrestricted endpoint interpolation with a high boundary included in the run → trial configuration
Automated results: Revision 2 focused and repository checks passed the FloorSurface coverage before the editor retry
Human observations (expected / actual): Expected to drag down from the top of the supplied slope or another raised tile / the first ramp could not be placed, another placement worked inconsistently, the viewport moved during left-drag and the highlight floated above lower tiles
Decision: Changes requested
Follow-up checklist items: Consume every active-drag motion event; retain both endpoint tiles as flat landings; snap a valid existing ramp start to its high landing; conform the highlight to planned corner heights with normal scene depth
Earlier checkpoints to repeat: Arbitrary 3m rise over one through five ramp tiles, grid toggle, undo/redo and invalid-gesture rollback
Evidence or feedback report path: User report in conversation; editor-only authoring has no gameplay recording
```

```text
Milestone / trial: M6 human-trial revision 3
Date / tester / revision: 2026-09-08 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v3 / Godot 3D editor viewport and physical ramp route
Settings changed (before → after): Start boundary became a ramp and needed hidden high support → both visible drag endpoints remain flat landings; active motion capture depended on the event button mask → every motion event is consumed until release; one-height no-depth preview box → depth-tested per-cell planned slope preview
Automated results: Painter, visuals, plugin, dock and playground suites pass 196 focused assertions covering flat endpoints, snapping an existing slope to its high landing, one-to-five-tile interpolation, surface-conforming previews, input capture and physical traversal. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,704 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown and dummy-renderer baseline failure.
Human observations (expected / actual): Expected a stable viewport, a highlight resting on the intended surface and successful painting from the top landing / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: With Paint Ramp active, drag from either flat landing to the other with at least one tile between; also begin on the supplied slope and confirm the preview starts from its flat high landing
Earlier checkpoints to repeat: Toggle the grid guide and test one undo/redo plus one invalid drag
Evidence or feedback report path: Not created yet; standalone editor authoring has no gameplay recording
```

```text
Milestone / trial: M6 human trial 4 typed-preview feedback
Date / tester / revision: 2026-09-08 / user / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v3 / Godot 3D editor viewport
Settings changed (before → after): Surface-conforming ramp preview and live drag validation text → trial configuration
Automated results: Revision 3 focused checks passed, but its typed test data did not reproduce an editor dictionary returning an untyped corner-height array
Human observations (expected / actual): Expected the ramp preview and placement to complete / repeated Array-to-Array[float] errors stopped the preview; live error text resized the plugin panel and caused the apparent viewport glitch
Decision: Changes requested
Follow-up checklist items: Convert preview height values explicitly at the dictionary boundary; add an untyped-array regression; remove live validation details and keep any release result to a fixed one-line status
Earlier checkpoints to repeat: Paint from the supplied slope and a separate raised landing; verify the highlight follows the surface and the camera remains still
Evidence or feedback report path: User report in conversation; editor-only authoring has no gameplay recording
```

```text
Milestone / trial: M6 human-trial revision 4
Date / tester / revision: 2026-09-08 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v4 / Godot 3D editor viewport
Settings changed (before → after): Direct Array[float] cast from editor preview dictionaries → explicit per-value typed conversion; variable live error details → no hover validation text and fixed one-line rejection status
Automated results: Painter, visuals, plugin and dock suites pass 145 focused assertions, including an untyped editor-dictionary preview regression and stable hover text. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,704 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown and dummy-renderer baseline failure.
Human observations (expected / actual): Expected error-free placement with no panel-driven viewport shift / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: Reload the editor script, drag between flat landing endpoints and confirm the panel size, camera and highlight remain steady through release
Earlier checkpoints to repeat: One-to-five-tile ramps, existing-slope high-landing snap, undo/redo, grid toggle and invalid rollback
Evidence or feedback report path: Not created yet; standalone editor authoring has no gameplay recording
```

```text
Milestone / trial: M6 ramp-state visibility request
Date / tester / revision: 2026-09-09 / user / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v4 / Godot 3D editor viewport
Settings changed (before → after): Ordinary optional grid in every edit mode → requested distinct ramp-tile colour while the grid and Ramp mode are both active
Automated results: Revision 4 checks passed before this editor-visibility request
Human observations (expected / actual): After flattening a visible slope, it was unclear whether Ramp metadata still remained because equal-height or invalid ramps could look like ordinary flat tiles
Decision: Changes requested
Follow-up checklist items: Encode authored Ramp cells in the grid mesh, apply a low-glare distinct tint only in Ramp mode, and refresh immediately when the mode or transition data changes
Earlier checkpoints to repeat: Grid off must show untouched textures; grid in other modes must retain its ordinary appearance; Make Flat must clear the ramp marker
Evidence or feedback report path: User request in conversation; editor-only authoring has no gameplay recording
```

```text
Milestone / trial: M6 human-trial revision 5
Date / tester / revision: 2026-09-09 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v5 / Godot 3D editor viewport
Settings changed (before → after): Ramp metadata indistinguishable in the optional grid → Ramp tiles receive a muted blue-green fill at 0.28 alpha while Ramp mode is active
Automated results: Elevation-overlay, editor-visuals and plugin suites pass 56 focused assertions covering an exact six-vertex ramp mask, low-glare tint limits and immediate mode toggling. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,709 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown and dummy-renderer baseline failure.
Human observations (expected / actual): Expected existing Ramp tiles to be visually distinguishable without obscuring their floor texture / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: Enable the grid in Ramp mode, verify slopes are tinted, use Make Flat and confirm the tint disappears; switch modes and confirm ordinary grid appearance
Earlier checkpoints to repeat: Texture readability with grid off, stable ramp dragging and one undo/redo
Evidence or feedback report path: Not created yet; standalone editor authoring has no gameplay recording
```

```text
Milestone / trial: M5 wall-material configuration request during M6
Date / tester / revision: 2026-09-09 / user / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v5 / Godot 3D editor viewport
Settings changed (before → after): Internally configurable Edge Material used the supplied floor textures and shared their UV scale → requested explicit wall texture configuration suitable for vertical masonry
Automated results: Previous FloorSurface checks passed before this appearance request
Human observations (expected / actual): Flagstones are plausible on horizontal tops but not on generated walls; those sides need their own selectable texture
Decision: Changes requested
Follow-up checklist items: Expose a plainly named Wall Material, separate its metres-per-repeat setting from floor/pit UV scale, retain old Edge Material resources safely, and give the supplied Flagstones style a real wall texture
Earlier checkpoints to repeat: Outer, ledge, pit and ramp sides must all use the configured wall material; tops and pit bottoms must remain unchanged
Evidence or feedback report path: User request in conversation; editor-only appearance review has no gameplay recording
```

```text
Milestone / trial: M5 wall-material configuration revision
Date / tester / revision: 2026-09-09 / Codex automated checks / 0e25424 + working tree
Fixture and camera view: M6 variable-five-tile-ramp-v6 / Godot 3D editor viewport
Settings changed (before → after): Edge Material plus one shared World UV Metres setting → Inspector-facing Wall Material plus independent Wall UV Metres; Flagstones wall reused floor albedo → existing stone-wall texture
Automated results: Style, geometry, surface, pit-resolver and editor-material-preview suites pass 146 focused assertions, including independent wall UV projection, distinct flagstone wall texture and legacy Edge Material fallback. ./check.sh validates 193 text-resource UIDs, 119/119 scenes and 237 script/test pairs; 245 suites report 2,712 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown and dummy-renderer baseline failure.
Human observations (expected / actual): Expected separate, editable wall appearance on every vertical generated face / awaiting editor retry
Decision: Awaiting human retry
Follow-up checklist items: Expand either FloorStyle in the styles palette, change Wall Material and Wall UV Metres, and inspect outer walls, a raised ledge, a pit wall and a ramp side
Earlier checkpoints to repeat: Floor texture continuity, pit-bottom appearance, grid/ramp tint and undoable style painting
Evidence or feedback report path: Not created yet; standalone editor authoring has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 3
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v1 / production player and perspective follow-camera
Settings changed (before → after): Exact obstruction-ray gate with 25% centre opacity and always-attached transparent floor wrappers → trial configuration
Automated results: Previous M7 focused checks passed before this visual review
Human observations (expected / actual): Expected only the true obstruction to fade without affecting unrelated rendering / 3D fixture text was overdrawn even while the player was clear; the fade centre remained too transparent; the player light behaved strangely at close range to the large slope
Decision: Changes requested
Follow-up checklist items: Keep clear terrain in the opaque render pass; order an active translucent floor behind ordinary transparent content; increase retained opacity; keep player light origins inside the collision hull
Earlier checkpoints to repeat: Genuine obstruction-only activation, smooth edges, restoration, ramp sides and nearby opaque scenery
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 3
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v2 / production player and perspective follow-camera
Settings changed (before → after): Transparent floor wrapper present for the entire run → source opaque materials while clear and temporary low-priority wrappers only during fade; 25% → 50% centre opacity; player lights 0.30m forward and outside the 0.28m capsule → 0.18m forward and inside the hull
Automated results: Visibility experiment, assembled playground and production-player suites pass 69 focused assertions covering render-pass activation/restoration, transparent priority, obstruction gating and light placement. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,737 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected fixture text and normal lighting to retain opaque ordering while clear, a less transparent obstruction, and no light-origin intersection at the large slope / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Walk clear beside the labels and large slope first, then cross behind each obstruction and confirm the 50% centre, soft edge, text ordering and light remain stable
Earlier checkpoints to repeat: F toggle, all named camera views, platform, terrace, pyramid and ramp
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 4
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v2 / production player and perspective follow-camera
Settings changed (before → after): 50% centre opacity, 1.35m radius and 0.45m soft edge → trial configuration
Automated results: The corrected render-pass, text-ordering and light-placement checks passed before this visual tuning review
Human observations (expected / actual): Expected a restrained local fade that preserved the obstruction / the structure remained too transparent and the circular affected area was too large
Decision: Changes requested
Follow-up checklist items: Increase retained structure opacity and reduce both the circle radius and feather width
Earlier checkpoints to repeat: Soft edge quality, player readability and complete restoration after leaving obstruction
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 4
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v3 / production player and perspective follow-camera
Settings changed (before → after): 50% → 70% centre opacity; 1.35m → 0.90m radius; 0.45m → 0.25m soft edge
Automated results: The focused visibility suite passes 23 assertions, including explicit default size, feather and opacity coverage. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,738 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected a smaller, subtler local visibility assist that keeps most of the structure visible / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Stand behind the 1m platform and pyramid, then compare player readability, preserved floor texture and circle scale while moving
Earlier checkpoints to repeat: Text ordering, clear-state lighting, genuine obstruction-only activation and restoration
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 5
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v3 / production player and perspective follow-camera
Settings changed (before → after): 70% opacity inside a 0.90m world-space radius with 0.25m world-space feather → trial configuration
Automated results: The tuned world-space defaults passed 23 focused assertions before this projection review
Human observations (expected / actual): Expected a consistently sized, visibly feathered partial-transparency assist / the feather was no longer apparent, the partial transparency was too subtle to identify the assist, and nearby obstruction geometry made the hole appear larger
Decision: Changes requested
Follow-up checklist items: Measure aperture and feather in screen pixels, retain world-space height eligibility and collision gating, and restore a visibly partial centre opacity
Earlier checkpoints to repeat: Constant circle size across near/far geometry, soft edge quality, player readability and preserved structure
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 5
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v4 / production player and perspective follow-camera
Settings changed (before → after): World-space distance to the camera/player segment → constant 90px screen-space player aperture; 0.25m → 28px feather; 70% → 62% retained opacity
Automated results: Visibility and assembled-playground suites pass 61 focused assertions, including constant-pixel shader math, a smoothstep feather, partial alpha, obstruction gating and safe camera-plane projection. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,739 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected the same circular size on near and far fragments, with an obvious soft transition and moderate transparency / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Move behind the platform while changing camera distance, then approach the pyramid and confirm the apparent circle size and feather remain stable
Earlier checkpoints to repeat: Clear-state text/light rendering, genuine obstruction-only activation, F comparison and smooth restoration
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 6
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v4 / production player and perspective follow-camera
Settings changed (before → after): Constant 90px aperture, 28px feather and 62% retained opacity → trial configuration
Automated results: The constant-pixel hybrid passed 61 focused assertions before this visual review
Human observations (expected / actual): Expected stable near/far sizing with a recognizable feather and partial transparency / the edge still appeared sharp, the obstruction appeared fully transparent, and fixed pixels made the aperture the wrong size after camera zoom
Decision: Rejected
Follow-up checklist items: Derive screen radius from projected player size rather than fixed pixels or fragment depth; remove the alpha depth pre-pass; enforce at least half opacity in the shader
Earlier checkpoints to repeat: Near/far obstruction fragments, manual zoom, continuous edge blending and preserved obstruction texture
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 6
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v5 / production player and perspective follow-camera
Settings changed (before → after): Fixed 90px radius and 28px feather → 0.75 and 0.25 of the actual player's projected collision height; transparent depth pre-pass → continuous alpha blend; 62% requested opacity → 55% requested opacity with a shader-enforced 50% minimum
Automated results: Visibility and assembled-playground suites pass 63 focused assertions covering player-collision sizing, zoom response, fragment-depth independence, smoothstep feathering, absence of the alpha depth pre-pass and the hard opacity floor. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,741 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected the aperture to scale with the player under zoom, remain independent of obstruction depth, retain at least half of the floor and show a continuous feather / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Stand behind near and far faces, zoom fully in/out and confirm the aperture tracks player size without changing across those faces; inspect centre texture and the full feather
Earlier checkpoints to repeat: Genuine obstruction-only activation, clear-state text/light rendering, F comparison and restoration
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 7
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v5 / production player and perspective follow-camera
Settings changed (before → after): Player-relative continuous alpha without depth writing → trial configuration
Automated results: The player-relative implementation passed 63 focused assertions before this rendered batching review
Human observations (expected / actual): Expected only the player-relative aperture to blend / the entire view faded when the FloorSurface entered its transparent pass
Decision: Changes requested
Follow-up checklist items: Preserve continuous feathering but write depth during the ordinary transparent pass so the batched floor cannot wash over already rendered content
Earlier checkpoints to repeat: At-least-half opacity, zoom-relative player scale, near/far geometry independence and soft edge
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 7
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v6 / production player and perspective follow-camera
Settings changed (before → after): Transparent blend with no depth write → transparent blend with depth_draw_always; separate alpha depth pre-pass remains disabled
Automated results: Visibility and assembled-playground suites pass 63 focused assertions, including the explicit depth-write/no-pre-pass contract. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,741 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected the FloorSurface to remain spatially bounded while retaining the continuous player-relative feather / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Trigger an obstruction and confirm the rest of the screen remains unchanged before evaluating opacity, feather and zoom behavior
Earlier checkpoints to repeat: Clear-state text/light rendering, genuine obstruction-only activation, F comparison and restoration
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 8
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v6 / production player and perspective follow-camera
Settings changed (before → after): Player-relative aperture with normal-pass depth writing and visible-mesh shadow ownership → trial configuration
Automated results: The bounded continuous-feather implementation passed 63 focused assertions before this shadow transition review
Human observations (expected / actual): Expected illumination and shadows to remain stable as the aperture activates / floor shadows visibly flicked between on and off when moving between unobscured and obscured states
Decision: Changes requested
Follow-up checklist items: Move shadow ownership out of the material-switched visible mesh and preserve identical opaque shadow geometry through activation, restoration and rebuilds
Earlier checkpoints to repeat: Whole-screen stability, at-least-half opacity, feathering, zoom-relative sizing and near/far geometry independence
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 8
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v7 / production player and perspective follow-camera
Settings changed (before → after): Visible mesh alternately cast opaque/transparent shadows → visible mesh never casts shadows while a separate shadows-only node continuously shares its generated geometry and original materials
Automated results: Visibility and assembled-playground suites pass 67 focused assertions covering stable shadow ownership before/during fade, rebuild synchronization and source-shadow restoration when the optional experiment is removed. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,745 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected shadows to retain the same silhouette and presence across obstruction activation and restoration / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Repeatedly cross the obstruction boundary under the player headlamp and directional light, watching only the platform/pyramid shadow before rechecking the accepted aperture behavior
Earlier checkpoints to repeat: Whole-screen stability, at-least-half opacity, continuous feather, player-relative zoom sizing and near/far geometry independence
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 9
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v7 / production player and perspective follow-camera
Settings changed (before → after): Stable shadows and accepted player-relative aperture with the ordinary opaque character visible through it → trial configuration
Automated results: The stable-shadow revision passed 67 focused assertions before this character-presentation review
Human observations (expected / actual): Expected an intentional x-ray view / the fully filled opaque character resembled ordinary rendering with the depth buffer disabled
Decision: Changes requested
Follow-up checklist items: Fade only the imported character fill while obstructed; preserve ordinary player rendering while clear; leave contact shadow and effects alone; retain an outline-only overlay as fallback
Earlier checkpoints to repeat: Shadow stability, whole-screen stability, feathering, zoom-relative sizing and obstruction opacity
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 9
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v8 / production player and perspective follow-camera
Settings changed (before → after): Opaque character seen through the faded floor → imported character surfaces temporarily use a 35%-opaque depth-independent x-ray material; clear sightlines restore authored overrides
Automated results: Visibility and assembled-playground suites pass 72 focused assertions covering actual imported-player surface discovery, clear/obstructed/restored material ownership, x-ray opacity/depth contract and isolation from the contact shadow. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,750 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected a lighter ghosted character fill that reads as an intentional x-ray rather than a depth-test failure / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Cross behind the 1m platform slowly and compare the character fill before, during and after obstruction; if it still reads incorrectly, revert the fill pass and trial an outline-only overlay
Earlier checkpoints to repeat: Shadow stability, whole-screen stability, at-least-half obstruction opacity, continuous feather and player-relative zoom sizing
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 10
Date / tester / revision: 2026-09-09 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v8 / production player and perspective follow-camera
Settings changed (before → after): Per-surface transparent x-ray materials → trial configuration
Automated results: The per-surface revision passed 72 focused assertions before this internal-depth review
Human observations (expected / actual): Expected a coherent translucent silhouette / rear character surfaces remained visible through nearer arms and body because transparency was applied independently to every face
Decision: Changes requested; one final filled-silhouette trial before the retained outline fallback
Follow-up checklist items: Render the player normally into an isolated transparent viewport, then alpha-composite that resolved image once; never replace authored player materials
Earlier checkpoints to repeat: Character readability, shadow stability, whole-screen stability, at-least-half obstruction opacity, continuous feather and player-relative zoom sizing
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 10
Date / tester / revision: 2026-09-09 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v9 / production player and perspective follow-camera
Settings changed (before → after): Character faces independently faded to 35% → authored character rendered with normal internal depth into an isolated transparent viewport, then its completed image composited once at 35%
Automated results: Visibility and assembled-playground suites pass 75 focused assertions covering capture isolation, authored-material preservation, obstruction-only camera-layer switching, single-pass composite opacity and exact layer restoration. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,753 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected a translucent but internally solid character silhouette, with arms correctly occluding the body instead of showing through it / awaiting retry
Decision: Awaiting final filled-silhouette retry; use the retained outline fallback if this presentation is still unsuitable
Follow-up checklist items: Walk behind the 1m platform and inspect overlapping arms/body while moving; confirm clear rendering, FloorSurface shadows, aperture feather and opacity remain unchanged
Earlier checkpoints to repeat: Shadow stability, whole-screen stability, at-least-half obstruction opacity, continuous feather and player-relative zoom sizing
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 11
Date / tester / revision: 2026-09-10 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v9 / production player and perspective follow-camera
Settings changed (before → after): Depth-resolved SubViewport character composite at 35% opacity → trial configuration
Automated results: The viewport-composite revision passed 75 focused assertions before this contrast and transition review
Human observations (expected / actual): Expected the resolved translucent character to remain readable / the character disappeared against dark walls, and partial obstruction caused an abrupt gray rendering change
Decision: Rejected together with the earlier scenery-fade and transparent-character approaches
Follow-up checklist items: Leave every source render untouched; draw an opaque high-contrast player silhouette only at pixels where ordinary opaque scene depth is closer than the player
Earlier checkpoints to repeat: Clear player rendering, dark/light obstruction contrast, partial overlap stability and shadow stability
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 11
Date / tester / revision: 2026-09-10 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v10 / production player and perspective follow-camera
Settings changed (before → after): Transparent viewport composite plus FloorSurface fade → two fully opaque unshaded player-only passes, using scene-depth rejection for a deep fill and bright expanded outline; no FloorSurface, camera or authored-player mutation
Automated results: Player-silhouette and assembled-playground suites pass 52 focused assertions covering isolated geometry copies, authored overlay preservation, source transform/visibility synchronization, solid depth-only shader contracts, comparison disable and teardown. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,730 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected ordinary rendering everywhere visible and a stable high-contrast silhouette only over hidden player pixels / awaiting retry
Decision: Awaiting human retry
Follow-up checklist items: Cross the 1m platform edge slowly, pause half-obscured, then repeat against the dark pyramid and multiple camera views; confirm the wall never changes and only hidden character pixels gain the two-tone silhouette
Earlier checkpoints to repeat: Clear player rendering, dark/light obstruction contrast, partial overlap stability and shadow stability
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 12
Date / tester / revision: 2026-09-10 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v10 / production player and perspective follow-camera
Settings changed (before → after): Player-only solid depth silhouette → trial configuration
Automated results: Headless structural suites passed 52 assertions, but did not compile the Forward Plus shaders
Human observations (expected / actual): Expected a two-tone silhouette over hidden player pixels / no silhouette or visible change appeared when occluded
Decision: Broken implementation; reproduce in the real renderer before another human retry
Follow-up checklist items: Compile and execute both shaders under Metal Forward+, then measure hidden, partial and clear pixel output without writing rendered assets
Earlier checkpoints to repeat: Any visible silhouette while hidden, no overlay while clear, partial overlap and unchanged scenery
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 12
Date / tester / revision: 2026-09-10 / Codex automated and Forward Plus checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v10 / Metal Forward+ in-memory render probe plus production-player assembled fixture
Settings changed (before → after): Invalid stage-built-in references and manual depth comparison → compiling solid shaders using inverted hardware depth, view-space source separation and expanded front-face outline
Automated results: The real renderer exposed the original SCREEN_UV and INV_PROJECTION_MATRIX compile failures. After correction, a 3840x2160 in-memory probe measured 99,856 changed/1,260 outline pixels fully hidden, 96,064/922 partially hidden and exactly 0/0 clear. Structural player-silhouette and assembled-playground suites pass 52 assertions. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,730 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected a stable solid silhouette only over hidden player pixels, with no effect while clear / awaiting retry
Decision: Awaiting human retry after real-renderer verification
Follow-up checklist items: Cross behind the 1m platform, pause partially hidden and repeat at the dark pyramid; verify the solid fill/outline appearance rather than basic effect activation
Earlier checkpoints to repeat: Dark/light contrast, partial overlap stability, unchanged scenery and unchanged shadows
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 13
Date / tester / revision: 2026-09-10 / user / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v10 / production player and perspective follow-camera
Settings changed (before → after): Compiling solid depth silhouette using duplicated skinned player meshes → trial configuration
Automated results: The controlled single-mesh Forward Plus probe passed hidden, partial and clear states, but had not exercised the six-piece production character
Human observations (expected / actual): Expected unchanged ordinary player rendering / the unobstructed production character appeared corrupted
Decision: Broken implementation; duplicated skinned geometry is not safe, and player self-occlusion must be distinguished from scenery occlusion
Follow-up checklist items: Remove geometry duplication, use the authoritative animated meshes, and stencil-mark their visible frontmost pixels before drawing the obstruction silhouette
Earlier checkpoints to repeat: Pixel-identical clear character, visible hidden silhouette, partial overlap, dark/light contrast and unchanged scenery
Evidence or feedback report path: User report in conversation; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 human-trial revision 13
Date / tester / revision: 2026-09-10 / Codex automated and Forward Plus checks / f0ac3d8 + working tree
Fixture and camera view: M7 player-visibility-v10 / Metal Forward+ production-player and controlled depth probes
Settings changed (before → after): Six independently duplicated skinned meshes → three ordered passes on each authoritative animated mesh: invisible visible-pixel stencil mark, solid expanded outline and solid fill rejected by both stencil and inverted depth
Automated results: The production-player probe first reproduced 13,506 incorrectly changed clear pixels. After the stencil/authoritative-mesh change, the same 3840x2160 clear comparison changed only 5 of 8,294,400 pixels while the hidden player changed 22,394. The controlled probe remains exact: 99,856/1,260 fill/outline pixels hidden, 96,064/922 partially hidden and 0/0 clear. Structural suites pass 51 assertions. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,729 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected the production character to remain visually intact while clear and gain the silhouette only behind scenery / awaiting retry
Decision: Awaiting human retry after production-player Forward Plus verification
Follow-up checklist items: Observe the unobstructed player while idle and walking, then cross the 1m platform edge and dark pyramid; judge visual quality only if the base character remains intact
Earlier checkpoints to repeat: Pixel-identical clear character, dark/light contrast, partial overlap stability, unchanged scenery and unchanged shadows
Evidence or feedback report path: Not created yet; standalone playground has no gameplay recording
```

```text
Milestone / trial: M7 Forward Plus human trial 14
Date / tester / revision: 2026-09-10 / user / f0ac3d8 + working tree
Fixture and camera view: Production Level 1 and Level 2 / ordinary gameplay camera
Settings changed (before → after): Root-level silhouette instance added only to Level 1 → trial configuration
Automated results: Earlier renderer probes showed compatible opaque depth-writing GridMaps, but did not verify that every level instantiated the player visibility component
Human observations (expected / actual): Expected the same obstruction silhouette across populated scenes / Level 1 worked, while Level 2 had no silhouette
Decision: Per-level integration rejected
Follow-up checklist items: Compose the separate visibility component into the shared player and remove the Level 1-specific scene edit
Earlier checkpoints to repeat: Level 1 and Level 2 GridMap obstruction, clear player rendering and floor playground comparison
Evidence or feedback report path: Latest Level 1 directed gameplay recording plus user report in conversation
```

```text
Milestone / trial: M7 integration revision 14
Date / tester / revision: 2026-09-10 / Codex automated checks / f0ac3d8 + working tree
Fixture and camera view: Shared production player used by the floor playground and every mapped gameplay level
Settings changed (before → after): Optional root-level component in selected scenes → one removable child component in player.tscn targeting its own imported character subtree
Automated results: Player, silhouette-component and assembled-playground suites pass 63 assertions. Metal Forward+ probes using only the shared player instance produce the hidden silhouette in both Level 1 and Level 2 and effectively no clear-state output. The committed Level 1 scene has no visibility-specific diff. ./check.sh validates 194 text-resource UIDs, 120/120 scenes and 239 script/test pairs; 247 suites report 2,731 passing assertions before the pre-existing Tutorial 3 GDKillBoundary3D teardown failure.
Human observations (expected / actual): Expected Level 2 and future levels to inherit the same effect without scene edits / awaiting cross-level retry
Decision: Awaiting human retry
Follow-up checklist items: Verify one genuine GridMap obstruction in Level 1 and Level 2, then spot-check a tutorial scene
Earlier checkpoints to repeat: Hidden fill/outline, unchanged visible player, partial overlap and unchanged scenery
Evidence or feedback report path: No new marker; structural integration checks and user report in conversation
```

## Deferred until a separate integration plan

After every final acceptance item passes, the prototype is ready for integration planning. That future plan must cover the PNG-generated floor path; existing floor-plane/GridMap migration; main scenery/GridMap grounding; navigation, enemies and gameplay consumers of the API; real-player and encumbrance tuning; the production camera/rendering setup; one representative converted level; and a rollback path before bulk conversion. Passing this plan does not itself authorize or start those changes.
