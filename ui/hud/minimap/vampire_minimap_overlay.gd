extends Control
class_name GDVampireMinimapOverlay


const MARKER_MARGIN := 10.0
const VAMPIRE_MARKER_LENGTH := 11.0
const VAMPIRE_MARKER_WIDTH := 7.0
const BELIEF_MARKER_RADIUS := 7.0
const PLAYER_MARKER_RADIUS := 6.0
const TARGET_MARKER_RADIUS := 6.0
const MINIMUM_UNCERTAINTY_RADIUS_PIXELS := 3.0

## Label that displays the Vampire's live perception, search, and route diagnostics.
@export var status_label_path: NodePath = ^"StatusBackdrop/StatusLabel"
## Purple map marker used for the Vampire and its current facing direction.
@export var vampire_color := Color(0.78, 0.32, 1.0, 1.0)
## Pink map marker used for the position where the Vampire believes the player is.
@export var belief_color := Color(1.0, 0.24, 0.62, 1.0)
## Cyan map marker used for the player's actual position during diagnostics.
@export var player_color := Color(0.16, 0.92, 1.0, 1.0)
## Gold map marker used for the Vampire's active navigation destination.
@export var target_color := Color(1.0, 0.72, 0.12, 1.0)

@onready var status_label := get_node_or_null(status_label_path) as Label

var vampire: Node3D
var minimap_camera: Camera3D
var viewport_container: SubViewportContainer
var snapshot: Dictionary = {}
var content_rect := Rect2()
var marker_font: Font


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    marker_font = GDGameFont.get_almendra_font()
    if status_label != null:
        GDGameFont.apply_to_label(status_label)
    clear_runtime_references()


func _process(_delta: float) -> void:
    _refresh_snapshot()


## Connects the overlay to a Vampire and the minimap view used to project its evidence.
func set_runtime_references(
    vampire_node: Node3D,
    camera: Camera3D,
    container: SubViewportContainer
) -> void:
    vampire = vampire_node if _supports_vampire_snapshot(vampire_node) else null
    minimap_camera = camera
    viewport_container = container
    visible = vampire != null and minimap_camera != null and viewport_container != null
    set_process(visible)
    if visible:
        _refresh_snapshot()
    else:
        snapshot.clear()
        queue_redraw()


## Removes all live references and hides Vampire-only diagnostics on ordinary minimaps.
func clear_runtime_references() -> void:
    vampire = null
    minimap_camera = null
    viewport_container = null
    snapshot.clear()
    visible = false
    set_process(false)
    if status_label != null:
        status_label.text = ""
    queue_redraw()


## Returns the latest displayed snapshot for tests and development tooling.
func get_snapshot() -> Dictionary:
    return snapshot.duplicate(true)


func _refresh_snapshot() -> void:
    if not is_instance_valid(vampire) \
            or not is_instance_valid(minimap_camera) \
            or not is_instance_valid(viewport_container):
        clear_runtime_references()
        return

    snapshot = vampire.call("get_minimap_debug_snapshot") as Dictionary
    content_rect = Rect2(viewport_container.position, viewport_container.size)
    _refresh_status_text()
    queue_redraw()


func _refresh_status_text() -> void:
    if status_label == null:
        return

    var state_name := _humanize_name(String(snapshot.get("state", "Unknown")))
    var line_of_sight := "YES" if bool(snapshot.get("player_visible", false)) else "NO"
    var awareness_name := _humanize_name(
        String(snapshot.get("awareness_source", "None"))
    )
    var belief_name := _humanize_name(String(snapshot.get("belief_kind", "Unknown")))
    var search_plan := _humanize_name(String(snapshot.get("search_plan", "None")))
    var route_index := int(snapshot.get("route_index", 0))
    var route_points := int(snapshot.get("route_points", 0))
    var uncertainty_radius := float(snapshot.get("uncertainty_radius", 0.0))
    var belief_error := float(snapshot.get("belief_error", 0.0))
    var belief_error_text := "%.1fm" % belief_error \
        if bool(snapshot.get("has_belief", false)) else "--"
    var evidence_age := float(snapshot.get("evidence_age", 0.0))
    var evidence_confidence := float(snapshot.get("evidence_confidence", -1.0))
    var evidence_confidence_text := "%.0f%%" % (evidence_confidence * 100.0) \
        if evidence_confidence >= 0.0 else "--"
    var speed := float(snapshot.get("speed", 0.0))
    var destination_distance := float(snapshot.get("destination_distance", 0.0))
    var destination_text := "%.1fm" % destination_distance \
        if bool(snapshot.get("has_navigation_target", false)) else "NONE"
    var route_status := _humanize_name(
        String(snapshot.get("route_status", "Unavailable"))
    )

    status_label.text = (
        "%s  •  LOS %s  •  %s\n"
        + "BELIEF %s  •  ±%.1fm  •  ERROR %s\n"
        + "SEARCH %s  •  ROUTE %d/%d  •  SPEED %.1fm/s\n"
        + "EVIDENCE %.1fs  •  CONF %s  •  DEST %s  •  %s"
    ) % [
        state_name,
        line_of_sight,
        awareness_name,
        belief_name,
        uncertainty_radius,
        belief_error_text,
        search_plan,
        route_index,
        route_points,
        speed,
        evidence_age,
        evidence_confidence_text,
        destination_text,
        route_status,
    ]


func _draw() -> void:
    if snapshot.is_empty() or content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
        return

    var vampire_position := snapshot.get("vampire_position", Vector3.ZERO) as Vector3
    var vampire_screen_position := _project_world_position(vampire_position)
    var facing_direction := snapshot.get("facing_direction", Vector3.FORWARD) as Vector3

    if bool(snapshot.get("has_belief", false)):
        var belief_position := snapshot.get("belief_position", Vector3.ZERO) as Vector3
        var raw_belief_screen_position := _project_world_position(belief_position)
        var belief_screen_position := _clamp_marker_to_content(raw_belief_screen_position)
        draw_dashed_line(
            vampire_screen_position,
            belief_screen_position,
            belief_color * Color(1.0, 1.0, 1.0, 0.7),
            1.5,
            5.0
        )
        if content_rect.has_point(raw_belief_screen_position):
            _draw_uncertainty(
                belief_screen_position,
                float(snapshot.get("uncertainty_radius", 0.0))
            )
        _draw_belief_marker(belief_screen_position)

    if bool(snapshot.get("has_actual_player", false)):
        var player_position := snapshot.get("actual_player_position", Vector3.ZERO) as Vector3
        _draw_player_marker(
            _clamp_marker_to_content(_project_world_position(player_position))
        )

    if bool(snapshot.get("has_navigation_target", false)):
        var target_position := snapshot.get("navigation_target", Vector3.ZERO) as Vector3
        _draw_target_marker(
            _clamp_marker_to_content(_project_world_position(target_position))
        )

    _draw_vampire_marker(vampire_screen_position, vampire_position, facing_direction)


func _draw_vampire_marker(
    screen_position: Vector2,
    world_position: Vector3,
    facing_direction: Vector3
) -> void:
    var horizontal_facing := Vector3(facing_direction.x, 0.0, facing_direction.z)
    if horizontal_facing.is_zero_approx():
        horizontal_facing = Vector3.FORWARD
    var facing_screen_position := _project_world_position(
        world_position + horizontal_facing.normalized()
    )
    var screen_direction := (facing_screen_position - screen_position).normalized()
    if screen_direction.is_zero_approx():
        screen_direction = Vector2.UP
    var screen_right := Vector2(-screen_direction.y, screen_direction.x)
    var points := PackedVector2Array([
        screen_position + screen_direction * VAMPIRE_MARKER_LENGTH,
        screen_position - screen_direction * VAMPIRE_MARKER_LENGTH * 0.65 \
            + screen_right * VAMPIRE_MARKER_WIDTH,
        screen_position - screen_direction * VAMPIRE_MARKER_LENGTH * 0.65 \
            - screen_right * VAMPIRE_MARKER_WIDTH,
    ])
    draw_colored_polygon(points, vampire_color)
    var outline := points.duplicate()
    outline.append(points[0])
    draw_polyline(outline, Color.WHITE, 1.5, true)


func _draw_belief_marker(screen_position: Vector2) -> void:
    var diamond := PackedVector2Array([
        screen_position + Vector2.UP * BELIEF_MARKER_RADIUS,
        screen_position + Vector2.RIGHT * BELIEF_MARKER_RADIUS,
        screen_position + Vector2.DOWN * BELIEF_MARKER_RADIUS,
        screen_position + Vector2.LEFT * BELIEF_MARKER_RADIUS,
        screen_position + Vector2.UP * BELIEF_MARKER_RADIUS,
    ])
    draw_polyline(diamond, belief_color, 3.0, true)
    _draw_marker_letter("?", screen_position, belief_color)


func _draw_player_marker(screen_position: Vector2) -> void:
    draw_circle(screen_position, PLAYER_MARKER_RADIUS, player_color, false, 2.5, true)
    _draw_marker_letter("P", screen_position, player_color)


func _draw_target_marker(screen_position: Vector2) -> void:
    draw_line(
        screen_position - Vector2.RIGHT * TARGET_MARKER_RADIUS,
        screen_position + Vector2.RIGHT * TARGET_MARKER_RADIUS,
        target_color,
        2.5,
        true
    )
    draw_line(
        screen_position - Vector2.UP * TARGET_MARKER_RADIUS,
        screen_position + Vector2.UP * TARGET_MARKER_RADIUS,
        target_color,
        2.5,
        true
    )


func _draw_uncertainty(screen_position: Vector2, world_radius: float) -> void:
    if minimap_camera == null or world_radius <= 0.0:
        return
    var radius_pixels := world_radius \
        * content_rect.size.y \
        / maxf(minimap_camera.size, 0.001)
    radius_pixels = maxf(radius_pixels, MINIMUM_UNCERTAINTY_RADIUS_PIXELS)
    draw_arc(
        screen_position,
        radius_pixels,
        0.0,
        TAU,
        48,
        belief_color * Color(1.0, 1.0, 1.0, 0.45),
        1.5,
        true
    )


func _draw_marker_letter(letter: String, screen_position: Vector2, color: Color) -> void:
    if marker_font == null:
        return
    var font_size := 12
    var text_size := marker_font.get_string_size(
        letter,
        HORIZONTAL_ALIGNMENT_CENTER,
        -1.0,
        font_size
    )
    var baseline := screen_position + Vector2(
        -text_size.x * 0.5,
        marker_font.get_ascent(font_size) * 0.5
    )
    draw_string(
        marker_font,
        baseline,
        letter,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        font_size,
        color
    )


func _project_world_position(world_position: Vector3) -> Vector2:
    if minimap_camera == null or viewport_container == null:
        return Vector2.ZERO
    var viewport_position := minimap_camera.unproject_position(world_position)
    var viewport_size := Vector2(minimap_camera.get_viewport().size)
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return content_rect.get_center()
    return content_rect.position + viewport_position * content_rect.size / viewport_size


func _clamp_marker_to_content(screen_position: Vector2) -> Vector2:
    var minimum := content_rect.position + Vector2.ONE * MARKER_MARGIN
    var maximum := content_rect.end - Vector2.ONE * MARKER_MARGIN
    return Vector2(
        clampf(screen_position.x, minimum.x, maximum.x),
        clampf(screen_position.y, minimum.y, maximum.y)
    )


func _supports_vampire_snapshot(candidate: Node) -> bool:
    return candidate != null and candidate.has_method("get_minimap_debug_snapshot")


func _humanize_name(value: String) -> String:
    var humanized := ""
    for character_index in value.length():
        var character := value.substr(character_index, 1)
        if character_index > 0:
            var previous_character := value.substr(character_index - 1, 1)
            var starts_word := character == character.to_upper() \
                and character != character.to_lower() \
                and previous_character == previous_character.to_lower() \
                and previous_character != previous_character.to_upper()
            if starts_word:
                humanized += " "
        humanized += character.to_upper()
    return humanized
