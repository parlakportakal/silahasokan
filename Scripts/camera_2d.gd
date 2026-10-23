extends Camera2D

@export_group("Oyuncuları Kadraja Alma")
@export var intro_duration: float = 1.2
@export var player_padding: Vector2 = Vector2(180, 130)
@export var minimum_frame_size: Vector2 = Vector2(640, 400)
@export var maximum_zoom: float = 2.0
@export var follow_speed: float = 4.0
@export var zoom_speed: float = 3.0
@export var target_group: StringName = &"camera_players"

var map_bounds := Rect2()
var following := false
var intro_remaining: float = 0.0

func _ready() -> void:
	# Merkez ve zoom birlikte yumuşatılır; ikinci bir kamera gecikmesi uygulanmaz.
	position_smoothing_enabled = false
	process_priority = 100
	offset = Vector2.ZERO

func configure_map(bounds: Rect2) -> void:
	map_bounds = bounds
	if not following or intro_remaining > 0.0:
		show_whole_map()

func show_whole_map() -> void:
	var size := map_bounds.size + Vector2.ONE * 32.0
	var viewport := get_viewport_rect().size
	var fit := minf(viewport.x / maxf(size.x, 1.0), viewport.y / maxf(size.y, 1.0))
	global_position = map_bounds.get_center()
	zoom = Vector2.ONE * fit
	offset = Vector2.ZERO

func begin_match() -> void:
	following = true
	intro_remaining = intro_duration
	show_whole_map()

func end_match() -> void:
	following = false
	intro_remaining = 0.0
	show_whole_map()

func _process(delta: float) -> void:
	if not following:
		return
	if intro_remaining > 0.0:
		intro_remaining = maxf(0.0, intro_remaining - delta)
		return
	var targets: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group(target_group):
		if node is Node2D and node.is_visible_in_tree() and get_tree().current_scene.is_ancestor_of(node):
			# Track the rendered position, not both it and the latest network packet.
			var sprite := node.get_node_or_null("Sprite2D") as Node2D
			if sprite != null:
				targets.append(sprite.global_position)
			else:
				targets.append(node.global_position)
	if targets.is_empty():
		return
	frame_targets(targets, delta)

func frame_targets(targets: Array[Vector2], delta: float) -> void:
	if targets.is_empty():
		return
	var bounds := Rect2(targets[0], Vector2.ZERO)
	for point in targets:
		bounds = bounds.expand(point)
	var frame_size := (bounds.size + player_padding * 2.0).max(minimum_frame_size)
	var viewport := get_viewport_rect().size
	var target_zoom := minf(maximum_zoom, minf(viewport.x / frame_size.x, viewport.y / frame_size.y))
	# Widen immediately for separated players; close in smoothly afterwards.
	var next_zoom := minf(target_zoom, lerpf(zoom.x, target_zoom, 1.0 - exp(-zoom_speed * delta)))
	var half_view := viewport / maxf(next_zoom, 0.001) * 0.5
	var center := global_position.lerp(bounds.get_center(), 1.0 - exp(-follow_speed * delta))
	for axis in range(2):
		# Keep the map edge stable using the actual zoom for this frame.
		if half_view[axis] * 2.0 >= map_bounds.size[axis]:
			center[axis] = map_bounds.get_center()[axis]
		else:
			center[axis] = clampf(center[axis], map_bounds.position[axis] + half_view[axis], map_bounds.end[axis] - half_view[axis])
		# Correct camera lag instead of zooming out on every jump or swing.
		var low := bounds.end[axis] + player_padding[axis] - half_view[axis]
		var high := bounds.position[axis] - player_padding[axis] + half_view[axis]
		center[axis] = clampf(center[axis], low, high) if low <= high else bounds.get_center()[axis]
	global_position = center
	zoom = Vector2.ONE * next_zoom
