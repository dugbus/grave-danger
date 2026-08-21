extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/spike_trap/spike_trap.gd")
const SUBJECT_PATH := "res://placeables/spike_trap/spike_trap.gd"
const EDITOR_PLACEMENT_SUBJECT := preload(
	"res://placeables/spike_trap/spike_trap_editor_placement.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_scene_uses_fixed_height_editor_placement()


func _test_scene_uses_fixed_height_editor_placement() -> void:
	var scene := load("res://placeables/spike_trap/spike_trap.tscn") as PackedScene
	var spike_trap := scene.instantiate() as GDSpikeTrap

	expect(
		spike_trap.get_node("FixedHeightEditorPlacement").get_script() \
			== EDITOR_PLACEMENT_SUBJECT,
		"The reusable spike-trap scene corrects its editor height."
	)

	spike_trap.free()
