# Crumbling floor

Instance `crumbling_floor.tscn` in a level. Its intact visual comes from
`Assets/environment/flagstone.glb`; each mesh block in that asset becomes one
falling box. The current asset contains **16 blocks**, rather than the original
plan's nine. Block names and material names do not affect the behavior.

## Placement in the editor

**Auto Place** is enabled by default. The scene's `@tool` script handles placement;
there is no custom placement plugin or toolbar.

1. Open the level and select its **FloorSurface**. Enable **Show Grid / Checker
   Guide** if you want a visible guide. Choose flat cells; ramps are unsupported.
2. Make the trap opening with the Floor Surface tools: enable **Enable Viewport
   Painting**, choose **Floor Shape**, select **Erase / make hole**, and use
   **Rectangle** to erase the whole corridor or patch in one drag. Set elevations
   before erasing; holes retain that intent. Skip this step for existing holes,
   then turn viewport painting off.
3. Drag `res://placeables/traps/crumbling_floor/crumbling_floor.tscn` into the
   level near the target cell. When the drop settles, the tile finds the level's
   FloorSurface, adopts its cell size, centres itself on the containing cell,
   and matches the lowest of the eight adjacent flat floor cells.
4. Duplicate the tile and move copies along the corridor. Horizontal moves snap
   again when released, so copies do not need separate floor assignments or
   height-button clicks. You can duplicate and move a whole row or group too.
5. Adjust **Transform > Position > Y** for unusual cases. Vertical-only changes
   remain as authored. Another horizontal move recalculates height; turn off
   **Auto Place** for completely manual positioning.
6. Use **Save Map** in the Floor Surface dock and save the level. Test that
   stepping onto each tile triggers collapse and exposes the opening beneath.

For a two-cell-wide corridor, place one tile in each column, select both,
duplicate the pair and move the copies to the next row. Built-in **Use Snap**
with a translation increment equal to the cell size helps move rows by exact
cell distances. Tile placement also corrects the floor's cell-centre offset.
Keep tile rotation zero, scale `(1, 1, 1)`, and use unscaled grouping parents.

If no adjacent flat floor remains inside a large opening, the tile uses its
own cell's retained authored height. Neighboring holes, pit bottoms and ramps
are not treated as supporting flat floor. Overlapping FloorSurfaces require
an explicit **Floor Surface** assignment in the Inspector; outside cells and
ramp targets leave the transform unchanged and show a configuration warning.
Assigning a floor or re-enabling **Auto Place** requests another placement.

Automatic corrections are appended to the editor's current action when Godot
can merge it, so ordinary placement and movement undo/redo together. Undo/redo
does not trigger another snap. Opening a saved level preserves its existing
placements and manual heights. Editor placement is disabled during gameplay.

Floor occupancy remains owned by the floor module: placing tiles does not erase
ordinary floor or change its elevations or materials. Remove the permanent
floor beneath the trap explicitly, so collapse opens a real hole.

**Match Floor Height** remains available for an explicit height-only correction
to the target cell's retained elevation. This action preserves X/Z and uses
normal editor Undo/Redo, including for raised and below-zero floors. Use it
after changing floor elevation if you want to update an existing tile.

An optional **Floor Grid Map** can supply tile dimensions instead of the
FloorSurface; its X/Z dimensions take priority. The tile origin is the walkable
top; its 0.25-metre thickness extends below that plane. Without either reference,
a tile stays one metre wide and can be manually positioned with **Auto Place**
disabled.

## Gameplay and settings

A grounded step by an existing `player`-group CharacterBody3D starts the warning.
A short ray beneath the feet confirms support from this tile, including during
floor snapping when the player has no fresh slide collision. Side contact,
airborne overlap and support from neighboring floor do not count. **Jumping over
the tile without landing leaves it intact.** Landing starts collapse, and the
player can still jump away.

After a brief warning, individual blocks fall in a shuffled order at staggered
intervals. A local seeded random generator gives neighboring tiles different
patterns while retaining repeatable replays. Each block loses its own collision
and visual when it falls; remaining blocks still provide real support. Once a
grounded step triggers the tile, leaving cannot cancel or reset the collapse.
The existing player gravity and fall-death handling take over as support vanishes.

The Inspector exposes collapse delay (0.05 seconds), time between falling blocks
(0.015 seconds), debris lifetime per block (3 seconds), scatter (0.5), angular
strength (2), fracture seed (0), and an optional shared floor material. Seed zero
derives a stable pattern per tile; a nonzero seed explicitly selects a repeatable
order and fragment motion. All 16 blocks disappear in roughly 0.275 seconds after
activation, plus physics tick rounding. The default timing is tuned for a narrow
escape margin at normal, unencumbered walking speed. Collapse
is permanent until the level restarts. Falling fragments collide with environment
layer 1, but cannot obstruct players or one another.

The single positional sound is `Assets/audio/floor-crack.mp3`. It plays once as
soon as a grounded step or landing activates the tile, through the project's SFX
bus. Jumping over without landing plays no floor cue. There are currently no
separate creak or collapse sound triggers.

Missing audio is silently skipped. The shared audio loader can read the supplied
MP3 without importing or modifying it. Debris cleanup leaves its audio player
alive, so the crack can finish playing.

## Scene size and runtime ownership

Each intact tile is a single `MultiMeshInstance3D` with no children. Its blocks
share one box mesh and a cached layout derived from the asset. The debug level's
14 tiles use 16 nodes including their grouping node and one shared contact
monitor, down from 575 nodes. Selecting and moving a tile still uses its authored
scene root and the same Inspector settings.

An intact tile has one static support body and one shape managed by
`PhysicsServer3D`. The first release replaces that shape with individual block
shapes, allowing support to disappear progressively. Completing the collapse or
removing the tile frees the support body. No collision-shape or trigger nodes
remain attached to untouched tiles.

One contact monitor per physics world checks player support; intact tiles have
no individual runtime frame or physics callbacks. The monitor unregisters removed
or activated tiles and frees itself after the last registration disappears.
Layouts, source materials, meshes and shapes are shared while tiles exist and
released when their owners disappear.

Falling pieces retain their ordinary short-lived rigid bodies, collision,
scatter, spin and cleanup timing. These nodes are created only when each block
falls. This keeps the existing falling effect while reducing the permanent cost
of placing many traps.

The source GLB is read in memory during development, without reimporting or
rewriting it. Exported games load Godot's packaged imported scene. The existing
`Assets/environment/flagstone.tscn` text wrapper uses the same visual loader, so
it can also be previewed before the new asset's first local import. No binary
assets are changed. Prototype debris uses axis-aligned BoxMeshes and BoxShapes
fitted to the authored mesh blocks; arbitrary non-box fracture meshes are outside
this prototype's scope.
