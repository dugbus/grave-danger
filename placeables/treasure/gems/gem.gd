class_name GDGem
extends "res://inventory/inventory_pickup.gd"

## Shared physical pickup behaviour for every cut gemstone variant.

const GEM_GROUP: StringName = &"gem"
const PICKUP_RADIUS_SCALABLE_GROUP: StringName = &"pickup_radius_scalable"

## World Y position below which a fallen gem is removed.
@export var despawn_below_y := -5.0

var item_group: StringName


func _ready() -> void:
    add_to_group(GEM_GROUP)
    add_to_group(PICKUP_RADIUS_SCALABLE_GROUP)
    if carried_item != null:
        item_group = carried_item.get("item_type") as StringName
        if item_group != &"":
            add_to_group(item_group)
    set_pickup_radius_multiplier(_get_runtime_pickup_radius_multiplier())
    super._ready()


func _physics_process(delta: float) -> void:
    if global_position.y < despawn_below_y:
        queue_free()
        return

    super._physics_process(delta)


func _after_collection_deactivated() -> void:
    remove_from_group(GEM_GROUP)
    if item_group != &"":
        remove_from_group(item_group)
