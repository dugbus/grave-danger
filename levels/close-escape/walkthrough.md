# Close Escape: route and collection guide

## Authored visual dressing

In `level.tscn`, select `CloseEscape/FloorGridMap` directly to paint the floor.
It is a native child of the main scene, with its cells saved there, not in a nested instance.
Expand the editable `AuthoredLayout` instance to paint `WallGridMap`; its source remains
`authored_layout.tscn`. The floor follows Tutorial 1: one-metre tiles, four alternating UV
phases of the same dirt texture used by Level 1, and tile collision ending at Y=0.
There is no separate floor slab. Keep `AuthoredLayout` before `FloorGridMap` in the
scene tree because zombie navigation selects the first grid covering its route.

The 134 road cells form interrupted worn paths and small asymmetric threshold
aprons rather than paving every room. All 297 original wall cells are unchanged.
Road stones have no collision and stay off the spike plates.

Expand the editable `PaintedGrass` instance in the main level (or open its source,
`painted_grass.tscn`) and select one of its four SimpleGrassTextured groups to
continue painting with Level 1's grass mesh and gradient. Western wall recesses
carry the strongest growth; the middle court and northern crypt have shorter
broken fringes; the vault has only a handful of seam tufts. Keep the broad dirt
clearings, visible rewards, and bare trap approaches. Grass is stored as editable
MultiMesh paint data, not generated during gameplay.

The art pass preserves keys, caches, enemies, walls, flame timing and the route.
The completion-route model and real zombie doorway checks also pass on the tiled floor.

## Trailing flame, not timed access

All future rooms and the northern exit approach begin inside the safe perimeter. Silver doors
still require their keys. The flame advances from west to east, then from the southern vault
toward the northern exit; there are no scheduled expansions to wait for.

Unlocking a district door smoothly accelerates the trailing flame toward that district's
authored checkpoint. Earlier arrivals therefore bring pressure forward instead of waiting for
a global schedule. Pause pickups pause that acceleration too. The flame never rewinds when
an earlier door is revisited. Collect a district's optional treasure before leaving it.

## Full-collection route

North means negative Z on the authored map, not necessarily screen-up under a rotated camera.

1. Western district: collect both southern caches, bank at the southern coffin, collect the
   middle cache, get the northern silver key, and return to the southern silver door.
2. Middle district: collect the southwestern cache and southeastern key, then work north
   through the central cache and coffin to the northwestern cache. Use the northeastern
   silver door. There is no reason to wait for the eastern district to open.
3. Eastern district: collect the northwestern cache, bank at the northeastern coffin, collect
   the southeastern cache, and get the southwestern silver key. Enter the southern vault.
4. Vault: take the western two-spike branch for its optional 30 coins, bank at the vault
   coffin, collect the central 40 coins, and get the southeastern gold key. Bank again.
   Bait the quick and delayed traps separately; allow time for the return crossing.
5. Return through the vault door and head north to the gold gate immediately. The flame
   closes from behind; the exit approach no longer waits for a later expansion.

Ten caches contain **240 coins**, with no gems. Western and middle districts each contain
65 coins, the upper eastern district 40, and the vault 70. Banking in this order fits the base
100-coin capacity. Pick up scattered coins before leaving. Skipping the western vault's
30-coin spike branch makes an easier escape but prevents 100%.

## Evidence and limits

On 2026-09-05 the player reported **100% completion** after the dead-zombie collision fix.
The subsequent doorway-navigation change corrects numerical floor-layer selection only;
treasure placement and flame pacing are unchanged.

The old saved markers record a 1:04–1:32 wait, despite reaching the eastern doorway around
0:50, plus later return-route stops. That fixed schedule was validated only against a slower
route arriving at the same door around 1:40. The markers remain preserved in the scene.

A later replay exposed a separate trap at approximately 1:49: a zombie died on the western
vault spike at XZ (7.985, 9.957), leaving its upright collider in the return opening even after
its mesh disappeared. Zombie death now releases that collision immediately. The regression in
`vault_clearance_test.gd` reproduces the recorded obstruction with the actual player capsule
and checks that the opening stays clear both during death presentation and after disappearance.

The revised tests use the actual floor, static obstacles, lock order, door-frame collision,
and progression-driven flame clock. They cover a conservative 2.5-units/second collection
route, a 4.5-units/second collection route, a fast key-only escape, and a paused collection
route. Collection and banking pauses are included, with extra time for the optional spikes.
No route inserts waiting to gain access. Flame clearance is sampled throughout at 0.6 metres.

The conservative model finishes at approximately 3:13 without a pause pickup. Its modelled
timings are separate from the player's reported 100% run. Continue using human playtests to
judge combat and pressure, rather than treating route checks as proof of pacing quality.
