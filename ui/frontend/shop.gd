@tool
class_name GDShop
extends "res://ui/frontend/frontend_screen.gd"

## Starter shop screen that keeps an authored reference canvas fitted inside the runtime viewport.

const SHOP_ITEM_ROW_SCENE := preload("res://ui/frontend/shop_item_row.tscn")
const SHOP_STAT_MODIFIER_ROW_SCENE := preload("res://ui/frontend/shop_stat_modifier_row.tscn")
const SHOP_CATALOG_SCRIPT := preload("res://ui/frontend/shop_catalog.gd")
const SHOP_ITEM_DEFINITION_SCRIPT := preload("res://ui/frontend/shop_item_definition.gd")
const SHOP_STAT_MODIFIER_SCRIPT := preload("res://ui/frontend/shop_stat_modifier.gd")
const FOCUS_SCROLL_LIST_SCRIPT := preload("res://ui/frontend/focus_scroll_list.gd")
const LEVEL_SELECT_SCENE_PATH := "res://ui/screens/level_select_screen.tscn"
const ITEM_NAME_MAX_FONT_SIZE := 58
const ITEM_NAME_MEDIUM_FONT_SIZE := 49
const ITEM_NAME_LONG_FONT_SIZE := 42
const ITEM_NAME_MEDIUM_LENGTH := 12
const ITEM_NAME_LONG_LENGTH := 17
const UNAFFORDABLE_ROW_MODULATE := Color(0.43, 0.43, 0.43, 1.0)

## Ordered shop content used to populate the available-item list and selected-item details.
@export var catalog: SHOP_CATALOG_SCRIPT
## Item selected when the shop first appears, when that item is available.
@export var initial_item_id: StringName = &"bone_charm"

var available_items: Array[SHOP_ITEM_DEFINITION_SCRIPT] = []
var item_rows: Array[Button] = []
var selected_item_index := -1
var default_payment_icon: Texture2D
var is_transitioning := false

@onready var available_items_scroll := get_node_or_null(
    ^"ScreenContainer/InventoryFrame/Content/ShopItemsPanel/AvailableItemsScroll"
) as FOCUS_SCROLL_LIST_SCRIPT
@onready var available_items_list := get_node_or_null(
    ^"ScreenContainer/InventoryFrame/Content/ShopItemsPanel/AvailableItemsScroll/ItemsMargin/AvailableItemsList"
) as VBoxContainer
@onready var selected_item_panel := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel"
) as Panel
@onready var item_artwork_texture := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/ItemArtworkTexture"
) as TextureRect
@onready var item_name_label := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/ItemNameLabel"
) as Label
@onready var item_description_label := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/ItemDescriptionLabel"
) as Label
@onready var price_value_label := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/PricePanel/PriceValueLabel"
) as Label
@onready var price_heading_label := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/PricePanel/PriceHeadingLabel"
) as Label
@onready var price_treasure_icon := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/PricePanel/PriceCoinIconTexture"
) as TextureRect
@onready var stat_effects_panel := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/StatEffectsPanel"
) as Panel
@onready var modifier_rows := get_node_or_null(
    ^"ScreenContainer/DetailsFrame/Content/SelectedItemPanel/StatEffectsPanel/ModifierRows"
) as VBoxContainer
@onready var wallet_tiles := get_node_or_null(^"ScreenContainer/WalletTiles") as HBoxContainer
@onready var back_button := get_node_or_null(
    ^"ScreenContainer/BottomActions/BackButton"
) as Button


func _ready() -> void:
    _sync_screen_container()
    if Engine.is_editor_hint():
        return

    default_payment_icon = price_treasure_icon.texture if price_treasure_icon != null else null
    _bind_bottom_actions()
    _populate_available_items()
    _select_initial_item()
    _update_wallet_tiles()


func _input(event: InputEvent) -> void:
    if Engine.is_editor_hint() or available_items_scroll == null:
        return
    if event is InputEventJoypadMotion and available_items_scroll.handle_analog_motion(event):
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton \
            and available_items_scroll.handle_dpad_button(event):
        get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
    if Engine.is_editor_hint() or is_transitioning or not _is_accept_event(event):
        return

    var viewport := get_viewport()
    if back_button.has_focus():
        _return_to_level_select()
    elif selected_item_index >= 0 and selected_item_index < item_rows.size() \
            and item_rows[selected_item_index].has_focus():
        _purchase_selected_item()
    else:
        return
    viewport.set_input_as_handled()


func _populate_available_items() -> void:
    if available_items_list == null:
        return

    for child in available_items_list.get_children():
        available_items_list.remove_child(child)
        child.queue_free()

    available_items.clear()
    item_rows.clear()
    if catalog == null:
        return

    available_items = catalog.get_available_items()
    for index in available_items.size():
        var item := available_items[index]
        var row := SHOP_ITEM_ROW_SCENE.instantiate() as Button
        row.name = "%sItemRow" % item.display_name.to_pascal_case()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.set_meta(&"shop_item_id", item.item_id)
        available_items_list.add_child(row)
        _populate_item_row(row, item)
        row.focus_entered.connect(_on_item_row_focused.bind(index))
        row.mouse_entered.connect(_on_item_row_hovered.bind(index))
        row.button_down.connect(_on_item_row_pressed.bind(index))
        item_rows.append(row)

    if available_items_scroll != null:
        available_items_scroll.configure_rows(
            item_rows,
            back_button,
            back_button,
            [back_button]
        )


func _populate_item_row(row: Button, item: SHOP_ITEM_DEFINITION_SCRIPT) -> void:
    var icon := row.get_node_or_null(^"ItemIconTexture") as TextureRect
    var item_name := row.get_node_or_null(^"ItemNameLabel") as Label
    var summary := row.get_node_or_null(^"ItemSummaryText") as RichTextLabel
    var price := row.get_node_or_null(^"PriceValueLabel") as Label
    var payment_icon := row.get_node_or_null(^"PriceCoinIconTexture") as TextureRect
    var stock_count := row.get_node_or_null(^"StockCountLabel") as Label
    if icon != null:
        icon.texture = item.icon
    if item_name != null:
        item_name.text = item.display_name
    if summary != null:
        summary.text = item.list_summary_bbcode
    if price != null:
        price.text = str(item.price)
    if payment_icon != null and item.payment_icon != null:
        payment_icon.texture = item.payment_icon
    if stock_count != null:
        stock_count.text = "x%d" % _get_remaining_stock(item)

    var can_purchase := _can_purchase_item(item)
    row.set_meta(&"can_purchase", can_purchase)
    row.disabled = false
    row.focus_mode = Control.FOCUS_ALL
    row.modulate = Color.WHITE if can_purchase else UNAFFORDABLE_ROW_MODULATE


func _select_initial_item() -> void:
    if available_items.is_empty():
        selected_item_index = -1
        return

    var initial_index := 0
    for index in available_items.size():
        if available_items[index].item_id == initial_item_id:
            initial_index = index
            break

    selected_item_index = initial_index
    _update_selected_item_details(available_items[initial_index])
    if available_items_scroll != null:
        available_items_scroll.focus_row.call_deferred(initial_index, true)
    else:
        item_rows[initial_index].call_deferred("grab_focus")


func _on_item_row_focused(index: int) -> void:
    _select_item(index)


func _on_item_row_hovered(index: int) -> void:
    if index >= 0 and index < item_rows.size() and not item_rows[index].has_focus():
        item_rows[index].grab_focus()


func _on_item_row_pressed(index: int) -> void:
    if index >= 0 and index < item_rows.size():
        item_rows[index].grab_focus()
        _select_item(index)
        _purchase_selected_item()


func _select_item(index: int) -> void:
    if index < 0 or index >= available_items.size():
        return
    selected_item_index = index
    _update_selected_item_details(available_items[index])


func _can_purchase_item(item: SHOP_ITEM_DEFINITION_SCRIPT) -> bool:
    var level_selection := _get_level_selection()
    return item != null and _get_remaining_stock(item) > 0 \
        and level_selection != null \
        and level_selection.can_afford_treasure(item.payment_treasure_type, item.price)


func _get_remaining_stock(item: SHOP_ITEM_DEFINITION_SCRIPT) -> int:
    if item == null:
        return 0
    var level_selection := _get_level_selection()
    var purchased_count := level_selection.get_shop_item_purchase_count(item.item_id) \
        if level_selection != null else 0
    return maxi(item.stock_count - purchased_count, 0)


func _update_selected_item_details(item: SHOP_ITEM_DEFINITION_SCRIPT) -> void:
    if selected_item_panel != null:
        selected_item_panel.modulate = Color.WHITE \
            if _can_purchase_item(item) else UNAFFORDABLE_ROW_MODULATE
    if item_artwork_texture != null:
        item_artwork_texture.texture = item.detail_texture if item.detail_texture != null else item.icon
    if item_name_label != null:
        item_name_label.text = item.display_name.to_upper()
        _fit_item_name(item_name_label.text.length())
    if item_description_label != null:
        item_description_label.text = item.description
    if price_value_label != null:
        price_value_label.text = str(item.price)
    if price_heading_label != null:
        price_heading_label.text = "PRICE: %s" % item.payment_treasure_name
    if price_treasure_icon != null:
        price_treasure_icon.texture = item.payment_icon \
            if item.payment_icon != null else default_payment_icon

    _populate_modifier_rows(item.stat_modifiers)


func _bind_bottom_actions() -> void:
    if back_button != null:
        back_button.focus_mode = Control.FOCUS_ALL
        back_button.button_down.connect(_return_to_level_select)
        back_button.mouse_entered.connect(back_button.grab_focus)


func _purchase_selected_item() -> void:
    if selected_item_index < 0 or selected_item_index >= available_items.size():
        return

    var item := available_items[selected_item_index]
    var level_selection := _get_level_selection()
    if level_selection == null or not level_selection.purchase_shop_item(
        item.item_id,
        item.payment_treasure_type,
        item.price,
        item.stock_count
    ):
        return

    var frontend_audio: Node = get_node_or_null("/root/FrontendAudio")
    if frontend_audio != null:
        frontend_audio.call("play_purchase")

    for index in available_items.size():
        _populate_item_row(item_rows[index], available_items[index])
    _update_selected_item_details(item)
    _update_wallet_tiles()


func _update_wallet_tiles() -> void:
    if wallet_tiles == null:
        return

    var level_selection := _get_level_selection()
    var visible_tile_count := 0
    for tile: Control in wallet_tiles.get_children():
        var treasure_type := tile.get_meta(&"treasure_type", &"") as StringName
        var quantity_label := tile.get_node_or_null(^"TreasureQuantityLabel") as Label
        if treasure_type.is_empty() or quantity_label == null:
            tile.visible = false
            continue
        var count := level_selection.get_treasure_count(treasure_type) \
            if level_selection != null else 0
        quantity_label.text = "x%d" % count
        tile.visible = count > 0
        if tile.visible:
            visible_tile_count += 1
    wallet_tiles.visible = visible_tile_count > 0


func _get_level_selection() -> GDLevelSelection:
    return get_node_or_null("/root/LevelSelection") as GDLevelSelection


func _return_to_level_select() -> void:
    if is_transitioning:
        return
    _play_select_sound()
    is_transitioning = true
    var change_error := get_tree().change_scene_to_file(LEVEL_SELECT_SCENE_PATH)
    if change_error != OK:
        is_transitioning = false
        push_error("Could not leave Shop: %s" % error_string(change_error))
func _fit_item_name(character_count: int) -> void:
    if item_name_label == null or item_name_label.label_settings == null:
        return

    var font_size := ITEM_NAME_MAX_FONT_SIZE
    if character_count > ITEM_NAME_LONG_LENGTH:
        font_size = ITEM_NAME_LONG_FONT_SIZE
    elif character_count > ITEM_NAME_MEDIUM_LENGTH:
        font_size = ITEM_NAME_MEDIUM_FONT_SIZE

    var settings := item_name_label.label_settings.duplicate() as LabelSettings
    settings.font_size = font_size
    item_name_label.label_settings = settings


func _populate_modifier_rows(modifiers: Array[SHOP_STAT_MODIFIER_SCRIPT]) -> void:
    if modifier_rows == null:
        return

    for child in modifier_rows.get_children():
        modifier_rows.remove_child(child)
        child.queue_free()

    if stat_effects_panel != null:
        stat_effects_panel.visible = not modifiers.is_empty()

    for index in modifiers.size():
        var modifier := modifiers[index]
        if modifier == null:
            continue

        var row := SHOP_STAT_MODIFIER_ROW_SCENE.instantiate() as Panel
        row.name = "%sModifierRow%d" % [modifier.display_name.to_pascal_case(), index + 1]
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        modifier_rows.add_child(row)

        var icon := row.get_node_or_null(^"ModifierIconTexture") as TextureRect
        var modifier_name := row.get_node_or_null(^"ModifierNameLabel") as Label
        var modifier_value := row.get_node_or_null(^"ModifierValueLabel") as Label
        if icon != null:
            icon.texture = modifier.icon
        if modifier_name != null:
            modifier_name.text = modifier.display_name
            _set_label_color(modifier_name, modifier.display_color)
        if modifier_value != null:
            modifier_value.text = modifier.value_text
            _set_label_color(modifier_value, modifier.display_color)


func _set_label_color(label: Label, color: Color) -> void:
    if label.label_settings == null:
        label.add_theme_color_override(&"font_color", color)
        return

    var settings := label.label_settings.duplicate() as LabelSettings
    settings.font_color = color
    label.label_settings = settings
