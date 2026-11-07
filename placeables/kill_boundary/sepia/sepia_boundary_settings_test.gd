extends "res://tests/test_case.gd"

const SETTINGS := preload("res://placeables/kill_boundary/sepia/sepia_boundary_settings.tres")


func run(_tree: SceneTree) -> void:
	expect(SETTINGS.edge_feather > 0.0 and SETTINGS.edge_feather < 0.3, "The edge transition remains quick and narrow.")
	expect(
		SETTINGS.photo_strength > 0.0 and SETTINGS.photo_strength < 0.7,
		"The default print blends gently with the original artwork instead of applying the full fade."
	)
	expect(
		SETTINGS.colour_retention >= 0.85 and SETTINGS.colour_retention <= 1.0,
		"The aged print retains most of the artist's original colour."
	)
	expect(
		SETTINGS.sepia_tint.r > SETTINGS.sepia_tint.b and SETTINGS.sepia_tint.r - SETTINGS.sepia_tint.b < 0.15,
		"Paper white has a mild warm cast rather than a sepia tint that overwhelms colour."
	)
	expect(
		SETTINGS.sepia_shadow_tint.r >= 0.2 and SETTINGS.sepia_shadow_tint.r < 0.35,
		"Lifted print blacks remain visibly faded without flattening all material detail."
	)
	expect(
		absf(SETTINGS.sepia_shadow_tint.r - SETTINGS.sepia_shadow_tint.b) < 0.04,
		"The black point stays nearly neutral so shadows do not turn the artwork brown."
	)

	expect(
		SETTINGS.film_grain_strength >= 0.0 and SETTINGS.film_grain_strength <= 0.015,
		"Paper texture stays faint and static rather than dominating the image."
	)
	expect(
		SETTINGS.film_vignette_strength >= 0.0 and SETTINGS.film_vignette_strength <= 0.06,
		"The print has only gentle edge shading."
	)

	expect(SETTINGS.veil_enabled, "Sepia boundaries have a visible perimeter by default.")
	expect(SETTINGS.veil_height > 1.0, "The veil rises high enough to mark the edge beside the player.")
	expect(
		SETTINGS.veil_opacity > 0.0 and SETTINGS.veil_opacity < 0.5,
		"Wisps mark the edge softly without dominating the scene."
	)
	expect(SETTINGS.veil_morph_speed > 0.0, "The shared default morphs rather than remaining a static pattern.")
