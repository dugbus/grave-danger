extends Resource
class_name GDVampireSettings


## Scale applied to the imported vampire model relative to its authored size.
@export_range(0.1, 8.0, 0.1) var model_scale := 2.0
## Maximum hunting speed, set to 1.1 times the player's unloaded maximum of 5.0.
@export_range(0.1, 20.0, 0.05) var max_speed := 5.5
## Radius of the wall-occluded instant-kill contact around the doubled Vampire model.
@export_range(0.1, 2.0, 0.05, "suffix:m") var instant_kill_contact_radius := 0.8
## Horizontal acceleration used while the vampire starts hunting.
@export_range(0.1, 50.0, 0.1) var acceleration := 22.0
## Horizontal deceleration used when the vampire reaches the heard location.
@export_range(0.1, 50.0, 0.1) var deceleration := 28.0
## Radians per second used to turn the vampire model toward its route.
@export_range(0.1, 30.0, 0.1) var turn_speed := 12.0
## Distance at which an intermediate maze route point is considered reached.
@export_range(0.05, 2.0, 0.05) var waypoint_reached_distance := 0.2
## Distance at which the last-heard noise location is considered reached.
@export_range(0.05, 2.0, 0.05) var target_reached_distance := 0.35
## Maximum cells searched while building a route through the maze.
@export_range(128, 65536, 128) var maximum_route_search_cells := 32768
## Stable seed used for replay-safe random choices after investigating a sound.
@export_range(1, 2147483647, 1) var noise_search_seed := 1031

@export_group("Obstacle Stride")
## Vertical speed used to lift the Vampire model over coffins it can run through.
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var obstacle_stride_vertical_speed := 6.0

@export_group("Route Recovery")
## Seconds without useful route progress before rebuilding from the current position.
@export_range(0.1, 2.0, 0.05) var wall_stall_recovery_seconds := 0.4
## Minimum commanded horizontal speed required before movement can count as a route stall.
@export_range(0.1, 10.0, 0.1) var wall_stall_minimum_speed := 1.0
## Minimum movement toward the active waypoint per second that counts as useful route progress.
@export_range(0.01, 2.0, 0.01) var wall_stall_minimum_progress_speed := 0.15

@export_group("Sight")
## Maximum distance at which the vampire can visually acquire the player.
@export_range(1.0, 100.0, 0.5) var sight_distance := 64.0
## Floor-relative cast height kept low so the doubled model cannot see over walls.
@export_range(0.1, 2.0, 0.05) var sight_origin_height := 0.65
## Radius swept along the floor, matching the vampire body width needed to reach the player.
@export_range(0.1, 1.5, 0.01) var sight_clearance_radius := 0.52
## Extra clearance around the body sweep before direct visible pursuit is considered safe.
@export_range(0.0, 0.5, 0.01, "suffix:m") var direct_path_clearance_margin := 0.12
## Half-width sampled across the player's body so wall edges cannot hide its centre point.
@export_range(0.0, 0.5, 0.01, "suffix:m") var visual_sight_sample_half_width := 0.15
## Time a blocked sight cast is tolerated so doorway edges cannot make the vampire abandon a chase.
@export_range(0.0, 3.0, 0.05) var sight_loss_grace_seconds := 0.35
## Minimum alignment with a visible player before a stale branch route is rebuilt immediately.
@export_range(-1.0, 1.0, 0.05) var chase_branch_change_alignment := 0.25
## Final-route precision used while closing on a confirmed visible player near walls.
@export_range(0.01, 0.5, 0.01, "suffix:m") var visible_target_reached_distance := 0.1
## Furthest a visible route endpoint may be from the player while still guaranteeing contact.
@export_range(0.1, 1.5, 0.05, "suffix:m") var visible_route_contact_distance := 0.55
@export_group("Last Seen Prediction")
## Seconds of confirmed player movement projected forward after sight is lost.
@export_range(0.0, 8.0, 0.1, "suffix:s") var last_seen_prediction_seconds := 2.0
## Maximum maze distance projected from the player's last confirmed position.
@export_range(0.0, 32.0, 0.5, "suffix:m") var last_seen_prediction_max_distance := 10.0
## Minimum confirmed player speed required before directional prediction is used.
@export_range(0.0, 10.0, 0.1) var last_seen_prediction_minimum_speed := 0.5
## Weight given to each newest visible velocity sample when smoothing player movement.
@export_range(0.0, 1.0, 0.05) var last_seen_velocity_sample_weight := 0.65
## Minimum maze-route alignment accepted in the player's last confirmed direction.
@export_range(-1.0, 1.0, 0.05) var last_seen_prediction_alignment := 0.1
## Minimum route radius searched from the last confirmed position after losing sight.
@export_range(1.0, 32.0, 0.5, "suffix:m") var prediction_followup_distance := 8.0
## Maximum expanding route radius searched from the last confirmed player position.
@export_range(1.0, 64.0, 0.5, "suffix:m") var prediction_followup_max_distance := 32.0
## Number of directional searches attempted before returning to ordinary hunting logic.
@export_range(0, 12, 1) var prediction_followup_search_count := 6

@export_group("Junction Scan")
## Idle time spent looking down each clear passage before choosing another search target.
@export_range(0.1, 3.0, 0.05) var junction_scan_seconds_per_direction := 0.5
## Floor distance checked when deciding which directions are open at an investigation point.
@export_range(0.5, 8.0, 0.25) var junction_scan_probe_distance := 2.0

@export_group("Noise Search")
## Horizontal distance within which an active noise target is reused without rebuilding its route.
@export_range(0.0, 8.0, 0.1) var noise_retarget_distance := 1.0
## Maximum player speed used to expand the reachable search area after a noise.
@export_range(0.1, 20.0, 0.1) var assumed_player_max_speed := 5.0
## Fraction of each reachable direction's distance reserved for targets near its search frontier.
@export_range(0.0, 1.0, 0.05) var noise_search_minimum_distance_fraction := 0.7
## Minimum movement between sounds before their maze path supplies a player-direction hint.
@export_range(0.1, 8.0, 0.1) var noise_path_hint_minimum_distance := 1.0
## Minimum alignment between a candidate's first route step and the inferred player direction.
@export_range(-1.0, 1.0, 0.05) var noise_path_hint_minimum_alignment := -0.05

@export_group("Layout Knowledge")
## Distance around a sound used to identify which known treasure, key, or deposit was disturbed.
@export_range(0.1, 8.0, 0.1) var layout_landmark_noise_match_distance := 2.5
## Uncertainty radius required before known objectives may influence a noise search.
@export_range(1.0, 64.0, 0.5) var layout_knowledge_minimum_search_distance := 12.0
## Seconds until a sound's landmark and direction clues carry half their original influence.
@export_range(0.1, 60.0, 0.1, "suffix:s") var noise_evidence_half_life_seconds := 6.0

@export_group("Proximity Fog")
## Distance at which the vampire's purple screen fog first becomes visible.
@export_range(1.0, 100.0, 0.5) var proximity_fog_distance := 18.0
## Distance at which the purple fog reaches its configured maximum strength.
@export_range(0.0, 50.0, 0.5) var proximity_fog_full_distance := 3.0
## Maximum shader intensity used when the vampire is extremely close.
@export_range(0.0, 1.0, 0.05) var proximity_fog_max_intensity := 0.85
## Speed at which the fog responds to changes in vampire distance.
@export_range(0.1, 30.0, 0.1) var proximity_fog_response_speed := 5.0
