extends CanvasLayer

@export var label_position := Vector2(16.0, 12.0)
@export var font_size := 90

var score := 0
var score_label: Label


func _ready() -> void:
	layer = 30
	add_to_group("coin_score_display")
	_create_label()
	_update_label()


func add_score(amount: int) -> void:
	score += maxi(amount, 0)
	_update_label()


func _create_label() -> void:
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = label_position
	score_label.add_theme_font_size_override("font_size", font_size)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
	score_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(score_label)


func _update_label() -> void:
	if score_label != null:
		score_label.text = "Coins %d" % score
