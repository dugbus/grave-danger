extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_content_config.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_content_config.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var configuration := SUBJECT.new() as Resource
	configuration.set("grass_coverage_percent", 31.0)
	configuration.set("grass_patch_size_tiles", 6.0)
	expect(
		bool(configuration.get("grass_enabled")) \
			and is_equal_approx(
				float(configuration.get("grass_coverage_percent")),
				31.0
			) \
			and is_equal_approx(
				float(configuration.get("grass_patch_size_tiles")),
				6.0
			) \
			and int(configuration.get("grass_blades_per_cell")) == 32 \
			and int(configuration.get("grass_route_clearance_tiles")) == 0,
		"Generated content exposes reactive grass-patch controls."
	)
