extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_visual.gd")
const ASSET_SCENE := preload("res://Assets/environment/flagstone.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_visual.gd")
	for index in 2:
		var visual := ASSET_SCENE.instantiate() as SUBJECT
		tree.root.add_child(visual)
		expect_equal(
			visual.multimesh.instance_count, 16, "The asset wrapper preserves all authored blocks in one render batch."
		)
		expect_equal(visual.get_child_count(), 0, "The asset preview is one node regardless of its block count.")
		visual.rebuild(Vector3(2.0, 0.25, 2.0), null)
		expect_equal(visual.get_child_count(), 0, "Rebuilding never accumulates generated child nodes.")
		visual.free()
		await tree.process_frame
