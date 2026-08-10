# Changelog

## 2026-08-10

### 0300

- Millstone rolling audio now fades out as soon as the stone leaves supporting ground.
  - Prompt: Fade millstone rolling audio as soon as it loses ground contact.

### 0200

- Millstones now obey gravity and fall when they roll beyond supporting ground.
  - Prompt: Smooth millstone audio, make pushing easier to control, and let it fall into holes.
- Players receive gentle sideways alignment assistance while pushing a millstone and can immediately steer away without being trapped.
  - Prompt: Smooth millstone audio, make pushing easier to control, and let it fall into holes.
- Millstone rolling audio now fades out quickly instead of stopping abruptly.
  - Prompt: Smooth millstone audio, make pushing easier to control, and let it fall into holes.
- Millstones already placed in Level 1 and the Debug Level now use the pushable physics scene instead of the static art source.
  - Prompt: Fix millstones that cannot be pushed.

## 2026-08-09

### 1900

- Rolling millstones kill skeletons and zombies on impact, while stationary millstones remain harmless.
  - Prompt: Add a two-direction physics millstone that only kills undead while rolling.
- Level editors can place a physics-enabled millstone that rolls only along its two opposing sides with rolling-rock resistance and audio.
  - Prompt: Add a two-direction physics millstone that only kills undead while rolling.

### 1600

- Level-select run playbacks now keep flask drinking and death scream samples muted without entering the normal player death flow.
  - Prompt: Mute potion and Wilhelm scream samples during level-select playback.

## 2026-08-07

### 1800

- Pickup radius flasks now expand only loose-item collection range and leave coffin drop-off distance unchanged.
  - Prompt: Keep pickup radius boosts from changing treasure drop-off range.

### 1700

- Pickup radius flasks now grant independently timed, stackable radius boosts for 15 seconds each.
  - Prompt: Make pickup radius flasks last fifteen seconds and stack their radius boosts.

### 1400

- The level duplication workflow now supports the typed level definitions used by the current level mapping.
  - Prompt: Generate a level named Flask Kill Expand from the existing level PNG in folder 5.
- Level editors can select Flask Kill Expand as a generated 32-by-32 level built around the existing folder 5 layout image.
  - Prompt: Generate a level named Flask Kill Expand from the existing level PNG in folder 5.

## 2026-08-04

### 2000

- Level editors no longer see stale optional-node path errors from lockable passages, the generated Vampire Maze, or the Graveyard camera.
  - Prompt: Remove the reported invalid scene paths and related editor errors.

### 1900

- Gold and silver keys no longer consume sack capacity, so a cleared coffin leaves the sack counter at zero while keys remain available for locks.
  - Prompt: Clarify why five sack units remained at the debug-level coffin.

### 1800

- Graveyard levels now load the rebuilt MeshLibrary by its stable path without stale UID warnings, and disabled text triggers no longer probe physics overlaps.
  - Prompt: Clear the stale MeshLibrary UID warnings and related text-trigger editor error.
- Paused text Continue now responds directly to the controller's primary face button as well as Enter and Space.
  - Prompt: Make the paused text Continue action respond to the controller's primary button.
- Paused text now uses the primary action and a large, polished Continue button positioned above the HUD panel.
  - Prompt: Improve the paused text Continue control's input, size, and placement.
- The Debug Level potion showcase now extends to separate popup and game-pausing text triggers.
  - Prompt: Add popup and pausing text-trigger examples after the Debug Level potions.

### 0100

- Graveyard GridMaps now retain Road item IDs and use the pulled artist-authored collision shapes for Fence and Tombstone.
  - Prompt: Rebuild the Graveyard MeshLibrary after pulling the latest models.

## 2026-08-03

### 2100

- Level editors can place reusable Fence and Tombstone scenes that retain the collision bounds authored in Blender.
  - Prompt: Make artist-placed Fence and Tombstone models collide outside GridMaps.

### 1200

- Existing Vampire Maze feedback snapshots no longer duplicate the live level scene UID when Godot scans the project.
  - Prompt: Check and resolve the editor errors from the supplied Godot log.

### 1100

- Level 1 now automatically selects its wall GridMap and repairs connected wall pieces, while switching levels no longer reuses an invalid GridMap target.
  - Prompt: Make automatic GridMap repair work in Level 1 as it does in Level 7.
- The PNG-to-GridMap editor addon now loads correctly after adding manual colour mappings and mapping-aware repairs.
  - Prompt: Restore the disabled PNG-to-GridMap addon after the mapping update.
- Level editors can add colour-to-piece mappings without a PNG and remove or restore existing mappings from the wall configuration.
  - Prompt: Correct updated wall autotiling and manage mappings without a PNG.
- PNG-to-GridMap now aligns repaired wall ends, corners, and T-junctions with the updated Graveyard meshes, including after mapping edits.
  - Prompt: Correct updated wall autotiling and manage mappings without a PNG.

## 2026-08-02

### 1600

- Level editors can now inspect typed level definitions and edit reusable prompt, flask-preview, and PNG-to-GridMap scene structure while existing gameplay and replay behaviour remain unchanged.
  - Prompt: Resolve every marked Godot TODO without changing runtime behaviour.

### 1500

- Developers and level editors can now find focused TODO guidance for Godot architecture, data, scene, and frame-loop concerns without gameplay changes.
  - Prompt: Review the code against Godot best practices and mark issues without fixing them.

### 1300

- Kill-boundary flames and moving blocker walls now affect the player without moving, blocking, or damaging zombies and skeletons.
  - Prompt: Prevent the moving kill boundary from affecting zombies or skeletons.

### 0200

- Each jump near a deposit coffin now transfers exactly two extra carried coins without accelerating later unloading.
  - Prompt: Replace the coffin jump speed boost with two extra coins per jump.

### 0100

- Five nearby jumps now double coffin unloading speed, sustained hopping can reach 2.5 times speed, and the boost fades after jumping stops.
  - Prompt: Rebalance the coffin jump boost after reviewing the Debug Level playback.

## 2026-08-01

### 2100

- Repeated jumps near a deposit coffin now accelerate unloading up to three times normal speed, then reset when the player leaves.
  - Prompt: Make repeated jumps accelerate treasure unloading at coffins by more than half.
- Large dense coin piles now collect smoothly in paced batches, and overflow coins remain in place when the sack is full.
  - Prompt: Stop large dense coin piles from chugging during collection.
- Deposit coffins now play the supplied spatial impact sound when they land.
  - Prompt: Use the supplied coffin impact sample during the physics spawn.
- Timed treasure-deposit coffins now fall and tumble into the level while coffins present from the start remain fixed.
  - Prompt: Make deposit coffins use physics when Spawn Time is positive.
- The Debug Level's original and timed skeleton and zombie patrols now turn around at each endpoint instead of jumping back to the start.
  - Prompt: Make Debug Level enemy patrols ping-pong instead of wrapping.

### 2000

- Gold and silver keys now play the shared spatial key impact sound after a meaningful landing while tiny placement corrections remain silent.
  - Prompt: Play the supplied landing sound for both key types.
- Timed gold and silver keys now tumble visibly into the level under rigid-body physics.
  - Prompt: Make timed keys use a physics drop-in.

### 1900

- The Debug Level's 28 duplicated review objects now spawn in walking order at one-second intervals.
  - Prompt: Complete one-second Spawn Time sequencing for the debug-level review row.
- Delayed spike traps now wind upward from below the floor using their recharge sound before activating, while bat nests activate at their authored position without moving or revealing the swarm early.
  - Prompt: Give spike traps and bat nests suitable non-drop spawn presentations.
- Level developers can now use Godot Tools for headless GDScript completion, scene previews, formatting, and F5 debugging of the project or current scene.
  - Prompt: Configure the installed VS Code Godot extensions for this project.
- Level developers now get consistent four-column tab indentation for GDScript in VS Code and other EditorConfig-aware editors.
  - Prompt: Align VS Code with the repository's preferred GDScript indentation.

### 1800

- Generated mazes now place the Vampire two cells inside the exit and keep the intervening gate approach clear.
  - Prompt: Move the generated Vampire further away from the exit gate.
- Players now play the new spatial landing sample after meaningful falls while initial floor contact and tiny steps stay silent; delayed zombie drops now use the existing enemy landing sample.
  - Prompt: Implement player landing with the new sample and identify missing spawn-impact sounds.

### 1700

- Level editors can now set the floor material and X/Y cells-per-texture directly on GeneratedMaze, with each texture continuing seamlessly across those cells.
  - Prompt: Show generated floor controls on the maze node and define tiling as cells covered by one texture.

### 1600

- Skeleton spawn drops now accelerate into the floor, with a stronger landing impact that carries clearly across the play area.
  - Prompt: Make skeleton spawn drops feel heavy and make their landing impact easier to hear.
- Skeletons now use their dedicated spatial footstep sound and play their landing impact after a visible drop or fall to the floor.
  - Prompt: Use the new skeleton footstep and landing sounds during movement and spawn impacts.
- Collecting the No Boundary flask no longer interrupts play when the removed kill boundary reaches the next recording checkpoint.
  - Prompt: Prevent the no-boundary flask from crashing an active run recording.
- Unused screen space on displays with a different aspect ratio now renders as solid black instead of Godot's gray fallback.
  - Prompt: Make the gray bars on non-16:9 Windows laptop displays black.
- Spawned flasks now tumble around varied axes throughout their fall instead of descending with a fixed pose.
  - Prompt: Make spawned flasks spin so their drop no longer looks unnaturally linear.

### 1500

- Flask impacts now remain audible from normal and zoomed-out gameplay cameras, with safe gain added for the quiet source sample.
  - Prompt: Make the flask floor-impact sample clearly audible after it could not be heard in gameplay.
- Flasks now play the new spatial glass-impact sound on substantial floor, wall, and object collisions without repeating it for tiny settling contacts.
  - Prompt: Play the new flask impact sample through the shared audio support when a flask hits another body.
- Spawned flasks now rest against the floor with collision shaped to the visible base, body, neck, rim, and stopper, without the visual bobbing away from the landed bottle.
  - Prompt: Align the spawned flask physics body with the visible bottle so it no longer appears to float above the floor.

### 1400

- Spawned flasks now rebound subtly, roll and wobble on a bottle-shaped collider, then settle naturally in their landed pose.
  - Prompt: Give spawned flasks a believable small bounce, roll, and settled bottle motion.
- Delayed physics items, including every flask variant, now begin rounded-body drops at deterministic varied angles, while zero-time editor placements remain fixed exactly as authored.
  - Prompt: Randomize spawned physics-item rotations and make health flasks physically drop while preserving zero-time placements.

### 0400

- Skeleton contact now causes the ordinary blood death presentation instead of incorrectly setting the player on fire.
  - Prompt: Use the correct death type when a skeleton kills the player.

### 0300

- Delayed keys, loose treasure, gems, gold bars, coins, and rolling rocks now drop in under physics, while non-physics placeables remain hidden and inactive until their spawn time.
  - Prompt: Give every map placeable and enemy a shared spawn time, preserving existing timers and identifying physics drops.
- Level editors can now set one Spawn Time on every reusable map item and enemy, with zero keeping the item present from level start and existing pile and enemy timings preserved.
  - Prompt: Give every map placeable and enemy a shared spawn time, preserving existing timers and identifying physics drops.

### 0200

- Level-editor feedback snapshots no longer claim the source level's scene identity, preventing duplicate UID warnings in Godot.
  - Prompt: Remove duplicate UIDs reported for Vampire Boss feedback snapshots.

### 0100

- GeneratedMaze placeables now spread through all valid walkable space without treating perimeter corridors as a separate placement zone.
  - Prompt: Spread GeneratedMaze placeables randomly through all valid space while preserving challenge constraints.
- Fire deaths now drive pronounced rapid whole-body convulsions before the burning player gradually falls still.
  - Prompt: Make the burning player convulse much more visibly during death.
- Fire-death flames now remain spread from the player's feet through the torso and head instead of collapsing at ground level.
  - Prompt: Extend fire-death flames from the feet over the head and torso.
- Flame kill boundaries now leave the player visibly charred and engulfed in fire instead of showing the ordinary blood death.
  - Prompt: Give fire kill boundaries a burning death over the player's blackened body.

## 2026-07-31

### 1900

- GeneratedMaze coffin deposits now occupy separate maze regions with generous spacing between them.
  - Prompt: Spread GeneratedMaze coffins across the level instead of clustering them together.
- Blood now sprays from the keeper's facial features, then visibly bursts and stains both the fallen body and nearby floor.
  - Prompt: Move death blood from the hat onto the face and make impacts and decals visible.
- Feedback notes now accept all keyboard typing while D-pad, left stick, accept, and cancel inputs independently operate the dialog actions.
  - Prompt: Route feedback typing to the note while the controller operates the dialog UI.
- Player deaths now leave irregular blood splatter decals attached to both the corpse and the contacted environment surface.
  - Prompt: Keep blood spraying during the death close-up and leave splatters on the corpse and environment.
- Facial blood now continues spraying while the player lies still during the death-camera close-up.
  - Prompt: Keep blood spraying during the death close-up and leave splatters on the corpse and environment.
- Player deaths now include diminishing body spasms and blood droplets from the mouth, nose, and both eyes.
  - Prompt: Make player deaths more visceral with twitching and facial blood.

### 1800

- The Vampire now glances into side corridors for three quarters of a second while continuing along its search route, with minimap diagnostics explicitly identifying each corridor look.
  - Prompt: Make the Vampire visibly check side corridors without pausing.
- The Vampire's gameplay field of view is now a focused 110 degrees, making deliberate head movement important for finding the player.
  - Prompt: Narrow the Vampire's sight to a human-scale field.
- The Vampire now pauses during junction searches and turns its head, sight, and headlamp down each clear forward or side corridor without rotating its travel direction.
  - Prompt: Give the searching Vampire deliberate corridor head checks.

### 1700

- The player now begins following visible enemies from five metres away, providing a longer and more readable head-tracking window while walking past them.
  - Prompt: Make nearby-enemy head tracking remain visible for longer.
- The player now keeps close enemies anywhere in front under observation, turning as far toward them as safely possible instead of glancing at the opposite wall.
  - Prompt: Correct the player's head direction when passing a nearby skeleton.
- Player head attention now prioritises visible vampires, zombies, and skeletons within three metres, follows them while they remain in the safe forward head-turn arc, and ignores threats behind the player or beyond close range.
  - Prompt: Improve player head awareness around nearby enemies

### 1600

- Stationary players and Vampires now begin scanning immediately and continue alternating off-centre looks, with a subtle upper-body turn that makes their attention readable.
  - Prompt: Keep stationary characters actively looking around instead of staring ahead.
- Player and Vampire headlamps now follow the complete animated head movement while keeping their authored position and cone.
  - Prompt: Attach each character's headlamp to its moving head.
- The player and Vampire now scan widely and often while stationary, then smoothly narrow their wandering gaze as movement approaches full pace.
  - Prompt: Make looking around stronger at rest and focused at full pace.
- Collecting an item while the player is looking at it no longer causes a crash on the following frame.
  - Prompt: Fix the crash after collecting an item during a player glance.
- The Vampire now glances from side to side while travelling, with its restricted sight cone and live look angle visible on the minimap.
  - Prompt: Let the Vampire search with safe glances and show its sight on the minimap.
- The player now briefly looks toward nearby unobstructed collectibles before returning attention to their travel direction.
  - Prompt: Let the player notice nearby collectibles with safe glances.

### 1500

- Level editors can now tune the Vampire's gameplay field of view independently from its visual headlamp cone.
  - Prompt: Separate the Vampire's visual headlamp effect from gameplay visibility.

### 1300

- Level editors now see the Vampire's essential gameplay controls first, with detailed behaviour tuning organised into Advanced subgroups.
  - Prompt: Keep critical Vampire controls in the base settings and move complex tuning into Advanced.
- The Vampire now sees only within its editor-authored headlamp cone instead of detecting players in every direction.
  - Prompt: Use the Vampire's editor property to determine its visibility cone.

## 2026-07-28

### 1400

- The corner minimap now keeps Vampire diagnostic text hidden, revealing it in the separate header only while the left trigger opens the full-screen map.
  - Prompt: Show Vampire diagnostic text only in the controller-expanded map.

## 2026-07-26

### 1800

- The full-screen minimap now places Vampire diagnostics in a dedicated header so they no longer cover the top of the fitted level map.
  - Prompt: Keep the top of the expanded minimap visible.
- The full-screen minimap now zooms out and centres the complete level instead of continuing to scroll around the tracked character.
  - Prompt: Fit the complete level inside the expanded minimap.
- Holding the left trigger now expands the minimap across the full screen with larger Vampire diagnostic text and markers, then restores the corner view on release.
  - Prompt: Make the minimap fill the screen while the left trigger is held so its Vampire diagnostics are readable.
- Gold coins and their pile previews now use the textured metallic skull model at its authored size, with matching shared convex physics and the existing treasure outline.
  - Prompt: Integrate the newly added skull-coin model.

### 1700

- Gold coins now build their convex physics hull from the displayed coin mesh, including transformed meshes inside replacement model hierarchies.
  - Prompt: Make coin physics follow the current and incoming replacement mesh.
- The Vampire Maze minimap now shows the boss's facing, current belief and uncertainty, actual player, route destination, perception source, search plan, route progress, and movement state.
  - Prompt: Show the Vampire's behaviour and believed player position on the minimap.

### 1600

- Closing the game now waits for pending playback saves before shutdown, preventing the macOS exit crash.
  - Prompt: Stop the game crashing when a recorded run closes.
- Players can write multiline feedback and use joypad-focusable Proceed or Cancel buttons before gameplay resumes.
  - Prompt: Use a multiline feedback area with joypad-operable actions.
- The centred feedback form now uses the game's standard font at more than twice its previous size. Feedback report 20260726T150541Z-graveyard marked at 2.73s in graveyard is archived with feedback/archive/2026-07-26/20260726T150541Z-graveyard.gdr.
  - Prompt: Resolve feedback report 20260726T150541Z-graveyard: i walked a bit and then submitted this feedback. The feedback is that the feedback form is too small to see clearly. More than double the font sizes please and use the games standard font.
- Player feedback reports preserve the played level scene so visual playback keeps its original layout after later level edits.
  - Prompt: Make player feedback conflict-free, prominent, paused, and independent of later level edits.
- Players can press Square to open a centred feedback dialog that pauses gameplay until the note is submitted or dismissed.
  - Prompt: Make player feedback conflict-free, prominent, paused, and independent of later level edits.

### 1500

- Level designers can now commit Triangle-marked bug reports with their exact playback time, while corrected reports retain their fix and playback in a size-limited archive recorded in the changelog.
  - Prompt: Let level designers commit replay-backed bug reports and archive corrected evidence without growing the repository indefinitely.
- Players can press Triangle during any run to mark a debounced feedback moment for Codex, optionally add a note with Cross, and return to Codex without first closing the game.
  - Prompt: Keep an always-available controller marker so Codex can inspect new player feedback immediately.
- Players can now accept a Codex-directed level test with an in-game instruction, while Codex can replay the newest recorded run using only the requested position, input, camera, button, metadata, summary, or drift logs.
  - Prompt: Let Codex request a confirmed player test and replay the latest session with selectable command-line logs.

### 1400

- Level editors can now see the originating request summarized beneath each timestamped changelog entry.
  - Prompt: Add a concise summary of the user request to every generated changelog entry.

### 1300

- Level editors can now scan changelog updates grouped by local date and hour through the shared repository workflow.
  - Prompt: Create a shared changelog skill with daily and hourly headings.

## Undated entries

- Changing the generated Vampire Maze size now repositions the player at its entrance and the Vampire beside the rebuilt gate, preventing stale larger-map positions from dropping the boss below the floor while its proximity fog remains active.
- The Vampire Maze now waits for its generated gate before validating and starting the boss, and its restored gate/content references ensure the Vampire immediately receives its entrance hunt instead of standing idle for the entire level.
- The Vampire now turns smoothly into its first junction inspection, resets every retained clue and prediction when reused, distinguishes failed routes from successful arrivals, recovers immediately from unreachable evidence, documents strict non-omniscient perception rules, and reports missing gameplay dependencies together.
- Editor-placed treasure coffins in the Vampire Maze now remain solid for the player while the larger Vampire strides visibly over them, preventing its grid route from stalling against a non-grid obstacle.
- Vampire searches now age sound clues over time: the possible movement area expands while landmark and direction confidence fades, and current sight removes visibly empty tiles without discarding a player position confirmed by sight.
- Vampire navigation now uses the level's explicit wall GridMap, scale-correct route distances, physical capsule clearance, deterministic search ranking, and reported search limits; projected targets, outside-grid destinations, and sustained stalls recover without unsafe shortcuts or misleading failures.
- The generated Vampire Maze now hides its reachable gold gate key down an exploration branch safely away from the exit, preventing the key from spawning beside the gate.
- Run-recording previews now use one shared safe scene loader for every level, preventing constructed levels such as the Vampire Maze from leaving an unsupported threaded load that blocks gameplay startup.
- Vampire searches now use an authored replay-stable seed, consistently ordered route candidates and explicit physics ordering, while run capture starts after gameplay bootstrap so its decisions remain repeatable without simplifying pursuit or investigation behaviour.
- Vampire Boss run recordings now appear in level selection after playing the Vampire Maze.
- Player-generated sounds no longer distract the Vampire during confirmed pursuit or its brief sight-loss grace period; confirmed sight clears older sound evidence so the Vampire keeps its live or last-seen player position as the authoritative target.
- The Vampire now resolves wall-adjacent sightings onto the player's actual side of a wall, continues searches from its latest position instead of revisiting an exhausted dead end, and rebuilds routes whenever movement stalls even without a wall collision.
- Coins, gold bars, and every gem now retain a subtle translucent gold outline under every lighting condition, with enough HDR emission to bloom while keeping treasure discoverable without overpowering its lit centre.
- Level editors now find the shared PNG-to-GridMap configuration under a concise filename that identifies the configured MeshLibrary.
- Vampire Maze generation now keeps ordinary usable edge corridors but inserts a sparse, size-scaled set of breaks so the border cannot become a route around the maze; it also distributes treasure across interior map regions, refreshes immediately when any generation setting changes, and lets level editors freeze and reparent generated scene content for a static editable level.
- Vampire Maze extra openings now use unbiased seeded selection, preventing isolated wall posts from clustering down the left side while retaining occasional posts across the layout.
- Vampire Maze live editor regeneration now keeps generated nodes transient until the level is frozen and avoids duplicate treasure-preview rebuilds, preventing Node3D child-order bounds errors when generation settings change.
- The Vampire Maze freeze action now remains callable after tool-script reloads and persists every generated gate, door, key, coffin, treasure pile, and bat scene as editable level content.
- Vampire Maze size now determines how many extra internal walls open into escape loops, while treasure piles favour spacious, well-connected areas across the dungeon instead of forming a breadcrumb trail through narrow passages.
- Last-run playback now applies collected flask effects, so removing the kill boundary during a run is reproduced correctly instead of letting the replay boundary kill the recorded player.
- Vampire sight remains omnidirectional but now checks visible edges across the player's body and lets real wall collision decide visibility at each endpoint, preventing thin obstacles or coarse wall tiles from hiding a player pressed against nearby scenery.
- Visible Vampire pursuit now moves same-cell endpoints and extends straight-corridor routes in place without resetting velocity or recalculating the maze path; route construction also omits the body's current cell, removing the repeated backward correction that caused stop-start chasing.
- The Vampire now aims its final chase point at the player's exact position along a corridor while clamping only for body clearance at nearby walls; its doubled model also has a larger wall-occluded instant-kill shell that is polled after movement, closing the narrow pass-by gap beside walls without killing through them.
- Visible Vampire routes now remain valid only while their final wall-safe point guarantees kill-contact reach of the player; stale routes are replaced immediately and final approaches use tighter precision, preventing the boss passing a player pressed close to a wall.
- A Vampire with confirmed sight now routes to the player's actual position instead of a projected point beyond them, preventing stale movement prediction from carrying it past a player who stops against a wall; directional prediction remains active only after sight is lost.
- The Vampire now learns the player's current position only from its known entrance, confirmed floor-level sight, or allowed pickup, coffin, and bat noises; the cheating timed aerial reveal and deliberate wrong-way search mistakes have been removed, while evidence-free searches intelligently cover plausible known objectives before guarding the required exit route.
- Direct visible pursuit now requires a margin-expanded body sweep with no wall or scenery collision anywhere along it; if a shortcut still touches a corner, the Vampire cancels it immediately and rebuilds its safe tile route instead of waiting in a wall stall.
- Visible Vampire chases no longer pause when an interception waypoint completes: they immediately refresh to the confirmed player position, continue directly after exhausting tile waypoints, and only use the closer-player shortcut when the body-width cast reaches the player before any wall or scenery blocker.
- Vampire sight now uses a low wall-occluded visual ray when its body-width sweep brushes a block edge, then keeps movement on safe tile routes; after losing a confirmed player it searches an expanding, direction-biased envelope from the last seen position for longer before returning to ordinary hunting.
- Noise searches now use an uncertainty radius that grows from the heard position by the player's assumed maximum travel speed; possible targets stay inside that reachable envelope and favour maze branches matching the player's last confirmed walking direction.
- The Vampire now follows each safe maze-tile waypoint without diagonal momentum cutting into walls; after seeing the player it only leaves that tile route when the player is closer than its next waypoint, with the live visible position refreshed immediately when the player passes nearby.
- The Vampire's continuous floor-level sight now reaches up to 64 metres, while walls and body-width clearance still prevent it seeing or pursuing through blocked maze routes.
- Game font loading now uses Godot's resource cache, torch outlines use instance shader parameters, lightweight embers use CPU particles, and bat nests stop active one-shot audio during teardown, eliminating headless validation shutdown leaks.
- LockedGate staircases now leave a full floor-length gate-swing area before the first riser; its visible surface sits 1 cm above the level floor to prevent z-fighting while its collision remains flush with ground height.
- The procedural staircase's CSG editor preview now uses the gate-facing positive-Z offset, centring its one-sided extrusion across the opening like the runtime mesh.
- LockedGate now places the procedural staircase's origin flush with the gate frame's outside face, keeping its first riser centred and attached to the opening in every level.
- The procedural staircase now starts at its first raised tread and relies on the level floor below the gate, removing the coplanar bottom step and collider that flickered against floor tiles.
- The procedural staircase now includes a serialized CSG editor preview generated from the same step count, steepness, and tread depth, so it remains visible while editing even before its tool script runs and hides automatically during play.
- Players inside a gate's procedural stairwell now temporarily ignore kill-boundary damage and its dedicated blocker collision, with both protections restored immediately on leaving the stairs in either direction; levels without a kill boundary grant no immunity.
- Procedural staircase triangles now use Godot's clockwise front-face winding, keeping every outward tread, riser, side, and foundation face visible with back-face culling enabled.
- LockedGate exits now use a completely new `ProceduralStaircase` that creates one watertight editor-visible mesh from step count, steepness, and tread depth; every previous staircase mesh and joined-flight implementation has been removed.
- Every reusable LockedGate now owns the guarded extended exit staircase and summit completion trigger, including authored levels and generated Vampire Maze gates.
- The Vampire Maze exit staircase now continues upward beyond its victory trigger and has invisible collision guards along both edges, preventing players from walking into the void while the level completes.
- Level editors can now disable the Vampire boss from its Development inspector setting, removing its AI, collisions, instant kill, lights, and purple fog while testing other maze features.
- The generated Vampire Maze exit now has a flush, doorway-width threshold and a longer shallow collision ramp, preventing falls beyond the gate while keeping the gate opening clear.
- The Vampire now runs at 1.1 times player speed and uses complete generated-layout knowledge of treasure piles, keys, coffins, doors, and the exit to predict likely destinations after player noise.
- GeneratedMaze authors can now set an exact treasure-pile count and deterministic minimum/maximum coins per pile, while every configured gem is reserved for challenging off-main-path locations.
- Vampire noise searches now continue along the branch implied by consecutive sounds, avoiding immediate double-backs while unexplored forward routes remain.
- Level editors can now generate bordered mazes with configurable pixel-wide hallways, including 128-by-128 layouts with two-pixel passages.
- Vampire Maze now has a double-sized, faster vampire boss that hunts pickup and coffin-deposit noises through the maze, carries a purple headlamp, and kills the player instantly on contact.
- The Vampire Maze boss now immediately hunts the player's authored entrance position when the level begins.
- Vampire Maze developers can toggle a scene-local zoomed-out camera and ambient-light helper without changing the presentation of other levels.
- Vampire Maze now enables the development minimap and centres it on the moving vampire while every other level retains player tracking.
- Vampire Maze's minimap now colours every shortest walkable floor route from the player's current position to the end gate.
- Vampire Maze level editors can change the `GeneratedMaze` seed to build a new two-tile-wide GridMap maze; wall joins reuse PNG-to-GridMap repair, generated content owns and instantiates the opposite-corner exit gate, and the vampire begins immediately inside it. The same scene and configuration can be instantiated for future runtime dungeons.
- Vampire Maze generation now exposes difficulty controls for exact treasure budgets, best-route placement, carrying load, locked-door count, hidden-key placement, and bat hazards; generated keys remain reachable in order, coffins account for real treasure weight, and disturbed bats alert the vampire.
- Vampire Maze now has its own scene identity instead of conflicting with Level 1, and editor difficulty-slider changes are debounced so procedural content regenerates once after editing settles rather than repeatedly during the adjustment.
- Starting Vampire Maze no longer constructs the obsolete authored 128-by-128 GridMaps, treasure piles, coffin, and keys before replacing them; its lightweight scene now loads empty maps and lets `GeneratedContent` build the configured dungeon once.
- Vampire Maze startup now reuses editor-baked GridMaps instead of clearing and rebuilding thousands of identical cells, while still generating its dynamic gate, keys, treasure, hazards, and boss setup.
- Vampire Maze exit carving now connects arbitrary editor-configured dimensions to the opposite-corner gate, so non-square sizes such as 54-by-64 always produce a reachable exit and a valid vampire start.
- Unplayed tombs no longer start a redundant replay-file lookup in Level Select before their first run.
- Vampire Maze no longer attempts to build its procedural dungeon inside the Level Select replay viewport, preventing its renderer-threaded preview load from blocking Play while other levels retain run previews.
- The Vampire Maze boss now passes through generated locked doors and route-side coffins without altering player collisions, preventing pursuit from stalling while preserving keys and deposit interactions.
- The Vampire Maze boss now follows the centre of two-tile passages and automatically rebuilds a detailed route when a wall collision stops its progress.
- The Vampire Maze boss now route-finds to the player's live position after gaining line of sight instead of abandoning the maze route for a straight-line charge.
- Vampire developers can toggle a world-space label above the boss that reports its live AI state and last confirmed line-of-sight result.
- Visible-player chase routes now remain stable for at least one second and only refresh after the player moves two metres, preventing repeated route resets from making the Vampire twitch.
- Vampire diagnostics now appear in a level-local HUD instead of above the boss, the Vampire matches the player's maximum speed, and only bats, successful pickups, and coffin deposits alert it—footsteps, jumps, and manual drops do not.
- Generated locked passages now initialise their real reusable door and gate leaves at the final maze transform, while two approach tiles on both sides remain clear of coffins and other generated content.
- The Vampire development HUD now identifies sound, player, and search targets alongside live route progress, making winding maze pursuit distinguishable from a lost target.
- The Vampire now tolerates momentary line-of-sight flicker at corners, then finishes routing to the player's last seen position after a sustained loss instead of turning back one turn before a stationary player.
- Vampire sight now sweeps its physical body width along the floor, so walls and tight scenery block player acquisition before the boss commits to an impossible approach.
- Vampire sight now also traces its full-width corridor through logical maze cells, preventing collision seams in visible GridMap walls from triggering impossible early turns and wall-bound chases.
- At an exhausted noise or search location, the Vampire now stops in its idle animation to inspect clear passages, then chooses a deterministic-random reachable target near the player's maximum travel frontier from the noise instead of cheating with the live player position or remaining idle.
- Vampire routes now finish at body-clear corridor positions rather than the exact centre of a smaller player's wall-adjacent location, preventing an investigation target from making the larger boss press indefinitely into scenery.
- Repeated deposits and pickups near the Vampire's active noise target now reuse its existing route, preventing multi-item coffin deposits from causing one movement stutter and route rebuild per item.
- The generated Vampire Maze exit now clears a frame-sized boundary pocket around the locked gate, preventing repaired wall pieces from covering the gate or colliding with the vampire at its starting position.
- The Vampire Maze boss now uses low wall-blocked sight, relentlessly pursues visible players, searches toward the exit with diminishing deterministic backtracking mistakes, hears all player-owned sounds, and surrounds nearby players with configurable purple fog.
- Skeleton avoidance bodies now use their own collision layer, preventing invisible player obstacles at skeleton patrol positions while enemies continue to avoid one another.
- Level-select actions now open immediately while a previous run recording finishes saving in the background, and title fades reliably reach full brightness after paused gameplay.
- Level treasure totals now include authored loose valuables as well as piles, while avoiding double-counting treasure spawned from piles at runtime.
- The selected-Path3D editor gizmo now validates clicked point data and uses explicit scalar conversions, preventing malformed editor selection data from breaking the add-on.
- Frontend screens now share one reference-canvas, primary-input, and selection-audio implementation, keeping Level Select, Shop, Settings, and results consistent as they evolve.
- Run recording now avoids periodic buffer reallocations during typical levels and moves compression and disk writes off the gameplay thread to prevent recording-related frame stalls.
- Run recordings now retain the shop upgrades active for each attempt and include periodic world checkpoints that report actionable playback drift warnings in debug builds.
- Opening a level or another frontend screen now waits for level-select playback loading to shut down cleanly, preventing slower machines from carrying preview work into the next scene.
- Gold coin and mixed treasure piles now include ordinary translucent placeholder geometry for normal editor selection, while hiding that geometry during gameplay.
- Level progress, recovered treasure, shop stock, and replay cleanup now live behind a dedicated persistence component instead of being implemented by level navigation.
- Successful treasure-free levels now record their escape correctly, and looping run previews hold their final pose instead of interpolating back toward the start.
- Audio settings now apply immediately while batching disk saves until interaction settles or the player leaves Settings.
- The standard project check now runs the long-lived Godot test suite, including stable held-navigation coverage for shop focus details.
- Looping a level-select replay now immediately replaces its complete isolated preview session, clearing the replay inventory and restoring pickups, enemies, hazards, and authored particle effects.
- Level-select replays now show the moving kill boundary throughout the recorded run.
- Starting a level now shuts down its level-select replay before changing scenes, and replay tutorial triggers no longer raise a deferred overlap error that could halt debug runs.
- Replay hazards and enemies now trigger the character's local death animation in level selection while the recorded camera close-up continues, without storing a separate death flag or opening the loss screen.
- Level-select replays now collect nearby treasure into a replay-only inventory, remain fully silent, and isolate completion, deposits, tutorials, torches, damage, and flask effects from saved player progress.
- Level-select run previews now simulate coin drops, enemy movement, and other level logic while keeping the recorded player isolated, and are shown more clearly behind the level details.
- Skeletons and zombies placed slightly below a walkable floor now shift up onto it when spawned, while enemies intentionally placed in the air still fall naturally before moving.
- Level selection now replays the most recent run for each tomb at half opacity behind its details, with threaded loading that keeps menu navigation responsive.
- Every run now stores compact, compressed per-physics-frame joypad actions, timing, player motion, and camera motion under the level's stable ID for faithful fixed-timing playback.
- Successful result screens now initially highlight Level Select while retaining Retry, and death screens explicitly highlight Retry so players can immediately re-enter the lost level.
- The Level Select gallery card now keeps its isolated viewport at the screen's native 1920x1080 size and scales the completed render, fixing the previous top-left-only preview.
- The gallery's Level Select preview now renders through an isolated 1920x1080 SubViewport, preventing its independently scaled title and backdrop from spilling behind the other preview cards.
- Level selection once again uses the shared illustrated graveyard backdrop and shade, matching Shop, Settings, and the result screens.
- The Lose scene now explicitly authors its "YOU DIED!" title and bottom action bounds at the shared result-screen positions, keeping both visible and correctly placed in the editor.
- Frontend authors can now open a single labelled gallery scene to compare the Title, Level Select, Shop, Settings, Win, and Lose screens side by side as linked miniature scene instances.
- Result screens now retain their editor-authored titles at runtime, keeping gallery previews and the actual Win and Lose presentations in sync.
- Level selection now hides zero-count loot tiles and removes the empty loot area entirely for tombs where the player has recovered nothing.
- Win and loss results now restore a Retry action as their initial highlighted choice, letting players immediately replay the selected tomb after either outcome.
- Settings now uses a full-page surround with a persistent external Back action, while Music and Sound Effect rows receive the same five-pixel yellow controller-focus highlight as other frontend actions.
- Win and loss results now keep their title outside a vertically centred surround, prioritise completion percentage, and show only non-zero relevant treasure in larger tiles that wrap across two centred rows; successful replays with no newly credited treasure show no resource tiles.
- Player deaths now load a dedicated loss-outcome scene script, ensuring the result title always reads "Claimed by the Grave" rather than reporting an escape.
- Level selection now mirrors the shop's two-panel layout: its title sits above the surrounds, the illustrated backdrop has been removed, and selecting a tomb shows the exact treasure liberated from that level in a dedicated right-hand panel.
- Win and loss screens now share the frontend's graveyard backdrop, tiled stone frame, Almendra typography, compact actions, distinct titles, exact per-treasure haul counts, total value, and recovered percentage; failed hauls are clearly shown as lost.
- A new Settings screen is available from level selection with supplied Music and Sound Effect icons, persistent sliders, separate audio buses, and a styled Yes/No confirmation before resetting all progress.
- Choose Your Tomb, Shop, Settings, Escaped the Grave, and Claimed by the Grave now use explicit coordinated screen titles, while the shop also shares the graveyard backdrop treatment.
- Level selection now provides a compact Settings action between Back and Shop, with shared focus navigation supporting all three bottom actions.
- Replaying a level now awards additional treasure only when that run also contains its entire previously credited haul, preventing different partial runs from being combined into an unearned 100% reward.
- Level-select and shop analog navigation now accept a partial stick release between deliberate flicks, making quick repeated movements responsive without adding held-stick repeats.
- The level-select Back and Shop buttons now sit outside the stone surround and use the same compact proportions as the shop actions.
- The shop now gives its treasure balances more breathing room at the top and uses smaller, neater Back and Buy buttons at the bottom.
- The shop now shows icon, name, and saved quantity for all seven treasure types in compact half-scale tiled frames above the shifted inventory and detail panels.
- Successful level exits now credit only treasure beyond that level's previously rewarded qualifying haul; losses, lower runs, and incompatible partial hauls never duplicate wallet rewards.
- Diamonds, rubies, sapphires, and emeralds now use distinct authored 3D cuts matching their frontend icons while retaining the established jewel material rendering and physical scale.
- Gem palettes now use a more consistent shadow, body, and highlight progression, with face-derived normals keeping facets crisp across the new primitive geometry.
- Level selection now uses a compact vertical row list instead of the old card grid, sharing smooth focus scrolling and five-pixel selection styling with the shop.
- Frontend lists now move left and right to their bottom actions; level selection provides Back and Shop, while the shop provides Back and Buy.
- Deposited coins, gold bars, and all five gem types now accumulate by exact object count in player progress and can fund data-driven shop purchases.
- Shop purchases now deduct their authored treasure type, persist purchased stock, refresh affordability immediately, and show all saved treasure balances.
- Shop item rows show authored stock and grey out upgrades the player cannot afford while still allowing their subdued artwork and details to be inspected.
- Level selection now shares the shop's tiled stone surround, purple divider treatment, dark panels, five-pixel yellow focus border, and replaceable heart placeholder icons.
- Players can open the populated upgrade shop from a dedicated joypad-accessible button beneath level selection.
- Players can browse an availability-filtered shop catalog with a clear yellow selection, smooth joypad scrolling, and item details that update from authored resource data.
- Shop item details now present the selected item artwork, Almendra-styled name and description, price, and clearly grouped stat-effect rows using the new frontend graphics.
- Level editors now have a 1920x1080 shop layout starter with two resizeable tiled nine-slice stone frames that scale uniformly to the output display.
- Skeletons and zombies placed above the ground now fall to the floor before beginning their ground movement.
- Contributors now retain explicit rename history for the relocated gold coin pile and kill boundary files.
- PNG-to-GridMap profile storage no longer carries special handling for the removed `levels/common` folder.
- Level progress and lit torches now follow stable level IDs when mappings are reordered or inserted, with existing numeric saves migrated to their original levels.
- Flame boundaries in existing levels now start moving again after their placeable-folder refactor.
- Artists and developers now find authored asset families beside matching `placeables` domains, while environment construction art and the original Kenney pack retain their distinct organisation.
- Level editors and contributors now have concise folder-placement criteria for the project's main domains.
- Level editors now have Godot filesystem favorites for every placeable scene, all enemy scenes, keys, reusable lighting, and the player, making common drag-and-drop authoring assets immediately accessible.
- HUD authors now find the minimap implementation and shared view settings together under `ui/hud/minimap`, while player jump tuning lives with player movement under `player`.
- Level editors now find reusable free-position objects under `placeables`, with kill boundaries, locks, traps, triggers, torches, pushables, and treasure deposits grouped by behaviour; lighting, graveyard-specific crypt presentation, HUD flask text, level settings, and legacy layouts now live with their owning systems instead of a shared level folder.
- Level editors now find treasure and collectible placeables under `placeables/treasure` and `placeables/collectibles`; each treasure's world and `*_inventory.tres` resources remain together, gem resources are grouped in `placeables/treasure/gems`, keys remain under `inventory`, and shared treasure systems use treasure-wide names.
- The PNG-to-GridMap dock and settings persistence now reserve converter settings for actual level folders while reusable placeables live outside `levels`.
- The PNG-to-GridMap dock now repairs blank tab wrappers left by Godot script hot reloads, keeps its Godot-created wrapper populated across plugin reloads, and appears only for saved scenes inside a `levels` subfolder.
- Treasure piles can now independently place diamonds, rubies, sapphires, emeralds, and amethysts; all five share the same polished gem behaviour and weigh one sack unit, with values of 10, 9, 5, 6, and 2 treasure respectively. Their implementation assets are grouped under `placeables/treasure/gems`, while the configurable pile remains directly available to level editors.
- Diamonds now use a purpose-built brilliant-cut GLB model and a single bold, opaque jewel material, giving players a readable game-style gemstone without the old glass and edge-overlay shader stack.
- Level-select completion percentages now explicitly represent recovered treasure value against all available treasure value, including coins, diamonds, and gold bars.
- Coffin deposits now accept every positive-value carried treasure and animate its real collectible model into the coffin; gold bars contribute 45 treasure and use their dedicated sound while diamonds continue to contribute five.
- Mixed treasure piles now show their configured coins, diamonds, and gold bars as lightweight material-correct meshes in the 3D editor, matching the established coin-pile preview behaviour.
- Level editors can now configure coins, diamonds, and gold bars through ordinary exported fields in a visible Pile Contents inspector group; marked future treasure types are still added by the editor scene scan.
- Diamond facets now receive stronger stable per-face colour and brightness contrast, keeping the cut readable without relying on level-light specular highlights.
- Diamond faces now use stylized cool-and-warm emissive studio lighting with a moving sparkle sweep, making the cut lively and readable instead of physically realistic and dull.
- Diamonds now ignore coloured torch tint while refracting the scene behind them, with subtle colour dispersion and sharp view-dependent facet sparkles supporting their edge bloom.
- Diamond bloom now follows the cut edges through a separate Fresnel overlay, keeping the glass transparent and its individual facets readable instead of solid white.
- Diamonds now settle on their faceted faces using a convex jewel-shaped collider, high friction, minimal bounce, and stronger angular damping.
- Vampire Maze setting changes now regenerate automatically while independently deterministic layout generation keeps the same maze geometry for the same seed.
- The generated Vampire Maze exit now occupies a straight bottom-wall run with intact corner walls, and an unlock-gated exterior staircase completes the level only from its summit.
- Generated Vampire Maze gates now use a single-tile boundary opening between solid wall shoulders; the reusable locked gate is only rotated and positioned, retaining its authored scale.
- Confirmed player sight now has absolute priority for the Vampire: sounds, searches, junction scans, backtracking, and aerial-scan requests cannot interrupt its routed chase.
- Vampire sight now samples independently on every physics frame, so crossing a clear floor-level sightline immediately forces the boss into its player chase regardless of its previous state.
- The Vampire now has short-range wall-occluded awareness in addition to its body-width sight sweep, so a player cannot slip immediately past when the wider cast brushes a nearby wall edge.
- A visible player choosing another branch at a junction now invalidates the Vampire's stale chase route immediately, without increasing routine route recalculation frequency.
- Confirmed sight now repairs any stale junction-scan state immediately, and visible pursuit uses bounded route-aware interception with faster half-second updates while reacquisition and branch changes remain anchored to the player's confirmed position.
- Final Vampire chase waypoints now use capsule-sized wall clearance instead of the wider corridor centre, and completed visible routes retry on the normal interval so a player cannot remain safe by pressing into a corner.
- After losing sight, the Vampire now predicts a reachable target from only the player's last confirmed positions and direction, then searches further along that direction before returning to ordinary hunting.
- Last-seen follow-up searches now choose the strongest deterministic forward route and carry the route's arrival direction around obstacles, preventing random wandering after a player circles a single wall block.
- Vampire pursuit routes now retain adjacent maze-cell waypoints, preventing its wide collision body from cutting diagonally into walls while chasing around corners.
- Generated Maze settings now expose a deterministic internal-connection count; extra passages create alternate loops and never remove cells from the outer wall.
- Vampire Maze coin piles now form evenly spaced route breadcrumbs while challenging exploration piles are spread across the whole journey instead of clustering in one region; the pile budget supports up to 256 piles.
- The Vampire now periodically rises above the maze, performs a full aerial turn to reveal the player's position, lands, and route-finds to that newly observed target.
- Generated Vampire Maze treasure piles now prefer their configured spacing, relax it deterministically on compact maps to honour the full distinct pile budget, and keep coffins away from nearby treasure where space permits.
- Diamonds now use clearer, nearly colourless glass with tighter reflections and neutral bloom instead of a cyan-filled appearance.
- Each emissive, refractive diamond uses one sack unit, carries five treasure value, and temporarily reuses coin sounds.
- Coins and gold bars now share a reflective gold finish that stays visible in darkness, responds to nearby lights, and produces a clearer indoor bloom.
- The PNG-to-GridMap dock now yields to the available editor width and height instead of collapsing Godot's bottom panel when several scenes or scripts are restored.
- PNG-to-GridMap settings are now persisted only for scenes inside a subfolder of `levels`, preventing editor configuration files from appearing beside player and other shared scenes.
- Windows level editors can now run one-click normal and Compatibility PNG-to-GridMap diagnostics that find Godot automatically and package verbose logs, graphics details, Windows errors, and crash dumps for sharing.
- PNG-to-GridMap resource discovery now follows Godot's edited-scene, filesystem-scan, and reimport lifecycle, preventing startup crashes on freshly imported colleague machines.
- Zombies and skeletons again use compact fake ground shadows; their overhead warning lights still cast level-geometry shadows without projecting oversized character silhouettes.
- Gold bars use distinct landing and pickup sounds and can be included in configurable mixed treasure piles.
- Gold bars can now be collected into 45 sack units and dropped back into the world as physical objects.
- Indoor walls and other lit faces no longer turn black from zero-bias self-shadowing.
- Indoor lighting now preserves the torch's authored shadow bias, preventing zero-bias concentric shadow acne around lit torches.
- Torch OmniLights use a dedicated shadow-caster mask to ignore their own model while still illuminating it and casting shadows.
- Nearby unlit torches now gain a subtle warm shader outline that fades with distance and disappears once lit.
- Torch flame particle effect.
- Wall-mounted torches now begin dark, light after the stationary player faces them, and remain lit across level restarts to improve navigation over successive runs.
- Invalid or unavailable remembered level slots now fall back safely to the first available level.
- Level selection now saves keyboard, joypad, and focus changes, restoring that same card on the next visit.
- The level-select heading and card text now author Almendra Bold directly.
- Each level card now uses the new level background artwork, while the screen retains its original page background and supports the renamed direct card nodes.
- Level selection now uses three large columns with TV-readable card titles, outcomes, treasure percentages, and play counts.
- The level-select frame and cards are larger, with each card led by its authored display name instead of a repeated level number.
- Level outcome, treasure caption, emphasised percentage, and play count now use separate card rows for clearer results.
- Returning to level selection now positions the remembered level fully inside the viewport before showing it.
- Moving focus beyond the visible level rows now scrolls quickly with eased motion instead of snapping the viewport.
- Level selection now includes sixteen playable slots, with the additional placeholders reusing Level 1 until their own levels are authored.
- Level cards now distinguish failed attempts, partial-treasure escapes, and 100% treasure successes without truncating their status text.
- Each level card now tracks and displays how many times that level slot has been played.
- Failed level cards now retain and display their best collected-treasure percentage alongside their play count.
- Tutorial levels can now be marked in the level lookup, and the most recently played level is highlighted when level selection opens.
- The level-select screen now scrolls through additional level rows with the mouse wheel and keeps keyboard or joypad selections visible automatically.
- Level selection now uses a clearer graveyard-styled frame, compact numbered cards, stronger focus states, and visible control hints.
- PNG-to-GridMap wall-piece and floor-material locations are now editable shared settings, with their existing locations retained as defaults.
- The redundant new-configuration action has been removed now that PNG-to-GridMap tile choices are shared automatically.
- Tooltips now explain the PNG-to-GridMap controls.
- PNG-to-GridMap can now automatically repair connected wall pieces shortly after painting stops, without repairing every tile during a brush stroke.
- The redundant GridMap output text has been disabled.
- PNG-to-GridMap now separates shared MeshLibrary colour and tile mappings from level-specific PNG, GridMap, export, floor, and auto-repair settings stored beside each level scene.
- Level editors can now create or rebuild a collision-backed floor from every non-transparent PNG pixel, using one batched GridMap tile and a selectable authored floor material in the floors folder.
- PNG-to-GridMap floor materials are now selected from a configurable project folder, replacing converter-owned texture and tiling controls so authored materials remain the source of their appearance.
- Imported wall and generated floor cells now use a fixed, grounded coordinate convention. No more cell->centre y changes. Disabled unused parameters.
- Connected tile mappings can now share an explicit connectivity group, allowing different colours or mesh sets to repair as one continuous wall type.
- Autotile mappings can now list decorative alternative pieces with their connection shape and rotation; repair preserves matching alternatives, corrects their orientation, and replaces them only when their neighbours require another shape. Only currently placeable in the gridmap editor in godot.
- GridMap repair is now an undoable editor action with coverage summaries and warnings for configured, skipped, and changed cells.
- PNG-to-GridMap profiles now retain selected GridMaps, floor materials, paths, export bounds, and auto-repair choices independently for each level while continuing to share the MeshLibrary catalogue.
- The PNG-to-GridMap dock has been reorganised around clearer wall configuration, level settings, floor-material selection, validation, and import/export actions.
- Selecting a supported Path3D and clicking one of its path points now seeks the matching animation marker and centres that arrival time in the Animation timeline.
- Kill-boundary path points now maintain named arrival markers derived from movement speed, making path timing visible and directly previewable in the editor.
- Editing a kill-boundary movement-speed key can now ripple-retime keys and markers on both sides of the edit so authored events remain attached to the same travelled positions.

- Kill-boundary animation duration now follows the distance and keyed movement speed needed to reach the end of the path instead of a separate per-level playback-duration setting.
- Kill-boundary size animation now uses explicit world-space width and depth tracks, preserving existing level dimensions without relying on scaled centre nodes.
- Level 6 now converts its original fixed 8-metre Flame Boundary scale into equivalent world-space sizes while retaining the incoming extended layout.
- Kill boundaries now expose editor-friendly controls for world size, path looping, shape morphing, segment count, flame or ghost presentation, player blockers, damage, and proximity audio.
- Kill-boundary collision, visuals, blockers, damage, audio, animation, removal, and editor-preview responsibilities have been split into focused scripts.
- Levels 1, 2, and 3 have been migrated to the new world-size kill-boundary animation tracks, and levels 6 and 8 now derive boundary duration automatically.
- Indoor lights now cast fully opaque shadows so areas behind walls stay dark.
- Indoor GridMaps now add batched, closed shadow volumes only for wall items, preventing light leaks without placing black shadow boxes beneath flagstone floors.
- Indoor GridMap walls now retain their authored face-culling settings so every intended wall face remains visible.
- Indoor headlamps now use a wide, shadow-safe 82-degree cone with a 60-metre range and gentler falloff while retaining their authored height.
- Indoor levels now place the player's shadow-casting omnidirectional fill at the headlamp, approximating local reflections around the visible area.
- Player light cone, range, falloff, placement, visibility, and shadow settings now live in the player scene, while flicker colours are exposed in the editor.
- Coins stop casting shadows only while flying into a treasure deposit, while collectible and dropped coins retain their shadows.
- Level 7 draft.
- Gold and silver keys now include dedicated player pickup areas, making collection more reliable without changing their physical rigid-body collisions.
- Holding the drop action now accelerates from deliberate individual drops to rapid unloading, while dropped items spread across a small deterministic angle instead of piling into one line.
- Treasure-deposit behavior is now packaged with its coffin as a reusable scene, reducing per-level setup and keeping every placed deposit consistently configured.
- Scene validation now covers relevant addon scenes while excluding only intentionally unsupported addon/test paths, and lint reporting now counts the same production scripts that are actually linted.
- Settings now fills the active display, Reset Progress raises a clearly layered confirmation as soon as it is clicked before clearing saved progress, and Back reliably returns players to level selection.
- Settings volume sliders now use double-thickness tracks centred vertically beside their icons and labels.
- Settings Back navigation now responds immediately to both mouse and joypad presses and reports scene-loading failures instead of silently remaining on the page.
- Settings now explicitly activates the focused Reset, Back, Yes, or No control from the joypad primary button, matching mouse activation throughout the complete settings flow.
- Win and Lose screens now scale their complete 1920x1080 layouts to the active display and explicitly activate focused Level Select or Retry actions from mouse, keyboard, and joypad primary presses.
- Shop items now purchase immediately when their row is clicked or activated, and Level Select is the only remaining bottom action.
- Shop resource balances now hide individual zero-count boxes and remove the complete balance row when the player owns no spendable resources.
- Frontend buttons now play selection feedback, successful shop purchases have a distinct sound, and joypad focus movement is audible across menus.
- Holding a joypad stick or directional button now repeatedly scrolls through level and shop lists after a short delay.
- Shop and level-list joypad movement now plays cursor feedback directly after focus reaches a different row, avoiding input-order-dependent silence.
- Level selection now hides the Liberated Loot heading and its complete section until a played tomb has actually yielded liberated treasure.
- Skeletons and zombies now block one another, with skeleton patrols reversing before enemies overlap instead of walking through or over them.
