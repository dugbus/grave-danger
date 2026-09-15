class_name GDGeneratedFloorSurfaceSettings
extends RefCounted

## Applies generated-maze material and texture-repeat settings to a FloorSurface.

const FLOOR_SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const FLOOR_STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


static func apply(
	floor_surface: FLOOR_SURFACE_SCRIPT,
	configured_material: BaseMaterial3D,
	texture_tile_size: Vector2i
) -> void:
	if floor_surface == null or floor_surface.styles.is_empty():
		return
	var style := floor_surface.styles[0] as FLOOR_STYLE_SCRIPT
	if style == null:
		return
	if configured_material != null:
		style.top_material = configured_material.duplicate(true) as BaseMaterial3D
		style.wall_material = configured_material.duplicate(true) as BaseMaterial3D
	var phase_size := Vector2i(
		maxi(texture_tile_size.x, 1),
		maxi(texture_tile_size.y, 1)
	)
	if phase_size.x != phase_size.y:
		push_warning(
			"Generated FloorSurface texture tiling is square; using the X tile count."
		)
	style.world_uv_metres = float(phase_size.x)
	style.wall_uv_metres = float(phase_size.x)
