extends Area2D

@export var speed: float = 900.0
@export var damage: float = 5.0
@export var knockback: float = 250.0
@export var lifetime: float = 2.0
## Knockback yönünü yukarı eğer, oyuncuyu havaya kaldırır
@export var launch_angle_degrees: float = 15.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body.has_method("apply_hit"):
		# Sağa giden mermide -açı, sola gidende +açı = hep yukarı eğilir
		var hit_dir := direction.rotated(-deg_to_rad(launch_angle_degrees) * signf(direction.x))
		body.apply_hit(damage, knockback, hit_dir)
	queue_free()  # oyuncuya veya duvara çarpınca yok ol
