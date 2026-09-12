# Grave Danger Level-Design Lessons

This is a living set of evidence-backed lessons. Add a lesson when playtesting or editor feedback
changes how future levels should be designed or validated. Refine existing lessons instead of accumulating duplicate
rules. Keep level-specific coordinates and transient tuning out of this file.

## Route integrity

- A connected floor is not necessarily a designed route. Rooms need distinct purposes, controlled
  sight lines, and a sequence the player can read from the environment.
- A door standing in open floor is decoration, not a lock. Place lockable passages inside continuous
  GridMap barriers and test the neighboring collision cells for bypasses.
- “Completable to 100%” includes the entire journey through temporal hazards, not just objectives
  inside isolated safe poses. Trace a contiguous route through actual walls and obstacles, consuming
  keys in order and sampling the interpolated boundary with player clearance. Budget collection,
  banking, trap timing, and steering; respect carrying capacity. Check closed and opened passages
  against actual collision geometry. Distinguish this route model from a completed gameplay replay.
- Use the actual player scene's shape and offset for passage sweeps, not a guessed or enemy-sized
  capsule. Test return routes with dynamic blockers and dead enemies, not just empty cell centres.

## Pressure and boundaries

- A large boundary that changes by only a few units over a long interval reads as static. Movement
  must be legible relative to the current room and decision window.
- Whole-map ping-pong motion can make players wait for access. Prefer room-scale contractions as
  deadlines, short expansions that open the next district, and later contractions that close the
  previous district behind the player.
- Rounded boundaries need both meaningful rounding and enough perimeter samples for their scale.
  A low-rounding, low-segment large rectangle reads as corners cut off with straight lines.
- A passing slow collection route can hide long waits for faster players. Validate early arrivals,
  optional-branch skips, and pause/expansion pickups as well as 100% collection. A pause pickup
  becomes a penalty when it postpones the expansion needed to move forward. If this occurs,
  separate door/key access from trailing flame pressure instead of repeatedly stretching the clock.

## Enemy and hazard readability

- Open skeleton paths must disable wrapping and enable endpoint reversal. Otherwise the path follower
  teleports from its end to its start even though the authored line looks like a patrol route.
- A physics object should kill only when its motion visually explains the hit. Check minimum speed,
  whether the target is ahead of travel, and lateral distance from the object's travel lane.
- A fading or sinking enemy mesh does not remove its upright body collision. Death should release
  blocking immediately unless a visible, intentional corpse obstacle is part of the design.
  Close Escape's spike pocket exposed a dead zombie sealing the return opening invisibly.
- When an enemy stalls at an opening that appears wide enough, inspect its chosen GridMap layer
  as well as the collision geometry. Tiny negative foot-height errors can select the layer below
  the floor. If correcting this, snap only approximately equal cell boundaries and test genuine
  other-floor positions; do not flatten all navigation onto one height or retune crowd AI without evidence.
- Variety comes from changing the player's verb, not merely moving identical traps. Use concentrated
  hazard identities—for example a timed spike vault, a pursuit room, or a rolling-object shortcut—
  instead of repeating trap pairs at entrances.

## Rewards and communication

- Routine caches should contain coins. Gems and gold bars are rare rewards and should be placed only
  where the route asks for meaningfully greater effort or risk.
- Opening messages should teach only information the environment and established game language cannot
  communicate. Remove exposition that narrates an otherwise readable route.

## Floors, roads and grass

- Separate the appearance reference from the construction reference. Level 1 demonstrates the dirt,
  road and grass vocabulary; Tutorial 1 demonstrates an editable floor GridMap. Inspect the actual
  nodes and resources rather than assuming that every reference level constructs its floor alike.
- For the Tutorial 1 floor technique, use one-metre PlaneMesh tiles with four StandardMaterial3D
  variants of `Assets/environment/dirt_2.png`: UV scale (0.5, 0.5), offsets (0, 0),
  (0.5, 0), (0, 0.5), (0.5, 0.5). Alternate the four items by X/Z parity so one texture
  spans two cells in each direction. Match cell size, origin and centring to the main GridMap.
  These are reference-specific settings, not mandatory dimensions for every level.
- Let the floor GridMap own its walkable surface, not just decorate a hidden slab. Tutorial 1 uses
  a (1, 0.5, 1) box per tile, offset down by 0.25, with cell-centre Y disabled: the top stays at
  Y=0. Remove redundant slab collision when adopting this setup, and rerun physical passage tests.
- Place Road items in the main wall/object GridMap without overwriting existing walls. In the
  current graveyard library, Road has no collision; verify item names and shapes when reusing a
  library instead of assuming every occupied cell blocks movement. Keep road rotations upright.
- Compose paving as worn route fragments, small threshold aprons and landmark courts, with exposed
  dirt between them. Vary continuity and width deliberately; do not pave every walkable cell or
  make every room entrance identical. Keep spike plates uncovered.
- For Level 1-style painted grass, reuse `addons/simplegrasstextured/grass.gd`,
  `Assets/environment/grass-small.res`, and the reference green-to-straw gradient. Store authored
  transforms in paintable MultiMesh instances, not a gameplay-time scatter generator. Reuse
  existing binary assets read-only; scene text can hold the new paint data.
- Paint asymmetric pockets and broken wall-foot fringes, with different amounts of growth in
  different districts. Leave broad clearings and protect the silhouettes and approaches of keys,
  scattered coins, coffins, traps and doors. A dangerous vault can benefit from almost no grass.
  Named paint groups help later editing; their number and density should follow the composition.

## Editor usability and art validation

- Make diagnostic grids and checkers optional editor overlays, disabled by default when the
  designer is judging final floor art. Never make a diagnostic pattern the only material on a
  textured surface: it prevents the editor from checking the texture, lighting and projection it
  is meant to diagnose. When the editor viewport cannot provide dependable scene lighting, use
  transient unshaded duplicates for its generated preview rather than changing the shared runtime
  materials; a texture that exists but renders almost black is not an editable visual reference.
- When introducing an experimental floor system, copy only the source textures it actively needs
  into a clearly owned game-art folder and leave established material references untouched. Point
  new styles at those copies so the prototype can grow its own floor library without migrating or
  risking existing levels prematurely.
- Treat editor overlays as supplemental information, not a bright replacement for authored
  materials. Keep their luminance and opacity low enough that underlying checker or texture detail
  remains visible, and pair colour coding with exact text for editors with impaired vision. The M4
  FloorSurface trial found a full-value false-colour overlay painfully bright and its checker hard
  to distinguish for a tester with diabetic retinopathy.
- Keep finite floor bounds as a storage and validation detail, not an authoring cage. Painting
  beyond an edge should expand the stored rectangle while leaving untouched newly enclosed cells
  absent; cancellation and undo must restore both occupancy and the previous extent. Compact the
  storage automatically after each completed gesture so erasing exterior tiles cannot leave a
  large invisible authored rectangle or require a separate cleanup action.
- Make mutually exclusive paint shapes visible as direct controls, and describe resource-copy
  actions by their consequence for the current scene. While a dedicated paint mode owns viewport
  clicks, hide obstructive transform gizmos and restore normal selection when painting ends.
- An object rendering at runtime is not proof that the level designer can find and paint it.
  Prefer a native `FloorGridMap` child of the main level scene for directly edited floor data.
  If deliberately using nested layout or grass scenes, expose their editable children and verify
  access from the main scene—not only by opening the nested source.
- Validate the scene with `PackedScene.GEN_EDIT_STATE_INSTANCE`: check parent/owner, editable
  instance flags where needed, visible state and populated cells. This checks saved editor state,
  not the user's currently open editor. If the user still cannot see a node, inspect which scene
  and on-disk version they are viewing; do not repeatedly claim that a runtime test proves their
  editor is fixed, or discard unsaved work to force a reload.
- Adding a floor grid can affect enemy navigation even when walls have not moved. The current
  zombie implementation selects the first covering GridMap; keep the wall layout before the floor
  in discovery order while that implementation remains. Test real navigation-grid discovery,
  rather than manually passing only the wall grid and hiding an ordering regression.
- Art-only changes should preserve the successful objective and flame choreography. Compare wall
  cells and orientations, rerun full-collection routes and doorway checks, and update fixtures to
  include the actual floor after moving it. Road-aware reachability checks must still verify real
  blocking geometry at locks; treating all occupied GridMap cells as walls is no longer valid.
- When an autotiled wall follows gently stepped ground, connect its cardinal neighbours by horizontal
  column using an explicit world-space vertical tolerance. Keep exact-height matching as the default,
  then run the actual GridMap correction operation and verify its end pieces, orientations and
  unchanged second pass instead of hand-authoring the expected variants.
- Inspect a rendered preview for composition, texture continuity and readable hazards. A neutral
  lighting preview helps inspect placement but does not establish readability under gameplay
  lighting or replace a human playthrough.
- Godot's headless dummy renderer can discard MultiMesh instance transforms. Validate serialized
  paint buffers for headless placement checks, then use a real renderer for appearance. Keep
  scene loading, editor accessibility, visual inspection and gameplay evidence distinct.
- A test runner can print zero failed assertions while a suite aborts on a script error. Inspect
  script errors and teardown diagnostics as well as counts; report unrelated validation failures
  without weakening checks or claiming an entirely clean run.

## Evidence recorded so far

- Close Escape playtests exposed bypassable freestanding doors, visually static whole-map flames,
  wrapping skeleton patrols, repetitive entrance spikes, overused gems, unnecessary opening text,
  waiting for a boundary cycle, a millstone side-contact kill, and a flame transition cutting off
  the approach to an otherwise valid doorway. Later markers captured a 28-second wait by a player
  ahead of the tested schedule, motivating early-arrival checks and progression-driven trailing
  pressure rather than timed expansion gates. These observations produced the
  reusable rules above; future Close Escape tuning belongs in its scene and tests.
- The player later reported 100% completion. The art pass therefore preserved the established
  route and pacing while adding selective roads and grass. The requested floor construction was
  clarified using Tutorial 1, rather than copying Level 1's large floor plane.
- Repeated reports that the floor was absent from the editor led to making it a native main-scene
  GridMap. The saved nested scene and rendered previews contained a floor, but the cause of the
  user's editor discrepancy was not established; direct ownership and editor-state tests were
  added rather than treating those previews as proof of editor accessibility.
- The first FloorSurface shape-painting trial found fixed bounds restrictive, the rectangle dropdown
  easy to overlook, the shared-resource copy language unclear, and the selected-node transform
  gizmo obstructive. The accepted cancellation, navigation and scene persistence behaviour was
  retained while those authoring affordances were revised. The retry accepted direct shape buttons,
  out-of-bounds painting and complete undo/redo; automatic extent compaction was added after the
  saved test gesture exposed redundant empty storage.
- The M5 texture-library retry exposed lit horizontal FloorSurface previews rendering almost black
  in the editor even though their vertical faces retained texture detail. Editor preview materials
  are therefore unshaded transient copies; runtime styles keep their authored lighting response.
