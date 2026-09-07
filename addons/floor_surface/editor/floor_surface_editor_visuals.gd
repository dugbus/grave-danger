@tool
class_name FloorSurfaceEditorVisuals
extends RefCounted

## Owns transient viewport meshes so authoring logic remains independent of rendering feedback.

const ELEVATION_OVERLAY := preload(
	"res://addons/floor_surface/editor/floor_surface_elevation_overlay.gd"
)

var _target: Node3D
var _footprint_mesh: MeshInstance3D
var _footprint_box: BoxMesh
var _footprint_material: StandardMaterial3D
var _elevation_mesh: MeshInstance3D
var _elevation_material: StandardMaterial3D


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
	_footprint_material.no_depth_test = true
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


## Removes every transient child without touching authored scene nodes.
func detach() -> void:
	if is_instance_valid(_footprint_mesh):
		_footprint_mesh.free()
	if is_instance_valid(_elevation_mesh):
		_elevation_mesh.free()
	_target = null
	_footprint_mesh = null
	_footprint_box = null
	_footprint_material = null
	_elevation_mesh = null
	_elevation_material = null


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
