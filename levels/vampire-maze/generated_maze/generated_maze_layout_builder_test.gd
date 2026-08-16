extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://levels/vampire-maze/generated_maze/generated_maze_layout_builder.gd"
)
const SUBJECT_PATH := (
	"res://levels/vampire-maze/generated_maze/generated_maze_layout_builder.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var host := Node3D.new()
	var first_layout := SUBJECT.replace(host)
	var first_layout_id := first_layout.get_instance_id()
	var second_layout := SUBJECT.replace(host)
	expect(
		second_layout != null \
			and second_layout.get_instance_id() != first_layout_id \
			and host.get_child_count() == 1 \
			and second_layout.name == &"Layout" \
			and second_layout.has_node("PNGGridMap") \
			and second_layout.has_node("PNGFloorGridMap") \
			and not second_layout.has_node("RoutedFloorGridMap") \
			and second_layout.has_node("GeneratedContent"),
		"Layout replacement keeps Road tiles in the same GridMap as the walls."
	)
	host.free()
