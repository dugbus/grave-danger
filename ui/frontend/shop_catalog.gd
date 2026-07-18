class_name GDShopCatalog
extends Resource

## Ordered collection of items offered by the shop.

const SHOP_ITEM_DEFINITION_SCRIPT := preload("res://ui/frontend/shop_item_definition.gd")

## All authored shop items, including entries hidden until they become available.
@export var items: Array[SHOP_ITEM_DEFINITION_SCRIPT] = []


func get_available_items() -> Array[SHOP_ITEM_DEFINITION_SCRIPT]:
    var available_items: Array[SHOP_ITEM_DEFINITION_SCRIPT] = []
    for item in items:
        if item != null and item.availability == SHOP_ITEM_DEFINITION_SCRIPT.Availability.Available:
            available_items.append(item)
    return available_items
