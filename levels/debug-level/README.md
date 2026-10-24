# Debug-level checks

## Skeleton and crumbling floor

Stay at the player landing point and watch the raised platform immediately to
the right, towards the camera: X=116–118, Z=1–3, with its walkable top at 2m.
The skeleton appears after four seconds and steps onto the cracked centre tile
at about five to six seconds on the elapsed timer. The tile cracks and collapses,
and the skeleton falls into the hole without the player touching it. Restart the
level to repeat the demonstration.

Select `Objects/SkeletonCrumblingDemo` in the level scene to edit the patrol and
tile. The platform is authored in `floor_surface_map.tres`; the centre cell is a
real hole with retained 2m elevation, covered by the crumbling-floor scene. The
player's landing point and existing debug props remain outside the raised floor.

## Rolling slope

The two-cell-wide rolling slope sits north of the pickup display near spawn,
between X=99–111 and Z=-5–-4. Select `Objects/RollingSlope` in the level scene
to find its boulder, millstone and four crumbling landing tiles.

Walk up the side approach at X=110–111, Z=-1–-3 to reach the raised starting
pad. Get east of either stone and push west towards the main slope. Both
stones descend under gravity, roll across the short flat apron, and trigger
the crumbling landing at the bottom. Restart the level to reset the test.

The ramps and raised pad are authored in the existing `FloorSurface` map.
The landing uses actual floor holes with crumbling tile scenes above them.
The demo boulder has `constrain_to_starting_height` disabled so it follows
the slope and falls when its support collapses.
