# Shared enemy presentation

Skeletons and zombies compose the same focused helpers:

- `enemy_presentation.gd` handles imported animation lookup, geometry discovery,
  transparency, shadow layers, and light setup.
- `enemy_footsteps.gd` owns animation-phase contact history. Each enemy retains
  its sample selection, speed thresholds, audio settings, and seeded random
  generator. The existing phase property forwards to the shared tracker.
- `enemy_death_presentation.gd` builds the parallel sink and fade tween. Each enemy
  retains its death transition, delay, animation, visibility, and cleanup lifecycle.

These helpers have no frame callbacks and are invoked at the same points as the
previous implementations. Movement, gravity, patrol selection, spawn/drop-in,
turning, and animation selection remain owned by the existing enemy scripts.
All scene paths and Inspector settings remain available. The existing
`skeleton_presentation.gd` entry points delegate to the shared visual helper.

`patrol_timing_test.gd` and `test_fixtures/patrol_timing.json` protect the existing
patrol and cue timing. Shared visual operations, contact-phase tracking, and death
fade easing also have focused sibling tests. The crumbling-floor contact suite
continues to exercise both enemy scenes through activation, collapse, falling,
and landing on a lower floor.
