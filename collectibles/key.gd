extends "res://inventory/inventory_pickup.gd"


const KEY_ITEM := preload("res://inventory/items/key.tres")

@export var key_material: Material


func _ready() -> void:
	if carried_item == null:
		carried_item = KEY_ITEM
	if key_material != null:
		_apply_material(self)
	super._ready()


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
