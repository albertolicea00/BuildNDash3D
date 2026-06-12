## Entry point: main menu and session lifecycle for the three modes.
## Builds all UI in code (low-poly flat style, no external assets).
extends Node

const GameScript := preload("res://scripts/game.gd")
const TITLE := "BUILD N DASH 3D"

var menu: Control
var status: Label
var ip_edit: LineEdit
var game: Node3D


func _ready() -> void:
	_build_menu()
	# Session lifecycle signals (shared by host and client).
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(
		func() -> void: status.text = "Connected. Waiting for host to start...")
	multiplayer.connection_failed.connect(
		func() -> void: _back_to_menu("Connection failed."))
	multiplayer.server_disconnected.connect(
		func() -> void: _back_to_menu("Host disconnected."))


func _build_menu() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.14, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	menu = CenterContainer.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	menu.add_child(box)

	var title := Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Asymmetric co-op: Track Builder shapes the track, Runner dodges in 3 lanes."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	box.add_child(_menu_button("Local Play (same device)", _on_local))
	box.add_child(_menu_button("Host LAN Game", _on_host.bind(false)))
	box.add_child(_menu_button("Host Local Server (validated)", _on_host.bind(true)))

	# Join row: IP field + button (offline LAN, manual IP entry).
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 8)
	box.add_child(join_row)
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Host IP (e.g. 192.168.1.10)"
	ip_edit.custom_minimum_size = Vector2(280, 44)
	join_row.add_child(ip_edit)
	join_row.add_child(_menu_button("Join", _on_join))

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status)


func _menu_button(text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(380, 48)
	btn.pressed.connect(handler)
	return btn


# --- Mode selection -------------------------------------------------------

func _on_local() -> void:
	Net.start_local()
	_start_game()


func _on_host(strict: bool) -> void:
	var err := Net.start_host(strict)
	if err != OK:
		status.text = "Could not host (port busy?). Error %d" % err
		return
	var ips := ", ".join(Net.local_ips())
	var label := "Local Server" if strict else "LAN"
	status.text = "%s hosting on: %s\nWaiting for the Track Builder to join..." % [label, ips]


func _on_join() -> void:
	var ip := ip_edit.text.strip_edges()
	if not ip.is_valid_ip_address():
		status.text = "Enter a valid IPv4 address."
		return
	var err := Net.start_client(ip)
	status.text = "Connecting to %s..." % ip if err == OK else "Failed to start client."


# --- Session lifecycle ----------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	# The host starts the match as soon as the single client arrives.
	if Net.mode == Net.Mode.HOST and game == null:
		_start_game_remote.rpc()
		_start_game()


func _on_peer_disconnected(_id: int) -> void:
	if game != null:
		_back_to_menu("Player disconnected.")


@rpc("authority", "call_remote", "reliable")
func _start_game_remote() -> void:
	_start_game()


func _start_game() -> void:
	menu.hide()
	game = GameScript.new()
	game.name = "Game"  # identical node path on host and client (required for RPCs)
	game.exited.connect(func() -> void: _back_to_menu(""))
	add_child(game)


func _back_to_menu(message: String) -> void:
	if game != null:
		game.queue_free()
		game = null
	Net.start_local()  # tear down any network peer
	menu.show()
	status.text = message
