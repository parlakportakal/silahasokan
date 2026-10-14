extends CharacterBody2D

var speed = 500
var jump_force = 400
var gravity = 980
var acceleration = 2540
var friction = 2500
var jump_count= 0
var max_jump = 2
var buffertime = 0.1
var buffercounter = 0.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	if Input.is_action_just_pressed("zipla"):
		buffercounter = buffertime
	buffercounter = max(buffercounter - delta , 0.0)
	
	
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor():
		jump_count = 0
		$cayotetimer.start()
	if $cayotetimer.is_stopped() and jump_count == 0:
		jump_count = 1
	if buffercounter > 0 and jump_count <  max_jump:
		jump_count += 1
		velocity.y = -jump_force
		buffercounter = 0
##sikik
	if Input.is_action_just_pressed("asagi") and is_on_floor():
		set_collision_mask_value(2, false)
		await get_tree().create_timer(0.2).timeout
		set_collision_mask_value(2, true)
	
	
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
