extends SceneTree

const Motion = preload("res://Scripts/network_motion.gd")
var failed := false

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: " + message)
	else:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var motion = Motion.new()
	var next_packet := 0
	var previous := -1.0
	var min_step := 1000.0
	var max_step := 0.0
	# 30 Hz packets with alternating delays; render them at 120 FPS.
	for frame in range(120):
		var now := frame / 120.0
		while next_packet < 30:
			var sent := next_packet / 30.0
			var arrived := sent + (0.008 if next_packet % 2 == 1 else 0.0)
			if arrived > now:
				break
			motion.push(arrived, Vector2(sent * 300.0, 0.0), 0.0)
			next_packet += 1
		var state: Dictionary = motion.sample(now)
		if state.is_empty():
			continue
		var x: float = state.position.x
		if frame > 20:
			var step := x - previous
			min_step = minf(min_step, step)
			max_step = maxf(max_step, step)
		previous = x
	check(min_step > 0.0 and max_step < 4.0, "jittery 30 Hz motion advances on every 120 FPS frame, without 10px jumps")
	print("Measured per-frame movement: ", min_step, " .. ", max_step, " px")
	var stopped: Vector2 = motion.sample(5.0).position
	check(stopped.is_equal_approx(Vector2(290.0, 0.0)), "missing packets stop at last known position instead of drifting")
	motion.clear()
	motion.push(1.0, Vector2.ZERO, deg_to_rad(179.0))
	motion.push(1.1, Vector2(10, 0), deg_to_rad(-179.0))
	var middle: Dictionary = motion.sample(1.05 + Motion.BUFFER_SECONDS)
	check(absf(absf(middle.angle) - PI) < 0.001, "aim crosses angle wrap using the short path")
	motion.push(1.2, Vector2(1000, 0), 0.0)
	check(motion.sample(1.2).position == Vector2(1000, 0), "teleports clear old motion")
	motion.clear()
	check(motion.sample(2.0).is_empty(), "respawn/disconnect can clear the buffer")

	var game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.solo_game()
	game.guest_id = 123
	game.guest.visible = true
	var now := Time.get_ticks_usec() / 1000000.0
	game.remote_motion.push(now - 0.1, Vector2(450, 300), 0.0)
	game._apply_state(game.guest, Vector2(500, 300), Vector2.ZERO, 0.0, 0, false)
	check(game.guest.position == Vector2(500, 300), "collision body keeps latest network position")
	check(game.guest.get_node("silaheksen").position.x < 0.0, "only remote visuals are interpolated")
	check(game.local_player.get_node("silaheksen").position == Vector2.ZERO, "local controls receive no interpolation delay")
	game.show_shot(1, Vector2(500, 300), 0.0, 0)
	var bullet = game.get_child(game.get_child_count() - 1)
	check(bullet.global_position.is_equal_approx(Vector2(542, 298)), "shot uses real muzzle instead of delayed visual offset")
	game.respawn(1)
	check(game.remote_motion.samples.is_empty() and game.guest.get_node("silaheksen").position == Vector2.ZERO, "respawn resets visual offsets and history")
	game.guest_id = 0
	game._leave("test complete")
	quit(1 if failed else 0)
