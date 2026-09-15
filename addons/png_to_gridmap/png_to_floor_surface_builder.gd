@tool
class_name PNGToFloorSurfaceBuilder
extends RefCounted

## Creates or rebuilds an editable FloorSurface from the non-transparent area of a PNG.
## Wall GridMap import remains independent; this service only owns floor authoring data.

const FLOOR_SURFACE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")
const DEFAULT_ELEVATION_PROFILE := preload(
	"res://addons/floor_surface/default_floor_elevation_profile.tres"
)
const DEFAULT_FLOOR_STYLE := preload("res://addons/floor_surface/default_floor_style.tres")
const GRID_ALIGNMENT := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")

const FLOOR_SURFACE_NAME := "FloorSurface"


## Creates a FloorSurface or replaces its occupancy while retaining authored height and style data.
func run(
	settings: Resource,
	image: Image,
	root: Node,
	source_grid_map: GridMap
) -> Dictionary:
	var errors := _validate(settings, image, root, source_grid_map)
	if not errors.is_empty():
		return {"errors": errors}

	var floor_surface := _find_floor_surface(settings, root)
	var created := floor_surface == null
	if created:
		floor_surface = FLOOR_SURFACE_SCENE.instantiate() as FloorSurface
		floor_surface.name = FLOOR_SURFACE_NAME
		root.add_child(floor_surface)
		floor_surface.owner = root
	_ensure_authoring_resources(floor_surface)
	settings.floor_surface_path = root.get_path_to(floor_surface)

	if source_grid_map != null:
		floor_surface.placement_grid_map_path = floor_surface.get_path_to(source_grid_map)
	if created or source_grid_map != null:
		_configure_alignment(floor_surface, settings, image, source_grid_map)
	_apply_selected_top_material(floor_surface, settings)
	var import_origin := _import_origin(image, settings, source_grid_map == null)
	var present_cells := _present_cells(image, import_origin)
	_apply_occupancy(floor_surface.floor_map, image, import_origin, present_cells)

	return {
		"created": created,
		"errors": [],
		"floor_surface": floor_surface,
		"placed": present_cells.size(),
	}


## Validates every dependency before changing the edited scene or an existing map resource.
func _validate(
	settings: Resource,
	image: Image,
	root: Node,
	source_grid_map: GridMap
) -> Array[String]:
	var errors: Array[String] = []
	if root == null:
		errors.append("Open a scene before creating a floor surface.")
	if image == null or image.is_empty():
		errors.append("Load a PNG before creating a floor surface.")
	if settings == null:
		errors.append("Floor import settings are unavailable.")
		return errors
	var material_path := String(settings.floor_material_path)
	if material_path != "":
		if not ResourceLoader.exists(material_path):
			errors.append("Floor material not found: %s" % material_path)
		elif not ResourceLoader.load(material_path) is Material:
			errors.append("Selected floor resource is not a Material: %s" % material_path)
	if source_grid_map != null:
		errors.append_array(_validate_grid_alignment(source_grid_map, root))
	if root != null and _has_ambiguous_surface_target(settings, root):
		errors.append(
			"This scene has multiple FloorSurface nodes; set the floor surface path before importing."
		)
	return errors


## Finds a configured surface, then an unambiguous conventional surface in the edited scene.
func _find_floor_surface(settings: Resource, root: Node) -> FloorSurface:
	if root == null:
		return null
	if settings != null and not settings.floor_surface_path.is_empty():
		var configured := root.get_node_or_null(settings.floor_surface_path) as FloorSurface
		if configured != null:
			return configured
	var conventional := root.get_node_or_null(NodePath(FLOOR_SURFACE_NAME)) as FloorSurface
	if conventional != null:
		return conventional
	var surfaces: Array[Node] = root.find_children("*", "FloorSurface", true, false)
	return surfaces[0] as FloorSurface if surfaces.size() == 1 else null


## Supplies any missing authoring resources without replacing valid existing level configuration.
func _ensure_authoring_resources(floor_surface: FloorSurface) -> void:
	if floor_surface.floor_map == null:
		var floor_map := FloorMap.new()
		floor_map.resource_local_to_scene = true
		floor_surface.floor_map = floor_map
	if floor_surface.elevation_profile == null:
		var elevation_profile := DEFAULT_ELEVATION_PROFILE.duplicate(true) as FloorElevationProfile
		elevation_profile.resource_local_to_scene = true
		floor_surface.elevation_profile = elevation_profile
	if floor_surface.styles.is_empty():
		var style := DEFAULT_FLOOR_STYLE.duplicate(true) as FloorStyle
		style.resource_local_to_scene = true
		var styles: Array[FloorStyle] = []
		styles.append(style)
		floor_surface.styles = styles


## Aligns cell centres with a wall GridMap, or centres a standalone imported rectangle.
func _configure_alignment(
	floor_surface: FloorSurface,
	settings: Resource,
	image: Image,
	source_grid_map: GridMap
) -> void:
	if source_grid_map != null:
		GRID_ALIGNMENT.align_surface_to_grid_map(floor_surface, source_grid_map)
		return

	var cell_size := maxf(float(settings.cell_size), 0.01)
	floor_surface.cell_size = cell_size
	if settings.export_size != Vector2i.ZERO:
		floor_surface.world_origin_xz = Vector2.ONE * -cell_size * 0.5
		return
	# Match the former generated GridMap convention: imported cell centres straddle world zero.
	floor_surface.world_origin_xz = -Vector2(image.get_width(), image.get_height()) * cell_size * 0.5


## Applies an optional top finish without replacing a surface's separately authored wall finish.
func _apply_selected_top_material(floor_surface: FloorSurface, settings: Resource) -> void:
	var material_path := String(settings.floor_material_path)
	if material_path == "":
		return
	var material := ResourceLoader.load(material_path) as Material
	if material == null:
		return
	var styles: Array[FloorStyle] = []
	styles.assign(floor_surface.styles)
	if styles.is_empty():
		var default_style := DEFAULT_FLOOR_STYLE.duplicate(true) as FloorStyle
		default_style.resource_local_to_scene = true
		styles.append(default_style)
	var first_style := styles[0].duplicate(true) as FloorStyle
	first_style.resource_local_to_scene = true
	first_style.display_name = material_path.get_file().get_basename().capitalize()
	first_style.top_material = material
	styles[0] = first_style
	floor_surface.styles = styles


## Converts opaque image pixels through the same coordinate convention as wall import.
func _present_cells(image: Image, import_origin: Vector2i) -> Array[Vector2i]:
	var import_size := Vector2i(image.get_width(), image.get_height())
	var cells: Array[Vector2i] = []
	for y in image.get_height():
		for x in image.get_width():
			if is_zero_approx(image.get_pixel(x, y).a):
				continue
			var grid_cell := PNGToGridMapImageGrid.pixel_to_cell(
				Vector2i(x, y),
				import_origin,
				import_size,
				true
			)
			cells.append(Vector2i(grid_cell.x, grid_cell.z))
	return cells


## Replaces only shape data, then automatically fits storage to the actual painted floor.
func _apply_occupancy(
	floor_map: FloorMap,
	image: Image,
	import_origin: Vector2i,
	present_cells: Array[Vector2i]
) -> void:
	var import_size := Vector2i(image.get_width(), image.get_height())
	floor_map.apply_shape_snapshot({
		"minimum_cell": import_origin,
		"dimensions": import_size,
		"default_present": false,
		"presence_exceptions": present_cells,
	})
	floor_map.compact_storage()


## Reuses wall round-trip coordinates, except for a newly centred standalone floor.
func _import_origin(image: Image, settings: Resource, standalone: bool) -> Vector2i:
	if standalone and settings.export_size == Vector2i.ZERO:
		return Vector2i.ZERO
	return PNGToGridMapImageGrid.get_import_origin(
		image.get_width(),
		image.get_height(),
		settings.export_origin,
		settings.export_size,
		true,
		true
	)


## Prevents silently creating another floor when no unique existing target can be inferred.
func _has_ambiguous_surface_target(settings: Resource, root: Node) -> bool:
	if not settings.floor_surface_path.is_empty() \
		and root.get_node_or_null(settings.floor_surface_path) is FloorSurface:
		return false
	if root.get_node_or_null(NodePath(FLOOR_SURFACE_NAME)) is FloorSurface:
		return false
	return root.find_children("*", "FloorSurface", true, false).size() > 1


## Rejects transforms the identity-root FloorSurface representation cannot reproduce safely.
func _validate_grid_alignment(source_grid_map: GridMap, root: Node) -> Array[String]:
	var errors: Array[String] = []
	var relative_transform := _transform_relative_to_root(source_grid_map, root)
	if not relative_transform.basis.is_equal_approx(Basis.IDENTITY):
		errors.append(
			"The selected GridMap is rotated or scaled; FloorSurface import requires identity alignment."
		)
	if not is_zero_approx(relative_transform.origin.y):
		errors.append(
			"The selected GridMap is vertically offset; FloorSurface import requires a zero base height."
		)
	if not is_equal_approx(source_grid_map.cell_size.x, source_grid_map.cell_size.z):
		errors.append("The selected GridMap must use equal X and Z cell sizes for square floor tiles.")
	if not source_grid_map.cell_center_x or not source_grid_map.cell_center_z:
		errors.append("The selected GridMap must centre items along X and Z.")
	return errors


## Accumulates local Node3D transforms until reaching the edited scene root.
func _transform_relative_to_root(node: Node3D, root: Node) -> Transform3D:
	var relative_transform := node.transform
	var ancestor := node.get_parent()
	while ancestor != null and ancestor != root:
		if ancestor is Node3D:
			relative_transform = (ancestor as Node3D).transform * relative_transform
		ancestor = ancestor.get_parent()
	return relative_transform
