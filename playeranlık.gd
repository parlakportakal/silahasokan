extends CharacterBody2D

var speed = 500
var jump_force = 400
var gravity = 980
var acceleration = 2540
var friction = 2500
var turn_multiplier
var jump_count= 0
var max_jump = 2

##selam bunu yazan piç

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	
	if direction.x != 0:
		var accel = acceleration
	
	
	
	
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor():
		jump_count = 0
		$cayotetimer.start()
	if $cayotetimer.is_stopped() and jump_count == 0:
		jump_count = 1
	if Input.is_action_just_pressed("zipla") and jump_count <  max_jump:
		jump_count += 1
		velocity.y = -jump_force
##sikik
	if Input.is_action_just_pressed("asagi") and is_on_floor():
		set_collision_mask_value(1, false)
		await get_tree().create_timer(1.2)
		set_collision_mask_value(1, true)
	
	
	
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
