extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player.gd")
const SUBJECT_PATH := "res://player/player.gd"
const PLAYER_SCENE := preload("res://player/player.tscn")
const VISIBILITY_SCRIPT := preload(
	"res://player/visibility/player_occlusion_silhouette.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	expect(
		player.get_node_or_null("PlaythroughPositionCapture") == null,
		"Reusable player instances cannot capture frontend playback as a live playthrough."
	)
	var collision_shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var capsule := collision_shape.shape as CapsuleShape3D if collision_shape != null else null
	var headlamp := player.get_node_or_null("Pivot/PlayerHeadlampLight") as SpotLight3D
	var fill_light := player.get_node_or_null("Pivot/PlayerLight") as OmniLight3D
	var visibility := player.get_node_or_null(
		"PlayerOcclusionSilhouette"
	) as VISIBILITY_SCRIPT
	expect(
		visibility != null and visibility.player_visual_root_path == ^"../Pivot/Character",
		"Every shared player instance owns the configured obstruction silhouette component."
	)
	expect(
		capsule != null and headlamp != null and absf(headlamp.position.z) < capsule.radius,
		"The headlamp source stays inside the player hull instead of entering nearby terrain first."
	)
	expect(
		capsule != null and fill_light != null and absf(fill_light.position.z) < capsule.radius,
		"The fill-light source stays inside the player hull instead of leaking through nearby terrain."
	)
	player.free()
