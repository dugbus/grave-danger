@tool
class_name GDGoldCoinPile
extends "res://placeables/treasure/collectible_pile.gd"


const GOLD_COIN_SCENE := preload("res://placeables/treasure/gold_coin.tscn")
const GOLD_COIN_ITEM := preload("res://placeables/treasure/gold_coin_inventory.tres")
const GOLD_TREASURE_MATERIAL := preload("res://placeables/treasure/gold_treasure_material.tres")

## Total number of coins this pile will spawn.
@export_range(0, 500, 1) var coin_count := 200:
    set(value):
        coin_count = maxi(value, 0)
        _refresh_preview_when_editing()

var preview_mesh: CylinderMesh


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
    var coin_preview := MeshInstance3D.new()
    coin_preview.name = "CoinPreview%d" % index
    coin_preview.mesh = _get_preview_mesh()
    return coin_preview


func _get_preview_mesh() -> CylinderMesh:
    if preview_mesh != null:
        return preview_mesh

    preview_mesh = CylinderMesh.new()
    preview_mesh.material = GOLD_TREASURE_MATERIAL
    preview_mesh.top_radius = 0.08
    preview_mesh.bottom_radius = 0.08
    preview_mesh.height = 0.035
    preview_mesh.radial_segments = 32
    return preview_mesh
