extends Node2D

@export var max_range: float = 350.0
@export var launch_speed: float = 1800.0
@export var retract_speed: float = 3000.0
@export var climb_speed: float = 220.0
@export var minimum_length: float = 20.0
@export var swing_acceleration: float = 500.0
@export var fall_gravity: float = 980.0
@export var terminal_fall_speed: float = 900.0

enum State { IDLE, FLYING, ATTACHED, RETRACTING, FALLING }
var fall_velocity := Vector2.ZERO
var outgoing_pull := Vector2.ZERO
var state: int = State.IDLE
var tip := Vector2.ZERO
var anchor := Vector2.ZERO
var rope_length: float = 0.0
var travel: float = 0.0
var launch_direction := Vector2.RIGHT
var target_body: Node2D
var target_offset := Vector2.ZERO
var player: CharacterBody2D

func _ready() -> void:
	player = get_parent() as CharacterBody2D

func origin() -> Vector2:
	var muzzle := player.get_node_or_null("silaheksen/pompgun/muzzle") as Node2D
	return muzzle.global_position if muzzle != null else player.global_position

func reset() -> void:
	_clear_pull()
	state = State.IDLE
	target_body = null
	queue_redraw()

func release() -> void:
	_clear_pull()
	if state != State.IDLE:
		state = State.RETRACTING
		target_body = null

func fire(target: Vector2) -> void:
	if state != State.IDLE:
		return
	tip = origin()
	launch_direction = tip.direction_to(target)
	travel = 0.0
	state = State.FLYING

func can_climb() -> bool:
	return state == State.ATTACHED

func attached_to_player() -> bool:
	return is_instance_valid(target_body) and target_body is CharacterBody2D and target_body != player and target_body.get_collision_layer_value(3)

func _clear_pull() -> void:
	outgoing_pull = Vector2.ZERO
	if attached_to_player() and target_body.has_method("receive_hook_pull"):
		target_body.receive_hook_pull(Vector2.ZERO)

func _advance_tip(next: Vector2) -> void:
	# The loose rope cannot extend beyond its length, even while falling.
	var offset := next - origin()
	if offset.length() > max_range:
		var radial := offset.normalized()
		next = origin() + radial * max_range
		fall_velocity -= radial * maxf(0.0, fall_velocity.dot(radial))
	var query := PhysicsRayQueryParameters2D.create(tip, next, 1 | 2 | 4, [player.get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		tip = next
		return
	anchor = hit.position
	tip = anchor
	target_body = hit.collider as Node2D
	target_offset = target_body.to_local(anchor)
	rope_length = maxf(minimum_length, player.global_position.distance_to(anchor))
	state = State.ATTACHED

func step(delta: float, enabled: bool) -> void:
	outgoing_pull = Vector2.ZERO
	if not enabled or not Input.is_action_pressed("sagtik"):
		release()
	elif Input.is_action_just_pressed("sagtik"):
		fire(get_global_mouse_position())
	if state == State.FLYING:
		var distance := minf(launch_speed * delta, max_range - travel)
		travel += distance
		_advance_tip(tip + launch_direction * distance)
		if state == State.FLYING and (travel >= max_range or tip.distance_to(origin()) >= max_range - 0.01):
			state = State.FALLING
			fall_velocity = launch_direction * launch_speed * 0.15
	elif state == State.FALLING:
		fall_velocity.y = minf(terminal_fall_speed, fall_velocity.y + fall_gravity * delta)
		fall_velocity.x = move_toward(fall_velocity.x, 0.0, 300.0 * delta)
		_advance_tip(tip + fall_velocity * delta)
	if state == State.ATTACHED:
		if not is_instance_valid(target_body) or (target_body is CharacterBody2D and (not target_body.is_visible_in_tree() or not target_body.get_collision_layer_value(3))):
			release()
		else:
			anchor = target_body.to_global(target_offset)
			tip = anchor
			if can_climb() and (Input.is_action_pressed("hook_up") or attached_to_player()):
				var reel_speed := climb_speed
				if attached_to_player():
					var separation := player.global_position.distance_to(anchor)
					var closing_speed := minf(climb_speed, maxf(0.0, separation - minimum_length) / maxf(delta, 0.0001))
					reel_speed = closing_speed * 0.85
					rope_length = minf(rope_length, maxf(minimum_length, separation))
					outgoing_pull = anchor.direction_to(player.global_position) * closing_speed * 0.15
					if target_body.has_method("receive_hook_pull"):
						target_body.receive_hook_pull(outgoing_pull)
				rope_length = maxf(minimum_length, rope_length - reel_speed * delta)
	if state == State.RETRACTING:
		tip = tip.move_toward(origin(), retract_speed * delta)
		if tip.distance_to(origin()) < 4.0:
			reset()
	queue_redraw()

func constrain(delta: float) -> void:
	if state != State.ATTACHED:
		return
	var offset := player.global_position - anchor
	var radial := offset.normalized()
	# Limit outward speed before moving; inward speed reels the rope in.
	var allowed := (rope_length - offset.length()) / maxf(delta, 0.0001)
	var outward := player.velocity.dot(radial)
	if outward > allowed:
		player.velocity -= radial * (outward - allowed)

func correct_position() -> void:
	if state == State.FLYING or state == State.FALLING:
		# Character movement happens after step(); keep the loose tip in range.
		if tip.distance_to(origin()) > max_range:
			_advance_tip(tip)
		return
	if state != State.ATTACHED:
		return
	var offset := player.global_position - anchor
	if offset.length() > rope_length:
		# Collision-aware correction prevents pulling through walls.
		player.move_and_collide(-offset.normalized() * (offset.length() - rope_length))

func _draw() -> void:
	if state == State.IDLE or player == null:
		return
	var start := to_local(origin())
	var end := to_local(tip)
	draw_line(start, end, Color(0.12, 0.16, 0.2), 4.0, true)
	draw_line(start, end, Color(0.65, 0.85, 0.95), 2.0, true)
	draw_circle(end, 4.0, Color(0.95, 0.7, 0.25))
