@tool
class_name FloorSurfaceEditorVisuals
extends RefCounted

## Owns transient viewport meshes so authoring logic remains independent of rendering feedback.

const ELEVATION_OVERLAY := preload(
	"res://addons/floor_surface/editor/floor_surface_elevation_overlay.gd"
)
const GRID_SHADER := preload(
	"res://addons/floor_surface/shaders/floor_surface_debug_grid.gdshader"
)
const GRID_SURFACE_OFFSET := 0.035
const GRID_WIDTH := 0.035
const GRID_COLOUR := Color(0.32, 0.5, 0.52, 0.58)
const GRID_TILE_COLOUR_A := Color(0.08, 0.12, 0.14, 0.02)
const GRID_TILE_COLOUR_B := Color(0.14, 0.18, 0.2, 0.1)
const GRID_RAMP_TILE_COLOUR := Color(0.2, 0.4, 0.46, 0.28)

var _target: Node3D
var _footprint_mesh: MeshInstance3D
var _footprint_box: BoxMesh
var _footprint_material: StandardMaterial3D
var _elevation_mesh: MeshInstance3D
var _elevation_material: StandardMaterial3D
var _grid_mesh: MeshInstance3D
var _grid_material: ShaderMaterial


## Adds unsaved preview children to the selected FloorSurface.
func attach(target: Node3D) -> void:
	detach()
	if target == null:
		return
	_target = target
	_footprint_mesh = MeshInstance3D.new()
	_footprint_mesh.name = "_FloorSurfacePaintPreview"
	_footprint_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_footprint_box = BoxMesh.new()
	_footprint_material = StandardMaterial3D.new()
	_footprint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_footprint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_footprint_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_footprint_box.material = _footprint_material
	_footprint_mesh.mesh = _footprint_box
	_footprint_mesh.visible = false
	_target.add_child(_footprint_mesh)
	_footprint_mesh.owner = null

	_elevation_mesh = MeshInstance3D.new()
	_elevation_mesh.name = "_FloorSurfaceElevationOverlay"
	_elevation_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_elevation_material = StandardMaterial3D.new()
	_elevation_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_elevation_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_elevation_material.vertex_color_use_as_albedo = true
	_elevation_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_target.add_child(_elevation_mesh)
	_elevation_mesh.owner = null

	_grid_mesh = MeshInstance3D.new()
	_grid_mesh.name = "_FloorSurfaceGridOverlay"
	_grid_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grid_mesh.visible = false
	_grid_material = ShaderMaterial.new()
	_grid_material.shader = GRID_SHADER
	_grid_material.render_priority = 2
	_grid_material.set_shader_parameter(&"grid_width", GRID_WIDTH)
	_grid_material.set_shader_parameter(&"grid_colour", GRID_COLOUR)
	_grid_material.set_shader_parameter(&"tile_colour_a", GRID_TILE_COLOUR_A)
	_grid_material.set_shader_parameter(&"tile_colour_b", GRID_TILE_COLOUR_B)
	_grid_material.set_shader_parameter(&"ramp_tile_colour", GRID_RAMP_TILE_COLOUR)
	_target.add_child(_grid_mesh)
	_grid_mesh.owner = null


## Removes every transient child without touching authored scene nodes.
func detach() -> void:
	if is_instance_valid(_footprint_mesh):
		_footprint_mesh.free()
	if is_instance_valid(_elevation_mesh):
		_elevation_mesh.free()
	if is_instance_valid(_grid_mesh):
		_grid_mesh.free()
	_target = null
	_footprint_mesh = null
	_footprint_box = null
	_footprint_material = null
	_elevation_mesh = null
	_elevation_material = null
	_grid_mesh = null
	_grid_material = null


## Updates the rectangular brush feedback above its intended world height.
func update_footprint(
	cells: Array[Vector2i],
	cell_size: float,
	world_origin_xz: Vector2,
	world_height: float,
	colour: Color,
	visible: bool
) -> void:
	if not is_instance_valid(_footprint_mesh):
		return
	_footprint_mesh.mesh = _footprint_box
	_footprint_mesh.position = Vector3.ZERO
	_footprint_mesh.visible = visible and not cells.is_empty()
	if not _footprint_mesh.visible:
		return
	var minimum := cells[0]
	var maximum := cells[0]
	for cell in cells:
		minimum.x = mini(minimum.x, cell.x)
		minimum.y = mini(minimum.y, cell.y)
		maximum.x = maxi(maximum.x, cell.x)
		maximum.y = maxi(maximum.y, cell.y)
	var width := maximum.x - minimum.x + 1
	var depth := maximum.y - minimum.y + 1
	_footprint_box.size = Vector3(float(width) * cell_size, 0.04, float(depth) * cell_size)
	_footprint_mesh.position = Vector3(
		world_origin_xz.x + (float(minimum.x) + float(width) * 0.5) * cell_size,
		world_height + 0.04,
		world_origin_xz.y + (float(minimum.y) + float(depth) * 0.5) * cell_size
	)
	_footprint_material.albedo_color = colour


## Draws a per-cell preview that follows flat or sloped authored top descriptions.
func update_surface_footprint(
	cells: Array[Vector2i],
	cell_size: float,
	world_origin_xz: Vector2,
	descriptions: Dictionary,
	colour: Color,
	visible: bool
) -> void:
	if not is_instance_valid(_footprint_mesh):
		return
	var vertices := PackedVector3Array()
	for cell in cells:
		var description := descriptions.get(cell, {}) as Dictionary
		var raw_heights := description.get("corner_heights", []) as Array
		var heights: Array[float] = []
		for raw_height in raw_heights:
			heights.append(raw_height as float)
		if heights.size() != 4:
			continue
		var minimum_x := world_origin_xz.x + float(cell.x) * cell_size
		var minimum_z := world_origin_xz.y + float(cell.y) * cell_size
		var maximum_x := minimum_x + cell_size
		var maximum_z := minimum_z + cell_size
		var corners := PackedVector3Array([
			Vector3(minimum_x, heights[0] + 0.04, minimum_z),
			Vector3(minimum_x, heights[1] + 0.04, maximum_z),
			Vector3(maximum_x, heights[2] + 0.04, maximum_z),
			Vector3(maximum_x, heights[3] + 0.04, minimum_z),
		])
		vertices.append_array(PackedVector3Array([
			corners[0], corners[2], corners[1],
			corners[0], corners[3], corners[2],
		]))
	var mesh := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, _footprint_material)
	_footprint_mesh.mesh = mesh
	_footprint_mesh.position = Vector3.ZERO
	_footprint_mesh.visible = visible and not vertices.is_empty()
	_footprint_material.albedo_color = colour


## Rebuilds and toggles the temporary false-colour elevation mesh.
func update_elevation_overlay(
	floor_map: Resource,
	profile: Resource,
	cell_size: float,
	world_origin_xz: Vector2,
	visible: bool
) -> void:
	if not is_instance_valid(_elevation_mesh):
		return
	_elevation_mesh.visible = visible
	if not visible or floor_map == null or profile == null:
		return
	var overlay_mesh := ELEVATION_OVERLAY.build_mesh(
		floor_map,
		profile,
		cell_size,
		world_origin_xz
	)
	if overlay_mesh.get_surface_count() > 0:
		overlay_mesh.surface_set_material(0, _elevation_material)
	_elevation_mesh.mesh = overlay_mesh


## Rebuilds and toggles the optional editor-only grid over the real floor materials.
func update_grid_overlay(
	floor_map: Resource,
	profile: Resource,
	cell_size: float,
	world_origin_xz: Vector2,
	visible: bool,
	highlight_ramps := false
) -> void:
	if not is_instance_valid(_grid_mesh):
		return
	_grid_mesh.visible = visible
	if not visible or floor_map == null or profile == null:
		return
	var overlay_mesh := ELEVATION_OVERLAY.build_mesh(
		floor_map,
		profile,
		cell_size,
		world_origin_xz,
		GRID_SURFACE_OFFSET,
		ELEVATION_OVERLAY.ColourMode.RampMask
	)
	_grid_material.set_shader_parameter(&"highlight_ramps", highlight_ramps)
	if overlay_mesh.get_surface_count() > 0:
		overlay_mesh.surface_set_material(0, _grid_material)
	_grid_mesh.mesh = overlay_mesh
