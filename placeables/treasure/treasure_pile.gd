@tool
class_name GDTreasurePile
extends "res://placeables/treasure/collectible_pile.gd"

## Configurable mixed treasure pile whose inspector types are discovered from marked treasure scenes.

const TREASURE_DIRECTORY := "res://placeables/treasure"
const BUILTIN_TREASURE_TYPES: Array[StringName] = [
    &"gold_coin",
    &"diamond",
    &"ruby",
    &"sapphire",
    &"emerald",
    &"amethyst",
    &"gold_bar",
]
const COUNT_PROPERTY_PREFIX := "treasure_count_"
const MAX_TREASURE_COUNT := 500
const TREASURE_PILE_COMPATIBLE_GROUP: StringName = &"treasure_pile_compatible"
const TREASURE_PILE_SCENE_PATH := "res://placeables/treasure/treasure_pile.tscn"

@export_group("Pile Contents")
## Number of individual gold coins spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var gold_coin_count := 5:
    set(value):
        gold_coin_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual diamonds spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var diamond_count := 3:
    set(value):
        diamond_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual rubies spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var ruby_count := 0:
    set(value):
        ruby_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual sapphires spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var sapphire_count := 0:
    set(value):
        sapphire_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual emeralds spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var emerald_count := 0:
    set(value):
        emerald_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual amethysts spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var amethyst_count := 0:
    set(value):
        amethyst_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
## Number of individual gold bars spawned by this pile.
@export_range(0, MAX_TREASURE_COUNT, 1) var gold_bar_count := 3:
    set(value):
        gold_bar_count = clampi(value, 0, MAX_TREASURE_COUNT)
        _on_treasure_count_changed()
@export_group("")

## Persisted counts for compatible treasure types discovered after the built-in types.
@export_storage var treasure_counts: Dictionary = {}

static var cached_catalog: Array[Dictionary] = []
static var is_catalog_cached := false

var treasure_catalog: Array[Dictionary] = []
var spawn_plan: Array[PackedScene] = []


func _ready() -> void:
    _refresh_treasure_catalog()
    if Engine.is_editor_hint():
        _connect_editor_filesystem_scan()
    super._ready()


func _get_property_list() -> Array[Dictionary]:
    if treasure_catalog.is_empty():
        _load_treasure_catalog()

    var properties: Array[Dictionary] = []
    if treasure_catalog.is_empty():
        return properties

    for entry in treasure_catalog:
        if _is_builtin_treasure_type(entry["item_type"] as StringName):
            continue
        properties.append({
            "name": COUNT_PROPERTY_PREFIX + String(entry["item_type"]),
            "type": TYPE_INT,
            "hint": PROPERTY_HINT_RANGE,
            "hint_string": "0,%d,1" % MAX_TREASURE_COUNT,
            "usage": PROPERTY_USAGE_DEFAULT,
        })

    if not properties.is_empty():
        properties.push_front({
            "name": "Additional Treasure Types",
            "type": TYPE_NIL,
            "hint_string": COUNT_PROPERTY_PREFIX,
            "usage": PROPERTY_USAGE_GROUP,
        })

    return properties


func _get(property: StringName) -> Variant:
    var property_name := String(property)
    if not property_name.begins_with(COUNT_PROPERTY_PREFIX):
        return null

    return get_treasure_count(StringName(property_name.trim_prefix(COUNT_PROPERTY_PREFIX)))


func _set(property: StringName, value: Variant) -> bool:
    var property_name := String(property)
    if not property_name.begins_with(COUNT_PROPERTY_PREFIX):
        return false

    set_treasure_count(
        StringName(property_name.trim_prefix(COUNT_PROPERTY_PREFIX)),
        int(value)
    )
    return true


func get_compatible_treasure_types() -> Array[StringName]:
    var item_types: Array[StringName] = []
    for entry in treasure_catalog:
        item_types.append(entry["item_type"] as StringName)
    return item_types


func get_treasure_count(item_type: StringName) -> int:
    match item_type:
        &"gold_coin":
            return gold_coin_count
        &"diamond":
            return diamond_count
        &"ruby":
            return ruby_count
        &"sapphire":
            return sapphire_count
        &"emerald":
            return emerald_count
        &"amethyst":
            return amethyst_count
        &"gold_bar":
            return gold_bar_count
        _:
            return maxi(int(treasure_counts.get(item_type, 0)), 0)


func set_treasure_count(item_type: StringName, count: int) -> void:
    if item_type == &"":
        return

    var safe_count := clampi(count, 0, MAX_TREASURE_COUNT)
    match item_type:
        &"gold_coin":
            gold_coin_count = safe_count
            return
        &"diamond":
            diamond_count = safe_count
            return
        &"ruby":
            ruby_count = safe_count
            return
        &"sapphire":
            sapphire_count = safe_count
            return
        &"emerald":
            emerald_count = safe_count
            return
        &"amethyst":
            amethyst_count = safe_count
            return
        &"gold_bar":
            gold_bar_count = safe_count
            return

    if safe_count <= 0:
        treasure_counts.erase(item_type)
    else:
        treasure_counts[item_type] = safe_count
    _on_treasure_count_changed()


func get_max_treasure_value() -> int:
    var total := 0
    for entry in treasure_catalog:
        total += get_treasure_count(entry["item_type"] as StringName) \
            * maxi(int(entry["treasure_value"]), 0)
    return total


func _get_item_count() -> int:
    var total := 0
    for entry in treasure_catalog:
        total += get_treasure_count(entry["item_type"] as StringName)
    return total


func _get_collectible_scene() -> PackedScene:
    if spawn_plan.size() != _get_item_count():
        _rebuild_spawn_plan()
    if spawned_items < 0 or spawned_items >= spawn_plan.size():
        return null
    return spawn_plan[spawned_items]


func _get_seed_salt() -> StringName:
    return &"treasure_pile"


func _create_preview_item(index: int) -> Node3D:
    if spawn_plan.size() != _get_item_count():
        _rebuild_spawn_plan()
    if index < 0 or index >= spawn_plan.size():
        return null

    var collectible_preview := spawn_plan[index].instantiate() as Node3D
    if collectible_preview == null:
        return null

    var visual_preview := Node3D.new()
    _copy_preview_meshes(
        collectible_preview,
        Transform3D.IDENTITY,
        visual_preview,
        null,
        null
    )
    if visual_preview.get_child_count() <= 0:
        collectible_preview.process_mode = Node.PROCESS_MODE_DISABLED
        return collectible_preview

    collectible_preview.free()
    return visual_preview


func _refresh_treasure_catalog(force_scan := false) -> void:
    _load_treasure_catalog(force_scan)
    notify_property_list_changed()
    _refresh_preview_when_editing()


func _load_treasure_catalog(force_scan := false) -> void:
    if force_scan or not is_catalog_cached:
        cached_catalog = _scan_compatible_treasure_scenes()
        is_catalog_cached = true

    treasure_catalog.clear()
    for entry in cached_catalog:
        treasure_catalog.append(entry.duplicate())
    _rebuild_spawn_plan()


func _scan_compatible_treasure_scenes() -> Array[Dictionary]:
    var scene_paths: Array[String] = []
    _collect_scene_paths(TREASURE_DIRECTORY, scene_paths)
    scene_paths.sort()

    var catalog: Array[Dictionary] = []
    var discovered_types := {}
    for scene_path in scene_paths:
        if scene_path == TREASURE_PILE_SCENE_PATH:
            continue

        var scene := load(scene_path) as PackedScene
        if scene == null:
            continue
        var collectible := scene.instantiate() as Node
        if collectible == null:
            continue
        if not collectible.is_in_group(TREASURE_PILE_COMPATIBLE_GROUP):
            collectible.free()
            continue

        var carried_item := collectible.get("carried_item") as Resource
        if carried_item == null:
            push_warning(
                "Treasure pile-compatible scene '%s' has no carried_item resource." % scene_path
            )
            collectible.free()
            continue

        var item_type: StringName = carried_item.get("item_type")
        if item_type == &"":
            push_warning(
                "Treasure pile-compatible scene '%s' has no carried item type." % scene_path
            )
            collectible.free()
            continue
        if discovered_types.has(item_type):
            push_warning(
                "Treasure type '%s' is marked compatible by more than one scene; using '%s'." \
                % [String(item_type), String(discovered_types[item_type])]
            )
            collectible.free()
            continue

        var display_name := String(carried_item.get("display_name"))
        if display_name.is_empty():
            display_name = String(collectible.name)
        catalog.append({
            "display_name": display_name,
            "item_type": item_type,
            "scene": scene,
            "scene_path": scene_path,
            "treasure_value": int(carried_item.get("treasure_value")),
        })
        discovered_types[item_type] = scene_path
        collectible.free()

    catalog.sort_custom(_sort_catalog_entries)
    return catalog


func _collect_scene_paths(directory_path: String, scene_paths: Array[String]) -> void:
    var directory := DirAccess.open(directory_path)
    if directory == null:
        push_warning("Treasure pile could not scan '%s'." % directory_path)
        return

    directory.list_dir_begin()
    var entry_name := directory.get_next()
    while not entry_name.is_empty():
        if not entry_name.begins_with("."):
            var entry_path := directory_path.path_join(entry_name)
            if directory.current_is_dir():
                _collect_scene_paths(entry_path, scene_paths)
            elif entry_name.get_extension().to_lower() == "tscn":
                scene_paths.append(entry_path)
        entry_name = directory.get_next()
    directory.list_dir_end()


func _rebuild_spawn_plan() -> void:
    spawn_plan.clear()
    for entry in treasure_catalog:
        var collectible_scene := entry["scene"] as PackedScene
        var count := get_treasure_count(entry["item_type"] as StringName)
        for _item_index in count:
            spawn_plan.append(collectible_scene)


func _on_treasure_count_changed() -> void:
    _rebuild_spawn_plan()
    _refresh_preview_when_editing()


func _is_builtin_treasure_type(item_type: StringName) -> bool:
    return item_type in BUILTIN_TREASURE_TYPES


func _copy_preview_meshes(
    source: Node,
    parent_transform: Transform3D,
    preview_root: Node3D,
    inherited_surface_material: Material,
    inherited_overlay_material: Material
) -> void:
    var source_transform := parent_transform
    if source is Node3D:
        source_transform *= (source as Node3D).transform

    var surface_material := _get_authored_preview_material(
        source,
        inherited_surface_material
    )
    var overlay_material := _get_authored_preview_overlay(
        source,
        inherited_overlay_material
    )
    if source is MeshInstance3D:
        var source_mesh := source as MeshInstance3D
        if source_mesh.mesh != null:
            var preview_mesh := MeshInstance3D.new()
            preview_mesh.name = source_mesh.name
            preview_mesh.transform = source_transform
            preview_mesh.mesh = source_mesh.mesh
            preview_mesh.layers = source_mesh.layers
            preview_mesh.cast_shadow = source_mesh.cast_shadow
            preview_mesh.visible = source_mesh.visible
            if surface_material != null:
                preview_mesh.material_override = surface_material
            else:
                preview_mesh.material_override = source_mesh.material_override
                for surface_index in source_mesh.mesh.get_surface_count():
                    preview_mesh.set_surface_override_material(
                        surface_index,
                        source_mesh.get_surface_override_material(surface_index)
                    )
            if overlay_material != null:
                preview_mesh.material_overlay = overlay_material
            else:
                preview_mesh.material_overlay = source_mesh.material_overlay
            preview_root.add_child(preview_mesh)

    for child in source.get_children():
        _copy_preview_meshes(
            child,
            source_transform,
            preview_root,
            surface_material,
            overlay_material
        )


func _get_authored_preview_material(source: Node, inherited_material: Material) -> Material:
    var authored_material := source.get("gold_material") as Material
    if authored_material == null:
        authored_material = source.get("gem_material") as Material
    return authored_material if authored_material != null else inherited_material


func _get_authored_preview_overlay(source: Node, inherited_material: Material) -> Material:
    var authored_material := source.get("edge_glow_material") as Material
    return authored_material if authored_material != null else inherited_material


func _connect_editor_filesystem_scan() -> void:
    var editor_filesystem := EditorInterface.get_resource_filesystem()
    if editor_filesystem == null:
        return
    if not editor_filesystem.filesystem_changed.is_connected(_on_editor_filesystem_changed):
        editor_filesystem.filesystem_changed.connect(_on_editor_filesystem_changed)


func _on_editor_filesystem_changed() -> void:
    is_catalog_cached = false
    _refresh_treasure_catalog()


func _sort_catalog_entries(first: Dictionary, second: Dictionary) -> bool:
    return String(first["display_name"]) < String(second["display_name"])
