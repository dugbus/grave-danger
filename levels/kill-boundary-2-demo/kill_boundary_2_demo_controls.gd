extends MarginContainer
class_name GDKillBoundary2DemoControls

## Demo boundary controlled by this runtime validation HUD.
@export var boundary_path: NodePath

@onready var _boundary := get_node_or_null(boundary_path) as GDKillBoundary2
@onready var _effect_option := get_node(^"Panel/VBox/EffectRow/Effect") as OptionButton
@onready var _mode_option := get_node(^"Panel/VBox/ModeRow/Mode") as OptionButton
@onready var _speed_option := get_node(^"Panel/VBox/SpeedRow/Speed") as OptionButton
@onready var _pause_button := get_node(^"Panel/VBox/TransportRow/PauseResume") as Button

var _paused := false


func _ready() -> void:
	_populate_options()
	_effect_option.item_selected.connect(_apply_effect)
	_mode_option.item_selected.connect(_apply_playback_mode)
	_speed_option.item_selected.connect(_apply_speed)
	(get_node(^"Panel/VBox/TransportRow/Restart") as Button).pressed.connect(_restart)
	_pause_button.pressed.connect(_toggle_pause)
	(get_node(^"Panel/VBox/BoundaryRow/Remove") as Button).pressed.connect(_remove_boundary)
	(get_node(^"Panel/VBox/BoundaryRow/Reload") as Button).pressed.connect(_reload_demo)


func _populate_options() -> void:
	_effect_option.clear()
	_effect_option.add_item("Flame", GDKillBoundary2Settings.RenderEffect.Flame)
	_effect_option.add_item("Ghost", GDKillBoundary2Settings.RenderEffect.Ghost)
	_effect_option.add_item("None", GDKillBoundary2Settings.RenderEffect.None)
	_mode_option.clear()
	_mode_option.add_item("Single Shot", GDKillBoundary2Animator.PlaybackMode.SingleShot)
	_mode_option.add_item("Loop", GDKillBoundary2Animator.PlaybackMode.Loop)
	_mode_option.add_item("Ping Pong", GDKillBoundary2Animator.PlaybackMode.PingPong)
	_speed_option.clear()
	for speed_percent in [50, 100, 150, 200]:
		_speed_option.add_item("%.1f×" % (float(speed_percent) / 100.0), speed_percent)
	_speed_option.select(_speed_option.get_item_index(100))


func _apply_effect(option_index: int) -> void:
	if _boundary != null:
		_boundary.set_render_effect(
			_effect_option.get_item_id(option_index) as GDKillBoundary2Settings.RenderEffect
		)


func _apply_playback_mode(option_index: int) -> void:
	if _boundary != null:
		_boundary.set_playback_mode(
			_mode_option.get_item_id(option_index) as GDKillBoundary2Animator.PlaybackMode
		)


func _apply_speed(option_index: int) -> void:
	if _boundary != null:
		_boundary.set_playback_speed(float(_speed_option.get_item_id(option_index)) / 100.0)


func _restart() -> void:
	if _boundary != null:
		_paused = false
		_boundary.restart_runtime_animation()
		_pause_button.text = "Pause"


func _toggle_pause() -> void:
	if _boundary == null:
		return
	_paused = not _paused
	_boundary.set_runtime_paused(_paused)
	_pause_button.text = "Resume" if _paused else "Pause"


func _remove_boundary() -> void:
	if _boundary != null:
		_boundary.remove_for_level()


func _reload_demo() -> void:
	get_tree().reload_current_scene()
