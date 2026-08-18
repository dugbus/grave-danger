extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/treasure_pile.gd")
const SUBJECT_PATH := "res://placeables/treasure/treasure_pile.gd"
const GOLD_COIN_SCENE := preload("res://placeables/treasure/gold_coin.tscn")
const GENERATED_FLOOR_TILE_HALF_EXTENT := 0.5
const FLOOR_EDGE_MARGIN := 0.05


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_expect_catalog_cache_uses_metadata_only()
	_expect_default_scatter_fits_generated_floor_tile()


func _expect_catalog_cache_uses_metadata_only() -> void:
	var pile := SUBJECT.new() as GDTreasurePile
	pile.call("_load_treasure_catalog", true)
	var cached_resources := 0
	for entry in pile.cached_catalog:
		for value in entry.values():
			if value is Resource:
				cached_resources += 1
	expect_equal(
		cached_resources,
		0,
		"The treasure catalog caches metadata without retaining resource cycles."
	)
	pile.free()


func _expect_default_scatter_fits_generated_floor_tile() -> void:
	var pile_scene := load(
		"res://placeables/treasure/treasure_pile.tscn"
	) as PackedScene
	var pile := pile_scene.instantiate() as GDTreasurePile
	var coin := GOLD_COIN_SCENE.instantiate() as GDGoldCoin
	var collision_shape := coin.get_node("CollisionShape3D") as CollisionShape3D
	var coin_shape := collision_shape.shape as CylinderShape3D
	expect(
		pile.pile_radius + coin_shape.radius + FLOOR_EDGE_MARGIN \
			<= GENERATED_FLOOR_TILE_HALF_EXTENT,
		"Mixed treasure stays inside one generated floor tile with collider clearance."
	)
	coin.free()
	pile.free()
