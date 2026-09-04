extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/playthrough_position_markers/export_scene_stripper.gd"
)
const SUBJECT_PATH := \
	"res://addons/playthrough_position_markers/export_scene_stripper.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var stripper := SUBJECT.new() as RefCounted
	var scene_root := Node3D.new()
	var gameplay_root := Node3D.new()
	gameplay_root.name = "Gameplay"
	scene_root.add_child(gameplay_root)

	var marker_group := Node3D.new()
	marker_group.name = "RenamedAuthoringTrace"
	marker_group.set_meta(&"playthrough_position_markers", true)
	gameplay_root.add_child(marker_group)
	marker_group.add_child(Path3D.new())
	marker_group.add_child(Label3D.new())

	expect(
		stripper.strip_marker_groups(scene_root),
		"Export customization reports that it removed an authoring marker group."
	)
	expect_equal(
		gameplay_root.get_child_count(),
		0,
		"Marker paths and labels are removed with their metadata-marked container."
	)
	expect_equal(
		scene_root.get_child_count(),
		1,
		"Unrelated gameplay nodes remain in the exported scene."
	)
	expect(
		not stripper.strip_marker_groups(scene_root),
		"A scene without authoring markers does not require export customization."
	)
	scene_root.free()
