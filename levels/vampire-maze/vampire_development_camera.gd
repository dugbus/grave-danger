extends GDFollowCamera
class_name GDVampireDevelopmentCamera


func _ready() -> void:
	super._ready()
	current = is_visible_in_tree()


func is_runtime_camera_enabled() -> bool:
	return is_visible_in_tree()
