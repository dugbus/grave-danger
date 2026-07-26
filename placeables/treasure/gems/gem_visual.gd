@tool
class_name GDGemVisual
extends Node3D

## Shared authored cut geometry with a palette material supplied by each gem variant.

enum GemCut {
    Brilliant,
    RoughHex,
    Oval,
    Emerald,
}

## Stylized jewel finish applied to every mesh in the shared gem model.
@export var gem_material: Material:
    set(value):
        gem_material = value
        if is_node_ready():
            _apply_gem_materials(self)
## Shared outline overlay that keeps every jewel visible in dark spaces.
@export var edge_glow_material: Material:
    set(value):
        edge_glow_material = value
        if is_node_ready():
            _apply_gem_materials(self)
## Silhouette and facet construction used by this jewel variant.
@export var cut := GemCut.Brilliant:
    set(value):
        cut = value
        if is_node_ready():
            _apply_cut_visibility()


func _ready() -> void:
    _apply_cut_visibility()
    _apply_gem_materials(self)


func _apply_cut_visibility() -> void:
    var cut_nodes: Array[Node3D] = [
        get_node_or_null(^"DiamondCut") as Node3D,
        get_node_or_null(^"RubyCut") as Node3D,
        get_node_or_null(^"SapphireCut") as Node3D,
        get_node_or_null(^"EmeraldCut") as Node3D,
    ]
    for index in cut_nodes.size():
        if cut_nodes[index] != null:
            cut_nodes[index].visible = index == cut


func _apply_gem_materials(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        mesh_instance.material_override = gem_material
        mesh_instance.material_overlay = edge_glow_material

    for child in node.get_children():
        _apply_gem_materials(child)
