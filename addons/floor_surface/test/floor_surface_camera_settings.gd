class_name FloorSurfaceCameraSettings
extends Resource

## Named perspective follow-camera arrangements for repeatable floor-surface evaluations.

enum CameraView {
	Overview,
	Close,
	Side,
}

@export_group("Overview")
## Camera position used for the broad default 2.5D view.
@export var overview_position := Vector3(8.5, 9.0, 10.5)
## World point observed by the broad default 2.5D view.
@export var overview_target := Vector3(0.0, 0.0, 0.0)
## Follow-camera distance used by the broad default 2.5D view.
@export_range(1.0, 100.0, 0.1, "or_greater", "suffix:m") var overview_size := 14.0

@export_group("Close")
## Camera position used to inspect movement and future surface seams more closely.
@export var close_position := Vector3(5.5, 5.5, 6.5)
## World point observed by the close inspection view.
@export var close_target := Vector3(0.0, 0.5, 0.0)
## Follow-camera distance used by the close inspection view.
@export_range(1.0, 100.0, 0.1, "or_greater", "suffix:m") var close_size := 9.0

@export_group("Side")
## Camera position reserved for later ledge and occlusion comparisons.
@export var side_position := Vector3(-10.0, 6.0, 0.0)
## World point observed by the side comparison view.
@export var side_target := Vector3(0.0, 0.5, 0.0)
## Follow-camera distance used by the side comparison view.
@export_range(1.0, 100.0, 0.1, "or_greater", "suffix:m") var side_size := 13.0


## Returns the stable display name for a configured camera arrangement.
func get_view_name(view: CameraView) -> String:
	match view:
		CameraView.Close:
			return "Close inspection"
		CameraView.Side:
			return "Side comparison"
		_:
			return "2.5D overview"


## Returns the world-space camera position for a configured arrangement.
func get_view_position(view: CameraView) -> Vector3:
	match view:
		CameraView.Close:
			return close_position
		CameraView.Side:
			return side_position
		_:
			return overview_position


## Returns the world-space look target for a configured arrangement.
func get_view_target(view: CameraView) -> Vector3:
	match view:
		CameraView.Close:
			return close_target
		CameraView.Side:
			return side_target
		_:
			return overview_target


## Returns the perspective follow distance for a configured arrangement.
func get_view_size(view: CameraView) -> float:
	match view:
		CameraView.Close:
			return close_size
		CameraView.Side:
			return side_size
		_:
			return overview_size
