extends Resource
class_name GDCarriedItem


## Stable identifier used by gameplay code, for example &"gold_coin" or &"key".
@export var item_type: StringName
## Label for debugging and future UI.
@export var display_name := ""
## Maximum copies of this item the player can carry.
@export_range(1, 999, 1) var max_count := 1
## Carry capacity consumed by one copy of this item.
@export_range(0.0, 999.0, 0.1) var weight := 1.0
## Lower values drop first when the player sheds carried items.
@export var drop_order := 100
## Scene spawned back into the world when this item is dropped.
@export_file("*.tscn") var world_scene_path := ""
## If enabled, pickups only succeed while the item is roughly in front of the player.
@export var require_facing_for_pickup := true
## Sound played by the inventory when this item is picked up.
@export var pickup_sound: AudioStream
## Sound played by the inventory when this item is dropped.
@export var drop_sound: AudioStream
