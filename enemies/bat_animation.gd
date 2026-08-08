extends RefCounted
class_name GDBatAnimation

const COMBINED_FLAP_ANIMATION: StringName = &"combined_flap"


static func find_players(root_node: Node) -> Array[AnimationPlayer]:
	var players: Array[AnimationPlayer] = []
	if root_node is AnimationPlayer:
		players.append(root_node as AnimationPlayer)
	for child: Node in root_node.get_children():
		players.append_array(find_players(child))
	return players


static func resolve_names(animation_players: Array[AnimationPlayer]) -> Dictionary:
	var animation_names: Dictionary = {}
	for animation_player in animation_players:
		var animation_list := animation_player.get_animation_list()
		if animation_list.is_empty():
			continue
		animation_names[animation_player] = _get_flap_animation_name(
			animation_player,
			animation_list
		)
	return animation_names


static func play(
	animation_players: Array[AnimationPlayer],
	animation_names: Dictionary,
	speed_scale: float
) -> void:
	for animation_player in animation_players:
		if not animation_names.has(animation_player):
			continue
		var animation_name := animation_names[animation_player] as StringName
		animation_player.speed_scale = speed_scale
		if animation_player.current_animation != animation_name \
				or not animation_player.is_playing():
			animation_player.play(animation_name, -1.0, speed_scale)


static func _get_flap_animation_name(
	animation_player: AnimationPlayer,
	animation_list: PackedStringArray
) -> StringName:
	if animation_list.size() == 1:
		return StringName(animation_list[0])
	if animation_player.has_animation(COMBINED_FLAP_ANIMATION):
		return COMBINED_FLAP_ANIMATION

	var combined_animation := Animation.new()
	combined_animation.resource_name = String(COMBINED_FLAP_ANIMATION)
	combined_animation.loop_mode = Animation.LOOP_LINEAR
	for animation_name in animation_list:
		var source_animation := animation_player.get_animation(animation_name)
		if source_animation == null:
			continue
		combined_animation.length = maxf(combined_animation.length, source_animation.length)
		for track_index in source_animation.get_track_count():
			source_animation.copy_track(track_index, combined_animation)
	if combined_animation.get_track_count() == 0:
		return StringName(animation_list[0])
	var animation_library := _get_or_create_default_animation_library(animation_player)
	animation_library.add_animation(COMBINED_FLAP_ANIMATION, combined_animation)
	return COMBINED_FLAP_ANIMATION


static func _get_or_create_default_animation_library(
	animation_player: AnimationPlayer
) -> AnimationLibrary:
	if animation_player.has_animation_library(&""):
		return animation_player.get_animation_library(&"")
	var animation_library := AnimationLibrary.new()
	animation_player.add_animation_library(&"", animation_library)
	return animation_library
