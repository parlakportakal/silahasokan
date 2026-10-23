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
	var player = load("res://Scenes/player.tscn").instantiate()
	root.add_child(player)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(400, 20)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(0, -200)
	root.add_child(wall)
	await physics_frame
	await physics_frame
	var hook = player.hook
	Input.action_press("sagtik")
	hook.fire(Vector2(0, -200))
	for i in range(10):
		hook.step(1.0 / 60.0, true)
	check(hook.state == hook.State.ATTACHED, "hook attaches to solid wall")
	check(hook.can_climb(), "vertical rope permits climbing")
	var length: float = hook.rope_length
	Input.action_press("hook_up")
	hook.step(0.1, true)
	check(hook.rope_length < length, "W shortens upward rope")
	player.velocity = Vector2(150, 100)
	hook.constrain(0.1)
	check(player.velocity.y < 0 and is_equal_approx(player.velocity.x, 150), "climb pulls up while preserving tangential speed")
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		hook.target_offset = wall.to_local(direction * 200)
		hook.rope_length = 200
		hook.step(0.1, true)
		player.velocity = Vector2.ZERO
		hook.constrain(0.1)
		check(hook.rope_length < 200 and player.velocity.dot(direction) > 0, "W pulls in direction " + str(direction))
	var velocity: Vector2 = player.velocity
	Input.action_release("sagtik")
	hook.step(0.01, true)
	check(hook.state == hook.State.RETRACTING and player.velocity == velocity, "release retracts without cancelling momentum")
	hook.step(1.0, true)
	check(hook.state == hook.State.IDLE, "retraction finishes at weapon")
	Input.action_release("hook_up")
	Input.action_press("sagtik")
	hook.fire(Vector2(800, 0))
	for i in range(30):
		hook.step(1.0 / 60.0, true)
	check(hook.state != hook.State.ATTACHED, "empty space cannot create anchor")
	check(hook.state == hook.State.FALLING and hook.tip.y > 0, "missed hook falls under gravity after maximum range")
	var stayed_in_range := true
	for i in range(600):
		hook.step(1.0 / 60.0, true)
		stayed_in_range = stayed_in_range and hook.tip.distance_to(hook.origin()) <= hook.max_range + 0.01
	check(stayed_in_range and hook.state == hook.State.FALLING, "loose hook stays within max range for ten seconds")
	player.position.x -= 100
	hook.correct_position()
	check(hook.tip.distance_to(hook.origin()) <= hook.max_range + 0.01, "moving owner cannot stretch loose rope")
	player.position = Vector2.ZERO
	hook.reset()
	hook.fire(Vector2(800, 0))
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(800, 20)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, hook.max_range * 0.5)
	root.add_child(floor_body)
	await physics_frame
	await physics_frame
	for i in range(60):
		hook.step(1.0 / 60.0, true)
	check(hook.state == hook.State.ATTACHED and hook.target_body == floor_body, "falling hook attaches on contact")
	player.reset_combat()
	check(hook.state == hook.State.IDLE, "respawn clears rope")
	var opponent = load("res://Scenes/player.tscn").instantiate()
	opponent.position = Vector2(200, 0)
	opponent.collision_layer = 4
	root.add_child(opponent)
	player.collision_layer = 4
	await physics_frame
	await physics_frame
	hook.fire(opponent.global_position)
	for i in range(10):
		hook.step(1.0 / 60.0, true)
	check(hook.state == hook.State.ATTACHED and hook.target_body == opponent, "hook hits opponent and excludes owner")
	length = hook.rope_length
	hook.step(0.1, true)
	player.velocity = Vector2.ZERO
	hook.constrain(0.1)
	check(hook.rope_length < length and player.velocity.x > 0, "player target pulls automatically without W")
	hook.rope_length = player.global_position.distance_to(hook.anchor)
	player.velocity = Vector2.ZERO
	hook.step(0.1, true)
	hook.constrain(0.1)
	check(is_equal_approx(player.velocity.x, hook.climb_speed * 0.85), "owner receives 85 percent of closing speed")
	check(is_equal_approx(opponent.hook_pull_velocity.x, -hook.climb_speed * 0.15), "target receives 15 percent towards owner")
	var old_anchor: Vector2 = hook.anchor
	opponent.position.y += 50
	hook.step(0.01, true)
	check(is_equal_approx(hook.anchor.y, old_anchor.y + 50), "anchor follows moving opponent")
	Input.action_release("sagtik")
	hook.step(0.01, true)
	check(hook.state == hook.State.RETRACTING, "right release stops automatic pull")
	check(opponent.hook_pull_velocity == Vector2.ZERO, "release clears target pull")
	hook.reset()
	hook.state = hook.State.ATTACHED
	hook.target_body = opponent
	opponent.hide()
	Input.action_press("sagtik")
	hook.step(0.01, true)
	check(hook.state != hook.State.ATTACHED, "unavailable opponent releases rope")
	Input.action_release("sagtik")
	# Use the real one-way platform scene, isolated from the other fixtures.
	var platform = load("res://Scenes/platform.tscn").instantiate()
	platform.position = Vector2(2000, 0)
	root.add_child(platform)
	await physics_frame
	await physics_frame
	for side in [-1.0, 1.0]:
		player.position = platform.position + Vector2(0, side * 100)
		hook.reset()
		Input.action_press("sagtik")
		hook.fire(platform.global_position)
		for i in range(10):
			hook.step(1.0 / 60.0, true)
		check(hook.state == hook.State.ATTACHED and hook.target_body == platform.get_node("StaticBody2D"), "hook attaches to one-way platform from side " + str(side))
		Input.action_release("sagtik")
	quit(1 if failed else 0)
