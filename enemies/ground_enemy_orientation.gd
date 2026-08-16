extends RefCounted
class_name GDGroundEnemyOrientation

## Shared orientation correction for ground enemies placed beneath rotated patrol paths.


## Returns an upright world basis while preserving the source node's authored scale.
static func upright_basis(source_basis: Basis) -> Basis:
	return Basis.IDENTITY.scaled(source_basis.get_scale())


## Removes inherited world rotation without changing the node's position or scale.
static func make_upright(node: Node3D) -> bool:
	if node == null or not node.is_inside_tree():
		return false

	var upright_transform := node.global_transform
	upright_transform.basis = upright_basis(upright_transform.basis)
	node.global_transform = upright_transform
	return true
