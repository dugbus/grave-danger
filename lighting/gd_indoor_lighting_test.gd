extends "res://tests/test_case.gd"

const SUBJECT := preload("res://lighting/gd_indoor_lighting.gd")
const SUBJECT_PATH := "res://lighting/gd_indoor_lighting.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var caster := MultiMeshInstance3D.new()
	SUBJECT.configure_wall_shadow_proxy(caster)
	expect(
		(
			caster.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			and caster.layers == GDIndoorLighting.WALL_SHADOW_PROXY_LAYER
		),
		"Wall-leak geometry uses a dedicated shadows-only visual layer."
	)
	caster.free()
	var scene := load("res://lighting/gd_indoor_lighting.tscn") as PackedScene
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var rig := scene.instantiate() as GDIndoorLighting
	viewport.add_child(rig)
	var environment := rig.get_node(^"WorldEnvironment") as WorldEnvironment
	var original := environment.environment
	var default_enabled := rig.light_mist_enabled
	expect(not original.volumetric_fog_enabled, "Other indoor levels keep their authored lighting by default.")
	rig.light_mist_enabled = true
	expect(
		environment.environment != original and environment.environment.volumetric_fog_enabled,
		"The level's Inspector toggle enables the shared atmosphere component."
	)
	rig.light_mist_enabled = false
	expect(environment.environment == original, "Turning the level toggle off restores its authored environment.")
	viewport.free()
	await tree.process_frame
	var level := load("res://levels/1/level.tscn") as PackedScene
	var state := level.get_state()
	var enabled := default_enabled
	for index in state.get_node_count():
		if state.get_node_name(index) != &"IndoorLighting":
			continue
		for property_index in state.get_node_property_count(index):
			if state.get_node_property_name(index, property_index) == &"light_mist_enabled":
				enabled = state.get_node_property_value(index, property_index) == true
	expect(not enabled, "Level 1 leaves the costly volumetric trial disabled after the frame-rate report.")
