extends RefCounted
class_name GDGeneratedTreasureBudget

const TREASURE_TYPES: Array[StringName] = [
	&"gold_coin",
	&"diamond",
	&"ruby",
	&"sapphire",
	&"emerald",
	&"amethyst",
	&"gold_bar",
]
const TREASURE_ITEMS := {
	&"gold_coin": preload("res://placeables/treasure/gold_coin_inventory.tres"),
	&"diamond": preload("res://placeables/treasure/gems/diamond_inventory.tres"),
	&"ruby": preload("res://placeables/treasure/gems/ruby_inventory.tres"),
	&"sapphire": preload("res://placeables/treasure/gems/sapphire_inventory.tres"),
	&"emerald": preload("res://placeables/treasure/gems/emerald_inventory.tres"),
	&"amethyst": preload("res://placeables/treasure/gems/amethyst_inventory.tres"),
	&"gold_bar": preload("res://placeables/treasure/gold_bar_inventory.tres"),
}


func from_configuration(configuration: Resource) -> Dictionary:
	return {
		&"gold_coin": 0,
		&"diamond": maxi(int(configuration.get("diamond_budget")), 0),
		&"ruby": maxi(int(configuration.get("ruby_budget")), 0),
		&"sapphire": maxi(int(configuration.get("sapphire_budget")), 0),
		&"emerald": maxi(int(configuration.get("emerald_budget")), 0),
		&"amethyst": maxi(int(configuration.get("amethyst_budget")), 0),
		&"gold_bar": maxi(int(configuration.get("gold_bar_budget")), 0),
	}


func get_total_weight(budgets: Dictionary) -> float:
	var total_weight := 0.0
	for item_type in TREASURE_TYPES:
		var item := TREASURE_ITEMS[item_type] as Resource
		total_weight += float(budgets.get(item_type, 0)) * float(item.get("weight"))
	return total_weight


func sum_caches(caches: Array[Dictionary]) -> Dictionary:
	var totals := {}
	for item_type in TREASURE_TYPES:
		totals[item_type] = 0
	for cache in caches:
		var counts := cache["counts"] as Dictionary
		for item_type in TREASURE_TYPES:
			totals[item_type] = int(totals[item_type]) + int(counts.get(item_type, 0))
	return totals
