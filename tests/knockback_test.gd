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
	var game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.solo_game()
	await physics_frame
	await physics_frame
	var player = game.local_player
	player.local_control = false
	player.respawn_delay = 0.0
	check(is_instance_valid(game.get_node_or_null("lifezone")), "lifezone survives game startup")
	player.respawn_grace = 0.0
	game.damage_player(player, game.guest, 10, Vector2.RIGHT)
	var first: float = player.knockback_velocity.x
	check(player.damage_percent == 10 and player.lives == 3 and first > 0, "bullet damage increases knockback without consuming a life")
	player.knockback_velocity = Vector2.ZERO
	game.damage_player(player, game.guest, 1000, Vector2.RIGHT)
	check(player.knockback_velocity.x > first and player.lives == 3, "high damage launches harder without health death")
	player.position = Vector2(5000, 5000)
	await physics_frame
	await physics_frame
	check(player.lives == 2 and player.position == game._spawn_position(0), "leaving lifezone costs one life and respawns")
	check(player.damage_percent == 0 and player.knockback_velocity == Vector2.ZERO, "respawn clears damage and impulse")
	game.player_left_lifezone(player)
	check(player.lives == 2, "duplicate exit does not cost another life")
	for i in range(2):
		player.respawn_grace = 0.0
		player.position = Vector2(-5000, 0)
		game.player_left_lifezone(player)
		await physics_frame
		await physics_frame
	check(player.lives == 0 and not game.playing and game.menu.visible, "last life ends match")
	game.solo_game()
	check(player.lives == 3 and game.playing, "new game restores stocks")
	quit(1 if failed else 0)
