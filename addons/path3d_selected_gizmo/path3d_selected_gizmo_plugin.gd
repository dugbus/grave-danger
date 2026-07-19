@tool
extends EditorNode3DGizmoPlugin

const RIBBON_OUTLINE_MATERIAL := "selected_path_ribbon_outline"
const RIBBON_CORE_MATERIAL := "selected_path_ribbon_core"
const POINT_OUTLINE_MATERIAL := "selected_path_point_outline"
const POINT_CORE_MATERIAL := "selected_path_point_core"
const ARROW_OUTLINE_MATERIAL := "selected_path_arrow_outline"
const ARROW_CORE_MATERIAL := "selected_path_arrow_core"
const CURVE_SAMPLE_COUNT := 256
const CURVE_SAMPLES_PER_UNIT := 10.0
const RIBBON_OUTLINE_WIDTH := 0.55
const RIBBON_CORE_WIDTH := 0.28
const RIBBON_OUTLINE_Y_OFFSET := 0.04
const RIBBON_CORE_Y_OFFSET := 0.075
const POINT_OUTLINE_SIZE := Vector3(0.82, 0.12, 0.82)
const POINT_CORE_SIZE := Vector3(0.52, 0.12, 0.52)
const POINT_OUTLINE_Y_OFFSET := 0.0
const POINT_CORE_Y_OFFSET := 0.0
const ARROW_SPACING := 1.6
const ARROW_OUTLINE_LENGTH := 0.9
const ARROW_OUTLINE_WIDTH := 0.72
const ARROW_CORE_LENGTH := 0.56
const ARROW_CORE_WIDTH := 0.38
const ARROW_OUTLINE_Y_OFFSET := 0.18
const ARROW_CORE_Y_OFFSET := 0.22
const DISTANCE_SCALE_FACTOR := 0.075
const MIN_OVERLAY_SCALE := 0.22
const MAX_OVERLAY_SCALE := 1.15
const MAX_EDITOR_VIEWPORTS := 4
const CURVE_HANDLE_EPSILON := 0.001

enum OverlayPass {
	OUTLINE,
	CORE,
}

var _editor_interface: EditorInterface
var _point_outline_mesh := BoxMesh.new()
var _point_core_mesh := BoxMesh.new()


func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_point_outline_mesh.size = POINT_OUTLINE_SIZE
	_point_core_mesh.size = POINT_CORE_SIZE
	add_material(RIBBON_OUTLINE_MATERIAL, _create_overlay_material(Color.BLACK, 0))
	add_material(RIBBON_CORE_MATERIAL, _create_overlay_material(Color.WHITE, 1))
	add_material(ARROW_OUTLINE_MATERIAL, _create_overlay_material(Color.BLACK, 2))
	add_material(ARROW_CORE_MATERIAL, _create_overlay_material(Color.WHITE, 3))
	add_material(POINT_OUTLINE_MATERIAL, _create_overlay_material(Color.BLACK, 4))
	add_material(POINT_CORE_MATERIAL, _create_overlay_material(Color.WHITE, 5))


func _get_gizmo_name() -> String:
	return "Selected Path3D"


func _get_priority() -> int:
	return 1


func _can_be_hidden() -> bool:
	return true


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is Path3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var path := gizmo.get_node_3d() as Path3D
	if path == null or path.curve == null:
		return
	if not _is_selected_path(path):
		return

	var point_positions := _curve_point_positions(path.curve)
	if point_positions.is_empty():
		return

	var overlay_scale := _overlay_scale(path, point_positions)
	var sampled_positions := _sampled_curve_positions(path.curve)
	if sampled_positions.size() >= 2:
		_draw_ribbon(gizmo, sampled_positions, overlay_scale)
		_draw_direction_arrows(gizmo, sampled_positions, overlay_scale)
	_draw_points(gizmo, point_positions, overlay_scale)


func _is_selected_path(path: Path3D) -> bool:
	if _editor_interface == null:
		return false

	for node in _editor_interface.get_selection().get_selected_nodes():
		if node == path:
			return true
	return false


func _curve_point_positions(curve: Curve3D) -> PackedVector3Array:
	var positions := PackedVector3Array()
	for index in curve.point_count:
		positions.append(curve.get_point_position(index))
	return positions


func _sampled_curve_positions(curve: Curve3D) -> PackedVector3Array:
	if _is_straight_polyline(curve):
		return _curve_point_positions(curve)

	var length := curve.get_baked_length()
	if length <= 0.0:
		return _curve_point_positions(curve)

	var sample_count := maxi(2, mini(CURVE_SAMPLE_COUNT, ceili(length * CURVE_SAMPLES_PER_UNIT)))
	var positions := PackedVector3Array()
	for index in sample_count:
		var ratio := float(index) / float(sample_count - 1)
		positions.append(curve.sample_baked(length * ratio, true))
	return positions


func _is_straight_polyline(curve: Curve3D) -> bool:
	for index in curve.point_count:
		if curve.get_point_in(index).length() > CURVE_HANDLE_EPSILON:
			return false
		if curve.get_point_out(index).length() > CURVE_HANDLE_EPSILON:
			return false
	return true


func _draw_ribbon(gizmo: EditorNode3DGizmo, positions: PackedVector3Array, overlay_scale: float) -> void:
	for overlay_pass_value in OverlayPass.values():
		var overlay_pass := overlay_pass_value as OverlayPass
		var material_name := RIBBON_OUTLINE_MATERIAL if overlay_pass == OverlayPass.OUTLINE else RIBBON_CORE_MATERIAL
		gizmo.add_mesh(_build_ribbon_mesh(positions, overlay_pass, overlay_scale), get_material(material_name, gizmo))


func _draw_points(gizmo: EditorNode3DGizmo, positions: PackedVector3Array, overlay_scale: float) -> void:
	var outline_material := get_material(POINT_OUTLINE_MATERIAL, gizmo)
	var core_material := get_material(POINT_CORE_MATERIAL, gizmo)
	var outline_basis := Basis().scaled(Vector3.ONE * overlay_scale)
	var core_basis := Basis().scaled(Vector3.ONE * overlay_scale)
	for position in positions:
		# Keep the marker origin on the exact Curve3D point so it lines up with Godot's selectable handle.
        var outline_position := position + Vector3(0.0, POINT_OUTLINE_Y_OFFSET * overlay_scale, 0.0)
        var core_position := position + Vector3(0.0, POINT_CORE_Y_OFFSET * overlay_scale, 0.0)
        gizmo.add_mesh(_point_outline_mesh, outline_material, Transform3D(outline_basis, outline_position))
        gizmo.add_mesh(_point_core_mesh, core_material, Transform3D(core_basis, core_position))


func _draw_direction_arrows(gizmo: EditorNode3DGizmo, positions: PackedVector3Array, overlay_scale: float) -> void:
    var arrow_centers := _arrow_centers(positions)
    if arrow_centers.is_empty():
        return

    gizmo.add_mesh(
        _build_arrow_mesh(arrow_centers, OverlayPass.OUTLINE, overlay_scale),
        get_material(ARROW_OUTLINE_MATERIAL, gizmo)
    )
    gizmo.add_mesh(
        _build_arrow_mesh(arrow_centers, OverlayPass.CORE, overlay_scale),
        get_material(ARROW_CORE_MATERIAL, gizmo)
    )


func _build_ribbon_mesh(positions: PackedVector3Array, overlay_pass: OverlayPass, overlay_scale: float) -> ArrayMesh:
    var width := (RIBBON_OUTLINE_WIDTH if overlay_pass == OverlayPass.OUTLINE else RIBBON_CORE_WIDTH) * overlay_scale
    var y_offset := (RIBBON_OUTLINE_Y_OFFSET if overlay_pass == OverlayPass.OUTLINE else RIBBON_CORE_Y_OFFSET) * overlay_scale
    var vertices := PackedVector3Array()
    var indices := PackedInt32Array()
    var previous_side := Vector3.ZERO

    for index in positions.size():
        var tangent := _position_tangent(positions, index)
        var side := Vector3.UP.cross(tangent).normalized()
        if side.is_zero_approx():
            side = Vector3.RIGHT
        if not previous_side.is_zero_approx() and side.dot(previous_side) < 0.0:
            side = -side
        previous_side = side

        var center := positions[index] + Vector3(0.0, y_offset, 0.0)
        vertices.append(center - side * width * 0.5)
        vertices.append(center + side * width * 0.5)

    for index in positions.size() - 1:
        var base := index * 2
        indices.append(base)
        indices.append(base + 1)
        indices.append(base + 2)
        indices.append(base + 1)
        indices.append(base + 3)
        indices.append(base + 2)

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh


func _build_arrow_mesh(arrow_centers: Array[Dictionary], overlay_pass: OverlayPass, overlay_scale: float) -> ArrayMesh:
    var length := (ARROW_OUTLINE_LENGTH if overlay_pass == OverlayPass.OUTLINE else ARROW_CORE_LENGTH) * overlay_scale
    var width := (ARROW_OUTLINE_WIDTH if overlay_pass == OverlayPass.OUTLINE else ARROW_CORE_WIDTH) * overlay_scale
    var y_offset := (ARROW_OUTLINE_Y_OFFSET if overlay_pass == OverlayPass.OUTLINE else ARROW_CORE_Y_OFFSET) * overlay_scale
    var vertices := PackedVector3Array()
    var indices := PackedInt32Array()

    for arrow_index in arrow_centers.size():
        var arrow := arrow_centers[arrow_index]
        var center := arrow["position"] as Vector3
        var tangent := (arrow["tangent"] as Vector3).normalized()
        var side := Vector3.UP.cross(tangent).normalized()
        if side.is_zero_approx():
            side = Vector3.RIGHT

        var base_index := arrow_index * 3
        var elevated_center := center + Vector3(0.0, y_offset, 0.0)
        vertices.append(elevated_center + tangent * length * 0.5)
        vertices.append(elevated_center - tangent * length * 0.5 - side * width * 0.5)
        vertices.append(elevated_center - tangent * length * 0.5 + side * width * 0.5)
        indices.append(base_index)
        indices.append(base_index + 1)
        indices.append(base_index + 2)

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh


func _arrow_centers(positions: PackedVector3Array) -> Array[Dictionary]:
    var centers: Array[Dictionary] = []
    var total_length := _polyline_length(positions)
    if total_length <= 0.0:
        return centers

    var arrow_count := maxi(1, floori(total_length / ARROW_SPACING))
    for index in arrow_count:
        var distance := total_length * (float(index) + 1.0) / (float(arrow_count) + 1.0)
        centers.append(_sample_polyline_with_tangent(positions, distance))
    return centers


func _polyline_length(positions: PackedVector3Array) -> float:
    var length := 0.0
    for index in positions.size() - 1:
        length += positions[index].distance_to(positions[index + 1])
    return length


func _sample_polyline_with_tangent(positions: PackedVector3Array, target_distance: float) -> Dictionary:
    var traversed := 0.0
    for index in positions.size() - 1:
        var segment_start := positions[index]
        var segment_end := positions[index + 1]
        var segment := segment_end - segment_start
        var segment_length := segment.length()
        if segment_length <= 0.0:
            continue

        if traversed + segment_length >= target_distance:
            var segment_ratio := (target_distance - traversed) / segment_length
            return {
                "position": segment_start.lerp(segment_end, segment_ratio),
                "tangent": segment / segment_length,
            }
        traversed += segment_length

    return {
        "position": positions[positions.size() - 1],
        "tangent": _position_tangent(positions, positions.size() - 1),
    }


func _overlay_scale(path: Path3D, local_positions: PackedVector3Array) -> float:
    var camera := _editor_camera()
    if camera == null:
        return 1.0

    var closest_distance := INF
    for local_position in local_positions:
        var global_position := path.global_transform * local_position
        closest_distance = minf(closest_distance, camera.global_position.distance_to(global_position))

    if closest_distance == INF:
        return 1.0
    return clampf(closest_distance * DISTANCE_SCALE_FACTOR, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)


func _editor_camera() -> Camera3D:
    if _editor_interface == null:
        return null

    for index in MAX_EDITOR_VIEWPORTS:
        var viewport: SubViewport = _editor_interface.get_editor_viewport_3d(index)
        if viewport != null and viewport.get_camera_3d() != null:
            return viewport.get_camera_3d()
    return null


func _position_tangent(positions: PackedVector3Array, index: int) -> Vector3:
    if index <= 0:
        return (positions[1] - positions[0]).normalized()
    if index >= positions.size() - 1:
        return (positions[index] - positions[index - 1]).normalized()
    return (positions[index + 1] - positions[index - 1]).normalized()


func _create_overlay_material(color: Color, render_priority: int) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.no_depth_test = true
    material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    material.render_priority = render_priority
    return material
