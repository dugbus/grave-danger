class_name GDShopItemDefinition
extends Resource

## Data needed to list and preview one purchasable shop item.

const SHOP_STAT_MODIFIER_SCRIPT := preload("res://ui/frontend/shop_stat_modifier.gd")

enum Availability {
    Available,
    Unavailable,
}

## Stable identifier used to select and save this shop item.
@export var item_id: StringName
## Human-friendly name shown in the shop list and details panel.
@export var display_name := "Shop Item"
## Rich-text summary shown beneath the item name in the shop list.
@export_multiline var list_summary_bbcode := "[color=#70bf45]+1 Strength[/color]"
## Longer description shown when this item is selected.
@export_multiline var description := "A mysterious upgrade from beyond the grave."
## Number of the selected payment treasure required to buy this item.
@export_range(0, 9999, 1) var price := 0
## Stable deposited-treasure type accepted as payment for this item.
@export var payment_treasure_type: StringName = &"gold_coin"
## Human-friendly plural payment name shown beside the amount.
@export var payment_treasure_name := "GOLD COINS"
## Currency icon used by list and detail price displays; missing art keeps the scene fallback.
@export var payment_icon: Texture2D
## Number of this upgrade currently held by the shop.
@export_range(0, 999, 1) var stock_count := 5
## Controls whether this item is included when the shop list is built.
@export var availability := Availability.Available
## Small image displayed in the scrolling shop list.
@export var icon: Texture2D
## Large artwork displayed in the selected-item details.
@export var detail_texture: Texture2D
## Gameplay effects described in the selected-item details.
@export var stat_modifiers: Array[SHOP_STAT_MODIFIER_SCRIPT] = []
