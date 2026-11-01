# Elevator

Instance `elevator.tscn` into a level and assign its Floor Surface when discovery is ambiguous.
Like a crumbling floor, it snaps to the containing cell centre and the lowest of eight
surrounding flat floors after a horizontal move. Vertical edits remain manual; Auto Place
can be disabled, and Match Floor Height adjusts only Y. Placement supports undo/redo and
never edits the floor map. Author an empty shaft explicitly with the floor painter.

The slab uses the floor cell's top and wall materials. Its distinct surrounding flat-floor
heights become landings. Missing tiles and ramps do not add stops; fewer than two different
heights leaves it stationary. A manually authored initial Y is preserved until travel starts.

Choose Travel Mode in the Inspector:

- **Automatic With Pauses:** shuttle continuously, pausing at each landing.
- **Automatic Continuous:** shuttle without pausing at intermediate or endpoint landings.
- **Player Activated:** start on grounded boarding and use Boarding Behaviour below.

Player-activated Boarding Behaviour offers:

- **While Occupied:** shuttle while aboard; finish the current leg after leaving.
- **Return Trip:** visit the opposite endpoint and return to the boarding landing.
- **Next Landing:** advance one stop, then wait for the player to leave and board again.

Shared tuning lives in `elevator_settings.tres`: 0.75 m/s, one-second landing pauses, and a
0.25 m slab thickness. Each setting has an Inspector description.

Put decorative children or item scenes under `Platform/Contents`. Authored physics items
detach at runtime, preserving their scene ownership, and use the same support detection
as independently placed or dropped items. Active bodies ride through physics; frozen
pickups receive the actual platform displacement. Collected or departed items stop riding.
Players retain their normal walking and jumping controls.

The elevator reverses before hitting an obstacle or squeezing a supported passenger.
Contact alone does not collapse a crumbling floor. If both directions are blocked it
waits safely, retrying until clearance returns.

The debug level has seven labelled stations under `Objects/ElevatorTests`. Station 1 is
west of the existing raised demonstration. Stations 2–7 run west to east along the south
side: continuous three-height travel, occupied travel, return trip, one landing per boarding,
crumbling-floor obstruction, and overhead rider protection. Restart to restore pickups
and crumbling floors.
