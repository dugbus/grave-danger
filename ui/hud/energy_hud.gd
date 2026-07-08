extends CanvasLayer
class_name GDEnergyHud

const ActiveFlaskHudScene := preload("res://ui/hud/active_flask_hud.gd")
const HudPanelScene := preload("res://ui/hud/panel.tscn")

## Node that owns flame energy and death state values for the HUD panel.
@export var death_controller_path: NodePath = ^"../Player/PlayerDeath"
## Node that owns carried coin counts for the HUD panel.
@export var inventory_path: NodePath = ^"../Player/PlayerInventory"
## Existing editor-placed full HUD panel. If missing, a fallback panel is created.
@export var hud_panel_path: NodePath = ^"HudPanel"
## Existing editor-placed low-health vignette. If missing, this HUD skips the screen-edge warning.
@export var low_health_vignette_path: NodePath = ^"../LowHealthVignette"

var death_controller: Node
var gold_inventory: Node
var player: Node
var active_flask_hud: Control
var hud_panel: Control
var low_health_vignette: Node


func _ready() -> void:
	layer = 35

	_bind_hud_panel()
	_bind_active_flask_hud()
	_bind_low_health_vignette()

	_resolve_references()
	_connect_inventory_signal()
	_connect_player_signal()


func set_runtime_references(death_controller_node: Node, gold_inventory_node: Node) -> void:
	death_controller = death_controller_node
	gold_inventory = gold_inventory_node
	player = death_controller.get_parent() if death_controller != null else null
	_connect_inventory_signal()
	_connect_player_signal()
	_update_health_display()
	_update_sack_display()


func _process(_delta: float) -> void:
	if hud_panel == null:
		_bind_hud_panel()

	if active_flask_hud == null:
		_bind_active_flask_hud()
	if low_health_vignette == null:
		_bind_low_health_vignette()

	if not is_instance_valid(death_controller) or not is_instance_valid(gold_inventory):
		_resolve_references()
		_connect_inventory_signal()
		_connect_player_signal()

	_update_health_display()
	_update_sack_display()


func _resolve_references() -> void:
	death_controller = _get_node_or_null_from_path(death_controller_path)
	gold_inventory = _get_node_or_null_from_path(inventory_path)
	player = death_controller.get_parent() if death_controller != null else null


func _connect_inventory_signal() -> void:
	if gold_inventory == null or not gold_inventory.has_signal("carried_gold_coins_changed"):
		return
	if gold_inventory.carried_gold_coins_changed.is_connected(_on_carried_gold_coins_changed):
		return

	gold_inventory.carried_gold_coins_changed.connect(_on_carried_gold_coins_changed)


func _connect_player_signal() -> void:
	if player == null or not player.has_signal("flask_effect_started"):
		return
	if player.flask_effect_started.is_connected(_on_flask_effect_started):
		return

	player.flask_effect_started.connect(_on_flask_effect_started)


func _bind_hud_panel() -> void:
	hud_panel = get_node_or_null(hud_panel_path) as Control
	if hud_panel != null:
		return

	hud_panel = HudPanelScene.instantiate() as Control
	hud_panel.name = "HudPanel"
	add_child(hud_panel)


func _bind_active_flask_hud() -> void:
	active_flask_hud = get_node_or_null("ActiveFlaskHud") as Control
	if active_flask_hud != null:
		return

	active_flask_hud = ActiveFlaskHudScene.new()
	active_flask_hud.name = "ActiveFlaskHud"
	add_child(active_flask_hud)


func _bind_low_health_vignette() -> void:
	low_health_vignette = _get_node_or_null_from_path(low_health_vignette_path)


func _on_carried_gold_coins_changed(_carried_count: int) -> void:
	_update_sack_display()


func _on_flask_effect_started(effect_id: StringName, liquid_color: Color, duration: float) -> void:
	_bind_active_flask_hud()
	if active_flask_hud != null and active_flask_hud.has_method("show_flask_effect"):
		active_flask_hud.show_flask_effect(effect_id, liquid_color, duration)


func _update_health_display() -> void:
	var energy_ratio := 1.0
	var is_dead := false
	if death_controller != null:
		var max_energy := float(death_controller.get("max_flame_energy"))
		var current_energy := float(death_controller.get("flame_energy"))
		if max_energy > 0.0:
			energy_ratio = clampf(current_energy / max_energy, 0.0, 1.0)

		var dead_value = death_controller.get("is_dead")
		is_dead = dead_value is bool and dead_value

	if hud_panel != null and hud_panel.has_method("set_health_ratio"):
		hud_panel.set_health_ratio(0.0 if is_dead else energy_ratio)
	if low_health_vignette != null and low_health_vignette.has_method("set_health_ratio"):
		low_health_vignette.set_health_ratio(energy_ratio, is_dead)


func _update_sack_display() -> void:
	var carried_count := 0
	var max_count := 100
	if gold_inventory != null:
		if gold_inventory.has_method("get_carried_gold_coins"):
			carried_count = maxi(gold_inventory.get_carried_gold_coins(), 0)
		if gold_inventory.has_method("get_max_carried_gold_coins"):
			max_count = maxi(gold_inventory.get_max_carried_gold_coins(), 1)

	if hud_panel != null and hud_panel.has_method("set_sack_counts"):
		hud_panel.set_sack_counts(carried_count, max_count)


func _get_node_or_null_from_path(path: NodePath) -> Node:
	if String(path).is_empty():
		return null

	return get_node_or_null(path)
