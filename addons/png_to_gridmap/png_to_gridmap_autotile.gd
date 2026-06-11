@tool
class_name PNGToGridMapAutotile
extends RefCounted

const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8

const VARIANT_BASE := "base"
const VARIANT_END := "end"
const VARIANT_CORNER := "corner"
const VARIANT_TEE := "tee"
const VARIANT_CROSS := "cross"

const VARIANTS := [
	VARIANT_BASE,
	VARIANT_END,
	VARIANT_CORNER,
	VARIANT_TEE,
	VARIANT_CROSS,
]


## Counts how many cardinal neighbours are represented in a bitmask.
static func bit_count(mask: int) -> int:
	var count := 0
	for bit in [NORTH, EAST, SOUTH, WEST]:
		if (mask & bit) != 0:
			count += 1
	return count


## Reports whether a neighbour bitmask is one of the four corner shapes.
static func is_corner_mask(mask: int) -> bool:
	return (
		mask == (NORTH | EAST)
		or mask == (EAST | SOUTH)
		or mask == (SOUTH | WEST)
		or mask == (WEST | NORTH)
	)


## Chooses the autotile variant that should represent a same-colour neighbour mask.
static func variant_for_mask(mask: int) -> String:
	var neighbours := bit_count(mask)
	if neighbours == 4:
		return VARIANT_CROSS
	if neighbours == 3:
		return VARIANT_TEE
	if neighbours == 1:
		return VARIANT_END
	if is_corner_mask(mask):
		return VARIANT_CORNER
	return VARIANT_BASE


## Computes the top-down rotation in radians for a deterministic autotile mask.
static func rotation_radians_for_mask(mask: int) -> float:
	var variant := variant_for_mask(mask)
	var default_mask := default_mask_for_variant(variant)
	for turns in 4:
		if rotate_mask_clockwise(default_mask, turns) == mask:
			return float(turns) * PI * 0.5
	return 0.0


## Returns the unrotated connection mask expected by the naming convention.
static func default_mask_for_variant(variant: String) -> int:
	if variant == VARIANT_END:
		return WEST
	if variant == VARIANT_CORNER:
		return EAST | SOUTH
	if variant == VARIANT_TEE:
		return EAST | SOUTH | WEST
	if variant == VARIANT_CROSS:
		return NORTH | EAST | SOUTH | WEST
	return EAST | WEST


## Rotates a cardinal mask clockwise in top-down PNG/grid space.
static func rotate_mask_clockwise(mask: int, turns: int) -> int:
	var result := mask
	for _turn in wrapi(turns, 0, 4):
		var rotated := 0
		if (result & NORTH) != 0:
			rotated |= EAST
		if (result & EAST) != 0:
			rotated |= SOUTH
		if (result & SOUTH) != 0:
			rotated |= WEST
		if (result & WEST) != 0:
			rotated |= NORTH
		result = rotated
	return result


## Builds a Godot basis for a variant after applying its per-item rotation offset.
static func basis_for_variant(
	mapping: Resource,
	variant: String,
	mask: int,
	use_autotile_rotation: bool
) -> Basis:
	var base_rotation := rotation_radians_for_mask(mask) if use_autotile_rotation else 0.0
	var offset := rotation_offset_for_mapping(mapping, variant)
	return Basis.IDENTITY.rotated(Vector3.UP, base_rotation + (PI * 0.5 * float(offset)))


## Reads the item reference assigned to one mapping variant.
static func variant_ref_for_mapping(mapping: Resource, variant: String) -> String:
	if variant == VARIANT_END:
		return mapping.end_item_ref
	if variant == VARIANT_CORNER:
		return mapping.corner_item_ref
	if variant == VARIANT_TEE:
		return mapping.tee_item_ref
	if variant == VARIANT_CROSS:
		return mapping.cross_item_ref
	return mapping.base_item_ref


## Writes the item reference assigned to one mapping variant.
static func set_variant_ref_for_mapping(mapping: Resource, variant: String, item_ref: String) -> void:
	if variant == VARIANT_END:
		mapping.end_item_ref = item_ref
	elif variant == VARIANT_CORNER:
		mapping.corner_item_ref = item_ref
	elif variant == VARIANT_TEE:
		mapping.tee_item_ref = item_ref
	elif variant == VARIANT_CROSS:
		mapping.cross_item_ref = item_ref
	else:
		mapping.base_item_ref = item_ref


## Reads the quarter-turn offset assigned to one mapping variant.
static func rotation_offset_for_mapping(mapping: Resource, variant: String) -> int:
	if variant == VARIANT_END:
		return int(mapping.get("end_rotation_offset"))
	if variant == VARIANT_CORNER:
		return int(mapping.get("corner_rotation_offset"))
	if variant == VARIANT_TEE:
		return int(mapping.get("tee_rotation_offset"))
	if variant == VARIANT_CROSS:
		return int(mapping.get("cross_rotation_offset"))
	return int(mapping.get("base_rotation_offset"))


## Writes a normalized quarter-turn offset to one mapping variant.
static func set_rotation_offset_for_mapping(mapping: Resource, variant: String, offset: int) -> void:
	var normalized_offset := wrapi(offset, 0, 4)
	if variant == VARIANT_END:
		mapping.set("end_rotation_offset", normalized_offset)
	elif variant == VARIANT_CORNER:
		mapping.set("corner_rotation_offset", normalized_offset)
	elif variant == VARIANT_TEE:
		mapping.set("tee_rotation_offset", normalized_offset)
	elif variant == VARIANT_CROSS:
		mapping.set("cross_rotation_offset", normalized_offset)
	else:
		mapping.set("base_rotation_offset", normalized_offset)


## Clears all derived variant references when a mapping base changes.
static func clear_derived_variant_refs(mapping: Resource) -> void:
	mapping.end_item_ref = ""
	mapping.corner_item_ref = ""
	mapping.tee_item_ref = ""
	mapping.cross_item_ref = ""


## Infers a variant item ref from a base ref and a conventional suffix.
static func infer_variant_ref(base_ref: String, suffix: String, available_refs: Array[String]) -> String:
	if base_ref == "":
		return ""
	var inference_ref := base_ref.get_slice("#", 0)
	var candidate := "%s-%s" % [inference_ref, suffix]
	if available_refs.has(candidate):
		return candidate
	return ""


## Fills missing derived variant refs from the current base item naming convention.
static func auto_fill_mapping_variants(mapping: Resource, available_refs: Array[String]) -> void:
	if mapping.base_item_ref == "":
		return
	if mapping.end_item_ref == "":
		mapping.end_item_ref = infer_variant_ref(mapping.base_item_ref, "end", available_refs)
	if mapping.corner_item_ref == "":
		mapping.corner_item_ref = infer_variant_ref(mapping.base_item_ref, "corner", available_refs)
	if mapping.tee_item_ref == "":
		mapping.tee_item_ref = infer_variant_ref(mapping.base_item_ref, "tee", available_refs)
	if mapping.cross_item_ref == "":
		mapping.cross_item_ref = infer_variant_ref(mapping.base_item_ref, "cross", available_refs)
