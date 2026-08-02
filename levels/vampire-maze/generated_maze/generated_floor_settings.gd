class_name GDGeneratedFloorSettings
extends RefCounted

## Builds phased floor meshes so one texture can span several generated GridMap cells.


static func apply(
    floor_grid_map: GridMap,
    configured_material: BaseMaterial3D,
    texture_tile_size: Vector2i
) -> void:
    var source_library := floor_grid_map.mesh_library
    if source_library == null or source_library.get_item_list().is_empty():
        return

    var floor_item_id := int(source_library.get_item_list()[0])
    var source_mesh := source_library.get_item_mesh(floor_item_id) as PlaneMesh
    if source_mesh == null:
        return

    if configured_material == null:
        configured_material = source_mesh.material as BaseMaterial3D
    if configured_material == null:
        return

    var phase_size := Vector2i(
        maxi(texture_tile_size.x, 1),
        maxi(texture_tile_size.y, 1)
    )
    var source_name := source_library.get_item_name(floor_item_id)
    var source_transform := source_library.get_item_mesh_transform(floor_item_id)
    var source_casts_shadow := source_library.get_item_mesh_cast_shadow(floor_item_id)
    var source_shapes := source_library.get_item_shapes(floor_item_id)
    var source_navigation_mesh := source_library.get_item_navigation_mesh(floor_item_id)
    var source_navigation_transform := source_library.get_item_navigation_mesh_transform(
        floor_item_id
    )
    var source_navigation_layers := source_library.get_item_navigation_layers(floor_item_id)
    var floor_library := MeshLibrary.new()
    for y_phase in phase_size.y:
        for x_phase in phase_size.x:
            var phase_item_id := y_phase * phase_size.x + x_phase
            var floor_material := configured_material.duplicate() as BaseMaterial3D
            floor_material.uv1_scale = Vector3(
                1.0 / float(phase_size.x),
                1.0 / float(phase_size.y),
                1.0
            )
            floor_material.uv1_offset = Vector3(
                float(x_phase) / float(phase_size.x),
                float(y_phase) / float(phase_size.y),
                0.0
            )
            var floor_mesh := source_mesh.duplicate() as PlaneMesh
            floor_mesh.material = floor_material
            floor_library.create_item(phase_item_id)
            floor_library.set_item_name(phase_item_id, "%s %d" % [source_name, phase_item_id])
            floor_library.set_item_mesh(phase_item_id, floor_mesh)
            floor_library.set_item_mesh_transform(phase_item_id, source_transform)
            floor_library.set_item_mesh_cast_shadow(phase_item_id, source_casts_shadow)
            floor_library.set_item_shapes(phase_item_id, source_shapes.duplicate(true))
            floor_library.set_item_navigation_mesh(phase_item_id, source_navigation_mesh)
            floor_library.set_item_navigation_mesh_transform(
                phase_item_id,
                source_navigation_transform
            )
            floor_library.set_item_navigation_layers(phase_item_id, source_navigation_layers)
    floor_grid_map.mesh_library = floor_library


static func item_id_for_cell(
    floor_grid_map: GridMap,
    cell: Vector2i,
    texture_tile_size: Vector2i
) -> int:
    var item_ids := floor_grid_map.mesh_library.get_item_list()
    var phase_size := Vector2i(
        maxi(texture_tile_size.x, 1),
        maxi(texture_tile_size.y, 1)
    )
    var phase_index := posmod(cell.y, phase_size.y) * phase_size.x \
        + posmod(cell.x, phase_size.x)
    return int(item_ids[mini(phase_index, item_ids.size() - 1)])
