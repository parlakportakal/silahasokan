extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run_check")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
	else:
		print("PASS: " + message)
func run_check() -> void:
	for path in ["res://Scenes/main.tscn", "res://Scenes/el_banyo.tscn"]:
		var game = load(path).instantiate()
		root.add_child(game)
		current_scene = game
		game.solo_game()
		var cam = game.camera
		cam.set_process(false)
		game.local_player.local_control = false
		var full_zoom: float = cam.zoom.x
		cam._process(0.5)
		check(is_equal_approx(cam.zoom.x, full_zoom), path + " starts with full map intro")
		cam.intro_remaining = 0.0
		game.local_player.position = Vector2(520, 350)
		for i in range(180):
			cam._process(1.0 / 60.0)
		check(cam.zoom.x > full_zoom, "nearby players cause smooth zoom in")
		var close_zoom: float = cam.zoom.x
		game.guest.visible = true
		game.guest.position = Vector2(1050, 500)
		game.local_player.position = Vector2(100, 200)
		var third := Node2D.new()
		game.add_child(third)
		third.add_to_group("camera_players")
		third.position = Vector2(700, 20)
		for i in range(120):
			cam._process(1.0 / 60.0)
			var half: Vector2 = game.get_viewport_rect().size / cam.zoom * 0.5
			for p in [game.local_player, game.guest, third]:
				var distance: Vector2 = (p.global_position - cam.global_position).abs()
				if distance.x > half.x or distance.y > half.y:
					failed = true
		check(cam.zoom.x < close_zoom, "separated players widen the view")
		check(not failed, "all three players stay visible during transition")
		third.hide()
		game.guest.hide()
		game.local_player.position = Vector2(520, 350)
		for i in range(180):
			cam._process(1.0 / 60.0)
		check(cam.zoom.x > full_zoom, "hidden players no longer affect framing")
		game._leave("test")
		check(is_equal_approx(cam.zoom.x, full_zoom), "leaving restores whole map view")
		game.queue_free()
		await process_frame
	quit(1 if failed else 0)
