extends "res://tests/test_case.gd"

const SUBJECT := preload("res://lighting/gd_indoor_lighting.gd")
const SUBJECT_PATH := "res://lighting/gd_indoor_lighting.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var caster := MultiMeshInstance3D.new()
	SUBJECT.configure_wall_shadow_proxy(caster)
	expect(
		caster.cast_shadow \
				== GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
			and caster.layers == GDIndoorLighting.WALL_SHADOW_PROXY_LAYER,
		"Wall-leak geometry uses a dedicated shadows-only visual layer."
	)
	caster.free()
