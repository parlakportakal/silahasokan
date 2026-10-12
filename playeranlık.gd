extends CharacterBody2D

var speed = 500
var jump_force = 200
var gravity = 980 


func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor() and Input.is_action_just_pressed("zipla"):
		velocity.y = -jump_force
	
	
	
	
	
	if Input.is_action_pressed("saga"):
		direction.x += 1
	if Input.is_action_pressed("sola"):
		direction.x -= 1
	
	
	if direction.x < 0:
		$Sprite2D.flip_h = true
	if direction.x > 0:
		$Sprite2D.flip_h = false
	

	
	velocity.x = direction.x * speed
	move_and_slide()
