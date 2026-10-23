extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run_test")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
	else:
		print("PASS: " + message)
func block(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = pos
	root.add_child(body)
	return body
func run_test() -> void:
	block(Vector2(0, 100), Vector2(1600, 20))
	block(Vector2(100, 55), Vector2(35, 70))
	var bot = load("res://Scenes/player.tscn").instantiate()
	root.add_child(bot)
	bot.position = Vector2(0, 60)
	bot.bot_home = Vector2(250, 60)
	bot.bot_control = true
	var jumped := false
	for i in range(300):
		await physics_frame
		jumped = jumped or bot.velocity.y < -100
	check(jumped and absf(bot.position.x - 250) < 20, "bot jumps over obstacle and returns home")
	bot.bot_control = false
	bot.position = Vector2(-400, -100)
	bot.bot_home = Vector2(-400, -280)
	bot.jump_count = 1
	bot.velocity = Vector2(0, 10)
	bot.move_and_slide()
	bot.bot_brain = load("res://Scripts/bot_movement.gd").new()
	check(bot.bot_brain.decide(bot, 0.016).jump, "bot requests double jump near apex for higher destination")
	bot.last_wall_side = 1
	bot.last_wall_jump_side = 0
	bot.wall_coyote_counter = 0.1
	bot.jump_count = 2
	bot.bot_brain.jump_cooldown = 0
	var action: Dictionary = bot.bot_brain.decide(bot, 0.016)
	check(action.jump and action.direction == -1, "bot wall jumps away from wall using remaining wall opportunity")
	block(Vector2(-400, -240), Vector2(100, 20))
	await physics_frame
	await physics_frame
	bot.bot_brain.scan_timer = 0
	action = bot.bot_brain.decide(bot, 0.016)
	check(action.held and action.reel, "bot chooses reachable overhead hook to recover")
	quit(1 if failed else 0)
