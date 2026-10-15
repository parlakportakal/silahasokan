extends CharacterBody2D

var speed = 500
var jump_force = 400
var gravity = 980
var acceleration = 2540
var friction = 2500
var jump_count = 0
var max_jump = 2
var buffertime = 0.1
var buffercounter = 0.0


func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO

	var sag_duvar = $raycastsag.is_colliding()
	var sol_duvar = $raycastsol.is_colliding()
	var duvarda = sag_duvar or sol_duvar

	if Input.is_action_just_pressed("zipla"):
		buffercounter = buffertime
	buffercounter = max(buffercounter - delta, 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor():
		jump_count = 0
		$cayotetimer.start()

	if $cayotetimer.is_stopped() and jump_count == 0:
		jump_count = 1

	# Normal zıplama ve double jump.
	# Duvara değince bu bölüm jump_count'u değiştirmez.
	if buffercounter > 0 and jump_count < max_jump and (is_on_floor() or not duvarda):
		jump_count += 1
		velocity.y = -jump_force
		buffercounter = 0

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
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	velocity.x = clamp(velocity.x, -speed, speed)

	# Wall slide
	if duvarda and not is_on_floor():
		velocity.y = min(velocity.y, 90.0)

	# Wall jump
	if buffercounter > 0 and not is_on_floor():
		if sag_duvar:
			velocity.y = -jump_force
			velocity.x = -300
			buffercounter = 0
		elif sol_duvar:
			velocity.y = -jump_force
			velocity.x = 300
			buffercounter = 0

	move_and_slide()
