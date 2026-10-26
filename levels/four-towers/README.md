# Four Towers

Open `levels/four-towers/level.tscn` in Godot to edit this blank starting level.
It is also available as **Four Towers** in level selection.

- **FloorSurface** supplies a flat 32 by 32 ground area, centered on the origin.
  Select it to use the floor editing tools. Its map and style resources belong
  to this level, so changes leave other levels alone.
- **PlacementGridMap** is empty and uses the existing graveyard mesh library.
  Paint walls and other grid pieces here. Brush strokes painted on layer **0**
  anchor their mesh base to the lowest supporting floor under their rotated
  footprint when the stroke finishes. Pieces stay upright and can intersect the
  uphill floor. Height rounds downward to a 1 cm vertical grid step to avoid gaps.
  Undo and redo include the height adjustment in the original stroke.
  The native eraser removes these raised pieces through the same brush layer.
  Choose another height layer, or disable **Follow Floor**, for manual placement.
  Completed floor height and ramp edits also move pieces seated on the previous
  floor. Floor and scenery changes share one undo step; manual height offsets
  stay where you placed them. Missing floor or an occupied destination leaves
  the piece in place and reports a warning.
  Older centre-height placements are reseated on the next floor edit, or you
  can repaint one to correct it immediately.
- **Objects** is an empty container for reusable placeable scenes, enemies,
  treasure, and any other objects you add.
- **Player** sets the starting position. Move it onto your intended starting tile.
- **OutdoorLighting** and **LevelSettings** provide the normal lighting and
  level options.

To paint, select **FloorSurface** in the scene tree and enable editing in the
**Floor Surface** dock. Use **Floor Shape → Paint floor** with **Brush** or
**Rectangle** to extend the ground beyond the starting square. The square is
already filled; painting inside it leaves its shape unchanged. Choose
**Erase / make hole** to remove floor.

After editing the floor, click **Save Map** in the Floor Surface dock to save its
shape, elevation, ramps, and painted styles. Save the scene separately to keep
fences and other placed objects; the floor map is stored in its own resource file.
Automatic scenery adjustments mark the edited scene as unsaved too.

To change floor type, select **Style**, choose **Dirt** or **Flagstones** from
**Surface style**, then use **Paint Style** with the brush or rectangle. The
palette resources are local to Four Towers and can be edited in the Inspector.

The template starts with no encounters, objectives, or moving boundary.
