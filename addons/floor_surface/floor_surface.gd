@tool
class_name FloorSurface
extends Node3D

## Owns authoritative floor data and replaces its derived geometry deterministically.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const SAMPLE_SCRIPT := preload("res://addons/floor_surface/floor_surface_sample.gd")
const BUILDER_SCRIPT := preload("res://addons/floor_surface/floor_surface_geometry_builder.gd")
const RAMP_RESOLVER_SCRIPT := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")
const EDITOR_MATERIAL_PREVIEW := preload(
	"res://addons/floor_surface/editor/floor_surface_editor_material_preview.gd"
)

signal surface_rebuilt(cell_count: int)

## Saved finite grid that remains the sole source of floor occupancy and elevation.
@export var floor_map: MAP_SCRIPT:
	set(value):
		_disconnect_change_signals()
		floor_map = value
		_connect_change_signals()
		_request_rebuild()
## Shared conversion from integer elevation units to absolute world height.
@export var elevation_profile: PROFILE_SCRIPT:
	set(value):
		_disconnect_change_signals()
		elevation_profile = value
		_connect_change_signals()
		_request_rebuild()
## Reusable appearance palette referenced by each authored cell's stable index.
@export var styles: Array[STYLE_SCRIPT] = []:
	set(value):
		_disconnect_change_signals()
		styles = value
		_connect_change_signals()
		_request_rebuild()
## Horizontal width and depth of each square grid cell.
@export_range(0.01, 100.0, 0.01, "or_greater", "suffix:m") var cell_size := 1.0:
	set(value):
		cell_size = maxf(value, 0.01)
		_request_rebuild()
## World X/Z position of the minimum corner of cell (0, 0).
@export var world_origin_xz := Vector2.ZERO:
	set(value):
		world_origin_xz = value
		_request_rebuild()
## Sparse GridMap whose equal X/Z cells receive walls and level objects on this floor.
@export_node_path("GridMap") var placement_grid_map_path: NodePath:
	set(value):
		placement_grid_map_path = value
		if is_inside_tree():
			align_with_placement_grid_map()
			update_configuration_warnings()
## Derived batched mesh replaced during every rebuild.
@export var top_mesh_path: NodePath = ^"Derived/TopMesh"
## Derived static collision replaced during every rebuild.
@export var collision_shape_path: NodePath = ^"Derived/StaticBody3D/CollisionShape3D"

@onready var top_mesh := get_node_or_null(top_mesh_path) as MeshInstance3D
@onready var collision_shape := get_node_or_null(collision_shape_path) as CollisionShape3D

var _builder := BUILDER_SCRIPT.new()
var _ramp_resolver := RAMP_RESOLVER_SCRIPT.new()
var _rebuild_count := 0
var _generated_cell_count := 0
var _rebuild_queued := false
var _last_rebuild_microseconds := 0


func _ready() -> void:
	set_notify_transform(true)
	align_with_placement_grid_map()
	_connect_change_signals()
	if Engine.is_editor_hint():
		_request_rebuild()
	else:
		rebuild()


func _exit_tree() -> void:
	_disconnect_change_signals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		update_configuration_warnings()


## Replaces derived mesh and collision without creating additional scene nodes.
func rebuild() -> int:
	if Engine.is_editor_hint():
		return _rebuild_editor_preview()
	if top_mesh == null or collision_shape == null:
		return 0
	if floor_map == null or elevation_profile == null or styles.is_empty():
		top_mesh.mesh = null
		collision_shape.shape = null
		_generated_cell_count = 0
		return 0
	var rebuild_started := Time.get_ticks_usec()
	var result := _builder.build(
		floor_map,
		elevation_profile,
		styles,
		cell_size,
		world_origin_xz
	)
	top_mesh.mesh = result["mesh"] as ArrayMesh
	collision_shape.shape = result["collision_shape"] as ConcavePolygonShape3D
	_generated_cell_count = result["cell_count"] as int
	_last_rebuild_microseconds = Time.get_ticks_usec() - rebuild_started
	_rebuild_count += 1
	surface_rebuilt.emit(_generated_cell_count)
	return _generated_cell_count


## Returns whether the authoritative map owns a top at the requested cell.
func has_floor(cell: Vector2i) -> bool:
	return floor_map != null and floor_map.has_floor(cell)


## Returns integer elevation or FloorMap.INVALID_ELEVATION for absent/outside cells.
func get_cell_elevation(cell: Vector2i) -> int:
	if floor_map == null:
		return MAP_SCRIPT.INVALID_ELEVATION
	return floor_map.get_cell_elevation(cell)


## Returns absolute world Y or NAN for absent/outside cells.
func get_world_height_at_cell(cell: Vector2i) -> float:
	if elevation_profile == null:
		return NAN
	var elevation := get_cell_elevation(cell)
	if elevation == MAP_SCRIPT.INVALID_ELEVATION:
		return NAN
	return elevation_profile.elevation_to_world(elevation)


## Classifies a directed neighbour edge from its local integer elevation difference.
func classify_edge(
	from_cell: Vector2i,
	to_cell: Vector2i
) -> PROFILE_SCRIPT.TraversalClass:
	if floor_map == null or elevation_profile == null \
			or not floor_map.has_floor(from_cell) or not floor_map.has_floor(to_cell):
		return PROFILE_SCRIPT.TraversalClass.BlockedLedge
	if _ramp_resolver.is_continuous_connection(
		floor_map,
		elevation_profile,
		from_cell,
		to_cell,
		cell_size
	):
		return PROFILE_SCRIPT.TraversalClass.Flat
	return elevation_profile.classify_edge(
		floor_map.get_cell_elevation(from_cell),
		floor_map.get_cell_elevation(to_cell)
	)


## Returns the signed integer rise from one present cell to an adjacent present cell.
func get_elevation_delta(from_cell: Vector2i, to_cell: Vector2i) -> int:
	if floor_map == null or not floor_map.has_floor(from_cell) or not floor_map.has_floor(to_cell):
		return MAP_SCRIPT.INVALID_ELEVATION
	return floor_map.get_cell_elevation(to_cell) - floor_map.get_cell_elevation(from_cell)


## Applies floor-based boundary ownership; exact grid lines belong to the positive cell.
func world_to_cell(world_position: Vector3) -> Vector2i:
	var safe_cell_size := maxf(cell_size, 0.01)
	return Vector2i(
		floori((world_position.x - world_origin_xz.x) / safe_cell_size),
		floori((world_position.z - world_origin_xz.y) / safe_cell_size)
	)


## Returns the local centre of an authored cell, including its flat or ramped centre height.
func cell_to_local(cell: Vector2i) -> Vector3:
	var local_x := world_origin_xz.x + (float(cell.x) + 0.5) * cell_size
	var local_z := world_origin_xz.y + (float(cell.y) + 0.5) * cell_size
	var sample := sample_surface(Vector3(local_x, 0.0, local_z))
	var local_y := sample.world_height if sample.valid else 0.0
	return Vector3(local_x, local_y, local_z)


## Returns the world-space centre of an authored cell for level content placement.
func cell_to_world(cell: Vector2i) -> Vector3:
	var local_position := cell_to_local(cell)
	return to_global(local_position) if is_inside_tree() else transform * local_position


## Reapplies the linked GridMap's cell size and cell-zero origin to this surface.
func align_with_placement_grid_map() -> Array[String]:
	if placement_grid_map_path.is_empty():
		return []
	var grid_map := get_placement_grid_map()
	var errors := _validate_placement_grid_map(grid_map)
	if not errors.is_empty():
		return errors
	var grid_to_surface := _transform_relative_to(grid_map, self)
	var zero_cell_centre := grid_to_surface * grid_map.map_to_local(Vector3i.ZERO)
	var aligned_origin := Vector2(zero_cell_centre.x, zero_cell_centre.z) \
		- Vector2.ONE * grid_map.cell_size.x * 0.5
	if not is_equal_approx(cell_size, grid_map.cell_size.x):
		cell_size = grid_map.cell_size.x
	if not world_origin_xz.is_equal_approx(aligned_origin):
		world_origin_xz = aligned_origin
	return []


## Returns the sparse GridMap used to place walls and objects on equal floor coordinates.
func get_placement_grid_map() -> GridMap:
	if placement_grid_map_path.is_empty():
		return null
	return get_node_or_null(placement_grid_map_path) as GridMap


## Samples the authoritative top under X/Z; holes and outside return valid=false.
func sample_surface(world_position: Vector3) -> SAMPLE_SCRIPT:
	var sampled_cell := world_to_cell(world_position)
	var sample := SAMPLE_SCRIPT.new()
	if floor_map == null or elevation_profile == null or not floor_map.has_floor(sampled_cell):
		return sample.set_invalid(sampled_cell)
	var description := get_cell_surface_description(sampled_cell)
	var local_xz := Vector2(
		(world_position.x - world_origin_xz.x) / cell_size - sampled_cell.x,
		(world_position.z - world_origin_xz.y) / cell_size - sampled_cell.y
	)
	return sample.set_surface(
		sampled_cell,
		_ramp_resolver.sample_height(description, local_xz),
		description.get("normal", Vector3.UP) as Vector3,
		floor_map.get_cell_style(sampled_cell),
		floor_map.get_cell_transition(sampled_cell)
	)


## Returns the shared top description used by mesh, collision, queries and editor tools.
func get_cell_surface_description(cell: Vector2i) -> Dictionary:
	if floor_map == null or elevation_profile == null:
		return {"valid": false, "error": "Floor surface resources are incomplete."}
	return _ramp_resolver.resolve_cell(floor_map, elevation_profile, cell, cell_size)


## Returns an actionable message for an invalid authored ramp, or an empty string.
func get_transition_error(cell: Vector2i) -> String:
	if floor_map == null or floor_map.get_cell_transition(cell) == MAP_SCRIPT.Transition.Flat:
		return ""
	var description := get_cell_surface_description(cell)
	if description.get("valid", false) as bool:
		return ""
	return description.get("error", "Invalid ramp.") as String


## Reports invalid resources, palette references and unsupported root transforms.
func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if floor_map == null:
		errors.append("FloorSurface needs a FloorMap resource.")
	else:
		if floor_map.dimensions.x <= 0 or floor_map.dimensions.y <= 0:
			errors.append("FloorMap dimensions must both be positive.")
		errors.append_array(floor_map.validate_palette_size(styles.size()))
	if elevation_profile == null:
		errors.append("FloorSurface needs a FloorElevationProfile resource.")
	else:
		errors.append_array(elevation_profile.validate())
		if floor_map != null:
			errors.append_array(_ramp_resolver.validate_map(floor_map, elevation_profile, cell_size))
	for style_index in styles.size():
		var style := styles[style_index] as STYLE_SCRIPT
		if style == null:
			errors.append("Palette entry %d is not a FloorStyle." % style_index)
		else:
			for style_error in style.validate():
				errors.append("Palette entry %d: %s" % [style_index, style_error])
	if not placement_grid_map_path.is_empty():
		var placement_grid_map := get_placement_grid_map()
		errors.append_array(_validate_placement_grid_map(placement_grid_map))
		if placement_grid_map != null and not _is_placement_grid_map_aligned(placement_grid_map):
			errors.append(
				"FloorSurface origin or cell size does not match its placement GridMap; reassign the path to align it."
			)
	var surface_transform := global_transform if is_inside_tree() else transform
	if not surface_transform.is_equal_approx(Transform3D.IDENTITY):
		errors.append(
			"FloorSurface root transform must remain identity; use world_origin_xz and integer elevation instead."
		)
	return errors


## Returns how many authored tops were included by the last successful rebuild.
func get_generated_cell_count() -> int:
	return _generated_cell_count


## Returns the number of complete derived-output replacements performed in this instance.
func get_rebuild_count() -> int:
	return _rebuild_count


## Returns the most recent complete geometry/collision rebuild duration for editor diagnostics.
func get_last_rebuild_microseconds() -> int:
	return _last_rebuild_microseconds


func _on_floor_map_changed() -> void:
	if Engine.is_editor_hint():
		_request_rebuild()
	else:
		rebuild()


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())


func _request_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	_rebuild_deferred.call_deferred()


func _rebuild_deferred() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	rebuild()
	update_configuration_warnings()


func _validate_placement_grid_map(grid_map: GridMap) -> Array[String]:
	var errors: Array[String] = []
	if grid_map == null:
		return ["FloorSurface placement GridMap path does not resolve to a GridMap."]
	var grid_to_surface := _transform_relative_to(grid_map, self)
	if not grid_to_surface.basis.is_equal_approx(Basis.IDENTITY):
		errors.append(
			"The placement GridMap is rotated or scaled relative to FloorSurface; identity alignment is required."
		)
	if not is_zero_approx(grid_to_surface.origin.y):
		errors.append(
			"The placement GridMap is vertically offset relative to FloorSurface; a shared base height is required."
		)
	if not is_equal_approx(grid_map.cell_size.x, grid_map.cell_size.z):
		errors.append("The placement GridMap must use equal X and Z sizes for square floor cells.")
	if not grid_map.cell_center_x or not grid_map.cell_center_z:
		errors.append("The placement GridMap must centre items along X and Z.")
	return errors


func _is_placement_grid_map_aligned(grid_map: GridMap) -> bool:
	if not _validate_placement_grid_map(grid_map).is_empty():
		return false
	if not is_equal_approx(cell_size, grid_map.cell_size.x):
		return false
	var grid_to_surface := _transform_relative_to(grid_map, self)
	var zero_cell_centre := grid_to_surface * grid_map.map_to_local(Vector3i.ZERO)
	var expected_origin := Vector2(zero_cell_centre.x, zero_cell_centre.z) \
		- Vector2.ONE * grid_map.cell_size.x * 0.5
	return world_origin_xz.is_equal_approx(expected_origin)


## Computes a Node3D transform in another Node3D's local coordinate space, on-tree or off-tree.
func _transform_relative_to(node: Node3D, target: Node3D) -> Transform3D:
	return _transform_to_tree_root(target).affine_inverse() * _transform_to_tree_root(node)


func _transform_to_tree_root(node: Node3D) -> Transform3D:
	var result := node.transform
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is Node3D:
			result = (ancestor as Node3D).transform * result
		ancestor = ancestor.get_parent()
	return result


func _rebuild_editor_preview() -> int:
	var preview := _get_or_create_editor_preview()
	if preview == null:
		return 0
	if floor_map == null or elevation_profile == null or styles.is_empty():
		preview.mesh = null
		_generated_cell_count = 0
		return 0
	var rebuild_started := Time.get_ticks_usec()
	var result := _builder.build(
		floor_map,
		elevation_profile,
		styles,
		cell_size,
		world_origin_xz
	)
	var preview_mesh := result["mesh"] as ArrayMesh
	EDITOR_MATERIAL_PREVIEW.apply_to_mesh(preview_mesh)
	preview.mesh = preview_mesh
	_generated_cell_count = result["cell_count"] as int
	_last_rebuild_microseconds = Time.get_ticks_usec() - rebuild_started
	_rebuild_count += 1
	surface_rebuilt.emit(_generated_cell_count)
	return _generated_cell_count


func _get_or_create_editor_preview() -> MeshInstance3D:
	var derived := get_node_or_null(^"Derived") as Node3D
	if derived == null:
		return null
	var preview := derived.get_node_or_null(^"_FloorSurfaceEditorPreview") as MeshInstance3D
	if preview != null:
		return preview
	preview = MeshInstance3D.new()
	preview.name = "_FloorSurfaceEditorPreview"
	derived.add_child(preview)
	# No owner means the derived preview remains editor-only and is never saved into the scene.
	preview.owner = null
	return preview


func _connect_change_signals() -> void:
	if not is_inside_tree():
		return
	for resource in _get_observed_resources():
		if not resource.changed.is_connected(_on_floor_map_changed):
			resource.changed.connect(_on_floor_map_changed)


func _disconnect_change_signals() -> void:
	for resource in _get_observed_resources():
		if resource.changed.is_connected(_on_floor_map_changed):
			resource.changed.disconnect(_on_floor_map_changed)


func _get_observed_resources() -> Array[Resource]:
	var resources: Array[Resource] = []
	if floor_map != null:
		resources.append(floor_map)
	if elevation_profile != null:
		resources.append(elevation_profile)
	for style in styles:
		if style != null:
			resources.append(style)
			for material in [
				style.top_material,
				style.get_wall_material(),
				style.pit_bottom_material,
			]:
				if material != null and not resources.has(material):
					resources.append(material)
	return resources
