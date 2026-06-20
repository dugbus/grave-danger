extends Resource
class_name FollowCameraProfile

@export var camera_offset := Vector3(0.0, 5.2, 5.6)
@export_range(-1.0, 89.0, 0.5) var view_elevation_degrees := -1.0
@export var look_ahead := Vector3(0.0, 0.55, 0.0)
@export_range(0.0, 24.0, 0.25) var forward_look_ahead := 0.0
@export_range(0.1, 20.0, 0.1) var follow_lag := 4.0

@export_range(0.1, 120.0, 0.1) var zoom_distance := 18.0
@export_range(0.1, 120.0, 0.1) var min_zoom_distance := 4.2
@export_range(0.1, 120.0, 0.1) var max_zoom_distance := 18.0
@export_range(0.1, 40.0, 0.1) var manual_zoom_speed := 8.0

@export_range(10.0, 90.0, 0.5) var field_of_view := 34.0
@export_range(1.0, 3.0, 0.05) var boundary_padding := 1.25
@export_range(0.1, 20.0, 0.1) var boundary_zoom_lag := 3.0
@export_range(0.1, 200.0, 0.1) var max_boundary_zoom_distance := 80.0
@export_range(4, 24, 1) var boundary_fit_iterations := 12

@export_range(0.0, 8.0, 0.05) var rotation_speed := 1.8
@export_range(0.0, 1.0, 0.01) var camera_input_deadzone := 0.35

@export_range(0.1, 20.0, 0.1) var death_zoom_distance := 2.4
@export var death_look_offset := Vector3(0.0, 0.38, 0.0)
@export_range(0.1, 20.0, 0.1) var death_zoom_lag := 4.5
