extends CanvasLayer
class_name GDEnergyHud

const ActiveFlaskHudScene := preload("res://ui/hud/active_flask_hud.gd")
const HudPanelScene := preload("res://ui/hud/panel.tscn")

## Node that owns flame energy and death state values for the HUD panel.
@export var death_controller_path: NodePath = ^"../Player/PlayerDeath"
## Node that owns carried-item capacity for the HUD panel.
@export var inventory_path: NodePath = ^"../Player/PlayerInventory"
## Existing editor-placed full HUD panel. If missing, a fallback panel is created.
@export var hud_panel_path: NodePath = ^"HudPanel"
## Existing editor-placed low-health vignette. If missing, this HUD skips the screen-edge warning.
@export var low_health_vignette_path: NodePath = ^"../LowHealthVignette"

var death_controller: GDPlayerDeath
var player_inventory: GDPlayerInventory
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
	_connect_player_signals()
	_update_health_display()
	_update_sack_display()
	set_process(false)


func set_runtime_references(death_controller_node: Node, player_inventory_node: Node) -> void:
	_disconnect_runtime_signals()
	death_controller = death_controller_node as GDPlayerDeath
	player_inventory = player_inventory_node as GDPlayerInventory
	player = death_controller.get_parent() if death_controller != null else null
	_connect_inventory_signal()
	_connect_player_signals()
	_update_health_display()
	_update_sack_display()


func _resolve_references() -> void:
	death_controller = _get_node_or_null_from_path(death_controller_path) as GDPlayerDeath
	player_inventory = _get_node_or_null_from_path(inventory_path) as GDPlayerInventory
	player = death_controller.get_parent() if death_controller != null else null


func _connect_inventory_signal() -> void:
	if player_inventory == null:
		return
	if player_inventory.has_signal("item_count_changed") \
		and not player_inventory.item_count_changed.is_connected(_on_item_count_changed):
		player_inventory.item_count_changed.connect(_on_item_count_changed)
	if player_inventory.has_signal("inventory_capacity_changed") \
		and not player_inventory.inventory_capacity_changed.is_connected(
			_on_inventory_capacity_changed
		):
		player_inventory.inventory_capacity_changed.connect(_on_inventory_capacity_changed)


func _connect_player_signals() -> void:
	if death_controller != null \
		and not death_controller.flame_energy_changed.is_connected(_on_flame_energy_changed):
		death_controller.flame_energy_changed.connect(_on_flame_energy_changed)
	if player != null and player.has_signal("flask_effect_started") \
		and not player.flask_effect_started.is_connected(_on_flask_effect_started):
		player.flask_effect_started.connect(_on_flask_effect_started)


func _disconnect_runtime_signals() -> void:
	if is_instance_valid(death_controller) \
		and death_controller.flame_energy_changed.is_connected(_on_flame_energy_changed):
		death_controller.flame_energy_changed.disconnect(_on_flame_energy_changed)
	if is_instance_valid(player) and player.has_signal("flask_effect_started") \
		and player.flask_effect_started.is_connected(_on_flask_effect_started):
		player.flask_effect_started.disconnect(_on_flask_effect_started)
	if is_instance_valid(player_inventory):
		if player_inventory.item_count_changed.is_connected(_on_item_count_changed):
			player_inventory.item_count_changed.disconnect(_on_item_count_changed)
		if player_inventory.inventory_capacity_changed.is_connected(
			_on_inventory_capacity_changed
		):
			player_inventory.inventory_capacity_changed.disconnect(
				_on_inventory_capacity_changed
			)


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


func _on_item_count_changed(_item_type: StringName, _carried_count: int) -> void:
	_update_sack_display()


func _on_inventory_capacity_changed(_max_units: int) -> void:
	_update_sack_display()


func _on_flask_effect_started(effect_id: StringName, liquid_color: Color, duration: float) -> void:
	_bind_active_flask_hud()
	if active_flask_hud != null and active_flask_hud.has_method("show_flask_effect"):
		active_flask_hud.show_flask_effect(effect_id, liquid_color, duration)


func _on_flame_energy_changed(
	_current_energy: float,
	_maximum_energy: float,
	_dead: bool
) -> void:
	_update_health_display()


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
	if player_inventory != null:
		if player_inventory.has_method("get_used_inventory_units"):
			carried_count = maxi(player_inventory.get_used_inventory_units(), 0)
		if player_inventory.has_method("get_max_inventory_units"):
			max_count = maxi(player_inventory.get_max_inventory_units(), 1)

	if hud_panel != null and hud_panel.has_method("set_sack_counts"):
		hud_panel.set_sack_counts(carried_count, max_count)


func _get_node_or_null_from_path(path: NodePath) -> Node:
	if String(path).is_empty():
		return null

	return get_node_or_null(path)
