class_name GDGoldBar
extends "res://inventory/inventory_pickup.gd"


const GOLD_BAR_ITEM := preload("res://placeables/treasure/gold_bar_inventory.tres")
const GOLD_BAR_GROUP: StringName = &"gold_bar"
const WORLD_COLLISION_LAYER := 1
const LANDING_AUDIO_NAME := "GoldBarLandingAudio"

## World Y position below which a fallen gold bar is removed.
@export var despawn_below_y := -5.0
## Shared reflective and gently emissive finish applied to every surface in the imported model.
@export var gold_material: Material

var has_played_landing_sound := false


func _ready() -> void:
    if carried_item == null:
        carried_item = GOLD_BAR_ITEM
    if gold_material != null:
        _apply_gold_material(self)
    add_to_group(GOLD_BAR_GROUP)
    add_to_group("pickup_radius_scalable")
    set_pickup_radius_multiplier(_get_runtime_pickup_radius_multiplier())
    body_entered.connect(_on_body_entered)
    super._ready()


func _physics_process(delta: float) -> void:
    if global_position.y < despawn_below_y:
        queue_free()
        return

    super._physics_process(delta)


func _after_collection_deactivated() -> void:
    remove_from_group(GOLD_BAR_GROUP)


func _apply_gold_material(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        var surface_count := 0
        if mesh_instance.mesh != null:
            surface_count = mesh_instance.mesh.get_surface_count()

        for surface_index in surface_count:
            mesh_instance.set_surface_override_material(surface_index, gold_material)

    for child in node.get_children():
        _apply_gold_material(child)


func _on_body_entered(body: Node) -> void:
    if has_played_landing_sound or not _is_world_collision_body(body):
        return

    var item := carried_item as GDCarriedItem
    if item == null or item.landing_sound == null:
        return

    has_played_landing_sound = true
    GDAudio.play_one_shot_3d(self, item.landing_sound, LANDING_AUDIO_NAME)


func _is_world_collision_body(body: Node) -> bool:
    if body == null:
        return false

    var body_collision_layer: Variant = body.get("collision_layer")
    if body_collision_layer == null:
        return false

    return (int(body_collision_layer) & WORLD_COLLISION_LAYER) != 0
