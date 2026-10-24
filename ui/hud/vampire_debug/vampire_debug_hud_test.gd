extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/vampire_debug/vampire_debug_hud.gd")
const SUBJECT_PATH := "res://ui/hud/vampire_debug/vampire_debug_hud.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var hud := SUBJECT.new() as GDVampireDebugHud
	var label := Label.new()
	hud.add_child(label)
	hud.state_label = label
	hud._refresh_text()
	expect(label.text.contains("State: Missing"), "The missing Vampire diagnostic remains visible.")
	var vampire := GDVampire.new()
	hud.vampire = vampire
	hud._refresh_text()
	expect(label.text.contains("State: Idle"), "The live AI diagnostics remain visible.")
	hud.free()
	vampire.free()
