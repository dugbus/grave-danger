extends Resource
class_name GDGlobalFlaskProperties


@export_group("Health Flask")
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var health_heal_duration := 2.0
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:%") var health_heal_percent_of_max := 25.0

@export_group("Bigger Sack")
@export_range(1, 999, 1, "or_greater") var bigger_sack_extra_inventory_space := 25
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var bigger_sack_display_seconds := 5.0

@export_group("Breathing Space")
@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var breathing_space_expansion_percent := 25.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var breathing_space_seconds := 8.0
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:s") var breathing_space_transition_seconds := 1.0

@export_group("No Boundary")
@export_range(0.05, 5.0, 0.05, "suffix:s") var no_boundary_sink_seconds := 1.0
@export_range(0.1, 20.0, 0.1, "suffix:m") var no_boundary_sink_distance := 3.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var no_boundary_display_seconds := 5.0

@export_group("Pause Boundary")
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var pause_boundary_seconds := 5.0

@export_group("Pickup Radius")
@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var pickup_radius_percent := 50.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var pickup_radius_seconds := 5.0

@export_group("Poison")
@export_range(0.1, 999.0, 0.1, "or_greater") var poison_damage_points := 25.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var poison_duration := 6.0
