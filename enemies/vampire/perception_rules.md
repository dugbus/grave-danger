# Vampire perception rules

The Vampire may choose actions from only these evidence sources:

- **Entrance:** the level supplies the authored player entrance position once during
  configuration. This is an event position, not permission to follow the live player.
- **Ordinary sound:** the sound emitter supplies one world position. It carries no
  landmark identity and cannot read or refresh from the player's transform.
- **Landmark sound:** the event supplies one world position and may associate it with
  a nearby authored landmark, such as a key or coffin. It reveals no inventory or
  objective state beyond the event that was actually heard.
- **Direct sight:** `GDVampireSenses` may sample the player's collision geometry to
  decide current visibility. Only after visibility is confirmed may hunt logic read
  the current player position and update observed velocity.

After sight is lost, the grace period, prediction, and searches use retained confirmed
positions and velocities. They must not read the live player position. Visibility
checks may rule out a candidate only from the Vampire's current view; moving away can
make that candidate plausible again because ruled-out positions are not stored
permanently.

Evidence priority is current sight, sight-loss grace, an accepted recent sound,
last-seen prediction, an old sound's expanding uncertainty area, then strategic
landmark or exit patrol. Sounds cannot interrupt current sight or its grace period.
