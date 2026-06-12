## BuildNDash3D game world. See AGENTS.md for the full spec.
##
## Authority model:
##   - LOCAL / HOST: this node owns procedural track generation, speed,
##     obstacles, lane sync and collisions (distance checks, no physics).
##   - CLIENT: renders synced state and forwards Track Builder requests.
##     The client (Track Builder) gets an aerial top-down camera.
## Role assignment in network modes: host = Runner, client = Track Builder
## (the Runner needs zero input latency, so it always runs on the host).
extends Node3D

const VIEW := Vector2(1280, 720)
const SEGMENT_LENGTH := 12.0
const TRACK_WIDTH := 7.5
const GEN_AHEAD := 160.0        # keep track generated this far ahead
const GEN_STEP := 14.0          # one ambient obstacle row every N meters
const BUILDER_DROP_AHEAD := 35.0
const HIT_RANGE := 0.9          # z window for obstacle contact
const BASE_SPEED := 10.0
const SPEED_GAIN := 0.25        # m/s gained per second (server timeline)
const MAX_SPEED := 22.0

signal exited

var runner: Runner3D
var builder: TrackBuilder
var camera: Camera3D

## Track floor segments (visual only): ordered list of MeshInstance3D.
var segments: Array[MeshInstance3D] = []
var next_segment_z := 0.0
## Obstacles: id -> { lane, z, kind, node }. Authority owns spawning.
var obstacles := {}
var next_obstacle_id := 0
var next_ambient_z := -40.0     # first ambient obstacle row

var timeline := 0.0
var speed := BASE_SPEED
var score := 0
var playing := true
## Host-side cooldown tracking for the remote Track Builder.
var remote_cooldown := 0.0
## Swipe tracking for the Runner's touch input.
var swipe_start := Vector2.ZERO
var swipe_active := false

var hud: CanvasLayer
var score_label: Label
var cooldown_bar: ProgressBar
var shield_label: Label
var over_box: VBoxContainer
var over_label: Label


func _ready() -> void:
	_build_environment()
	_build_players()
	_build_hud()
	_ensure_track()


# --- Scene construction (all original low-poly code-built art) --------------

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.5, 0.75, 0.95)  # flat sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	add_child(light)


func _build_players() -> void:
	runner = Runner3D.new()
	add_child(runner)

	builder = TrackBuilder.new()
	# Role wiring per mode: in LOCAL both roles share the device (the Builder
	# uses HUD buttons, the Runner uses gestures); in HOST the Track Builder
	# is the remote client, so the local one is disabled.
	builder.active = Net.mode != Net.Mode.HOST
	builder.place_requested.connect(_on_place_requested)
	add_child(builder)

	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	_update_camera(true)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	score_label = Label.new()
	score_label.text = "0 m"
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.position = Vector2(VIEW.x / 2.0 - 50, 20)
	hud.add_child(score_label)

	shield_label = Label.new()
	shield_label.text = "SHIELD"
	shield_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	shield_label.position = Vector2(24, 24)
	shield_label.visible = false
	hud.add_child(shield_label)

	var is_builder := Net.mode != Net.Mode.HOST

	cooldown_bar = ProgressBar.new()
	cooldown_bar.size = Vector2(220, 18)
	cooldown_bar.position = Vector2(VIEW.x - 244, VIEW.y - 36)
	cooldown_bar.show_percentage = false
	cooldown_bar.visible = is_builder
	hud.add_child(cooldown_bar)

	if is_builder:
		_build_builder_toolbar()

	# Game-over panel, hidden until the run ends.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(center)
	over_box = VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 10)
	over_box.visible = false
	center.add_child(over_box)
	over_label = Label.new()
	over_label.add_theme_font_size_override("font_size", 40)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(over_label)
	var restart := Button.new()
	restart.text = "Restart"
	restart.custom_minimum_size = Vector2(220, 48)
	restart.pressed.connect(_on_restart_pressed)
	over_box.add_child(restart)
	var quit := Button.new()
	quit.text = "Back to Menu"
	quit.custom_minimum_size = Vector2(220, 48)
	quit.pressed.connect(func() -> void: exited.emit())
	over_box.add_child(quit)


func _build_builder_toolbar() -> void:
	# Object type selector (top row) + lane drop buttons (bottom row).
	# The Track Builder picks WHAT, then taps WHERE (left/center/right lane).
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	panel.position = Vector2(VIEW.x - 560, VIEW.y - 156)
	hud.add_child(panel)

	var kinds := HBoxContainer.new()
	kinds.add_theme_constant_override("separation", 6)
	panel.add_child(kinds)
	var group := ButtonGroup.new()
	var names := {
		TrackBuilder.Kind.LOW_BARRIER: "Low",
		TrackBuilder.Kind.HIGH_BARRIER: "High",
		TrackBuilder.Kind.TRAIN: "Train",
		TrackBuilder.Kind.RAMP: "Ramp",
		TrackBuilder.Kind.SHIELD: "Shield",
	}
	for kind_id: int in names:
		var btn := Button.new()
		btn.text = names[kind_id]
		btn.toggle_mode = true
		btn.button_group = group
		btn.custom_minimum_size = Vector2(100, 48)
		btn.button_pressed = kind_id == builder.kind
		btn.pressed.connect(func() -> void: builder.kind = kind_id)
		kinds.add_child(btn)

	var lanes := HBoxContainer.new()
	lanes.add_theme_constant_override("separation", 6)
	panel.add_child(lanes)
	for lane_id in 3:
		var btn := Button.new()
		btn.text = ["Drop LEFT", "Drop CENTER", "Drop RIGHT"][lane_id]
		btn.custom_minimum_size = Vector2(172, 48)
		btn.pressed.connect(builder.request_drop.bind(lane_id))
		lanes.add_child(btn)


# --- Camera ------------------------------------------------------------------

func _update_camera(snap: bool) -> void:
	var target: Vector3
	var look_at_point: Vector3
	if Net.mode == Net.Mode.CLIENT:
		# Track Builder: aerial view of the track ahead of the Runner.
		target = Vector3(0, 30.0, runner.position.z - 18.0)
		look_at_point = Vector3(0, 0, runner.position.z - 19.0)
	else:
		# Runner POV: third-person chase camera, slightly above and behind.
		target = Vector3(runner.position.x * 0.6, 3.2, runner.position.z + 6.0)
		look_at_point = runner.position + Vector3(0, 1.2, -8.0)
	camera.position = target if snap else camera.position.lerp(target, 0.2)
	camera.look_at(look_at_point)


# --- Track generation ----------------------------------------------------------

func _ensure_track() -> void:
	# Floor segments are deterministic visuals, so BOTH peers generate them
	# locally from the runner's z. Obstacles are authority-only (RPC'd).
	while next_segment_z > runner.position.z - GEN_AHEAD:
		var segment := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(TRACK_WIDTH, 0.4, SEGMENT_LENGTH)
		segment.mesh = box
		segment.material_override = _flat_material(
			Color(0.25, 0.27, 0.32) if int(next_segment_z / SEGMENT_LENGTH) % 2 == 0
			else Color(0.3, 0.32, 0.38))
		segment.position = Vector3(0, -0.2, next_segment_z - SEGMENT_LENGTH / 2.0)
		add_child(segment)
		segments.append(segment)
		next_segment_z -= SEGMENT_LENGTH
	# Free segments well behind the runner.
	while segments.size() > 0 and segments[0].position.z > runner.position.z + 30.0:
		segments[0].queue_free()
		segments.remove_at(0)

	# Ambient obstacles: authority drops a row every GEN_STEP meters,
	# always leaving at least one free lane.
	if not Net.is_authority():
		return
	while next_ambient_z > runner.position.z - GEN_AHEAD:
		var free_lane := randi_range(0, 2)
		for lane_id in 3:
			if lane_id == free_lane or randf() < 0.45:
				continue
			var kind := randi_range(0, TrackBuilder.Kind.SHIELD)
			_spawn_obstacle(next_obstacle_id, lane_id, next_ambient_z, kind)
			if Net.mode == Net.Mode.HOST:
				_spawn_obstacle_remote.rpc(next_obstacle_id, lane_id, next_ambient_z, kind)
			next_obstacle_id += 1
		next_ambient_z -= GEN_STEP


func _flat_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


# --- Obstacles -----------------------------------------------------------------

func _spawn_obstacle(id: int, lane: int, z: float, kind: int) -> void:
	var node := MeshInstance3D.new()
	var x: float = Runner3D.LANES[lane]
	match kind:
		TrackBuilder.Kind.LOW_BARRIER:
			# Knee-high wall: jump over it.
			node.mesh = _box(Vector3(1.8, 0.8, 0.4))
			node.material_override = _flat_material(Color(0.85, 0.3, 0.25))
			node.position = Vector3(x, 0.4, z)
		TrackBuilder.Kind.HIGH_BARRIER:
			# Overhead bar: slide under it.
			node.mesh = _box(Vector3(1.8, 0.5, 0.4))
			node.material_override = _flat_material(Color(0.9, 0.6, 0.2))
			node.position = Vector3(x, 1.6, z)
		TrackBuilder.Kind.TRAIN:
			# Full lane blocker: switch lanes, no vertical dodge.
			node.mesh = _box(Vector3(2.0, 2.6, 6.0))
			node.material_override = _flat_material(Color(0.35, 0.4, 0.75))
			node.position = Vector3(x, 1.3, z)
		TrackBuilder.Kind.RAMP:
			# Launches the Runner upward on contact (helpful or chaotic).
			node.mesh = _box(Vector3(1.8, 0.3, 2.4))
			node.material_override = _flat_material(Color(0.4, 0.8, 0.4))
			node.rotation_degrees.x = -15.0
			node.position = Vector3(x, 0.3, z)
		TrackBuilder.Kind.SHIELD:
			# Power-up: absorbs exactly one hit.
			var sphere := SphereMesh.new()
			sphere.radius = 0.45
			sphere.height = 0.9
			node.mesh = sphere
			node.material_override = _flat_material(Color(1.0, 0.85, 0.2))
			node.position = Vector3(x, 1.0, z)
	add_child(node)
	obstacles[id] = {"lane": lane, "z": z, "kind": kind, "node": node}


func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


@rpc("authority", "call_remote", "reliable")
func _spawn_obstacle_remote(id: int, lane: int, z: float, kind: int) -> void:
	_spawn_obstacle(id, lane, z, kind)


func _free_obstacle(id: int) -> void:
	if obstacles.has(id):
		obstacles[id]["node"].queue_free()
		obstacles.erase(id)


@rpc("authority", "call_remote", "reliable")
func _free_obstacle_remote(id: int) -> void:
	_free_obstacle(id)


# --- Track Builder placement -----------------------------------------------------

func _on_place_requested(lane: int, kind: int) -> void:
	if Net.mode == Net.Mode.CLIENT:
		# Forward to the host; the host validates and spawns authoritatively.
		_request_place.rpc_id(1, lane, kind)
	else:
		_place(lane, kind)


@rpc("any_peer", "call_remote", "reliable")
func _request_place(lane: int, kind: int) -> void:
	# Runs on the host when the remote Track Builder drops an object.
	if not playing:
		return
	if Net.strict_validation:
		# "Local Server" mode: never trust the client. Re-check the cooldown
		# and reject malformed lanes/kinds.
		if remote_cooldown > 0.0:
			return
		if lane < 0 or lane > 2 or kind < 0 or kind > TrackBuilder.Kind.SHIELD:
			return
	remote_cooldown = TrackBuilder.COOLDOWN
	_place(lane, kind)


func _place(lane: int, kind: int) -> void:
	# Drop ahead of the Runner so there is always reaction time.
	var z := runner.position.z - BUILDER_DROP_AHEAD
	_spawn_obstacle(next_obstacle_id, lane, z, kind)
	if Net.mode == Net.Mode.HOST:
		_spawn_obstacle_remote.rpc(next_obstacle_id, lane, z, kind)
	next_obstacle_id += 1


# --- Runner input ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not playing or Net.mode == Net.Mode.CLIENT:
		return  # the client is the Track Builder; it never controls the Runner
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A: runner.switch_lane(-1)
			KEY_RIGHT, KEY_D: runner.switch_lane(1)
			KEY_UP, KEY_W, KEY_SPACE: runner.jump()
			KEY_DOWN, KEY_S: runner.slide()
		return
	# Touch swipes: horizontal = lane switch, up = jump, down = slide.
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			swipe_active = true
		elif swipe_active:
			swipe_active = false
			_resolve_swipe(event.position - swipe_start)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			swipe_start = event.position
			swipe_active = true
		elif swipe_active:
			swipe_active = false
			_resolve_swipe(event.position - swipe_start)


func _resolve_swipe(delta: Vector2) -> void:
	if delta.length() < 24.0:
		runner.jump()  # tap = jump
	elif absf(delta.x) > absf(delta.y):
		runner.switch_lane(1 if delta.x > 0.0 else -1)
	elif delta.y < 0.0:
		runner.jump()
	else:
		runner.slide()


# --- Simulation ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	remote_cooldown = maxf(remote_cooldown - delta, 0.0)
	cooldown_bar.value = (1.0 - builder.cooldown_left / TrackBuilder.COOLDOWN) * 100.0
	_update_camera(false)
	if not playing:
		return

	_ensure_track()

	if Net.mode == Net.Mode.CLIENT:
		return

	timeline += delta
	speed = minf(BASE_SPEED + timeline * SPEED_GAIN, MAX_SPEED)
	runner.step_physics(delta, speed)

	var meters := int(-runner.position.z)
	if meters != score:
		score = meters
		score_label.text = "%d m" % score

	_check_collisions()

	if Net.mode == Net.Mode.HOST:
		_sync.rpc(runner.position, runner.lane, runner.is_sliding(),
			score, runner.has_shield)


func _check_collisions() -> void:
	# Distance-based contact resolution per obstacle kind. Runs only on the
	# authority; outcomes (consumed pickups, death) replicate via RPC.
	var consumed: Array[int] = []
	for id in obstacles:
		var obstacle: Dictionary = obstacles[id]
		# Cleanup: obstacle is far behind the runner.
		if obstacle["z"] > runner.position.z + 15.0:
			consumed.append(id)
			continue
		if obstacle["lane"] != runner.lane:
			continue
		if absf(obstacle["z"] - runner.position.z) > HIT_RANGE \
				and obstacle["kind"] != TrackBuilder.Kind.TRAIN:
			continue
		# Trains are long: use their half-length as the contact window.
		if obstacle["kind"] == TrackBuilder.Kind.TRAIN \
				and absf(obstacle["z"] - runner.position.z) > 3.0:
			continue
		match obstacle["kind"]:
			TrackBuilder.Kind.LOW_BARRIER:
				if runner.position.y < 0.9:  # cleared by jumping
					_hit()
			TrackBuilder.Kind.HIGH_BARRIER:
				if not runner.is_sliding():  # cleared by sliding
					_hit()
			TrackBuilder.Kind.TRAIN:
				_hit()  # no vertical dodge: lane switch was the only option
			TrackBuilder.Kind.RAMP:
				if runner.position.y < 0.5:
					runner.vertical_velocity = 13.0  # launch!
					consumed.append(id)
			TrackBuilder.Kind.SHIELD:
				runner.grant_shield()
				shield_label.visible = true
				consumed.append(id)
		if not playing:
			break
	for id in consumed:
		_free_obstacle(id)
		if Net.mode == Net.Mode.HOST:
			_free_obstacle_remote.rpc(id)


func _hit() -> void:
	# The shield absorbs exactly one hit, then the next one kills.
	if runner.absorb_hit():
		shield_label.visible = false
		return
	_on_runner_died()


# --- Game over / restart ----------------------------------------------------------

func _on_runner_died() -> void:
	_show_game_over()
	if Net.mode == Net.Mode.HOST:
		_game_over_remote.rpc(score)


@rpc("authority", "call_remote", "reliable")
func _game_over_remote(final_score: int) -> void:
	score = final_score
	_show_game_over()


func _show_game_over() -> void:
	playing = false
	over_label.text = "Game Over — Distance: %d m" % score
	over_box.visible = true


func _on_restart_pressed() -> void:
	if Net.mode == Net.Mode.CLIENT:
		_request_restart.rpc_id(1)  # only the host may restart the match
	else:
		_restart()
		if Net.mode == Net.Mode.HOST:
			_restart_remote.rpc()


@rpc("any_peer", "call_remote", "reliable")
func _request_restart() -> void:
	if not playing:
		_restart()
		_restart_remote.rpc()


@rpc("authority", "call_remote", "reliable")
func _restart_remote() -> void:
	_restart()


func _restart() -> void:
	for id in obstacles.keys():
		_free_obstacle(id)
	for segment in segments:
		segment.queue_free()
	segments.clear()
	next_segment_z = 0.0
	next_ambient_z = -40.0
	runner.reset()
	timeline = 0.0
	speed = BASE_SPEED
	score = 0
	score_label.text = "0 m"
	shield_label.visible = false
	over_box.visible = false
	playing = true
	_ensure_track()
	_update_camera(true)


# --- Client-side state sync ----------------------------------------------------------

@rpc("authority", "call_remote", "unreliable")
func _sync(runner_pos: Vector3, lane: int, sliding: bool,
		new_score: int, shield: bool) -> void:
	runner.position = runner_pos
	runner.lane = lane
	if sliding and not runner.is_sliding():
		runner.slide()
	if shield != runner.has_shield:
		runner.has_shield = shield
		shield_label.visible = shield
	if new_score != score:
		score = new_score
		score_label.text = "%d m" % score
