extends SceneTree
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
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var bullet = load("res://Scenes/mermi.tscn").instantiate()
	bullet.position = Vector2(100, 100)
	world.add_child(bullet)
	bullet.set_process(false)
	bullet.set_physics_process(false)
	bullet.render_visual(0.0)
	check(bullet.get_node("Sprite2D").global_position == Vector2(100, 100), "first rendered frame starts at muzzle, not world origin")
	bullet._physics_process(1.0 / 60.0)
	var start: Vector2 = bullet.previous_position
	var finish: Vector2 = bullet.global_position
	bullet.render_visual(0.25)
	var first: Vector2 = bullet.get_node("Sprite2D").global_position
	bullet.render_visual(0.75)
	var second: Vector2 = bullet.get_node("Sprite2D").global_position
	check(first.is_equal_approx(start.lerp(finish, 0.25)) and second.is_equal_approx(start.lerp(finish, 0.75)), "bullet advances between physics ticks")
	check(second.x > first.x and bullet.global_position == finish, "visual smoothing preserves authoritative collision position")
	check(bullet.velocity.y > 0.0, "gravity remains active")
	var player = load("res://Scenes/player.tscn").instantiate()
	world.add_child(player)
	player.get_node("Sprite2D").modulate = Color(0.4, 0.75, 1.0)
	player.show_hit_feedback()
	check(player.get_node("Sprite2D").self_modulate.g < 0.2, "hit immediately flashes red")
	await create_timer(0.1).timeout
	player.show_hit_feedback()
	await create_timer(0.22).timeout
	check(player.get_node("Sprite2D").self_modulate.is_equal_approx(Color.WHITE), "repeated hits recover to normal appearance")
	check(player.get_node("Sprite2D").modulate == Color(0.4, 0.75, 1.0), "hit flash preserves player identity color")
	quit(1 if failed else 0)
