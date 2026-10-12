class_name GDAudioPlaybackHost
extends Resource

## Optional host-owned executor; an empty callable keeps normal native audio playback.
## Deterministic hosts can inspect cue requests without starting a hardware decoder.
var executor: Callable


## Returns whether the host handled this cue; otherwise the caller uses native playback.
func execute(player: Node) -> bool:
	if not executor.is_valid():
		return false
	executor.call(player)
	return true
