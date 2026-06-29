extends CanvasLayer
class_name GDScoreHud

## Screen position of the top-left corner of the score label.
@export var label_position := Vector2(16.0, 12.0)
## Font size used for the score label.
@export var font_size := 90
## Existing label to update. If missing, a fallback label is created.
@export var score_label_path: NodePath = ^"ScoreLabel"

var score := 0
var score_label: Label


func _ready() -> void:
	layer = 30
	add_to_group("coin_score_display")
	_bind_label()
	_update_label()


func add_score(amount: int) -> void:
	score += maxi(amount, 0)
	_update_label()


func _bind_label() -> void:
	score_label = get_node_or_null(score_label_path) as Label
	if score_label != null:
		GDGameFont.apply_to_label(score_label)
		return

	score_label = _create_fallback_label()
	add_child(score_label)


func _create_fallback_label() -> Label:
	var label := Label.new()
	label.name = "ScoreLabel"
	label.position = label_position
	GDGameFont.apply_to_label(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _update_label() -> void:
	if score_label != null:
		score_label.text = "Coins %d" % score
