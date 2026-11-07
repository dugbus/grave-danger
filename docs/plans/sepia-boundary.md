# Sepia kill-boundary mode

Status: presented as an **aged colour photograph through Sepia in the existing kill boundary Render Effect selector**, on both the original boundary and Kill Boundary 2. Level 1 selects this mode on its existing animated `KillBoundary3D`.

## Spatial rule

**By default, inside the kill boundary is sepia and outside remains in colour.**

Both boundary implementations expose **Sepia Inverted** in the Inspector. Enabling it keeps the enclosed interior in colour and puts the sepia safe view outside. The same flag reverses scene recolouring, threat/pickup concealment and player interaction filtering. It can change at runtime without moving the perimeter or resetting its timeline.

The boundary's selected sepia side is the abandoned view of the same continuously running world. It conceals threats and pickups and filters their interaction with the player. The coloured side shows the inhabited past, with its ordinary threats and rewards.

A player straddling the actual boundary is drawn partly sepia and partly coloured in the same frame. Each visible surface point determines its own treatment; the player's origin or percentage of overlap does not select one treatment for the whole model.

## Geometry and authoring

Sepia has no independent footprint, size, transform, rounding, path, or timeline. It consumes every point of the owning kill boundary's live canonical perimeter:

- The original boundary exposes the same `_get_boundary_points()` used for strips, collisions, and distance damage, transformed through its current animated BoundaryCenter.
- Kill Boundary 2 supplies its existing `get_boundary_world_points()` from its Geometry component.
- Translation, path travel, keyed size, scale, rotation, shape morph, runtime expansion, pause and removal all remain owned by the existing boundary.
- Both the rendering mask and interaction checks use this perimeter. They do not build or resample a separate rectangle or ellipse.
- The footprint extends through all heights. Up to four overlapping Sepia boundaries form a union of their individually selected safe sides; each can retain its authored segment count up to 128.

The existing selector keeps Flame, Ghost, and None at their original serialized values. Sepia is appended as the additional option. In Sepia mode the boundary's own lethal damage, solid blocking walls, flame/ghost artwork, and lethal proximity audio are disabled; its animation continues normally. Switching back restores the ordinary selected mode.

Shared tint, edge-feather and procedural veil settings live in `placeables/kill_boundary/sepia/sepia_boundary_settings.tres`. The SepiaMode child is an internal composed component of the boundary scenes, not a separately placeable region.

## Gameplay contract

| Subject | Selected sepia side | Selected coloured side |
| --- | --- | --- |
| Environment and player | Sepia treatment per surface point | Existing colour appearance |
| Enemies and threats | Concealed; no local player damage, forced encounter lock, pushing, or blocking | Ordinary appearance and interactions |
| Coins, treasure, keys, flasks | Concealed and unavailable to collect | Ordinary appearance and collection |
| Structural floors, doors and supports | Existing functionality | Existing functionality |
| Inventory, health and score | Retained; no automatic restoration or healing | Existing behaviour |

Enemies keep moving, pursuing, attacking, animating, spawning, and advancing their timers while concealed. Traps keep cycling. Coins and other loose objects keep their physics. World interactions between non-player objects continue. A threat emerges at its naturally advanced position and animation phase, without a resume step or extra rearming delay.

Local interaction checks sample the player's contact-side capsule surface and the source location. Expanded pickup radii cannot collect concealed items through the edge. Pending attack callbacks are checked before committing damage; a moving Sepia boundary can release a reserved player lock while the enemy animation continues. Actual death presentations remain irreversible.

Sepia does not create missing floor, repair collapsed ground, rewind damage, restore collected items, or duplicate rewards. Existing boundary potions act on the same boundary through their normal APIs, including pausing its motion, expanding its bounds, and removing it. Those operations do not pause enemies or pickups.

## Rendering

The scene pass spatially clips concealed threat and pickup surfaces before they write depth/colour, revealing scenery behind them. A following camera-space draw reconstructs world positions from depth and applies the sepia treatment only to the selected safe side. Each boundary reverses its signed distance before the union is formed when Sepia Inverted is enabled; clipping and recolouring share that mask. A narrow shared feather gives quick, reversible transitions without changing simulation timing.

The photograph retains the scene's RGB channel relationships through a shared soft highlight shoulder, then applies a nearly neutral raised black point and a mild warm paper white. Colour Retention defaults to 0.95, preserving the artist's hues. Photo Strength defaults to 0.55, blending the full print with the original scene to restore deeper blacks and richer contrast. Faint, stationary paper grain and gentle edge shading supply a quiet photographic texture. Moving scratches, vertical bars and exposure flicker have been removed. The existing Sepia selector, resources and scene paths remain compatible.

Depthless pixels are part of the photograph too. For empty map-edge background, the shader intersects the camera ray with each boundary's own live base height, then tests that point against that boundary's exact polygon and inversion. The resulting virtual footprint only assigns background pixels to a side; it draws no floor and writes no depth. Different-height boundaries, movement, inversion, perspective and orthographic cameras each retain their proper footprint. Void pixels far outside a footprint are rejected with its cached bounds before evaluating polygon edges.

The print has no animation clock. Paper tint, full-print black point, exposure, colour retention, Photo Strength, static grain and edge shading are shared resource controls. Photo Strength 0 preserves original RGB values while the region's gameplay concealment remains active; 1 applies the full faded print. The same blend applies to black geometry and depthless background. The separate perimeter veil keeps its own presentation-only animation.

The player and environment use the actual visible surface positions, giving a partial-body colour split at the real perimeter. This follows Godot's [depth-based post-processing approach](https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html).

The transparent passes share an explicit order: world photograph, boundary veil, message dimming, then lit screen text. Trigger messages and flask messages retain their existing 3D lighting and colours above the completed world image. Their camera-aligned geometry and dedicated lights bypass world concealment even when a message is attached to an enemy. Paused messages dim the treated world without obscuring their text; these overlays also bypass atmospheric fog.

An additional translucent time veil marks the exact live perimeter. Its world-space, layered procedural noise morphs into warm gold and parchment wisps, with a soft low ribbon and a fade toward the top. Shared veil opacity is 0.35 and brightness is 1.25, keeping the edge readable without a heavy glowing sheet. The veil is a visual child of SepiaMode, extruded vertically from the same boundary points; it has no separate footprint, collisions, lights or gameplay state. It draws after the sepia composite, depth-tested against the scene, so walls and the player naturally occlude it. Its local visual clock respects scene pause and never changes the boundary timeline or enemy timing. The opacity band and its brighter ribbon follow the real player's world-space feet height. On a raised platform, in a jump or while falling below the base, the shader extends the visible curtain vertically and concentrates its opacity beside the player. This changes no horizontal perimeter points and needs no per-frame mesh uploads. Culling bounds track the shader's vertical extent. With no player present the veil uses its authored base height, and removing or replacing the player releases the old tracking reference. Shared appearance settings control band height, tint, opacity, brightness, detail scale and morph speed.

Imported assets stay read-only. Instance-local adapters preserve Level 1's material inputs and custom shader code while adding spatial concealment. Associated threat lights are concealed without changing AI or audio clocks. Mode changes and removal release the overrides and player-only collision exceptions.

Godot's [3D screen copy excludes transparent geometry](https://docs.godotengine.org/en/latest/tutorials/shaders/screen-reading_shaders.html), so new transparent effect and occlusion-overlay families still require rendered review. Existing checks cover the opaque player/environment split, concealed threats, revealed background, and exposed transparent material blending.

## Level 1 and validation

`levels/1/level.tscn` uses its original `KillBoundary3D`, authored curve, animation, size, scale, rotation, and shape controls. Only its Render Effect selection changes to Sepia. The separate static region has been removed. Existing player placement, encounters, terrain, treasure and patrol tuning are retained.

Regression checks cover:

- Default and inverted safe-side membership on both boundary implementations, including partial player contact and mixed-region unions.
- Exact agreement with the original boundary's transformed collision/visual perimeter after movement, rotation, shape morph and expansion.
- Kill Boundary 2's canonical geometry at more than 32 segments, with no resampling.
- No boundary damage or solid perimeter walls in Sepia mode, while the boundary clock continues.
- Switching back to lethal modes, overlapping boundaries, boundary removal, and surviving-view handover.
- Continuous fixed-tick patrol position, animation, RNG and audio timing while concealed.
- Hidden collection and attacks, pending player locks, late spawns, collision cleanup, and transparent blending.
- Rendered height-following opacity above and below the base, player removal and culling after shader extrusion.
- Procedural veil alignment after transformed perimeter updates, in-place mesh reuse, mode cleanup and independently animated pixels.
- Rendered red, green and blue swatches verifying retained hues, gentle paper whites, neutral midtones, lifted blacks and tonal ordering.
- Empty map-edge background receiving the same black point as black geometry, with inversion, camera movement, boundary movement, elevation and different-height unions.
- Stable photographic pixels across frames, deeper default blacks than full strength, exact source colours at zero strength and unchanged perimeter points.
- Rendered pixels showing simultaneous colour and sepia on one model, normal exterior threats, and background revealed behind concealed threats.

After script changes, format changed paths, run focused boundary and sepia suites, perform rendered review, and run `./check.sh`. Human gameplay feedback can then refine presentation using the repository's replay workflow and readiness process.
