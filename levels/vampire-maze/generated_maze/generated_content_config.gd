@tool
class_name GDGeneratedDungeonContentConfig
extends Resource

## Strategic content budgets and difficulty controls for a generated maze.

@export_group("Treasure Piles")
## Exact number of separate treasure piles placed through the generated dungeon.
@export_range(0, 256, 1) var treasure_pile_count := 8:
    set(value):
        if treasure_pile_count == value:
            return
        treasure_pile_count = value
        emit_changed()
## Minimum number of gold coins placed in each generated treasure pile.
@export_range(0, 500, 1) var minimum_coins_per_pile := 3:
    set(value):
        if minimum_coins_per_pile == value:
            return
        minimum_coins_per_pile = value
        emit_changed()
## Maximum number of gold coins placed in each generated treasure pile.
@export_range(0, 500, 1) var maximum_coins_per_pile := 8:
    set(value):
        if maximum_coins_per_pile == value:
            return
        maximum_coins_per_pile = value
        emit_changed()
## Minimum centre-to-centre tile spacing preferred between generated treasure piles.
@export_range(1, 12, 1, "suffix: tiles") var minimum_treasure_pile_spacing_tiles := 3:
    set(value):
        if minimum_treasure_pile_spacing_tiles == value:
            return
        minimum_treasure_pile_spacing_tiles = value
        emit_changed()
## Percentage of treasure piles kept directly on the best route to the exit.
@export_range(0.0, 100.0, 1.0, "suffix:%") var main_path_treasure_percent := 25.0:
    set(value):
        if is_equal_approx(main_path_treasure_percent, value):
            return
        main_path_treasure_percent = value
        emit_changed()
@export_group("")

@export_group("Grass Patches")
## Enables deterministic patches of Level 1-style grass across walkable maze cells.
@export var grass_enabled := true:
    set(value):
        if grass_enabled == value:
            return
        grass_enabled = value
        emit_changed()
## Percentage of eligible walkable floor cells selected by the plasma field.
@export_range(0.0, 100.0, 1.0, "suffix:%") var grass_coverage_percent := 24.0:
    set(value):
        var clamped_value := clampf(value, 0.0, 100.0)
        if is_equal_approx(grass_coverage_percent, clamped_value):
            return
        grass_coverage_percent = clamped_value
        emit_changed()
## Approximate width of each coherent grass patch in maze tiles.
@export_range(1.0, 16.0, 0.5, "suffix: tiles") var grass_patch_size_tiles := 4.5:
    set(value):
        var clamped_value := maxf(value, 1.0)
        if is_equal_approx(grass_patch_size_tiles, clamped_value):
            return
        grass_patch_size_tiles = clamped_value
        emit_changed()
## Maximum grass-blade frequency at the densest point of a plasma patch.
@export_range(1, 64, 1, "suffix: blades/cell") var grass_blades_per_cell := 32:
    set(value):
        var clamped_value := maxi(value, 1)
        if grass_blades_per_cell == clamped_value:
            return
        grass_blades_per_cell = clamped_value
        emit_changed()
## Extra cell clearance around the principal gate route where grass is omitted.
@export_range(0, 4, 1, "suffix: tiles") var grass_route_clearance_tiles := 0:
    set(value):
        var clamped_value := maxi(value, 0)
        if grass_route_clearance_tiles == clamped_value:
            return
        grass_route_clearance_tiles = clamped_value
        emit_changed()
@export_group("")

@export_group("Additional Treasure Budgets")
## Number of diamonds distributed through the generated dungeon.
@export_range(0, 500, 1) var diamond_budget := 3:
    set(value):
        if diamond_budget == value:
            return
        diamond_budget = value
        emit_changed()
## Number of rubies distributed through the generated dungeon.
@export_range(0, 500, 1) var ruby_budget := 2:
    set(value):
        if ruby_budget == value:
            return
        ruby_budget = value
        emit_changed()
## Number of sapphires distributed through the generated dungeon.
@export_range(0, 500, 1) var sapphire_budget := 3:
    set(value):
        if sapphire_budget == value:
            return
        sapphire_budget = value
        emit_changed()
## Number of emeralds distributed through the generated dungeon.
@export_range(0, 500, 1) var emerald_budget := 2:
    set(value):
        if emerald_budget == value:
            return
        emerald_budget = value
        emit_changed()
## Number of amethysts distributed through the generated dungeon.
@export_range(0, 500, 1) var amethyst_budget := 4:
    set(value):
        if amethyst_budget == value:
            return
        amethyst_budget = value
        emit_changed()
## Number of heavy gold bars distributed through the generated dungeon.
@export_range(0, 100, 1) var gold_bar_budget := 2:
    set(value):
        if gold_bar_budget == value:
            return
        gold_bar_budget = value
        emit_changed()
@export_group("")

@export_group("Encumbrance and Coffins")
## Carry capacity assumed while deriving how many deposit coffins are required.
@export_range(1.0, 500.0, 1.0) var assumed_carry_capacity := 100.0:
    set(value):
        if is_equal_approx(assumed_carry_capacity, value):
            return
        assumed_carry_capacity = value
        emit_changed()
## Target percentage of the sack filled between deposits; higher values are harder.
@export_range(10.0, 100.0, 1.0, "suffix:%") var target_carry_load_percent := 75.0:
    set(value):
        if is_equal_approx(target_carry_load_percent, value):
            return
        target_carry_load_percent = value
        emit_changed()
## Minimum number of reachable coffin deposits distributed through the maze.
@export_range(1, 16, 1) var minimum_coffin_count := 1:
    set(value):
        if minimum_coffin_count == value:
            return
        minimum_coffin_count = value
        emit_changed()
## Preferred centre-to-centre spacing between generated coffin deposits.
@export_range(1, 24, 1, "suffix: tiles") var minimum_coffin_spacing_tiles := 8:
    set(value):
        if minimum_coffin_spacing_tiles == value:
            return
        minimum_coffin_spacing_tiles = value
        emit_changed()
## Preferred centre-to-centre clearance between coffins and treasure piles.
@export_range(1, 12, 1, "suffix: tiles") var preferred_coffin_treasure_clearance_tiles := 3:
    set(value):
        if preferred_coffin_treasure_clearance_tiles == value:
            return
        preferred_coffin_treasure_clearance_tiles = value
        emit_changed()
@export_group("")

@export_group("Locked Doors")
## Number of sequential locked doors placed across guaranteed route cut points.
@export_range(0, 12, 1) var door_count := 2:
    set(value):
        if door_count == value:
            return
        door_count = value
        emit_changed()
## Percentage chance that each door key is hidden away from the best route.
@export_range(0.0, 100.0, 1.0, "suffix:%") var key_off_path_percent := 40.0:
    set(value):
        if is_equal_approx(key_off_path_percent, value):
            return
        key_off_path_percent = value
        emit_changed()
## Minimum best-route cells kept between generated locked doors.
@export_range(3, 24, 1) var minimum_door_spacing := 6:
    set(value):
        if minimum_door_spacing == value:
            return
        minimum_door_spacing = value
        emit_changed()
@export_group("")

@export_group("Bat Noise")
## Number of bat nests placed as player-noise hazards.
@export_range(0, 24, 1) var bat_nest_count := 3:
    set(value):
        if bat_nest_count == value:
            return
        bat_nest_count = value
        emit_changed()
## Percentage of bat nests placed off the best route; higher values are harder.
@export_range(0.0, 100.0, 1.0, "suffix:%") var bat_off_path_percent := 35.0:
    set(value):
        if is_equal_approx(bat_off_path_percent, value):
            return
        bat_off_path_percent = value
        emit_changed()
@export_group("")
