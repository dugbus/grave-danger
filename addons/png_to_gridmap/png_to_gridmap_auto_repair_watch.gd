@tool
extends RefCounted
class_name PNGToGridMapAutoRepairWatch

## Debounces GridMap painting and mapping edits into one automatic repair pass.

const CHECK_INTERVAL_MILLISECONDS := 200
const DEBOUNCE_MILLISECONDS := 600

var observed_grid_map_id := 0
var observed_grid_map_fingerprint := 0
var observed_configuration_fingerprint := 0
var next_check_milliseconds := 0
var repair_due_milliseconds := 0


## Clears the selected GridMap and configuration observation state.
func reset() -> void:
	observed_grid_map_id = 0
	observed_grid_map_fingerprint = 0
	observed_configuration_fingerprint = 0
	next_check_milliseconds = 0
	repair_due_milliseconds = 0


## Reports when cell or mapping changes have remained stable for the debounce interval.
func should_repair(
	grid_map: GridMap,
	now_milliseconds: int,
	configuration_fingerprint: int = 0
) -> bool:
	if grid_map == null:
		reset()
		return false
	if now_milliseconds < next_check_milliseconds:
		return false
	next_check_milliseconds = now_milliseconds + CHECK_INTERVAL_MILLISECONDS

	var instance_id := int(grid_map.get_instance_id())
	var current_fingerprint := fingerprint(grid_map)
	if instance_id != observed_grid_map_id:
		observed_grid_map_id = instance_id
		observed_grid_map_fingerprint = current_fingerprint
		observed_configuration_fingerprint = configuration_fingerprint
		repair_due_milliseconds = 0
		return false
	if current_fingerprint != observed_grid_map_fingerprint \
			or configuration_fingerprint != observed_configuration_fingerprint:
		observed_grid_map_fingerprint = current_fingerprint
		observed_configuration_fingerprint = configuration_fingerprint
		repair_due_milliseconds = now_milliseconds + DEBOUNCE_MILLISECONDS
	if repair_due_milliseconds == 0 or now_milliseconds < repair_due_milliseconds:
		return false
	repair_due_milliseconds = 0
	return true


## Accepts the repaired state so its own cell changes do not schedule another pass.
func accept_repair(grid_map: GridMap, configuration_fingerprint: int = 0) -> void:
	observed_grid_map_fingerprint = fingerprint(grid_map)
	observed_configuration_fingerprint = configuration_fingerprint


## Summarises every placed item and orientation in deterministic cell order.
func fingerprint(grid_map: GridMap) -> int:
	var cells := grid_map.get_used_cells()
	cells.sort()
	var current_fingerprint := cells.size()
	for cell: Vector3i in cells:
		current_fingerprint = hash([
			current_fingerprint,
			cell,
			grid_map.get_cell_item(cell),
			grid_map.get_cell_item_orientation(cell),
		])
	return current_fingerprint
