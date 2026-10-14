extends Node2D

const BULLET = preload("res://Scenes/mermi.tscn")

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees < 270 and rotation_degrees > 90:
		scale.y = -1
	else:
		scale.y = 1

	if Input.is_action_pressed("soltik"):
		var bullet_instance = BULLET
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = $muzzle.global_position
