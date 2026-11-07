extends "res://tests/test_case.gd"

const REGION := preload("res://placeables/kill_boundary/sepia/sepia_boundary_mode.gd")
const CONTACTS := preload("res://placeables/kill_boundary/sepia/sepia_contacts.gd")


func run(tree: SceneTree) -> void:
	var root := Node3D.new()
	var region := load("res://placeables/kill_boundary/kill_boundary.tscn").instantiate() as GDKillBoundary3D
	region.boundary_animation = Animation.new()
	region.autoplay_boundary_animation = false
	region.render_effect = region.RenderEffect.Sepia
	var player := CharacterBody3D.new()
	var enemy := AnimatableBody3D.new()
	enemy.sync_to_physics = false
	var world_body := StaticBody3D.new()
	var contacts := CONTACTS.new()
	root.add_child(region)
	root.add_child(player)
	root.add_child(enemy)
	root.add_child(world_body)
	root.add_child(contacts)
	tree.root.add_child(root)
	region.near_flame_audio_player.stream = null
	region.get_node(^"SepiaMode/View/Contacts").set_physics_process(false)
	contacts.set_physics_process(false)
	contacts.register_player(player)
	contacts.register_body(enemy)
	contacts._physics_process(0.0)
	expect(enemy in player.get_collision_exceptions(), "Concealed bodies cannot block the player.")
	expect(world_body not in player.get_collision_exceptions(), "World support remains solid.")
	expect_equal(enemy.collision_layer, 1, "Enemy world collision layers remain intact.")
	region.sepia_inverted = true
	contacts._physics_process(0.0)
	expect(
		enemy not in player.get_collision_exceptions(),
		"Inversion restores body contact on the newly coloured interior."
	)
	enemy.position.x = 100.0
	contacts._physics_process(0.0)
	expect(enemy in player.get_collision_exceptions(), "Inversion conceals exterior threats from player contact.")
	region.sepia_inverted = false
	region.render_effect = region.RenderEffect.None
	contacts._physics_process(0.0)
	expect(enemy not in player.get_collision_exceptions(), "Colour restores normal player contact immediately.")
	player.add_collision_exception_with(enemy)
	region.render_effect = region.RenderEffect.Sepia
	contacts._physics_process(0.0)
	region.render_effect = region.RenderEffect.None
	contacts._physics_process(0.0)
	expect(enemy in player.get_collision_exceptions(), "Authored exceptions are never removed by the view.")
	player.free()
	expect(
		contacts.players.is_empty() and contacts._ignored.is_empty(),
		"Removing a player clears tracked contacts before its body is freed."
	)
	contacts.reset()
	root.free()
