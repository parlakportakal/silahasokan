extends CharacterBody2D

var hook_pull_velocity := Vector2.ZERO
var hook_pull_remaining: float = 0.0

func receive_hook_pull(pull: Vector2) -> void:
	hook_pull_velocity = pull
	hook_pull_remaining = 0.15

var hook: Node2D

func _ready() -> void:
	hook = preload("res://Scripts/grappling_hook.gd").new()
	hook.name = "GrapplingHook"
	add_child(hook)

var local_control: bool = false
var bot_control: bool = false
var bot_home := Vector2.ZERO
var bot_brain = preload("res://Scripts/bot_movement.gd").new()
var bot_actions: Dictionary = {}
var drop_remaining: float = 0.0
@export var starting_lives: int = 3
@export_group("Yeniden Doğma")
@export_range(0.0, 30.0, 0.1, "or_greater", "suffix:s") var respawn_delay: float = 2.0
@export_range(0.0, 30.0, 0.1, "or_greater", "suffix:s") var respawn_invulnerability_duration: float = 2.0
var respawning: bool = false
var respawn_remaining: float = 0.0
var blink_elapsed: float = 0.0
var lives: int = 3
var spawn_generation: int = 0
var damage_percent: float = 0.0
var knockback_velocity := Vector2.ZERO
var respawn_grace: float = 0.0
var last_attacker: int = -1
var knockback_multiplier: float:
	get:
		return 1.0 + damage_percent / 100.0

func reset_combat() -> void:
	bot_brain = preload("res://Scripts/bot_movement.gd").new()
	bot_actions.clear()
	drop_remaining = 0.0
	hook_pull_velocity = Vector2.ZERO
	hook_pull_remaining = 0.0
	if hook != null:
		hook.reset()
	damage_percent = 0.0
	knockback_velocity = Vector2.ZERO
	respawn_grace = 0.0
	respawning = false
	respawn_remaining = 0.0
	blink_elapsed = 0.0
	modulate.a = 1.0
	if hit_flash != null and hit_flash.is_valid():
		hit_flash.kill()
	$Sprite2D.self_modulate = Color.WHITE
	last_attacker = -1
	velocity = Vector2.ZERO
	jump_count = 0
	buffercounter = 0.0
	wall_coyote_counter = 0.0
	last_wall_side = 0
	last_wall_jump_side = 0
	set_collision_mask_value(2, true)

var score: int = 0
var hit_flash: Tween

func show_hit_feedback() -> void:
	if hit_flash != null and hit_flash.is_valid():
		hit_flash.kill()
	# self_modulate sadece karakteri boyar; silah ve oyuncu rengi korunur.
	$Sprite2D.self_modulate = Color(1.0, 0.15, 0.15)
	hit_flash = create_tween()
	hit_flash.tween_property($Sprite2D, "self_modulate", Color.WHITE, 0.18)

var speed = 500
var jump_force = 400
var gravity = 980
var acceleration = 2540
var friction = 2500
var jump_count = 0
var max_jump = 2
var buffertime = 0.1
var buffercounter = 0.0
var wall_coyote_time  = 0.12
var wall_coyote_counter = 0.0
var last_wall_side = 0  # Sol: -1, sağ: 1.
var last_wall_jump_side = 0


func _physics_process(delta: float) -> void:
	if drop_remaining > 0.0:
		drop_remaining = maxf(0.0, drop_remaining - delta)
		if drop_remaining == 0.0:
			set_collision_mask_value(2, true)
	if bot_control and lives > 0 and not respawning:
		bot_actions = bot_brain.decide(self, delta)
		var axis := get_node_or_null("silaheksen")
		if axis != null:
			axis.select_weapon(1)
			if bot_actions.get("held", false):
				axis.look_at(bot_actions.get("target", bot_home))
		hook.step(delta, true, bot_actions)
	hook_pull_remaining = maxf(0.0, hook_pull_remaining - delta)
	if hook_pull_remaining <= 0.0:
		hook_pull_velocity = Vector2.ZERO
	respawn_grace = maxf(0.0, respawn_grace - delta)
	if respawn_grace > 0.0:
		blink_elapsed += delta
		modulate.a = 0.2 if int(blink_elapsed / 0.1) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0
		blink_elapsed = 0.0
	if local_control:
		var axis := get_node_or_null("silaheksen")
		hook.step(delta, lives > 0 and not respawning and axis != null and axis.selected_weapon == 1)
	elif hook.state != hook.State.IDLE:
		hook.queue_redraw()
	if (not local_control and not bot_control) or lives <= 0 or respawning:
		return
	var direction = Vector2.ZERO

	var sag_duvar = $raycastsag.is_colliding()
	var sol_duvar = $raycastsol.is_colliding()
	var duvarda = sag_duvar or sol_duvar
	wall_coyote_counter = maxf(wall_coyote_counter - delta, 0.0)
	if is_on_floor():
		last_wall_jump_side = 0
		last_wall_side = 0
		wall_coyote_counter = 0.0
	elif duvarda:
		# İki duvar aynı anda algılanırsa kullanılabilir karşı tarafı seç.
		if sag_duvar and (not sol_duvar or last_wall_jump_side != 1):
			last_wall_side = 1
		else:
			last_wall_side = -1
		wall_coyote_counter = wall_coyote_time

	if (local_control and Input.is_action_just_pressed("zipla")) or (bot_control and bot_actions.get("jump", false)):
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
	# Tolerans süresinde normal zıplama, duvar zıplamasını tüketmesin.
	if buffercounter > 0 and jump_count < max_jump and (is_on_floor() or (not duvarda and wall_coyote_counter <= 0.0)):
		jump_count += 1
		velocity.y = -jump_force
		buffercounter = 0

	if is_on_floor() and drop_remaining <= 0.0 and ((local_control and Input.is_action_just_pressed("asagi")) or (bot_control and bot_actions.get("drop", false))):
		set_collision_mask_value(2, false)
		drop_remaining = 0.2

	if local_control and Input.is_action_pressed("saga"):
		direction.x += 1
	if local_control and Input.is_action_pressed("sola"):
		direction.x -= 1
	if bot_control:
		direction.x = bot_actions.get("direction", 0.0)

	if direction.x < 0:
		$Sprite2D.flip_h = true
	if direction.x > 0:
		$Sprite2D.flip_h = false

	if hook.state == hook.State.ATTACHED:
		velocity.x += direction.x * hook.swing_acceleration * delta
	elif direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	if hook.state != hook.State.ATTACHED:
		velocity.x = clamp(velocity.x, -speed, speed)

	# Wall slide
	if duvarda and not is_on_floor():
		velocity.y = min(velocity.y, 90.0)

	# Wall jump
	if buffercounter > 0 and not is_on_floor() and wall_coyote_counter > 0.0:
		if last_wall_side != 0 and last_wall_side != last_wall_jump_side:
			velocity.y = -jump_force
			velocity.x = -last_wall_side * 300
			last_wall_jump_side = last_wall_side
			wall_coyote_counter = 0.0
			buffercounter = 0

	var movement_velocity := velocity
	velocity += knockback_velocity + hook_pull_velocity
	hook.constrain(delta)
	if hook.state == hook.State.ATTACHED:
		movement_velocity = velocity - knockback_velocity - hook_pull_velocity
	move_and_slide()
	hook.correct_position()
	for index in range(get_slide_collision_count()):
		knockback_velocity = knockback_velocity.slide(get_slide_collision(index).get_normal())
	velocity = movement_velocity
	if is_on_floor() or is_on_ceiling():
		velocity.y = 0.0
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 650.0 * delta)
