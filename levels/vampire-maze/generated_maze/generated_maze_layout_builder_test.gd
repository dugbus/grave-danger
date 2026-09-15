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
	var first_floor := first_layout.get_node("FloorSurface") as FloorSurface
	var first_map := first_floor.floor_map
	var first_style := first_floor.styles[0]
	var second_layout := SUBJECT.replace(host)
	var second_floor := second_layout.get_node("FloorSurface") as FloorSurface
	expect(
		second_layout != null \
			and second_layout.get_instance_id() != first_layout_id \
			and host.get_child_count() == 1 \
			and second_layout.name == &"Layout" \
			and second_layout.has_node("PNGGridMap") \
			and second_layout.has_node("FloorSurface") \
			and second_layout.has_node("GeneratedContent"),
		"Layout replacement keeps an editable FloorSurface beside the wall GridMap."
	)
	expect(
		second_floor.floor_map != first_map \
			and second_floor.styles[0] != first_style \
			and second_floor.floor_map.resource_local_to_scene \
			and second_floor.styles[0].resource_local_to_scene,
		"Each generated layout owns independent editable floor map and style resources."
	)
	host.free()
