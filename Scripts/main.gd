extends Node2D


func _ready() -> void:
	var background: Sprite2D = $Arkaplan
	var camera: Camera2D = $player/Camera2D
	var bounds := background.get_global_transform() * background.get_rect()
	camera.limit_left = ceili(bounds.position.x)
	camera.limit_top = ceili(bounds.position.y)
	camera.limit_right = floori(bounds.end.x)
	camera.limit_bottom = floori(bounds.end.y)
	_fit_camera_to_map()
	get_viewport().size_changed.connect(_fit_camera_to_map)
	# Başlangıçta kamera uzaktan kayarak gelmesin.
	camera.reset_smoothing()


func _fit_camera_to_map() -> void:
	var camera: Camera2D = $player/Camera2D
	var map_size := Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)
	var viewport_size := get_viewport_rect().size
	# Çok geniş veya yüksek pencerelerde de haritanın dışı görünmesin.
	var zoom_level := maxf(2.96, maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
	camera.zoom = Vector2.ONE * zoom_level


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rHARFi"):
		get_tree().reload_current_scene()
		
