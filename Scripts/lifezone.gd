extends Area2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4

func contains_point(point: Vector2) -> bool:
	var collider := $CollisionShape2D as CollisionShape2D
	var rectangle := collider.shape as RectangleShape2D
	return Rect2(-rectangle.size * 0.5, rectangle.size).has_point(collider.to_local(point))

func _on_body_exited(body: Node2D) -> void:
	var game := get_parent()
	if game.has_method("player_left_lifezone"):
		game.call_deferred("player_left_lifezone", body)
