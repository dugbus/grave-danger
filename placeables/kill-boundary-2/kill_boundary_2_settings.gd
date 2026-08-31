class_name GDKillBoundary2Settings
extends Resource

## Shared game-wide presentation, collision, damage, blocker, and audio tuning.

enum RenderEffect {
	Flame,
	Ghost,
	None,
}

## Controls how smoothly rounded boundaries are drawn. Raise this when curves look faceted; lower
## it when fewer visual and collision pieces are more important than smooth curves.
@export_range(8, 128, 1) var boundary_segments := 32
## Sets how high the visible wall and damaging area reach above the boundary base. Raise this for
## taller characters or a more imposing wall.
@export_range(0.05, 10.0, 0.05) var flame_height := 1.55
## Moves the entire boundary up or down. Change this when the level floor is above or below the
## boundary node's height.
@export var flame_y := 0.0
## Sets how wide the damaging strip is around the boundary line. Increase it to make the edge less
## forgiving, or reduce it when damage should closely match the visible line.
@export_range(0.01, 5.0, 0.01) var flame_thickness := 0.18
## Sets how far the flame artwork spreads across the ground without changing the damaging width.
## Increase it for broader-looking flames.
@export_range(0.1, 3.0, 0.05) var flame_visual_depth := 0.7
## Makes the flames more transparent or solid. Lower this for a subtle boundary; 0 hides the flame
## artwork without disabling damage.
@export_range(0.0, 1.0, 0.01) var flame_effect_opacity := 1.0
## Controls how busy and filled-in the flame pattern looks. Raise it for denser flames or lower it
## for larger, more open gaps.
@export_range(0.1, 8.0, 0.05) var flame_effect_density := 3.1
## Controls how brightly the flames glow, especially in dark areas. This changes appearance only,
## not how much damage the boundary causes.
@export_range(0.0, 20.0, 0.1) var flame_effect_emission := 7.0
## Controls how quickly the flame pattern moves. Lower values make calmer flames; higher values make
## them flicker and flow faster. 0 freezes the pattern.
@export_range(0.0, 2.0, 0.01) var flame_effect_time_scale := 0.72
## Sets the colour of the hottest, brightest part of each flame.
@export var flame_effect_core_color := Color(1.0, 0.92, 0.42)
## Sets the main colour between the bright core and dark outer edge of each flame.
@export var flame_effect_mid_color := Color(1.0, 0.28, 0.015)
## Sets the colour around the cooler outside edge of each flame.
@export var flame_effect_outer_color := Color(0.48, 0.008, 0.001)
## Tints every ghost on the boundary. Change this to match the level's mood or lighting.
@export var ghost_effect_color := Color(0.58, 0.9, 1.0)
## Controls how brightly ghosts glow, especially in dark areas. This changes appearance only,
## not damage.
@export_range(0.0, 20.0, 0.1) var ghost_effect_emission := 6.2
## Controls how softly ghosts fade at their edges. Raise it for mistier ghosts or lower it for
## sharper silhouettes.
@export_range(0.0, 1.0, 0.01) var ghost_effect_edge_softness := 0.28
## Controls how crowded the boundary is with ghosts. Higher values add more ghosts around the full
## perimeter; 0 hides the ghosts without disabling damage.
@export_range(0, 8, 1) var ghost_ribbons_per_segment := 5
## Sets the shortest and tallest ghost heights. Widen the range for more visual variety.
@export var ghost_height_range := Vector2(2.0, 3.45)
## Sets the narrowest and widest ghost sizes. Widen the range for more visual variety.
@export var ghost_width_range := Vector2(0.22, 0.52)
## Sets how far ghosts rise during their animation. Increase it for a stronger upward sweep or
## reduce it to keep ghosts close to the ground.
@export_range(0.0, 4.0, 0.05) var ghost_rise_distance := 1.3
## Sets how far ghosts sway sideways. Increase it for restless movement or reduce it for steadier
## ghosts.
@export_range(0.0, 2.0, 0.01) var ghost_wave_amplitude := 0.14
## Places the invisible player barrier farther outside the damaging line. Increase it to keep players
## farther from the edge, or use 0 to centre the barrier on the hazard.
@export_range(0.0, 3.0, 0.01) var player_blocking_outset := 1.0
## Sets how thick the invisible player barrier is. Increase it when fast players can slip through;
## it does not change the visible boundary or damage width.
@export_range(0.01, 3.0, 0.01) var player_blocking_thickness := 0.75
## Sets how high the invisible player barrier reaches. Raise it for tall or jumping players; it does
## not change the visible boundary height.
@export_range(0.05, 10.0, 0.05) var player_blocking_height := 1.6
## Sets how quickly players lose flame energy while touching the boundary. Raise it for a harsher
## hazard or lower it to give players more time to escape.
@export var flame_damage_per_second := 35.0
## Sets how far damage reaches inside the playable area. Increase it to punish players before they
## fully cross the visible edge.
@export var flame_damage_inner_depth := 0.35
## Sets how far beyond the edge damage takes to grow from normal to maximum. Increase it for a more
## gradual danger increase; reduce it for a sudden punishment outside.
@export var outside_damage_ramp_depth := 0.65
## Caps how much stronger damage becomes outside the boundary. Raise it to kill escaped players more
## quickly, or lower it for a more forgiving exterior.
@export var max_outside_damage_multiplier := 6.0
## Extends damage above and below the visible wall. Increase it when jumping or uneven ground lets
## players avoid damage near the boundary.
@export var flame_damage_vertical_margin := 0.75
## Sets how far from a flame boundary its sound begins to fade in. Increase it for earlier warning or
## reduce it so the sound is heard only near the danger.
@export var near_flame_audio_distance := 4.0
## Sets the sound volume at the outer edge of the listening distance. More negative values are quieter.
@export var near_flame_audio_min_db := -55.0
## Sets the sound volume when standing on the boundary. Higher values are louder.
@export var near_flame_audio_max_db := 4.0
## Shapes how volume grows while approaching. Values below 1 make the warning audible earlier;
## values above 1 keep it quieter until the player is close.
@export_range(0.1, 3.0, 0.05) var near_flame_audio_curve := 0.45
## Controls how quickly sound follows the player's distance. Raise it for immediate volume changes
## or lower it for smoother, slower fades.
@export var near_flame_audio_lag := 8.0
