extends Node
class_name GDVampireLayoutKnowledge


## Strategic memory of authored maze landmarks used to predict the player's next objective.

enum LandmarkKind {
	Unknown,
	TreasurePile,
	SilverKey,
	GoldKey,
	Coffin,
	LockedDoor,
	EndGate,
}

const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const LANDMARK_PRIORITY_SCORE := 100000
const DIRECTION_ALIGNMENT_SCORE := 10000
const ROUTE_DISTANCE_SCORE := 100
const INVESTIGATION_PENALTY := 10000000

var landmarks: Array[Dictionary] = []
var investigation_counts: Dictionary = {}
var last_evidence_kind := LandmarkKind.Unknown
var selection_count := 0


## Replaces the vampire's complete knowledge of strategic level landmarks.
func configure(layout_landmarks: Array[Dictionary]) -> void:
	landmarks.clear()
	reset_runtime_state()
	for landmark_value in layout_landmarks:
		var position := landmark_value.get("position", Vector3.ZERO) as Vector3
		var kind := _parse_landmark_kind(
			landmark_value.get("kind", &"") as StringName
		)
		if kind == LandmarkKind.Unknown:
			continue
		var landmark_id := landmark_value.get("id", &"") as StringName
		if landmark_id == &"":
			landmark_id = StringName(
				"%d_%d_%d" % [kind, roundi(position.x * 10.0), roundi(position.z * 10.0)]
			)
		landmarks.append({
			"id": landmark_id,
			"kind": kind,
			"position": position,
		})
	landmarks.sort_custom(_sort_landmark)


## Clears investigation evidence while preserving the authored landmark catalogue.
func reset_runtime_state() -> void:
	investigation_counts.clear()
	last_evidence_kind = LandmarkKind.Unknown
	selection_count = 0


## Records which known objective produced a sound without reading the player's live position.
func record_noise_evidence(noise_position: Vector3, maximum_match_distance: float) -> void:
	var maximum_distance_squared := pow(maxf(maximum_match_distance, 0.0), 2.0)
	var nearest_distance_squared := maximum_distance_squared
	var nearest_landmark: Dictionary = {}
	for landmark in landmarks:
		var landmark_position := landmark["position"] as Vector3
		var distance_squared := Vector2(
			landmark_position.x - noise_position.x,
			landmark_position.z - noise_position.z
		).length_squared()
		if distance_squared > nearest_distance_squared \
				or (not nearest_landmark.is_empty() \
				and distance_squared >= nearest_distance_squared):
			continue
		nearest_distance_squared = distance_squared
		nearest_landmark = landmark
	if nearest_landmark.is_empty():
		return

	var landmark_id := nearest_landmark["id"] as StringName
	last_evidence_kind = int(nearest_landmark["kind"]) as LandmarkKind
	investigation_counts[landmark_id] = maxi(
		int(investigation_counts.get(landmark_id, 0)),
		1
	)


## Clears landmark-specific assumptions when bats or another location-only clue makes the sound.
func record_location_only_evidence() -> void:
	last_evidence_kind = LandmarkKind.Unknown


## Selects a known objective the player can plausibly reach after the latest sound.
func select_likely_destination(
		evidence_position: Vector3,
		maximum_route_distance: float,
		preferred_direction: Vector3,
		minimum_direction_alignment: float,
		navigation: Node,
		evidence_relevance: float = 1.0,
		position_is_ruled_out: Callable = Callable()
) -> Dictionary:
	if landmarks.is_empty() or navigation == null:
		return {}

	var relevance := clampf(evidence_relevance, 0.0, 1.0)
	var horizontal_preference := preferred_direction
	horizontal_preference.y = 0.0
	horizontal_preference = horizontal_preference.normalized()
	var effective_minimum_alignment := lerpf(
		-1.0,
		minimum_direction_alignment,
		relevance
	)
	var best_landmark: Dictionary = {}
	var best_score := -2147483648
	for landmark in landmarks:
		var landmark_position := landmark["position"] as Vector3
		if position_is_ruled_out.is_valid() \
				and bool(position_is_ruled_out.call(landmark_position)):
			continue
		var route_distance := float(navigation.get_path_distance(
			evidence_position,
			landmark_position
		))
		if route_distance <= 0.001 or route_distance > maximum_route_distance:
			continue

		var alignment := 0.0
		if not horizontal_preference.is_zero_approx():
			var departure_direction := navigation.get_path_departure_direction(
				evidence_position,
				landmark_position
			) as Vector3
			alignment = departure_direction.dot(horizontal_preference)
			if alignment < effective_minimum_alignment:
				continue

		var landmark_id := landmark["id"] as StringName
		var landmark_kind := int(landmark["kind"]) as LandmarkKind
		var score := _get_landmark_priority(
			landmark_kind,
			relevance
		) * LANDMARK_PRIORITY_SCORE \
			+ roundi((alignment + 1.0) * DIRECTION_ALIGNMENT_SCORE * relevance) \
			- roundi(route_distance * ROUTE_DISTANCE_SCORE) \
			- int(investigation_counts.get(landmark_id, 0)) * INVESTIGATION_PENALTY \
			+ posmod(
				DETERMINISTIC_SEED.from_text(String(landmark_id)),
				ROUTE_DISTANCE_SCORE
			)
		if score <= best_score:
			continue
		best_score = score
		best_landmark = landmark

	if best_landmark.is_empty():
		return {}
	var selected_id := best_landmark["id"] as StringName
	investigation_counts[selected_id] = int(investigation_counts.get(selected_id, 0)) + 1
	selection_count += 1
	return best_landmark.duplicate(true)


func _parse_landmark_kind(kind_name: StringName) -> LandmarkKind:
	match kind_name:
		&"treasure_pile":
			return LandmarkKind.TreasurePile
		&"silver_key":
			return LandmarkKind.SilverKey
		&"gold_key":
			return LandmarkKind.GoldKey
		&"coffin":
			return LandmarkKind.Coffin
		&"locked_door":
			return LandmarkKind.LockedDoor
		&"end_gate":
			return LandmarkKind.EndGate
		_:
			return LandmarkKind.Unknown


func _sort_landmark(first: Dictionary, second: Dictionary) -> bool:
	var first_id := String(first.get("id", &""))
	var second_id := String(second.get("id", &""))
	if first_id != second_id:
		return first_id < second_id
	var first_position := first.get("position", Vector3.ZERO) as Vector3
	var second_position := second.get("position", Vector3.ZERO) as Vector3
	if first_position.x != second_position.x:
		return first_position.x < second_position.x
	if first_position.z != second_position.z:
		return first_position.z < second_position.z
	return first_position.y < second_position.y


func _get_landmark_priority(kind: LandmarkKind, evidence_relevance: float) -> int:
	return roundi(lerpf(
		float(_get_default_landmark_priority(kind)),
		float(_get_contextual_landmark_priority(kind)),
		clampf(evidence_relevance, 0.0, 1.0)
	))


func _get_contextual_landmark_priority(kind: LandmarkKind) -> int:
	if last_evidence_kind == LandmarkKind.GoldKey:
		return 120 if kind == LandmarkKind.EndGate else 10
	if last_evidence_kind == LandmarkKind.SilverKey:
		return 120 if kind == LandmarkKind.LockedDoor else 20
	if last_evidence_kind == LandmarkKind.TreasurePile:
		match kind:
			LandmarkKind.GoldKey:
				return 110
			LandmarkKind.SilverKey:
				return 100
			LandmarkKind.TreasurePile:
				return 80
			LandmarkKind.Coffin:
				return 50
	if last_evidence_kind == LandmarkKind.Coffin:
		if kind in [LandmarkKind.GoldKey, LandmarkKind.SilverKey]:
			return 110
		if kind == LandmarkKind.TreasurePile:
			return 90

	return _get_default_landmark_priority(kind)


func _get_default_landmark_priority(kind: LandmarkKind) -> int:
	match kind:
		LandmarkKind.GoldKey:
			return 100
		LandmarkKind.SilverKey:
			return 95
		LandmarkKind.TreasurePile:
			return 80
		LandmarkKind.Coffin:
			return 50
		LandmarkKind.LockedDoor:
			return 30
		LandmarkKind.EndGate:
			return 20
		_:
			return 0
