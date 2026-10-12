extends SkeletonModifier3D

## Add attention yaw after animation and foot IK without replacing the authored pose.
var head_yaw := 0.0
var head_bone := -1
var head_transform := Transform3D.IDENTITY


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if head_bone < 0:
		head_bone = skeleton.find_bone("DEF-spine.006")
	if head_bone < 0:
		return
	# Convert skeleton-space up into the animated parent's space so pitch and
	# roll remain authored and turning stays horizontal even during locomotion.
	var parent := skeleton.get_bone_parent(head_bone)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis
	var axis := (parent_basis.inverse() * Vector3.UP).normalized()
	var authored := skeleton.get_bone_pose_rotation(head_bone)
	skeleton.set_bone_pose_rotation(head_bone, Quaternion(axis, head_yaw) * authored)
	head_transform = skeleton.get_bone_global_pose(head_bone)
