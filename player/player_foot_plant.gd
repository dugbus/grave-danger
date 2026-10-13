extends SkeletonModifier3D
class_name GDPlayerFootPlant

## Prepare targets before native IK, then preserve the planted ankle and toe pose after IK.
## Godot restores the authored pose after modifiers, so corrections never accumulate.
enum ModificationPass { PrepareTargets, PreserveFootPose }

const SETTINGS := preload("res://player/player_gait_settings.tres")

## Place this modifier before IK to prepare targets, or after IK to preserve foot pose.
@export_storage var modification_pass := ModificationPass.PrepareTargets
## Target-preparation modifier read by the final foot-pose pass.
@export_storage var preparation_path: NodePath = ^"../FootPlant"

# A native base type avoids a self-script reference cycle through the preloaded settings resource.
@onready var preparation := get_node_or_null(preparation_path) as SkeletonModifier3D
@onready var left_target := get_node_or_null(^"../LeftFootTarget") as Node3D
@onready var right_target := get_node_or_null(^"../RightFootTarget") as Node3D
@onready var left_pole := get_node_or_null(^"../LeftKneePole") as Node3D
@onready var right_pole := get_node_or_null(^"../RightKneePole") as Node3D
@onready var left_ik := get_node_or_null(^"../LeftFootIK") as TwoBoneIK3D
@onready var right_ik := get_node_or_null(^"../RightFootIK") as TwoBoneIK3D

var walking := false
var grounded := false
var stationary := true
var phase := 0.0
var contact_scale := 1.0
var left_planted := false
var right_planted := false
var left_anchor := Transform3D.IDENTITY
var right_anchor := Transform3D.IDENTITY
var left_toe_anchor := Transform3D.IDENTITY
var right_toe_anchor := Transform3D.IDENTITY
var left_rendered := Transform3D.IDENTITY
var right_rendered := Transform3D.IDENTITY
var left_toe_rendered := Transform3D.IDENTITY
var right_toe_rendered := Transform3D.IDENTITY
var left_authored := Transform3D.IDENTITY
var right_authored := Transform3D.IDENTITY
var left_toe_authored := Transform3D.IDENTITY
var right_toe_authored := Transform3D.IDENTITY
var left_foot := -1
var right_foot := -1
var left_knee := -1
var right_knee := -1
var left_toe := -1
var right_toe := -1
var left_hip := -1
var right_hip := -1


func _ready() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	left_foot = skeleton.find_bone("DEF-foot.L")
	right_foot = skeleton.find_bone("DEF-foot.R")
	left_knee = skeleton.find_bone("DEF-shin.L")
	right_knee = skeleton.find_bone("DEF-shin.R")
	left_toe = skeleton.find_bone("DEF-toe.L")
	right_toe = skeleton.find_bone("DEF-toe.R")
	left_hip = skeleton.find_bone("DEF-thigh.L")
	right_hip = skeleton.find_bone("DEF-thigh.R")


func set_motion(is_walking: bool, is_grounded: bool, walk_phase: float, stance_scale: float = 1.0) -> void:
	walking = true
	stationary = not is_walking
	grounded = is_grounded
	phase = walk_phase
	contact_scale = stance_scale


func reset() -> void:
	walking = false
	grounded = false
	left_planted = false
	right_planted = false
	if left_ik != null:
		left_ik.influence = 0.0
	if right_ik != null:
		right_ik.influence = 0.0


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or left_foot < 0 or right_foot < 0:
		return
	if modification_pass == ModificationPass.PreserveFootPose:
		_preserve_foot_pose(skeleton)
		return
	sample_contacts()


## Sample every distance substep; native modifiers solve the final rendered pose once.
func sample_contacts() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or left_foot < 0 or right_foot < 0:
		return
	_prepare_foot(skeleton, true)
	_prepare_foot(skeleton, false)


func _prepare_foot(skeleton: Skeleton3D, left: bool) -> void:
	var foot := left_foot if left else right_foot
	var knee := left_knee if left else right_knee
	var target := left_target if left else right_target
	var pole := left_pole if left else right_pole
	var ik := left_ik if left else right_ik
	if target == null or pole == null or ik == null or knee < 0:
		return
	# Idle uses the authored pose without carrying walking anchors into the blend.
	var contact := walking and grounded and not stationary and SETTINGS.is_contact(phase, left, contact_scale)
	var planted := left_planted if left else right_planted
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(foot)
	var toe := left_toe if left else right_toe
	var toe_pose := skeleton.global_transform * skeleton.get_bone_global_pose(toe)
	if left:
		left_authored = pose
		left_toe_authored = toe_pose
	else:
		right_authored = pose
		right_toe_authored = toe_pose
	if contact and not planted:
		if left:
			left_anchor = pose
			left_toe_anchor = toe_pose
		else:
			right_anchor = pose
			right_toe_anchor = toe_pose
	if left:
		left_planted = contact
	else:
		right_planted = contact
	ik.influence = SETTINGS.contact_weight(phase, left, contact_scale) if contact else 0.0
	target.global_transform = (left_anchor if left else right_anchor) if contact else pose
	# Follow the authored knee bend so the IK cannot flip to the other side.
	var knee_pose := skeleton.get_bone_global_pose(knee)
	var hip := left_hip if left else right_hip
	var hip_position := skeleton.get_bone_global_pose(hip).origin
	var ankle_position := skeleton.get_bone_global_pose(foot).origin
	var leg_axis := (ankle_position - hip_position).normalized()
	var knee_offset := knee_pose.origin - hip_position
	var bend_direction := knee_offset - leg_axis * knee_offset.dot(leg_axis)
	bend_direction = (bend_direction.normalized() if bend_direction.length_squared() > 0.000001 else Vector3.BACK)
	pole.global_position = skeleton.to_global(knee_pose.origin + bend_direction * 0.2)


func _preserve_foot_pose(skeleton: Skeleton3D) -> void:
	if preparation == null:
		return
	var inverse := skeleton.global_transform.affine_inverse()
	# Native IK and final ankle/toe correction share the same eased weight.
	# Interpolate from the pre-IK authored pose to avoid applying the blend twice.
	if preparation.left_planted:
		var weight: float = preparation.left_ik.influence
		skeleton.set_bone_global_pose(
			left_foot, inverse * preparation.left_authored.interpolate_with(preparation.left_anchor, weight)
		)
		skeleton.set_bone_global_pose(
			left_toe, inverse * preparation.left_toe_authored.interpolate_with(preparation.left_toe_anchor, weight)
		)
	if preparation.right_planted:
		var weight: float = preparation.right_ik.influence
		skeleton.set_bone_global_pose(
			right_foot, inverse * preparation.right_authored.interpolate_with(preparation.right_anchor, weight)
		)
		skeleton.set_bone_global_pose(
			right_toe, inverse * preparation.right_toe_authored.interpolate_with(preparation.right_toe_anchor, weight)
		)
	left_rendered = skeleton.global_transform * skeleton.get_bone_global_pose(left_foot)
	right_rendered = skeleton.global_transform * skeleton.get_bone_global_pose(right_foot)
	left_toe_rendered = skeleton.global_transform * skeleton.get_bone_global_pose(left_toe)
	right_toe_rendered = skeleton.global_transform * skeleton.get_bone_global_pose(right_toe)
