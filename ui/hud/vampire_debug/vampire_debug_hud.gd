extends CanvasLayer
class_name GDVampireDebugHud


## Vampire whose live AI state is displayed by this development HUD.
@export var vampire_path: NodePath = ^"../Vampire"
## Authored HUD label updated with the Vampire state and confirmed sight result.
@export var state_label_path: NodePath = ^"Screen/StateLabel"

@onready var state_label := get_node_or_null(state_label_path) as Label

var vampire: GDVampire
var hunt: Node
var navigation: Node


func _ready() -> void:
    if state_label != null:
        GDGameFont.apply_to_label(state_label)
    _resolve_vampire()
    _refresh_text()


func _process(_delta: float) -> void:
    if not is_instance_valid(vampire):
        _resolve_vampire()
    _refresh_text()


func _resolve_vampire() -> void:
    vampire = get_node_or_null(vampire_path) as GDVampire
    hunt = vampire.get_node_or_null("VampireHunt") if vampire != null else null
    navigation = vampire.get_node_or_null("VampireNavigation") if vampire != null else null


func _refresh_text() -> void:
    if state_label == null:
        return
    if vampire == null:
        state_label.text = "VAMPIRE  State: Missing  LOS: NO"
        return

    var state := vampire.get_vampire_state()
    var state_names := GDVampire.VampireState.keys()
    var state_name := "Unknown"
    if state >= 0 and state < state_names.size():
        state_name = String(state_names[state])
    var has_line_of_sight: bool = hunt != null and bool(hunt.call("is_player_visible"))
    var target_name := _get_target_name(state)
    var route_progress := "0/0"
    if navigation != null:
        var route_points := navigation.call("get_route_points") as Array[Vector3]
        route_progress = "%d/%d" % [int(navigation.get("route_index")), route_points.size()]
    state_label.text = "VAMPIRE  State: %s  LOS: %s  Target: %s  Route: %s" % [
        state_name,
        "YES" if has_line_of_sight else "NO",
        target_name,
        route_progress,
    ]


func _get_target_name(state: GDVampire.VampireState) -> String:
    match state:
        GDVampire.VampireState.Hunting:
            return "Sound"
        GDVampire.VampireState.ChasingPlayer:
            return "Player"
        GDVampire.VampireState.SearchingRoute:
            return "Search"
        GDVampire.VampireState.PursuingLastSeen:
            return "Last Seen"
        GDVampire.VampireState.ScanningJunction:
            return "Junction Scan"
        _:
            return "None"
