class_name GDBloodSplatterDecal
extends Node3D
## Reusable blood mark that projects onto either environment or character geometry.


enum SplatterTarget {
    Environment,
    Player,
}

const ENVIRONMENT_VISUAL_LAYER := 1
const PLAYER_VISUAL_LAYER := 2
const ENVIRONMENT_PROJECTION_DEPTH := 0.28
const PLAYER_PROJECTION_DEPTH := 0.22

## Geometry category that receives this decal without staining unrelated surfaces.
@export var target := SplatterTarget.Environment
## Visible width and depth of the irregular blood mark.
@export_range(0.05, 2.0, 0.01, "suffix:m") var diameter := 0.65
## Distance through which the decal projects onto the receiving surface.
@export_range(0.01, 0.5, 0.01, "suffix:m") var projection_depth := 0.28

@onready var decal := $Decal as Decal
@onready var surface_mark := $SurfaceMark as MeshInstance3D
@onready var impact_blood := $ImpactBlood as GPUParticles3D


func _ready() -> void:
    _apply_configuration()


## Retargets and resizes a splatter after it has been attached to a surface node.
func configure_surface(new_target: SplatterTarget, new_diameter: float) -> void:
    target = new_target
    diameter = maxf(new_diameter, 0.05)
    if is_node_ready():
        _apply_configuration()


func _apply_configuration() -> void:
    var is_player_target := target == SplatterTarget.Player
    decal.cull_mask = PLAYER_VISUAL_LAYER if is_player_target else ENVIRONMENT_VISUAL_LAYER
    projection_depth = PLAYER_PROJECTION_DEPTH \
        if is_player_target else ENVIRONMENT_PROJECTION_DEPTH
    decal.size = Vector3(diameter, maxf(projection_depth, 0.01), diameter)
    surface_mark.scale = Vector3(diameter, 1.0, diameter)
    impact_blood.amount = 8 if is_player_target else 18
    impact_blood.global_transform = global_transform
    impact_blood.emitting = true
    impact_blood.restart()
