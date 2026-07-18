@tool
class_name GDCollectiblePile
extends Node3D


const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const PREVIEW_CONTAINER_NAME := "EditorPreviewItems"
const EDITOR_SELECTION_PLACEHOLDER_NAME := "EditorSelectionPlaceholder"
const GAMEPLAY_PROCESS_GROUP := &"deterministic_gameplay_process"
const USEC_PER_SECOND := 1000000
const EDITOR_SELECTION_MINIMUM_HEIGHT := 0.25

## Radius of the circular spawn area around this node.
@export_range(0.05, 10.0, 0.05) var pile_radius := 0.5:
    set(value):
        pile_radius = maxf(value, 0.05)
        _refresh_preview_when_editing()

## Height above this node where spawned items initially appear.
@export_range(0.0, 10.0, 0.05) var spawn_height := 1.0

## Seconds after scene start before this pile begins spawning items.
@export_range(0.0, 300.0, 0.05) var trigger_time := 0.0

## Seconds between individual item spawns; zero queues the whole pile at once.
@export_range(0.0, 1.0, 0.005) var spawn_interval := 0.01

## Random seed for repeatable scatter; zero derives a stable seed from the scene path.
@export var random_seed := 0:
    set(value):
        random_seed = value
        _refresh_preview_when_editing()

@export_group("Editor Preview")
## Base height used to rest preview items above the pile origin.
@export_range(0.0, 2.0, 0.005) var preview_base_height := 0.018:
    set(value):
        preview_base_height = maxf(value, 0.0)
        _refresh_preview_when_editing()
## Extra height applied near the center so preview items resemble a pile.
@export_range(0.0, 2.0, 0.005) var preview_center_height := 0.18:
    set(value):
        preview_center_height = maxf(value, 0.0)
        _refresh_preview_when_editing()
## Repeating vertical separation used to keep preview items readable.
@export_range(0.0, 1.0, 0.005) var preview_item_spacing := 0.012:
    set(value):
        preview_item_spacing = maxf(value, 0.0)
        _refresh_preview_when_editing()
@export_group("")

@export_group("Runtime Culling")
## Wait until the pile is close to the camera view before creating scheduled physics items.
@export var spawn_when_near_camera := false
## Extra screen area around the camera frustum where piles may begin spawning.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var spawn_screen_margin := 420.0
## Extra world-space radius tested around the pile center for visibility checks.
@export_range(0.0, 20.0, 0.05) var spawn_visibility_radius := 2.0
## Seconds between visibility checks before this pile starts spawning.
@export_range(0.02, 2.0, 0.01) var visibility_check_interval := 0.15
@export_group("")

var spawn_elapsed_usec := 0
var trigger_elapsed_usec := 0
var scheduled_items := 0
var spawned_items := 0
var spawn_started := false
var spawn_all_queued := false
var spawn_area_active := false
var visibility_check_elapsed := 0.0
var runtime_seed := 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
    add_to_group(GAMEPLAY_PROCESS_GROUP)
    if Engine.is_editor_hint():
        _configure_editor_selection_placeholder()
        _refresh_editor_preview()
        return

    _hide_editor_selection_placeholder()
    runtime_seed = DETERMINISTIC_SEED.from_node(self, random_seed, _get_seed_salt())
    rng.seed = runtime_seed
    spawn_started = trigger_time <= 0.0


func get_max_item_count() -> int:
    return _get_item_count()


func get_runtime_random_seed() -> int:
    return runtime_seed


func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    _advance_spawn_schedule()

    if not _is_spawn_area_active(delta):
        if scheduled_items >= _get_item_count() and _get_item_count() <= 0:
            queue_free()
        return

    _spawn_scheduled_items()


func _advance_spawn_schedule() -> void:
    var item_count := _get_item_count()
    if scheduled_items >= item_count:
        return

    if not spawn_started:
        trigger_elapsed_usec += _get_physics_tick_usec()
        if trigger_elapsed_usec < _seconds_to_usec(trigger_time):
            return

        spawn_started = true

    if spawn_interval <= 0.0:
        scheduled_items = item_count
        return

    spawn_elapsed_usec += _get_physics_tick_usec()
    var spawn_interval_usec := _seconds_to_usec(spawn_interval)
    while spawn_elapsed_usec >= spawn_interval_usec and scheduled_items < item_count:
        spawn_elapsed_usec -= spawn_interval_usec
        scheduled_items += 1


func _spawn_scheduled_items() -> void:
    var item_count := _get_item_count()
    if spawned_items >= item_count:
        queue_free()
        return

    while spawned_items < scheduled_items:
        if not _spawn_collectible():
            queue_free()
            return

    if spawned_items >= item_count:
        queue_free()


func _queue_spawn_all() -> void:
    if spawn_all_queued:
        return

    spawn_all_queued = true
    call_deferred("_spawn_all_and_free")


func _spawn_all_and_free() -> void:
    while spawned_items < _get_item_count():
        if not _spawn_collectible():
            break
    queue_free()


func _spawn_collectible() -> bool:
    var collectible_scene := _get_collectible_scene()
    if collectible_scene == null:
        push_warning("Collectible pile '%s' has no item scene." % name)
        return false

    var collectible := collectible_scene.instantiate() as Node3D
    if collectible == null:
        push_warning("Collectible pile '%s' item scene does not instantiate a Node3D." % name)
        return false

    var spawn_parent := get_parent()
    if spawn_parent == null:
        spawn_parent = get_tree().current_scene
    if spawn_parent == null:
        collectible.free()
        return false

    spawn_parent.add_child(collectible)
    spawned_items += 1

    var local_offset := _random_local_spawn_offset(rng, spawn_height)
    var spawn_transform := Transform3D(
        Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
        global_transform * local_offset
    )

    if collectible.has_method("throw_from"):
        collectible.throw_from(spawn_transform, Vector3.ZERO)
    else:
        collectible.global_transform = spawn_transform

    if collectible is RigidBody3D:
        (collectible as RigidBody3D).angular_velocity = Vector3(
            rng.randf_range(-2.0, 2.0),
            rng.randf_range(-2.0, 2.0),
            rng.randf_range(-2.0, 2.0)
        )

    return true


func _is_spawn_area_active(delta: float) -> bool:
    if not spawn_when_near_camera or spawn_area_active:
        return true

    visibility_check_elapsed -= delta
    if visibility_check_elapsed > 0.0:
        return false

    visibility_check_elapsed = visibility_check_interval
    spawn_area_active = _is_near_camera_view()
    return spawn_area_active


func _is_near_camera_view() -> bool:
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return true

    var viewport_rect := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(
        spawn_screen_margin
    )
    for point in _get_visibility_probe_points():
        if camera.is_position_behind(point):
            continue

        if viewport_rect.has_point(camera.unproject_position(point)):
            return true

    return false


func _get_visibility_probe_points() -> Array[Vector3]:
    var radius := maxf(spawn_visibility_radius, pile_radius)
    return [
        global_position,
        global_position + Vector3(radius, 0.0, 0.0),
        global_position + Vector3(-radius, 0.0, 0.0),
        global_position + Vector3(0.0, 0.0, radius),
        global_position + Vector3(0.0, 0.0, -radius),
    ]


func _random_local_spawn_offset(source_rng: RandomNumberGenerator, height: float) -> Vector3:
    var angle := source_rng.randf_range(0.0, TAU)
    var radius := sqrt(source_rng.randf()) * pile_radius
    return Vector3(cos(angle) * radius, height, sin(angle) * radius)


func _refresh_preview_when_editing() -> void:
    if not Engine.is_editor_hint() or not is_inside_tree():
        return

    call_deferred("_refresh_editor_preview")


func _refresh_editor_preview() -> void:
    if not Engine.is_editor_hint() or not is_inside_tree():
        return

    _configure_editor_selection_placeholder()
    var preview_container := _get_or_create_preview_container()
    for child in preview_container.get_children():
        preview_container.remove_child(child)
        child.free()

    var preview_rng := RandomNumberGenerator.new()
    if random_seed == 0:
        preview_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, _get_seed_salt())
    else:
        preview_rng.seed = random_seed

    for index in _get_item_count():
        var item_preview := _create_preview_item(index)
        if item_preview == null:
            continue

        item_preview.name = "ItemPreview%d" % index
        item_preview.transform = Transform3D(
            Basis(Vector3.UP, preview_rng.randf_range(0.0, TAU)),
            _editor_preview_offset(preview_rng, index)
        )
        item_preview.process_mode = Node.PROCESS_MODE_DISABLED
        preview_container.add_child(item_preview)
        item_preview.owner = null
        _disable_preview_collisions(item_preview)


func _editor_preview_offset(source_rng: RandomNumberGenerator, index: int) -> Vector3:
    var offset := _random_local_spawn_offset(source_rng, 0.0)
    var center_weight := 1.0 - clampf(
        Vector2(offset.x, offset.z).length() / pile_radius,
        0.0,
        1.0
    )
    offset.y = preview_base_height \
        + (center_weight * center_weight * preview_center_height) \
        + (float(index % 5) * preview_item_spacing)
    return offset


func _get_or_create_preview_container() -> Node3D:
    var existing := get_node_or_null(PREVIEW_CONTAINER_NAME) as Node3D
    if existing != null:
        return existing

    var preview_container := Node3D.new()
    preview_container.name = PREVIEW_CONTAINER_NAME
    add_child(preview_container)
    preview_container.owner = null
    return preview_container


func _configure_editor_selection_placeholder() -> void:
    var placeholder := get_node_or_null(
        EDITOR_SELECTION_PLACEHOLDER_NAME
    ) as MeshInstance3D
    if placeholder == null:
        return

    var placeholder_mesh := placeholder.mesh as CylinderMesh
    if placeholder_mesh == null:
        return

    var placeholder_height := maxf(
        preview_base_height + preview_center_height + preview_item_spacing * 5.0,
        EDITOR_SELECTION_MINIMUM_HEIGHT
    )
    placeholder_mesh.top_radius = pile_radius
    placeholder_mesh.bottom_radius = pile_radius
    placeholder_mesh.height = placeholder_height
    placeholder.position.y = placeholder_height * 0.5
    placeholder.visible = true


func _hide_editor_selection_placeholder() -> void:
    var placeholder := get_node_or_null(
        EDITOR_SELECTION_PLACEHOLDER_NAME
    ) as MeshInstance3D
    if placeholder != null:
        placeholder.visible = false


func _disable_preview_collisions(node: Node) -> void:
    if node is CollisionObject3D:
        (node as CollisionObject3D).collision_layer = 0
        (node as CollisionObject3D).collision_mask = 0

    for child in node.get_children():
        _disable_preview_collisions(child)


func _seconds_to_usec(seconds: float) -> int:
    return maxi(roundi(maxf(seconds, 0.0) * float(USEC_PER_SECOND)), 1)


func _get_physics_tick_usec() -> int:
    var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
    return maxi(roundi(float(USEC_PER_SECOND) / float(ticks_per_second)), 1)


func _get_item_count() -> int:
    return 0


func _get_collectible_scene() -> PackedScene:
    return null


func _get_seed_salt() -> StringName:
    return &"collectible_pile"


func _create_preview_item(_index: int) -> Node3D:
    var collectible_scene := _get_collectible_scene()
    return collectible_scene.instantiate() as Node3D if collectible_scene != null else null
