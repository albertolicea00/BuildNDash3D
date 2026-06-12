## Player A controller: the Track Builder. Picks an object type, then drops
## it on a lane ahead of the Runner using the HUD lane buttons (built by the
## game world). Placement has a cooldown; the authoritative check lives in
## the game world ("Local Server" strict validation).
class_name TrackBuilder
extends Node

const COOLDOWN := 2.5

## Object types the Track Builder can drop, matching the spec:
## obstacles, trains, ramps and power-ups.
enum Kind { LOW_BARRIER, HIGH_BARRIER, TRAIN, RAMP, SHIELD }

signal place_requested(lane: int, kind: int)

var kind: int = Kind.LOW_BARRIER
var cooldown_left := 0.0
var active := true


func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


## Called by the HUD lane buttons. Emits only when off cooldown.
func request_drop(lane: int) -> void:
	if not active or cooldown_left > 0.0:
		return
	cooldown_left = COOLDOWN
	place_requested.emit(lane, kind)
