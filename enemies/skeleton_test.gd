extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton.gd")
const SUBJECT_PATH := "res://enemies/skeleton.gd"
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")
const OCCLUSION_BLOCKER_SCRIPT := preload("res://player/visibility/player_occlusion_blocker.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_authored_start_matches_first_path_point()
	_test_rotated_path_keeps_skeleton_upright(tree)
	await _test_skeleton_blocks_player_silhouette(tree)
	await _test_support_loss_and_lower_landing(tree)


func _test_authored_start_matches_first_path_point() -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Path3D
	var path_follow := skeleton.get_node(^"PathFollow3D") as PathFollow3D
	var drop_pivot := skeleton.get_node(^"PathFollow3D/DropPivot") as Node3D
	var skeleton_body := skeleton.get_node(^"PathFollow3D/DropPivot/SkeletonBody") as AnimatableBody3D
	var editor_placement := skeleton.get_node(^"GroundEditorPlacement") as GDGroundEnemyEditorPlacement
	var first_path_point := skeleton.curve.get_point_position(0)
	expect(
		first_path_point.is_zero_approx() and path_follow.position.is_equal_approx(first_path_point),
		"The skeleton editor origin, character carrier, and first patrol point coincide."
	)
	expect(
		(
			is_zero_approx(path_follow.position.y)
			and is_zero_approx(drop_pivot.position.y)
			and is_zero_approx(skeleton_body.position.y)
		),
		"The authored skeleton body origin rests at ground height."
	)
	expect_equal(
		editor_placement.floor_sample_path,
		NodePath("../PathFollow3D"),
		"The skeleton editor placement helper samples its path follower position."
	)
	skeleton.free()


func _test_rotated_path_keeps_skeleton_upright(tree: SceneTree) -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Node3D
	skeleton.rotation = Vector3(0.35, 1.2, -0.25)
	tree.root.add_child(skeleton)
	var drop_pivot := skeleton.get_node(^"PathFollow3D/DropPivot") as Node3D
	expect(
		drop_pivot.global_basis.is_equal_approx(Basis.IDENTITY),
		"A rotated patrol path does not tilt or turn the skeleton carrier."
	)
	skeleton.free()


func _test_skeleton_blocks_player_silhouette(tree: SceneTree) -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Node3D
	tree.root.add_child(skeleton)
	await tree.process_frame
	var blocker := skeleton.get_node(^"PathFollow3D/DropPivot/Pivot/PlayerOcclusionBlocker") as OCCLUSION_BLOCKER_SCRIPT
	expect(
		blocker.is_blocking_active() and blocker.get_blocked_mesh_count() > 0,
		"A visible skeleton blocks the player's through-scenery silhouette."
	)
	skeleton.free()


# Flow: Losing a raised floor pauses patrol, starts gravity, and permits landing on a lower surface.
func _test_support_loss_and_lower_landing(tree: SceneTree) -> void:
	var fixture := Node3D.new()
	var upper_floor := _add_floor(fixture, 2.0)
	_add_floor(fixture, -1.0)
	var skeleton := SKELETON_SCENE.instantiate() as GDSkeletonPath
	skeleton.position.y = 2.0
	skeleton.spawn_time = 0.0
	skeleton.shuffle_speed = 0.0
	skeleton.curve = Curve3D.new()
	skeleton.curve.add_point(Vector3.ZERO)
	skeleton.curve.add_point(Vector3.RIGHT * 2.0)
	skeleton.loop_patrol = false
	fixture.add_child(skeleton)
	tree.root.add_child(fixture)
	skeleton.footstep_sounds.clear()
	skeleton.landing_sound = null
	for frame in 10:
		await tree.physics_frame
		await tree.process_frame
	expect(skeleton.has_landed, "The skeleton settles on its elevated starting floor.")
	expect(
		is_equal_approx(skeleton.path_follow.global_position.y, 2.0),
		"Repeated support checks keep the skeleton at the authored 2m floor height."
	)
	skeleton.shuffle_speed = 0.75
	for frame in 10:
		await tree.physics_frame
		await tree.process_frame
	var grounded_progress := skeleton.path_follow.progress
	expect(grounded_progress > 0.05, "The supported skeleton continues its patrol.")
	upper_floor.free()
	var body_follows_fall := true
	for frame in 20:
		await tree.physics_frame
		await tree.process_frame
		body_follows_fall = (
			body_follows_fall
			and skeleton.skeleton_body.global_position.is_equal_approx(skeleton.drop_pivot.global_position)
		)
	expect(not skeleton.has_landed and skeleton.fall_velocity < 0.0, "Losing support reactivates gravity.")
	expect(
		skeleton.path_follow.global_position.y < 1.8 and skeleton.path_follow.global_position.y > -0.5,
		"The skeleton falls through the intervening air instead of snapping to the lower floor."
	)
	expect(
		is_equal_approx(skeleton.path_follow.progress, grounded_progress),
		"Patrol pauses while the skeleton is airborne."
	)
	expect(body_follows_fall, "The blocking body follows the visible skeleton throughout its fall.")
	for frame in 60:
		await tree.physics_frame
		await tree.process_frame
	expect(skeleton.has_landed and is_zero_approx(skeleton.fall_velocity), "The skeleton lands on the lower floor.")
	expect(
		is_equal_approx(skeleton.path_follow.global_position.y, -1.0),
		"Landing preserves the lower floor height without returning to the original patrol elevation."
	)
	expect(skeleton.path_follow.progress > grounded_progress + 0.05, "Patrol resumes after landing.")
	fixture.free()
	await tree.process_frame


func _add_floor(parent: Node3D, height: float) -> StaticBody3D:
	var floor_body := StaticBody3D.new()
	floor_body.position.y = height - 0.25
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.0, 0.5, 6.0)
	collision.shape = shape
	floor_body.add_child(collision)
	parent.add_child(floor_body)
	return floor_body
