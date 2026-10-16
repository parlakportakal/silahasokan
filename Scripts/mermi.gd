extends Area2D

var direction := Vector2.RIGHT
var speed := 900.0
var damage := 10
var lifetime := 2.0
var velocity := Vector2.ZERO
# var gravity := 980.0 daha önceden playerda yazmışız zaten gravity

func _physics_process(delta):
	position += direction * speed * delta
	velocity.y += gravity * delta
	position += velocity * delta

func _ready():
	rotation = direction.angle()
	await get_tree().create_timer(lifetime).timeout
	queue_free()
