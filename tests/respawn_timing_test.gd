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
	var player = game.local_player
	player.local_control = false
	check(player.respawn_delay == 2.0 and player.respawn_invulnerability_duration == 2.0, "both exported durations default to two seconds")
	player.position = Vector2(5000, 5000)
	game.player_left_lifezone(player)
	check(player.respawning and not player.visible and player.lives == 2 and player.collision_layer == 0, "death hides and disables the player immediately")
	game.damage_player(player, game.guest, 10)
	game.request_fire()
	check(player.damage_percent == 0 and player.get_node("silaheksen/pistol").cooldown == 0, "dead player cannot take damage or shoot")
	await create_timer(1.7).timeout
	check(player.respawning and not player.visible, "player remains dead before the respawn deadline")
	await create_timer(0.4).timeout
	check(not player.respawning and player.visible and player.position == game._spawn_position(0), "player reappears at spawn after two seconds")
	check(player.respawn_grace > 1.7, "protection begins on respawn, not on death")
	var alphas := {}
	for i in range(20):
		await physics_frame
		alphas[player.modulate.a] = true
	game.damage_player(player, game.guest, 10)
	check(alphas.size() > 1 and player.damage_percent == 0 and player.knockback_velocity == Vector2.ZERO, "protected player blinks and ignores damage and knockback")
	await create_timer(1.8).timeout
	game.damage_player(player, game.guest, 10)
	check(player.respawn_grace == 0 and player.modulate.a == 1.0 and player.damage_percent == 10, "protection expires and normal appearance and damage return")
	player.respawn_delay = 0.1
	player.respawn_invulnerability_duration = 0.0
	player.position = Vector2(5000, 5000)
	game.player_left_lifezone(player)
	await create_timer(0.2).timeout
	check(player.visible and not player.respawning and player.respawn_grace == 0, "custom delay and zero protection are honored")
	player.position = Vector2(5000, 5000)
	player.lives = 2
	game.player_left_lifezone(player)
	game.solo_game()
	player.local_control = false
	await create_timer(0.2).timeout
	check(not player.respawning and player.visible and player.lives == 3 and player.spawn_generation == 0, "new session cancels an outstanding respawn")
	quit(1 if failed else 0)
