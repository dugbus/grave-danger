extends RefCounted
class_name GDGeneratedContentPlan

var errors: Array[String] = []
var warnings: Array[String] = []
var seed_value := 0
var main_path: Array[Vector2i] = []
var main_path_cells: Array[Vector3i] = []
var doors: Array = []
var keys: Array = []
var coffins: Array[Dictionary] = []
var treasure_caches: Array[Dictionary] = []
var bat_nests: Array[Dictionary] = []
var treasure_budgets: Dictionary = {}
var placed_treasure_budgets: Dictionary = {}
var total_treasure_weight := 0.0
var main_path_treasure_percent := 0.0


func to_dictionary() -> Dictionary:
	return {
		"errors": errors,
		"warnings": warnings,
		"seed": seed_value,
		"main_path": main_path,
		"main_path_cells": main_path_cells,
		"doors": doors,
		"keys": keys,
		"coffins": coffins,
		"treasure_caches": treasure_caches,
		"bat_nests": bat_nests,
		"treasure_budgets": treasure_budgets,
		"placed_treasure_budgets": placed_treasure_budgets,
		"total_treasure_weight": total_treasure_weight,
		"main_path_treasure_percent": main_path_treasure_percent,
		"solvable": errors.is_empty(),
	}
