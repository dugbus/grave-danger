# Skellie skeleton presentation

`skellie.glb` came from the Halloween asset update. The reusable skeleton enemy
in `enemies/skeleton.tscn` instances `skellie.tscn` as its Character visual.

| Imported clip | Duration | Integration |
| --- | --- | --- |
| `walk` | 1⅓ seconds | Patrol walk. |
| `rest` | 1⅓ seconds | Exposed as `idle` for the existing enemy controller. |
| `attack` | 1⅓ seconds | Plays on confirmed lethal contact before the player's death animation. |
| `walkreal`, `restreal`, `attackreal` | 1⅓ seconds each | Static poses, retained but unused by the enemy. |

There is no imported death clip. `skellie_death.tres` supplies an editable,
non-looping visual fall as `die`, followed by the enemy's existing sink and fade.
Its duration and the existing death playback speed preserve the previous fall
duration. The imported model and animation resources remain unchanged; the scene
script adds aliases to an animation library belonging to each model instance.

The visual is scaled to 0.8 to match the previous skeleton's height, with no
translation or facing correction. Patrol roots, collision shapes, paths, spawn
settings, and movement logic retain their existing coordinates and behaviour.
The new walk is twice as long as the previous walk, so the enemy scene uses a
playback rate of 0.9 instead of 0.45 to retain the same cycle and footstep period.
The controller continues restarting completed clips as before.

Confirmed contact freezes the player in place and turns both characters toward
each other. The skeleton pauses at that contact position while its attack plays
at the authored speed. The player's death pose, effects, scream, camera focus,
and lose-screen countdown start when the attack finishes. Interrupted attacks
complete the death flow so the player cannot remain frozen. Patrol positions
and timing before contact retain the existing regression checkpoints.
Replay previews reproduce the waiting and death poses using preview-owned
state, without opening the live game's lose screen.

`skellie_test.gd` protects animation selection, instance isolation, stride period,
stationary carriers, and the death lifecycle. The existing patrol timing fixture
retains every gameplay and sound checkpoint; only the visual walk playback rate
changes in its skeleton samples.
