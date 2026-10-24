extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/enemy_presentation.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/enemy_presentation.gd")
	_test_imported_animation_lookup()
	_test_geometry_and_lighting(tree)


# Flow: Imported animation names resolve identically for both enemies, including namespaced mixed-case names.
func _test_imported_animation_lookup() -> void:
	var root := Node3D.new()
	var nested := Node3D.new()
	var player := AnimationPlayer.new()
	root.add_child(nested)
	nested.add_child(player)
	var library := AnimationLibrary.new()
	library.add_animation("Walk", Animation.new())
	player.add_animation_library("Rig", library)
	expect_equal(SUBJECT.find_animation_player(root), player, "Both enemies find deeply nested animation players.")
	expect_equal(SUBJECT.resolve_animation_name(player, "walk"), "Rig/Walk", "Namespaced names ignore case.")
	expect_equal(SUBJECT.resolve_animation_name(player, "Rig/Walk"), "Rig/Walk", "Exact animation names stay exact.")
	expect_equal(SUBJECT.resolve_animation_name(player, "run"), "", "Absent animations remain absent.")
	expect_equal(SUBJECT.resolve_animation_name(null, "walk"), "", "Missing animation players are supported.")
	root.free()


# Flow: Shared visual setup reaches nested geometry and shadows while retaining each enemy's light settings.
func _test_geometry_and_lighting(tree: SceneTree) -> void:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var limb := MeshInstance3D.new()
	var shadow := MeshInstance3D.new()
	var light := OmniLight3D.new()
	root.add_child(body)
	body.add_child(limb)
	root.add_child(shadow)
	root.add_child(light)
	tree.root.add_child(root)
	expect_equal(
		SUBJECT.collect_fade_geometry(body, shadow), [body, limb, shadow], "Fade includes body, limbs, and shadow."
	)
	expect_equal(
		SUBJECT.collect_fade_geometry(null, shadow), [shadow], "Missing body geometry does not hide the shadow."
	)
	SUBJECT.set_geometry_transparency(body, 0.4)
	expect(
		is_equal_approx(body.transparency, 0.4) and is_equal_approx(limb.transparency, 0.4),
		"Transparency reaches every nested body mesh."
	)
	expect(is_zero_approx(shadow.transparency), "Body-only transparency leaves the separate shadow unchanged.")
	SUBJECT.set_shadow_casting(body, 1 << 18)
	expect(body.layers == 1 << 18 and limb.layers == 1 << 18, "Nested enemy geometry shares the enemy visual layer.")
	expect_equal(limb.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Nested limbs retain shadows.")
	SUBJECT.configure_light(light, Color.CORNFLOWER_BLUE, 0.7, 5.5, 1.2, false, 7, 31)
	expect(
		light.light_color == Color.CORNFLOWER_BLUE and is_equal_approx(light.light_energy, 0.7),
		"Light color and brightness stay with the calling enemy."
	)
	expect(
		is_equal_approx(light.omni_range, 5.5) and is_equal_approx(light.omni_attenuation, 1.2),
		"Light reach and attenuation retain authored values."
	)
	expect(
		not light.visible and light.shadow_enabled and light.light_cull_mask == 7 and light.shadow_caster_mask == 31,
		"Visibility and rendering masks retain the caller's settings."
	)
	root.free()
