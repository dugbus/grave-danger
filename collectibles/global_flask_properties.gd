extends Resource
class_name GDGlobalFlaskProperties

@export_group("Health Flask")
## Seconds over which the health flask restores health after pickup.
## Higher values make the recovery feel slower and safer to tune than an instant heal.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var health_heal_duration := 2.0
## Percent of the player's maximum health restored by one health flask.
## For example, 25 restores one quarter of max health over health_heal_duration.
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:%") var health_heal_percent_of_max := 25.0

@export_group("Bigger Sack")
## Extra inventory capacity granted while the bigger sack flask effect is active.
## This is added on top of the player's normal carry limit.
@export_range(1, 999, 1, "or_greater") var bigger_sack_extra_inventory_space := 25
## Seconds the bigger sack flask message stays visible on the HUD after the flask is collected.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var bigger_sack_display_seconds := 5.0

@export_group("Breathing Space")
## Percent increase applied to the kill boundary's current size while the breathing space flask effect is active.
@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var breathing_space_expansion_percent := 25.0
## Seconds the expanded boundary is held before it returns to its normal pressure.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var breathing_space_seconds := 8.0
## Seconds used to ease the boundary into and out of the expanded breathing space size.
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:s") var breathing_space_transition_seconds := 1.0

@export_group("No Boundary")
## Seconds the boundary takes to sink out of view when the no boundary flask starts.
@export_range(0.05, 5.0, 0.05, "suffix:s") var no_boundary_sink_seconds := 1.0
## World-space distance the boundary moves downward while hidden by the no boundary flask.
@export_range(0.1, 20.0, 0.1, "suffix:m") var no_boundary_sink_distance := 3.0
## Seconds the no boundary flask message stays visible on the HUD after the flask is collected.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var no_boundary_display_seconds := 5.0

@export_group("Pause Boundary")
## Seconds the kill boundary's movement and pressure are paused after collecting a pause boundary flask.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var pause_boundary_seconds := 5.0

@export_group("Pickup Radius")
## Percent increase applied to the player's pickup radius while the pickup radius flask effect is active.
@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var pickup_radius_percent := 50.0
## Seconds the boosted pickup radius remains active after collecting the flask.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var pickup_radius_seconds := 5.0

@export_group("Poison")
## Total damage dealt by a poison flask effect across poison_duration.
## This drains health gradually rather than all at once.
@export_range(0.1, 999.0, 0.1, "or_greater") var poison_damage_points := 25.0
## Seconds over which poison_damage_points is applied to the affected player.
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var poison_duration := 6.0
