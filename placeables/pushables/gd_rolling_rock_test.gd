extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/pushables/gd_rolling_rock.gd")
const SUBJECT_PATH := "res://placeables/pushables/gd_rolling_rock.gd"
const ROCK_SCENE := preload("res://placeables/pushables/rolling_rock_pushable.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_collision_sits_on_tiled_floors()


func _test_collision_sits_on_tiled_floors() -> void:
	var rock := ROCK_SCENE.instantiate() as RollingRock
	var collision_shape := rock.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	var sphere := collision_shape.shape as SphereShape3D if collision_shape != null else null

	expect(sphere != null, "The rolling rock uses a spherical physics collision.")
	if sphere != null:
		expect(
			is_equal_approx(sphere.radius, 0.5),
			"The rolling rock rests on 0.5-high placements without penetrating tiled floors."
		)
		expect(
			is_equal_approx(sphere.radius, rock.visual_roll_radius),
			"The rolling rock collision and visible rolling radius stay aligned."
		)

	rock.free()
