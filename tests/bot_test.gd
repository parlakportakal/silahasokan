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
	var game = load("res://Scenes/el_kanyon.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.solo_game()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_B
	key.pressed = true
	game._input(key)
	var bot = game.bot
	check(is_instance_valid(bot) and bot.bot_control, "B creates AI character")
	game._input(key)
	check(game.bot == bot, "repeated B keeps a single bot")
	for i in range(60):
		await physics_frame
	check(bot.is_on_floor(), "bot stands on terrain")
	game.damage_player(bot, game.local_player, 10, Vector2.RIGHT)
	check(bot.damage_percent == 10 and bot.knockback_velocity.x > 0, "bot receives normal damage and knockback")
	var furthest := 0.0
	for i in range(240):
		await physics_frame
		furthest = maxf(furthest, absf(bot.global_position.x - bot.bot_home.x))
	check(furthest > 10 and absf(bot.global_position.x - bot.bot_home.x) < 20, "displaced bot walks back home")
	bot.position = Vector2(0, 1800)
	game._update_bot(0.016)
	check(bot.lives == 2 and bot.respawning, "bot has normal lives and respawn")
	game._update_bot(3.0)
	check(bot.visible and bot.global_position == bot.bot_home, "bot respawns at its own home")
	game._leave("done")
	check(game.bot == null, "leaving clears bot")
	quit(1 if failed else 0)
