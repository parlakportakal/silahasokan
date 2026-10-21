extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/mermi.tscn")
@export var pellet_count: int = 1
@export var spread_degrees: float = 0.0
@export var fire_interval: float = 0.2

var cooldown: float = 0.0
@onready var muzzle: Marker2D = $muzzle

func _process(delta: float) -> void:
	# Dönüşü üstteki eksen yönetir; sola bakarken silahı düz tut.
	scale.y = -1.0 if cos(global_rotation) < 0.0 else 1.0
	cooldown = maxf(0.0, cooldown - delta)


func shoot() -> void:
	scale.y = -1.0 if cos(global_rotation) < 0.0 else 1.0
	cooldown = fire_interval
	for index in range(pellet_count):
		var offset_angle := 0.0
		if pellet_count > 1:
			offset_angle = deg_to_rad(spread_degrees) * (float(index) / float(pellet_count - 1) - 0.5)
		var bullet = bullet_scene.instantiate()
		bullet.shooter = get_parent().get_parent()
		bullet.direction = Vector2.RIGHT.rotated(global_rotation + offset_angle)
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position
		bullet.global_rotation = bullet.direction.angle()
