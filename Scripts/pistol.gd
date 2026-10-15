extends Node2D

func _process(_delta: float) -> void:
	# Dönüşü üstteki eksen yönetir; sola bakarken silahı düz tut.
	scale.y = -1.0 if cos(global_rotation) < 0.0 else 1.0
	
	
