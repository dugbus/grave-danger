extends CanvasLayer
class_name GDPauseScreen

var feedback_pause_active := false
var tree_was_paused_before_feedback := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process_unhandled_input(true)
	var paused_label := get_node_or_null("PausedLabel") as Label
	GDGameFont.apply_to_label(paused_label)


func _unhandled_input(event: InputEvent) -> void:
	if not feedback_pause_active and event.is_action_pressed("pause_game"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if (visible or feedback_pause_active) and get_tree().paused:
		get_tree().paused = false


## Pauses gameplay without covering the centered feedback dialog.
func begin_feedback_pause() -> void:
	if feedback_pause_active:
		return
	tree_was_paused_before_feedback = get_tree().paused
	feedback_pause_active = true
	_set_paused(true)


## Restores the pause state that existed before the feedback dialog opened.
func end_feedback_pause() -> void:
	if not feedback_pause_active:
		return
	feedback_pause_active = false
	_set_paused(tree_was_paused_before_feedback)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused and not feedback_pause_active
