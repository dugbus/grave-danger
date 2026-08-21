extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/gold-coin.gd")
const SUBJECT_PATH := "res://placeables/treasure/gold-coin.gd"
const GOLD_COIN_SCENE := preload("res://placeables/treasure/gold_coin.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _expect_out_of_bounds_coin_recovers_on_floor(tree)


func _expect_out_of_bounds_coin_recovers_on_floor(tree: SceneTree) -> void:
	var test_origin := Vector3(1234.0, 1.0, 1234.0)
	var test_root := Node3D.new()
	test_root.name = "GoldCoinRecoveryTest"
	tree.root.add_child(test_root)

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	test_root.add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(4.0, 0.2, 4.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	floor_body.global_position = Vector3(test_origin.x, 0.0, test_origin.z)
	await tree.physics_frame

	var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
	test_root.add_child(coin)
	coin.throw_from(Transform3D(Basis(), test_origin), Vector3.ZERO)
	await tree.physics_frame

	coin.global_position = Vector3(test_origin.x, coin.despawn_below_y - 1.0, test_origin.z)
	coin.linear_velocity = Vector3(1.0, -10.0, 1.0)
	coin.angular_velocity = Vector3.ONE
	await tree.physics_frame

	expect(
		is_instance_valid(coin) and not coin.is_queued_for_deletion(),
		"A gold coin remains available after crossing the out-of-bounds threshold."
	)
	expect(
		coin.get_out_of_bounds_recovery_count() == 1 \
			and coin.is_in_group("recovered_gold_coin"),
		"Out-of-bounds recovery is detected and recorded on the recovered coin."
	)
	expect(
		is_equal_approx(coin.global_position.y, 0.1) \
			and coin.freeze \
			and coin.linear_velocity.is_zero_approx() \
			and coin.angular_velocity.is_zero_approx(),
		"A recovered coin rests motionless above the nearest floor surface."
	)

	test_root.queue_free()
	await tree.process_frame
