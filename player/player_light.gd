extends OmniLight3D

@export var base_energy := 2.5
@export var dip_amount := 1.2      # how far below base it can drop
@export var peak_amount := 0.5     # how far above base it can rise
@export var flicker_speed := 6.0
@export var noise_fast: NoiseTexture3D
@export var noise_slow: NoiseTexture3D

var time_passed := 0.0

func _process(delta: float) -> void:
	time_passed += delta

	# Fast flutter — the constant quick flicker of flame
	var fast := noise_fast.noise.get_noise_1d(time_passed * flicker_speed)

	# Slow swell — occasional bigger dips / surges
	var slow := noise_slow.noise.get_noise_1d(time_passed * 1.2)

	# Weighted blend: slow drives the big dips, fast adds texture
	var combined := fast * 0.35 + slow * 0.65

	# Asymmetric remap: torch dips more than it peaks
	var flicker: float
	if combined < 0.0:
		flicker = combined * dip_amount   # full dip range
	else:
		flicker = combined * peak_amount  # reduced peak range

	light_energy = base_energy + flicker

	# Subtle color shift: dimmer = deeper orange, brighter = yellow
	var t := inverse_lerp(-dip_amount, peak_amount, flicker)
	light_color = Color(1.0, 0.45, 0.1).lerp(Color(1.0, 0.75, 0.3), t)
