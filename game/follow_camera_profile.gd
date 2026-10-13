extends Resource
class_name GDFollowCameraProfile

## Base 2.5D offset before rotation and zoom scaling are applied.
@export var camera_offset := Vector3(0.0, 5.2, 5.6)
## Optional camera elevation angle above the ground plane. Negative uses camera_offset.
@export_range(-1.0, 89.0, 0.5) var view_elevation_degrees := -1.0
## Offset added to the followed position before the camera looks at it.
@export var look_ahead := Vector3(0.0, 0.55, 0.0)
## Extra distance to look past the target in the camera's forward direction.
@export_range(0.0, 24.0, 0.25) var forward_look_ahead := 0.0
## Responsiveness of camera follow smoothing; higher values track faster.
@export_range(0.1, 20.0, 0.1) var follow_lag := 4.0

## Current camera distance along the offset direction.
@export_range(0.1, 120.0, 0.1) var zoom_distance := 18.0
## Closest manual or boundary-driven camera distance.
@export_range(0.1, 120.0, 0.1) var min_zoom_distance := 4.2
## Farthest manual camera distance when no boundary controls zoom.
@export_range(0.1, 120.0, 0.1) var max_zoom_distance := 18.0
## Manual zoom speed in distance units per second.
@export_range(0.1, 40.0, 0.1) var manual_zoom_speed := 8.0

## Camera field of view, in degrees.
@export_range(10.0, 90.0, 0.5) var field_of_view := 34.0
## Multiplier applied to kill-boundary bounds before fitting them on screen.
@export_range(1.0, 3.0, 0.05) var boundary_padding := 1.25
## Responsiveness of boundary auto-zoom; higher values settle faster.
@export_range(0.1, 20.0, 0.1) var boundary_zoom_lag := 3.0
## Farthest distance allowed while trying to fit the kill boundary.
## Keep this near max_zoom_distance so large flames do not force excessive zoom-out.
@export_range(0.1, 200.0, 0.1) var max_boundary_zoom_distance := 18.0
## Binary-search iterations used to solve the boundary fit distance.
@export_storage var boundary_fit_iterations := 12

## Camera yaw rotation speed in radians per second from right-stick input.
@export_range(0.0, 8.0, 0.05) var rotation_speed := 1.8
## Input magnitude ignored for camera rotation and manual zoom.
@export_range(0.0, 1.0, 0.01) var camera_input_deadzone := 0.35

## Camera distance used while focusing on a dead player.
@export_range(0.1, 20.0, 0.1) var death_zoom_distance := 2.4
## Focus offset from the dead player's origin during the death close-up.
@export var death_look_offset := Vector3(0.0, 0.38, 0.0)
## Responsiveness of death camera zoom and focus smoothing.
@export_range(0.1, 20.0, 0.1) var death_zoom_lag := 4.5
