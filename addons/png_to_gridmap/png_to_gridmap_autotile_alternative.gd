@tool
class_name PNGToGridMapAutotileAlternative
extends Resource

## Describes an additional mesh shape that may already exist in a connected autotile group.
## Alternatives let repair operations recognise valid authored pieces without selecting them as primary outputs.

enum ConnectionShape {
	SOLO,
	END,
	STRAIGHT,
	CORNER,
	TEE,
	CROSS,
}

## MeshLibrary item recognised as part of this tiling group but never chosen as repair output.
@export var item_ref := ""
## Connections exposed by the unrotated alternative piece.
@export var connection_shape := ConnectionShape.STRAIGHT
## Clockwise quarter-turn correction applied before the GridMap cell orientation.
@export_range(0, 3, 1) var rotation_offset := 0


## Converts the editor-facing connection shape into the shared autotile variant name.
static func variant_for_connection_shape(shape: ConnectionShape) -> String:
	match shape:
		ConnectionShape.SOLO:
			return PNGToGridMapAutotile.VARIANT_SOLO
		ConnectionShape.END:
			return PNGToGridMapAutotile.VARIANT_END
		ConnectionShape.CORNER:
			return PNGToGridMapAutotile.VARIANT_CORNER
		ConnectionShape.TEE:
			return PNGToGridMapAutotile.VARIANT_TEE
		ConnectionShape.CROSS:
			return PNGToGridMapAutotile.VARIANT_CROSS
		_:
			return PNGToGridMapAutotile.VARIANT_BASE
