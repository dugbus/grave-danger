# Floor Surface M8–M10 Implementation Notes

## Scope and accepted visibility approach

These milestones remain isolated in `addons/floor_surface` and the standalone playground. They do not integrate grounding with production GridMaps or require per-level scene edits.

The accepted visibility implementation is the player-owned dark fill and bright outline already composed into `player/player.tscn`. The earlier plan language about fading scenery is superseded: FloorSurface and GridMap geometry, materials, shadows, and render layers remain unchanged.

## Grounding contract

`FloorSurfaceGrounding` is placed as a child of an ordinary editable `Node3D` and explicitly references its `FloorSurface`.

- **Upright** uses world up and the configured heading.
- **Align Normal** uses the authoritative sampled ramp normal and the configured heading projected onto that surface.
- **Absolute** preserves the complete authored transform.
- `height_offset` is measured along world up. This keeps X/Z placement stable on slopes and makes repeated conform operations idempotent.
- Floor rebuilds mark non-absolute objects stale but do not move them. **Conform Grounded Objects** moves all valid targeted objects as one undoable action; objects over holes are skipped and reported rather than moved to zero height.

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
