extends Resource

## Baseline amount of dust in the air. Small values reveal lights without veiling the whole room.
@export_range(0.0, 0.02, 0.0005) var density := 0.004:
	set(value):
		if density == value:
			return
		density = value
		emit_changed()
## Light-scattering colour of the air; near-white keeps each light's own colour visible.
@export var albedo := Color(0.95, 0.97, 1.0):
	set(value):
		if albedo == value:
			return
		albedo = value
		emit_changed()
## World-space noise frequency. Smaller values make broad, soft variations through the room.
@export_range(0.05, 1.0, 0.01) var noise_scale := 0.32:
	set(value):
		if noise_scale == value:
			return
		noise_scale = value
		emit_changed()
## Density variation around the baseline. Keep this low for haze rather than visible clouds.
@export_range(0.0, 0.8, 0.01) var noise_strength := 0.28:
	set(value):
		if noise_strength == value:
			return
		noise_strength = value
		emit_changed()
## Slow movement of the 3D density field in metres per second. Zero keeps the air pattern stationary.
@export var drift_velocity := Vector3(0.018, 0.006, 0.012):
	set(value):
		if drift_velocity == value:
			return
		drift_velocity = value
		emit_changed()
## Distance over which the camera computes the mist; a short indoor range keeps light detail sharper.
@export_range(8.0, 80.0, 1.0, "suffix:m") var fog_length := 32.0:
	set(value):
		if fog_length == value:
			return
		fog_length = value
		emit_changed()
## Slight forward scattering of light. Values near zero keep the haze readable from different angles.
@export_range(-0.5, 0.5, 0.05) var anisotropy := 0.2:
	set(value):
		if anisotropy == value:
			return
		anisotropy = value
		emit_changed()
## Blend with previous fog frames to smooth the volume and limit moving-light trails; 0 disables reprojection.
@export_range(0.0, 0.9, 0.05) var temporal_blend := 0.6:
	set(value):
		if temporal_blend == value:
			return
		temporal_blend = value
		emit_changed()
