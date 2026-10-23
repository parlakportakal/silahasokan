extends SceneTree

var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
	else:
		print("PASS: " + message)

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	set_meta("launch_mode", "solo")
	var game = load("res://Scenes/el_kanyon.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	check(game.playing and game.local_player.local_control, "solo launch activates player")
	var player = game.local_player
	for slot in [0, 1]:
		player.position = game._spawn_position(slot)
		player.reset_combat()
		for i in range(60):
			await physics_frame
		check(player.is_on_floor() and player.lives == 3, "spawn rests safely on terrain: " + str(slot))
	var start: Vector2 = player.position
	Input.action_press("saga")
	for i in range(12):
		await physics_frame
	Input.action_release("saga")
	check(player.position.x > start.x, "player can move")
	var axis = player.get_node("silaheksen")
	axis.select_weapon(1)
	game.request_fire()
	check(axis.weapons[1].cooldown > 0 and player.hook != null, "shotgun fires and hook is available")
	check(game.camera.enabled and game.camera.following, "camera follows match")
	player.position = Vector2(0, 1500)
	game.player_left_lifezone(player)
	check(player.respawning and player.lives == 2, "falling out costs one life")
	game.finish_respawn(0, 0.0)
	check(player.visible and player.position == game._spawn_position(0), "player respawns at canyon marker")
	game._leave("test")
	game._start(game.guest)
	check(game.guest.local_control and not player.local_control, "guest can control second player")
	quit(1 if failed else 0)
