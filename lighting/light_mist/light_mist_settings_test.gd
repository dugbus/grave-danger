extends "res://tests/test_case.gd"

const SETTINGS := preload("res://lighting/light_mist/light_mist_settings.tres")


func run(_tree: SceneTree) -> void:
	expect(SETTINGS.density > 0.0 and SETTINGS.density < 0.01, "The shared baseline stays a thin, light-catching haze.")
	expect(
		SETTINGS.noise_strength > 0.0 and SETTINGS.noise_strength < 0.5,
		"Three-dimensional density variations are gentle rather than separate smoke clouds."
	)
	expect(
		SETTINGS.noise_scale > 0.0 and SETTINGS.noise_scale < 1.0,
		"Noise varies broadly through the room in world metres."
	)
	expect(
		SETTINGS.drift_velocity.length() > 0.0 and SETTINGS.drift_velocity.length() < 0.05,
		"The mist drifts slowly enough to avoid distracting movement."
	)
	expect(
		SETTINGS.temporal_blend > 0.0 and SETTINGS.temporal_blend < 0.8,
		"A moderate temporal blend limits moving-headlamp trails."
	)

	var runtime_settings := SETTINGS.duplicate() as Resource
	var edits: Array[StringName] = []
	runtime_settings.changed.connect(func() -> void: edits.append(&"changed"))
	runtime_settings.density *= 2.0
	runtime_settings.noise_strength += 0.1
	runtime_settings.fog_length += 2.0
	expect_equal(edits.size(), 3, "Runtime slider edits notify the active fog immediately.")
	runtime_settings.density = runtime_settings.density
	expect_equal(edits.size(), 3, "Reapplying an unchanged value does not trigger unnecessary work.")
