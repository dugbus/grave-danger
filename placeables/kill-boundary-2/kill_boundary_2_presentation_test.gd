extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_presentation.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_presentation.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var presentation := GDKillBoundary2Presentation.new()
	var settings := GDKillBoundary2Settings.new()
	presentation.configure(settings, GDKillBoundary2Settings.RenderEffect.Flame)
	presentation.apply_geometry(
		GDKillBoundary2Geometry.build_points(Vector2(8.0, 8.0), 0.5, settings.boundary_segments)
	)
	expect(
		presentation.segments.size() == settings.boundary_segments,
		"Presentation creates one visual per canonical segment."
	)
	expect(
		presentation.segments[0].mesh != presentation.segments[1].mesh,
		"Each generated visual owns its independently resizable mesh."
	)
	var lightly_rounded := GDKillBoundary2Geometry.build_points(
		Vector2(8.0, 4.0), 0.2, settings.boundary_segments
	)
	presentation.apply_geometry(lightly_rounded)
	var flame_phase_before := float(
		presentation.segments[7].get_instance_shader_parameter(&"noise_along_offset")
	)
	var ghost_direction_before := (
		Vector2(presentation.ghosts[7].position.x, presentation.ghosts[7].position.z).normalized()
	)
	presentation.apply_geometry(
		GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.8, settings.boundary_segments)
	)
	var flame_phase_after := float(
		presentation.segments[7].get_instance_shader_parameter(&"noise_along_offset")
	)
	var ghost_direction_after := (
		Vector2(presentation.ghosts[7].position.x, presentation.ghosts[7].position.z).normalized()
	)
	expect(
		is_equal_approx(flame_phase_before, flame_phase_after),
		"Flame noise phase stays anchored while rounding changes."
	)
	expect(
		absf(ghost_direction_before.cross(ghost_direction_after)) < 0.1,
		"Each ghost stays near its stable perimeter direction while rounding changes."
	)
	presentation.apply_geometry(
		GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.00001, 32)
	)
	var nearly_sharp_flame_position := presentation.segments[7].position
	var nearly_sharp_ghost_position := presentation.ghosts[7].position
	presentation.apply_geometry(
		GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.0, 32)
	)
	expect(
		presentation.segments[7].position.distance_to(nearly_sharp_flame_position) < 0.001
		and presentation.ghosts[7].position.distance_to(nearly_sharp_ghost_position) < 0.001,
		"Flames and Ghosts do not flick when the perimeter reaches a sharp rectangle."
	)
	expect(
		is_equal_approx(
			GDKillBoundary2Presentation.resolve_ghost_emission(4.0, true),
			GDKillBoundary2Presentation.EDITOR_GHOST_MINIMUM_EMISSION
		)
		and is_equal_approx(
			GDKillBoundary2Presentation.resolve_ghost_edge_softness(0.5, true),
			GDKillBoundary2Presentation.EDITOR_GHOST_MAXIMUM_EDGE_SOFTNESS
		)
		and GDKillBoundary2Presentation.resolve_ghost_opacity(1.0, true) > 1.0,
		"Editor Ghost previews receive stronger contrast and opacity."
	)
	expect(
		is_equal_approx(GDKillBoundary2Presentation.resolve_ghost_emission(4.0, false), 4.0)
		and is_equal_approx(
			GDKillBoundary2Presentation.resolve_ghost_edge_softness(0.5, false), 0.5
		)
		and is_equal_approx(
			GDKillBoundary2Presentation.resolve_ghost_opacity(0.75, false), 0.75
		),
		"Runtime Ghost rendering preserves every authored value exactly."
	)
	presentation.free()
