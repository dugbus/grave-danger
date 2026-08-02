extends "res://inventory/inventory_pickup.gd"
class_name GDKey


const KEY_ITEM := preload("res://inventory/items/key.tres")
const WORLD_COLLISION_LAYER := 1
const LANDING_AUDIO_NAME := "KeyLandingAudio"
const MINIMUM_AUDIBLE_LANDING_SPEED := 1.5
const LANDING_MAX_DISTANCE := 32.0
const LANDING_UNIT_SIZE := 8.0

@export var key_material: Material

var previous_linear_velocity := Vector3.ZERO
var has_played_landing_sound := false


func _ready() -> void:
    if carried_item == null:
        carried_item = KEY_ITEM
    if key_material != null:
        _apply_material(self)
    body_entered.connect(_on_body_entered)
    super._ready()


func _physics_process(delta: float) -> void:
    previous_linear_velocity = linear_velocity
    super._physics_process(delta)


func _apply_material(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        var surface_count := 1
        if mesh_instance.mesh != null:
            surface_count = mesh_instance.mesh.get_surface_count()

        for surface_index in surface_count:
            mesh_instance.set_surface_override_material(surface_index, key_material)

    for child in node.get_children():
        _apply_material(child)


func _on_body_entered(body: Node) -> void:
    if has_played_landing_sound \
            or -previous_linear_velocity.y < MINIMUM_AUDIBLE_LANDING_SPEED \
            or not _is_world_collision_body(body):
        return

    var item := carried_item as GDCarriedItem
    if item == null or item.landing_sound == null:
        return

    has_played_landing_sound = true
    GDAudio.play_one_shot_3d(
        self,
        item.landing_sound,
        LANDING_AUDIO_NAME,
        0.0,
        1.0,
        LANDING_MAX_DISTANCE,
        LANDING_UNIT_SIZE
    )


func _is_world_collision_body(body: Node) -> bool:
    if body == null:
        return false

    var body_collision_layer: Variant = body.get("collision_layer")
    if body_collision_layer == null:
        return false

    return (int(body_collision_layer) & WORLD_COLLISION_LAYER) != 0
