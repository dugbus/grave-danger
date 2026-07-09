@tool
extends Control
class_name GDHudPanel

## Full-width HUD panel that displays treasure, sack capacity, and segmented health.

enum HealthSegmentState {
	Remaining,
	Lost,
	Locked,
}

const ACTIVE_HEALTH_SEGMENTS := 6
const TOTAL_HEALTH_SEGMENTS := 12
const DEFAULT_LEVEL_COIN_TOTAL := 0

@export_group("Placement Help")
## Inspector note: edit ScreenContainer/PanelPlacement to move or resize the panel inside the reference canvas.
## HudPanel scales ScreenContainer uniformly to the actual viewport, so child aspect ratios are preserved.
@export_multiline var placement_help := (
	"Edit ScreenContainer/PanelPlacement to position and scale the HUD panel inside the 1920x1080 "
	+ "reference canvas. HudPanel scales ScreenContainer uniformly to fit the real viewport, so child "
	+ "aspect ratios stay unchanged. ScreenGuide shows the reference canvas in the editor. PlacementGuide "
	+ "shows the panel placement rectangle and is hidden at runtime."
)
@export_group("")

## Reference canvas size used to position HUD elements before uniform screen scaling.
@export var reference_screen_size := Vector2(1920.0, 1080.0):
	set(value):
		reference_screen_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_sync_screen_container()
## Canvas that contains HUD elements in reference-screen coordinates.
@export var screen_container_path: NodePath = ^"ScreenContainer"
## Label that displays deposited treasure against the level total.
@export var treasure_lifted_label_path: NodePath = ^"ScreenContainer/PanelPlacement/PanelArt/TreasureLifted"
## Label that displays the total treasure available on the level.
@export var treasure_total_label_path: NodePath = ^"ScreenContainer/PanelPlacement/PanelArt/TreasureOnLevel"
## Label that displays carried treasure in the current sack.
@export var sack_contents_label_path: NodePath = ^"ScreenContainer/PanelPlacement/PanelArt/SackContents"
## Label that displays the current sack capacity.
@export var sack_max_label_path: NodePath = ^"ScreenContainer/PanelPlacement/PanelArt/SackMax"
## Container that owns the health segment TextureRects.
@export var health_segments_path: NodePath = ^"ScreenContainer/PanelPlacement/PanelArt/HealthSegments"
## Texture used for remaining health segments.
@export var remaining_health_texture: Texture2D
## Texture used for lost health segments.
@export var lost_health_texture: Texture2D
## Texture used for locked upgrade-space segments.
@export var locked_health_texture: Texture2D

var treasure_collected := 0
var treasure_available := DEFAULT_LEVEL_COIN_TOTAL
var sack_used := 0
var sack_available := 1
var health_available := ACTIVE_HEALTH_SEGMENTS
var health_remaining := ACTIVE_HEALTH_SEGMENTS

@onready var screen_container := get_node_or_null(screen_container_path) as Control
@onready var placement_guide := get_node_or_null(^"ScreenContainer/PanelPlacement/PlacementGuide") as Control
@onready var screen_guide := get_node_or_null(^"ScreenContainer/ScreenGuide") as Control
@onready var treasure_lifted_label: Label = get_node(treasure_lifted_label_path) as Label
@onready var treasure_total_label: Label = get_node(treasure_total_label_path) as Label
@onready var sack_contents_label: Label = get_node(sack_contents_label_path) as Label
@onready var sack_max_label: Label = get_node(sack_max_label_path) as Label
@onready var health_segments: HBoxContainer = get_node(health_segments_path) as HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_screen_container()
	if placement_guide != null and not Engine.is_editor_hint():
		placement_guide.visible = false
	if screen_guide != null and not Engine.is_editor_hint():
		screen_guide.visible = false
	add_to_group("coin_score_display")
	_update_labels()
	_update_health_segments()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_screen_container()


func add_score(amount: int) -> void:
	treasure_collected += maxi(amount, 0)
	_update_labels()


func set_treasure_total(total: int) -> void:
	treasure_available = maxi(total, 0)
	_update_labels()


func set_sack_counts(used_count: int, available_count: int) -> void:
	sack_used = maxi(used_count, 0)
	sack_available = maxi(available_count, 1)
	_update_labels()


func set_health_ratio(ratio: float) -> void:
	health_remaining = ceili(clampf(ratio, 0.0, 1.0) * float(health_available))
	_update_health_segments()


func set_health_counts(remaining_count: int, available_count: int = ACTIVE_HEALTH_SEGMENTS) -> void:
	health_available = clampi(available_count, 0, TOTAL_HEALTH_SEGMENTS)
	health_remaining = clampi(remaining_count, 0, health_available)
	_update_health_segments()


func _update_labels() -> void:
	if treasure_lifted_label != null:
		treasure_lifted_label.text = "%d" % treasure_collected
	if treasure_total_label != null:
		treasure_total_label.text = "of %d" % treasure_available
	if sack_contents_label != null:
		sack_contents_label.text = "%d" % sack_used
	if sack_max_label != null:
		sack_max_label.text = "of %d" % sack_available


func _sync_screen_container() -> void:
	if screen_container == null:
		screen_container = get_node_or_null(screen_container_path) as Control
	if screen_container == null:
		return

	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var scale_factor := minf(
		viewport_size.x / reference_screen_size.x,
		viewport_size.y / reference_screen_size.y
	)
	var scaled_size := reference_screen_size * scale_factor
	screen_container.position = (viewport_size - scaled_size) * 0.5
	screen_container.size = reference_screen_size
	screen_container.scale = Vector2.ONE * scale_factor


func _update_health_segments() -> void:
	if health_segments == null:
		return

	var segment_index := 0
	for child in health_segments.get_children():
		var segment := child as TextureRect
		if segment == null:
			continue

		var segment_state := _get_health_segment_state(segment_index)
		segment.texture = _get_health_segment_texture(segment_state)
		segment_index += 1


func _get_health_segment_state(segment_index: int) -> HealthSegmentState:
	if segment_index >= health_available:
		return HealthSegmentState.Locked
	if segment_index < health_remaining:
		return HealthSegmentState.Remaining
	return HealthSegmentState.Lost


func _get_health_segment_texture(segment_state: HealthSegmentState) -> Texture2D:
	match segment_state:
		HealthSegmentState.Remaining:
			return remaining_health_texture
		HealthSegmentState.Lost:
			return lost_health_texture
		HealthSegmentState.Locked:
			return locked_health_texture

	return locked_health_texture
