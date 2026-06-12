## Automated smoke playtest (headless-friendly).
## Boots the real game in LOCAL mode and drives both roles programmatically:
## the Runner switches lanes/jumps/slides on timers, the Track Builder drops
## every object kind on random lanes (trains will eventually land a hit).
## Verifies: play -> die -> game over -> restart -> play.
## Run with: godot --headless res://tests/playtest.tscn
extends Node

const MAX_TIME := 60.0

var main: Node
var game: Node3D
var phase := "play"
var t := 0.0
var lane_timer := 1.0
var jump_timer := 1.1
var slide_timer := 1.7
var build_timer := 2.0
var kind_cycle := 0
var died_once := false
var restarted := false
var max_score := 0

func _ready() -> void:
	main = $Main
	await get_tree().process_frame
	main._on_local()
	game = main.game
	print("[playtest] BuildNDash3D started in LOCAL mode")


func _physics_process(delta: float) -> void:
	if game == null:
		return
	t += delta
	max_score = maxi(max_score, game.score)
	match phase:
		"play":
			# Drive the Runner: random lane switches plus periodic jump/slide.
			lane_timer -= delta
			if lane_timer <= 0.0:
				lane_timer = 1.0
				game.runner.switch_lane(1 if randf() < 0.5 else -1)
			jump_timer -= delta
			if jump_timer <= 0.0:
				jump_timer = 1.1
				game.runner.jump()
			slide_timer -= delta
			if slide_timer <= 0.0:
				slide_timer = 1.7
				game.runner.slide()
			# Drive the Track Builder: cycle all kinds on random lanes.
			build_timer -= delta
			if build_timer <= 0.0:
				build_timer = 2.5
				game._place(randi_range(0, 2), kind_cycle % 5)
				kind_cycle += 1
			if not game.playing:
				died_once = true
				print("[playtest] game over at t=%.1fs dist=%dm obstacles=%d speed=%.1f" % [
					t, game.score, game.obstacles.size(), game.speed])
				phase = "restart"
		"restart":
			game._on_restart_pressed()
			restarted = game.playing and game.score == 0
			print("[playtest] restart -> playing=%s score=%d obstacles=%d" % [
				game.playing, game.score, game.obstacles.size()])
			phase = "second"
		"second":
			lane_timer -= delta
			if lane_timer <= 0.0:
				lane_timer = 1.0
				game.runner.switch_lane(1 if randf() < 0.5 else -1)
			jump_timer -= delta
			if jump_timer <= 0.0:
				jump_timer = 1.1
				game.runner.jump()
			if t > 45.0 or not game.playing:
				_finish()
	if t > MAX_TIME:
		_finish()


func _finish() -> void:
	var ok := died_once and restarted
	print("[playtest] RESULT: %s | died_once=%s restarted=%s max_dist=%dm kinds_used=%d" % [
		"PASS" if ok else "FAIL", died_once, restarted, max_score, mini(kind_cycle, 5)])
	get_tree().quit(0 if ok else 1)
