extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/title_screen.gd")
const SUBJECT_PATH := "res://ui/screens/title_screen.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_cinematic(tree)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("_precache_first_transition"),
		"The title screen begins preparing its immediate frontend destination."
	)
	expect(
		source.contains("scene_loader.request_scene(LEVEL_SELECT_SCENE)")
			and not source.contains("request_scene_directory")
			and not source.contains("GAME_SCENE"),
		"The title transition does not compete with gameplay and dynamic-catalog precaching."
	)


func _test_cinematic(tree: SceneTree) -> void:
	var packed := load(
		"res://ui/screens/churchyard_cinematic/churchyard_cinematic.tscn"
	) as PackedScene
	var cinematic := packed.instantiate() as Node3D
	tree.root.add_child(cinematic)
	var camera := cinematic.get_node("Churchyard/Camera") as Camera3D
	var player := cinematic.get_node("Churchyard/AnimationPlayer") as AnimationPlayer
	var orbit := player.get_animation(&"Camera")
	var sun := cinematic.get_node("Churchyard/Sun") as DirectionalLight3D
	var churchyard_mesh := cinematic.get_node("Churchyard/Mesh_0") as MeshInstance3D
	var material := churchyard_mesh.get_active_material(0) as StandardMaterial3D
	expect(
		material != null and material.albedo_texture != null,
		"The churchyard keeps its imported albedo texture."
	)
	expect(
		is_equal_approx(sun.light_energy, 1.0),
		"Unitless export preserves the authored sun energy without washing out the textures."
	)
	expect(camera.current, "The cinematic uses the Blender camera.")
	expect_equal(player.autoplay, "Camera", "The authored orbit starts automatically.")
	expect_equal(orbit.loop_mode, Animation.LOOP_LINEAR, "The title orbit repeats.")
	expect(is_equal_approx(orbit.length, 250.0 / 24.0), "The orbit retains Blender's timing.")
	player.play(&"Camera")
	player.seek(1.0 / 24.0, true)
	var start := camera.transform
	expect(
		start.origin.distance_to(Vector3(2.6326876, 0.7688352, 6.876258)) < 0.001,
		"The opening pose matches Blender's evaluated path constraint in Godot coordinates."
	)
	player.seek(125.0 / 24.0, true)
	expect(
		camera.position.distance_to(Vector3(-2.4582531, 0.7688352, -6.9380307)) < 0.001,
		"The camera reaches Blender's authored midpoint."
	)
	expect(
		not camera.basis.is_equal_approx(start.basis),
		"The tracked camera aim rotates along with its position."
	)
	player.seek(orbit.length - 1.0 / 24.0, true)
	player.advance(2.0 / 24.0)
	expect(
		camera.position.distance_to(start.origin) < 0.001,
		"The imported animation wraps back to the opening frame."
	)
	var imported := cinematic.get_node("Churchyard") as Node3D
	expect_equal(
		imported.scene_file_path, "res://Assets/churchyard/churchyard.gltf",
		"The cinematic plays the exported asset directly."
	)
	cinematic.free()
