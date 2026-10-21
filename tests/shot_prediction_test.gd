extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.solo_game()
	var bullets = game.local_player.get_node("silaheksen/pistol").shoot()
	game.predicted_shots[77] = bullets
	game.reject_shot(77)
	if not game.predicted_shots.is_empty() or not bullets[0].is_queued_for_deletion():
		push_error("Rejected prediction was not removed")
		quit(1)
		return
	game.predicted_shots[78] = []
	game._leave("test")
	if not game.predicted_shots.is_empty() or game.shot_sequence != 0:
		push_error("Session prediction state was not reset")
		quit(1)
		return
	print("PASS: rejected prediction removed; disconnect resets prediction state")
	quit()
