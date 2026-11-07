extends RefCounted

## Shared ordering contract for transparent world effects and camera-aligned 3D HUD overlays.
## Keep the final slots for dimming and text so world post-processing cannot erase their pixels.
enum DrawPass {
	WorldTreatment = Material.RENDER_PRIORITY_MAX - 3,
	BoundaryVeil = Material.RENDER_PRIORITY_MAX - 2,
	ScreenDim = Material.RENDER_PRIORITY_MAX - 1,
	ScreenText = Material.RENDER_PRIORITY_MAX,
}

const SCREEN_TEXT_VISUAL_LAYER := 1 << 19
