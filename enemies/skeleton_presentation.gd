extends RefCounted
class_name GDSkeletonPresentation

## Compatibility entry points for existing skeleton presentation consumers.

const EnemyPresentation := preload("res://enemies/enemy_presentation.gd")


static func find_animation_player(node: Node) -> AnimationPlayer:
	return EnemyPresentation.find_animation_player(node)


static func resolve_animation_name(animation_player: AnimationPlayer, animation_name: String) -> String:
	return EnemyPresentation.resolve_animation_name(animation_player, animation_name)


static func collect_geometry(node: Node) -> Array[GeometryInstance3D]:
	return EnemyPresentation.collect_geometry(node)
