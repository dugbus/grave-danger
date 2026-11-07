extends Resource

## Width of the quick visual fade on the coloured side of the boundary, in metres.
@export_range(0.01, 0.5, 0.01, "suffix:m") var edge_feather := 0.12
## Overall strength of the aged print: 0 keeps the original image, 1 applies the full fade and paper tint.
@export_range(0.0, 1.0, 0.05) var photo_strength := 0.55
## Subtly warm paper white for the aged colour print; keep it near neutral to retain the artwork's hues.
@export var sepia_tint := Color(0.96, 0.94, 0.86)
## Faded, nearly neutral black point, applied equally to scene shadows and empty background on the selected side.
@export var sepia_shadow_tint := Color(0.25, 0.245, 0.235)
## Exposure of the photograph's soft highlight curve; affects the colour print rather than scene lights.
@export_range(0.2, 4.0, 0.05) var sepia_exposure := 1.2
## Fraction of the artwork's chroma retained in the print. 1 keeps full colour; 0 makes a neutral print.
@export_range(0.0, 1.0, 0.05) var colour_retention := 0.95
## Very fine, stationary paper texture. Use 0 for a completely clean print.
@export_range(0.0, 0.2, 0.005) var film_grain_strength := 0.01
## Gentle shading toward the photograph's frame edges; 0 keeps the print evenly exposed.
@export_range(0.0, 0.3, 0.01) var film_vignette_strength := 0.05

## Show an animated veil along the real perimeter so the safe area's edge reads clearly in dark rooms.
@export var veil_enabled := true
## Height of the veil's opacity band above the player's feet, or the boundary base if no player is present.
@export_range(0.3, 4.0, 0.05, "suffix:m") var veil_height := 1.6
## Warm gold and parchment colour of the veil; it is shared by both kill-boundary implementations.
@export var veil_color := Color(0.92, 0.68, 0.32)
## Strength of the veil's transparent wisps and low ribbon. Reduce this to see more of the scene through it.
@export_range(0.0, 1.0, 0.05) var veil_opacity := 0.35
## Brightness of the veil in dark areas, without adding lights or changing the room's lighting.
@export_range(0.1, 4.0, 0.05) var veil_brightness := 1.25
## Scale of the procedural wisps. Higher values add smaller, more closely spaced details.
@export_range(0.2, 5.0, 0.1) var veil_noise_scale := 1.8
## Speed of the flowing, morphing noise. This affects the veil only; 0 keeps its pattern still.
@export_range(0.0, 2.0, 0.05) var veil_morph_speed := 0.4
