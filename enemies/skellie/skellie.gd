extends Node3D

## Adapts skellie's imported clips to the existing skeleton's presentation contract.
## Patrol, spawning, collisions, damage, and death timing belong to the skeleton carrier.

## Editable visual fall used until the model supplies an authored death clip.
@export var death_animation: Animation

@onready var animation_player := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	# Keep the imported library untouched, including the attack and static *real clips.
	# Each instance receives its own aliases so preparing a model cannot affect another.
	var library := animation_player.get_animation_library(&"").duplicate() as AnimationLibrary
	library.add_animation(&"idle", library.get_animation(&"rest"))
	if death_animation != null:
		library.add_animation(&"die", death_animation)
	animation_player.remove_animation_library(&"")
	animation_player.add_animation_library(&"", library)
