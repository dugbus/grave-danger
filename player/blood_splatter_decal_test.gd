extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/blood_splatter_decal.gd")
const SUBJECT_PATH := "res://player/blood_splatter_decal.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_skin_projection_and_environment_plane(tree)


# Flow: Face stains project onto skin without a floating plane; floor splats keep their visible mark.
func _test_skin_projection_and_environment_plane(tree: SceneTree) -> void:
	var splatter := (
		(load("res://player/blood_splatter_decal.tscn") as PackedScene).instantiate() as GDBloodSplatterDecal
	)
	tree.root.add_child(splatter)
	var impact_material := splatter.impact_blood.draw_pass_1.surface_get_material(0) as StandardMaterial3D
	var blocker := impact_material.next_pass as ShaderMaterial
	expect(
		(
			blocker != null
			and blocker.render_priority < 0
			and blocker.shader.resource_path == PlayerOcclusionBlocker.BLOCKER_SHADER_PATH
		),
		"Impact droplets block the gold player silhouette while retaining ordinary depth testing."
	)
	splatter.configure_surface(GDBloodSplatterDecal.SplatterTarget.Player, 0.2)
	expect(splatter.decal.cull_mask == SUBJECT.PLAYER_VISUAL_LAYER, "The face decal stains character geometry only.")
	if StringName(RenderingServer.get_current_rendering_method()) != SUBJECT.COMPATIBILITY_RENDERER:
		expect(
			not splatter.surface_mark.visible,
			"A decal-capable renderer stains the curved face without showing a rigid overlay plane."
		)
	splatter.configure_surface(GDBloodSplatterDecal.SplatterTarget.Environment, 0.72)
	expect(
		splatter.surface_mark.visible and splatter.decal.cull_mask == SUBJECT.ENVIRONMENT_VISUAL_LAYER,
		"Environment splats retain their visible surface mark and environment-only projection."
	)
	splatter.free()
