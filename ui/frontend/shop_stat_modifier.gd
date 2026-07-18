class_name GDShopStatModifier
extends Resource

## One named gameplay effect displayed for a shop item.

## Human-friendly effect name shown in the selected-item details.
@export var display_name := "STRENGTH"
## Value text shown beside the effect, such as "+1" or "ON".
@export var value_text := "+1"
## Icon displayed beside this effect.
@export var icon: Texture2D
## Colour used for both the effect name and value.
@export var display_color := Color(0.43, 0.75, 0.25, 1.0)
