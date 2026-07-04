extends Resource
class_name GDMinimapViewSettings


## Fraction of the game viewport width used by the minimap panel.
@export_range(0.05, 0.5, 0.01) var viewport_width_fraction := 0.2

## Minimum on-screen minimap panel width in pixels.
@export_range(96.0, 640.0, 1.0) var minimum_panel_width := 256.0

## Width-to-height ratio used by the minimap panel.
@export_range(0.5, 2.0, 0.05) var panel_aspect_ratio := 1.0

## Distance between the minimap panel and the viewport edges.
@export_range(0.0, 80.0, 1.0) var screen_margin := 20.0

## Padding between the minimap frame and rendered level view.
@export_range(0.0, 32.0, 1.0) var content_padding := 8.0

## Orthographic world size used when no level or boundary bounds are available.
@export_range(1.0, 300.0, 0.5) var fallback_orthographic_size := 18.0

## Height of the top-down minimap camera above the level focus.
@export_range(10.0, 600.0, 1.0) var top_down_camera_height := 220.0

## Background color used only by the minimap camera environment.
@export var background_color := Color(0.035, 0.04, 0.05, 1.0)

## Ambient light color used only by the minimap camera environment.
@export var ambient_light_color := Color(0.82, 0.86, 1.0, 1.0)

## Ambient light energy used only by the minimap camera environment.
@export_range(0.0, 8.0, 0.05) var ambient_light_energy := 1.6
