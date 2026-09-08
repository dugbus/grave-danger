@tool
class_name FloorSurfaceEditorMaterialPreview
extends RefCounted

## Makes lit game materials readable in the editor without changing their runtime settings.


## Replaces each BaseMaterial3D surface material with an unshaded transient duplicate.
static func apply_to_mesh(mesh: ArrayMesh) -> void:
	if mesh == null:
		return
	for surface_index in mesh.get_surface_count():
		var source_material := mesh.surface_get_material(surface_index)
		if not source_material is BaseMaterial3D:
			continue
		var preview_material := source_material.duplicate(true) as BaseMaterial3D
		preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.surface_set_material(surface_index, preview_material)
