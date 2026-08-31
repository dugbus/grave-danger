extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://placeables/kill-boundary-2/editor/kill_boundary_2_editor_overlay.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT, "res://placeables/kill-boundary-2/editor/kill_boundary_2_editor_overlay.gd"
	)
	var boundary := GDKillBoundary2.new()
	var overlay := GDKillBoundary2EditorOverlay.new()
	overlay.bind_boundary(boundary)
	expect_equal(
		overlay.get_label_count(), 1, "A selected boundary receives one label per default pose."
	)
	overlay.bind_boundary(null)
	expect_equal(
		overlay.get_label_count(), 0, "Deselecting clears transient editor labels immediately."
	)
	overlay.free()
	boundary.free()
