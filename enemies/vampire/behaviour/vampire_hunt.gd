extends Node
class_name GDVampireHunt


enum SearchPlan {
	StrategicRoute,
	NoiseRadius,
	LastSeenDirection,
}

## The only evidence allowed to update the Vampire's knowledge of the player.
## Entrance supplies the authored spawn location, Noise supplies only its event position,
## and Sight permits reading the live player position only after current perception confirms it.
## Landmark sounds still use Noise, but may update which authored landmark was disturbed.
enum AwarenessSource {
	None,
	Entrance,
	Noise,
	Sight,
}

var body: CharacterBody3D
var navigation: Node
var senses: Node
var layout_knowledge: Node
var player: Node3D
var end_gate: Node3D
var settings: Resource
var noise_target_active := false
var player_was_visible := false
var player_is_visible := false
var searching := false
var pursuing_last_seen_position := false
var junction_scan_active := false
var junction_scan_directions: Array[Vector3] = []
var junction_scan_direction_index := 0
var junction_scan_elapsed := 0.0
var search_plan_after_scan := SearchPlan.StrategicRoute
var active_search_plan := SearchPlan.StrategicRoute
var sight_loss_elapsed := 0.0
var last_chase_target := Vector3.ZERO
var last_chase_observed_player_position := Vector3.ZERO
var has_chase_target := false
var noise_search_rng := RandomNumberGenerator.new()
var last_noise_position := Vector3.ZERO
var noise_elapsed_seconds := 0.0
var has_noise_position := false
var noise_path_direction_hint := Vector3.ZERO
var player_location_unknown_elapsed := 0.0
var last_confirmed_player_position := Vector3.ZERO
var previous_visible_player_position := Vector3.ZERO
var last_seen_player_velocity := Vector3.ZERO
var prediction_search_direction := Vector3.ZERO
var has_visible_observation := false
var prediction_followup_searches_remaining := 0
var awareness_source := AwarenessSource.None


func configure(
		vampire_body: CharacterBody3D,
		vampire_navigation: Node,
		vampire_senses: Node,
		vampire_layout_knowledge: Node,
		target_player: Node3D,
		level_end_gate: Node3D,
		vampire_settings: Resource
) -> void:
	if senses != null \
			and senses.has_signal(&"player_visibility_changed") \
			and senses.player_visibility_changed.is_connected(
				_on_player_visibility_changed
			):
		senses.player_visibility_changed.disconnect(_on_player_visibility_changed)
	body = vampire_body
	navigation = vampire_navigation
	senses = vampire_senses
	layout_knowledge = vampire_layout_knowledge
	player = target_player
	end_gate = level_end_gate
	settings = vampire_settings
	reset_runtime_state()
	if senses != null:
		if senses.has_signal(&"player_visibility_changed") \
				and not senses.player_visibility_changed.is_connected(
					_on_player_visibility_changed
				):
			senses.player_visibility_changed.connect(_on_player_visibility_changed)
		senses.configure(player, settings)


## Clears all evidence, timers, velocity history, RNG progress, and active search modes.
func reset_runtime_state() -> void:
	noise_target_active = false
	player_was_visible = false
	player_is_visible = false
	searching = false
	pursuing_last_seen_position = false
	_cancel_junction_scan()
	search_plan_after_scan = SearchPlan.StrategicRoute
	active_search_plan = SearchPlan.StrategicRoute
	sight_loss_elapsed = 0.0
	last_chase_target = Vector3.ZERO
	last_chase_observed_player_position = Vector3.ZERO
	has_chase_target = false
	last_noise_position = Vector3.ZERO
	noise_elapsed_seconds = 0.0
	has_noise_position = false
	noise_path_direction_hint = Vector3.ZERO
	player_location_unknown_elapsed = 0.0
	last_confirmed_player_position = Vector3.ZERO
	previous_visible_player_position = Vector3.ZERO
	last_seen_player_velocity = Vector3.ZERO
	prediction_search_direction = Vector3.ZERO
	has_visible_observation = false
	prediction_followup_searches_remaining = 0
	awareness_source = AwarenessSource.None
	if settings != null:
		noise_search_rng.seed = int(settings.noise_search_seed)
	if navigation != null:
		navigation.reset_runtime_state()
	if layout_knowledge != null:
		layout_knowledge.reset_runtime_state()


func update_hunt(delta: float) -> void:
	if body == null or navigation == null or senses == null or player == null:
		return
	if has_noise_position:
		noise_elapsed_seconds += maxf(delta, 0.0)

	player_is_visible = senses.can_see_player()
	if player_is_visible:
		var confirmed_player_position := player.global_position
		navigation.update_visible_player_position(
			confirmed_player_position,
			bool(senses.is_player_direct_path_clear())
		)
		_enter_visible_chase(delta, confirmed_player_position)
		return
	navigation.clear_visible_player_position()

	player_location_unknown_elapsed += maxf(delta, 0.0)

	if player_was_visible:
		sight_loss_elapsed += maxf(delta, 0.0)
		if sight_loss_elapsed < settings.sight_loss_grace_seconds:
			return
		player_was_visible = false
		sight_loss_elapsed = 0.0
		has_chase_target = false
		prediction_search_direction = last_seen_player_velocity
		prediction_followup_searches_remaining = int(
			settings.prediction_followup_search_count
		)
		last_chase_target = _get_predicted_last_seen_target()
		if _is_possible_player_position_ruled_out(last_chase_target):
			pursuing_last_seen_position = false
			_begin_junction_scan(SearchPlan.LastSeenDirection, delta)
			return
		pursuing_last_seen_position = true
		var last_seen_route := navigation.build_route_to(
			last_chase_target
		) as Array[Vector3]
		if last_seen_route.is_empty():
			pursuing_last_seen_position = false
			recover_from_route_failure()
		else:
			body.pursue_last_seen_player(last_chase_target)
		return

	if junction_scan_active:
		_update_junction_scan(delta)
		return

	if pursuing_last_seen_position:
		if not bool(navigation.get("has_target")):
			pursuing_last_seen_position = false
			if _active_route_failed():
				recover_from_route_failure()
			else:
				_begin_junction_scan(SearchPlan.LastSeenDirection, delta)
		return

	if noise_target_active and not bool(navigation.get("has_target")):
		noise_target_active = false
		if _active_route_failed():
			recover_from_route_failure()
			return
		if noise_path_direction_hint.is_zero_approx():
			noise_path_direction_hint = navigation.get_last_arrival_direction() as Vector3
		_begin_junction_scan(SearchPlan.NoiseRadius, delta)
		return

	if searching and not bool(navigation.get("has_target")):
		searching = false
		if _active_route_failed():
			recover_from_route_failure()
			return
		if active_search_plan == SearchPlan.LastSeenDirection:
			_update_prediction_direction_from_completed_route()
		_begin_junction_scan(active_search_plan, delta)


func notify_noise(
		noise_position: Vector3,
		records_landmark_evidence := false,
		source: AwarenessSource = AwarenessSource.Noise
) -> bool:
	var confirmed_pursuit_active := _try_prioritize_visible_player() \
		or _is_confirmed_player_pursuit_active()
	if confirmed_pursuit_active:
		return false
	_remember_noise(noise_position, records_landmark_evidence)
	noise_target_active = true
	player_was_visible = false
	player_is_visible = false
	sight_loss_elapsed = 0.0
	searching = false
	pursuing_last_seen_position = false
	_cancel_junction_scan()
	has_chase_target = false
	player_location_unknown_elapsed = 0.0
	prediction_followup_searches_remaining = 0
	awareness_source = source
	return true


## Refreshes the search envelope for a nearby noise without interrupting the current route.
func refresh_noise_origin(noise_position: Vector3, records_landmark_evidence := false) -> void:
	var confirmed_pursuit_active := _try_prioritize_visible_player() \
		or _is_confirmed_player_pursuit_active()
	if confirmed_pursuit_active:
		return
	_remember_noise(noise_position, records_landmark_evidence)
	player_location_unknown_elapsed = 0.0
	awareness_source = AwarenessSource.Noise


## Selects a hidden known objective, exit route, or reachable frontier to investigate.
func begin_search() -> bool:
	if body == null or navigation == null or settings == null or end_gate == null:
		return false
	if _try_prioritize_visible_player():
		return false
	pursuing_last_seen_position = false

	var known_destination := _select_plausible_known_destination()
	if not known_destination.is_empty() and _begin_strategic_search_to(
		known_destination["position"] as Vector3
	):
		return true
	if not _is_possible_player_position_ruled_out(end_gate.global_position) \
			and _begin_strategic_search_to(end_gate.global_position):
		return true
	var hidden_frontier := navigation.get_reachable_search_points(
		body.global_position,
		float(settings.prediction_followup_max_distance),
		float(settings.noise_search_minimum_distance_fraction),
		navigation.get_last_arrival_direction() as Vector3,
		float(settings.last_seen_prediction_alignment)
	) as Array[Vector3]
	hidden_frontier = _remove_ruled_out_player_positions(hidden_frontier)
	for hidden_target in hidden_frontier:
		if _begin_strategic_search_to(hidden_target):
			return true

	searching = false
	body.finish_search()
	return false


## Returns the furthest maze-route distance the player could cover since the latest sound.
func get_noise_uncertainty_radius() -> float:
	if settings == null:
		return 0.0
	return maxf(noise_elapsed_seconds, 0.0) \
		* maxf(float(settings.assumed_player_max_speed), 0.0)


## Returns the time-decayed confidence retained from the latest sound.
func get_noise_evidence_relevance() -> float:
	if settings == null:
		return 0.0
	var half_life_seconds := maxf(
		float(settings.noise_evidence_half_life_seconds),
		0.001
	)
	return pow(0.5, maxf(noise_elapsed_seconds, 0.0) / half_life_seconds)


## Selects a deterministic-random reachable point inside the noise travel envelope.
func begin_noise_radius_search() -> bool:
	if _try_prioritize_visible_player():
		return false
	if body == null or navigation == null or settings == null or not has_noise_position:
		return begin_search()

	var maximum_travel_distance := get_noise_uncertainty_radius()
	if layout_knowledge != null \
			and maximum_travel_distance \
			>= float(settings.layout_knowledge_minimum_search_distance):
		var known_destination := layout_knowledge.select_likely_destination(
			last_noise_position,
			maximum_travel_distance,
			noise_path_direction_hint,
			settings.noise_path_hint_minimum_alignment,
			navigation,
			get_noise_evidence_relevance(),
			Callable(self, &"_is_possible_player_position_ruled_out")
		) as Dictionary
		if not known_destination.is_empty() and _begin_noise_search_to(
			known_destination["position"] as Vector3
		):
			return true
	var candidates := navigation.get_reachable_search_points(
		last_noise_position,
		maximum_travel_distance,
		settings.noise_search_minimum_distance_fraction,
		noise_path_direction_hint,
		settings.noise_path_hint_minimum_alignment
	) as Array[Vector3]
	candidates = _remove_ruled_out_player_positions(candidates)
	if candidates.is_empty():
		# Recheck a still-plausible sound origin, otherwise leave the visible envelope
		# for a hidden strategic position while the uncertainty radius keeps growing.
		if not _is_possible_player_position_ruled_out(last_noise_position) \
				and _begin_noise_search_to(last_noise_position):
			return true
		return begin_search()

	var selected_index := noise_search_rng.randi_range(0, candidates.size() - 1)
	for candidate_offset in candidates.size():
		var candidate_index := (selected_index + candidate_offset) % candidates.size()
		if _begin_noise_search_to(candidates[candidate_index]):
			return true
	return begin_search()


## Continues along the player's last confirmed movement without consulting their live position.
func begin_last_seen_direction_search() -> bool:
	if _try_prioritize_visible_player():
		return false
	var search_direction := prediction_search_direction
	if search_direction.is_zero_approx():
		search_direction = last_seen_player_velocity
	if prediction_followup_searches_remaining <= 0 \
			or search_direction.length() \
			< float(settings.last_seen_prediction_minimum_speed):
		return begin_search()
	var followup_distance := get_last_seen_uncertainty_radius()
	var prediction_seconds := followup_distance / maxf(
		search_direction.length(),
		float(settings.last_seen_prediction_minimum_speed)
	)
	# Each follow-up begins where the previous prediction finished. Reusing the
	# original sight-loss position can select the same exhausted dead end and
	# repeatedly send the Vampire back toward stale evidence.
	var prediction_origin := body.global_position
	var search_target := navigation.predict_reachable_target(
		prediction_origin,
		search_direction,
		prediction_seconds,
		followup_distance,
		float(settings.last_seen_prediction_alignment),
		false,
		Callable(self, &"_is_possible_player_position_ruled_out")
	) as Vector3
	if Vector2(
		search_target.x - body.global_position.x,
		search_target.z - body.global_position.z
	).length() <= float(settings.target_reached_distance) \
			or _is_possible_player_position_ruled_out(search_target):
		prediction_followup_searches_remaining = 0
		return begin_search()

	prediction_followup_searches_remaining -= 1
	var route := navigation.build_route_to(search_target) as Array[Vector3]
	if route.is_empty():
		prediction_followup_searches_remaining = 0
		return begin_search()
	searching = true
	active_search_plan = SearchPlan.LastSeenDirection
	body.search_route(search_target)
	return true


## Returns the expanding reachable radius searched after the player leaves sight.
func get_last_seen_uncertainty_radius() -> float:
	if settings == null:
		return 0.0
	var elapsed_travel_distance := maxf(player_location_unknown_elapsed, 0.0) \
		* maxf(float(settings.assumed_player_max_speed), 0.0)
	return clampf(
		maxf(elapsed_travel_distance, float(settings.prediction_followup_distance)),
		float(settings.prediction_followup_distance),
		maxf(
			float(settings.prediction_followup_max_distance),
			float(settings.prediction_followup_distance)
		)
	)


func _begin_noise_search_to(search_target: Vector3) -> bool:
	var route := navigation.build_route_to(search_target) as Array[Vector3]
	if route.is_empty():
		return false
	searching = true
	active_search_plan = SearchPlan.NoiseRadius
	body.search_route(search_target)
	return true


func is_player_visible() -> bool:
	return player_is_visible


func get_awareness_source() -> AwarenessSource:
	return awareness_source


## Broadens the investigation after route construction fails instead of treating it as arrival.
func recover_from_route_failure() -> bool:
	noise_target_active = false
	searching = false
	pursuing_last_seen_position = false
	_cancel_junction_scan()
	has_chase_target = false
	if begin_search():
		return true
	body.finish_search()
	return false


func _active_route_failed() -> bool:
	return navigation.get_route_traversal_status() \
		== GDVampireNavigation.RouteTraversalStatus.Failed


func _begin_junction_scan(search_plan: SearchPlan, _delta: float) -> void:
	if _try_prioritize_visible_player():
		return
	search_plan_after_scan = search_plan
	_cancel_junction_scan()
	_resume_search_after_scan()


func _update_junction_scan(delta: float) -> void:
	if junction_scan_directions.is_empty():
		_resume_search_after_scan()
		return

	junction_scan_elapsed += maxf(delta, 0.0)
	var seconds_per_direction := float(settings.junction_scan_seconds_per_direction)
	junction_scan_direction_index = mini(
		floori(junction_scan_elapsed / seconds_per_direction),
		junction_scan_directions.size() - 1
	)
	body.face_scan_direction(
		junction_scan_directions[junction_scan_direction_index],
		delta
	)
	if junction_scan_elapsed < seconds_per_direction * junction_scan_directions.size():
		return
	_resume_search_after_scan()


func _resume_search_after_scan() -> void:
	_cancel_junction_scan()
	if search_plan_after_scan == SearchPlan.NoiseRadius:
		begin_noise_radius_search()
	elif search_plan_after_scan == SearchPlan.LastSeenDirection:
		begin_last_seen_direction_search()
	else:
		begin_search()


func _update_visible_chase(
		confirmed_player_position: Vector3
) -> void:
	var visible_route_completed := has_chase_target \
		and not bool(navigation.get("has_target"))
	var visible_branch_changed := has_chase_target \
		and _visible_player_requires_branch_repath(confirmed_player_position)
	var visible_route_refreshed := has_chase_target \
		and not visible_route_completed \
		and not visible_branch_changed \
		and bool(navigation.refresh_visible_route_target(confirmed_player_position))
	var visible_route_misses_contact := has_chase_target \
		and not visible_route_refreshed \
		and not bool(navigation.is_route_endpoint_within_distance(
			confirmed_player_position,
			float(settings.visible_route_contact_distance)
		))
	if has_chase_target \
			and not visible_route_completed \
			and not visible_branch_changed \
			and not visible_route_misses_contact:
		return

	body.chase_visible_player(
		confirmed_player_position,
		confirmed_player_position,
		bool(senses.is_player_direct_path_clear())
	)
	last_chase_target = confirmed_player_position
	last_chase_observed_player_position = confirmed_player_position
	has_chase_target = true


func _visible_player_requires_branch_repath(player_position: Vector3) -> bool:
	var active_direction := navigation.get_active_route_direction() as Vector3
	var visible_direction := player_position - body.global_position
	visible_direction.y = 0.0
	if active_direction.is_zero_approx() or visible_direction.is_zero_approx():
		return false
	return active_direction.dot(visible_direction.normalized()) \
		< float(settings.chase_branch_change_alignment)


func _try_prioritize_visible_player() -> bool:
	if body == null or navigation == null or settings == null \
			or player == null or senses == null:
		return false
	if not bool(senses.can_see_player()):
		return false
	player_is_visible = true
	var confirmed_player_position := player.global_position
	navigation.update_visible_player_position(
		confirmed_player_position,
		bool(senses.is_player_direct_path_clear())
	)
	_enter_visible_chase(0.0, confirmed_player_position)
	return true


## Keeps sound evidence below confirmed sight and its short occlusion grace period.
func _is_confirmed_player_pursuit_active() -> bool:
	if body != null and body.has_method(&"is_chasing_player"):
		return bool(body.call(&"is_chasing_player"))
	return player_is_visible or player_was_visible


func _enter_visible_chase(
		delta: float,
		confirmed_player_position: Vector3,
		force_confirmed_reacquisition := false
) -> void:
	var newly_acquired := not player_was_visible or force_confirmed_reacquisition
	var chase_state_was_invalid := not bool(body.call("is_chasing_player"))
	player_location_unknown_elapsed = 0.0
	noise_target_active = false
	has_noise_position = false
	noise_elapsed_seconds = 0.0
	searching = false
	pursuing_last_seen_position = false
	_cancel_junction_scan()
	sight_loss_elapsed = 0.0
	awareness_source = AwarenessSource.Sight
	if newly_acquired or chase_state_was_invalid:
		has_chase_target = false
	_record_visible_player_motion(delta, confirmed_player_position)
	_update_visible_chase(
		confirmed_player_position
	)
	player_was_visible = true


func _cancel_junction_scan() -> void:
	junction_scan_active = false
	junction_scan_directions.clear()
	junction_scan_direction_index = 0
	junction_scan_elapsed = 0.0
	if body != null and body.has_method(&"finish_junction_scan"):
		body.call(&"finish_junction_scan")


func _on_player_visibility_changed(visible: bool) -> void:
	player_is_visible = visible
	if visible:
		var confirmed_player_position := player.global_position
		navigation.update_visible_player_position(
			confirmed_player_position,
			bool(senses.is_player_direct_path_clear())
		)
		_enter_visible_chase(0.0, confirmed_player_position, true)
	else:
		navigation.clear_visible_player_position()


func _record_visible_player_motion(delta: float, observed_position: Vector3) -> void:
	if has_visible_observation and delta > 0.0001:
		var sampled_velocity := (observed_position - previous_visible_player_position) / delta
		sampled_velocity.y = 0.0
		var maximum_speed := maxf(float(settings.assumed_player_max_speed), 0.1)
		if sampled_velocity.length() > maximum_speed:
			sampled_velocity = sampled_velocity.normalized() * maximum_speed
		last_seen_player_velocity = last_seen_player_velocity.lerp(
			sampled_velocity,
			clampf(float(settings.last_seen_velocity_sample_weight), 0.0, 1.0)
		)
		prediction_search_direction = last_seen_player_velocity
	previous_visible_player_position = observed_position
	last_confirmed_player_position = observed_position
	has_visible_observation = true


func _update_prediction_direction_from_completed_route() -> void:
	var arrival_direction := navigation.get_last_arrival_direction() as Vector3
	if arrival_direction.is_zero_approx():
		return
	var retained_speed := maxf(
		prediction_search_direction.length(),
		last_seen_player_velocity.length()
	)
	prediction_search_direction = arrival_direction.normalized() * retained_speed


func _get_predicted_last_seen_target() -> Vector3:
	if not has_visible_observation \
			or last_seen_player_velocity.length() \
			< float(settings.last_seen_prediction_minimum_speed):
		return last_confirmed_player_position \
			if has_visible_observation else last_chase_target
	return navigation.predict_reachable_target(
		last_confirmed_player_position,
		last_seen_player_velocity,
		float(settings.last_seen_prediction_seconds),
		float(settings.last_seen_prediction_max_distance),
		float(settings.last_seen_prediction_alignment),
		false,
		Callable(self, &"_is_possible_player_position_ruled_out")
	) as Vector3


func _update_noise_direction_hint(noise_position: Vector3) -> void:
	if has_noise_position and Vector2(
		noise_position.x - last_noise_position.x,
		noise_position.z - last_noise_position.z
	).length() >= float(settings.noise_path_hint_minimum_distance):
		var inferred_direction := navigation.get_path_arrival_direction(
			last_noise_position,
			noise_position
		) as Vector3
		if not inferred_direction.is_zero_approx():
			noise_path_direction_hint = inferred_direction
			return

	var confirmed_walking_direction := last_seen_player_velocity
	confirmed_walking_direction.y = 0.0
	if has_visible_observation \
			and confirmed_walking_direction.length() \
			>= float(settings.last_seen_prediction_minimum_speed):
		noise_path_direction_hint = confirmed_walking_direction.normalized()
	elif not has_noise_position:
		noise_path_direction_hint = Vector3.ZERO


## Remembers sound evidence without deciding whether it may interrupt the active behavior.
func _remember_noise(noise_position: Vector3, records_landmark_evidence: bool) -> void:
	_update_noise_direction_hint(noise_position)
	if layout_knowledge != null and records_landmark_evidence:
		layout_knowledge.record_noise_evidence(
			noise_position,
			settings.layout_landmark_noise_match_distance
		)
	elif layout_knowledge != null:
		layout_knowledge.record_location_only_evidence()
	last_noise_position = noise_position
	noise_elapsed_seconds = 0.0
	has_noise_position = true


func _select_plausible_known_destination() -> Dictionary:
	if layout_knowledge == null:
		return {}
	var evidence_position := last_confirmed_player_position \
		if has_visible_observation else body.global_position
	var maximum_route_distance := get_last_seen_uncertainty_radius() \
		if has_visible_observation else INF
	var preferred_direction := prediction_search_direction \
		if has_visible_observation else navigation.get_last_arrival_direction() as Vector3
	var evidence_relevance := get_noise_evidence_relevance() \
		if awareness_source == AwarenessSource.Noise and has_noise_position \
		else 1.0
	return layout_knowledge.select_likely_destination(
		evidence_position,
		maximum_route_distance,
		preferred_direction,
		float(settings.last_seen_prediction_alignment),
		navigation,
		evidence_relevance,
		Callable(self, &"_is_possible_player_position_ruled_out")
	) as Dictionary


func _remove_ruled_out_player_positions(
		candidates: Array[Vector3]
) -> Array[Vector3]:
	var possible_positions: Array[Vector3] = []
	for candidate in candidates:
		if not _is_possible_player_position_ruled_out(candidate):
			possible_positions.append(candidate)
	return possible_positions


func _is_possible_player_position_ruled_out(candidate: Vector3) -> bool:
	if player_is_visible and player != null and is_instance_valid(player):
		var player_offset := player.global_position - candidate
		player_offset.y = 0.0
		var confirmed_position_tolerance := float(settings.target_reached_distance) \
			if settings != null else 0.001
		if player_offset.length() <= confirmed_position_tolerance:
			return false
	if senses == null or not senses.has_method(&"can_verify_position_is_empty"):
		return false
	return bool(senses.call(&"can_verify_position_is_empty", candidate))


func _begin_strategic_search_to(search_target: Vector3) -> bool:
	var horizontal_distance := Vector2(
		search_target.x - body.global_position.x,
		search_target.z - body.global_position.z
	).length()
	if horizontal_distance <= float(settings.target_reached_distance):
		return false
	var route := navigation.build_route_to(search_target) as Array[Vector3]
	if route.is_empty():
		return false
	searching = true
	active_search_plan = SearchPlan.StrategicRoute
	body.search_route(search_target)
	return true
