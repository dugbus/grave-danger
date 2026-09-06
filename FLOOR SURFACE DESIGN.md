# Grave Danger — Standalone Floor Surface System Specification

## Purpose

Build a reusable 2.5D floor/elevation system for Godot 4.7 that can eventually replace Grave Danger's inconsistent mixture of large textured floor planes and floor GridMaps.

The first implementation **must not modify or integrate with existing Grave Danger levels**. It must be developed and proven in an isolated test scene so the system can be iterated on aggressively without risking the game.

The system is responsible for:

- floor occupancy and holes;
- discrete authored elevation;
- ramps/other explicit transitions between elevations;
- configurable top, exposed-edge and pit-bottom appearance;
- collision and surface sampling;
- grounding placed objects onto the authored surface;
- preserving player readability when elevated geometry passes in front of the player in the 2.5D camera;
- editor tooling that makes all of the above fast to author.

The central design rule is:

> Humans author gameplay surface intent. Geometry, collision, materials, exposed depth, grounded placement and visibility behaviour are derived consequences.

---

## 1. Standalone prototype first

Create the system as an isolated scene/toolset, with no dependency on the existing Grave Danger floor implementation.

A suggested initial structure is:

```text
floor_surface/
    floor_surface.tscn
    floor_surface.gd
    floor_map.gd
    floor_style.gd
    floor_elevation_profile.gd
    floor_surface_editor_plugin.gd
    shaders/
    test/
        floor_surface_test.tscn
        floor_surface_test_player.tscn
```

The test scene must contain its own camera, controllable CharacterBody3D test player, lighting and sample materials. Existing Grave Danger scenes may be inspected for conventions, but they must not be changed during the prototype phase.

Integration with Grave Danger is the **last milestone**, after the test scene demonstrates that authoring, movement, jumping, pits, slopes, object placement and 2.5D visibility all work satisfactorily.

---

## 2. Authoritative floor data

`FloorSurface` owns an authoritative 2D `FloorMap` aligned to a configurable X/Z cell grid.

Each cell contains approximately:

```text
present: bool
absolute_elevation: int
style: int
transition: Transition
```

`present == false` means there is no walkable top surface at that cell: it may be a hole, pit or outside the authored floor.

### Absolute elevation is quantised, not arbitrary

Do not store free-form floating-point heights per cell. Store an integer elevation in fixed vertical units:

```text
world_y = absolute_elevation * elevation_unit
```

For example, if `elevation_unit = 0.25m`:

```text
0  = 0.00m
1  = 0.25m
2  = 0.50m
...
24 = 6.00m
```

This permits genuinely tall structures such as a 6m stepped pyramid while preventing accidental centimetre-level variations.

The designer authors **absolute world elevation**, while gameplay interprets the **difference between neighbouring elevations**.

---

## 3. Traversal profile is separate from elevation

Do not encode concepts such as `JUMPABLE` or `BLOCKED` as absolute heights. They describe an elevation **delta**.

A project-wide `FloorElevationProfile` maps vertical differences to gameplay meaning. Example values only:

```text
0 units      flat
1 unit       walkable step
2 units      normal jump
3 units      unencumbered-only jump
4+ units     blocked ledge
```

These thresholds must be tuned against the actual player controller before Grave Danger integration.

Therefore these two edges are gameplay-equivalent:

```text
0.00m -> 0.50m
5.00m -> 5.50m
```

Their absolute elevations differ, but their local elevation delta is identical.

This guarantees consistent jump design throughout the game while allowing structures to be arbitrarily high in world space.

---

## 4. Explicit transitions: ramps and stairs

A difference in elevation normally produces a ledge. Continuous movement between levels is allowed only where an explicit transition exists.

Initial transition data should support at least:

```text
FLAT
RAMP
```

with room for later additions such as:

```text
STAIRS
LADDER
DROP
```

A ramp records its orientation/low edge. Its start and end elevations should normally be inferred from neighbouring floor cells.

Initially, ramps should connect adjacent authored elevation bands only. Multi-level ramps are represented as a sequence of locally simple transition cells.

Example:

```text
level 0 -> ramp -> level 1 -> ramp -> level 2 -> ramp -> level 3
```

The player sees one continuous route while the floor data remains simple and deterministic.

### Stepped-pyramid acceptance case

The prototype must support a stepped pyramid whose centre/top is approximately 6m above its base.

Each terrace is authored at a progressively greater **absolute elevation**. Terrace edges are vertical and non-traversable except where explicit ramps are painted.

A one-cell-wide ramp route up a side consists of successive transition cells connecting each terrace. Four such routes may be painted, one on each side.

This is a required stress test because it proves that:

- tall world-space structures are possible;
- traversal depends on local height differences, not absolute height;
- ledges and ramps can coexist along the same terrace boundary;
- ramps can form a continuous route across many absolute elevation levels.

---

## 5. Configurable floor appearance

Gameplay geometry and appearance must remain independent.

`FloorSurface` exposes a palette of reusable `FloorStyle` resources. A style should contain at least:

```text
top_material: Material
edge_material: Material
pit_bottom_material: Material
pit_depth: float
```

Optional later properties may include normal strength, texture scale, edge tint, rim treatment or pit darkness.

Top materials should support continuous world-space X/Z texture projection so tiles do not visibly restart their UVs at cell boundaries.

Exposed vertical surfaces should use an appropriate world-space/triplanar projection so arbitrary ledge and pit depths do not require hand-authored UVs.

The same elevation geometry must work with dirt, grass, stone, crypt floor or other styles without creating geometry variants for every combination.

---

## 6. Generated geometry and collision

The authored `FloorMap` is the source of truth. Rendering and collision are generated from it.

A rebuild must:

1. Generate top floor geometry at each cell's absolute elevation.
2. Generate appropriate collision.
3. Generate ramp geometry/collision for transition cells.
4. Inspect neighbouring cells and create exposed vertical faces wherever a surface meets a hole or a lower neighbour.
5. Generate triangular/trapezoidal exposed sides beside ramps where required.
6. Generate optional visible pit-bottom geometry below holes using the configured style/depth.
7. Update any derived elevation/visibility data used by shaders or gameplay.

A pit is not a special object. It is absent floor surrounded by present floor. The same edge-generation rules should handle pits, cliffs, terraces, raised platforms and sunken areas.

Generated geometry should be batched/chunked where practical rather than creating one scene node per face.

---

## 7. Surface query API

Other systems must not directly interpret `FloorMap` internals. `FloorSurface` should expose a small authoritative API, for example:

```text
has_floor(cell)
get_cell_elevation(cell)
get_world_height_at_cell(cell)
sample_surface(world_position)
```

`sample_surface()` should return enough information for placement and gameplay, such as:

```text
valid
world_height
surface_normal
cell
style
transition
```

On ramps, `world_height` must represent the actual interpolated sloping surface rather than simply returning the cell's base elevation.

---

## 8. Grounded object placement

The eventual system must support objects in Grave Danger's main placement/GridMap workflow without assuming Y=0.

Objects should support grounding modes such as:

```text
GROUND_UPRIGHT
GROUND_ALIGN_NORMAL
ABSOLUTE
```

`GROUND_UPRIGHT` follows sampled floor height while staying vertical and should be the normal scenery behaviour.

`GROUND_ALIGN_NORMAL` follows both the surface height and normal, useful for rubble, decals and similar objects on slopes.

`ABSOLUTE` ignores FloorSurface.

Changing an authored elevation must not silently leave previously grounded objects floating. The future integration must therefore provide a **Conform Grounded Objects** operation that resamples the floor and updates grounded placements while preserving any explicit offset.

This behaviour should be demonstrated in the standalone test scene before integration work begins.

---

## 9. Authoring tooling and workflow

The editor workflow is a core deliverable. Editing individual cell properties through the Inspector is explicitly unacceptable.

Create a dedicated Floor Surface editor mode operating directly in the Godot 3D viewport.

### Shape tool

Supports:

- paint floor;
- erase floor / create holes;
- brush sizes;
- rectangle fill;
- flood fill.

### Elevation tool

Supports:

- set selected cells directly to an absolute elevation;
- raise by one elevation unit;
- lower by one elevation unit;
- sample elevation under the cursor;
- brush, rectangle and flood-fill operations.

The UI should display both units and physical height, for example:

```text
Elevation 24 — 6.00m
```

Designers must never need to click Raise twenty-four times to make a 6m structure.

### Elevation visualisation

While editing, apply a temporary false-colour overlay so elevations remain instantly readable regardless of the actual floor material or lighting.

Hovered/selected cells should be able to show their elevation number and world height.

### Terrace workflow

Provide fast support for nested raised regions. At minimum, rectangle/fill elevation painting should make this efficient. A later dedicated terrace/inset tool is desirable if it materially improves authoring.

A designer should be able to create a stepped pyramid by rapidly assigning increasing absolute elevations to nested areas rather than manipulating individual tiles.

### Transition tool

The designer drags across or along an elevation boundary to author a ramp connection.

The tool should infer orientation from neighbouring elevations rather than requiring the designer to manually choose north/east/south/west wherever possible.

Dragging a route across multiple terraces may create a chain of ramp cells automatically.

### Style tool

Paint `FloorStyle` using the same brush, rectangle, sample and flood-fill workflow.

Changing dirt to stone should not require changing geometry or rebuilding the level structure manually.

### Undo and validation

A complete brush stroke must be a single undo/redo action.

The tool should flag invalid topology such as:

- transition with no meaningful lower/higher neighbour;
- unsupported elevation change across a ramp;
- grounded object over absent floor;
- missing style/material resource;
- generated slope outside the player controller's supported movement limits.

Prefer visible editor warnings and repair actions over runtime surprises.

---

## 10. 2.5D player visibility through elevated terrain

Elevation introduces a new failure mode for Grave Danger: raised floor/ledge geometry can pass between the fixed 2.5D camera and the player and completely hide the character.

The floor system is not considered usable until this case is solved.

### Required behaviour

When elevated floor geometry obstructs the camera's view of the player, the obstructing portion of that geometry must become partially or fully transparent around the player's screen-space position so the player remains readable while moving behind it.

The fade should:

- affect only geometry actually obstructing the player;
- have a configurable radius/soft edge around the player;
- transition smoothly rather than popping;
- restore full opacity when no longer obstructing the player;
- work with flat raised surfaces, vertical exposed faces and ramps;
- preserve the visual impression of the raised structure rather than simply hiding the entire object.

### Elevation/visibility texture

`FloorSurface` should generate a world-aligned elevation texture (or equivalent GPU-readable representation) derived from `FloorMap`. Each texel/cell records the authored top elevation in a form suitable for shader/visibility queries.

This texture should update when floor topology/elevation changes, not be expensively regenerated every frame when the floor is static.

The initial visibility prototype should investigate using this elevation representation together with:

- player world position;
- player screen-space position/depth;
- camera transform/projection;
- fragment/world position and/or viewport depth information;

to identify floor fragments that lie between the camera and player and fade those fragments.

Do **not** force a particular shader technique before the prototype proves it. The architectural requirement is that `FloorSurface` supplies the authored elevation data and the renderer reliably produces the required 2.5D visibility behaviour.

Transparency, sorting, shadows and interactions between top/edge materials must be tested explicitly in the prototype.

### Visibility test cases

The standalone test scene must let the player:

1. walk behind a 1m raised platform;
2. walk behind progressively taller terraces;
3. walk behind the 6m stepped pyramid from several sides;
4. walk up a ramp while portions of the ramp/pyramid overlap the player on screen;
5. move in and out of obstruction repeatedly to expose flicker, popping or sorting problems.

The test scene should display/debug enough information to understand why a surface is fading, including player position and optionally the generated elevation/occlusion texture.

---

## 11. Standalone test playground

`floor_surface_test.tscn` should be deliberately small but contain difficult cases rather than a decorative demo.

It should contain:

- normal flat ground;
- a hole with exposed dirt/stone sides and visible pit bottom;
- two or more FloorStyles;
- a small walkable step;
- a tuned jumpable ledge;
- a ledge intended to be jumpable only in a future unencumbered state;
- a clearly blocked ledge;
- a simple ramp;
- placed upright and surface-aligned objects;
- the approximately 6m stepped pyramid with restricted ramp routes;
- camera/player positions that deliberately cause elevated geometry to occlude the player.

Include lightweight debug UI showing at least:

- current floor cell;
- sampled world height;
- absolute elevation unit;
- local surface normal;
- neighbouring elevation delta/traversal classification;
- current transition type.

The test player does not need Grave Danger gameplay systems. It only needs enough movement/jumping behaviour to validate the floor system and tune the elevation profile.

---

## 12. Prototype acceptance criteria

The standalone system is ready for integration planning only when all of these are true:

- floor and holes can be authored quickly without per-cell Inspector editing;
- arbitrary tall structures can be created using quantised absolute elevations;
- jump/step/block behaviour is derived consistently from local elevation delta;
- explicit ramps are the only continuous route across otherwise blocked terrace boundaries;
- the 6m stepped-pyramid case works;
- top, exposed-edge and pit-bottom materials/depth are configurable;
- world-projected floor textures remain continuous across cells;
- collision matches generated tops, ledges and ramps;
- surface sampling returns correct heights/normals on both flat cells and ramps;
- test objects correctly conform to changed floor heights;
- the player remains readable behind raised geometry using the 2.5D occlusion/fade system;
- the authoring workflow has reliable undo/redo and useful validation;
- none of the prototype work requires modifying an existing Grave Danger level.

---

## 13. Integration is deliberately last

Only after the standalone system passes the acceptance criteria should a separate integration plan be produced for Grave Danger.

That later plan should cover:

- adapting/replacing the current PNG-generated floor path;
- migrating existing large floor planes and floor GridMaps;
- grounding the existing main GridMap/scenery system to FloorSurface;
- connecting navigation, enemies and gameplay to the shared surface API;
- tuning traversal thresholds against the real player and encumbrance mechanics;
- bringing the visibility/fade system into the real Grave Danger camera/rendering setup;
- converting one representative level before bulk migration;
- retaining a rollback path until the converted level is proven.

Do not start this integration as part of the initial implementation.

---

## 14. What Codex should plan

Produce an implementation plan for the **standalone prototype only**.

The plan should identify:

1. resources/data structures;
2. generated mesh/collision architecture;
3. editor plugin and painting workflow;
4. transition/ramp generation;
5. FloorStyle/material handling;
6. surface query API;
7. grounded test-object placement;
8. generated elevation texture and alternative approaches for player occlusion fading;
9. standalone player/camera test harness;
10. automated tests where practical;
11. staged milestones ending in the stepped-pyramid and 2.5D visibility acceptance tests.

Prefer small independently testable milestones. Do not modify existing Grave Danger levels or replace existing floor systems during this work.
