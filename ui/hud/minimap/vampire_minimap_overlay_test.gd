extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/minimap/vampire_minimap_overlay.gd")
const SUBJECT_PATH := "res://ui/hud/minimap/vampire_minimap_overlay.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var overlay := SUBJECT.new() as GDVampireMinimapOverlay
	var label := Label.new()
	overlay.add_child(label)
	overlay.status_label = label
	overlay.snapshot = {"state": "ChasingPlayer", "player_visible": true}
	overlay._refresh_status_text()
	expect(label.text.contains("CHASING PLAYER") and label.text.contains("LOS YES"), "AI diagnostics remain visible.")
	expect_equal(label.text.count("\n"), 3, "The minimap retains four diagnostic lines.")
	overlay.free()
