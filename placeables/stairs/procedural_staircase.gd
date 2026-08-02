@tool
class_name GDProceduralStaircase
extends "res://placeables/placeable.gd"

## Builds one watertight staircase mesh from three construction settings.

signal geometry_rebuilt

const MIN_STEP_DEPTH := 0.1
const MIN_STEEPNESS_DEGREES := 1.0
const MAX_STEEPNESS_DEGREES := 25.0
const STAIR_WIDTH := 3.0
const APPROACH_FLOOR_LENGTH := 1.25
const APPROACH_FLOOR_THICKNESS := 0.1
const APPROACH_FLOOR_VISUAL_BIAS := 0.01
const STAIR_START_DISTANCE := APPROACH_FLOOR_LENGTH
const GATE_OVERLAP_DISTANCE := 0.45
const TOP_LANDING_LENGTH := 1.2
const FOUNDATION_Y := -0.1
const RAMP_COLLISION_THICKNESS := 0.16
const COLLISION_SEAM_OVERLAP := 0.05
const SIDE_GUARD_HEIGHT := 6.0
const SIDE_GUARD_THICKNESS := 0.2
const COMPLETION_PROGRESS := 0.58
const PLAYER_COLLISION_LAYER := 2
const WORLD_COLLISION_LAYER := 1
const KILL_BOUNDARY_GROUP: StringName = &"kill_boundary"

@export_group("Stair Construction")
## Number of treads generated in the single staircase mesh.
@export_range(1, 64, 1) var step_count := 12:
    set(value):
        step_count = clampi(value, 1, 64)
        _queue_rebuild()
## Angle of the complete staircase run; this determines each riser height.
@export_range(1.0, 35.0, 0.25, "suffix:deg") var steepness_degrees := 11.75:
    set(value):
        steepness_degrees = clampf(
            value,
            MIN_STEEPNESS_DEGREES,
            MAX_STEEPNESS_DEGREES
        )
        _queue_rebuild()
## Front-to-back depth of every generated tread.
@export_range(0.1, 3.0, 0.05, "suffix:m") var step_depth := 0.8:
    set(value):
        step_depth = maxf(value, MIN_STEP_DEPTH)
        _queue_rebuild()

@export_group("Appearance")
## Material applied to the one generated staircase mesh.
@export var stair_material: Material:
    set(value):
        stair_material = value
        _queue_rebuild()
@export_group("")

var _rebuild_queued := false
var _protected_players: Array[Node3D] = []


func _ready() -> void:
    rebuild()
    if Engine.is_editor_hint():
        super._ready()
        return

    var safety_area := get_node_or_null(^"StairwellSafetyArea") as Area3D
    if safety_area == null:
        super._ready()
        return
    safety_area.body_entered.connect(_on_safety_area_body_entered)
    safety_area.body_exited.connect(_on_safety_area_body_exited)
    _protect_initial_safety_area_bodies.call_deferred()
    super._ready()


func _exit_tree() -> void:
    if Engine.is_editor_hint():
        return
    for player in _protected_players.duplicate():
        _set_player_kill_boundary_immunity(player, false)
    _protected_players.clear()


## Regenerates the single visual mesh and every derived gameplay volume.
func rebuild() -> void:
    _rebuild_queued = false
    var stair_mesh := get_node_or_null(^"GeneratedStairMesh") as MeshInstance3D
    var stair_collision := get_node_or_null(^"StairCollision") as StaticBody3D
    var completion_area := get_node_or_null(^"CompletionArea") as Area3D
    var safety_area := get_node_or_null(^"StairwellSafetyArea") as Area3D
    if stair_mesh == null \
            or stair_collision == null \
            or completion_area == null \
            or safety_area == null:
        return

    stair_mesh.visible = not Engine.is_editor_hint()
    stair_mesh.mesh = _build_stair_mesh()
    stair_mesh.material_override = stair_material
    _configure_editor_preview()
    stair_collision.collision_layer = WORLD_COLLISION_LAYER
    stair_collision.collision_mask = PLAYER_COLLISION_LAYER
    _configure_approach_floor(stair_collision)
    _configure_walkable_collision(stair_collision)
    _configure_side_guards(stair_collision)
    _configure_completion_area(completion_area)
    _configure_stairwell_safety_area(safety_area)
    _position_top_marker()
    geometry_rebuilt.emit()


## Returns the calculated height of one riser.
func get_step_height() -> float:
    return tan(deg_to_rad(steepness_degrees)) * step_depth


## Returns the height of the final tread.
func get_top_height() -> float:
    return get_step_height() * float(step_count)


## Returns the local X coordinate at the far end of the generated mesh.
func get_end_distance() -> float:
    return _stair_end_x() + TOP_LANDING_LENGTH


func _queue_rebuild() -> void:
    if not is_inside_tree() or _rebuild_queued:
        return
    _rebuild_queued = true
    _run_queued_rebuild.call_deferred()


func _run_queued_rebuild() -> void:
    if is_inside_tree():
        rebuild()


func _build_stair_mesh() -> ArrayMesh:
    var surface_tool := SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half_width := STAIR_WIDTH * 0.5
    var negative_z := -half_width
    var positive_z := half_width
    var mesh_start := STAIR_START_DISTANCE

    var step_height := get_step_height()
    for step_index in step_count:
        var step_start := STAIR_START_DISTANCE + step_depth * float(step_index)
        var step_end := step_start + step_depth
        var previous_height := FOUNDATION_Y \
            if step_index == 0 else step_height * float(step_index)
        var tread_height := step_height * float(step_index + 1)
        _add_vertical_quad(
            surface_tool,
            step_start,
            previous_height,
            tread_height,
            negative_z,
            positive_z,
            Vector3.LEFT
        )
        _add_horizontal_quad(
            surface_tool,
            step_start,
            step_end,
            tread_height,
            negative_z,
            positive_z
        )
        _add_side_interval(
            surface_tool,
            step_start,
            step_end,
            tread_height,
            negative_z
        )
        _add_side_interval(
            surface_tool,
            step_start,
            step_end,
            tread_height,
            positive_z
        )

    var landing_start := _stair_end_x()
    var landing_end := get_end_distance()
    _add_horizontal_quad(
        surface_tool,
        landing_start,
        landing_end,
        get_top_height(),
        negative_z,
        positive_z
    )
    _add_side_interval(
        surface_tool,
        landing_start,
        landing_end,
        get_top_height(),
        negative_z
    )
    _add_side_interval(
        surface_tool,
        landing_start,
        landing_end,
        get_top_height(),
        positive_z
    )
    _add_vertical_quad(
        surface_tool,
        landing_end,
        FOUNDATION_Y,
        get_top_height(),
        negative_z,
        positive_z,
        Vector3.RIGHT
    )
    _add_bottom_quad(
        surface_tool,
        mesh_start,
        landing_end,
        negative_z,
        positive_z
    )
    return surface_tool.commit()


func _configure_editor_preview() -> void:
    var editor_preview := get_node_or_null(^"EditorPreview") as CSGPolygon3D
    if editor_preview == null:
        return
    editor_preview.polygon = _build_stair_profile()
    editor_preview.depth = STAIR_WIDTH
    editor_preview.position.z = STAIR_WIDTH * 0.5
    editor_preview.material = stair_material
    editor_preview.visible = Engine.is_editor_hint()


func _build_stair_profile() -> PackedVector2Array:
    var profile := PackedVector2Array([
        Vector2(STAIR_START_DISTANCE, FOUNDATION_Y),
        Vector2(get_end_distance(), FOUNDATION_Y),
        Vector2(get_end_distance(), get_top_height()),
        Vector2(_stair_end_x(), get_top_height()),
    ])
    var step_height := get_step_height()
    for step_index in range(step_count, 0, -1):
        var step_start := STAIR_START_DISTANCE + step_depth * float(step_index - 1)
        profile.append(Vector2(step_start, step_height * float(step_index)))
        profile.append(Vector2(step_start, step_height * float(step_index - 1)))
    return profile


func _configure_approach_floor(stair_collision: StaticBody3D) -> void:
    var approach_floor := get_node_or_null(^"ApproachFloor") as MeshInstance3D
    var approach_collision := stair_collision.get_node_or_null(
        ^"ApproachFloorShape"
    ) as CollisionShape3D
    if approach_floor == null or approach_collision == null:
        return

    var approach_mesh := BoxMesh.new()
    approach_mesh.size = Vector3(
        APPROACH_FLOOR_LENGTH,
        APPROACH_FLOOR_THICKNESS,
        STAIR_WIDTH
    )
    approach_floor.mesh = approach_mesh
    approach_floor.position = Vector3(
        APPROACH_FLOOR_LENGTH * 0.5,
        APPROACH_FLOOR_VISUAL_BIAS - APPROACH_FLOOR_THICKNESS * 0.5,
        0.0
    )
    approach_floor.material_override = stair_material

    var approach_shape := BoxShape3D.new()
    approach_shape.size = Vector3(
        APPROACH_FLOOR_LENGTH,
        APPROACH_FLOOR_THICKNESS,
        STAIR_WIDTH
    )
    approach_collision.shape = approach_shape
    approach_collision.position = Vector3(
        APPROACH_FLOOR_LENGTH * 0.5,
        -APPROACH_FLOOR_THICKNESS * 0.5,
        0.0
    )


func _add_horizontal_quad(
    surface_tool: SurfaceTool,
    start_x: float,
    end_x: float,
    height: float,
    negative_z: float,
    positive_z: float
) -> void:
    _add_quad(
        surface_tool,
        Vector3(start_x, height, negative_z),
        Vector3(start_x, height, positive_z),
        Vector3(end_x, height, positive_z),
        Vector3(end_x, height, negative_z),
        Vector3.UP
    )


func _add_vertical_quad(
    surface_tool: SurfaceTool,
    x_position: float,
    bottom_y: float,
    top_y: float,
    negative_z: float,
    positive_z: float,
    normal: Vector3
) -> void:
    if normal == Vector3.LEFT:
        _add_quad(
            surface_tool,
            Vector3(x_position, bottom_y, negative_z),
            Vector3(x_position, bottom_y, positive_z),
            Vector3(x_position, top_y, positive_z),
            Vector3(x_position, top_y, negative_z),
            normal
        )
        return
    _add_quad(
        surface_tool,
        Vector3(x_position, bottom_y, negative_z),
        Vector3(x_position, top_y, negative_z),
        Vector3(x_position, top_y, positive_z),
        Vector3(x_position, bottom_y, positive_z),
        normal
    )


func _add_side_interval(
    surface_tool: SurfaceTool,
    start_x: float,
    end_x: float,
    top_y: float,
    z_position: float
) -> void:
    if z_position < 0.0:
        _add_quad(
            surface_tool,
            Vector3(start_x, FOUNDATION_Y, z_position),
            Vector3(start_x, top_y, z_position),
            Vector3(end_x, top_y, z_position),
            Vector3(end_x, FOUNDATION_Y, z_position),
            Vector3.FORWARD
        )
        return
    _add_quad(
        surface_tool,
        Vector3(start_x, FOUNDATION_Y, z_position),
        Vector3(end_x, FOUNDATION_Y, z_position),
        Vector3(end_x, top_y, z_position),
        Vector3(start_x, top_y, z_position),
        Vector3.BACK
    )


func _add_bottom_quad(
    surface_tool: SurfaceTool,
    start_x: float,
    end_x: float,
    negative_z: float,
    positive_z: float
) -> void:
    _add_quad(
        surface_tool,
        Vector3(start_x, FOUNDATION_Y, negative_z),
        Vector3(end_x, FOUNDATION_Y, negative_z),
        Vector3(end_x, FOUNDATION_Y, positive_z),
        Vector3(start_x, FOUNDATION_Y, positive_z),
        Vector3.DOWN
    )


func _add_quad(
    surface_tool: SurfaceTool,
    first: Vector3,
    second: Vector3,
    third: Vector3,
    fourth: Vector3,
    normal: Vector3
) -> void:
    _add_triangle(surface_tool, first, second, third, normal)
    _add_triangle(surface_tool, first, third, fourth, normal)


func _add_triangle(
    surface_tool: SurfaceTool,
    first: Vector3,
    second: Vector3,
    third: Vector3,
    normal: Vector3
) -> void:
    surface_tool.set_normal(normal)
    surface_tool.add_vertex(first)
    surface_tool.set_normal(normal)
    surface_tool.add_vertex(third)
    surface_tool.set_normal(normal)
    surface_tool.add_vertex(second)


func _configure_walkable_collision(stair_collision: StaticBody3D) -> void:
    var ramp := stair_collision.get_node_or_null(^"RampShape") as CollisionShape3D
    var top_landing := stair_collision.get_node_or_null(
        ^"TopLandingShape"
    ) as CollisionShape3D
    if ramp == null or top_landing == null:
        return

    var run_length := step_depth * float(step_count)
    var rise_height := get_top_height()
    var ramp_length := Vector2(run_length, rise_height).length()
    var ramp_angle := atan2(rise_height, run_length)
    var ramp_surface_normal := Vector3(-sin(ramp_angle), cos(ramp_angle), 0.0)
    var ramp_shape := BoxShape3D.new()
    ramp_shape.size = Vector3(ramp_length, RAMP_COLLISION_THICKNESS, STAIR_WIDTH)
    ramp.shape = ramp_shape
    ramp.position = Vector3(
        STAIR_START_DISTANCE + run_length * 0.5,
        rise_height * 0.5,
        0.0
    ) - ramp_surface_normal * RAMP_COLLISION_THICKNESS * 0.5
    ramp.rotation = Vector3(0.0, 0.0, ramp_angle)

    var landing_shape := BoxShape3D.new()
    landing_shape.size = Vector3(
        TOP_LANDING_LENGTH + COLLISION_SEAM_OVERLAP,
        RAMP_COLLISION_THICKNESS,
        STAIR_WIDTH
    )
    top_landing.shape = landing_shape
    top_landing.position = Vector3(
        _stair_end_x() + (TOP_LANDING_LENGTH - COLLISION_SEAM_OVERLAP) * 0.5,
        get_top_height() - RAMP_COLLISION_THICKNESS * 0.5,
        0.0
    )


func _configure_side_guards(stair_collision: StaticBody3D) -> void:
    var left_guard := stair_collision.get_node_or_null(
        ^"LeftSideGuardShape"
    ) as CollisionShape3D
    var right_guard := stair_collision.get_node_or_null(
        ^"RightSideGuardShape"
    ) as CollisionShape3D
    if left_guard == null or right_guard == null:
        return

    var guard_start := -GATE_OVERLAP_DISTANCE
    var guard_end := get_end_distance()
    var guard_size := Vector3(
        guard_end - guard_start,
        SIDE_GUARD_HEIGHT,
        SIDE_GUARD_THICKNESS
    )
    var guard_x := (guard_start + guard_end) * 0.5
    var guard_z := STAIR_WIDTH * 0.5 + SIDE_GUARD_THICKNESS * 0.5
    for guard in [left_guard, right_guard]:
        var guard_shape := BoxShape3D.new()
        guard_shape.size = guard_size
        guard.shape = guard_shape
        guard.position = Vector3(
            guard_x,
            FOUNDATION_Y + SIDE_GUARD_HEIGHT * 0.5,
            -guard_z if guard == left_guard else guard_z
        )


func _configure_completion_area(completion_area: Area3D) -> void:
    var completion_shape := completion_area.get_node_or_null(
        ^"CollisionShape3D"
    ) as CollisionShape3D
    if completion_shape == null:
        return

    completion_area.collision_layer = 0
    completion_area.collision_mask = PLAYER_COLLISION_LAYER
    var completion_step := clampi(
        ceili(float(step_count) * COMPLETION_PROGRESS),
        1,
        step_count
    )
    var ramp_height := get_step_height() * (float(completion_step) - 0.5)
    completion_area.position = Vector3(
        STAIR_START_DISTANCE + step_depth * (float(completion_step) - 0.5),
        ramp_height + 1.0,
        0.0
    )
    var area_shape := BoxShape3D.new()
    area_shape.size = Vector3(step_depth, 2.0, STAIR_WIDTH - 0.2)
    completion_shape.shape = area_shape


func _configure_stairwell_safety_area(safety_area: Area3D) -> void:
    var safety_shape := safety_area.get_node_or_null(
        ^"CollisionShape3D"
    ) as CollisionShape3D
    if safety_shape == null:
        return

    safety_area.collision_layer = 0
    safety_area.collision_mask = PLAYER_COLLISION_LAYER
    safety_area.monitoring = true
    safety_area.monitorable = true
    var area_start := -GATE_OVERLAP_DISTANCE
    var area_end := get_end_distance()
    var area_top := get_top_height() + 2.0
    var area_box := BoxShape3D.new()
    area_box.size = Vector3(
        area_end - area_start,
        area_top - FOUNDATION_Y,
        STAIR_WIDTH
    )
    safety_shape.shape = area_box
    safety_area.position = Vector3(
        (area_start + area_end) * 0.5,
        (FOUNDATION_Y + area_top) * 0.5,
        0.0
    )


func _protect_initial_safety_area_bodies() -> void:
    var safety_area := get_node_or_null(^"StairwellSafetyArea") as Area3D
    if safety_area == null:
        return
    for body in safety_area.get_overlapping_bodies():
        _on_safety_area_body_entered(body)


func _on_safety_area_body_entered(body: Node3D) -> void:
    if not _has_active_kill_boundary() \
            or not body.has_method("set_kill_boundary_immunity"):
        return
    if not _protected_players.has(body):
        _protected_players.append(body)
    _set_player_kill_boundary_immunity(body, true)


func _on_safety_area_body_exited(body: Node3D) -> void:
    if not _protected_players.has(body):
        return
    _protected_players.erase(body)
    _set_player_kill_boundary_immunity(body, false)


func _set_player_kill_boundary_immunity(player: Node3D, enabled: bool) -> void:
    if is_instance_valid(player) and player.has_method("set_kill_boundary_immunity"):
        player.call("set_kill_boundary_immunity", self, enabled)


func _has_active_kill_boundary() -> bool:
    if not is_inside_tree():
        return false
    for boundary in get_tree().get_nodes_in_group(KILL_BOUNDARY_GROUP):
        if not is_instance_valid(boundary):
            continue
        var boundary_3d := boundary as Node3D
        if boundary_3d == null or boundary_3d.is_visible_in_tree():
            return true
    return false


func _position_top_marker() -> void:
    var top_marker := get_node_or_null(^"TopMarker") as Marker3D
    if top_marker != null:
        top_marker.position = Vector3(get_end_distance(), get_top_height(), 0.0)


func _stair_end_x() -> float:
    return STAIR_START_DISTANCE + step_depth * float(step_count)
