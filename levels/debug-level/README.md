# Rolling slope test

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
