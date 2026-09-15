extends "res://tests/test_case.gd"

## Every selectable level owns one editor-exposed, level-specific FloorSurface data set.

const LEVEL_DIMENSIONS := {
	"res://levels/tutorial-1/level.tscn": Vector2i(16, 16),
	"res://levels/tutorial-2/level.tscn": Vector2i(25, 25),
	"res://levels/tutorial-3/level.tscn": Vector2i(31, 31),
	"res://levels/tutorial-4/level.tscn": Vector2i(31, 31),
	"res://levels/tutorial-5/level.tscn": Vector2i(31, 31),
	"res://levels/debug-level/level.tscn": Vector2i(256, 16),
	"res://levels/1/level.tscn": Vector2i(24, 24),
	"res://levels/2/level.tscn": Vector2i(32, 32),
	"res://levels/3/level.tscn": Vector2i(150, 24),
	"res://levels/4/level.tscn": Vector2i(124, 186),
	"res://levels/graveyard/level.tscn": Vector2i(100, 100),
	"res://levels/5/level.tscn": Vector2i(38, 33),
	"res://levels/6/level.tscn": Vector2i(52, 52),
	"res://levels/7/level.tscn": Vector2i(22, 112),
	"res://levels/8/level.tscn": Vector2i(52, 52),
	"res://levels/vampire-maze/level.tscn": Vector2i(34, 34),
	"res://levels/kill-boundary-2-demo/level.tscn": Vector2i(32, 32),
	"res://levels/close-escape/level.tscn": Vector2i(35, 29),
}
const GENERATED_FLOOR_DIMENSIONS := {
	"res://levels/vampire-maze/generated_maze/generated_floor_surface_map.tres": Vector2i.ONE,
}

const NESTED_EDITABLE_PATHS := {
	"res://levels/tutorial-1/level.tscn": "Layout",
	"res://levels/tutorial-2/level.tscn": "Layout",
	"res://levels/tutorial-3/level.tscn": "Layout",
	"res://levels/tutorial-4/level.tscn": "Layout",
	"res://levels/tutorial-5/level.tscn": "GeneratedMaze/Layout",
	"res://levels/vampire-maze/level.tscn": "GeneratedMaze/Layout",
}
const STATIC_PLACEMENT_PAIRS := {
	"res://levels/tutorial-1/level.tscn": [
		NodePath("Layout/FloorSurface"), NodePath("Layout/PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/tutorial-2/level.tscn": [
		NodePath("Layout/FloorSurface"), NodePath("Layout/PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/tutorial-3/level.tscn": [
		NodePath("Layout/FloorSurface"), NodePath("Layout/PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/tutorial-4/level.tscn": [
		NodePath("Layout/FloorSurface"), NodePath("Layout/PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/debug-level/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/1/level.tscn": [
		NodePath("FloorSurface"), NodePath("GridMap"), Vector2i(-2, -2),
	],
	"res://levels/2/level.tscn": [
		NodePath("FloorSurface"), NodePath("GridMap"), Vector2i(-16, -16),
	],
	"res://levels/3/level.tscn": [
		NodePath("FloorSurface"), NodePath("GridMap"), Vector2i(-75, -12),
	],
	"res://levels/4/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i(-2, -3),
	],
	"res://levels/5/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i(0, -1),
	],
	"res://levels/6/level.tscn": [
		NodePath("FloorSurface"), NodePath("GridMap"), Vector2i(-26, -26),
	],
	"res://levels/7/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i.ZERO,
	],
	"res://levels/8/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i(-10, -10),
	],
	"res://levels/graveyard/level.tscn": [
		NodePath("FloorSurface"), NodePath("PNGGridMap"), Vector2i(-25, -25),
	],
	"res://levels/vampire-maze/level.tscn": [
		NodePath("GeneratedMaze/Layout/FloorSurface"),
		NodePath("GeneratedMaze/Layout/PNGGridMap"),
		Vector2i.ZERO,
	],
	"res://levels/kill-boundary-2-demo/level.tscn": [
		NodePath("FloorSurface"), NodePath("PlacementGridMap"), Vector2i.ZERO,
	],
	"res://levels/close-escape/level.tscn": [
		NodePath("FloorSurface"), NodePath("AuthoredLayout/WallGridMap"), Vector2i.ZERO,
	],
}
const BALANCED_PLACEMENT_LEVELS: Array[String] = [
	"res://levels/1/level.tscn",
	"res://levels/2/level.tscn",
	"res://levels/3/level.tscn",
	"res://levels/4/level.tscn",
	"res://levels/6/level.tscn",
	"res://levels/8/level.tscn",
	"res://levels/graveyard/level.tscn",
]
const PIT_LEVEL_REGION_COUNTS := {
	"res://levels/debug-level/floor_surface_map.tres": 6,
	"res://levels/7/floor_surface_map.tres": 2,
}
const PIT_LEVEL_CELL_COUNTS := {
	"res://levels/debug-level/floor_surface_map.tres": 14,
	"res://levels/7/floor_surface_map.tres": 2,
}
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]
const MINIMUM_READABLE_PIT_DEPTH := 2.0
const GridAlignment := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")
const GeometryBuilder := preload(
	"res://addons/floor_surface/floor_surface_geometry_builder.gd"
)
const PitResolver := preload("res://addons/floor_surface/floor_surface_pit_resolver.gd")
const ShapePainter := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)
const ElevationProfile := preload(
	"res://addons/floor_surface/default_floor_elevation_profile.tres"
)


func run(_tree: SceneTree) -> void:
	for path_value: Variant in LEVEL_DIMENSIONS:
		_check_level(String(path_value), LEVEL_DIMENSIONS[path_value] as Vector2i)
	for path_value: Variant in STATIC_PLACEMENT_PAIRS:
		_check_static_placement_alignment(
			String(path_value),
			STATIC_PLACEMENT_PAIRS[path_value] as Array
		)
	for path_value: Variant in GENERATED_FLOOR_DIMENSIONS:
		var map_path := String(path_value)
		_check_map(map_path, GENERATED_FLOOR_DIMENSIONS[path_value] as Vector2i)
		_check_style(_style_path_for_map(map_path))
		_check_readable_pit_walls(map_path)


func _check_level(scene_path: String, expected_dimensions: Vector2i) -> void:
	var level_source := FileAccess.get_file_as_string(scene_path)
	var level_folder := scene_path.get_base_dir()
	var map_path := level_folder.path_join("floor_surface_map.tres")
	var style_path := level_folder.path_join("floor_surface_style.tres")
	expect(not level_source.is_empty(), "%s remains a readable text scene." % scene_path)
	expect_equal(
		level_source.count('[node name="FloorSurface"'),
		1,
		"%s declares exactly one editable FloorSurface override." % scene_path
	)
	expect(
		level_source.contains('path="%s"' % map_path) \
			and level_source.contains('path="%s"' % style_path),
		"%s references its own editable floor map and style." % scene_path
	)
	expect(
		not level_source.contains("PNGFloorGridMap") \
			and not level_source.contains("FloorGridMap"),
		"%s contains no legacy floor GridMap node." % scene_path
	)
	if NESTED_EDITABLE_PATHS.has(scene_path):
		var editable_path := String(NESTED_EDITABLE_PATHS[scene_path])
		expect(
			level_source.contains('[editable path="%s"]' % editable_path),
			"%s exposes its nested FloorSurface to the level editor." % scene_path
		)
	else:
		expect(
			level_source.contains('[node name="FloorSurface" parent="."'),
			"%s owns its FloorSurface directly at the level root." % scene_path
		)
	_check_map(map_path, expected_dimensions)
	_check_style(style_path)
	_check_readable_pit_walls(map_path)


func _check_map(map_path: String, expected_dimensions: Vector2i) -> void:
	var source := FileAccess.get_file_as_string(map_path)
	var floor_map := load(map_path) as FloorMap
	expect(
		floor_map.dimensions == expected_dimensions \
			and not floor_map.get_present_cells().is_empty(),
		"%s preserves the complete original floor footprint." % map_path
	)
	expect(
		not source.contains("elevation_overrides") \
			and not source.contains("transition_overrides"),
		"%s preserves the original flat elevation." % map_path
	)
	var repainted_map := FloorMap.new()
	var painter := ShapePainter.new()
	expect(
		painter.begin(repainted_map, ShapePainter.PaintMode.Paint),
		"%s can begin a normal FloorSurface paint gesture." % map_path
	)
	painter.apply_cells(floor_map.get_present_cells())
	var gesture := painter.finish()
	expect(not gesture.is_empty(), "%s completes a FloorSurface paint gesture." % map_path)
	expect_equal(
		repainted_map.get_shape_snapshot(),
		floor_map.get_shape_snapshot(),
		"%s stores the canonical result produced by the FloorSurface painter." % map_path
	)


func _check_style(style_path: String) -> void:
	var source := FileAccess.get_file_as_string(style_path)
	var style := load(style_path) as FloorStyle
	expect(
		source.contains("top_material = ") and source.contains("wall_material = "),
		"%s keeps editable top and exposed-side materials." % style_path
	)
	expect(style.top_material != null, "%s retains its authored floor-top material." % style_path)
	expect(
		style.get_wall_material() != null and style.get_wall_material() != style.top_material,
		"%s uses an independent FloorSurface wall material." % style_path
	)
	expect(
		style.pit_bottom_material != null,
		"%s uses an explicit FloorSurface pit-bottom material." % style_path
	)
	expect(
		style.pit_depth >= MINIMUM_READABLE_PIT_DEPTH,
		"%s uses player-scale FloorSurface wall depth." % style_path
	)


func _check_static_placement_alignment(scene_path: String, pair: Array) -> void:
	var packed := load(scene_path) as PackedScene
	var level := packed.instantiate()
	var floor_surface := level.get_node(pair[0] as NodePath) as FloorSurface
	var placement_grid_map := level.get_node(pair[1] as NodePath) as GridMap
	var expected_minimum := pair[2] as Vector2i
	var expanded_cell := expected_minimum - Vector2i.ONE
	expect(
		floor_surface.placement_grid_map_path == floor_surface.get_path_to(placement_grid_map) \
			and GridAlignment.is_aligned(floor_surface, placement_grid_map) \
			and floor_surface.floor_map.minimum_cell == expected_minimum,
		"%s keeps its floor and object-placement coordinates aligned." % scene_path
	)
	expect_equal(
		GridAlignment.floor_cell_to_grid_cell(
			floor_surface,
			placement_grid_map,
			expanded_cell
		),
		expanded_cell,
		"%s can place GridMap objects beyond its current floor edge." % scene_path
	)
	if BALANCED_PLACEMENT_LEVELS.has(scene_path):
		var used_bounds := _horizontal_used_bounds(placement_grid_map)
		var lower_padding := used_bounds.position - floor_surface.floor_map.minimum_cell
		var upper_padding := floor_surface.floor_map.minimum_cell \
			+ floor_surface.floor_map.dimensions - used_bounds.end
		expect_equal(
			lower_padding,
			upper_padding,
			"%s keeps equal floor padding on opposite GridMap edges." % scene_path
		)
	level.free()


func _check_readable_pit_walls(map_path: String) -> void:
	var floor_map := load(map_path) as FloorMap
	var style_path := _style_path_for_map(map_path)
	var style := load(style_path) as FloorStyle
	var styles: Array[FloorStyle] = [style]
	var pit_result := PitResolver.new().resolve(floor_map, ElevationProfile, styles)
	var bottoms := pit_result["bottom_heights"] as Dictionary[Vector2i, float]
	var expected_region_count := PIT_LEVEL_REGION_COUNTS.get(map_path, 0) as int
	var expected_cell_count := PIT_LEVEL_CELL_COUNTS.get(map_path, 0) as int
	expect_equal(
		pit_result["region_count"],
		expected_region_count,
		"%s resolves only its enclosed holes as pit regions." % map_path
	)
	expect_equal(
		bottoms.size(),
		expected_cell_count,
		"%s retains every enclosed hole cell." % map_path
	)
	var build_result := GeometryBuilder.new().build(
		floor_map,
		ElevationProfile,
		styles,
		1.0,
		Vector2.ZERO
	)
	var mesh := build_result["mesh"] as ArrayMesh
	var collision_shape := build_result["collision_shape"] as ConcavePolygonShape3D
	expect_equal(
		build_result["cell_count"],
		floor_map.get_present_cells().size(),
		"%s generates a top for every painted FloorSurface cell." % map_path
	)
	expect(mesh.get_surface_count() > 0, "%s generates visible FloorSurface geometry." % map_path)
	expect(
		not collision_shape.get_faces().is_empty(),
		"%s generates collision from its painted FloorSurface cells." % map_path
	)
	if bottoms.is_empty():
		return
	expect(
		style.pit_depth >= MINIMUM_READABLE_PIT_DEPTH,
		"%s uses player-scale hole walls rather than its former thin floor slab." % style_path
	)
	var wall_surface := _find_material_surface(mesh, style.get_wall_material())
	expect(wall_surface >= 0, "%s generates a visible wall-material batch." % map_path)
	if wall_surface < 0:
		return
	var arrays := mesh.surface_get_arrays(wall_surface)
	var wall_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for hole_value: Variant in bottoms:
		var hole_cell := hole_value as Vector2i
		var bottom_height := bottoms[hole_cell] as float
		for direction in CARDINAL_DIRECTIONS:
			if not floor_map.has_floor(hole_cell + direction):
				continue
			var bottom_corners := _pit_edge_bottom_corners(
				hole_cell,
				direction,
				bottom_height
			)
			expect(
				wall_vertices.has(bottom_corners[0]) and wall_vertices.has(bottom_corners[1]),
				"%s closes the complete wall beside hole cell %s." % [map_path, hole_cell]
			)


func _style_path_for_map(map_path: String) -> String:
	return map_path.replace("_map.tres", "_style.tres")


func _find_material_surface(mesh: ArrayMesh, material: Material) -> int:
	for surface_index in mesh.get_surface_count():
		if mesh.surface_get_material(surface_index) == material:
			return surface_index
	return -1


func _pit_edge_bottom_corners(
	hole_cell: Vector2i,
	neighbour_direction: Vector2i,
	bottom_height: float
) -> Array[Vector3]:
	var minimum_x := float(hole_cell.x)
	var minimum_z := float(hole_cell.y)
	if neighbour_direction == Vector2i.UP:
		return [
			Vector3(minimum_x, bottom_height, minimum_z),
			Vector3(minimum_x + 1.0, bottom_height, minimum_z),
		]
	if neighbour_direction == Vector2i.RIGHT:
		return [
			Vector3(minimum_x + 1.0, bottom_height, minimum_z),
			Vector3(minimum_x + 1.0, bottom_height, minimum_z + 1.0),
		]
	if neighbour_direction == Vector2i.DOWN:
		return [
			Vector3(minimum_x, bottom_height, minimum_z + 1.0),
			Vector3(minimum_x + 1.0, bottom_height, minimum_z + 1.0),
		]
	return [
		Vector3(minimum_x, bottom_height, minimum_z),
		Vector3(minimum_x, bottom_height, minimum_z + 1.0),
	]


func _horizontal_used_bounds(grid_map: GridMap) -> Rect2i:
	var used_cells := grid_map.get_used_cells()
	var minimum := Vector2i(used_cells[0].x, used_cells[0].z)
	var maximum := minimum
	for cell in used_cells:
		var horizontal_cell := Vector2i(cell.x, cell.z)
		minimum = minimum.min(horizontal_cell)
		maximum = maximum.max(horizontal_cell)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
