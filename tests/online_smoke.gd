extends SceneTree
var game
var role := "host"
var failed := false

func _initialize() -> void:
	if "client" in OS.get_cmdline_user_args():
		role = "client"
	call_deferred("run_test")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(role + ": " + message)
	else:
		print("PASS " + role + ": " + message)

func run_test() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if role == "host":
		game.host_game()
	else:
		game.address.text = "127.0.0.1"
		game.join_game()
	for i in range(150):
		await create_timer(0.1).timeout
		if game.guest_id != 0 and game.playing:
			break
	check(game.guest_id != 0 and game.playing, "two peers connected")
	if failed:
		quit(1)
		return
	game.local_player.local_control = false
	if role == "client":
		game.local_player.position = Vector2(500, 300)
		game.local_player.get_node("silaheksen").rotation = PI
		game.local_player.get_node("silaheksen").select_weapon(1)
		await create_timer(1.0).timeout
		game.request_fire()
		await create_timer(1.5).timeout
		check(game.get_node("player").position.distance_to(Vector2(404, 300)) < 2.0, "host movement replicated")
		await create_timer(3.0).timeout
		check(game.get_node("player").score >= 1, "host score replicated after death")
		check(game.local_player.health == 100, "respawn restores health")
		game._leave("test")
	else:
		game.local_player.position = Vector2(404, 300)
		await create_timer(0.8).timeout
		check(game.guest.position.distance_to(Vector2(500, 300)) < 2.0, "client movement replicated")
		check(game.guest.get_node("silaheksen").selected_weapon == 1, "client weapon replicated")
		check(absf(game.guest.get_node("silaheksen").rotation - PI) < 0.01, "client aim replicated")
		await create_timer(1.2).timeout
		check(game.local_player.health < 100, "client shot damages host")
		game.local_player.get_node("silaheksen").rotation = 0.0
		game.local_player.get_node("silaheksen").select_weapon(0)
		game.request_fire()
		await create_timer(0.3).timeout
		check(game.guest.health == 90, "host pistol damages client")
		game.damage_player(game.guest, game.local_player, 100)
		check(game.local_player.score == 1, "server awards score")
		await create_timer(4.0).timeout
		check(game.guest_id == 0 and not game.guest.visible, "disconnect removes guest")
	game._leave("test done")
	quit(1 if failed else 0)
