extends Node2D

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees < 270 and rotation_degrees > 90:
		scale.y = -1
		position.x 
	else :
		scale.y = +1
	
	
