extends Resource
class_name GDPlayerGaitSettings

## Distance-based cadence, contact windows and movement recovery shared by all players.

## Fraction of the authored stagger that must play before movement can interrupt it.
@export_range(0.0, 1.0, 0.01) var stagger_interrupt_fraction := 0.25

## Nominal travel per complete left/right cycle before the animation cadence cap is reached.
@export var cycle_distance := 0.4
## Maximum complete left/right cycles per second, independent of imported clip duration.
@export_range(0.1, 5.0, 0.1) var maximum_cycles_per_second := 2.5
## Small visual lift between foot contacts; collision and explicit jumping remain physics owned.
@export_range(0.0, 0.1, 0.001, "suffix:m") var transfer_height := 0.02
## World units travelled during a complete legacy walk cycle.
@export var legacy_cycle_distance := 2.5
## Normalized clip phase at which the left foot lands.
@export_range(0.0, 1.0) var left_contact_start := 0.38
## Normalized clip phase at which the left foot lifts.
@export_range(0.0, 1.0) var left_contact_end := 0.66
## Normalized clip phase at which the right foot lands.
@export_range(0.0, 1.0) var right_contact_start := 0.88
## Normalized clip phase at which the right foot lifts, across the clip loop.
@export_range(0.0, 1.0) var right_contact_end := 0.16
## Fraction of each foot contact eased in and out to preserve natural leg motion.
@export_range(0.0, 0.5, 0.01) var foot_plant_blend_fraction := 0.25
## Maximum animation phase advanced in a single foot-plant update.
@export_storage var maximum_phase_step := 0.04
## Motion below this world-space speed is treated as stationary.
@export_storage var stationary_speed := 0.01


func is_contact(phase: float, left: bool, stance_scale: float = 1.0) -> bool:
	var start := left_contact_start if left else right_contact_start
	var end := _contact_end(left, stance_scale)
	var duration := fposmod(end - start, 1.0)
	if duration <= 0.000001:
		return false
	return fposmod(phase - start, 1.0) < duration


## Zero slope at landing and lift-off avoids snapping between IK and authored motion.
func contact_weight(phase: float, left: bool, scale: float = 1.0) -> float:
	if not is_contact(phase, left, scale):
		return 0.0
	var blend := clampf(foot_plant_blend_fraction, 0.0, 0.5)
	if blend <= 0.0:
		return 1.0
	var start := left_contact_start if left else right_contact_start
	var duration := fposmod(_contact_end(left, scale) - start, 1.0)
	var progress := fposmod(phase - start, 1.0) / duration
	return smoothstep(0.0, blend, minf(progress, 1.0 - progress))


func playback_speed(distance: float, delta: float, clip_length: float, legacy: bool) -> float:
	if delta <= 0.0 or clip_length <= 0.0:
		return 0.0
	var stride := legacy_cycle_distance if legacy else cycle_distance
	var cycles_per_second := maxf(distance, 0.0) / (delta * maxf(stride, 0.001))
	return minf(cycles_per_second, maxf(maximum_cycles_per_second, 0.0)) * clip_length


## Faster travel shortens stance while animation cadence remains bounded.
## This limits planted travel to the authored stride without changing physics speed.
func contact_scale(horizontal_speed: float) -> float:
	var reference_speed := maxf(cycle_distance, 0.001) * maxf(maximum_cycles_per_second, 0.0)
	return clampf(reference_speed / maxf(horizontal_speed, 0.001), 0.0, 1.0)


func _contact_end(left: bool, scale: float) -> float:
	var start := left_contact_start if left else right_contact_start
	var end := left_contact_end if left else right_contact_end
	return fposmod(start + fposmod(end - start, 1.0) * clampf(scale, 0.0, 1.0), 1.0)


## Both feet leave their targets only between a push-off and the opposite landing.
func get_transfer_height(phase: float, stance_scale: float = 1.0) -> float:
	if is_contact(phase, true, stance_scale) or is_contact(phase, false, stance_scale):
		return 0.0
	var left_gap := _gap_progress(phase, _contact_end(true, stance_scale), right_contact_start)
	var right_gap := _gap_progress(phase, _contact_end(false, stance_scale), left_contact_start)
	var progress := left_gap if left_gap >= 0.0 else right_gap
	if progress < 0.0:
		return 0.0
	# Zero slope at takeoff and touchdown avoids a visible vertical snap.
	return maxf(transfer_height, 0.0) * pow(sin(PI * progress), 2.0)


func _gap_progress(phase: float, start: float, end: float) -> float:
	var width := fposmod(end - start, 1.0)
	var distance := fposmod(phase - start, 1.0)
	if width <= 0.0 or distance > width:
		return -1.0
	return distance / width
