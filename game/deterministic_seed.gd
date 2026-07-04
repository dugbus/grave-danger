extends RefCounted
class_name GDDeterministicSeed


const HASH_MODULUS := 2147483647
const HASH_OFFSET := 2166136261
const HASH_PRIME := 16777619


static func from_text(source_text: String, salt: int = 0) -> int:
	var hash_value := int((HASH_OFFSET + salt) % HASH_MODULUS)
	for index in range(source_text.length()):
		hash_value = int(((hash_value ^ source_text.unicode_at(index)) * HASH_PRIME) % HASH_MODULUS)

	return maxi(hash_value, 1)


static func from_node(node: Node, explicit_seed: int = 0, seed_namespace: StringName = &"") -> int:
	if explicit_seed != 0:
		return explicit_seed

	if node == null:
		return from_text(String(seed_namespace))

	var node_path: String = str(node.get_path()) if node.is_inside_tree() else String(node.name)
	var seed_source := "%s:%s:%s" % [String(seed_namespace), node.scene_file_path, node_path]
	return from_text(seed_source)
