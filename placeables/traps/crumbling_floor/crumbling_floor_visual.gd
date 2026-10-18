@tool
extends MultiMeshInstance3D

## Standalone asset preview uses one batched render node, never one child per authored block.
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")

var _geometry := GEOMETRY.shared(GEOMETRY) as GEOMETRY


func _ready() -> void:
	rebuild(Vector3(1.0, GEOMETRY.THICKNESS, 1.0), null)


func rebuild(size: Vector3, material: Material) -> Material:
	return _geometry.populate_visual(self, size, material)
