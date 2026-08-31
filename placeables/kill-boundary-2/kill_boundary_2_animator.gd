@tool
class_name GDKillBoundary2Animator
extends Node

## Deterministic sequence clock and pose evaluator without animation tracks.

signal state_changed(state: GDKillBoundary2State)
signal playback_finished

enum PlaybackMode {
	SingleShot,
	Loop,
	PingPong,
}

var sequence: GDKillBoundary2Sequence
var playback_mode := PlaybackMode.SingleShot
var playback_speed := 1.0
var loop_return_seconds := 1.0
var playback_phase := 0.0
var authored_position := 0.0
var playing := false
var paused := false
var finished_emitted := false
var state := GDKillBoundary2State.new()


func configure(
	new_sequence: GDKillBoundary2Sequence,
	new_playback_mode: PlaybackMode,
	new_playback_speed: float,
	new_loop_return_seconds := 1.0
) -> void:
	sequence = new_sequence
	playback_mode = new_playback_mode
	playback_speed = maxf(new_playback_speed, 0.0)
	loop_return_seconds = maxf(new_loop_return_seconds, 0.01)
	seek(authored_position)


func restart(should_play := true) -> void:
	playback_phase = 0.0
	authored_position = 0.0
	playing = should_play
	paused = false
	finished_emitted = false
	evaluate_at(0.0)


func stop() -> void:
	playing = false


func set_paused(value: bool) -> void:
	paused = value


func seek(time_seconds: float) -> void:
	var duration := get_playback_duration()
	authored_position = clampf(time_seconds, 0.0, duration)
	playback_phase = authored_position
	finished_emitted = false
	_evaluate_playback_position(authored_position)


func advance(delta: float) -> void:
	if not playing or paused or sequence == null:
		return
	var duration := _get_duration()
	if duration <= 0.0:
		authored_position = 0.0
		evaluate_at(0.0)
		return
	playback_phase += maxf(delta, 0.0) * playback_speed
	match playback_mode:
		PlaybackMode.SingleShot:
			authored_position = minf(playback_phase, duration)
			if playback_phase >= duration:
				playing = false
				if not finished_emitted:
					finished_emitted = true
					playback_finished.emit()
		PlaybackMode.Loop:
			var cycle_duration := get_playback_duration()
			authored_position = fposmod(playback_phase, cycle_duration)
		PlaybackMode.PingPong:
			var cycle_position := fposmod(playback_phase, duration * 2.0)
			authored_position = duration - absf(duration - cycle_position)
	_evaluate_playback_position(authored_position)


## Complete preview/runtime timeline length, including Loop's closing transition.
func get_playback_duration() -> float:
	var authored_duration := _get_duration()
	if (
		playback_mode == PlaybackMode.Loop
		and sequence != null
		and sequence.get_pose_count() > 1
		and authored_duration > 0.0
	):
		return authored_duration + maxf(loop_return_seconds, 0.01)
	return authored_duration


func evaluate_at(time_seconds: float) -> GDKillBoundary2State:
	if sequence == null or sequence.get_pose_count() == 0:
		state.set_values(Vector3.ZERO, 0.0, Vector2(8.0, 8.0), 0.0)
		state_changed.emit(state)
		return state
	var pose_count := sequence.get_pose_count()
	if pose_count == 1 or time_seconds <= 0.0:
		_copy_pose_to_state(sequence.get_pose(0))
		state_changed.emit(state)
		return state
	var last_pose := sequence.get_pose(pose_count - 1)
	if time_seconds >= last_pose.time_seconds:
		_copy_pose_to_state(last_pose)
		state_changed.emit(state)
		return state
	for index in pose_count - 1:
		var pose_a := sequence.get_pose(index)
		var pose_b := sequence.get_pose(index + 1)
		if time_seconds > pose_b.time_seconds:
			continue
		var duration := maxf(pose_b.time_seconds - pose_a.time_seconds, 0.000001)
		var ratio := clampf((time_seconds - pose_a.time_seconds) / duration, 0.0, 1.0)
		return _interpolate_poses(pose_a, pose_b, ratio)
	_copy_pose_to_state(last_pose)
	state_changed.emit(state)
	return state


func _evaluate_playback_position(time_seconds: float) -> GDKillBoundary2State:
	var authored_duration := _get_duration()
	if (
		playback_mode != PlaybackMode.Loop
		or sequence == null
		or sequence.get_pose_count() < 2
		or time_seconds <= authored_duration
	):
		return evaluate_at(time_seconds)
	var return_ratio := clampf(
		(time_seconds - authored_duration) / maxf(loop_return_seconds, 0.01), 0.0, 1.0
	)
	var last_pose := sequence.get_pose(sequence.get_pose_count() - 1)
	return _interpolate_poses(last_pose, sequence.get_pose(0), return_ratio)


func _interpolate_poses(
	pose_a: GDKillBoundary2Pose, pose_b: GDKillBoundary2Pose, ratio: float
) -> GDKillBoundary2State:
	var eased := _apply_easing(clampf(ratio, 0.0, 1.0), pose_a.outgoing_easing)
	state.set_values(
		pose_a.position.lerp(pose_b.position, eased),
		lerp_angle(pose_a.yaw_radians, pose_b.yaw_radians, eased),
		pose_a.size.lerp(pose_b.size, eased),
		lerpf(pose_a.rounding, pose_b.rounding, eased)
	)
	state_changed.emit(state)
	return state


func _apply_easing(ratio: float, easing: GDKillBoundary2Pose.TransitionEasing) -> float:
	match easing:
		GDKillBoundary2Pose.TransitionEasing.Smooth:
			return ratio * ratio * (3.0 - 2.0 * ratio)
		GDKillBoundary2Pose.TransitionEasing.Accelerate:
			return ratio * ratio
		GDKillBoundary2Pose.TransitionEasing.Decelerate:
			return 1.0 - (1.0 - ratio) * (1.0 - ratio)
		GDKillBoundary2Pose.TransitionEasing.Constant:
			return ratio
	return ratio


func _copy_pose_to_state(pose: GDKillBoundary2Pose) -> void:
	state.set_values(pose.position, pose.yaw_radians, pose.size, pose.rounding)


func _get_duration() -> float:
	return sequence.get_duration() if sequence != null else 0.0
