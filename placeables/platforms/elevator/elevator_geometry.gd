@tool
extends RefCounted

## Six closed faces with the owning floor palette's materials and UV scales.


static func build(surface: FloorSurface, origin: Vector3, width: float, depth: float, thickness: float) -> ArrayMesh:
	var cell := surface.world_to_cell(origin)
	var index := clampi(surface.floor_map.get_cell_style(cell), 0, surface.styles.size() - 1)
	var style := surface.styles[index] as FloorStyle
	var mesh := ArrayMesh.new()
	var x := width * 0.5
	var z := depth * 0.5
	var a := Vector3(-x, 0.0, -z)
	var b := Vector3(-x, 0.0, z)
	var c := Vector3(x, 0.0, z)
	var d := Vector3(x, 0.0, -z)
	var down := Vector3.DOWN * thickness
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_face(top, [a, b, c, d], Vector3.UP, origin, style, surface)
	top.set_material(style.top_material)
	top.commit(mesh)
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_face(walls, [d, c, b, a], Vector3.DOWN, origin + down, style, surface, down)
	_append_face(walls, [a, d, d + down, a + down], Vector3.FORWARD, origin, style, surface)
	_append_face(walls, [c, b, b + down, c + down], Vector3.BACK, origin, style, surface)
	_append_face(walls, [b, a, a + down, b + down], Vector3.LEFT, origin, style, surface)
	_append_face(walls, [d, c, c + down, d + down], Vector3.RIGHT, origin, style, surface)
	walls.set_material(style.get_wall_material())
	walls.commit(mesh)
	return mesh


static func _append_face(
	tool: SurfaceTool,
	corners: Array[Vector3],
	normal: Vector3,
	origin: Vector3,
	style: FloorStyle,
	surface: FloorSurface,
	offset := Vector3.ZERO
) -> void:
	for index in [0, 2, 1, 0, 3, 2]:
		var vertex := corners[index] + offset
		var world := corners[index] + origin
		var uv := Vector2.ZERO
		if normal.y > 0.5:
			uv = Vector2(world.x, world.z) / style.world_uv_metres
			if style.top_uv_mapping == FloorStyle.TopUvMapping.SurfaceNormalized:
				var start := surface.world_origin_xz + Vector2(surface.floor_map.minimum_cell) * surface.cell_size
				uv = (Vector2(world.x, world.z) - start) / (Vector2(surface.floor_map.dimensions) * surface.cell_size)
		else:
			uv = Vector2(world.z if absf(normal.x) > 0.5 else world.x, -world.y) / style.wall_uv_metres
		tool.set_normal(normal)
		tool.set_uv(uv)
		tool.add_vertex(vertex)
