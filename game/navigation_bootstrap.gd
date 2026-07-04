extends RefCounted
class_name GDNavigationBootstrap


const RUNTIME_NAVIGATION_REGION_NAME := "RuntimeNavigationRegion"
const RUNTIME_NAVIGATION_MESH_NAME := "RuntimeNavigationMesh"
const RUNTIME_NAVIGATION_OBSTACLE_NAME := "RuntimeNavigationObstacle"
const NAVIGATION_BLOCKER_GROUP := &"navigation_blocker"
const SMART_ZOMBIE_GROUP := &"smart_zombie"
const PLAYER_GROUP := &"player"
const GAMEPLAY_PROCESS_GROUP := &"deterministic_gameplay_process"
const NAVIGATION_MARGIN := 3.0
const DEFAULT_HALF_EXTENTS := 30.0


static func prepare_level(level: Node) -> void:
    if level == null:
        return

    var tree := level.get_tree()
    if tree == null:
        return

    _set_player_processing(level, false)
    _set_runtime_gameplay_processing(level, false)
    _set_zombie_navigation_ready(level, false)
    _ensure_navigation_region(level)
    _ensure_navigation_obstacles(level)
    _set_zombie_navigation_grid_maps(level)
    await tree.physics_frame
    await tree.physics_frame
    _set_zombie_navigation_ready(level, true)
    _set_runtime_gameplay_processing(level, true)
    _set_player_processing(level, true)


static func _ensure_navigation_region(level: Node) -> NavigationRegion3D:
    var region := level.get_node_or_null(RUNTIME_NAVIGATION_REGION_NAME) as NavigationRegion3D
    if region == null:
        region = NavigationRegion3D.new()
        region.name = RUNTIME_NAVIGATION_REGION_NAME
        level.add_child(region)

    var mesh := NavigationMesh.new()
    mesh.resource_name = RUNTIME_NAVIGATION_MESH_NAME
    _configure_simple_navigation_mesh(mesh, _get_navigation_bounds(level))
    region.navigation_mesh = mesh
    region.enabled = true
    return region


static func _configure_simple_navigation_mesh(mesh: NavigationMesh, bounds: Rect2) -> void:
    var min_x := bounds.position.x
    var min_z := bounds.position.y
    var max_x := bounds.position.x + bounds.size.x
    var max_z := bounds.position.y + bounds.size.y
    var vertices := PackedVector3Array([
        Vector3(min_x, 0.0, min_z),
        Vector3(max_x, 0.0, min_z),
        Vector3(max_x, 0.0, max_z),
        Vector3(min_x, 0.0, max_z),
    ])

    mesh.clear_polygons()
    mesh.vertices = vertices
    mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))


static func _get_navigation_bounds(level: Node) -> Rect2:
    var has_point := false
    var min_x := INF
    var min_z := INF
    var max_x := -INF
    var max_z := -INF

    for node in _get_descendants(level):
        if node is GridMap:
            for cell in (node as GridMap).get_used_cells():
                var point := (node as GridMap).to_global((node as GridMap).map_to_local(cell))
                min_x = minf(min_x, point.x)
                min_z = minf(min_z, point.z)
                max_x = maxf(max_x, point.x)
                max_z = maxf(max_z, point.z)
                has_point = true
        elif node is Node3D:
            var position := (node as Node3D).global_position
            min_x = minf(min_x, position.x)
            min_z = minf(min_z, position.z)
            max_x = maxf(max_x, position.x)
            max_z = maxf(max_z, position.z)
            has_point = true

    if not has_point:
        return Rect2(
            Vector2(-DEFAULT_HALF_EXTENTS, -DEFAULT_HALF_EXTENTS),
            Vector2(DEFAULT_HALF_EXTENTS * 2.0, DEFAULT_HALF_EXTENTS * 2.0)
        )

    min_x -= NAVIGATION_MARGIN
    min_z -= NAVIGATION_MARGIN
    max_x += NAVIGATION_MARGIN
    max_z += NAVIGATION_MARGIN
    return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))


static func _ensure_navigation_obstacles(level: Node) -> void:
    for node in _get_descendants(level):
        if not node is Node3D:
            continue
        if not node.is_in_group(NAVIGATION_BLOCKER_GROUP):
            continue

        var node_3d := node as Node3D
        if node_3d.get_node_or_null(RUNTIME_NAVIGATION_OBSTACLE_NAME) != null:
            continue

        var obstacle := NavigationObstacle3D.new()
        obstacle.name = RUNTIME_NAVIGATION_OBSTACLE_NAME
        node_3d.add_child(obstacle)


static func _set_zombie_navigation_ready(level: Node, is_ready: bool) -> void:
    for node in _get_descendants(level):
        if node.is_in_group(SMART_ZOMBIE_GROUP) and node.has_method("set_navigation_ready"):
            node.set_navigation_ready(is_ready)


static func _set_zombie_navigation_grid_maps(level: Node) -> void:
    var grid_maps: Array[GridMap] = []
    for node in _get_descendants(level):
        if node is GridMap:
            grid_maps.append(node as GridMap)

    for node in _get_descendants(level):
        if node.is_in_group(SMART_ZOMBIE_GROUP) and node.has_method("set_navigation_grid_maps"):
            node.set_navigation_grid_maps(grid_maps)


static func _set_player_processing(level: Node, enabled: bool) -> void:
    for node in _get_descendants(level):
        if node.is_in_group(PLAYER_GROUP):
            node.set_physics_process(enabled)


static func _set_runtime_gameplay_processing(level: Node, enabled: bool) -> void:
    for node in _get_descendants(level):
        if node.is_in_group(GAMEPLAY_PROCESS_GROUP):
            node.set_physics_process(enabled)


static func _get_descendants(root: Node) -> Array[Node]:
    var descendants: Array[Node] = []
    for child in root.get_children():
        descendants.append(child)
        descendants.append_array(_get_descendants(child))
    return descendants
