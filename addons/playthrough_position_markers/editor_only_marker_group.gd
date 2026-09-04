@tool
extends Node3D
class_name GDEditorOnlyPlaythroughMarkerGroup


func _enter_tree() -> void:
	# The generated labels are authoring aids and must never render in a running game.
	if not Engine.is_editor_hint():
		visible = false
