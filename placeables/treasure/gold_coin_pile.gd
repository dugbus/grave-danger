@tool
class_name GDGoldCoinPile
extends "res://placeables/treasure/collectible_pile.gd"


const GOLD_COIN_SCENE := preload("res://placeables/treasure/gold_coin.tscn")
const GOLD_COIN_MODEL := preload("res://Assets/environment/skull-coin.glb")
const GOLD_COIN_ITEM := preload("res://placeables/treasure/gold_coin_inventory.tres")
const TREASURE_OUTLINE_MATERIAL := preload(
    "res://placeables/treasure/treasure_outline_material.tres"
)

## Total number of coins this pile will spawn.
@export_range(0, 500, 1) var coin_count := 200:
    set(value):
        coin_count = maxi(value, 0)
        _refresh_preview_when_editing()


func get_max_coin_count() -> int:
    return coin_count


func get_max_treasure_value() -> int:
    return coin_count * maxi(GOLD_COIN_ITEM.treasure_value, 0)


func _get_item_count() -> int:
    return coin_count


func _get_collectible_scene() -> PackedScene:
    return GOLD_COIN_SCENE


func _get_seed_salt() -> StringName:
    return &"gold_coin_pile"


func _create_preview_item(index: int) -> Node3D:
    var coin_preview := GOLD_COIN_MODEL.instantiate() as Node3D
    if coin_preview == null:
        return null
    coin_preview.name = "CoinPreview%d" % index
    _apply_preview_outline(coin_preview)
    return coin_preview


func _apply_preview_outline(node: Node) -> void:
    if node is MeshInstance3D:
        (node as MeshInstance3D).material_overlay = TREASURE_OUTLINE_MATERIAL
    for child in node.get_children():
        _apply_preview_outline(child)
