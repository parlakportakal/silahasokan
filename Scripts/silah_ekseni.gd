extends Node2D


func _process(_delta: float) -> void:
	# Dönüş merkezi oyuncuda kalır; uzaktaki silah bu merkez etrafında döner.
	if global_position.distance_squared_to(get_global_mouse_position()) > 0.001:
		look_at(get_global_mouse_position())
