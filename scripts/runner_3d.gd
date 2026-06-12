## Player B character: runs forward automatically in 3 lanes, dodges by
## switching lanes, jumping, and sliding. Kinematics are manual (no physics
## bodies): the game world resolves obstacle contact with distance checks,
## which is robust and identical across platforms.
## Only the simulation authority steps this; clients are positioned directly
## from synced state.
class_name Runner3D
extends Node3D

## Lane index -> world X. Three lanes, Subway Surfers style.
const LANES: Array[float] = [-2.2, 0.0, 2.2]
const GRAVITY := 30.0
const JUMP_VELOCITY := 11.0
const SLIDE_TIME := 0.6
const LANE_LERP_SPEED := 12.0

var lane := 1
var vertical_velocity := 0.0
var slide_left := 0.0
var has_shield := false

var _body: MeshInstance3D
var _shield_visual: MeshInstance3D


func _ready() -> void:
	# Visual: low-poly capsule runner with flat colors (original art).
	_body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.7
	_body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.35, 0.2)
	_body.material_override = mat
	_body.position = Vector3(0, 0.85, 0)
	add_child(_body)

	_shield_visual = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	_shield_visual.mesh = sphere
	var shield_mat := StandardMaterial3D.new()
	shield_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_visual.material_override = shield_mat
	_shield_visual.position = Vector3(0, 1.0, 0)
	_shield_visual.visible = false
	add_child(_shield_visual)


func switch_lane(direction: int) -> void:
	lane = clampi(lane + direction, 0, LANES.size() - 1)


func jump() -> void:
	# Only from the ground: no double jumps.
	if position.y <= 0.01:
		vertical_velocity = JUMP_VELOCITY


func slide() -> void:
	if slide_left <= 0.0:
		slide_left = SLIDE_TIME
		# Crouch the visual; the game treats "sliding" as a low profile.
		_body.scale = Vector3(1.0, 0.45, 1.0)
		_body.position.y = 0.4


func is_sliding() -> bool:
	return slide_left > 0.0


func grant_shield() -> void:
	has_shield = true
	_shield_visual.visible = true


## Consume the shield for one hit. Returns true if the hit was absorbed.
func absorb_hit() -> bool:
	if has_shield:
		has_shield = false
		_shield_visual.visible = false
		return true
	return false


## Called by the game world each physics frame, authority side only.
## Forward is -Z; `speed` is owned by the server timeline.
func step_physics(delta: float, speed: float) -> void:
	position.z -= speed * delta
	# Smooth lateral lane change.
	position.x = lerpf(position.x, LANES[lane], LANE_LERP_SPEED * delta)
	# Vertical motion: jump arc with manual gravity, floor at y = 0.
	vertical_velocity -= GRAVITY * delta
	position.y = maxf(position.y + vertical_velocity * delta, 0.0)
	if position.y == 0.0 and vertical_velocity < 0.0:
		vertical_velocity = 0.0
	# Slide timer.
	if slide_left > 0.0:
		slide_left -= delta
		if slide_left <= 0.0:
			_end_slide()


func _end_slide() -> void:
	slide_left = 0.0
	_body.scale = Vector3.ONE
	_body.position.y = 0.85


func reset() -> void:
	position = Vector3(0, 0, 0)
	lane = 1
	vertical_velocity = 0.0
	has_shield = false
	_shield_visual.visible = false
	_end_slide()
