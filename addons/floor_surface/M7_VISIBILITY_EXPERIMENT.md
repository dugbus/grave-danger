# M7 player visibility experiment notes

Status: solid depth-silhouette implemented on the shared player for Forward Plus human evaluation;
visual acceptance is pending.

## Selected rendering approach

The current experiment does not alter `FloorSurface`, other scenery, the production camera, player
geometry or authored material resources. A separate player-owned component appends three rendering
passes to the authoritative imported character meshes, so the production skeleton, transforms and
blend shapes remain the only animation source.

An invisible first pass uses the ordinary depth test to stencil-mark only the frontmost player pixels
that are already visible. The following unshaded passes use Godot 4.7's inverted hardware depth test
and reject that stencil value. They can therefore draw where scenery is in front, but not where
another part of the six-piece production character is in front. A small view-space bias separates the
extra passes from their numerically identical authored surface. The first visible pass expands front
faces to produce a bright gold border; the second draws a deep blue-green fill over its interior.
Both are fully opaque. The combination makes the hidden character readable against dark scenery
through the bright edge and against pale scenery through the dark fill.

The decision is per pixel and the overlay remains armed continuously. A wall moving across only part
of the player therefore reveals only the hidden pixels; there is no centre-ray threshold that can
switch the whole player or wall between rendering states. Visible player pixels are supplied solely
by the original authored meshes. The `F` comparison control removes the extra rendering passes.

## Isolation and material contract

The component lives under `player/visibility/` and is composed into the shared `player.tscn`, so
ordinary gameplay levels receive the same behaviour without editing their scenes or GridMaps. The
M7 playground uses that player-owned instance instead of adding a second copy. If a mesh already has
a material overlay, the component duplicates that overlay chain before appending its own passes; it
never mutates the authored material resource. Comparison mode and teardown restore the exact original
overlay reference. An external system remains free to replace the runtime overlay, and teardown will
not overwrite such a later replacement. Render layers, geometry, transparency and shadow ownership
remain unchanged.

The effect works through opaque depth-writing obstructions. Transparent scenery that does not write
depth will not trigger the silhouette, which is intentional because the ordinary player should
already remain visible through it. The outline expands each imported mesh's front faces, so joints
between separately authored mesh pieces remain an explicit visual trial item.

## Rejected experiments

- Whole-object hiding was rejected because one batched FloorSurface can contain the entire level.
- Screen-door and transparent floor apertures were rejected after producing missing-looking scenery,
  hard edges, whole-screen fades, unstable shadows and incorrect apparent sizes across geometry
  depths.
- Player-relative transparent apertures still made the result depend on wall colour and caused
  partially obstructed transitions to read as rendering faults.
- Transparent character materials were rejected because rear arms and body surfaces remained visible
  through nearer character surfaces.
- Rendering the authored character into a transparent `SubViewport` resolved its internal depth, but
  the alpha composite disappeared against dark walls and visibly changed tone at partial obstruction.
- The retained elevation/occupancy encoder records the earlier elevation-guided comparison, but the
  selected silhouette does not consume it or rebuild any terrain data at runtime.

## Cost envelope

The experiment submits the imported character geometry three more times: one invisible stencil mask,
one expanded border and one flat fill. The visible passes are unlit and rejected by fixed-function
depth/stencil tests everywhere the player is already visible. It creates no full-resolution secondary
viewport, performs no floor material translation and does not rebuild static data each frame. Godot
4.7 describes stencil support as experimental, so engine-version validation remains part of future
integration. A meaningful frame-cost comparison still requires the human Forward Plus run.

## Trial checklist

Use `T` to select the 1 m platform, taller terrace, 6 m stepped pyramid and five-tile ramp starts.
Walk slowly across obstruction boundaries and pause with only part of the player hidden. Confirm that
visible player pixels retain the authored appearance, hidden pixels become a stable two-tone
silhouette, dark and pale walls remain unchanged, and shadows do not flicker. Circle both sides and
use `V` for the named camera angles. Press `F` to compare with no silhouette and `H` only if detailed
diagnostics are needed.
