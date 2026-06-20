extends CanvasLayer
class_name GDPauseScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible and get_tree().paused:
		get_tree().paused = false


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
