extends Node

## Close Escape only: advance the trailing flame when a district is unlocked.
## Forward access never depends on this clock; doors, not flame expansions, gate progress.

## Boundary whose authored poses remain editable in the level scene.
@export var boundary: GDKillBoundary2
## District passages, in route order, that bring the trailing flame forward.
@export var passages: Array[GDLockableHingedPassage] = []
## Authored pose reached after each corresponding passage unlocks.
@export var checkpoints: Array[GDKillBoundary2Pose] = []
## Additional authored seconds advanced per real second while catching up behind the player.
@export_range(0.1, 20.0, 0.1) var catch_up_rate := 4.0

var target_time := 0.0


func _ready() -> void:
	assert(passages.size() == checkpoints.size())
	for index in passages.size():
		passages[index].unlocked.connect(request_checkpoint.bind(checkpoints[index]))


func request_checkpoint(pose: GDKillBoundary2Pose) -> void:
	target_time = maxf(target_time, pose.time_seconds)


func _physics_process(delta: float) -> void:
	if boundary == null or boundary.animator == null or boundary.boundary_removed_for_level:
		return
	advance_catch_up(boundary.animator, delta)


## Use the same deterministic step in route tests; preserve pause and stopped-startup semantics.
func advance_catch_up(animator: GDKillBoundary2Animator, delta: float) -> void:
	if not animator.playing or animator.paused or animator.playback_speed <= 0.0:
		return
	var remaining := maxf(target_time - animator.authored_position, 0.0)
	var extra_seconds := minf(remaining, maxf(delta, 0.0) * catch_up_rate)
	if extra_seconds > 0.0:
		animator.advance(extra_seconds / animator.playback_speed)
