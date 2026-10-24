# Enemy patrol timing baseline

`patrol_timing.json` records the skeleton and zombie behaviour before extracting
shared presentation helpers, using Godot 4.7.2 at 60 physics ticks per second.
Each six-second case uses an open, three-point patrol on a flat floor and covers
immediate spawn, delayed spawn, or looping. The enemies retain their authored
movement speeds, acceleration, turning, drop duration, and animation rates.

The co-located `patrol_timing_test.gd` compares position, path progress, patrol
state and direction, spawn/drop progress, facing, animation selection/rate, and
random-generator state at regular checkpoints. It also compares every footstep
and landing cue's exact physics tick and sample. Animation advances manually so
rendering frequency cannot change the recorded cue times. The audio playback
host captures requests without starting a hardware decoder.

The fixture is a behaviour contract, not runtime configuration. Tests never
rewrite it. Update it only when deliberately changing enemy timing, after
reviewing the affected patrols. A presentation-only refactor must preserve it.

Run it with:

```sh
godot --headless --path . --script res://tests/test_runner.gd --log-file scene_scan.log -- --test-file=res://enemies/patrol_timing_test.gd
```
