extends Area2D

var direction := Vector2.RIGHT
@export var speed: float = 900.0
@export var bullet_gravity: float = 980.0
var damage := 10
var lifetime := 2.0
var velocity := Vector2.ZERO
var shooter: CollisionObject2D

func _physics_process(delta):
	velocity.y += bullet_gravity * delta
	var next_position: Vector2 = global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 7)
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if multiplayer.is_server() and get_tree().current_scene.has_method("damage_player"):
			get_tree().current_scene.damage_player(hit.collider, shooter, damage)
		queue_free()
		return
	global_position = next_position
	global_rotation = velocity.angle()

func _ready():
	velocity = direction.normalized() * speed
	global_rotation = velocity.angle()
	await get_tree().create_timer(lifetime).timeout
	queue_free()
