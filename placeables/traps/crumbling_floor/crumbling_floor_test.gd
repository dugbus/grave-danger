extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")


class Walker:
	extends CharacterBody3D
	var direction := Vector3.ZERO

	func _ready() -> void:
		add_to_group(&"player")

	func _physics_process(delta: float) -> void:
		velocity += get_gravity() * delta
		velocity.x = direction.x
		velocity.z = direction.z
		move_and_slide()


class FallingPlayer:
	extends GDPlayer
	var fell := false

	func _ready() -> void:
		add_to_group(&"player")

	func _physics_process(delta: float) -> void:
		velocity += get_gravity() * delta
		move_and_slide()
		_die_if_fallen_below_floor()

	func die_from_fall() -> void:
		fell = true


class EditorHistoryProbe:
	extends Node
	signal version_changed


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor.gd")
	await _test_editor_state_recovery(tree)
	expect(
		SUBJECT.load_optional_sound("res://Assets/audio/missing-floor-crack.mp3") == null,
		"Missing optional sound is silently skipped."
	)
	if FileAccess.file_exists(SUBJECT.CRACK_SOUND_PATH) or ResourceLoader.exists(SUBJECT.CRACK_SOUND_PATH):
		var supplied_sound := SUBJECT.load_optional_sound(SUBJECT.CRACK_SOUND_PATH)
		expect(
			supplied_sound is AudioStreamMP3 and supplied_sound.get_length() > 0.0,
			"The supplied floor-crack MP3 can play, including before its first local import."
		)
	await _test_seeded_order(tree)
	await _test_collapse_and_escape(tree)
	await _test_warning_survives_escape(tree)
	await _test_side_and_airborne_contacts(tree)
	await _test_adjacent_tiles_and_fall(tree)


func _add_tile(root: Node3D, at: Vector3, delay: float = 0.25) -> SUBJECT:
	var tile := SCENE.instantiate() as SUBJECT
	tile.position = at
	tile.collapse_delay = delay
	tile.debris_lifetime = 1.0
	tile.block_release_interval = 0.045
	root.add_child(tile)
	return tile


func _add_walker(root: Node3D, at: Vector3) -> Walker:
	var walker := Walker.new()
	walker.position = at
	walker.collision_layer = 2
	walker.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.3, 0.8, 0.3)
	collision.shape = shape
	collision.position.y = 0.4
	walker.add_child(collision)
	root.add_child(walker)
	return walker


func _frames(tree: SceneTree, count: int) -> void:
	for index in count:
		await tree.physics_frame
		await tree.process_frame


func _test_collapse_and_escape(tree: SceneTree) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var tile := _add_tile(root, Vector3.ZERO)
	var states: Array[SUBJECT.State] = []
	tile.state_changed.connect(func(next: SUBJECT.State) -> void: states.append(next))
	var sound := AudioStreamWAV.new()
	sound.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(40000)
	samples.fill(128)
	sound.data = samples
	tile._crack_sound = sound
	var walker := _add_walker(root, Vector3(-0.7, 0.02, 0.0))
	# A neighboring floor lets the player walk naturally onto and away from the trap.
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.25, 1.0)
	collision.shape = shape
	floor.position = Vector3(-1.0, -0.125, 0.0)
	floor.add_child(collision)
	root.add_child(floor)
	await _frames(tree, 5)
	expect_equal(tile.state, SUBJECT.State.Intact, "The neighboring floor does not activate the trap.")
	walker.direction = Vector3(1.0, 0.0, 0.0)
	for index in 45:
		await _frames(tree, 1)
		if tile.state == SUBJECT.State.Warning:
			break
	expect_equal(tile.state, SUBJECT.State.Warning, "Walking onto the tile starts a warning.")
	expect_equal(_audio_players(tile).size(), 1, "The grounded step immediately plays one crack cue.")
	var crack_player := _audio_players(tile)[0] as AudioStreamPlayer3D
	expect_equal(crack_player.stream, sound, "The positional cue uses the configured crack sound.")
	expect_equal(crack_player.bus, SUBJECT.AUDIO.SFX_BUS, "The crack follows the project's sound-effects routing.")
	expect(walker.is_on_floor(), "The intact tile provides working support collision.")
	expect_equal(_solid_blocks(tile), 16, "The warning initially keeps every block solid.")
	var floor_transform := tile.transform
	await _frames(tree, 5)
	expect_equal(tile.state, SUBJECT.State.Warning, "The configured delay elapses before collapse.")
	expect_equal(tile.transform, floor_transform, "Warning motion never shakes the supporting body.")
	walker.velocity.y = 5.0
	walker.direction = Vector3(-3.0, 0.0, 0.0)
	for index in 30:
		await _frames(tree, 1)
		if tile.state == SUBJECT.State.Collapsing:
			break
	expect_equal(tile.state, SUBJECT.State.Collapsing, "The floor enters a progressive collapse.")
	expect(
		tile._active_fragments.size() > 0 and tile._active_fragments.size() < 16,
		"Only some blocks fall at the start of the collapse."
	)
	expect(
		_solid_blocks(tile) > 0 and _solid_blocks(tile) < 16,
		"Unreleased blocks keep independent support while the first blocks disappear."
	)
	_test_partial_support(tile)
	for index in 90:
		await _frames(tree, 1)
		if tile.state == SUBJECT.State.Collapsed:
			break
	expect_equal(tile.state, SUBJECT.State.Collapsed, "Escaping does not cancel the default one-shot collapse.")
	expect(
		not tile._support.body.is_valid() and tile.multimesh.visible_instance_count == 0,
		"Collapse removes the intact visual and support."
	)
	expect_equal(tile._active_fragments.size(), 16, "Collapse releases the asset's sixteen physical blocks.")
	var state_after_contact := tile.state
	tile._activate_from_support()
	tile._activate_from_support()
	expect_equal(tile.state, state_after_contact, "Repeated contacts cannot retrigger a collapsed floor.")
	var lowest_fragment := tile._active_fragments.back() as RigidBody3D
	var start_height := lowest_fragment.global_position.y
	await _frames(tree, 5)
	expect(lowest_fragment.global_position.y < start_height, "Released fragments fall under rigid-body gravity.")
	await _frames(tree, 65)
	expect_equal(tile._active_fragments.size(), 0, "Debris is removed after its lifetime.")
	expect_equal(
		states,
		[SUBJECT.State.Warning, SUBJECT.State.Collapsing, SUBJECT.State.Collapsed],
		"A supported contact traverses each state exactly once."
	)
	expect_equal(
		_audio_players(tile).size(),
		1,
		"Warning, collapse and cleanup neither retrigger nor cut off the single crack cue."
	)
	expect(
		is_instance_valid(tile) and tile.is_inside_tree(), "Cleanup preserves the collapsed tile and its audio owner."
	)
	root.free()
	await tree.process_frame


func _test_warning_survives_escape(tree: SceneTree) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var tile := _add_tile(root, Vector3.ZERO, 0.5)
	var walker := _add_walker(root, Vector3(0.0, 0.01, 0.0))
	await _frames(tree, 6)
	expect_equal(tile.state, SUBJECT.State.Warning, "A grounded step starts the warning.")
	walker.position.x = 3.0
	await _frames(tree, 4)
	expect_equal(tile.state, SUBJECT.State.Warning, "Escaping cannot cancel a warning or leave the tile solid.")
	expect_equal(_solid_blocks(tile), 16, "Support persists only until the configured warning ends.")
	walker.position = Vector3(0.0, 0.01, 0.0)
	walker.velocity = Vector3.ZERO
	await _frames(tree, 6)
	expect_equal(tile.state, SUBJECT.State.Warning, "Returning during the warning does not restart its timer.")
	await _frames(tree, 20)
	expect_equal(tile.state, SUBJECT.State.Collapsing, "Returning cannot postpone the original collapse deadline.")
	root.free()
	await tree.process_frame


func _test_side_and_airborne_contacts(tree: SceneTree) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var tile := _add_tile(root, Vector3.ZERO)
	var side := _add_walker(root, Vector3(0.64, -0.2, -0.4))
	side.direction = Vector3(0.0, 0.0, 2.0)
	await _frames(tree, 10)
	expect_equal(tile.state, SUBJECT.State.Intact, "Brushing the side of the floor cannot trigger collapse.")
	var airborne := _add_walker(root, Vector3(0.0, 0.1, 0.0))
	airborne.velocity.y = 4.0
	await _frames(tree, 4)
	expect_equal(
		tile.state, SUBJECT.State.Intact, "Passing upward through the trigger volume cannot activate the floor."
	)
	root.free()
	await tree.process_frame


func _test_adjacent_tiles_and_fall(tree: SceneTree) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var first := _add_tile(root, Vector3.ZERO, 0.1)
	var second := _add_tile(root, Vector3.RIGHT, 0.1)
	var player := FallingPlayer.new()
	player.collision_layer = 2
	player.collision_mask = 1
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.8, 0.3)
	collision.shape = box
	collision.position.y = 0.4
	player.add_child(collision)
	# GDPlayer's existing onready wiring is provided without its presentation dependencies.
	for child_name in ["PlayerMovement", "PlayerInventory", "PlayerAnimation", "PlayerDeath", "PlayerAttention"]:
		var child := Node.new()
		child.name = child_name
		player.add_child(child)
	root.add_child(player)
	await _frames(tree, 60)

	expect_equal(first.state, SUBJECT.State.Collapsed, "A supported player collapses its own tile.")
	expect_equal(second.state, SUBJECT.State.Intact, "An adjacent tile stays independent.")
	_add_walker(root, Vector3(1.0, 0.01, 0.0))
	await _frames(tree, 60)
	expect_equal(
		second.state, SUBJECT.State.Collapsed, "The adjacent tile can subsequently collapse on its own contact."
	)
	await _frames(tree, 30)
	expect(player.fell, "Falling through the opening reaches GDPlayer's existing fall-death route.")
	root.free()
	await tree.process_frame


func _solid_blocks(tile: SUBJECT) -> int:
	return tile._blocks.size() - tile._released_count


func _test_partial_support(tile: SUBJECT) -> void:
	var released := tile._release_order[0]
	var remaining := tile._release_order.back() as int
	for index in [released, remaining]:
		var centre := tile._blocks[index].get_center()
		var world_top := tile.to_global(Vector3(centre.x, 0.0, centre.z))
		var ray := PhysicsRayQueryParameters3D.create(world_top + Vector3.UP * 0.1, world_top + Vector3.DOWN * 0.4, 1)
		var hit := tile.get_world_3d().direct_space_state.intersect_ray(ray)
		expect_equal(
			hit.get("collider") == tile,
			index == remaining,
			"Only the fallen block loses actual physics support during a partial collapse."
		)


func _test_seeded_order(tree: SceneTree) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var first := _add_tile(root, Vector3.ZERO)
	var second := _add_tile(root, Vector3.RIGHT)
	first.fracture_seed = 23
	second.fracture_seed = 23
	first._randomize_release_order()
	second._randomize_release_order()
	var order := first._release_order.duplicate() as Array[int]
	expect_equal(order, second._release_order, "Equal explicit seeds reproduce the collapse order across tiles.")
	for index in first._blocks.size():
		expect_equal(order.count(index), 1, "The shuffled order releases every authored block exactly once.")
	var authored_order: Array[int] = []
	for index in first._blocks.size():
		authored_order.append(index)
	expect(order != authored_order, "Collapse does not follow the original authored block order.")
	first._randomize_release_order()
	expect_equal(order, first._release_order, "Rebuilding an order retains deterministic replay behavior.")
	second.fracture_seed = 24
	second._randomize_release_order()
	expect(order != second._release_order, "A different seed changes the collapse order.")
	first.fracture_seed = 0
	second.fracture_seed = 0
	first._randomize_release_order()
	second._randomize_release_order()
	expect(first._release_order != second._release_order, "Default adjacent tiles derive different shuffled orders.")
	root.free()
	await tree.process_frame


func _audio_players(tile: SUBJECT) -> Array[AudioStreamPlayer3D]:
	var result: Array[AudioStreamPlayer3D] = []
	for child in tile.get_children():
		if child is AudioStreamPlayer3D:
			result.append(child as AudioStreamPlayer3D)
	return result


func _test_editor_state_recovery(tree: SceneTree) -> void:
	var root := Node3D.new()
	var tile := SCENE.instantiate() as SUBJECT
	var history := EditorHistoryProbe.new()
	expect(not tile._bind_editor_placement(history), "Off-tree tiles cannot initialize editor placement.")
	expect(tile._editor_placement == null, "Off-tree initialization does not allocate placement state.")
	tile.position = Vector3(2.3, 7.0, -4.2)
	root.add_child(tile)
	tree.root.add_child(root)
	var authored := tile.transform
	var previous_edited_root := tree.edited_scene_root
	tree.edited_scene_root = root
	# Exercise the reported callback with both fields absent and no EditorInterface in this headless run.
	tile._process_editor_placement()
	expect_equal(tile.transform, authored, "Missing editor services leave the processing tile unchanged.")
	expect(tile._editor_history == null, "Unavailable editor history remains safely disconnected.")
	expect(tile._bind_editor_placement(history), "A valid history restores missing placement state.")
	var placement := tile._editor_placement
	expect(not placement.pending, "Restoring editor state does not resnap an existing tile.")
	tile._bind_editor_placement(history)
	expect_equal(tile._editor_placement, placement, "Repeated binding preserves the placement baseline.")
	expect_equal(history.version_changed.get_connections().size(), 1, "Repeated binding connects history only once.")
	# A tool-script reload can clear fields while the existing signal connection survives.
	tile._editor_history = null
	tile._editor_placement = null
	expect(tile._bind_editor_placement(history), "Reloaded fields recover without another _enter_tree callback.")
	expect_equal(history.version_changed.get_connections().size(), 1, "Reload recovery reuses a surviving connection.")
	expect_equal(tile.transform, authored, "Reload recovery preserves authored horizontal placement and manual height.")
	tile._editor_placement.pending = true
	history.version_changed.emit()
	expect(not tile._editor_placement.pending, "Undo and redo still cancel pending placement after recovery.")
	var replacement := EditorHistoryProbe.new()
	tile._bind_editor_placement(replacement)
	expect(history.version_changed.get_connections().is_empty(), "Replacing history disconnects the old service.")
	expect_equal(replacement.version_changed.get_connections().size(), 1, "Replacement history connects once.")
	replacement.free()
	expect(tile._bind_editor_placement(history), "A freed history reference can be replaced safely.")
	root.remove_child(tile)
	expect(history.version_changed.get_connections().is_empty(), "Leaving the tree disconnects recovered history.")
	expect(tile._editor_history == null and tile._editor_placement == null, "Leaving clears editor-only state.")
	root.add_child(tile)
	expect(tile._bind_editor_placement(history), "Re-entering can restore editor state without another _ready call.")
	tree.edited_scene_root = previous_edited_root
	root.free()
	history.free()
	await tree.process_frame
