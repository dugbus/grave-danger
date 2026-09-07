@tool
class_name FloorElevationProfile
extends Resource

## Shared conversion between integer authored elevation and absolute world height.

enum TraversalClass {
	Flat,
	WalkableStep,
	NormalJump,
	UnencumberedOnlyJump,
	BlockedLedge,
	WalkableStepDown,
	Drop,
	TallDrop,
}

## World metres represented by one integer elevation unit.
@export_range(0.01, 10.0, 0.01, "or_greater", "suffix:m") var elevation_unit := 0.25
## Largest upward difference the prototype controller should walk without jumping.
@export_range(0, 1024, 1, "or_greater", "suffix: units") var walkable_step_units := 1
## Largest upward difference reachable by the normal prototype jump.
@export_range(1, 1024, 1, "or_greater", "suffix: units") var normal_jump_units := 2
## Largest upward difference reserved for the unencumbered prototype jump.
@export_range(1, 1024, 1, "or_greater", "suffix: units") var unencumbered_jump_units := 3
## Largest downward difference treated as an ordinary drop rather than a tall fall.
@export_range(1, 1024, 1, "or_greater", "suffix: units") var ordinary_drop_units := 3


## Converts integer authored elevation into absolute world-space Y.
func elevation_to_world(elevation: int) -> float:
	return float(elevation) * maxf(elevation_unit, 0.01)


## Classifies a directed local edge; absolute world elevation never affects the result.
func classify_edge(from_elevation: int, to_elevation: int) -> TraversalClass:
	var delta := to_elevation - from_elevation
	if delta == 0:
		return TraversalClass.Flat
	if delta < 0:
		if -delta <= walkable_step_units:
			return TraversalClass.WalkableStepDown
		return TraversalClass.Drop \
			if -delta <= ordinary_drop_units else TraversalClass.TallDrop
	if delta <= walkable_step_units:
		return TraversalClass.WalkableStep
	if delta <= normal_jump_units:
		return TraversalClass.NormalJump
	if delta <= unencumbered_jump_units:
		return TraversalClass.UnencumberedOnlyJump
	return TraversalClass.BlockedLedge


## Returns whether an upward edge is supported by the selected prototype movement mode.
func can_traverse_upward(
	from_elevation: int,
	to_elevation: int,
	allow_unencumbered_jump: bool
) -> bool:
	match classify_edge(from_elevation, to_elevation):
		TraversalClass.Flat, TraversalClass.WalkableStep, TraversalClass.NormalJump:
			return true
		TraversalClass.UnencumberedOnlyJump:
			return allow_unencumbered_jump
		_:
			return false


## Returns a stable editor and debug label for a directed local edge classification.
func get_traversal_name(traversal: TraversalClass) -> String:
	match traversal:
		TraversalClass.WalkableStep:
			return "Walkable step"
		TraversalClass.NormalJump:
			return "Normal jump"
		TraversalClass.UnencumberedOnlyJump:
			return "Unencumbered-only jump"
		TraversalClass.BlockedLedge:
			return "Blocked ledge"
		TraversalClass.WalkableStepDown:
			return "Walkable step down"
		TraversalClass.Drop:
			return "Drop"
		TraversalClass.TallDrop:
			return "Tall drop"
		_:
			return "Flat"


## Reports when the standalone controller cannot physically meet authored thresholds.
func validate_controller_limits(
	maximum_step_height: float,
	normal_jump_height: float,
	unencumbered_jump_height: float
) -> Array[String]:
	var errors: Array[String] = []
	if maximum_step_height + 0.001 < elevation_to_world(walkable_step_units):
		errors.append("Controller step height is below the walkable-step threshold.")
	if normal_jump_height + 0.001 < elevation_to_world(normal_jump_units):
		errors.append("Controller normal jump is below the normal-jump threshold.")
	if unencumbered_jump_height + 0.001 < elevation_to_world(unencumbered_jump_units):
		errors.append("Controller unencumbered jump is below its reserved threshold.")
	return errors


## Reports configuration problems without silently replacing authored tuning.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if elevation_unit <= 0.0:
		errors.append("Elevation unit must be greater than zero metres.")
	if walkable_step_units < 0:
		errors.append("Walkable step units cannot be negative.")
	if normal_jump_units <= walkable_step_units:
		errors.append("Normal jump units must be greater than walkable step units.")
	if unencumbered_jump_units <= normal_jump_units:
		errors.append("Unencumbered jump units must be greater than normal jump units.")
	if ordinary_drop_units < 1:
		errors.append("Ordinary drop units must be at least one.")
	return errors
