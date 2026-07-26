extends Node
class_name GDVampirePresentation


var animation_player: AnimationPlayer
var idle_animation := ""
var run_animation := ""
var current_animation := ""


func configure(character: Node) -> void:
	animation_player = _find_animation_player(character)
	idle_animation = _resolve_animation(["idle", "static"])
	run_animation = _resolve_animation(["run", "walk"])
	update_animation(0.0)


func update_animation(horizontal_speed: float) -> void:
	var requested_animation := run_animation if horizontal_speed > 0.1 else idle_animation
	if animation_player == null or requested_animation.is_empty():
		return
	if current_animation == requested_animation and animation_player.is_playing():
		return

	current_animation = requested_animation
	animation_player.play(requested_animation, 0.12)


func _resolve_animation(candidates: Array[String]) -> String:
	if animation_player == null:
		return ""
	for candidate in candidates:
		if animation_player.has_animation(candidate):
			return candidate
		for animation_name in animation_player.get_animation_list():
			if String(animation_name).get_file() == candidate:
				return String(animation_name)
	return ""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result
	return null
