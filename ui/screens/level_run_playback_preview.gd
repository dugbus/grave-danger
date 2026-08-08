extends RefCounted
class_name GDLevelRunPlaybackPreview

const PLAYBACK_PLAYER_SCRIPT := preload("res://ui/screens/level_run_playback_player.gd")
const MUTED_AUDIO_BUS: StringName = &"RunPlaybackMuted"


static func ensure_muted_audio_bus() -> void:
	if AudioServer.get_bus_index(MUTED_AUDIO_BUS) < 0:
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, MUTED_AUDIO_BUS)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUTED_AUDIO_BUS), true)


static func prepare_tree(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		mute_audio_node(node)
	for child in node.get_children():
		prepare_tree(child)


static func configure_player(player_node: Node3D) -> void:
	if player_node.get_script() != PLAYBACK_PLAYER_SCRIPT:
		player_node.set_script(PLAYBACK_PLAYER_SCRIPT)
	player_node.set_process(false)
	player_node.set_physics_process(false)
	var collision_body := player_node as CollisionObject3D
	if collision_body != null:
		collision_body.collision_mask = 0


static func isolate_state(node: Node) -> void:
	if node is GDTorch:
		node.set_physics_process(false)
	if node is GDTreasureDeposit:
		node.set_physics_process(false)
	if node is GDTextTrigger:
		node.process_mode = Node.PROCESS_MODE_DISABLED
		node.set_process_input(false)
		disable_area(node as Area3D, false)
	if node is GDFlaskBase:
		node.set_physics_process(false)
		disable_area(node.get_node_or_null(^"PickupArea") as Area3D)
	if node is GDLockableHingedPassage:
		var completion_path: NodePath = node.get("completion_area_path") as NodePath
		disable_area(node.get_node_or_null(completion_path) as Area3D)
	for child in node.get_children():
		isolate_state(child)


static func start_runtime(node: Node) -> void:
	if node is GDKillBoundary3D:
		(node as GDKillBoundary3D).begin_runtime_animation()
	for child in node.get_children():
		start_runtime(child)


static func disable_area(area: Area3D, stop_monitoring: bool = true) -> void:
	if area == null:
		return
	if stop_monitoring:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
	area.collision_layer = 0
	area.collision_mask = 0


static func mute_audio_node(node: Node) -> void:
	node.set("autoplay", false)
	node.set("bus", MUTED_AUDIO_BUS)
	node.call("stop")


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null


static func find_animation(player_node: AnimationPlayer, candidates: Array[String]) -> String:
	for candidate in candidates:
		for animation_name in player_node.get_animation_list():
			if animation_name.to_lower() == candidate:
				return animation_name
	return ""
