extends CharacterBody2D

var speed = 500
var jump_force = 200
var gravity = 980
var acceleration = 2540
var friction = 2500


##selam bunu yazan piç

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
	
	
	if direction.x != 0:
		velocity.x = move_toward(velocity.x , direction.x * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x , 0 , friction * delta)
	velocity.x = clamp(velocity.x, -speed, speed)
	
	
	move_and_slide()
