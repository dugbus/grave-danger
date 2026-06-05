extends CanvasLayer

const HudStatusBarScene := preload("res://hud_status_bar.gd")

## Node that owns flame energy and death state values for the hitpoints bar.
@export var death_controller_path: NodePath = ^"../Player/PlayerDeath"
## Node that owns carried coin counts for the coins-held bar.
@export var gold_inventory_path: NodePath = ^"../Player/PlayerGoldInventory"

@export_group("Bars")
## Width of each HUD status bar, in screen pixels.
@export_range(120.0, 900.0, 1.0, "suffix:px") var bar_width := 420.0:
	set(value):
		bar_width = maxf(value, 120.0)
		_apply_bar_layout()

## Height of each HUD status bar, in screen pixels.
@export_range(12.0, 80.0, 1.0, "suffix:px") var bar_height := 26.0:
	set(value):
		bar_height = maxf(value, 12.0)
		_apply_bar_layout()

## Vertical spacing between the hitpoints and coins-held bars.
@export_range(0.0, 80.0, 1.0, "suffix:px") var bar_gap := 10.0:
	set(value):
		bar_gap = maxf(value, 0.0)
		_apply_bar_layout()

## Distance from the top of the viewport to the first status bar.
@export_range(0.0, 160.0, 1.0, "suffix:px") var top_offset := 20.0:
	set(value):
		top_offset = maxf(value, 0.0)
		_apply_bar_layout()

var death_controller: Node
var gold_inventory: Node
var energy_bar: Control
var coins_bar: Control


func _ready() -> void:
	layer = 35

	energy_bar = HudStatusBarScene.new()
	energy_bar.name = "EnergyBar"
	energy_bar.configure_label("Hitpoints")
	add_child(energy_bar)

	coins_bar = HudStatusBarScene.new()
	coins_bar.name = "CoinsHeldBar"
	coins_bar.warning_enabled = false
	coins_bar.spark_enabled = false
	coins_bar.configure_label("Coins Held")
	coins_bar.configure_fill(
		Color(1.0, 0.76, 0.2),
		Color(1.0, 0.92, 0.34),
		Color(0.72, 1.0, 0.62)
	)
	add_child(coins_bar)

	_apply_bar_layout()
	_resolve_references()
	_connect_inventory_signal()


func set_runtime_references(death_controller_node: Node, gold_inventory_node: Node) -> void:
	death_controller = death_controller_node
	gold_inventory = gold_inventory_node
	_connect_inventory_signal()
	_update_energy_bar()
	_update_coins_bar()


func _process(_delta: float) -> void:
	if not is_instance_valid(death_controller) or not is_instance_valid(gold_inventory):
		_resolve_references()
		_connect_inventory_signal()

	_update_energy_bar()
	_update_coins_bar()


func _resolve_references() -> void:
	death_controller = get_node_or_null(death_controller_path)
	gold_inventory = get_node_or_null(gold_inventory_path)


func _connect_inventory_signal() -> void:
	if gold_inventory == null or not gold_inventory.has_signal("carried_gold_coins_changed"):
		return
	if gold_inventory.carried_gold_coins_changed.is_connected(_on_carried_gold_coins_changed):
		return

	gold_inventory.carried_gold_coins_changed.connect(_on_carried_gold_coins_changed)


func _on_carried_gold_coins_changed(_carried_count: int) -> void:
	_update_coins_bar()


func _update_energy_bar() -> void:
	var energy_ratio := 1.0
	var is_dead := false
	if death_controller != null:
		var max_energy := float(death_controller.get("max_flame_energy"))
		var current_energy := float(death_controller.get("flame_energy"))
		if max_energy > 0.0:
			energy_ratio = clampf(current_energy / max_energy, 0.0, 1.0)

		var dead_value = death_controller.get("is_dead")
		is_dead = dead_value is bool and dead_value

	energy_bar.set_ratio(energy_ratio, is_dead)


func _update_coins_bar() -> void:
	var carried_count := 0
	var max_count := 100
	if gold_inventory != null:
		if gold_inventory.has_method("get_carried_gold_coins"):
			carried_count = maxi(gold_inventory.get_carried_gold_coins(), 0)
		if gold_inventory.has_method("get_max_carried_gold_coins"):
			max_count = maxi(gold_inventory.get_max_carried_gold_coins(), 1)

	coins_bar.set_ratio(float(carried_count) / float(max_count))


func _apply_bar_layout() -> void:
	if energy_bar == null or coins_bar == null:
		return

	energy_bar.configure_size(bar_width, bar_height, top_offset)
	coins_bar.configure_size(bar_width, bar_height, top_offset + bar_height + bar_gap)

	var label_size := int(clampf(bar_height * 0.28 + 2.0, 14.0, 22.0))
	var label_width := clampf(bar_width * 0.24, 96.0, 150.0)
	energy_bar.configure_label("Hitpoints", label_size, label_width)
	coins_bar.configure_label("Coins Held", label_size, label_width)
