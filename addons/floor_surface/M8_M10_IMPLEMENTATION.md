# Floor Surface M8–M10 Implementation Notes

## Scope and accepted visibility approach

The original milestones remain isolated in `addons/floor_surface` and the standalone playground.
Four Towers additionally opts into native GridMap brush grounding through
`floor_surface_placement_gridmap.gd`; other placement GridMaps keep their existing behavior.

The accepted visibility implementation is the player-owned dark fill and bright outline already composed into `player/player.tscn`. The earlier plan language about fading scenery is superseded: FloorSurface and GridMap geometry, materials, shadows, and render layers remain unchanged.

## Grounding contract

`FloorSurfaceGrounding` is placed as a child of an ordinary editable `Node3D` and explicitly references its `FloorSurface`.

- **Upright** uses world up and the configured heading.
- **Align Normal** uses the authoritative sampled ramp normal and the configured heading projected onto that surface.
- **Absolute** preserves the complete authored transform.
- `height_offset` is measured along world up. This keeps X/Z placement stable on slopes and makes repeated conform operations idempotent.
- Floor rebuilds mark non-absolute objects stale but do not move them. **Conform Grounded Objects** moves all valid targeted objects as one undoable action; objects over holes are skipped and reported rather than moved to zero height.

## Native placement GridMap brush

Four Towers' `PlacementGridMap` keeps Godot's mesh palette, brush, orientation,
eraser, and scene undo history. Its tool script observes completed **GridMap Paint**
actions and anchors newly painted layer-zero items to the lowest support under
their rotated, scaled mesh bounds, including the authored mesh base offset.
The minimum is sampled over each intersected floor cell, so a lower interior
support is retained even when the outer footprint corners are higher. Height
rounds downward to the GridMap's 1 cm vertical step. Pieces stay upright and
intersect uphill floor instead of floating above downhill floor. The
correction merges into that same action through `EditorUndoRedoManager`, including
the original contents of any replaced cells. Eraser coordinates are observed by
the existing Floor Surface editor plugin without consuming native input, so the
eraser can also remove items moved above layer zero.
Repainting replaces recognized placements from the earlier centre-height rule;
undo restores the original placement without leaving a second copy behind.

The same edit/undo hook also watches the histories owning the floor map and
elevation profile. It retains one detached, editor-only snapshot of the previous
floor. After a geometry-affecting edit is committed, cells seated on that previous
surface are reseated against the current floor and merged into the floor edit's
own history. This covers Floor Surface strokes and Inspector resource changes,
including shared resources in global history. Undo/redo restores both floor and
scenery, then refreshes the snapshot without initiating another edit. Shared-resource
corrections also mark the active owning scene unsaved so its moved cells can be saved.

Style-only edits do not move scenery. Loading or reopening a scene establishes
the query baseline without moving saved cells. There is no per-object grounding
metadata or continuous floor polling. Disable **Follow Floor** to freeze placement;
pieces with a manual offset from their previous support keep their authored height.
Missing floor, occupied destinations, incompatible transforms, and heights outside
the GridMap's coordinate range preserve placements and report a warning.
The helper never edits the shared MeshLibrary or floor map. Other levels are not
opted into this behavior.

## Fill and recovery contract

All fills are four-connected and bounded by the current finite storage rectangle.

- Shape fill matches the seed's floor/hole state.
- Elevation fill matches present tiles at the seed's exact integer elevation.
- Style fill matches both the seed's style and floor/hole state, so a fill does not leak between a pit and its rim.

The persistent diagnostics report surface resources, style/material configuration, transforms, invalid slopes, stale grounding, and grounding over holes. **Repair Safe Issues** only converts currently invalid ramps to Flat; it preserves elevations and every unrelated authoring choice in one undoable change.

FloorSurface deliberately performs a complete deterministic rebuild after authoritative map changes. This already covers changed cells, neighbouring ledges, ramp sides, pits, collision, and signal-driven consumers without dirty-border omissions. Geometry is batched by style and face material. Chunking was not introduced for the prototype-sized maps because its invalidation complexity was not justified by the measured rebuild.

## Final playground route

The test route starts at any of four cardinal low landings, follows a one-cell-wide six-tile slope, and reaches the shared 6 m summit. The six-metre run stays within the production player's 45-degree floor limit. Unpainted terrace boundaries remain blocked ledges, so the authored routes are the continuous way up.

The standalone map is 16 × 22 stored cells with 324 present tops. A headless Forward+ fixture rebuild on 2026-09-10 took 38.233 ms and produced five material-batched mesh surfaces. The working editor-responsiveness target for this prototype size is less than 100 ms per complete rebuild on the development machine; the measured result leaves enough margin without chunking.

The fixture retains the central styled pit, walkable step, normal jump, unencumbered-only jump, blocked ledge, independent simple ramp, three grounding modes, both floor styles, production player, production camera, and the accepted silhouette renderer. A separate editable GridMap beside the pyramid places six graveyard wall cells on floor heights from 0m to 1.25m in quarter-metre steps. Its vertical cell unit deliberately matches the FloorSurface elevation profile, so each wall's authored Y coordinate is also its supporting floor elevation. The graveyard GridMap correction profile joins cardinal neighbours within 0.3m vertically: running the real correction operation produces opposed `WallEnd` pieces at the exposed ends, retains four straight interiors, and then reaches an unchanged second pass.

World-space instructional labels were removed after the fixture gained named trial starts and its optional HUD. This leaves the floor, wall bases, ramps, and player unobstructed during visual inspection. The fixture opens at the gradient-wall start; press `T` for the remaining trials and `H` only when diagnostics are needed.
