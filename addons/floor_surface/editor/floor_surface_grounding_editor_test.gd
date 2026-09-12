extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/floor_surface/editor/floor_surface_grounding_editor.gd"
)
const GROUNDING_SCRIPT := preload("res://addons/floor_surface/floor_surface_grounding.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_grounding_editor.gd"
	)
	await _test_conform_plan_and_reversible_state(tree)


func _test_conform_plan_and_reversible_state(tree: SceneTree) -> void:
	var root := Node3D.new()
	var surface := SURFACE_SCRIPT.new()
	surface.name = "Surface"
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i.ONE
	floor_map.default_present = true
	floor_map.default_elevation = 8
	surface.floor_map = floor_map
	surface.elevation_profile = PROFILE_SCRIPT.new()
	root.add_child(surface)
	var target := Node3D.new()
	target.name = "GroundedTarget"
	target.position = Vector3(0.5, 7.0, 0.5)
	root.add_child(target)
	var grounding := GROUNDING_SCRIPT.new()
	target.add_child(grounding)
	grounding.surface_path = NodePath("../../Surface")
	var absolute_target := Node3D.new()
	absolute_target.name = "AbsoluteTarget"
	absolute_target.position = Vector3(0.5, 9.0, 0.5)
	root.add_child(absolute_target)
	var absolute_grounding := GROUNDING_SCRIPT.new()
	absolute_target.add_child(absolute_grounding)
	absolute_grounding.surface_path = NodePath("../../Surface")
	absolute_grounding.grounding_mode = GROUNDING_SCRIPT.GroundingMode.Absolute
	tree.root.add_child(root)
	var plan := SUBJECT.plan_conform(root, surface)
	var changes := plan["changes"] as Array[Dictionary]
	expect_equal(changes.size(), 2, "The editor finds ordinary and absolute components for one surface.")
	expect((plan["errors"] as Array[String]).is_empty(), "Valid grounded objects have no skipped errors.")
	var ordinary_change := changes[0]
	grounding.apply_grounding_state(
		ordinary_change["after_transform"] as Transform3D,
		ordinary_change["after_stale"] as bool
	)
	expect(is_equal_approx(target.global_position.y, 2.0), "The planned do state conforms to the surface.")
	grounding.apply_grounding_state(
		ordinary_change["before_transform"] as Transform3D,
		ordinary_change["before_stale"] as bool
	)
	expect(is_equal_approx(target.global_position.y, 7.0), "The planned undo state restores authored placement.")
	expect(is_equal_approx(absolute_target.global_position.y, 9.0), "Planning never mutates absolute objects.")
	root.queue_free()
	await tree.process_frame

