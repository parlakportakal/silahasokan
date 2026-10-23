extends RefCounted

var jump_cooldown := 0.0
var scan_timer := 0.0
var waypoint := Vector2.ZERO
var grip := Vector2.ZERO
var has_grip := false
var wall_push_time := 0.0
var wall_push_direction := 0.0

func ray(body: CharacterBody2D, from: Vector2, to: Vector2, mask: int = 3) -> Dictionary:
	return body.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, mask, [body.get_rid()]))

func decide(body: CharacterBody2D, delta: float) -> Dictionary:
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	wall_push_time = maxf(0.0, wall_push_time - delta)
	scan_timer -= delta
	var home: Vector2 = body.bot_home
	var pos := body.global_position
	# Spawn markers sit above the ground; tolerate that standing-height difference.
	var arrived := absf(home.x - pos.x) < 12 and absf(home.y - pos.y) < 65
	if arrived and body.is_on_floor():
		return {"direction": 0.0, "jump": false, "drop": false, "held": false, "reel": false}
	if scan_timer <= 0:
		scan_timer = 0.15
		waypoint = home
		has_grip = false
		var best := INF
		# Choose reachable stepping stones rather than pushing into a tall wall.
		for x in range(-300, 301, 60):
			var hit := ray(body, pos + Vector2(x, -180), pos + Vector2(x, 220))
			if hit.is_empty():
				continue
			var landing: Vector2 = hit.position + Vector2(0, -24)
			if landing.y > pos.y + 100 and home.y < pos.y - 60:
				continue
			var score := landing.distance_to(home) + landing.distance_to(pos) * 0.2
			if score < best and landing.distance_to(home) < pos.distance_to(home) - 20:
				best = score
				waypoint = landing
		# Look for a useful anchor in range, including overhead and diagonal surfaces.
		best = INF
		for i in range(13):
			var aim := Vector2.UP.rotated(deg_to_rad(-90 + i * 15))
			var hit := ray(body, body.hook.origin(), body.hook.origin() + aim * body.hook.max_range)
			if hit.is_empty():
				continue
			var point: Vector2 = hit.position
			var score := point.distance_to(home)
			if point.y < pos.y - 45 and score < best and score < pos.distance_to(home):
				best = score
				grip = point
				has_grip = true
	var dx := waypoint.x - pos.x
	var direction := signf(dx) if absf(dx) > 10 else 0.0
	# Brake at the destination instead of oscillating past it at full speed.
	var braking: float = body.velocity.x * body.velocity.x / (2.0 * body.friction)
	if absf(home.x - pos.x) < braking + 8 and signf(body.velocity.x) == signf(home.x - pos.x):
		direction = 0.0
	var ahead := pos + Vector2(direction * 45, 0)
	var obstacle := not ray(body, pos, ahead, 1).is_empty() and direction != 0
	var gap := ray(body, ahead, ahead + Vector2(0, 100)).is_empty() and direction != 0
	var above := waypoint.y < pos.y - 55 or home.y < pos.y - 65
	var wall_side: int = body.last_wall_side
	var wall_jump: bool = not body.is_on_floor() and body.wall_coyote_counter > 0 and wall_side != body.last_wall_jump_side and (above or obstacle)
	var jump: bool = jump_cooldown <= 0 and ((body.is_on_floor() and (obstacle or gap or above)) or wall_jump or (not body.is_on_floor() and body.jump_count < body.max_jump and body.velocity.y > -50 and (above or gap or obstacle)))
	if jump:
		jump_cooldown = 0.22
		if wall_jump:
			wall_push_time = 0.18
			wall_push_direction = -wall_side
	if wall_push_time > 0:
		direction = wall_push_direction
	var drop := body.is_on_floor() and home.y > pos.y + 75 and absf(home.x - pos.x) < 120
	var use_hook := has_grip and not body.is_on_floor() and (above or body.velocity.y > 100)
	if body.hook.state == body.hook.State.ATTACHED:
		use_hook = body.hook.anchor.distance_to(home) < pos.distance_to(home) and pos.distance_to(body.hook.anchor) > body.hook.minimum_length + 12 and not arrived
	return {"direction": direction, "jump": jump, "drop": drop, "held": use_hook, "pressed": use_hook and body.hook.state == body.hook.State.IDLE, "target": grip, "reel": use_hook}
