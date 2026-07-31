extends Resource
class_name GDCharacterLookSettings


## Maximum sideways head turn that remains safe while a character keeps walking.
@export_range(0.0, 90.0, 1.0, "suffix:°") var maximum_head_turn_degrees := 60.0
## Maximum wandering head turn retained while moving at full pace.
@export_range(0.0, 45.0, 1.0, "suffix:°") var focused_head_turn_degrees := 8.0
## Distance where the player treats an enemy as an immediate threat worth tracking.
@export_range(0.5, 10.0, 0.1, "suffix:m") var enemy_attention_distance := 5.0
## Maximum forward angle to either side where a close enemy still holds attention.
@export_range(60.0, 90.0, 1.0, "suffix:°") var enemy_attention_half_arc_degrees := 90.0
## Radians per second used when a character glances away from or back to travel.
@export_range(0.1, 20.0, 0.1) var head_turn_speed := 6.0
## Seconds a stationary character studies something before returning to travel facing.
@export_range(0.0, 3.0, 0.05, "suffix:s") var glance_hold_seconds := 1.0
## Seconds a full-pace character holds a small wandering glance.
@export_range(0.0, 3.0, 0.05, "suffix:s") var focused_glance_hold_seconds := 0.25
## Shortest delay between stationary wandering glances.
@export_range(0.05, 10.0, 0.05, "suffix:s") var idle_glance_interval_min_seconds := 0.35
## Longest delay between stationary wandering glances.
@export_range(0.05, 10.0, 0.05, "suffix:s") var idle_glance_interval_max_seconds := 0.8
## Shortest delay between wandering glances at full pace.
@export_range(0.05, 10.0, 0.05, "suffix:s") var focused_glance_interval_min_seconds := 1.8
## Longest delay between wandering glances at full pace.
@export_range(0.05, 10.0, 0.05, "suffix:s") var focused_glance_interval_max_seconds := 3.0
## Curve power that preserves wider glances until a character approaches full pace.
@export_range(0.1, 5.0, 0.1) var movement_focus_exponent := 2.0
## Wandering strength above which a resting character scans continuously without waiting at centre.
@export_range(0.0, 1.0, 0.05) var continuous_idle_strength_threshold := 0.8
## Fraction of the total look angle contributed by the upper body for visual readability.
@export_range(0.0, 0.5, 0.05) var upper_body_turn_fraction := 0.2


## Returns one at rest and approaches zero as movement reaches full pace.
func get_wandering_strength(movement_focus_ratio: float) -> float:
    var focus_ratio := clampf(movement_focus_ratio, 0.0, 1.0)
    return 1.0 - pow(focus_ratio, movement_focus_exponent)


## Returns the movement-scaled limit used only for ambient wandering glances.
func get_wandering_head_turn_radians(movement_focus_ratio: float) -> float:
    return deg_to_rad(lerpf(
        focused_head_turn_degrees,
        maximum_head_turn_degrees,
        get_wandering_strength(movement_focus_ratio)
    ))


## Returns how long an ambient glance should linger at the current pace.
func get_wandering_hold_seconds(movement_focus_ratio: float) -> float:
    return lerpf(
        focused_glance_hold_seconds,
        glance_hold_seconds,
        get_wandering_strength(movement_focus_ratio)
    )


## Returns the shortest delay between wandering glances at the current pace.
func get_wandering_interval_min_seconds(movement_focus_ratio: float) -> float:
    return lerpf(
        focused_glance_interval_min_seconds,
        idle_glance_interval_min_seconds,
        get_wandering_strength(movement_focus_ratio)
    )


## Returns the longest delay between wandering glances at the current pace.
func get_wandering_interval_max_seconds(movement_focus_ratio: float) -> float:
    return lerpf(
        focused_glance_interval_max_seconds,
        idle_glance_interval_max_seconds,
        get_wandering_strength(movement_focus_ratio)
    )
