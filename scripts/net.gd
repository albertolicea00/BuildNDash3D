## NetworkManager (autoload "Net").
##
## Handles the three connection modes required by the spec:
##   LOCAL  - single device, no networking at all.
##   HOST   - this instance hosts an offline-LAN game (and also plays).
##   CLIENT - this instance joins a LAN host by local IP.
##
## "Local Server" mode is HOST with strict server-side validation enabled:
## the host then verifies every client request (cooldowns, lanes, types)
## instead of trusting the remote peer. The host also owns procedural track
## generation, speed, obstacles, lane sync and collisions.
extends Node

enum Mode { LOCAL, HOST, CLIENT }

## Each game uses its own port so two games can run on the same LAN
## without clashing. BuildNDash3D = 7804.
const PORT := 7804
const MAX_CLIENTS := 1  # asymmetric co-op: exactly one remote player

var mode: int = Mode.LOCAL
## True when hosting in "Local Server" mode: validate everything server-side.
var strict_validation := false


func start_local() -> void:
	# Replace any previous network peer with an offline one so that
	# local play never touches the network stack.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.LOCAL
	strict_validation = false


func start_host(strict: bool) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	strict_validation = strict
	return OK


func start_client(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	return OK


func is_authority() -> bool:
	# The simulation authority is the local instance (LOCAL) or the host.
	return mode != Mode.CLIENT


func local_ips() -> Array[String]:
	# Return private IPv4 addresses so the host player can read their
	# address to the client player (offline LAN, no discovery service).
	var out: Array[String] = []
	for address in IP.get_local_addresses():
		if address.begins_with("192.168.") or address.begins_with("10.") \
				or address.begins_with("172."):
			out.append(address)
	return out
