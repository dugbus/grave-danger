@tool
class_name PNGToGridMapMappingCatalog
extends RefCounted

## Owns colour-mapping list operations shared by PNG discovery and the manual editor controls.

const ColorMappingResource := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")


## Finds the configured mapping for one normalized HTML colour key.
static func mapping_for_key(settings: Resource, key: String) -> Resource:
	for mapping: Resource in settings.color_mappings:
		if PNGToGridMapImageGrid.colour_key(mapping.colour) == key:
			return mapping
	return null


## Lists detected colours first, followed by configured manual colours absent from the PNG.
static func ordered_keys(settings: Resource, detected_order: Array[String]) -> Array[String]:
	var keys := detected_order.duplicate()
	for mapping: Resource in settings.color_mappings:
		var key := PNGToGridMapImageGrid.colour_key(mapping.colour)
		if not keys.has(key):
			keys.append(key)
	return keys


## Adds or restores one mapping and returns the existing mapping when the colour is already configured.
static func add_mapping(settings: Resource, colour: Color) -> Resource:
	var key := PNGToGridMapImageGrid.colour_key(colour)
	var existing := mapping_for_key(settings, key)
	if existing != null:
		return existing
	settings.ignored_colour_keys.erase(key)
	var mapping := ColorMappingResource.new()
	mapping.colour = colour
	mapping.display_name = "#" + key
	settings.color_mappings.append(mapping)
	return mapping


## Removes one mapping and remembers that PNG discovery must leave the colour unconfigured.
static func remove_mapping(settings: Resource, mapping: Resource) -> void:
	if mapping == null:
		return
	var key := PNGToGridMapImageGrid.colour_key(mapping.colour)
	settings.color_mappings.erase(mapping)
	if not settings.ignored_colour_keys.has(key):
		settings.ignored_colour_keys.append(key)


## Creates a mapping for a newly detected PNG colour unless an editor removed it deliberately.
static func ensure_detected_mapping(settings: Resource, key: String, colour: Color) -> Resource:
	var existing := mapping_for_key(settings, key)
	if existing != null or settings.ignored_colour_keys.has(key):
		return existing
	return add_mapping(settings, colour)
