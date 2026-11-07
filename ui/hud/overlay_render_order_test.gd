extends "res://tests/test_case.gd"

const ORDER := preload("res://ui/hud/overlay_render_order.gd")


func run(_tree: SceneTree) -> void:
	expect(
		ORDER.DrawPass.WorldTreatment < ORDER.DrawPass.BoundaryVeil,
		"The boundary veil is drawn over the treated world."
	)
	expect(
		ORDER.DrawPass.BoundaryVeil < ORDER.DrawPass.ScreenDim, "Message dimming covers both world presentation passes."
	)
	expect(ORDER.DrawPass.ScreenDim < ORDER.DrawPass.ScreenText, "Lit message text is drawn after its dimming panel.")
	expect(
		(
			ORDER.DrawPass.WorldTreatment >= Material.RENDER_PRIORITY_MIN
			and ORDER.DrawPass.ScreenText <= Material.RENDER_PRIORITY_MAX
		),
		"All overlay passes fit the renderer's supported priority range."
	)
