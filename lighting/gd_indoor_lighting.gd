class_name GDIndoorLighting
extends Node3D

const GRID_MAP_SHADOW_CASTERS_NAME := "GridMapShadowCasters"
const SHADOW_VOLUME_INSET := 0.01
const AUTHORED_SHADOW_SETTINGS_GROUP: StringName = &"authored_shadow_settings"

## Fully opaque indoor shadows prevent lit geometry from showing through occluders.
@export_range(0.0, 1.0, 0.01) var shadow_opacity := 1.0
## Depth bias used by indoor lights to prevent wall faces from shadowing themselves.
@export_range(0.0, 1.0, 0.001) var shadow_bias := 0.03
## Normal bias used by indoor lights to prevent acne on faces near wall shadow volumes.
@export_range(0.0, 10.0, 0.01) var shadow_normal_bias := 0.6

var level_root: Node3D


func _ready() -> void:
    level_root = get_parent() as Node3D
    strengthen_level_shadows()


## Applies the indoor occlusion settings to every shadow-casting light in this level.
func strengthen_level_shadows() -> void:
    level_root = get_parent() as Node3D
    if level_root == null:
        return

    _create_grid_map_shadow_casters()

    for node in level_root.find_children("*", "Light3D", true, false):
        var light := node as Light3D
        if not light.shadow_enabled \
                or light.name in [&"PlayerHeadlampLight", &"PlayerLight"] \
                or light.is_in_group(AUTHORED_SHADOW_SETTINGS_GROUP):
            continue

        light.shadow_opacity = shadow_opacity
        light.shadow_bias = shadow_bias
        light.shadow_normal_bias = shadow_normal_bias


func _create_grid_map_shadow_casters() -> void:
    for node in level_root.find_children("*", "GridMap", true, false):
        var grid_map := node as GridMap
        if grid_map.has_node(GRID_MAP_SHADOW_CASTERS_NAME):
            continue

        var mesh_library := grid_map.mesh_library
        if mesh_library == null:
            continue

        var shadow_casters := Node3D.new()
        shadow_casters.name = GRID_MAP_SHADOW_CASTERS_NAME
        grid_map.add_child(shadow_casters)

        for item_id in mesh_library.get_item_list():
            if not mesh_library.get_item_name(item_id).begins_with("Wall") \
                    or mesh_library.get_item_mesh_cast_shadow(item_id) \
                    == RenderingServer.SHADOW_CASTING_SETTING_OFF:
                continue

            var used_cells := grid_map.get_used_cells_by_item(item_id)
            if used_cells.is_empty():
                continue

            var occluder_bounds := _get_item_occluder_bounds(mesh_library, item_id)
            if not occluder_bounds.has_volume():
                continue

            var caster_mesh := BoxMesh.new()
            caster_mesh.size = Vector3(
                maxf(occluder_bounds.size.x - SHADOW_VOLUME_INSET * 2.0, 0.01),
                occluder_bounds.size.y,
                maxf(occluder_bounds.size.z - SHADOW_VOLUME_INSET * 2.0, 0.01)
            )
            var multimesh := MultiMesh.new()
            multimesh.transform_format = MultiMesh.TRANSFORM_3D
            multimesh.mesh = caster_mesh
            multimesh.instance_count = used_cells.size()
            var bounds_transform := Transform3D(Basis.IDENTITY, occluder_bounds.get_center())
            for cell_index in used_cells.size():
                var cell := used_cells[cell_index]
                var cell_transform := Transform3D(
                    grid_map.get_cell_item_basis(cell),
                    grid_map.map_to_local(cell)
                )
                multimesh.set_instance_transform(cell_index, cell_transform * bounds_transform)

            var caster := MultiMeshInstance3D.new()
            caster.name = "ShadowCaster%d" % item_id
            var caster_material := StandardMaterial3D.new()
            caster_material.cull_mode = BaseMaterial3D.CULL_DISABLED
            caster.material_override = caster_material
            caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
            caster.multimesh = multimesh
            shadow_casters.add_child(caster)


func _get_item_occluder_bounds(mesh_library: MeshLibrary, item_id: int) -> AABB:
    var bounds := AABB()
    var has_bounds := false
    var shapes := mesh_library.get_item_shapes(item_id)
    for shape_index in range(0, shapes.size(), 2):
        var shape := shapes[shape_index] as Shape3D
        var shape_transform := shapes[shape_index + 1] as Transform3D
        if not shape is ConvexPolygonShape3D:
            continue

        for point in (shape as ConvexPolygonShape3D).points:
            var transformed_point := shape_transform * point
            if not has_bounds:
                bounds = AABB(transformed_point, Vector3.ZERO)
                has_bounds = true
            else:
                bounds = bounds.expand(transformed_point)

    if has_bounds:
        return bounds

    var mesh := mesh_library.get_item_mesh(item_id)
    if mesh == null:
        return AABB()

    return mesh_library.get_item_mesh_transform(item_id) * mesh.get_aabb()
