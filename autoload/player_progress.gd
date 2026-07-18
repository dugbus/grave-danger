class_name GDPlayerProgress
extends RefCounted

## Persisted level outcomes, recovered treasure, shop stock, and replay cleanup.

const RUN_RECORDING := preload("res://game/run_recording.gd")
const RESULTS_PATH := "user://level_results.json"
const RESULTS_VERSION := 3

var level_results: Dictionary = {}
var treasure_wallet: Dictionary = {}
var shop_purchases: Dictionary = {}
var last_highlighted_level_index := -1
var persistence_enabled := true


func get_level_result(level_id: String) -> Dictionary:
    if level_results.has(level_id):
        var stored_result: Dictionary = level_results[level_id].duplicate()
        var played := bool(stored_result.get("played", false))
        stored_result["best_score"] = int(stored_result.get("best_score", 0))
        stored_result["best_percentage"] = int(stored_result.get("best_percentage", 0))
        stored_result["escaped"] = bool(stored_result.get("escaped", false))
        stored_result["play_count"] = int(
            stored_result.get("play_count", 1 if played else 0)
        )
        stored_result["played"] = played
        stored_result["lit_torches"] = normalize_lit_torches(
            stored_result.get("lit_torches", [])
        )
        stored_result["banked_treasure_counts"] = normalize_count_dictionary(
            stored_result.get("banked_treasure_counts", {})
        )
        return stored_result

    return {
        "best_score": 0,
        "best_percentage": 0,
        "escaped": false,
        "play_count": 0,
        "played": false,
        "lit_torches": [],
        "banked_treasure_counts": {},
    }


func mark_level_started(level_id: String) -> void:
    var result := get_level_result(level_id)
    result["play_count"] = int(result.get("play_count", 0)) + 1
    result["played"] = true
    level_results[level_id] = result


func is_torch_lit(level_id: String, torch_id: StringName) -> bool:
    var result := get_level_result(level_id)
    var lit_torches := normalize_lit_torches(result.get("lit_torches", []))
    return String(torch_id) in lit_torches


func mark_torch_lit(level_id: String, torch_id: StringName) -> bool:
    var result := get_level_result(level_id)
    var lit_torches := normalize_lit_torches(result.get("lit_torches", []))
    var stored_id := String(torch_id)
    if stored_id in lit_torches:
        return false

    lit_torches.append(stored_id)
    result["lit_torches"] = lit_torches
    level_results[level_id] = result
    return true


func reset() -> void:
    level_results.clear()
    treasure_wallet.clear()
    shop_purchases.clear()
    last_highlighted_level_index = -1
    if persistence_enabled:
        RUN_RECORDING.clear_all()


func get_treasure_count(treasure_type: StringName) -> int:
    return maxi(int(treasure_wallet.get(String(treasure_type), 0)), 0)


func add_treasure_bundle(treasure_by_type: Dictionary) -> bool:
    var changed := false
    for stored_type: Variant in treasure_by_type:
        var treasure_type := StringName(stored_type)
        var count := maxi(int(treasure_by_type[stored_type]), 0)
        if treasure_type.is_empty() or count <= 0:
            continue
        treasure_wallet[String(treasure_type)] = get_treasure_count(treasure_type) + count
        changed = true
    return changed


func can_afford_treasure(treasure_type: StringName, amount: int) -> bool:
    return amount >= 0 and get_treasure_count(treasure_type) >= amount


func get_shop_item_purchase_count(item_id: StringName) -> int:
    return maxi(int(shop_purchases.get(String(item_id), 0)), 0)


func purchase_shop_item(
    item_id: StringName,
    treasure_type: StringName,
    amount: int,
    stock_count: int
) -> bool:
    var safe_amount := maxi(amount, 0)
    var purchased_count := get_shop_item_purchase_count(item_id)
    if item_id.is_empty() or treasure_type.is_empty() or stock_count <= purchased_count \
            or not can_afford_treasure(treasure_type, safe_amount):
        return false

    treasure_wallet[String(treasure_type)] = get_treasure_count(treasure_type) - safe_amount
    shop_purchases[String(item_id)] = purchased_count + 1
    return true


func record_level_result(
    level_id: String,
    score: int,
    percentage: int,
    escaped: bool,
    collected_treasure: Dictionary
) -> Dictionary:
    var existing := get_level_result(level_id)
    var existing_escaped := bool(existing.get("escaped", false))
    var best_score := int(existing.get("best_score", 0))
    var best_percentage := int(existing.get("best_percentage", 0))
    if escaped and existing_escaped:
        best_score = maxi(best_score, score)
        best_percentage = maxi(best_percentage, percentage)
    elif escaped:
        best_score = score
        best_percentage = percentage
    elif not existing_escaped:
        best_score = maxi(best_score, score)
        best_percentage = maxi(best_percentage, percentage)

    var banked_counts := normalize_count_dictionary(
        existing.get("banked_treasure_counts", {})
    )
    var newly_recovered := {}
    if escaped:
        var successful_counts := normalize_count_dictionary(collected_treasure)
        var contains_previously_banked_haul := true
        for stored_type: Variant in banked_counts:
            if int(successful_counts.get(stored_type, 0)) < int(banked_counts[stored_type]):
                contains_previously_banked_haul = false
                break

        if contains_previously_banked_haul:
            for stored_type: Variant in successful_counts:
                var previous_count := int(banked_counts.get(stored_type, 0))
                var successful_count := int(successful_counts[stored_type])
                if successful_count > previous_count:
                    newly_recovered[stored_type] = successful_count - previous_count
            banked_counts = successful_counts
            add_treasure_bundle(newly_recovered)

    level_results[level_id] = {
        "best_score": best_score,
        "best_percentage": best_percentage,
        "escaped": existing_escaped or escaped,
        "play_count": int(existing.get("play_count", 0)),
        "played": true,
        "lit_torches": existing.get("lit_torches", []),
        "banked_treasure_counts": banked_counts,
    }
    return newly_recovered


func load_results(level_mapping: Resource) -> void:
    if not FileAccess.file_exists(RESULTS_PATH):
        reset_loaded_state()
        return

    var results_file := FileAccess.open(RESULTS_PATH, FileAccess.READ)
    if results_file == null:
        push_warning("Could not open level results file: %s" % RESULTS_PATH)
        reset_loaded_state()
        return

    var parsed: Variant = JSON.parse_string(results_file.get_as_text())
    if parsed is Dictionary:
        var parsed_results: Dictionary = parsed.get("levels", {})
        level_results = migrate_legacy_results(parsed_results, level_mapping)
        treasure_wallet = normalize_count_dictionary(parsed.get("treasure_wallet", {}))
        shop_purchases = normalize_count_dictionary(parsed.get("shop_purchases", {}))
        last_highlighted_level_index = resolve_saved_highlighted_level_index(
            parsed,
            level_mapping
        )
    else:
        push_warning("Level results file is not valid JSON: %s" % RESULTS_PATH)
        reset_loaded_state()


func save_results(level_mapping: Resource) -> void:
    if not persistence_enabled:
        return

    var results_file := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
    if results_file == null:
        push_warning("Could not write level results file: %s" % RESULTS_PATH)
        return

    results_file.store_string(JSON.stringify({
        "version": RESULTS_VERSION,
        "last_highlighted_level_id": get_level_id(
            level_mapping,
            last_highlighted_level_index
        ),
        "last_highlighted_level_index": last_highlighted_level_index,
        "levels": level_results,
        "treasure_wallet": treasure_wallet,
        "shop_purchases": shop_purchases,
    }, "\t"))


func migrate_legacy_results(stored_results: Dictionary, level_mapping: Resource) -> Dictionary:
    var migrated_results := stored_results.duplicate(true)
    if level_mapping == null:
        return migrated_results

    for index in int(level_mapping.get_level_count()):
        var level_id := get_level_id(level_mapping, index)
        var legacy_key := String(level_mapping.get_legacy_result_key(index))
        if level_id.is_empty() or legacy_key.is_empty() or level_id == legacy_key:
            continue
        if stored_results.has(legacy_key) and not migrated_results.has(level_id):
            migrated_results[level_id] = stored_results[legacy_key]
        migrated_results.erase(legacy_key)

    return migrated_results


func resolve_saved_highlighted_level_index(
    parsed_results: Dictionary,
    level_mapping: Resource
) -> int:
    var highlighted_level_id := String(parsed_results.get("last_highlighted_level_id", ""))
    if not highlighted_level_id.is_empty() and level_mapping != null:
        var highlighted_index := int(level_mapping.find_level_index_by_id(highlighted_level_id))
        if highlighted_index >= 0:
            return highlighted_index

    var legacy_index := int(parsed_results.get(
        "last_highlighted_level_index",
        parsed_results.get("last_played_level_index", -1)
    ))
    if legacy_index < 0 or level_mapping == null:
        return legacy_index

    var legacy_key := "%02d" % (legacy_index + 1)
    var migrated_index := int(level_mapping.find_level_index_by_legacy_result_key(legacy_key))
    return migrated_index if migrated_index >= 0 else legacy_index


func normalize_count_dictionary(stored_value: Variant) -> Dictionary:
    var normalized := {}
    if not stored_value is Dictionary:
        return normalized

    for stored_key: Variant in stored_value:
        var key := String(stored_key)
        var count := maxi(int(stored_value[stored_key]), 0)
        if not key.is_empty() and count > 0:
            normalized[key] = count
    return normalized


func normalize_lit_torches(stored_value: Variant) -> Array[String]:
    var lit_torches: Array[String] = []
    if not stored_value is Array:
        return lit_torches

    for stored_id: Variant in stored_value:
        var torch_id := String(stored_id)
        if not torch_id.is_empty() and torch_id not in lit_torches:
            lit_torches.append(torch_id)
    return lit_torches


func reset_loaded_state() -> void:
    level_results = {}
    treasure_wallet = {}
    shop_purchases = {}
    last_highlighted_level_index = -1


func get_level_id(level_mapping: Resource, index: int) -> String:
    if level_mapping == null or index < 0 or index >= int(level_mapping.get_level_count()):
        return ""
    return String(level_mapping.get_level_id(index))
