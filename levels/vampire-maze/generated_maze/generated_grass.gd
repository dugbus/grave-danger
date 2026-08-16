@tool
class_name GDGeneratedMazeGrass
extends MultiMeshInstance3D

## Builds deterministic plasma-clustered grass patches from walkable floor cells.

const NOISE_SEED_SALT := 1327217884
const TRANSFORM_SEED_SALT := 915488749
const MINIMUM_BLADE_SCALE := 0.82
const MAXIMUM_BLADE_SCALE := 1.18
const CELL_JITTER_RADIUS := 0.42
const FLOOR_OFFSET := 0.015

## Serialized blade transforms used to restore the generated editor preview.
@export_storage var generated_transforms: Array[Transform3D] = []


func _ready() -> void:
	if Engine.is_editor_hint() and not generated_transforms.is_empty():
		call_deferred(&"_restore_editor_preview")


## Replaces the current MultiMesh transforms with one seeded patch layout.
func populate(
	floor_cells: Dictionary,
	floor_grid_map: GridMap,
	excluded_cells: Dictionary,
	seed_value: int,
	coverage_percent: float,
	patch_size_tiles: float,
	blades_per_cell: int
) -> Dictionary:
	if floor_grid_map == null or not floor_grid_map.is_inside_tree() \
			or not is_inside_tree():
		_clear_instances()
		return {"errors": ["Generated grass requires scene-tree GridMap and grass nodes."]}

	var plasma := _create_plasma(seed_value, patch_size_tiles)

	var candidates: Array[Dictionary] = []
	for cell_value in floor_cells:
		var cell := cell_value as Vector2i
		var floor_cell := Vector3i(cell.x, 0, cell.y)
		if excluded_cells.has(cell) \
				or floor_grid_map.get_cell_item(floor_cell) == GridMap.INVALID_CELL_ITEM:
			continue
		candidates.append({
			"cell": cell,
			"score": plasma.get_noise_2d(float(cell.x), float(cell.y)),
		})
	candidates.sort_custom(_sort_patch_candidate)
	var selected_count := clampi(
		roundi(
			float(candidates.size())
			* clampf(coverage_percent, 0.0, 100.0)
			/ 100.0
		),
		0,
		candidates.size()
	)
	var selected_cells: Array[Vector2i] = []
	var blade_counts := {}
	var minimum_selected_score := 0.0
	var maximum_selected_score := 0.0
	if selected_count > 0:
		minimum_selected_score = float(candidates[selected_count - 1]["score"])
		maximum_selected_score = float(candidates[0]["score"])
	for candidate_index in selected_count:
		var candidate := candidates[candidate_index] as Dictionary
		var selected_cell := candidate["cell"] as Vector2i
		selected_cells.append(selected_cell)
		blade_counts[selected_cell] = _blade_count_for_plasma_score(
			float(candidate["score"]),
			minimum_selected_score,
			maximum_selected_score,
			blades_per_cell
		)

	var random := RandomNumberGenerator.new()
	random.seed = seed_value ^ TRANSFORM_SEED_SALT
	var transforms: Array[Transform3D] = []
	for cell in selected_cells:
		var cell_world_position := floor_grid_map.to_global(
			floor_grid_map.map_to_local(Vector3i(cell.x, 0, cell.y))
		)
		var cell_local_position := to_local(cell_world_position)
		for _blade_index in int(blade_counts[cell]):
			var blade_position := cell_local_position + Vector3(
				random.randf_range(-CELL_JITTER_RADIUS, CELL_JITTER_RADIUS),
				FLOOR_OFFSET,
				random.randf_range(-CELL_JITTER_RADIUS, CELL_JITTER_RADIUS)
			)
			var blade_scale := random.randf_range(
				MINIMUM_BLADE_SCALE,
				MAXIMUM_BLADE_SCALE
			)
			var blade_basis := Basis(
				Vector3.UP,
				random.randf_range(0.0, TAU)
			).scaled(Vector3.ONE * blade_scale)
			transforms.append(Transform3D(blade_basis, blade_position))
	_set_transforms(transforms)
	return {
		"errors": [],
		"cells": selected_cells,
		"blade_counts": blade_counts,
		"instance_count": transforms.size(),
	}


func _set_transforms(transforms: Array[Transform3D]) -> void:
	generated_transforms = transforms.duplicate()
	_apply_transforms(transforms)
	if Engine.is_editor_hint() and not transforms.is_empty():
		# Layout generation can finish during the editor's scene attachment pass.
		# Rebinding once deferred makes the completed batch visible in that viewport.
		call_deferred(&"_restore_editor_preview")


func _apply_transforms(transforms: Array[Transform3D]) -> void:
	var source_mesh := multimesh.mesh if multimesh != null else null
	var generated_multimesh := MultiMesh.new()
	generated_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	generated_multimesh.mesh = source_mesh
	generated_multimesh.instance_count = transforms.size()
	generated_multimesh.buffer = _build_transform_buffer(transforms)
	# Updating each instance also refreshes the editor renderer immediately;
	# the packed buffer above keeps those transforms serializable with Layout.
	for transform_index in transforms.size():
		generated_multimesh.set_instance_transform(
			transform_index,
			transforms[transform_index]
		)
	multimesh = generated_multimesh
	generated_multimesh.visible_instance_count = -1
	custom_aabb = _calculate_bounds(transforms, source_mesh)
	generated_multimesh.emit_changed()
	notify_property_list_changed()


func _restore_editor_preview() -> void:
	if generated_transforms.is_empty():
		return
	_apply_transforms(generated_transforms)


func _create_plasma(seed_value: int, patch_size_tiles: float) -> FastNoiseLite:
	var plasma := FastNoiseLite.new()
	plasma.seed = seed_value ^ NOISE_SEED_SALT
	plasma.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	plasma.fractal_type = FastNoiseLite.FRACTAL_FBM
	plasma.frequency = 1.0 / maxf(patch_size_tiles, 1.0)
	plasma.fractal_octaves = 4
	plasma.fractal_lacunarity = 2.0
	plasma.fractal_gain = 0.5
	return plasma


func _blade_count_for_plasma_score(
	score: float,
	minimum_score: float,
	maximum_score: float,
	maximum_blades: int
) -> int:
	var safe_maximum_blades := maxi(maximum_blades, 1)
	if is_equal_approx(minimum_score, maximum_score):
		return safe_maximum_blades
	var density := inverse_lerp(minimum_score, maximum_score, score)
	return clampi(
		roundi(lerpf(1.0, float(safe_maximum_blades), density)),
		1,
		safe_maximum_blades
	)


func _calculate_bounds(
	transforms: Array[Transform3D],
	source_mesh: Mesh
) -> AABB:
	if transforms.is_empty() or source_mesh == null:
		return AABB()
	var mesh_bounds := source_mesh.get_aabb()
	var generated_bounds := transforms[0] * mesh_bounds
	for transform_index in range(1, transforms.size()):
		generated_bounds = generated_bounds.merge(
			transforms[transform_index] * mesh_bounds
		)
	return generated_bounds.grow(CELL_JITTER_RADIUS)


func _build_transform_buffer(transforms: Array[Transform3D]) -> PackedFloat32Array:
	var transform_buffer := PackedFloat32Array()
	transform_buffer.resize(transforms.size() * 12)
	for transform_index in transforms.size():
		var instance_transform := transforms[transform_index]
		var buffer_index := transform_index * 12
		transform_buffer[buffer_index] = instance_transform.basis.x.x
		transform_buffer[buffer_index + 1] = instance_transform.basis.y.x
		transform_buffer[buffer_index + 2] = instance_transform.basis.z.x
		transform_buffer[buffer_index + 3] = instance_transform.origin.x
		transform_buffer[buffer_index + 4] = instance_transform.basis.x.y
		transform_buffer[buffer_index + 5] = instance_transform.basis.y.y
		transform_buffer[buffer_index + 6] = instance_transform.basis.z.y
		transform_buffer[buffer_index + 7] = instance_transform.origin.y
		transform_buffer[buffer_index + 8] = instance_transform.basis.x.z
		transform_buffer[buffer_index + 9] = instance_transform.basis.y.z
		transform_buffer[buffer_index + 10] = instance_transform.basis.z.z
		transform_buffer[buffer_index + 11] = instance_transform.origin.z
	return transform_buffer


func _clear_instances() -> void:
	_set_transforms([] as Array[Transform3D])


func _sort_patch_candidate(first: Dictionary, second: Dictionary) -> bool:
	var first_score := float(first["score"])
	var second_score := float(second["score"])
	if not is_equal_approx(first_score, second_score):
		return first_score > second_score
	var first_cell := first["cell"] as Vector2i
	var second_cell := second["cell"] as Vector2i
	if first_cell.y != second_cell.y:
		return first_cell.y < second_cell.y
	return first_cell.x < second_cell.x
