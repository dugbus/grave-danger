extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/kill-boundary-2-demo/kill_boundary_2_demo_controls.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT, "res://levels/kill-boundary-2-demo/kill_boundary_2_demo_controls.gd"
	)
	var source := (SUBJECT as Script).get_source_code()
	expect(source.contains("RenderEffect.Ghost"), "The demo controls expose Ghost presentation.")
	expect(source.contains("PlaybackMode.PingPong"), "The demo controls expose Ping Pong playback.")
	expect(
		source.contains("[50, 100, 150, 200]"),
		"The demo controls expose all requested speed presets."
	)
	expect(
		source.contains("remove_for_level"), "The demo controls exercise runtime boundary removal."
	)
