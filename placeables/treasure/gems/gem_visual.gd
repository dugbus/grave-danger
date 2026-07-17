class_name GDGemVisual
extends Node3D

## Shared GLB visual with a palette material supplied by each gem variant.

## Stylized jewel finish applied to every mesh in the shared gem model.
@export var gem_material: Material


func _ready() -> void:
    _apply_gem_material(self)


func _apply_gem_material(node: Node) -> void:
    if node is MeshInstance3D:
        (node as MeshInstance3D).material_override = gem_material

    for child in node.get_children():
        _apply_gem_material(child)
