@tool
class_name GDKillBoundary2Pose
extends Node3D

## One authored boundary pose. Its Node3D transform stores position and yaw.

signal pose_changed(pose: GDKillBoundary2Pose)

enum TransitionEasing {
	Constant,
	Smooth,
	Accelerate,
	Decelerate,
}

const MINIMUM_SIZE := 0.1

## Set the boundary's width and depth at this pose. Different values make a rectangle or oval;
## matching values make a square or circle depending on Rounding.
@export var size := Vector2(8.0, 8.0):
	set(value):
		size = Vector2(maxf(value.x, MINIMUM_SIZE), maxf(value.y, MINIMUM_SIZE))
		_emit_pose_changed()

## Change the corner shape at this pose. 0 is a sharp rectangle, values between 0 and 1 round the
## corners, and 1 is an ellipse. It becomes a perfect circle only when both Size values match.
@export_range(0.0, 1.0, 0.001) var rounding := 0.0:
	set(value):
		rounding = clampf(value, 0.0, 1.0)
		_emit_pose_changed()

## Choose when the boundary reaches this pose, measured from the start. Increase the gap between
## pose times for slower movement; Pose 1 always stays at 0 seconds.
@export_range(0.0, 3600.0, 0.01, "or_greater", "suffix:s") var time_seconds := 0.0:
	set(value):
		time_seconds = maxf(value, 0.0)
		_emit_pose_changed()

## Choose how movement leaves this pose. Constant moves evenly; Smooth starts and ends gently;
## Accelerate speeds up; Decelerate slows down.
@export var outgoing_easing := TransitionEasing.Constant:
	set(value):
		outgoing_easing = value as TransitionEasing
		_emit_pose_changed()

var yaw_radians: float:
	get:
		return rotation.y
	set(value):
		set_authored_transform(position, value)

var _sanitizing_transform := false


func _ready() -> void:
	set_notify_local_transform(true)
	_sanitize_transform()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_sanitize_transform()


## Applies the only supported spatial values: position and upright yaw.
func set_authored_transform(pose_position: Vector3, pose_yaw_radians: float) -> void:
	_set_authored_transform(pose_position, pose_yaw_radians)
	_emit_pose_changed()


## Copies all authored values without sharing mutable state.
func copy_values_from(source: GDKillBoundary2Pose) -> void:
	if source == null:
		return
	_set_authored_transform(source.position, source.yaw_radians)
	size = source.size
	rounding = source.rounding
	time_seconds = source.time_seconds
	outgoing_easing = source.outgoing_easing


func _sanitize_transform() -> void:
	if _sanitizing_transform:
		return
	var current_yaw := rotation.y
	var sanitized_basis := Basis(Vector3.UP, current_yaw)
	if basis.is_equal_approx(sanitized_basis):
		_emit_pose_changed()
		return
	_sanitizing_transform = true
	transform = Transform3D(sanitized_basis, position)
	_sanitizing_transform = false
	_emit_pose_changed()


func _set_authored_transform(pose_position: Vector3, pose_yaw_radians: float) -> void:
	_sanitizing_transform = true
	transform = Transform3D(Basis(Vector3.UP, pose_yaw_radians), pose_position)
	_sanitizing_transform = false


func _emit_pose_changed() -> void:
	if not _sanitizing_transform:
		pose_changed.emit(self)
