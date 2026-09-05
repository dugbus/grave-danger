# Churchyard glTF export

Export `churchyard.blend` using Blender's built-in **File → Export → glTF 2.0**
exporter. Save to `Assets/churchyard/churchyard.gltf`, relative to the project root.
These settings produced the working title-screen camera animation.

## Blender scene

- Keep the camera named **Camera**. The Godot scene uses that node and its exported
  animation name.
- Keep the camera's **Follow Path** and **Track To** constraints enabled.
- The current authored playback range is **1–250**, at **24 fps**. Preserve the
  authored range and frame rate when exporting.

## Export settings

| Setting | Value |
| --- | --- |
| Format | **glTF Separate (.gltf + .bin + textures)** |
| Selected Objects | **Off**, to include the whole cinematic |
| Cameras | **On** |
| Punctual Lights | **On** |
| Lighting Mode | **Unitless** (compatibility mode) |
| +Y Up | **On** |
| Materials | **Export**, including textures |
| Keep Original (textures) | **Off**, so packed images are exported |
| Animations | **On** |
| Animation Mode | **Scene** |
| Split Animation by Object | **On**, producing the animation named `Camera` |
| Limit to Playback Range | **On** |
| Always Sample Animations | **On**; Scene mode may enforce this automatically |
| Sampling Rate | **1**, meaning evaluate every frame |

**Unitless** lighting matches this project's Godot lighting setup. Standard
lighting exported the sun at energy 683 instead of 1, washing out the scene
and making its textures appear missing.

**Scene** mode exports the evaluated camera motion, including its path and tracking
constraints. The earlier export contained the camera but no animation tracks.
No custom Python exporter or separate camera animation resource is needed.

Keep `churchyard.gltf`, `churchyard.bin`, and the referenced `Image_*.jpg` textures
together when sharing or committing the export. Let Godot reimport after exporting.

## Godot setup and verification

The committed `churchyard.gltf.import` settings use **24 fps**, set the `Camera`
animation's loop mode to **Linear**, and disable the AnimationPlayer's optimizer
to retain the sampled camera motion.

The scene at `ui/screens/churchyard_cinematic/churchyard_cinematic.tscn` instances
this glTF, makes its camera current, and autoplays its imported `Camera` animation.
The title screen displays that cinematic.

After re-exporting, confirm the imported AnimationPlayer contains `Camera` with
position and rotation tracks. Run the project and check that the camera moves,
keeps its authored aim, and repeats the orbit. If you intentionally rename the
camera or change the frame rate, update the corresponding Godot scene/import
settings and title-screen tests as well.
