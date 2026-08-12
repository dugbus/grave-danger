extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/treasure_pile.gd")
const SUBJECT_PATH := "res://placeables/treasure/treasure_pile.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_expect_catalog_cache_uses_metadata_only()


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
