extends Area2D

var direction := Vector2.RIGHT
@export var speed: float = 900.0
@export var bullet_gravity: float = 980.0
var damage := 10
var lifetime := 2.0
var velocity := Vector2.ZERO
var shooter: CollisionObject2D
var previous_position := Vector2.ZERO
var previous_rotation: float = 0.0

func _process(_delta: float) -> void:
	render_visual(Engine.get_physics_interpolation_fraction())

func render_visual(fraction: float) -> void:
	# Çarpışma hesabını değiştirmeden, görüntüyü her karede ilerlet.
	$Sprite2D.global_position = previous_position.lerp(global_position, fraction)
	$Sprite2D.global_rotation = lerp_angle(previous_rotation, global_rotation, fraction)

func _physics_process(delta):
	previous_position = global_position
	previous_rotation = global_rotation
	velocity.y += bullet_gravity * delta
	var next_position: Vector2 = global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 7)
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if multiplayer.is_server() and get_tree().current_scene.has_method("damage_player"):
			get_tree().current_scene.damage_player(hit.collider, shooter, damage, velocity.normalized())
		queue_free()
		return
	global_position = next_position
	global_rotation = velocity.angle()

func _ready():
	velocity = direction.normalized() * speed
	global_rotation = velocity.angle()
	previous_position = global_position
	previous_rotation = global_rotation
	await get_tree().create_timer(lifetime).timeout
	queue_free()
